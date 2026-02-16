"""
Trainee-facing community views: announcements, achievements, community feed.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from django.db import IntegrityError
from django.db.models import Count, Q, QuerySet
from django.utils import timezone
from rest_framework import generics, status, views
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainee
from users.models import User

from .models import (
    Announcement,
    AnnouncementReadStatus,
    Achievement,
    CommunityPost,
    PostReaction,
    UserAchievement,
)
from .serializers import (
    AchievementWithStatusSerializer,
    AnnouncementSerializer,
    CommunityPostSerializer,
    CreatePostSerializer,
    MarkReadResponseSerializer,
    NewAchievementSerializer,
    PostAuthorSerializer,
    ReactionResponseSerializer,
    ReactionToggleSerializer,
    UnreadCountSerializer,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Trainee Announcements
# ---------------------------------------------------------------------------


class TraineeAnnouncementListView(generics.ListAPIView[Announcement]):
    """
    GET /api/community/announcements/
    List announcements from the trainee's parent_trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainee]
    serializer_class = AnnouncementSerializer

    def get_queryset(self) -> QuerySet[Announcement]:
        user = cast(User, self.request.user)
        if user.parent_trainer is None:
            return Announcement.objects.none()
        return Announcement.objects.filter(
            trainer=user.parent_trainer,
        ).order_by('-is_pinned', '-created_at')


class AnnouncementUnreadCountView(views.APIView):
    """
    GET /api/community/announcements/unread-count/
    Returns {unread_count: int}.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'unread_count': 0})

        try:
            read_status = AnnouncementReadStatus.objects.get(
                user=user, trainer=trainer,
            )
            unread_count = Announcement.objects.filter(
                trainer=trainer,
                created_at__gt=read_status.last_read_at,
            ).count()
        except AnnouncementReadStatus.DoesNotExist:
            unread_count = Announcement.objects.filter(trainer=trainer).count()

        return Response({'unread_count': unread_count})


class AnnouncementMarkReadView(views.APIView):
    """
    POST /api/community/announcements/mark-read/
    Upserts AnnouncementReadStatus with last_read_at = now.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        now = timezone.now()
        read_status, _created = AnnouncementReadStatus.objects.update_or_create(
            user=user,
            trainer=trainer,
            defaults={'last_read_at': now},
        )
        return Response({'last_read_at': read_status.last_read_at})


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------


class AchievementListView(views.APIView):
    """
    GET /api/community/achievements/
    All achievements with earned status for the current user.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        achievements = Achievement.objects.all().order_by('criteria_type', 'criteria_value')

        earned_map: dict[int, Any] = {}
        for ua in UserAchievement.objects.filter(user=user).select_related('achievement'):
            earned_map[ua.achievement_id] = ua.earned_at

        data = []
        for a in achievements:
            earned_at = earned_map.get(a.id)
            data.append({
                'id': a.id,
                'name': a.name,
                'description': a.description,
                'icon_name': a.icon_name,
                'criteria_type': a.criteria_type,
                'criteria_value': a.criteria_value,
                'earned': earned_at is not None,
                'earned_at': earned_at,
            })

        serializer = AchievementWithStatusSerializer(data, many=True)
        return Response(serializer.data)


class AchievementRecentView(views.APIView):
    """
    GET /api/community/achievements/recent/
    5 most recently earned achievements for current user.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        recent = (
            UserAchievement.objects.filter(user=user)
            .select_related('achievement')
            .order_by('-earned_at')[:5]
        )
        serializer = NewAchievementSerializer(recent, many=True)
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Community Feed
# ---------------------------------------------------------------------------


class CommunityFeedView(views.APIView):
    """
    GET  /api/community/feed/ — paginated feed scoped to trainer group.
    POST /api/community/feed/ — create a text post.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'count': 0, 'next': None, 'previous': None, 'results': []})

        from rest_framework.pagination import PageNumberPagination

        queryset = (
            CommunityPost.objects.filter(trainer=trainer)
            .select_related('author')
            .order_by('-created_at')
        )

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(queryset, request)
        if page is None:
            page = list(queryset)

        data = self._serialize_posts(page, user, request)

        if paginator.page is not None:
            return paginator.get_paginated_response(data)
        return Response(data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response(
                {'error': "You must be part of a trainer's group to post."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CreatePostSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        post = CommunityPost.objects.create(
            author=user,
            trainer=trainer,
            content=serializer.validated_data['content'],
            post_type=CommunityPost.PostType.TEXT,
        )

        response_data = self._serialize_posts([post], user, request)
        return Response(response_data[0], status=status.HTTP_201_CREATED)

    @staticmethod
    def _serialize_posts(
        posts: list[CommunityPost],
        current_user: User,
        request: Request,
    ) -> list[dict[str, Any]]:
        """Serialize a list of posts with reaction aggregates and user_reactions."""
        if not posts:
            return []

        post_ids = [p.id for p in posts]

        # Aggregate reaction counts per post per type in one query
        reaction_counts_qs = (
            PostReaction.objects.filter(post_id__in=post_ids)
            .values('post_id', 'reaction_type')
            .annotate(count=Count('id'))
        )
        reaction_map: dict[int, dict[str, int]] = {}
        for row in reaction_counts_qs:
            pid = row['post_id']
            if pid not in reaction_map:
                reaction_map[pid] = {'fire': 0, 'thumbs_up': 0, 'heart': 0}
            reaction_map[pid][row['reaction_type']] = row['count']

        # Current user's reactions
        user_reaction_qs = PostReaction.objects.filter(
            post_id__in=post_ids, user=current_user,
        ).values_list('post_id', 'reaction_type')
        user_reactions_map: dict[int, list[str]] = {}
        for pid, rt in user_reaction_qs:
            user_reactions_map.setdefault(pid, []).append(rt)

        result: list[dict[str, Any]] = []
        for post in posts:
            author = post.author
            author_data = {
                'id': author.id,
                'first_name': author.first_name,
                'last_name': author.last_name,
                'profile_image': (
                    request.build_absolute_uri(author.profile_image.url)
                    if author.profile_image else None
                ),
            }
            result.append({
                'id': post.id,
                'author': author_data,
                'content': post.content,
                'post_type': post.post_type,
                'metadata': post.metadata,
                'created_at': post.created_at,
                'reactions': reaction_map.get(post.id, {'fire': 0, 'thumbs_up': 0, 'heart': 0}),
                'user_reactions': user_reactions_map.get(post.id, []),
            })

        return result


class CommunityPostDeleteView(views.APIView):
    """
    DELETE /api/community/feed/<id>/
    Author can delete own post. Trainer can delete any post in their group.
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        try:
            post = CommunityPost.objects.select_related('author', 'trainer').get(id=pk)
        except CommunityPost.DoesNotExist:
            return Response(
                {'error': 'Post not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Author can delete own post
        is_author = post.author == user
        # Trainer can delete any post in their group
        is_group_trainer = user.is_trainer() and post.trainer == user
        # Trainee impersonated by trainer also counts — the request user will be trainee
        # but we also allow the actual trainee author.

        if not (is_author or is_group_trainer):
            return Response(
                {'error': "You don't have permission to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

        post.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReactionToggleView(views.APIView):
    """
    POST /api/community/feed/<post_id>/react/
    Toggle a reaction on a post.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request, post_id: int) -> Response:
        user = cast(User, request.user)

        serializer = ReactionToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reaction_type = serializer.validated_data['reaction_type']

        try:
            post = CommunityPost.objects.get(id=post_id)
        except CommunityPost.DoesNotExist:
            return Response(
                {'error': 'Post not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Row-level security: user must be in the same trainer group
        if user.parent_trainer is None or post.trainer != user.parent_trainer:
            return Response(
                {'error': 'You cannot react to posts outside your group.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Toggle: delete if exists, create if not
        try:
            existing = PostReaction.objects.get(
                user=user, post=post, reaction_type=reaction_type,
            )
            existing.delete()
        except PostReaction.DoesNotExist:
            try:
                PostReaction.objects.create(
                    user=user, post=post, reaction_type=reaction_type,
                )
            except IntegrityError:
                # Race condition — reaction already exists, treat as no-op
                pass

        # Return updated counts
        counts_qs = (
            PostReaction.objects.filter(post=post)
            .values('reaction_type')
            .annotate(count=Count('id'))
        )
        reactions: dict[str, int] = {'fire': 0, 'thumbs_up': 0, 'heart': 0}
        for row in counts_qs:
            reactions[row['reaction_type']] = row['count']

        user_reactions = list(
            PostReaction.objects.filter(post=post, user=user)
            .values_list('reaction_type', flat=True)
        )

        return Response({
            'reactions': reactions,
            'user_reactions': user_reactions,
        })

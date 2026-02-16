"""
Trainee-facing community views: announcements, achievements, community feed,
leaderboards, comments.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from django.db import IntegrityError
from django.db.models import Count, QuerySet
from django.utils import timezone
from rest_framework import generics, status, views
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainee
from users.models import User

from .models import (
    Announcement,
    AnnouncementReadStatus,
    Achievement,
    Comment,
    CommunityPost,
    Leaderboard,
    PostReaction,
    UserAchievement,
)
from .serializers import (
    AnnouncementSerializer,
    CommentSerializer,
    CreateCommentSerializer,
    CreatePostSerializer,
    NewAchievementSerializer,
    ReactionToggleSerializer,
)


class FeedPagination(PageNumberPagination):
    """Pagination for community feed endpoint."""
    page_size = 20

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

        return Response(data)


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

_ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
_MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB


class CommunityFeedView(views.APIView):
    """
    GET  /api/community/feed/ -- paginated feed scoped to trainer group.
    POST /api/community/feed/ -- create a text post (with optional image).
    """
    permission_classes = [IsAuthenticated, IsTrainee]
    parser_classes = [MultiPartParser, JSONParser]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'count': 0, 'next': None, 'previous': None, 'results': []})

        queryset = (
            CommunityPost.objects.filter(trainer=trainer)
            .select_related('author')
            .annotate(comment_count=Count('comments'))
            .order_by('-created_at')
        )

        paginator = FeedPagination()
        page = paginator.paginate_queryset(queryset, request)
        if page is None:
            page = list(queryset)

        data = _serialize_posts(page, user, request)

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

        # Handle optional image
        image_file = request.FILES.get('image')
        if image_file is not None:
            if image_file.content_type not in _ALLOWED_IMAGE_TYPES:
                return Response(
                    {'error': 'Invalid image type. Allowed: JPEG, PNG, GIF, WebP.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if image_file.size > _MAX_IMAGE_SIZE:
                return Response(
                    {'error': 'Image too large. Maximum size is 10 MB.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        post = CommunityPost.objects.create(
            author=user,
            trainer=trainer,
            content=serializer.validated_data['content'],
            content_format=serializer.validated_data.get(
                'content_format', CommunityPost.ContentFormat.PLAIN,
            ),
            post_type=CommunityPost.PostType.TEXT,
            image=image_file,
        )

        # Annotate comment_count for serialization
        post.comment_count = 0  # type: ignore[attr-defined]

        response_data = _serialize_posts([post], user, request)

        # Broadcast via WebSocket (fire-and-forget)
        _broadcast_new_post(trainer.id, response_data[0])

        return Response(response_data[0], status=status.HTTP_201_CREATED)


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

        if not (is_author or is_group_trainer):
            return Response(
                {'error': "You don't have permission to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

        trainer_id = post.trainer_id
        post_id = post.id

        # Delete image file if exists
        if post.image:
            post.image.delete(save=False)

        post.delete()

        # Broadcast deletion via WebSocket
        _broadcast_post_deleted(trainer_id, post_id)

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
                # Race condition -- reaction already exists, treat as no-op
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


# ---------------------------------------------------------------------------
# Comments
# ---------------------------------------------------------------------------

class CommentPagination(PageNumberPagination):
    """Pagination for comments."""
    page_size = 30


class CommentListCreateView(views.APIView):
    """
    GET  /api/community/feed/<post_id>/comments/ -- list comments on a post.
    POST /api/community/feed/<post_id>/comments/ -- create a comment.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request, post_id: int) -> Response:
        user = cast(User, request.user)
        post = self._get_post(post_id, user)
        if post is None:
            return Response(
                {'error': 'Post not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        comments = (
            Comment.objects.filter(post=post)
            .select_related('author')
            .order_by('created_at')
        )

        paginator = CommentPagination()
        page = paginator.paginate_queryset(comments, request)
        serializer = CommentSerializer(
            page if page is not None else comments,
            many=True,
            context={'request': request},
        )

        if paginator.page is not None:
            return paginator.get_paginated_response(serializer.data)
        return Response(serializer.data)

    def post(self, request: Request, post_id: int) -> Response:
        user = cast(User, request.user)
        post = self._get_post(post_id, user)
        if post is None:
            return Response(
                {'error': 'Post not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = CreateCommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        comment = Comment.objects.create(
            post=post,
            author=user,
            content=serializer.validated_data['content'],
        )

        response_serializer = CommentSerializer(
            comment, context={'request': request},
        )

        # Send push notification to post author if commenter is not the author
        if post.author_id != user.id:
            _notify_post_comment(post, user)

        # Broadcast new comment via WebSocket
        _broadcast_new_comment(post.trainer_id, post_id, response_serializer.data)

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @staticmethod
    def _get_post(post_id: int, user: User) -> CommunityPost | None:
        """Get post, ensuring row-level security."""
        try:
            post = CommunityPost.objects.select_related('trainer').get(id=post_id)
        except CommunityPost.DoesNotExist:
            return None

        # Verify user is in the same trainer group
        if user.parent_trainer is None or post.trainer != user.parent_trainer:
            return None

        return post


class CommentDeleteView(views.APIView):
    """
    DELETE /api/community/feed/<post_id>/comments/<comment_id>/
    Author can delete own comment. Trainer can delete any comment.
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request: Request, post_id: int, comment_id: int) -> Response:
        user = cast(User, request.user)

        try:
            comment = Comment.objects.select_related(
                'author', 'post__trainer',
            ).get(id=comment_id, post_id=post_id)
        except Comment.DoesNotExist:
            return Response(
                {'error': 'Comment not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        is_author = comment.author == user
        is_group_trainer = user.is_trainer() and comment.post.trainer == user

        if not (is_author or is_group_trainer):
            return Response(
                {'error': "You don't have permission to delete this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )

        comment.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------------------------

class LeaderboardView(views.APIView):
    """
    GET /api/community/leaderboard/
    Returns leaderboard entries for the trainee's trainer group.
    Query params: metric_type (default workout_count), time_period (default weekly).
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'entries': [], 'my_rank': None})

        metric_type = request.query_params.get('metric_type', 'workout_count')
        time_period = request.query_params.get('time_period', 'weekly')

        # Check if this leaderboard is enabled
        is_enabled = Leaderboard.objects.filter(
            trainer=trainer,
            metric_type=metric_type,
            time_period=time_period,
            is_enabled=True,
        ).exists()

        if not is_enabled:
            return Response({
                'entries': [],
                'my_rank': None,
                'enabled': False,
            })

        from .services.leaderboard_service import compute_leaderboard

        entries = compute_leaderboard(
            trainer_id=trainer.id,
            metric_type=metric_type,
            time_period=time_period,
        )

        # Find current user's rank
        my_rank: int | None = None
        for entry in entries:
            if entry.user_id == user.id:
                my_rank = entry.rank
                break

        # Build image URLs
        entries_data = []
        for entry in entries:
            profile_image_url = None
            if entry.profile_image:
                profile_image_url = request.build_absolute_uri(
                    f'/media/{entry.profile_image}',
                )
            entries_data.append({
                'rank': entry.rank,
                'user_id': entry.user_id,
                'first_name': entry.first_name,
                'last_name': entry.last_name,
                'profile_image': profile_image_url,
                'value': entry.value,
            })

        return Response({
            'entries': entries_data,
            'my_rank': my_rank,
            'enabled': True,
        })


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


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

        image_url = None
        if post.image:
            image_url = request.build_absolute_uri(post.image.url)

        # comment_count is annotated on queryset, fallback to 0
        comment_count = getattr(post, 'comment_count', 0)

        result.append({
            'id': post.id,
            'author': author_data,
            'content': post.content,
            'post_type': post.post_type,
            'content_format': post.content_format,
            'image_url': image_url,
            'metadata': post.metadata,
            'comment_count': comment_count,
            'created_at': post.created_at,
            'reactions': reaction_map.get(post.id, {'fire': 0, 'thumbs_up': 0, 'heart': 0}),
            'user_reactions': user_reactions_map.get(post.id, []),
        })

    return result


def _broadcast_new_post(trainer_id: int, post_data: dict[str, Any]) -> None:
    """Broadcast new post to WebSocket group (fire-and-forget)."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'community_feed_{trainer_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'feed.new_post',
                'post': post_data,
            },
        )
    except Exception:
        logger.debug("Failed to broadcast new post to WebSocket", exc_info=True)


def _broadcast_post_deleted(trainer_id: int, post_id: int) -> None:
    """Broadcast post deletion to WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'community_feed_{trainer_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'feed.post_deleted',
                'post_id': post_id,
            },
        )
    except Exception:
        logger.debug("Failed to broadcast post deletion to WebSocket", exc_info=True)


def _broadcast_new_comment(
    trainer_id: int,
    post_id: int,
    comment_data: dict[str, Any],
) -> None:
    """Broadcast new comment to WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'community_feed_{trainer_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'feed.new_comment',
                'post_id': post_id,
                'comment': comment_data,
            },
        )
    except Exception:
        logger.debug("Failed to broadcast new comment to WebSocket", exc_info=True)


def _notify_post_comment(post: CommunityPost, commenter: User) -> None:
    """Send push notification to post author when someone comments."""
    try:
        from core.services.notification_service import send_push_notification

        send_push_notification(
            user_id=post.author_id,
            title='New Comment',
            body=f'{commenter.first_name} commented on your post',
            data={
                'type': 'community_comment',
                'post_id': str(post.id),
            },
        )
    except Exception:
        logger.debug("Failed to send comment notification", exc_info=True)

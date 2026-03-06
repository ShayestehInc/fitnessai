"""
Trainee-facing community views: announcements, achievements, community feed,
leaderboards, comments, spaces, bookmarks, courses, events, reports.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from django.db import IntegrityError
from django.db.models import Count, Exists, OuterRef, QuerySet, Subquery, Value
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
    Bookmark,
    BookmarkCollection,
    Comment,
    CommunityEvent,
    CommunityPost,
    ContentReport,
    Course,
    CourseEnrollment,
    CourseLesson,
    Leaderboard,
    LessonProgress,
    PostImage,
    PostReaction,
    Space,
    SpaceMembership,
    UserAchievement,
)
from .serializers import (
    AnnouncementSerializer,
    CommentReplySerializer,
    CommentSerializer,
    CommunityEventSerializer,
    ContentReportCreateSerializer,
    CourseDetailSerializer,
    CourseEnrollmentSerializer,
    CourseSerializer,
    CreateCommentSerializer,
    CreatePostSerializer,
    EventRSVPCreateSerializer,
    LessonProgressSerializer,
    LessonProgressUpdateSerializer,
    NewAchievementSerializer,
    ReactionToggleSerializer,
)
from .serializers.space_serializers import (
    SpaceCreateSerializer,
    SpaceMembershipSerializer,
    SpaceSerializer,
)
from .serializers.bookmark_serializers import (
    BookmarkCollectionCreateSerializer,
    BookmarkCollectionSerializer,
    BookmarkSerializer,
    BookmarkToggleSerializer,
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

_ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp'}
_MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5 MB


_MAX_IMAGES_PER_POST = 10


class CommunityFeedView(views.APIView):
    """
    GET  /api/community/feed/ -- paginated feed scoped to trainer group.
         Query params: ?space=<id>, ?sort=latest|popular
    POST /api/community/feed/ -- create a text post (with optional images).
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
            .select_related('author', 'space')
            .prefetch_related('images')
            .annotate(comment_count=Count('comments'))
        )

        # Filter by space
        space_id = request.query_params.get('space')
        if space_id is not None:
            queryset = queryset.filter(space_id=space_id)

        # Sort: latest (default) or popular (by reaction count + comments)
        sort = request.query_params.get('sort', 'latest')
        if sort == 'popular':
            queryset = queryset.annotate(
                reaction_count=Count('reactions'),
            ).order_by('-is_pinned', '-reaction_count', '-comment_count', '-created_at')
        else:
            queryset = queryset.order_by('-is_pinned', '-created_at')

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

        # Validate space if provided
        space_id = serializer.validated_data.get('space')
        space = None
        if space_id is not None:
            try:
                space = Space.objects.get(id=space_id, trainer=trainer)
            except Space.DoesNotExist:
                return Response(
                    {'error': 'Space not found.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Collect image files — support both 'images' (multiple) and 'image' (single, backward compat)
        image_files = request.FILES.getlist('images')
        single_image = request.FILES.get('image')
        if not image_files and single_image is not None:
            image_files = [single_image]

        if len(image_files) > _MAX_IMAGES_PER_POST:
            return Response(
                {'error': f'Maximum {_MAX_IMAGES_PER_POST} images per post.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate all images
        for img_file in image_files:
            if img_file.content_type not in _ALLOWED_IMAGE_TYPES:
                return Response(
                    {'error': f'Invalid image format for "{img_file.name}". Use JPEG, PNG, or WebP.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if img_file.size > _MAX_IMAGE_SIZE:
                return Response(
                    {'error': f'Image "{img_file.name}" must be under 5MB.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        post = CommunityPost.objects.create(
            author=user,
            trainer=trainer,
            space=space,
            content=serializer.validated_data['content'],
            content_format=serializer.validated_data.get(
                'content_format', CommunityPost.ContentFormat.PLAIN,
            ),
            post_type=CommunityPost.PostType.TEXT,
        )

        # Create PostImage records
        for idx, img_file in enumerate(image_files):
            PostImage.objects.create(post=post, image=img_file, sort_order=idx)

        # Annotate comment_count for serialization
        post.comment_count = 0  # type: ignore[attr-defined]

        response_data = _serialize_posts([post], user, request)

        # Broadcast via WebSocket (fire-and-forget)
        _broadcast_new_post(trainer.id, response_data[0], space_id=space.id if space else None)

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

        # Delete image files
        if post.image:
            post.image.delete(save=False)
        for post_image in post.images.all():
            post_image.image.delete(save=False)

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

        # Broadcast reaction update via WebSocket
        _broadcast_reaction_update(post.trainer_id, post_id, reactions)

        return Response({
            'reactions': reactions,
            'user_reactions': user_reactions,
        })


# ---------------------------------------------------------------------------
# Comments
# ---------------------------------------------------------------------------

class CommentPagination(PageNumberPagination):
    """Pagination for comments."""
    page_size = 20


class CommentListCreateView(views.APIView):
    """
    GET  /api/community/feed/<post_id>/comments/ -- list comments on a post.
    POST /api/community/feed/<post_id>/comments/ -- create a comment.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request, post_id: int) -> Response:
        user = cast(User, request.user)
        post, error_response = self._get_post(post_id, user)
        if error_response is not None:
            return error_response

        assert post is not None

        # Only return top-level comments; replies are nested via prefetch
        comments = (
            Comment.objects.filter(post=post, parent_comment__isnull=True)
            .select_related('author')
            .prefetch_related('replies__author')
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
        post, error_response = self._get_post(post_id, user)
        if error_response is not None:
            return error_response

        assert post is not None

        serializer = CreateCommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        parent_comment_id = serializer.validated_data.get('parent_comment')
        parent_comment = None
        if parent_comment_id is not None:
            try:
                parent_comment = Comment.objects.get(
                    id=parent_comment_id, post=post,
                )
                # Enforce single level of threading
                if parent_comment.parent_comment_id is not None:
                    parent_comment = parent_comment.parent_comment
            except Comment.DoesNotExist:
                return Response(
                    {'error': 'Parent comment not found.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        comment = Comment.objects.create(
            post=post,
            author=user,
            content=serializer.validated_data['content'],
            parent_comment=parent_comment,
        )

        response_serializer = CommentReplySerializer(
            comment, context={'request': request},
        )

        # Send push notification to post author if commenter is not the author
        if post.author_id != user.id:
            _notify_post_comment(post, user)

        # Broadcast new comment via WebSocket
        _broadcast_new_comment(post.trainer_id, post_id, response_serializer.data)

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @staticmethod
    def _get_post(
        post_id: int,
        user: User,
    ) -> tuple[CommunityPost | None, Response | None]:
        """
        Get post, ensuring row-level security.

        Returns (post, None) on success, or (None, error_response) on failure.
        Distinguishes 404 (not found) from 403 (wrong group).
        """
        try:
            post = CommunityPost.objects.select_related('trainer').get(id=post_id)
        except CommunityPost.DoesNotExist:
            return None, Response(
                {'error': 'Post not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Verify user is in the same trainer group
        if user.parent_trainer is None or post.trainer != user.parent_trainer:
            return None, Response(
                {'error': 'You do not have access to this post.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        return post, None


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

    _VALID_METRICS = {'workout_count', 'current_streak'}
    _VALID_PERIODS = {'weekly', 'monthly'}

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'entries': [], 'my_rank': None})

        metric_type = request.query_params.get('metric_type')
        time_period = request.query_params.get('time_period')

        if not metric_type or metric_type not in self._VALID_METRICS:
            return Response(
                {'error': 'metric_type is required and must be one of: workout_count, current_streak.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not time_period or time_period not in self._VALID_PERIODS:
            return Response(
                {'error': 'time_period is required and must be one of: weekly, monthly.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check if this leaderboard is explicitly disabled.
        # If no config exists, treat as enabled (default is_enabled=True per AC-1).
        leaderboard_config = Leaderboard.objects.filter(
            trainer=trainer,
            metric_type=metric_type,
            time_period=time_period,
        ).first()

        if leaderboard_config is not None and not leaderboard_config.is_enabled:
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
# Spaces
# ---------------------------------------------------------------------------


class SpaceListCreateView(views.APIView):
    """
    GET  /api/community/spaces/ -- list spaces for trainer group.
    POST /api/community/spaces/ -- create a space (trainer only).
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, JSONParser]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = _get_trainer_for_user(user)
        if trainer is None:
            return Response([])

        spaces = (
            Space.objects.filter(trainer=trainer)
            .annotate(
                member_count=Count('memberships'),
                is_member=Exists(
                    SpaceMembership.objects.filter(
                        space=OuterRef('pk'), user=user,
                    )
                ),
            )
        )

        serializer = SpaceSerializer(
            spaces, many=True, context={'request': request},
        )
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        if not user.is_trainer() and not user.is_admin():
            return Response(
                {'error': 'Only trainers can create spaces.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = SpaceCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .services.space_service import create_space

        try:
            space = create_space(
                trainer=user if user.is_trainer() else user,
                **serializer.validated_data,
            )
        except IntegrityError:
            return Response(
                {'error': 'A space with this name already exists.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Handle cover image
        cover_image = request.FILES.get('cover_image')
        if cover_image is not None:
            space.cover_image = cover_image
            space.save(update_fields=['cover_image'])

        out = SpaceSerializer(space, context={'request': request})
        return Response(out.data, status=status.HTTP_201_CREATED)


class SpaceDetailView(views.APIView):
    """
    GET    /api/community/spaces/<id>/ -- space detail.
    PUT    /api/community/spaces/<id>/ -- update space (trainer only).
    DELETE /api/community/spaces/<id>/ -- delete space (trainer only).
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, JSONParser]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        space = self._get_space(pk, user)
        if space is None:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)

        space_qs = Space.objects.filter(pk=pk).annotate(
            member_count=Count('memberships'),
            is_member=Exists(
                SpaceMembership.objects.filter(space=OuterRef('pk'), user=user)
            ),
        )
        serializer = SpaceSerializer(space_qs.first(), context={'request': request})
        return Response(serializer.data)

    def put(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        space = self._get_space(pk, user)
        if space is None:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)
        if space.trainer != user and not user.is_admin():
            return Response({'error': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = SpaceCreateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        for field, value in serializer.validated_data.items():
            setattr(space, field, value)

        cover_image = request.FILES.get('cover_image')
        if cover_image is not None:
            space.cover_image = cover_image

        space.save()
        out = SpaceSerializer(space, context={'request': request})
        return Response(out.data)

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        space = self._get_space(pk, user)
        if space is None:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)
        if space.trainer != user and not user.is_admin():
            return Response({'error': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        space.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @staticmethod
    def _get_space(pk: int, user: User) -> Space | None:
        trainer = _get_trainer_for_user(user)
        if trainer is None:
            return None
        try:
            return Space.objects.get(pk=pk, trainer=trainer)
        except Space.DoesNotExist:
            return None


class SpaceJoinView(views.APIView):
    """POST /api/community/spaces/<id>/join/ -- join a space."""
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'error': 'No trainer assigned.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            space = Space.objects.get(pk=pk, trainer=trainer)
        except Space.DoesNotExist:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .services.space_service import join_space

        try:
            membership = join_space(space=space, user=user)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)

        return Response({
            'joined': True,
            'role': membership.role,
            'space_id': space.id,
        })


class SpaceLeaveView(views.APIView):
    """POST /api/community/spaces/<id>/leave/ -- leave a space."""
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if trainer is None:
            return Response({'error': 'No trainer assigned.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            space = Space.objects.get(pk=pk, trainer=trainer)
        except Space.DoesNotExist:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .services.space_service import leave_space

        try:
            leave_space(space=space, user=user)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response({'left': True, 'space_id': space.id})


class SpaceMembersView(views.APIView):
    """GET /api/community/spaces/<id>/members/ -- list space members."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = _get_trainer_for_user(user)
        if trainer is None:
            return Response([])

        try:
            space = Space.objects.get(pk=pk, trainer=trainer)
        except Space.DoesNotExist:
            return Response({'error': 'Space not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .services.space_service import get_space_members

        members = get_space_members(space)
        serializer = SpaceMembershipSerializer(
            members, many=True, context={'request': request},
        )
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Bookmarks
# ---------------------------------------------------------------------------


class BookmarkToggleView(views.APIView):
    """POST /api/community/bookmarks/toggle/ -- toggle bookmark on a post."""
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        serializer = BookmarkToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        post_id = serializer.validated_data['post_id']
        try:
            post = CommunityPost.objects.get(id=post_id)
        except CommunityPost.DoesNotExist:
            return Response({'error': 'Post not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Row-level security
        if user.parent_trainer is None or post.trainer != user.parent_trainer:
            return Response({'error': 'Access denied.'}, status=status.HTTP_403_FORBIDDEN)

        from .services.bookmark_service import toggle_bookmark

        result = toggle_bookmark(user=user, post=post)
        return Response({
            'is_bookmarked': result.is_bookmarked,
            'bookmark_id': result.bookmark_id,
        })


class BookmarkListView(views.APIView):
    """GET /api/community/bookmarks/ -- list user's bookmarked posts."""
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)

        collection_id = request.query_params.get('collection')
        collection_id_int = int(collection_id) if collection_id else None

        from .services.bookmark_service import get_user_bookmarks

        bookmarks = get_user_bookmarks(user, collection_id=collection_id_int)

        # Serialize as full posts
        posts = [b.post for b in bookmarks]
        for post in posts:
            post.comment_count = 0  # type: ignore[attr-defined]

        data = _serialize_posts(posts, user, request)
        return Response(data)


class BookmarkCollectionListCreateView(views.APIView):
    """
    GET  /api/community/bookmark-collections/ -- list collections.
    POST /api/community/bookmark-collections/ -- create collection.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        from .services.bookmark_service import get_user_collections

        collections = get_user_collections(user).annotate(
            bookmark_count=Count('bookmarks'),
        )
        serializer = BookmarkCollectionSerializer(collections, many=True)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        serializer = BookmarkCollectionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .services.bookmark_service import create_collection

        try:
            collection = create_collection(
                user=user,
                name=serializer.validated_data['name'],
            )
        except IntegrityError:
            return Response(
                {'error': 'A collection with this name already exists.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        out = BookmarkCollectionSerializer(collection)
        return Response(out.data, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_trainer_for_user(user: User) -> User | None:
    """Get the trainer for any user (trainee → parent, trainer → self)."""
    if user.is_trainee():
        return user.parent_trainer
    if user.is_trainer():
        return user
    if user.is_admin():
        return user  # Admin can access everything; caller may further restrict
    return None


def _serialize_posts(
    posts: list[CommunityPost],
    current_user: User,
    request: Request,
) -> list[dict[str, Any]]:
    """Serialize a list of posts with reaction aggregates, user_reactions, images, bookmarks."""
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

    # Bookmarked post IDs
    from .services.bookmark_service import get_user_bookmarked_post_ids
    bookmarked_ids = get_user_bookmarked_post_ids(current_user, post_ids)

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

        # Legacy single image (backward compat)
        image_url = None
        if post.image:
            image_url = request.build_absolute_uri(post.image.url)

        # Multi-image: use prefetched images relation
        images: list[dict[str, Any]] = []
        post_images = getattr(post, '_prefetched_objects_cache', {}).get('images')
        if post_images is None:
            post_images = post.images.all()
        for pi in post_images:
            images.append({
                'id': pi.id,
                'url': request.build_absolute_uri(pi.image.url),
                'sort_order': pi.sort_order,
            })

        # If no PostImage records but legacy image exists, include it
        if not images and image_url:
            images.append({'id': None, 'url': image_url, 'sort_order': 0})

        # Space info
        space_data = None
        if post.space is not None:
            space_data = {
                'id': post.space.id,
                'name': post.space.name,
                'emoji': post.space.emoji,
            }

        # comment_count is annotated on queryset, fallback to 0
        comment_count = getattr(post, 'comment_count', 0)

        result.append({
            'id': post.id,
            'author': author_data,
            'content': post.content,
            'post_type': post.post_type,
            'content_format': post.content_format,
            'image_url': image_url,  # Kept for backward compat
            'images': images,
            'space': space_data,
            'is_pinned': post.is_pinned,
            'is_bookmarked': post.id in bookmarked_ids,
            'metadata': post.metadata,
            'comment_count': comment_count,
            'created_at': post.created_at,
            'reactions': reaction_map.get(post.id, {'fire': 0, 'thumbs_up': 0, 'heart': 0}),
            'user_reactions': user_reactions_map.get(post.id, []),
        })

    return result


def _broadcast_new_post(
    trainer_id: int,
    post_data: dict[str, Any],
    space_id: int | None = None,
) -> None:
    """Broadcast new post to WebSocket group (fire-and-forget)."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        msg = {
            'type': 'feed.new_post',
            'post': post_data,
            'timestamp': timezone.now().isoformat(),
        }

        # Broadcast to trainer-level group
        group_name = f'community_feed_{trainer_id}'
        async_to_sync(channel_layer.group_send)(group_name, msg)

        # Also broadcast to space-specific group if applicable
        if space_id is not None:
            space_group = f'community_space_{space_id}'
            async_to_sync(channel_layer.group_send)(space_group, msg)
    except Exception:
        logger.warning("Failed to broadcast new post to WebSocket", exc_info=True)


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
                'timestamp': timezone.now().isoformat(),
            },
        )
    except Exception:
        logger.warning("Failed to broadcast post deletion to WebSocket", exc_info=True)


def _broadcast_reaction_update(
    trainer_id: int,
    post_id: int,
    reactions: dict[str, int],
) -> None:
    """Broadcast reaction update to WebSocket group."""
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
                'type': 'feed.reaction_update',
                'post_id': post_id,
                'reactions': reactions,
                'timestamp': timezone.now().isoformat(),
            },
        )
    except Exception:
        logger.warning("Failed to broadcast reaction update to WebSocket", exc_info=True)


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
                'timestamp': timezone.now().isoformat(),
            },
        )
    except Exception:
        logger.warning("Failed to broadcast new comment to WebSocket", exc_info=True)


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
            category='community_activity',
        )
    except Exception:
        logger.warning("Failed to send comment notification", exc_info=True)


# ===========================================================================
# Phase 2 — Classroom (Trainee-facing)
# ===========================================================================

class TraineeCourseListView(generics.ListAPIView[Course]):
    """
    GET /api/community/courses/ — List published courses for trainee's trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainee]
    serializer_class = CourseSerializer

    def get_queryset(self) -> QuerySet[Course]:
        user = cast(User, self.request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Course.objects.none()
        return (
            Course.objects.filter(
                trainer=trainer,
                status=Course.Status.PUBLISHED,
            )
            .annotate(
                lesson_count=Count('lessons'),
                enrollment_count=Count('enrollments'),
            )
            .order_by('sort_order', '-created_at')
        )


class TraineeCourseDetailView(views.APIView):
    """
    GET /api/community/courses/<id>/ — Course detail with lessons + drip availability.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            course = (
                Course.objects.filter(
                    id=pk, trainer=trainer, status=Course.Status.PUBLISHED,
                )
                .annotate(
                    lesson_count=Count('lessons'),
                    enrollment_count=Count('enrollments'),
                )
                .prefetch_related('lessons')
                .get()
            )
        except Course.DoesNotExist:
            return Response(
                {'error': 'Course not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        course_data = CourseDetailSerializer(course).data

        # Add enrollment and lesson availability info
        enrollment = CourseEnrollment.objects.filter(
            course=course, user=user,
        ).first()

        course_data['is_enrolled'] = enrollment is not None
        if enrollment:
            from .services.classroom_service import ClassroomService
            availability = ClassroomService.get_all_lesson_availability(enrollment)
            progress_qs = LessonProgress.objects.filter(enrollment=enrollment)
            progress_map = {p.lesson_id: p.status for p in progress_qs}

            for lesson_data in course_data.get('lessons', []):
                lesson_id = lesson_data['id']
                avail = next((a for a in availability if a.lesson.id == lesson_id), None)
                lesson_data['is_unlocked'] = avail.is_unlocked if avail else True
                lesson_data['unlocks_at'] = avail.unlocks_at if avail else None
                lesson_data['progress_status'] = progress_map.get(
                    lesson_id, LessonProgress.ProgressStatus.NOT_STARTED,
                )

        return Response(course_data)


class TraineeCourseEnrollView(views.APIView):
    """
    POST /api/community/courses/<id>/enroll/ — Enroll in a course.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            course = Course.objects.get(
                id=pk, trainer=trainer, status=Course.Status.PUBLISHED,
            )
        except Course.DoesNotExist:
            return Response(
                {'error': 'Course not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from .services.classroom_service import ClassroomService
        result = ClassroomService.enroll_trainee(course, user)
        serializer = CourseEnrollmentSerializer(result.enrollment)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if result.created else status.HTTP_200_OK,
        )


class TraineeMyEnrollmentsView(generics.ListAPIView[CourseEnrollment]):
    """
    GET /api/community/my-enrollments/ — List trainee's enrollments.
    """
    permission_classes = [IsAuthenticated, IsTrainee]
    serializer_class = CourseEnrollmentSerializer

    def get_queryset(self) -> QuerySet[CourseEnrollment]:
        user = cast(User, self.request.user)
        return (
            CourseEnrollment.objects.filter(user=user)
            .select_related('course')
            .order_by('-enrolled_at')
        )


class TraineeLessonProgressView(views.APIView):
    """
    PATCH /api/community/courses/<course_id>/lessons/<lesson_id>/progress/
    Body: {"status": "in_progress" | "completed"}
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def patch(self, request: Request, course_id: int, lesson_id: int) -> Response:
        user = cast(User, request.user)

        try:
            enrollment = CourseEnrollment.objects.get(
                course_id=course_id, user=user,
            )
        except CourseEnrollment.DoesNotExist:
            return Response(
                {'error': 'Not enrolled in this course.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            lesson = CourseLesson.objects.get(
                id=lesson_id, course_id=course_id,
            )
        except CourseLesson.DoesNotExist:
            return Response(
                {'error': 'Lesson not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Check drip availability
        from .services.classroom_service import ClassroomService
        avail = ClassroomService.get_lesson_availability(enrollment, lesson)
        if not avail.is_unlocked:
            return Response(
                {'error': f'Lesson locked until {avail.unlocks_at}.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = LessonProgressUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        progress = ClassroomService.mark_lesson_progress(
            enrollment, lesson, serializer.validated_data['status'],
        )
        response_serializer = LessonProgressSerializer(progress)
        return Response(response_serializer.data)


# ===========================================================================
# Phase 3 — Events (Trainee-facing)
# ===========================================================================

class TraineeEventListView(generics.ListAPIView[CommunityEvent]):
    """
    GET /api/community/events/ — List upcoming events for trainee's trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainee]
    serializer_class = CommunityEventSerializer

    def get_queryset(self) -> QuerySet[CommunityEvent]:
        user = cast(User, self.request.user)
        trainer = user.parent_trainer
        if not trainer:
            return CommunityEvent.objects.none()
        return (
            CommunityEvent.objects.filter(
                trainer=trainer,
                status__in=[
                    CommunityEvent.EventStatus.SCHEDULED,
                    CommunityEvent.EventStatus.LIVE,
                ],
            )
            .prefetch_related('rsvps')
            .order_by('starts_at')
        )

    def get_serializer_context(self) -> dict[str, Any]:
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx


class TraineeEventDetailView(views.APIView):
    """
    GET /api/community/events/<id>/ — Event detail.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            event = CommunityEvent.objects.prefetch_related('rsvps').get(
                id=pk, trainer=trainer,
            )
        except CommunityEvent.DoesNotExist:
            return Response(
                {'error': 'Event not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = CommunityEventSerializer(event, context={'request': request})
        return Response(serializer.data)


class TraineeEventRSVPView(views.APIView):
    """
    POST   /api/community/events/<id>/rsvp/ — RSVP to an event.
    DELETE /api/community/events/<id>/rsvp/ — Cancel RSVP.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            event = CommunityEvent.objects.get(id=pk, trainer=trainer)
        except CommunityEvent.DoesNotExist:
            return Response(
                {'error': 'Event not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = EventRSVPCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .services.event_service import EventService
        result = EventService.rsvp(event, user, serializer.validated_data['status'])

        response_data: dict[str, Any] = {'status': result.rsvp.status}
        if result.at_capacity:
            response_data['warning'] = 'Event is at capacity. RSVP set to maybe.'

        return Response(
            response_data,
            status=status.HTTP_201_CREATED if result.created else status.HTTP_200_OK,
        )

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            event = CommunityEvent.objects.get(id=pk, trainer=trainer)
        except CommunityEvent.DoesNotExist:
            return Response(
                {'error': 'Event not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from .services.event_service import EventService
        deleted = EventService.cancel_rsvp(event, user)
        if not deleted:
            return Response(
                {'error': 'No RSVP found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


# ===========================================================================
# Phase 4 — Content Reporting (Trainee-facing)
# ===========================================================================

class TraineeReportContentView(views.APIView):
    """
    POST /api/community/report/ — Report a post or comment.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer
        if not trainer:
            return Response(
                {'error': 'No trainer assigned.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ContentReportCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        post = None
        comment = None
        if data['content_type'] == 'post' and data.get('post_id'):
            try:
                post = CommunityPost.objects.get(id=data['post_id'], trainer=trainer)
            except CommunityPost.DoesNotExist:
                return Response(
                    {'error': 'Post not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
        elif data['content_type'] == 'comment' and data.get('comment_id'):
            from .models import Comment as CommentModel
            try:
                comment = CommentModel.objects.select_related('post').get(
                    id=data['comment_id'], post__trainer=trainer,
                )
            except CommentModel.DoesNotExist:
                return Response(
                    {'error': 'Comment not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )

        from .services.moderation_service import ModerationService
        report = ModerationService.create_report(
            reporter=user,
            trainer=trainer,
            content_type=data['content_type'],
            reason=data['reason'],
            details=data.get('details', ''),
            post=post,
            comment=comment,
        )
        return Response(
            {'id': report.id, 'status': report.status},
            status=status.HTTP_201_CREATED,
        )

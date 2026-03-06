"""
Trainer-facing views: announcements, leaderboard, courses, events, moderation, config.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from django.db.models import Count, QuerySet
from rest_framework import generics, status, views
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainer
from users.models import User

from .models import (
    Announcement,
    AutoModRule,
    CommunityConfig,
    CommunityEvent,
    ContentReport,
    Course,
    CourseEnrollment,
    CourseLesson,
    EventRSVP,
    Leaderboard,
    LessonProgress,
    UserBan,
)
from .serializers import (
    AnnouncementCreateSerializer,
    AnnouncementSerializer,
    AutoModRuleCreateSerializer,
    AutoModRuleSerializer,
    CommunityConfigSerializer,
    CommunityEventCreateSerializer,
    CommunityEventSerializer,
    ContentReportSerializer,
    CourseCreateSerializer,
    CourseDetailSerializer,
    CourseLessonCreateSerializer,
    CourseLessonSerializer,
    CourseSerializer,
    LeaderboardSettingsSerializer,
    ReportReviewSerializer,
    UserBanCreateSerializer,
    UserBanSerializer,
)

logger = logging.getLogger(__name__)


class TrainerAnnouncementListCreateView(generics.ListCreateAPIView[Announcement]):
    """
    GET  /api/trainer/announcements/ -- List trainer's own announcements.
    POST /api/trainer/announcements/ -- Create a new announcement.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = AnnouncementSerializer

    def get_queryset(self) -> QuerySet[Announcement]:
        user = cast(User, self.request.user)
        return Announcement.objects.filter(trainer=user).order_by('-is_pinned', '-created_at')

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        user = cast(User, request.user)

        create_serializer = AnnouncementCreateSerializer(data=request.data)
        create_serializer.is_valid(raise_exception=True)

        announcement = Announcement.objects.create(
            trainer=user,
            title=create_serializer.validated_data['title'],
            body=create_serializer.validated_data['body'],
            is_pinned=create_serializer.validated_data.get('is_pinned', False),
            content_format=create_serializer.validated_data.get(
                'content_format', Announcement.ContentFormat.PLAIN,
            ),
        )

        # Send push notification to all trainees (fire-and-forget)
        _notify_trainees_announcement(user, announcement)

        response_serializer = AnnouncementSerializer(announcement)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerAnnouncementDetailView(views.APIView):
    """
    PUT    /api/trainer/announcements/<id>/ — Update an announcement.
    DELETE /api/trainer/announcements/<id>/ — Delete an announcement.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def put(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        try:
            announcement = Announcement.objects.get(id=pk, trainer=user)
        except Announcement.DoesNotExist:
            return Response(
                {'error': 'Announcement not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = AnnouncementCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        announcement.title = serializer.validated_data['title']
        announcement.body = serializer.validated_data['body']
        announcement.is_pinned = serializer.validated_data.get('is_pinned', False)
        announcement.content_format = serializer.validated_data.get(
            'content_format', Announcement.ContentFormat.PLAIN,
        )
        announcement.save(update_fields=[
            'title', 'body', 'is_pinned', 'content_format', 'updated_at',
        ])

        response_serializer = AnnouncementSerializer(announcement)
        return Response(response_serializer.data)

    def patch(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        try:
            announcement = Announcement.objects.get(id=pk, trainer=user)
        except Announcement.DoesNotExist:
            return Response(
                {'error': 'Announcement not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = AnnouncementCreateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        update_fields: list[str] = ['updated_at']
        for field in ('title', 'body', 'is_pinned', 'content_format'):
            if field in serializer.validated_data:
                setattr(announcement, field, serializer.validated_data[field])
                update_fields.append(field)

        announcement.save(update_fields=update_fields)

        response_serializer = AnnouncementSerializer(announcement)
        return Response(response_serializer.data)

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        try:
            announcement = Announcement.objects.get(id=pk, trainer=user)
        except Announcement.DoesNotExist:
            return Response(
                {'error': 'Announcement not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        announcement.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Leaderboard Settings (Trainer)
# ---------------------------------------------------------------------------

class TrainerLeaderboardSettingsView(views.APIView):
    """
    GET  /api/trainer/leaderboard-settings/ -- list all leaderboard configs.
    POST /api/trainer/leaderboard-settings/ -- upsert a leaderboard config.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        leaderboards = Leaderboard.objects.filter(trainer=user)
        data = [
            {
                'id': lb.id,
                'metric_type': lb.metric_type,
                'time_period': lb.time_period,
                'is_enabled': lb.is_enabled,
            }
            for lb in leaderboards
        ]
        return Response(data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)

        serializer = LeaderboardSettingsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        leaderboard, created = Leaderboard.objects.update_or_create(
            trainer=user,
            metric_type=serializer.validated_data['metric_type'],
            time_period=serializer.validated_data['time_period'],
            defaults={
                'is_enabled': serializer.validated_data['is_enabled'],
            },
        )

        return Response(
            {
                'id': leaderboard.id,
                'metric_type': leaderboard.metric_type,
                'time_period': leaderboard.time_period,
                'is_enabled': leaderboard.is_enabled,
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _notify_trainees_announcement(
    trainer: User,
    announcement: Announcement,
) -> None:
    """Send push notification to all trainer's trainees about new announcement."""
    try:
        from core.services.notification_service import send_push_to_group

        trainee_ids = list(
            User.objects.filter(
                parent_trainer=trainer,
                role=User.Role.TRAINEE,
                is_active=True,
            ).values_list('id', flat=True)
        )

        if trainee_ids:
            send_push_to_group(
                user_ids=trainee_ids,
                title=f'New Announcement: {announcement.title}',
                body=announcement.body[:100],
                data={
                    'type': 'announcement',
                    'announcement_id': str(announcement.id),
                },
                category='trainer_announcement',
            )
    except Exception:
        logger.warning("Failed to send announcement push notifications", exc_info=True)


# ===========================================================================
# Phase 2 — Classroom (Trainer CRUD)
# ===========================================================================

class TrainerCourseListCreateView(generics.ListCreateAPIView[Course]):
    """
    GET  /api/trainer/courses/ — List trainer's courses.
    POST /api/trainer/courses/ — Create a new course.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = CourseSerializer

    def get_queryset(self) -> QuerySet[Course]:
        user = cast(User, self.request.user)
        return (
            Course.objects.filter(trainer=user)
            .annotate(
                lesson_count=Count('lessons'),
                enrollment_count=Count('enrollments'),
            )
            .order_by('sort_order', '-created_at')
        )

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        user = cast(User, request.user)
        serializer = CourseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        space = None
        if data.get('space'):
            from .models import Space
            try:
                space = Space.objects.get(id=data['space'], trainer=user)
            except Space.DoesNotExist:
                return Response(
                    {'error': 'Space not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )

        course = Course.objects.create(
            trainer=user,
            space=space,
            title=data['title'],
            description=data.get('description', ''),
            status=data.get('status', Course.Status.DRAFT),
            drip_enabled=data.get('drip_enabled', False),
            is_mandatory=data.get('is_mandatory', False),
            sort_order=data.get('sort_order', 0),
        )
        response_serializer = CourseSerializer(course)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerCourseDetailView(views.APIView):
    """
    GET    /api/trainer/courses/<id>/ — Course detail with lessons.
    PUT    /api/trainer/courses/<id>/ — Update course.
    DELETE /api/trainer/courses/<id>/ — Delete course.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            course = (
                Course.objects.filter(trainer=user, id=pk)
                .annotate(
                    lesson_count=Count('lessons'),
                    enrollment_count=Count('enrollments'),
                )
                .prefetch_related('lessons')
                .get()
            )
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CourseDetailSerializer(course)
        return Response(serializer.data)

    def put(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            course = Course.objects.get(id=pk, trainer=user)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CourseCreateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        update_fields: list[str] = ['updated_at']
        for field in ('title', 'description', 'status', 'drip_enabled', 'is_mandatory', 'sort_order'):
            if field in serializer.validated_data:
                setattr(course, field, serializer.validated_data[field])
                update_fields.append(field)

        course.save(update_fields=update_fields)

        # Auto-enroll if newly published and mandatory
        if course.status == Course.Status.PUBLISHED and course.is_mandatory:
            from .services.classroom_service import ClassroomService
            trainees = User.objects.filter(
                parent_trainer=user, role=User.Role.TRAINEE, is_active=True,
            )
            for trainee in trainees:
                ClassroomService.enroll_trainee(course, trainee)

        response_serializer = CourseSerializer(course)
        return Response(response_serializer.data)

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            course = Course.objects.get(id=pk, trainer=user)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)
        course.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TrainerLessonListCreateView(views.APIView):
    """
    GET  /api/trainer/courses/<course_id>/lessons/ — List lessons.
    POST /api/trainer/courses/<course_id>/lessons/ — Create a lesson.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, course_id: int) -> Response:
        user = cast(User, request.user)
        try:
            course = Course.objects.get(id=course_id, trainer=user)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)

        lessons = course.lessons.all()
        serializer = CourseLessonSerializer(lessons, many=True)
        return Response(serializer.data)

    def post(self, request: Request, course_id: int) -> Response:
        user = cast(User, request.user)
        try:
            course = Course.objects.get(id=course_id, trainer=user)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CourseLessonCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        lesson = CourseLesson.objects.create(
            course=course,
            title=data['title'],
            content_type=data.get('content_type', CourseLesson.ContentType.TEXT),
            text_content=data.get('text_content', ''),
            video_url=data.get('video_url', ''),
            sort_order=data.get('sort_order', 0),
            drip_delay_days=data.get('drip_delay_days', 0),
            estimated_minutes=data.get('estimated_minutes', 0),
        )
        response_serializer = CourseLessonSerializer(lesson)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerLessonDetailView(views.APIView):
    """
    PUT    /api/trainer/courses/<course_id>/lessons/<id>/ — Update lesson.
    DELETE /api/trainer/courses/<course_id>/lessons/<id>/ — Delete lesson.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def put(self, request: Request, course_id: int, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            lesson = CourseLesson.objects.select_related('course').get(
                id=pk, course_id=course_id, course__trainer=user,
            )
        except CourseLesson.DoesNotExist:
            return Response({'error': 'Lesson not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CourseLessonCreateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        update_fields: list[str] = ['updated_at']
        for field in ('title', 'content_type', 'text_content', 'video_url',
                       'sort_order', 'drip_delay_days', 'estimated_minutes'):
            if field in serializer.validated_data:
                setattr(lesson, field, serializer.validated_data[field])
                update_fields.append(field)

        lesson.save(update_fields=update_fields)
        response_serializer = CourseLessonSerializer(lesson)
        return Response(response_serializer.data)

    def delete(self, request: Request, course_id: int, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            lesson = CourseLesson.objects.select_related('course').get(
                id=pk, course_id=course_id, course__trainer=user,
            )
        except CourseLesson.DoesNotExist:
            return Response({'error': 'Lesson not found.'}, status=status.HTTP_404_NOT_FOUND)
        lesson.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ===========================================================================
# Phase 3 — Events (Trainer CRUD)
# ===========================================================================

class TrainerEventListCreateView(generics.ListCreateAPIView[CommunityEvent]):
    """
    GET  /api/trainer/events/ — List trainer's events.
    POST /api/trainer/events/ — Create a new event.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = CommunityEventSerializer

    def get_queryset(self) -> QuerySet[CommunityEvent]:
        user = cast(User, self.request.user)
        return CommunityEvent.objects.filter(trainer=user).prefetch_related('rsvps')

    def get_serializer_context(self) -> dict[str, Any]:
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        user = cast(User, request.user)
        serializer = CommunityEventCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        space = None
        if data.get('space'):
            from .models import Space
            try:
                space = Space.objects.get(id=data['space'], trainer=user)
            except Space.DoesNotExist:
                return Response(
                    {'error': 'Space not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )

        event = CommunityEvent.objects.create(
            trainer=user,
            space=space,
            title=data['title'],
            description=data.get('description', ''),
            event_type=data.get('event_type', CommunityEvent.EventType.LIVE_SESSION),
            starts_at=data['starts_at'],
            ends_at=data['ends_at'],
            meeting_url=data.get('meeting_url', ''),
            max_attendees=data.get('max_attendees'),
            is_recurring=data.get('is_recurring', False),
            recurrence_rule=data.get('recurrence_rule', {}),
        )

        # Send push notification to all trainees (fire-and-forget)
        from .services.event_service import EventService
        EventService.notify_event_created(event)

        response_serializer = CommunityEventSerializer(
            event, context={'request': request},
        )
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerEventDetailView(views.APIView):
    """
    GET    /api/trainer/events/<id>/ — Event detail with RSVPs.
    PUT    /api/trainer/events/<id>/ — Update event.
    DELETE /api/trainer/events/<id>/ — Delete (cancel) event.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            event = CommunityEvent.objects.prefetch_related(
                'rsvps__user',
            ).get(id=pk, trainer=user)
        except CommunityEvent.DoesNotExist:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CommunityEventSerializer(event, context={'request': request})
        return Response(serializer.data)

    def put(self, request: Request, pk: int) -> Response:
        return self._update(request, pk, partial=False)

    def patch(self, request: Request, pk: int) -> Response:
        return self._update(request, pk, partial=True)

    def _update(self, request: Request, pk: int, *, partial: bool) -> Response:
        user = cast(User, request.user)
        try:
            event = CommunityEvent.objects.get(id=pk, trainer=user)
        except CommunityEvent.DoesNotExist:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CommunityEventCreateSerializer(data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)

        # Track whether time/location changed for notification
        notify_fields = {'starts_at', 'ends_at', 'meeting_url'}
        changed_fields = set(serializer.validated_data.keys())
        should_notify = bool(changed_fields & notify_fields)

        update_fields: list[str] = ['updated_at']
        for field in ('title', 'description', 'event_type', 'starts_at', 'ends_at',
                       'meeting_url', 'max_attendees', 'is_recurring', 'recurrence_rule'):
            if field in serializer.validated_data:
                setattr(event, field, serializer.validated_data[field])
                update_fields.append(field)

        event.save(update_fields=update_fields)

        # Notify RSVP'd users if time/location changed (fire-and-forget)
        if should_notify and event.status == CommunityEvent.EventStatus.SCHEDULED:
            from .services.event_service import EventService
            EventService.notify_event_updated(event)

        response_serializer = CommunityEventSerializer(event, context={'request': request})
        return Response(response_serializer.data)

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            event = CommunityEvent.objects.get(id=pk, trainer=user)
        except CommunityEvent.DoesNotExist:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .services.event_service import EventService
        EventService.transition_status(event, CommunityEvent.EventStatus.CANCELLED)

        # Notify RSVP'd users about cancellation (fire-and-forget)
        EventService.notify_event_cancelled(event)

        return Response(status=status.HTTP_204_NO_CONTENT)


class TrainerEventStatusView(views.APIView):
    """
    PATCH /api/trainer/events/<id>/status/ — Transition event status.
    Body: {"status": "live" | "completed" | "cancelled"}
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def patch(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            event = CommunityEvent.objects.get(id=pk, trainer=user)
        except CommunityEvent.DoesNotExist:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        valid_statuses = dict(CommunityEvent.EventStatus.choices)
        if new_status not in valid_statuses:
            return Response(
                {'error': f'Invalid status. Must be one of: {", ".join(valid_statuses.keys())}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from .services.event_service import EventService
        EventService.transition_status(event, new_status)

        # Notify RSVP'd users if event was cancelled via status transition
        if new_status == CommunityEvent.EventStatus.CANCELLED:
            EventService.notify_event_cancelled(event)

        serializer = CommunityEventSerializer(event, context={'request': request})
        return Response(serializer.data)


# ===========================================================================
# Phase 4 — Moderation (Trainer views)
# ===========================================================================

class ModerationPagination(PageNumberPagination):
    page_size = 20
    max_page_size = 50


class TrainerReportListView(generics.ListAPIView[ContentReport]):
    """
    GET /api/trainer/moderation/reports/ — List reports for trainer's community.
    Query params: ?status=pending (filter by status)
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = ContentReportSerializer
    pagination_class = ModerationPagination

    def get_queryset(self) -> QuerySet[ContentReport]:
        user = cast(User, self.request.user)
        qs = ContentReport.objects.filter(
            trainer=user,
        ).select_related('reporter', 'reviewed_by')

        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs


class TrainerReportReviewView(views.APIView):
    """
    POST /api/trainer/moderation/reports/<id>/review/ — Review a report.
    Body: {"action_type": "...", "reason": "..."}
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            report = ContentReport.objects.get(id=pk, trainer=user)
        except ContentReport.DoesNotExist:
            return Response({'error': 'Report not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = ReportReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .services.moderation_service import ModerationService

        if serializer.validated_data['action_type'] == 'dismiss':
            ModerationService.dismiss_report(report, user)
            return Response({'status': 'dismissed'})

        action = ModerationService.review_report(
            report=report,
            reviewer=user,
            action_type=serializer.validated_data['action_type'],
            reason=serializer.validated_data.get('reason', ''),
        )
        return Response({
            'status': 'action_taken',
            'action_type': action.action_type,
            'report_status': report.status,
        })


class TrainerBanListCreateView(views.APIView):
    """
    GET  /api/trainer/moderation/bans/ — List active bans.
    POST /api/trainer/moderation/bans/ — Ban a user.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        bans = UserBan.objects.filter(
            trainer=user, is_active=True,
        ).select_related('user', 'banned_by').order_by('-created_at')
        serializer = UserBanSerializer(bans, many=True)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        serializer = UserBanCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            target_user = User.objects.get(
                id=data['user_id'],
                parent_trainer=user,
                role=User.Role.TRAINEE,
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found or not your trainee.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from .services.moderation_service import ModerationService
        ban = ModerationService.ban_user(
            user=target_user,
            trainer=user,
            banned_by=user,
            reason=data['reason'],
            is_permanent=data.get('is_permanent', False),
            duration_days=data.get('duration_days'),
        )
        response_serializer = UserBanSerializer(ban)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerUnbanView(views.APIView):
    """
    DELETE /api/trainer/moderation/bans/<user_id>/ — Unban a user.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def delete(self, request: Request, user_id: int) -> Response:
        user = cast(User, request.user)
        try:
            target_user = User.objects.get(
                id=user_id,
                parent_trainer=user,
                role=User.Role.TRAINEE,
            )
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .services.moderation_service import ModerationService
        updated = ModerationService.unban_user(target_user, user)
        if not updated:
            return Response(
                {'error': 'No active ban found for this user.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class TrainerAutoModRuleListCreateView(views.APIView):
    """
    GET  /api/trainer/moderation/rules/ — List auto-mod rules.
    POST /api/trainer/moderation/rules/ — Create a rule.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        rules = AutoModRule.objects.filter(trainer=user)
        serializer = AutoModRuleSerializer(rules, many=True)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        serializer = AutoModRuleCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        rule = AutoModRule.objects.create(
            trainer=user,
            rule_type=data['rule_type'],
            config=data['config'],
            action=data.get('action', AutoModRule.RuleAction.FLAG),
            is_enabled=data.get('is_enabled', True),
        )
        response_serializer = AutoModRuleSerializer(rule)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class TrainerAutoModRuleDetailView(views.APIView):
    """
    PUT    /api/trainer/moderation/rules/<id>/ — Update rule.
    DELETE /api/trainer/moderation/rules/<id>/ — Delete rule.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def put(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            rule = AutoModRule.objects.get(id=pk, trainer=user)
        except AutoModRule.DoesNotExist:
            return Response({'error': 'Rule not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = AutoModRuleCreateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        update_fields: list[str] = ['updated_at']
        for field in ('rule_type', 'config', 'action', 'is_enabled'):
            if field in serializer.validated_data:
                setattr(rule, field, serializer.validated_data[field])
                update_fields.append(field)

        rule.save(update_fields=update_fields)
        response_serializer = AutoModRuleSerializer(rule)
        return Response(response_serializer.data)

    def delete(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            rule = AutoModRule.objects.get(id=pk, trainer=user)
        except AutoModRule.DoesNotExist:
            return Response({'error': 'Rule not found.'}, status=status.HTTP_404_NOT_FOUND)
        rule.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ===========================================================================
# Phase 5 — Community Config (Admin Builder)
# ===========================================================================

class TrainerCommunityConfigView(views.APIView):
    """
    GET  /api/trainer/community-config/ — Get community configuration.
    PUT  /api/trainer/community-config/ — Update community configuration.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        config, _ = CommunityConfig.objects.get_or_create(trainer=user)
        serializer = CommunityConfigSerializer(config)
        return Response(serializer.data)

    def put(self, request: Request) -> Response:
        user = cast(User, request.user)
        config, _ = CommunityConfig.objects.get_or_create(trainer=user)
        serializer = CommunityConfigSerializer(config, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

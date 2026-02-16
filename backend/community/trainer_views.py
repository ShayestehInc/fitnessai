"""
Trainer-facing announcement and leaderboard views.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from django.db.models import QuerySet
from rest_framework import generics, status, views
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainer
from users.models import User

from .models import Announcement, Leaderboard
from .serializers import (
    AnnouncementCreateSerializer,
    AnnouncementSerializer,
    LeaderboardSettingsSerializer,
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
            )
    except Exception:
        logger.warning("Failed to send announcement push notifications", exc_info=True)

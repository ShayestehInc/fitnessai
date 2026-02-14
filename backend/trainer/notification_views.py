"""
Views for trainer notification endpoints.

Provides list, unread count, mark-read, mark-all-read, and delete operations
for the TrainerNotification model.
"""
from __future__ import annotations

import logging
from typing import cast

from django.utils import timezone
from rest_framework import generics, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsTrainer
from users.models import User

from .models import TrainerNotification
from .notification_serializers import TrainerNotificationSerializer

logger = logging.getLogger(__name__)


class NotificationPagination(PageNumberPagination):
    """Pagination for notification list — 20 per page."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 50


class NotificationListView(generics.ListAPIView[TrainerNotification]):
    """
    GET /api/trainer/notifications/
    Returns paginated list of trainer's notifications, newest first.
    Supports ?is_read=true|false filter.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TrainerNotificationSerializer
    pagination_class = NotificationPagination

    def get_queryset(self) -> generics.QuerySet[TrainerNotification]:
        trainer = cast(User, self.request.user)
        qs = TrainerNotification.objects.filter(trainer=trainer)

        is_read_param = self.request.query_params.get('is_read')
        if is_read_param is not None:
            is_read = is_read_param.lower() in ('true', '1', 'yes')
            qs = qs.filter(is_read=is_read)

        return qs.order_by('-created_at')


class UnreadCountView(APIView):
    """
    GET /api/trainer/notifications/unread-count/
    Returns {"unread_count": N} for the authenticated trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        count = TrainerNotification.objects.filter(
            trainer=trainer,
            is_read=False,
        ).count()
        return Response({'unread_count': count})


class MarkNotificationReadView(APIView):
    """
    POST /api/trainer/notifications/<pk>/read/
    Marks a single notification as read.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, pk: int) -> Response:
        trainer = cast(User, request.user)
        try:
            notification = TrainerNotification.objects.get(pk=pk, trainer=trainer)
        except TrainerNotification.DoesNotExist:
            return Response(
                {'error': 'Notification not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not notification.is_read:
            notification.is_read = True
            notification.read_at = timezone.now()
            notification.save(update_fields=['is_read', 'read_at'])

        serializer = TrainerNotificationSerializer(notification)
        return Response(serializer.data)


class MarkAllReadView(APIView):
    """
    POST /api/trainer/notifications/mark-all-read/
    Marks all unread notifications for the trainer as read.
    Uses bulk update for efficiency.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        now = timezone.now()
        marked_count = TrainerNotification.objects.filter(
            trainer=trainer,
            is_read=False,
        ).update(is_read=True, read_at=now)

        return Response({'marked_count': marked_count})


class DeleteNotificationView(APIView):
    """
    DELETE /api/trainer/notifications/<pk>/
    Deletes a single notification.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def delete(self, request: Request, pk: int) -> Response:
        trainer = cast(User, request.user)
        try:
            notification = TrainerNotification.objects.get(pk=pk, trainer=trainer)
        except TrainerNotification.DoesNotExist:
            return Response(
                {'error': 'Notification not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        notification.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

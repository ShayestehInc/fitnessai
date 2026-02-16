"""
Trainer-facing announcement views: CRUD for announcements.
"""
from __future__ import annotations

import logging
from typing import cast

from django.db.models import QuerySet
from rest_framework import generics, status, views
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainer
from users.models import User

from .models import Announcement
from .serializers import AnnouncementCreateSerializer, AnnouncementSerializer

logger = logging.getLogger(__name__)


class TrainerAnnouncementListCreateView(generics.ListCreateAPIView[Announcement]):
    """
    GET  /api/trainer/announcements/ — List trainer's own announcements.
    POST /api/trainer/announcements/ — Create a new announcement.
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
        )

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
        announcement.save(update_fields=['title', 'body', 'is_pinned', 'updated_at'])

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

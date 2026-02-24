"""
Views for persistent AI chat threads.
"""
from __future__ import annotations

import logging
from typing import cast

from rest_framework import status, views
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from core.permissions import IsTrainer
from trainer.ai_chat_serializers import (
    AIChatThreadDetailSerializer,
    AIChatThreadListSerializer,
    CreateThreadSerializer,
    RenameThreadSerializer,
    SendMessageSerializer,
    SendMessageResponseSerializer,
)
from trainer.models import AIChatMessage
from trainer.services.ai_chat_service import (
    create_thread,
    delete_thread,
    get_thread_with_messages,
    get_threads_for_trainer,
    rename_thread,
    send_message_to_thread,
)
from users.models import User

logger = logging.getLogger(__name__)


class AIChatThreadListCreateView(views.APIView):
    """
    GET: List all AI chat threads for the authenticated trainer.
    POST: Create a new AI chat thread.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        threads = get_threads_for_trainer(trainer)
        serializer = AIChatThreadListSerializer(threads, many=True)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        serializer = CreateThreadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            thread_data = create_thread(
                trainer=trainer,
                title=serializer.validated_data['title'],
                trainee_context_id=serializer.validated_data.get('trainee_context_id'),
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                'id': thread_data.id,
                'title': thread_data.title,
                'trainee_context_id': thread_data.trainee_context_id,
                'last_message_at': thread_data.last_message_at,
                'created_at': thread_data.created_at.isoformat(),
            },
            status=status.HTTP_201_CREATED,
        )


class AIChatThreadDetailView(views.APIView):
    """
    GET: Get thread detail with all messages.
    PATCH: Rename a thread.
    DELETE: Soft-delete a thread.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, thread_id: int) -> Response:
        trainer = cast(User, request.user)

        try:
            thread = get_thread_with_messages(trainer, thread_id)
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = AIChatThreadDetailSerializer(thread)
        return Response(serializer.data)

    def patch(self, request: Request, thread_id: int) -> Response:
        trainer = cast(User, request.user)
        serializer = RenameThreadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            thread_data = rename_thread(
                trainer=trainer,
                thread_id=thread_id,
                title=serializer.validated_data['title'],
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'id': thread_data.id,
            'title': thread_data.title,
        })

    def delete(self, request: Request, thread_id: int) -> Response:
        trainer = cast(User, request.user)

        try:
            delete_thread(trainer, thread_id)
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(status=status.HTTP_204_NO_CONTENT)


class AIChatThreadSendView(views.APIView):
    """
    POST: Send a message to a thread and get an AI response.

    Returns both the user message and the assistant response.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, thread_id: int) -> Response:
        trainer = cast(User, request.user)
        serializer = SendMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            result = send_message_to_thread(
                trainer=trainer,
                thread_id=thread_id,
                content=serializer.validated_data['message'],
                trainee_id=serializer.validated_data.get('trainee_id'),
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except RuntimeError as exc:
            logger.error("AI chat error for trainer %s: %s", trainer.id, exc)
            return Response(
                {'error': 'AI service is temporarily unavailable. Please try again.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        # Fetch the actual message objects for proper serialization
        user_msg = AIChatMessage.objects.get(id=result.user_message.id)
        assistant_msg = AIChatMessage.objects.get(id=result.assistant_message.id)

        response_serializer = SendMessageResponseSerializer({
            'user_message': user_msg,
            'assistant_message': assistant_msg,
            'thread_title': result.thread_title,
        })

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

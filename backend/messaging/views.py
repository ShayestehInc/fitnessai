"""
Views for the messaging app.

All views enforce row-level security: trainers only see conversations
with their trainees; trainees only see their own conversation.

Business logic (broadcasting, push notifications, impersonation checks)
is delegated to the services layer. Views handle request/response only.
"""
from __future__ import annotations

import logging
from typing import cast

from rest_framework import status, views
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from users.models import User

from .models import Conversation, Message
from .serializers import (
    ConversationListSerializer,
    MessageSerializer,
    SendMessageSerializer,
    StartConversationSerializer,
)
from .services.messaging_service import (
    broadcast_new_message,
    broadcast_read_receipt,
    get_conversations_for_user,
    get_messages_for_conversation,
    get_unread_count,
    is_impersonating,
    mark_conversation_read,
    send_message,
    send_message_push_notification,
    send_message_to_trainee,
)

logger = logging.getLogger(__name__)


class MessagePagination(PageNumberPagination):
    """Pagination for messages within a conversation."""
    page_size = 20


class ConversationPagination(PageNumberPagination):
    """Pagination for conversation list."""
    page_size = 50


# ---------------------------------------------------------------------------
# Conversation endpoints
# ---------------------------------------------------------------------------


class ConversationListView(views.APIView):
    """
    GET /api/messaging/conversations/
    List all conversations for the authenticated user.
    Row-level security: trainers see their trainees' conversations,
    trainees see their own conversation.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        conversations = get_conversations_for_user(user)

        paginator = ConversationPagination()
        page = paginator.paginate_queryset(conversations, request)

        serializer = ConversationListSerializer(
            page if page is not None else conversations,
            many=True,
            context={'request': request},
        )

        if paginator.page is not None:
            return paginator.get_paginated_response(serializer.data)
        return Response(serializer.data)


class ConversationDetailView(views.APIView):
    """
    GET /api/messaging/conversations/<id>/messages/
    Get paginated messages for a specific conversation.
    Row-level security enforced.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, conversation_id: int) -> Response:
        user = cast(User, request.user)

        try:
            conversation = Conversation.objects.select_related(
                'trainer', 'trainee',
            ).get(id=conversation_id)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Row-level security
        if user.id not in (conversation.trainer_id, conversation.trainee_id):
            return Response(
                {'error': 'You do not have access to this conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            messages = get_messages_for_conversation(user, conversation)
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_403_FORBIDDEN,
            )

        paginator = MessagePagination()
        page = paginator.paginate_queryset(messages, request)
        serializer = MessageSerializer(
            page if page is not None else messages,
            many=True,
            context={'request': request},
        )

        if paginator.page is not None:
            return paginator.get_paginated_response(serializer.data)
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Send message endpoints
# ---------------------------------------------------------------------------


class SendMessageView(views.APIView):
    """
    POST /api/messaging/conversations/<id>/send/
    Send a message in an existing conversation.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'messaging'

    def post(self, request: Request, conversation_id: int) -> Response:
        user = cast(User, request.user)

        # Check for impersonation (read-only guard)
        if is_impersonating(request.auth):
            return Response(
                {'error': 'Cannot send messages during impersonation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = SendMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            conversation = Conversation.objects.select_related(
                'trainer', 'trainee',
            ).get(id=conversation_id)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Row-level security
        if user.id not in (conversation.trainer_id, conversation.trainee_id):
            return Response(
                {'error': 'You do not have access to this conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            result = send_message(
                sender=user,
                conversation=conversation,
                content=serializer.validated_data['content'],
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get the full message object for serialization
        message = Message.objects.select_related('sender').get(id=result.message_id)
        response_serializer = MessageSerializer(message, context={'request': request})

        # Broadcast via WebSocket (fire-and-forget)
        broadcast_new_message(conversation.id, response_serializer.data)

        # Send push notification to recipient
        recipient_id = (
            conversation.trainee_id
            if user.id == conversation.trainer_id
            else conversation.trainer_id
        )
        send_message_push_notification(
            recipient_id=recipient_id,
            sender=user,
            content=result.content,
            conversation_id=conversation.id,
        )

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class StartConversationView(views.APIView):
    """
    POST /api/messaging/conversations/start/
    Start a new conversation with a trainee (trainer-only).
    Creates conversation if needed and sends the first message.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'messaging'

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)

        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can start conversations.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if is_impersonating(request.auth):
            return Response(
                {'error': 'Cannot send messages during impersonation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = StartConversationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            result = send_message_to_trainee(
                trainer=user,
                trainee_id=serializer.validated_data['trainee_id'],
                content=serializer.validated_data['content'],
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get the full message for serialization
        message = Message.objects.select_related('sender').get(id=result.message_id)
        response_serializer = MessageSerializer(message, context={'request': request})

        # Broadcast via WebSocket
        broadcast_new_message(result.conversation_id, response_serializer.data)

        # Send push notification
        conversation = Conversation.objects.get(id=result.conversation_id)
        send_message_push_notification(
            recipient_id=conversation.trainee_id,
            sender=user,
            content=result.content,
            conversation_id=result.conversation_id,
        )

        return Response(
            {
                'conversation_id': result.conversation_id,
                'message': response_serializer.data,
                'is_new_conversation': result.is_new_conversation,
            },
            status=status.HTTP_201_CREATED,
        )


# ---------------------------------------------------------------------------
# Read receipts & unread count
# ---------------------------------------------------------------------------


class MarkReadView(views.APIView):
    """
    POST /api/messaging/conversations/<id>/read/
    Mark all messages in a conversation as read for the current user.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, conversation_id: int) -> Response:
        user = cast(User, request.user)

        try:
            conversation = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Row-level security
        if user.id not in (conversation.trainer_id, conversation.trainee_id):
            return Response(
                {'error': 'You do not have access to this conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            result = mark_conversation_read(user, conversation)
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Broadcast read receipt via WebSocket
        broadcast_read_receipt(
            conversation_id=conversation.id,
            reader_id=user.id,
            read_at=result.read_at.isoformat(),
        )

        return Response({
            'conversation_id': result.conversation_id,
            'messages_marked': result.messages_marked,
            'read_at': result.read_at,
        })


class UnreadCountView(views.APIView):
    """
    GET /api/messaging/unread-count/
    Get the total unread message count for the current user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        result = get_unread_count(user)
        return Response({'unread_count': result.unread_count})

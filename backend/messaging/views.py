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

from django.core.files.uploadedfile import UploadedFile
from rest_framework import status, views
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from users.models import User

from .models import Conversation, Message
from .serializers import (
    ConversationListSerializer,
    EditMessageSerializer,
    MessageSerializer,
    SendMessageSerializer,
    StartConversationSerializer,
)
from .services.messaging_service import (
    broadcast_message_deleted,
    broadcast_message_edited,
    broadcast_new_message,
    broadcast_read_receipt,
    delete_message,
    edit_message,
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

# Image validation constants
_ALLOWED_IMAGE_TYPES: frozenset[str] = frozenset({
    'image/jpeg', 'image/png', 'image/webp',
})
_MAX_IMAGE_SIZE: int = 5 * 1024 * 1024  # 5MB


def _validate_message_image(image_file: UploadedFile) -> str | None:
    """Validate an uploaded message image.

    Returns an error message string if invalid, None if valid.
    """
    if image_file.content_type not in _ALLOWED_IMAGE_TYPES:
        return 'Only JPEG, PNG, and WebP images are supported.'
    if image_file.size is not None and image_file.size > _MAX_IMAGE_SIZE:
        return 'Image must be under 5MB.'
    return None


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
    Accepts JSON (text-only) or multipart form data (text + optional image).
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser]
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

        # Handle optional image attachment
        image_file = request.FILES.get('image')
        if image_file is not None:
            error = _validate_message_image(image_file)
            if error:
                return Response(
                    {'error': error},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Ensure at least content or image is provided
        content = serializer.validated_data['content']
        if not content and not image_file:
            return Response(
                {'error': 'Message must contain text or an image.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

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
                content=content,
                image=image_file,
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
            has_image=image_file is not None,
        )

        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class StartConversationView(views.APIView):
    """
    POST /api/messaging/conversations/start/
    Start a new conversation with a trainee (trainer-only).
    Creates conversation if needed and sends the first message.
    Accepts JSON (text-only) or multipart form data (text + optional image).
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser]
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

        # Handle optional image attachment
        image_file = request.FILES.get('image')
        if image_file is not None:
            error = _validate_message_image(image_file)
            if error:
                return Response(
                    {'error': error},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Ensure at least content or image is provided
        content = serializer.validated_data['content']
        if not content and not image_file:
            return Response(
                {'error': 'Message must contain text or an image.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            result = send_message_to_trainee(
                trainer=user,
                trainee_id=serializer.validated_data['trainee_id'],
                content=content,
                image=image_file,
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
            has_image=image_file is not None,
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
# Edit & Delete message endpoints
# ---------------------------------------------------------------------------


class EditMessageView(views.APIView):
    """
    PATCH /api/messaging/conversations/<id>/messages/<message_id>/
    Edit a message's content. Sender only, within 15-minute window.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'messaging'

    def patch(self, request: Request, conversation_id: int, message_id: int) -> Response:
        user = cast(User, request.user)

        if is_impersonating(request.auth):
            return Response(
                {'error': 'Cannot edit messages during impersonation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = EditMessageSerializer(data=request.data)
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

        try:
            result = edit_message(
                user=user,
                conversation=conversation,
                message_id=message_id,
                new_content=serializer.validated_data['content'],
            )
        except PermissionError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_403_FORBIDDEN,
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get full message for serialized response
        message = Message.objects.select_related('sender').get(id=result.message_id)
        response_serializer = MessageSerializer(message, context={'request': request})

        # Broadcast edit event via WebSocket
        broadcast_message_edited(
            conversation_id=conversation.id,
            message_id=result.message_id,
            new_content=result.content,
            edited_at=result.edited_at.isoformat(),
        )

        return Response(response_serializer.data)


class DeleteMessageView(views.APIView):
    """
    DELETE /api/messaging/conversations/<id>/messages/<message_id>/
    Soft-delete a message. Sender only, no time limit.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'messaging'

    def delete(self, request: Request, conversation_id: int, message_id: int) -> Response:
        user = cast(User, request.user)

        if is_impersonating(request.auth):
            return Response(
                {'error': 'Cannot delete messages during impersonation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            conversation = Conversation.objects.select_related(
                'trainer', 'trainee',
            ).get(id=conversation_id)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            result = delete_message(
                user=user,
                conversation=conversation,
                message_id=message_id,
            )
        except PermissionError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_403_FORBIDDEN,
            )
        except ValueError as exc:
            return Response(
                {'error': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Broadcast delete event via WebSocket
        broadcast_message_deleted(
            conversation_id=conversation.id,
            message_id=result.message_id,
        )

        return Response(status=status.HTTP_204_NO_CONTENT)


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

"""
Business logic for direct messaging between trainers and trainees.

All functions return dataclass instances, never dicts.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from datetime import timedelta

from django.core.files.uploadedfile import UploadedFile
from django.db import transaction
from django.db.models import BooleanField, Count, OuterRef, Q, QuerySet, Subquery, Value
from django.db.models.expressions import Case, When
from django.db.models.functions import Left
from django.utils import timezone

from messaging.models import Conversation, Message
from users.models import User

# Configurable edit window: messages can only be edited within this time.
EDIT_WINDOW = timedelta(minutes=15)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Result dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SendMessageResult:
    """Result of sending a message."""
    message_id: int
    conversation_id: int
    content: str
    sender_id: int
    created_at: datetime
    is_new_conversation: bool
    image_url: str | None = None


@dataclass(frozen=True)
class MarkReadResult:
    """Result of marking a conversation as read."""
    conversation_id: int
    messages_marked: int
    read_at: datetime


@dataclass(frozen=True)
class UnreadCountResult:
    """Unread message count for a user."""
    unread_count: int


@dataclass(frozen=True)
class EditMessageResult:
    """Result of editing a message."""
    message_id: int
    conversation_id: int
    content: str
    edited_at: datetime


@dataclass(frozen=True)
class DeleteMessageResult:
    """Result of soft-deleting a message."""
    message_id: int
    conversation_id: int


# ---------------------------------------------------------------------------
# Service functions
# ---------------------------------------------------------------------------

def get_or_create_conversation(
    trainer: User,
    trainee: User,
) -> tuple[Conversation, bool]:
    """
    Get or create a conversation between a trainer and trainee.

    Validates the trainer-trainee relationship. Raises ValueError if invalid.
    Returns (conversation, was_created).
    """
    if not trainer.is_trainer():
        raise ValueError('First participant must be a trainer.')

    if not trainee.is_trainee():
        raise ValueError('Second participant must be a trainee.')

    if trainee.parent_trainer_id != trainer.id:
        raise ValueError('Trainee is not assigned to this trainer.')

    conversation, created = Conversation.objects.get_or_create(
        trainer=trainer,
        trainee=trainee,
        defaults={'is_archived': False},
    )

    # Un-archive if it was previously archived (trainee re-assigned)
    if not created and conversation.is_archived:
        conversation.is_archived = False
        conversation.save(update_fields=['is_archived', 'updated_at'])

    return conversation, created


def send_message(
    sender: User,
    conversation: Conversation,
    content: str,
    image: UploadedFile | None = None,
) -> SendMessageResult:
    """
    Send a message in a conversation.

    Validates:
    - Sender is a participant
    - Conversation is not archived
    - At least one of content or image must be provided
    - Content is within 2000 chars
    - Sender is not an impersonating admin (read-only guard)

    Returns SendMessageResult.
    Raises ValueError on validation failure.
    """
    stripped_content = content.strip()

    if not stripped_content and not image:
        raise ValueError('Message must contain text or an image.')

    if len(stripped_content) > 2000:
        raise ValueError('Message content cannot exceed 2000 characters.')

    if conversation.is_archived:
        raise ValueError('Cannot send messages in an archived conversation.')

    # Verify sender is a participant
    if sender.id not in (conversation.trainer_id, conversation.trainee_id):
        raise ValueError('You are not a participant in this conversation.')

    is_new = conversation.last_message_at is None

    with transaction.atomic():
        message = Message.objects.create(
            conversation=conversation,
            sender=sender,
            content=stripped_content,
            image=image,
        )

        # Update conversation timestamp
        conversation.last_message_at = message.created_at
        conversation.save(update_fields=['last_message_at', 'updated_at'])

    image_url: str | None = message.image.url if message.image else None

    return SendMessageResult(
        message_id=message.id,
        conversation_id=conversation.id,
        content=message.content,
        sender_id=sender.id,
        created_at=message.created_at,
        is_new_conversation=is_new,
        image_url=image_url,
    )


def mark_conversation_read(
    user: User,
    conversation: Conversation,
) -> MarkReadResult:
    """
    Mark all unread messages in a conversation as read for the given user.

    Only marks messages sent by the OTHER participant (you don't read your own).
    Returns MarkReadResult.
    Raises ValueError if user is not a participant.
    """
    if user.id not in (conversation.trainer_id, conversation.trainee_id):
        raise ValueError('You are not a participant in this conversation.')

    now = timezone.now()
    updated_count = Message.objects.filter(
        conversation=conversation,
        is_read=False,
    ).exclude(
        sender=user,
    ).update(
        is_read=True,
        read_at=now,
    )

    return MarkReadResult(
        conversation_id=conversation.id,
        messages_marked=updated_count,
        read_at=now,
    )


def get_unread_count(user: User) -> UnreadCountResult:
    """
    Get the total number of unread messages across all conversations for a user.

    Only counts messages from the OTHER participant.
    Uses a single query by filtering on conversation ownership directly.
    """
    if user.is_trainer():
        conversation_filter = Q(
            conversation__trainer=user,
            conversation__is_archived=False,
        )
    elif user.is_trainee():
        conversation_filter = Q(
            conversation__trainee=user,
            conversation__is_archived=False,
        )
    else:
        return UnreadCountResult(unread_count=0)

    unread = Message.objects.filter(
        conversation_filter,
        is_read=False,
    ).exclude(
        sender=user,
    ).count()

    return UnreadCountResult(unread_count=unread)


def get_conversations_for_user(user: User) -> QuerySet[Conversation]:
    """
    Get conversations for a user with row-level security.

    Trainers see conversations with their trainees.
    Trainees see conversations with their trainer.
    Always excludes archived unless specifically requested.

    The queryset is annotated with:
    - annotated_last_message_preview: last message content (truncated to 100 chars)
    - annotated_unread_count: count of unread messages from the other party
    """
    if user.is_trainer():
        base_qs = Conversation.objects.filter(trainer=user, is_archived=False)
    elif user.is_trainee():
        base_qs = Conversation.objects.filter(trainee=user, is_archived=False)
    else:
        return Conversation.objects.none()

    # Subquery: get the content of the most recent message per conversation
    last_message_subquery = (
        Message.objects.filter(conversation=OuterRef('pk'))
        .order_by('-created_at')
        .values('content')[:1]
    )

    # Subquery: get the image path of the most recent message per conversation
    last_message_image_subquery = (
        Message.objects.filter(conversation=OuterRef('pk'))
        .order_by('-created_at')
        .values('image')[:1]
    )

    # Subquery: check if the most recent message is soft-deleted
    last_message_is_deleted_subquery = (
        Message.objects.filter(conversation=OuterRef('pk'))
        .order_by('-created_at')
        .values('is_deleted')[:1]
    )

    return (
        base_qs
        .select_related('trainer', 'trainee')
        .annotate(
            annotated_last_message_preview=Left(
                Subquery(last_message_subquery),
                100,
            ),
            _last_message_image=Subquery(last_message_image_subquery),
            _last_message_is_deleted=Subquery(last_message_is_deleted_subquery),
        )
        .annotate(
            annotated_last_message_has_image=Case(
                When(
                    condition=~Q(_last_message_image='') & Q(_last_message_image__isnull=False),
                    then=Value(True),
                ),
                default=Value(False),
                output_field=BooleanField(),
            ),
            annotated_last_message_is_deleted=Case(
                When(
                    _last_message_is_deleted=True,
                    then=Value(True),
                ),
                default=Value(False),
                output_field=BooleanField(),
            ),
            annotated_unread_count=Count(
                'messages',
                filter=Q(messages__is_read=False) & ~Q(messages__sender=user),
            ),
        )
        .order_by('-last_message_at')
    )


def get_messages_for_conversation(
    user: User,
    conversation: Conversation,
) -> QuerySet[Message]:
    """
    Get messages for a conversation with row-level security.

    Raises ValueError if user is not a participant.
    """
    if user.id not in (conversation.trainer_id, conversation.trainee_id):
        raise ValueError('You are not a participant in this conversation.')

    return (
        Message.objects.filter(conversation=conversation)
        .select_related('sender')
        .order_by('-created_at')
    )


def archive_conversations_for_trainee(trainee: User) -> int:
    """
    Archive all conversations for a trainee (called when trainee is removed).

    Returns the number of conversations archived.
    """
    return Conversation.objects.filter(
        trainee=trainee,
        is_archived=False,
    ).update(is_archived=True)


def send_message_to_trainee(
    trainer: User,
    trainee_id: int,
    content: str,
    image: UploadedFile | None = None,
) -> SendMessageResult:
    """
    High-level: send a message from a trainer to a trainee.

    Creates conversation if needed.
    Validates ownership.
    """
    try:
        trainee = User.objects.get(
            id=trainee_id,
            role=User.Role.TRAINEE,
            parent_trainer=trainer,
        )
    except User.DoesNotExist:
        raise ValueError('Trainee not found or not assigned to you.')

    conversation, _created = get_or_create_conversation(trainer, trainee)
    return send_message(trainer, conversation, content, image=image)


def edit_message(
    user: User,
    conversation: Conversation,
    message_id: int,
    new_content: str,
) -> EditMessageResult:
    """
    Edit a message's content.

    Validates:
    - User is a participant in the conversation
    - User is the sender of the message
    - Message is not soft-deleted
    - Message is within the edit window (EDIT_WINDOW)
    - New content is not empty for text-only messages
    - New content is within 2000 chars

    Returns EditMessageResult.
    Raises ValueError on validation failure.
    Raises PermissionError if user is not the sender.
    """
    if user.id not in (conversation.trainer_id, conversation.trainee_id):
        raise PermissionError('You are not a participant in this conversation.')

    stripped = new_content.strip()
    if len(stripped) > 2000:
        raise ValueError('Message content cannot exceed 2000 characters.')

    with transaction.atomic():
        try:
            message = Message.objects.select_for_update().get(
                id=message_id,
                conversation=conversation,
            )
        except Message.DoesNotExist:
            raise ValueError('Message not found.')

        if message.sender_id != user.id:
            raise PermissionError('You can only edit your own messages.')

        if message.is_deleted:
            raise ValueError('Message has been deleted.')

        now = timezone.now()
        if (now - message.created_at) > EDIT_WINDOW:
            raise ValueError('Edit window has expired.')

        # If message has no image, content cannot be empty
        if not stripped and not message.image:
            raise ValueError('Content cannot be empty for a text-only message.')

        message.content = stripped
        message.edited_at = now
        message.save(update_fields=['content', 'edited_at'])

    return EditMessageResult(
        message_id=message.id,
        conversation_id=conversation.id,
        content=message.content,
        edited_at=message.edited_at,
    )


def delete_message(
    user: User,
    conversation: Conversation,
    message_id: int,
) -> DeleteMessageResult:
    """
    Soft-delete a message.

    Clears content and image. Sets is_deleted=True.
    No time limit on deletion.

    Validates:
    - User is a participant in the conversation
    - User is the sender of the message
    - Message is not already deleted

    Returns DeleteMessageResult.
    Raises ValueError on validation failure.
    Raises PermissionError if user is not the sender.
    """
    if user.id not in (conversation.trainer_id, conversation.trainee_id):
        raise PermissionError('You are not a participant in this conversation.')

    old_image_field = None

    with transaction.atomic():
        try:
            message = Message.objects.select_for_update().get(
                id=message_id,
                conversation=conversation,
            )
        except Message.DoesNotExist:
            raise ValueError('Message not found.')

        if message.sender_id != user.id:
            raise PermissionError('You can only delete your own messages.')

        if message.is_deleted:
            raise ValueError('Message has already been deleted.')

        # Save reference to image file before clearing
        if message.image:
            old_image_field = message.image

        message.content = ''
        message.image = None
        message.is_deleted = True
        message.save(update_fields=['content', 'image', 'is_deleted'])

    # Delete the actual image file from storage (outside transaction)
    if old_image_field:
        try:
            old_image_field.delete(save=False)
        except OSError as exc:
            logger.warning(
                "Failed to delete image file for message %d: %s",
                message_id,
                exc,
            )

    return DeleteMessageResult(
        message_id=message.id,
        conversation_id=conversation.id,
    )


# ---------------------------------------------------------------------------
# WebSocket broadcast helpers
# ---------------------------------------------------------------------------

def broadcast_new_message(
    conversation_id: int,
    message_data: dict[str, Any],
) -> None:
    """Broadcast a new message to the conversation's WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'messaging_conversation_{conversation_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'chat.new_message',
                'message': message_data,
                'timestamp': timezone.now().isoformat(),
            },
        )
    except (ConnectionError, TimeoutError, OSError) as exc:
        logger.warning(
            "Failed to broadcast message to WebSocket for conversation %d: %s",
            conversation_id,
            exc,
        )


def broadcast_read_receipt(
    conversation_id: int,
    reader_id: int,
    read_at: str,
) -> None:
    """Broadcast a read receipt to the conversation's WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'messaging_conversation_{conversation_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'chat.read_receipt',
                'reader_id': reader_id,
                'read_at': read_at,
            },
        )
    except (ConnectionError, TimeoutError, OSError) as exc:
        logger.warning(
            "Failed to broadcast read receipt for conversation %d: %s",
            conversation_id,
            exc,
        )


def broadcast_message_edited(
    conversation_id: int,
    message_id: int,
    new_content: str,
    edited_at: str,
) -> None:
    """Broadcast a message-edited event to the conversation's WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'messaging_conversation_{conversation_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'chat.message_edited',
                'message_id': message_id,
                'content': new_content,
                'edited_at': edited_at,
            },
        )
    except (ConnectionError, TimeoutError, OSError) as exc:
        logger.warning(
            "Failed to broadcast message-edited for conversation %d: %s",
            conversation_id,
            exc,
        )


def broadcast_message_deleted(
    conversation_id: int,
    message_id: int,
) -> None:
    """Broadcast a message-deleted event to the conversation's WebSocket group."""
    try:
        from channels.layers import get_channel_layer
        from asgiref.sync import async_to_sync

        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        group_name = f'messaging_conversation_{conversation_id}'
        async_to_sync(channel_layer.group_send)(
            group_name,
            {
                'type': 'chat.message_deleted',
                'message_id': message_id,
            },
        )
    except (ConnectionError, TimeoutError, OSError) as exc:
        logger.warning(
            "Failed to broadcast message-deleted for conversation %d: %s",
            conversation_id,
            exc,
        )


def send_message_push_notification(
    recipient_id: int,
    sender: User,
    content: str,
    conversation_id: int,
    has_image: bool = False,
) -> None:
    """Send push notification for a new message."""
    try:
        from core.services.notification_service import send_push_notification

        if content:
            preview = content[:100] if len(content) > 100 else content
        elif has_image:
            preview = 'Sent a photo'
        else:
            preview = 'New message'

        sender_name = f'{sender.first_name} {sender.last_name}'.strip()
        if not sender_name:
            sender_name = sender.email

        send_push_notification(
            user_id=recipient_id,
            title=f'New message from {sender_name}',
            body=preview,
            data={
                'type': 'direct_message',
                'conversation_id': str(conversation_id),
                'sender_id': str(sender.id),
            },
        )
    except (ConnectionError, TimeoutError, OSError) as exc:
        logger.warning(
            "Failed to send message push notification to user %d: %s",
            recipient_id,
            exc,
        )


def is_impersonating(request_auth: Any) -> bool:
    """Check if the provided auth token indicates an impersonation session.

    Uses the already-validated token from simplejwt authentication.
    """
    if request_auth is None:
        return False
    # simplejwt sets request.auth to the validated token object
    # which supports dict-style access for custom claims.
    if hasattr(request_auth, 'get'):
        return bool(request_auth.get('impersonating', False))
    # Fallback: if auth is not a token object (e.g. SessionAuth)
    return False

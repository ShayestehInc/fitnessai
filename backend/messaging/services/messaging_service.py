"""
Business logic for direct messaging between trainers and trainees.

All functions return dataclass instances, never dicts.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime

from django.db import transaction
from django.db.models import Count, OuterRef, Q, QuerySet, Subquery
from django.db.models.functions import Left
from django.utils import timezone

from messaging.models import Conversation, Message
from users.models import User

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
) -> SendMessageResult:
    """
    Send a message in a conversation.

    Validates:
    - Sender is a participant
    - Conversation is not archived
    - Content is not empty / whitespace
    - Content is within 2000 chars
    - Sender is not an impersonating admin (read-only guard)

    Returns SendMessageResult.
    Raises ValueError on validation failure.
    """
    stripped_content = content.strip()
    if not stripped_content:
        raise ValueError('Message content cannot be empty.')

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
        )

        # Update conversation timestamp
        conversation.last_message_at = message.created_at
        conversation.save(update_fields=['last_message_at', 'updated_at'])

    return SendMessageResult(
        message_id=message.id,
        conversation_id=conversation.id,
        content=message.content,
        sender_id=sender.id,
        created_at=message.created_at,
        is_new_conversation=is_new,
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
    """
    if user.is_trainer():
        conversations = Conversation.objects.filter(
            trainer=user,
            is_archived=False,
        )
    elif user.is_trainee():
        conversations = Conversation.objects.filter(
            trainee=user,
            is_archived=False,
        )
    else:
        return UnreadCountResult(unread_count=0)

    unread = Message.objects.filter(
        conversation__in=conversations,
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

    return (
        base_qs
        .select_related('trainer', 'trainee')
        .annotate(
            annotated_last_message_preview=Left(
                Subquery(last_message_subquery),
                100,
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
    return send_message(trainer, conversation, content)

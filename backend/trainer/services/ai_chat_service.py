"""
Business logic for persistent AI chat threads.

All functions return dataclass instances, never dicts.
"""
from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from django.db import transaction
from django.db.models import Count, QuerySet
from django.utils import timezone

from trainer.ai_chat import AIChat
from trainer.models import AIChatMessage, AIChatThread
from users.models import User

logger = logging.getLogger(__name__)

MAX_TITLE_LENGTH = 60

FOLLOWUP_TAG_PATTERN: re.Pattern[str] = re.compile(
    r'<suggested_followup>(.*?)</suggested_followup>',
    re.DOTALL,
)

FOLLOWUP_INSTRUCTION = (
    '\n\nAt the very end of your response, suggest one short follow-up '
    'question the trainer might want to ask next. Wrap it in XML tags '
    'exactly like this: <suggested_followup>your suggestion here</suggested_followup>'
)


def _extract_followup(response: str) -> tuple[str, str]:
    """Extract <suggested_followup> tag from response.

    Returns (clean_response, followup_text). If no tag found,
    followup_text is empty and clean_response is the original.
    """
    match = FOLLOWUP_TAG_PATTERN.search(response)
    if not match:
        return response, ''
    followup = match.group(1).strip()
    clean = response[:match.start()].rstrip() + response[match.end():]
    return clean.strip(), followup


# ---------------------------------------------------------------------------
# Result dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class AIChatThreadData:
    """Result of creating or fetching a thread."""
    id: int
    title: str
    trainee_context_id: int | None
    last_message_at: datetime | None
    created_at: datetime


@dataclass(frozen=True)
class AIChatMessageData:
    """A single message from the DB."""
    id: int
    role: str
    content: str
    provider: str
    model_name: str
    created_at: datetime


@dataclass(frozen=True)
class SendAIMessageResult:
    """Result of sending a message and getting an AI response."""
    user_message: AIChatMessageData
    assistant_message: AIChatMessageData
    thread_title: str
    suggested_followup: str


# ---------------------------------------------------------------------------
# Service functions
# ---------------------------------------------------------------------------

def create_thread(
    trainer: User,
    title: str = 'New conversation',
    trainee_context_id: int | None = None,
) -> AIChatThreadData:
    """
    Create a new AI chat thread for a trainer.

    Validates trainee_context_id belongs to this trainer if provided.
    """
    trainee_context: User | None = None

    if trainee_context_id is not None:
        try:
            trainee_context = User.objects.get(
                id=trainee_context_id,
                parent_trainer=trainer,
                role=User.Role.TRAINEE,
            )
        except User.DoesNotExist:
            raise ValueError('Trainee not found or not assigned to you.')

    thread = AIChatThread.objects.create(
        trainer=trainer,
        trainee_context=trainee_context,
        title=title.strip() or 'New conversation',
    )

    return AIChatThreadData(
        id=thread.id,
        title=thread.title,
        trainee_context_id=thread.trainee_context_id,
        last_message_at=thread.last_message_at,
        created_at=thread.created_at,
    )


def get_threads_for_trainer(trainer: User) -> QuerySet[AIChatThread]:
    """
    Get all non-deleted threads for a trainer, annotated with message_count.

    Ordered by most recently active.
    """
    return (
        AIChatThread.objects.filter(
            trainer=trainer,
            is_deleted=False,
        )
        .annotate(message_count=Count('messages'))
        .select_related('trainee_context')
        .order_by('-last_message_at', '-created_at')
    )


def get_thread_with_messages(
    trainer: User,
    thread_id: int,
) -> AIChatThread:
    """
    Get a specific thread with all its messages, enforcing row-level security.

    Raises ValueError if thread not found or not owned by trainer.
    """
    try:
        thread = (
            AIChatThread.objects.filter(
                id=thread_id,
                trainer=trainer,
                is_deleted=False,
            )
            .prefetch_related('messages')
            .select_related('trainee_context')
            .get()
        )
    except AIChatThread.DoesNotExist:
        raise ValueError('Thread not found.')

    return thread


def send_message_to_thread(
    trainer: User,
    thread_id: int,
    content: str,
    trainee_id: Optional[int] = None,
) -> SendAIMessageResult:
    """
    Send a user message and get an AI response in a thread.

    1. Load full history from DB
    2. Persist user message
    3. Call AIChat.chat() with history
    4. Persist assistant message
    5. Auto-generate title from first user message

    Uses trainee_id param if provided, otherwise falls back to thread's trainee_context.
    """
    stripped = content.strip()
    if not stripped:
        raise ValueError('Message content cannot be empty.')

    if len(stripped) > 5000:
        raise ValueError('Message content cannot exceed 5000 characters.')

    try:
        thread = AIChatThread.objects.get(
            id=thread_id,
            trainer=trainer,
            is_deleted=False,
        )
    except AIChatThread.DoesNotExist:
        raise ValueError('Thread not found.')

    # Determine which trainee to use for context
    effective_trainee_id = trainee_id or thread.trainee_context_id

    # Load existing conversation history
    existing_messages = list(
        AIChatMessage.objects.filter(thread=thread)
        .order_by('created_at')
        .values('role', 'content')
    )

    conversation_history = [
        {'role': msg['role'], 'content': msg['content']}
        for msg in existing_messages
    ]

    now = timezone.now()

    with transaction.atomic():
        # Persist user message
        user_msg = AIChatMessage.objects.create(
            thread=thread,
            role=AIChatMessage.Role.USER,
            content=stripped,
        )

        # Call AI — append instruction so the model includes a follow-up suggestion
        ai_chat = AIChat(trainer)
        result = ai_chat.chat(
            message=stripped + FOLLOWUP_INSTRUCTION,
            conversation_history=conversation_history,
            trainee_id=effective_trainee_id,
        )

        if result.get('error') and not result.get('response'):
            raise RuntimeError(f"AI service error: {result['error']}")

        raw_response: str = result.get('response', '')
        provider: str = result.get('provider', '')
        model_name: str = result.get('model', '')
        usage = result.get('usage')

        # Extract the follow-up suggestion before persisting
        response_content, suggested_followup = _extract_followup(raw_response)

        # Persist assistant message (clean content, without the tag)
        assistant_msg = AIChatMessage.objects.create(
            thread=thread,
            role=AIChatMessage.Role.ASSISTANT,
            content=response_content,
            provider=provider,
            model_name=model_name,
            usage_metadata=usage,
        )

        # Update thread's last_message_at
        thread.last_message_at = assistant_msg.created_at
        update_fields = ['last_message_at', 'updated_at']

        # Auto-title from first user message
        if thread.title == 'New conversation':
            auto_title = stripped[:MAX_TITLE_LENGTH]
            if len(stripped) > MAX_TITLE_LENGTH:
                auto_title = auto_title[:MAX_TITLE_LENGTH - 3] + '...'
            thread.title = auto_title
            update_fields.append('title')

        thread.save(update_fields=update_fields)

    return SendAIMessageResult(
        user_message=AIChatMessageData(
            id=user_msg.id,
            role=user_msg.role,
            content=user_msg.content,
            provider=user_msg.provider,
            model_name=user_msg.model_name,
            created_at=user_msg.created_at,
        ),
        assistant_message=AIChatMessageData(
            id=assistant_msg.id,
            role=assistant_msg.role,
            content=assistant_msg.content,
            provider=assistant_msg.provider,
            model_name=assistant_msg.model_name,
            created_at=assistant_msg.created_at,
        ),
        thread_title=thread.title,
        suggested_followup=suggested_followup,
    )


def rename_thread(
    trainer: User,
    thread_id: int,
    title: str,
) -> AIChatThreadData:
    """
    Rename a thread. Enforces row-level security.

    Raises ValueError if thread not found or title is empty.
    """
    stripped_title = title.strip()
    if not stripped_title:
        raise ValueError('Title cannot be empty.')

    if len(stripped_title) > 200:
        raise ValueError('Title cannot exceed 200 characters.')

    try:
        thread = AIChatThread.objects.get(
            id=thread_id,
            trainer=trainer,
            is_deleted=False,
        )
    except AIChatThread.DoesNotExist:
        raise ValueError('Thread not found.')

    thread.title = stripped_title
    thread.save(update_fields=['title', 'updated_at'])

    return AIChatThreadData(
        id=thread.id,
        title=thread.title,
        trainee_context_id=thread.trainee_context_id,
        last_message_at=thread.last_message_at,
        created_at=thread.created_at,
    )


def delete_thread(
    trainer: User,
    thread_id: int,
) -> None:
    """
    Soft-delete a thread. Enforces row-level security.

    Raises ValueError if thread not found.
    """
    try:
        thread = AIChatThread.objects.get(
            id=thread_id,
            trainer=trainer,
            is_deleted=False,
        )
    except AIChatThread.DoesNotExist:
        raise ValueError('Thread not found.')

    thread.is_deleted = True
    thread.save(update_fields=['is_deleted', 'updated_at'])

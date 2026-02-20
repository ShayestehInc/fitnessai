"""
Service for searching messages across conversations.

All functions return dataclass instances, never dicts.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from django.core.paginator import Paginator
from django.db.models import Q

from messaging.models import Conversation, Message
from users.models import User

PAGE_SIZE = 20


@dataclass(frozen=True)
class SearchMessageItem:
    """A single message search result with conversation context."""
    message_id: int
    conversation_id: int
    sender_id: int
    sender_first_name: str
    sender_last_name: str
    content: str
    image_url: str | None
    created_at: datetime
    other_participant_id: int
    other_participant_first_name: str
    other_participant_last_name: str


@dataclass(frozen=True)
class SearchMessagesResult:
    """Paginated search results."""
    results: list[SearchMessageItem]
    count: int
    has_next: bool
    has_previous: bool
    page: int
    num_pages: int


def search_messages(
    user: User,
    query: str,
    page: int = 1,
) -> SearchMessagesResult:
    """
    Search messages across all non-archived conversations the user participates in.

    Args:
        user: The authenticated user performing the search.
        query: The search string (case-insensitive substring match).
        page: Page number (1-indexed).

    Returns:
        SearchMessagesResult with paginated matching messages.

    Raises:
        ValueError: If query is empty or too short.
    """
    stripped_query = query.strip()
    if not stripped_query:
        raise ValueError('Search query is required.')
    if len(stripped_query) < 2:
        raise ValueError('Search query must be at least 2 characters.')

    # Determine which conversations this user participates in
    if user.is_trainer():
        conversation_filter = Q(conversation__trainer=user)
    elif user.is_trainee():
        conversation_filter = Q(conversation__trainee=user)
    else:
        return SearchMessagesResult(
            results=[],
            count=0,
            has_next=False,
            has_previous=False,
            page=1,
            num_pages=0,
        )

    messages = (
        Message.objects.filter(
            conversation_filter,
            content__icontains=stripped_query,
            is_deleted=False,
            conversation__is_archived=False,
        )
        .select_related(
            'sender',
            'conversation',
            'conversation__trainer',
            'conversation__trainee',
        )
        .order_by('-created_at')
    )

    paginator = Paginator(messages, PAGE_SIZE)
    # Clamp page to valid range
    page_number = max(1, min(page, paginator.num_pages or 1))
    page_obj = paginator.get_page(page_number)

    results: list[SearchMessageItem] = []
    for msg in page_obj:
        conversation: Conversation = msg.conversation

        # Determine the "other" participant relative to the searching user
        if user.id == conversation.trainer_id:
            other = conversation.trainee
        else:
            other = conversation.trainer

        other_id = other.id if other else 0
        other_first = other.first_name if other else ''
        other_last = other.last_name if other else '[removed]'

        image_url: str | None = msg.image.url if msg.image else None

        results.append(
            SearchMessageItem(
                message_id=msg.id,
                conversation_id=conversation.id,
                sender_id=msg.sender_id,
                sender_first_name=msg.sender.first_name,
                sender_last_name=msg.sender.last_name,
                content=msg.content,
                image_url=image_url,
                created_at=msg.created_at,
                other_participant_id=other_id,
                other_participant_first_name=other_first,
                other_participant_last_name=other_last,
            )
        )

    return SearchMessagesResult(
        results=results,
        count=paginator.count,
        has_next=page_obj.has_next(),
        has_previous=page_obj.has_previous(),
        page=page_number,
        num_pages=paginator.num_pages,
    )

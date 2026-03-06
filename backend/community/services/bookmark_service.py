"""
Service layer for Bookmark operations: toggle, list, collections.
"""
from __future__ import annotations

from dataclasses import dataclass

from django.db.models import QuerySet

from users.models import User

from ..models import Bookmark, BookmarkCollection, CommunityPost


@dataclass(frozen=True)
class BookmarkToggleResult:
    is_bookmarked: bool
    bookmark_id: int | None


def toggle_bookmark(*, user: User, post: CommunityPost) -> BookmarkToggleResult:
    """
    Toggle bookmark on a post. Returns whether the post is now bookmarked.
    """
    try:
        bookmark = Bookmark.objects.get(user=user, post=post)
        bookmark.delete()
        return BookmarkToggleResult(is_bookmarked=False, bookmark_id=None)
    except Bookmark.DoesNotExist:
        bookmark = Bookmark.objects.create(user=user, post=post)
        return BookmarkToggleResult(is_bookmarked=True, bookmark_id=bookmark.id)


def get_user_bookmarks(user: User, collection_id: int | None = None) -> QuerySet[Bookmark]:
    """
    Get all bookmarks for a user, optionally filtered by collection.
    """
    qs = Bookmark.objects.filter(user=user).select_related(
        'post__author', 'post__space', 'collection',
    ).prefetch_related('post__images')

    if collection_id is not None:
        qs = qs.filter(collection_id=collection_id)

    return qs.order_by('-created_at')


def get_user_bookmarked_post_ids(user: User, post_ids: list[int]) -> set[int]:
    """
    Given a list of post IDs, return the subset that the user has bookmarked.
    Efficient batch check for serialization.
    """
    return set(
        Bookmark.objects.filter(
            user=user, post_id__in=post_ids,
        ).values_list('post_id', flat=True)
    )


def create_collection(*, user: User, name: str) -> BookmarkCollection:
    """Create a bookmark collection."""
    return BookmarkCollection.objects.create(user=user, name=name)


def get_user_collections(user: User) -> QuerySet[BookmarkCollection]:
    """Get all bookmark collections for a user."""
    return BookmarkCollection.objects.filter(user=user).order_by('name')

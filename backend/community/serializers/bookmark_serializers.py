"""
Serializers for Bookmarks and BookmarkCollections.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from ..models import Bookmark, BookmarkCollection


class BookmarkCollectionSerializer(serializers.ModelSerializer[BookmarkCollection]):
    """Read/write serializer for bookmark collections."""
    bookmark_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = BookmarkCollection
        fields = ['id', 'name', 'created_at', 'bookmark_count']
        read_only_fields = ['id', 'created_at']


class BookmarkCollectionCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation of a bookmark collection."""
    name = serializers.CharField(max_length=200)

    def validate_name(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError("Collection name cannot be empty.")
        return stripped


class BookmarkToggleSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates bookmark toggle request."""
    post_id = serializers.IntegerField()


class BookmarkSerializer(serializers.ModelSerializer[Bookmark]):
    """Read serializer for bookmarks with nested post summary."""
    post_id = serializers.IntegerField(source='post.id', read_only=True)
    post_content = serializers.CharField(source='post.content', read_only=True)
    post_author_name = serializers.SerializerMethodField()
    collection_name = serializers.CharField(
        source='collection.name', read_only=True, default=None,
    )

    class Meta:
        model = Bookmark
        fields = [
            'id', 'post_id', 'post_content', 'post_author_name',
            'collection_name', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def get_post_author_name(self, obj: Bookmark) -> str:
        author = obj.post.author
        full = f"{author.first_name} {author.last_name}".strip()
        return full if full else 'Anonymous'

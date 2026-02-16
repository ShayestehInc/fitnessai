"""
Serializers for the community app: announcements, achievements, community feed.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import (
    Announcement,
    UserAchievement,
    PostReaction,
)


# ---------------------------------------------------------------------------
# Announcements
# ---------------------------------------------------------------------------

class AnnouncementSerializer(serializers.ModelSerializer[Announcement]):
    """Serializer for announcements (trainer CRUD and trainee list)."""

    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'body', 'is_pinned',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AnnouncementCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of an announcement."""
    title = serializers.CharField(max_length=200)
    body = serializers.CharField(max_length=2000)
    is_pinned = serializers.BooleanField(default=False)


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------

class NewAchievementSerializer(serializers.ModelSerializer[UserAchievement]):
    """Serializer for newly earned achievements returned in API responses."""
    name = serializers.CharField(source='achievement.name')
    description = serializers.CharField(source='achievement.description')
    icon_name = serializers.CharField(source='achievement.icon_name')

    class Meta:
        model = UserAchievement
        fields = ['id', 'name', 'description', 'icon_name', 'earned_at']


# ---------------------------------------------------------------------------
# Community Feed
# ---------------------------------------------------------------------------

class CreatePostSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation of a text post."""
    content = serializers.CharField(max_length=1000)

    def validate_content(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError("Post content cannot be empty.")
        return stripped


class ReactionToggleSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates reaction toggle request."""
    reaction_type = serializers.ChoiceField(
        choices=PostReaction.ReactionType.choices,
    )

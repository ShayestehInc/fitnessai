"""
Serializers for the community app: announcements, achievements, community feed.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import (
    Announcement,
    AnnouncementReadStatus,
    Achievement,
    UserAchievement,
    CommunityPost,
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


class UnreadCountSerializer(serializers.Serializer[dict[str, Any]]):
    """Response for unread announcement count."""
    unread_count = serializers.IntegerField()


class MarkReadResponseSerializer(serializers.Serializer[dict[str, Any]]):
    """Response after marking announcements as read."""
    last_read_at = serializers.DateTimeField()


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------

class AchievementWithStatusSerializer(serializers.Serializer[dict[str, Any]]):
    """
    Achievement with earned/unearned status for the current user.
    Used by GET /api/community/achievements/.
    """
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    icon_name = serializers.CharField()
    criteria_type = serializers.CharField()
    criteria_value = serializers.IntegerField()
    earned = serializers.BooleanField()
    earned_at = serializers.DateTimeField(allow_null=True)


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

class PostAuthorSerializer(serializers.Serializer[dict[str, Any]]):
    """Nested author data inside a community post."""
    id = serializers.IntegerField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    profile_image = serializers.SerializerMethodField()

    def get_profile_image(self, obj: Any) -> str | None:
        request = self.context.get('request')
        if hasattr(obj, 'profile_image') and obj.profile_image:
            if request:
                return request.build_absolute_uri(obj.profile_image.url)
            return obj.profile_image.url
        return None


class CommunityPostSerializer(serializers.Serializer[dict[str, Any]]):
    """
    Read serializer for a community post including author, reactions, user_reactions.
    Built manually to avoid N+1 issues; annotation-based reaction counts are pre-computed.
    """
    id = serializers.IntegerField()
    author = PostAuthorSerializer()
    content = serializers.CharField()
    post_type = serializers.CharField()
    metadata = serializers.JSONField()
    created_at = serializers.DateTimeField()
    reactions = serializers.DictField(child=serializers.IntegerField())
    user_reactions = serializers.ListField(child=serializers.CharField())


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


class ReactionResponseSerializer(serializers.Serializer[dict[str, Any]]):
    """Response after toggling a reaction."""
    reactions = serializers.DictField(child=serializers.IntegerField())
    user_reactions = serializers.ListField(child=serializers.CharField())

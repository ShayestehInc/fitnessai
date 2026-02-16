"""
Serializers for the community app: announcements, achievements, community feed,
leaderboards, and comments.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import (
    Announcement,
    Comment,
    CommunityPost,
    Leaderboard,
    PostReaction,
    UserAchievement,
)


# ---------------------------------------------------------------------------
# Announcements
# ---------------------------------------------------------------------------

class AnnouncementSerializer(serializers.ModelSerializer[Announcement]):
    """Serializer for announcements (trainer CRUD and trainee list)."""

    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'body', 'is_pinned', 'content_format',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AnnouncementCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of an announcement."""
    title = serializers.CharField(max_length=200)
    body = serializers.CharField(max_length=2000)
    is_pinned = serializers.BooleanField(default=False)
    content_format = serializers.ChoiceField(
        choices=Announcement.ContentFormat.choices,
        default=Announcement.ContentFormat.PLAIN,
    )


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
    """Validates creation of a text post (JSON or multipart)."""
    content = serializers.CharField(max_length=1000)
    content_format = serializers.ChoiceField(
        choices=CommunityPost.ContentFormat.choices,
        default=CommunityPost.ContentFormat.PLAIN,
    )

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


# ---------------------------------------------------------------------------
# Comments
# ---------------------------------------------------------------------------

class CreateCommentSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation of a comment on a post."""
    content = serializers.CharField(max_length=500)

    def validate_content(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError("Comment cannot be empty.")
        return stripped


class CommentSerializer(serializers.ModelSerializer[Comment]):
    """Read serializer for comments with author data."""
    author_id = serializers.IntegerField(source='author.id', read_only=True)
    author_first_name = serializers.CharField(
        source='author.first_name', read_only=True,
    )
    author_last_name = serializers.CharField(
        source='author.last_name', read_only=True,
    )
    author_profile_image = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            'id', 'post_id', 'author_id', 'author_first_name',
            'author_last_name', 'author_profile_image',
            'content', 'created_at',
        ]
        read_only_fields = ['id', 'post_id', 'created_at']

    def get_author_profile_image(self, obj: Comment) -> str | None:
        request = self.context.get('request')
        if obj.author.profile_image and request is not None:
            return request.build_absolute_uri(obj.author.profile_image.url)
        return None


# ---------------------------------------------------------------------------
# Leaderboards
# ---------------------------------------------------------------------------

class LeaderboardSettingsSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates trainer leaderboard settings update."""
    metric_type = serializers.ChoiceField(
        choices=Leaderboard.MetricType.choices,
    )
    time_period = serializers.ChoiceField(
        choices=Leaderboard.TimePeriod.choices,
    )
    is_enabled = serializers.BooleanField()

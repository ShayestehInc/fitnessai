"""
Serializers for Community Config (Admin Builder).
"""
from __future__ import annotations

from rest_framework import serializers

from ..models import CommunityConfig


class CommunityConfigSerializer(serializers.ModelSerializer[CommunityConfig]):
    """Read/write serializer for community configuration."""

    class Meta:
        model = CommunityConfig
        fields = [
            'id',
            # Feature toggles
            'feed_enabled', 'spaces_enabled', 'courses_enabled',
            'events_enabled', 'leaderboard_enabled',
            'achievements_enabled', 'bookmarks_enabled',
            # Posting rules
            'trainee_can_post', 'trainee_can_comment',
            'trainee_can_react', 'post_approval_required',
            # Branding
            'community_name', 'welcome_message',
            # Guidelines
            'community_guidelines',
            # Timestamps
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

"""
Serializers for Moderation: reports, actions, bans, auto-mod rules.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from ..models import (
    AutoModRule,
    ContentReport,
    ModerationAction,
    UserBan,
)


# ---------------------------------------------------------------------------
# Reports
# ---------------------------------------------------------------------------

class ContentReportSerializer(serializers.ModelSerializer[ContentReport]):
    """Read serializer for a content report."""
    reporter_email = serializers.EmailField(source='reporter.email', read_only=True)
    reviewer_email = serializers.EmailField(
        source='reviewed_by.email', read_only=True, default=None,
    )

    class Meta:
        model = ContentReport
        fields = [
            'id', 'reporter_id', 'reporter_email',
            'content_type', 'post_id', 'comment_id',
            'reason', 'details', 'status',
            'reviewed_at', 'reviewer_email',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class ContentReportCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation of a content report."""
    content_type = serializers.ChoiceField(
        choices=ContentReport.ContentTypeChoice.choices,
    )
    post_id = serializers.IntegerField(required=False, allow_null=True, default=None)
    comment_id = serializers.IntegerField(required=False, allow_null=True, default=None)
    reason = serializers.ChoiceField(choices=ContentReport.ReportReason.choices)
    details = serializers.CharField(
        max_length=1000, required=False, allow_blank=True, default='',
    )

    def validate(self, data: dict[str, Any]) -> dict[str, Any]:
        if data['content_type'] == 'post' and not data.get('post_id'):
            raise serializers.ValidationError("post_id is required for post reports.")
        if data['content_type'] == 'comment' and not data.get('comment_id'):
            raise serializers.ValidationError("comment_id is required for comment reports.")
        return data


class ReportReviewSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates review of a report."""
    action_type = serializers.ChoiceField(choices=ModerationAction.ActionType.choices)
    reason = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default='',
    )


# ---------------------------------------------------------------------------
# Bans
# ---------------------------------------------------------------------------

class UserBanSerializer(serializers.ModelSerializer[UserBan]):
    """Read serializer for a user ban."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    banned_by_email = serializers.EmailField(source='banned_by.email', read_only=True)

    class Meta:
        model = UserBan
        fields = [
            'id', 'user_id', 'user_email',
            'banned_by_email', 'reason',
            'is_permanent', 'expires_at', 'is_active',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class UserBanCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation of a user ban."""
    user_id = serializers.IntegerField()
    reason = serializers.CharField(max_length=500)
    is_permanent = serializers.BooleanField(default=False)
    duration_days = serializers.IntegerField(
        required=False, allow_null=True, default=None, min_value=1,
    )


# ---------------------------------------------------------------------------
# Auto-Mod Rules
# ---------------------------------------------------------------------------

class AutoModRuleSerializer(serializers.ModelSerializer[AutoModRule]):
    """Read serializer for an auto-mod rule."""

    class Meta:
        model = AutoModRule
        fields = [
            'id', 'rule_type', 'config', 'action', 'is_enabled',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AutoModRuleCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of an auto-mod rule."""
    rule_type = serializers.ChoiceField(choices=AutoModRule.RuleType.choices)
    config = serializers.JSONField()
    action = serializers.ChoiceField(
        choices=AutoModRule.RuleAction.choices,
        default=AutoModRule.RuleAction.FLAG,
    )
    is_enabled = serializers.BooleanField(default=True)


# ---------------------------------------------------------------------------
# Moderation Actions
# ---------------------------------------------------------------------------

class ModerationActionSerializer(serializers.ModelSerializer[ModerationAction]):
    """Read serializer for a moderation action."""
    moderator_email = serializers.EmailField(source='moderator.email', read_only=True)

    class Meta:
        model = ModerationAction
        fields = [
            'id', 'report_id', 'moderator_email',
            'action_type', 'reason', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']

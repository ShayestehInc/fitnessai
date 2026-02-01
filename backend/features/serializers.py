"""
Serializers for features app.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import FeatureRequest, FeatureVote, FeatureComment

User = get_user_model()


class FeatureCommentSerializer(serializers.ModelSerializer[FeatureComment]):
    """Serializer for feature comments."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = FeatureComment
        fields = [
            'id', 'feature', 'user', 'user_email', 'user_name',
            'content', 'is_admin_response', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']

    def get_user_name(self, obj: FeatureComment) -> str:
        if obj.user:
            name = f"{obj.user.first_name} {obj.user.last_name}".strip()
            return name or obj.user.email
        return 'Deleted User'


class CreateCommentSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for creating new comments."""
    content = serializers.CharField(max_length=2000)


class FeatureVoteSerializer(serializers.ModelSerializer[FeatureVote]):
    """Serializer for feature votes."""

    class Meta:
        model = FeatureVote
        fields = ['id', 'feature', 'user', 'vote_type', 'created_at']
        read_only_fields = ['user', 'created_at']


class VoteSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for voting on a feature."""
    vote_type = serializers.ChoiceField(
        choices=[('up', 'Upvote'), ('down', 'Downvote'), ('remove', 'Remove Vote')]
    )


class FeatureRequestListSerializer(serializers.ModelSerializer[FeatureRequest]):
    """Serializer for listing feature requests."""
    submitted_by_email = serializers.EmailField(source='submitted_by.email', read_only=True)
    submitted_by_name = serializers.SerializerMethodField()
    vote_score = serializers.IntegerField(read_only=True)
    user_vote = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()

    class Meta:
        model = FeatureRequest
        fields = [
            'id', 'title', 'description', 'category', 'status',
            'submitted_by', 'submitted_by_email', 'submitted_by_name',
            'upvotes', 'downvotes', 'vote_score', 'user_vote',
            'comment_count', 'created_at', 'updated_at'
        ]

    def get_submitted_by_name(self, obj: FeatureRequest) -> str:
        if obj.submitted_by:
            name = f"{obj.submitted_by.first_name} {obj.submitted_by.last_name}".strip()
            return name or obj.submitted_by.email
        return 'Deleted User'

    def get_user_vote(self, obj: FeatureRequest) -> str | None:
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = obj.votes.filter(user=request.user).first()
            if vote:
                return vote.vote_type
        return None

    def get_comment_count(self, obj: FeatureRequest) -> int:
        return obj.comments.count()


class FeatureRequestDetailSerializer(serializers.ModelSerializer[FeatureRequest]):
    """Detailed serializer for single feature request."""
    submitted_by_email = serializers.EmailField(source='submitted_by.email', read_only=True)
    submitted_by_name = serializers.SerializerMethodField()
    vote_score = serializers.IntegerField(read_only=True)
    user_vote = serializers.SerializerMethodField()
    comments = FeatureCommentSerializer(many=True, read_only=True)

    class Meta:
        model = FeatureRequest
        fields = [
            'id', 'title', 'description', 'category', 'status',
            'submitted_by', 'submitted_by_email', 'submitted_by_name',
            'public_response', 'target_release',
            'upvotes', 'downvotes', 'vote_score', 'user_vote',
            'comments', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'submitted_by', 'status', 'public_response', 'target_release',
            'upvotes', 'downvotes', 'created_at', 'updated_at'
        ]

    def get_submitted_by_name(self, obj: FeatureRequest) -> str:
        if obj.submitted_by:
            name = f"{obj.submitted_by.first_name} {obj.submitted_by.last_name}".strip()
            return name or obj.submitted_by.email
        return 'Deleted User'

    def get_user_vote(self, obj: FeatureRequest) -> str | None:
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = obj.votes.filter(user=request.user).first()
            if vote:
                return vote.vote_type
        return None


class CreateFeatureRequestSerializer(serializers.ModelSerializer[FeatureRequest]):
    """Serializer for creating new feature requests."""

    class Meta:
        model = FeatureRequest
        fields = ['title', 'description', 'category']

    def validate_title(self, value: str) -> str:
        if len(value) < 10:
            raise serializers.ValidationError(
                "Title must be at least 10 characters long."
            )
        return value

    def validate_description(self, value: str) -> str:
        if len(value) < 30:
            raise serializers.ValidationError(
                "Description must be at least 30 characters long."
            )
        return value


class AdminUpdateStatusSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin status updates."""
    status = serializers.ChoiceField(choices=FeatureRequest.Status.choices)
    public_response = serializers.CharField(required=False, allow_blank=True)
    admin_notes = serializers.CharField(required=False, allow_blank=True)
    target_release = serializers.CharField(required=False, allow_blank=True)

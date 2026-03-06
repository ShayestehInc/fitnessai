"""
Serializers for Space and SpaceMembership.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from ..models import Space, SpaceMembership


class SpaceSerializer(serializers.ModelSerializer[Space]):
    """Read serializer for spaces."""
    member_count = serializers.IntegerField(read_only=True, default=0)
    is_member = serializers.BooleanField(read_only=True, default=False)
    cover_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Space
        fields = [
            'id', 'name', 'description', 'cover_image_url', 'emoji',
            'visibility', 'is_default', 'sort_order', 'created_at',
            'member_count', 'is_member',
        ]
        read_only_fields = ['id', 'created_at']

    def get_cover_image_url(self, obj: Space) -> str | None:
        request = self.context.get('request')
        if obj.cover_image and request is not None:
            return request.build_absolute_uri(obj.cover_image.url)
        return None


class SpaceCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates space creation/update."""
    name = serializers.CharField(max_length=200)
    description = serializers.CharField(max_length=2000, required=False, default='')
    emoji = serializers.CharField(max_length=10, required=False, default='💬')
    visibility = serializers.ChoiceField(
        choices=Space.Visibility.choices,
        required=False,
        default=Space.Visibility.PUBLIC,
    )
    is_default = serializers.BooleanField(required=False, default=False)
    sort_order = serializers.IntegerField(required=False, default=0, min_value=0)

    def validate_name(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError("Space name cannot be empty.")
        return stripped


class SpaceMembershipSerializer(serializers.ModelSerializer[SpaceMembership]):
    """Read serializer for space memberships."""
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    profile_image = serializers.SerializerMethodField()

    class Meta:
        model = SpaceMembership
        fields = [
            'user_id', 'first_name', 'last_name', 'profile_image',
            'role', 'joined_at', 'is_muted',
        ]

    def get_profile_image(self, obj: SpaceMembership) -> str | None:
        request = self.context.get('request')
        if obj.user.profile_image and request is not None:
            return request.build_absolute_uri(obj.user.profile_image.url)
        return None

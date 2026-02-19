"""
Serializers for the messaging app.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import Conversation, Message


# ---------------------------------------------------------------------------
# Input serializers (validation)
# ---------------------------------------------------------------------------

class SendMessageSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates message send request."""
    content = serializers.CharField(max_length=2000)

    def validate_content(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError('Message content cannot be empty.')
        return stripped


class StartConversationSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates starting a new conversation (trainer -> trainee)."""
    trainee_id = serializers.IntegerField()
    content = serializers.CharField(max_length=2000)

    def validate_content(self, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise serializers.ValidationError('Message content cannot be empty.')
        return stripped


# ---------------------------------------------------------------------------
# Output serializers (response)
# ---------------------------------------------------------------------------

class MessageSenderSerializer(serializers.Serializer[dict[str, Any]]):
    """Minimal sender info in a message."""
    id = serializers.IntegerField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    profile_image = serializers.SerializerMethodField()

    def get_profile_image(self, obj: Any) -> str | None:
        request = self.context.get('request')
        if hasattr(obj, 'profile_image') and obj.profile_image and request is not None:
            return request.build_absolute_uri(obj.profile_image.url)
        return None


class MessageSerializer(serializers.ModelSerializer[Message]):
    """Serializer for a single message."""
    sender = MessageSenderSerializer(read_only=True)

    class Meta:
        model = Message
        fields = [
            'id', 'conversation_id', 'sender', 'content',
            'is_read', 'read_at', 'created_at',
        ]
        read_only_fields = [
            'id', 'conversation_id', 'sender', 'content',
            'is_read', 'read_at', 'created_at',
        ]


class ConversationParticipantSerializer(serializers.Serializer[dict[str, Any]]):
    """Minimal participant info for conversation list."""
    id = serializers.IntegerField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    email = serializers.EmailField()
    profile_image = serializers.SerializerMethodField()

    def get_profile_image(self, obj: Any) -> str | None:
        request = self.context.get('request')
        if hasattr(obj, 'profile_image') and obj.profile_image and request is not None:
            return request.build_absolute_uri(obj.profile_image.url)
        return None


class ConversationListSerializer(serializers.ModelSerializer[Conversation]):
    """Serializer for the conversation list view."""
    trainer = ConversationParticipantSerializer(read_only=True)
    trainee = ConversationParticipantSerializer(read_only=True)
    last_message_preview = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id', 'trainer', 'trainee', 'last_message_at',
            'last_message_preview', 'unread_count', 'is_archived',
            'created_at',
        ]
        read_only_fields = [
            'id', 'trainer', 'trainee', 'last_message_at',
            'last_message_preview', 'unread_count', 'is_archived',
            'created_at',
        ]

    def get_last_message_preview(self, obj: Conversation) -> str | None:
        """Return the last message content truncated to 100 chars."""
        last_msg = (
            Message.objects.filter(conversation=obj)
            .order_by('-created_at')
            .values_list('content', flat=True)
            .first()
        )
        if last_msg is None:
            return None
        return last_msg[:100] if len(last_msg) > 100 else last_msg

    def get_unread_count(self, obj: Conversation) -> int:
        """Return unread message count for the requesting user."""
        request = self.context.get('request')
        if request is None or not hasattr(request, 'user'):
            return 0
        user = request.user
        return Message.objects.filter(
            conversation=obj,
            is_read=False,
        ).exclude(
            sender=user,
        ).count()

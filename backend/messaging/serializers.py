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

class SendMessageSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Validates message send request. Either content or image (or both) must be provided."""
    content = serializers.CharField(max_length=2000, required=False, default='')

    def validate_content(self, value: str) -> str:
        return value.strip()

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        # Image is handled separately in the view (file upload validation).
        # This serializer only validates the text content field.
        # The view enforces that at least one of content/image is present.
        return attrs


class StartConversationSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Validates starting a new conversation (trainer -> trainee)."""
    trainee_id = serializers.IntegerField()
    content = serializers.CharField(max_length=2000, required=False, default='')

    def validate_content(self, value: str) -> str:
        return value.strip()


# ---------------------------------------------------------------------------
# Output serializers (response)
# ---------------------------------------------------------------------------

class MessageSenderSerializer(serializers.Serializer):  # type: ignore[type-arg]
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


class EditMessageSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Validates message edit request."""
    content = serializers.CharField(max_length=2000, required=True)

    def validate_content(self, value: str) -> str:
        return value.strip()


class MessageSerializer(serializers.ModelSerializer[Message]):
    """Serializer for a single message."""
    sender = MessageSenderSerializer(read_only=True)
    image = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id', 'conversation_id', 'sender', 'content',
            'image', 'is_read', 'read_at', 'edited_at',
            'is_deleted', 'created_at',
        ]
        read_only_fields = [
            'id', 'conversation_id', 'sender', 'content',
            'image', 'is_read', 'read_at', 'edited_at',
            'is_deleted', 'created_at',
        ]

    def get_image(self, obj: Message) -> str | None:
        if not obj.image:
            return None
        request = self.context.get('request')
        if request is not None:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url


class ConversationParticipantSerializer(serializers.Serializer):  # type: ignore[type-arg]
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
        """Return the last message content truncated to 100 chars.

        Uses the ``annotated_last_message_preview`` annotation added by
        ``get_conversations_for_user()`` to avoid N+1 queries.
        Falls back to "Sent a photo" when the last message has an image
        but no text content, or "This message was deleted" when the last
        message is soft-deleted.
        """
        is_deleted = getattr(obj, 'annotated_last_message_is_deleted', False)
        if is_deleted:
            return 'This message was deleted'

        preview = getattr(obj, 'annotated_last_message_preview', None)
        if not preview:
            has_image = getattr(obj, 'annotated_last_message_has_image', False)
            if has_image:
                return 'Sent a photo'
        return preview

    def get_unread_count(self, obj: Conversation) -> int:
        """Return unread message count for the requesting user.

        Uses the ``annotated_unread_count`` annotation added by
        ``get_conversations_for_user()`` to avoid N+1 queries.
        """
        return getattr(obj, 'annotated_unread_count', 0)

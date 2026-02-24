"""
Serializers for persistent AI chat threads and messages.
"""
from __future__ import annotations

from rest_framework import serializers

from trainer.models import AIChatMessage, AIChatThread


# ---------------------------------------------------------------------------
# Input serializers
# ---------------------------------------------------------------------------

class CreateThreadSerializer(serializers.Serializer):
    """Validate input for creating a new AI chat thread."""
    title = serializers.CharField(max_length=200, required=False, default='New conversation')
    trainee_context_id = serializers.IntegerField(required=False, allow_null=True, default=None)


class RenameThreadSerializer(serializers.Serializer):
    """Validate input for renaming a thread."""
    title = serializers.CharField(max_length=200)


class SendMessageSerializer(serializers.Serializer):
    """Validate input for sending a message to a thread."""
    message = serializers.CharField(max_length=5000)
    trainee_id = serializers.IntegerField(required=False, allow_null=True, default=None)


# ---------------------------------------------------------------------------
# Output serializers
# ---------------------------------------------------------------------------

class AIChatMessageSerializer(serializers.ModelSerializer):
    """Serialize a single AI chat message."""

    class Meta:
        model = AIChatMessage
        fields = ['id', 'role', 'content', 'provider', 'model_name', 'created_at']
        read_only_fields = fields


class AIChatThreadListSerializer(serializers.ModelSerializer):
    """Serialize thread for the sidebar list, with message count."""
    message_count = serializers.IntegerField(read_only=True)
    trainee_context_name = serializers.SerializerMethodField()

    class Meta:
        model = AIChatThread
        fields = [
            'id', 'title', 'trainee_context_id', 'trainee_context_name',
            'last_message_at', 'message_count', 'created_at',
        ]
        read_only_fields = fields

    def get_trainee_context_name(self, obj: AIChatThread) -> str | None:
        if obj.trainee_context is None:
            return None
        name = f"{obj.trainee_context.first_name} {obj.trainee_context.last_name}".strip()
        return name or obj.trainee_context.email


class AIChatThreadDetailSerializer(serializers.ModelSerializer):
    """Serialize thread detail with nested messages."""
    messages = AIChatMessageSerializer(many=True, read_only=True)
    trainee_context_name = serializers.SerializerMethodField()

    class Meta:
        model = AIChatThread
        fields = [
            'id', 'title', 'trainee_context_id', 'trainee_context_name',
            'last_message_at', 'created_at', 'messages',
        ]
        read_only_fields = fields

    def get_trainee_context_name(self, obj: AIChatThread) -> str | None:
        if obj.trainee_context is None:
            return None
        name = f"{obj.trainee_context.first_name} {obj.trainee_context.last_name}".strip()
        return name or obj.trainee_context.email


class SendMessageResponseSerializer(serializers.Serializer):
    """Serialize the response from sending a message."""
    user_message = AIChatMessageSerializer()
    assistant_message = AIChatMessageSerializer()
    thread_title = serializers.CharField()

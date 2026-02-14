"""
Serializers for trainer notification endpoints.
"""
from __future__ import annotations

from rest_framework import serializers

from .models import TrainerNotification


class TrainerNotificationSerializer(serializers.ModelSerializer[TrainerNotification]):
    """Read-only serializer for trainer notifications."""

    class Meta:
        model = TrainerNotification
        fields = [
            'id',
            'notification_type',
            'title',
            'message',
            'data',
            'is_read',
            'read_at',
            'created_at',
        ]
        read_only_fields = fields

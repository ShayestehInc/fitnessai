from __future__ import annotations

from typing import Any

from rest_framework import serializers
from .models import CalendarConnection, CalendarEvent, TrainerAvailability


class CalendarConnectionSerializer(serializers.ModelSerializer[CalendarConnection]):
    """Serializer for calendar connections."""

    provider_display = serializers.CharField(source='get_provider_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_connected = serializers.BooleanField(read_only=True)

    class Meta:
        model = CalendarConnection
        fields = [
            'id', 'provider', 'provider_display', 'status', 'status_display',
            'is_connected', 'calendar_email', 'calendar_name',
            'sync_enabled', 'last_synced_at', 'created_at'
        ]
        read_only_fields = ['id', 'status', 'calendar_email', 'calendar_name', 'last_synced_at', 'created_at']


class CalendarEventSerializer(serializers.ModelSerializer[CalendarEvent]):
    """Serializer for calendar events."""

    provider = serializers.CharField(source='connection.provider', read_only=True)

    class Meta:
        model = CalendarEvent
        fields = [
            'id', 'external_id', 'title', 'description', 'location',
            'start_time', 'end_time', 'all_day', 'timezone',
            'event_type', 'external_link', 'is_recurring', 'synced_at',
            'provider',
        ]
        read_only_fields = ['id', 'external_id', 'synced_at', 'provider']


class TrainerAvailabilitySerializer(serializers.ModelSerializer[TrainerAvailability]):
    """Serializer for trainer availability slots."""

    day_display = serializers.CharField(source='get_day_of_week_display', read_only=True)

    class Meta:
        model = TrainerAvailability
        fields = [
            'id', 'day_of_week', 'day_display', 'start_time', 'end_time', 'is_active'
        ]


class OAuthCallbackSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for OAuth callback data."""

    code = serializers.CharField(required=True, max_length=2048, min_length=1)
    state = serializers.CharField(required=True, max_length=256, min_length=1)


class CreateEventSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for creating calendar events."""

    title = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True, max_length=8192)
    location = serializers.CharField(required=False, allow_blank=True, max_length=500)
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()
    attendee_emails = serializers.ListField(
        child=serializers.EmailField(),
        required=False,
        default=list,
        max_length=50
    )
    provider = serializers.ChoiceField(
        choices=CalendarConnection.Provider.choices,
        required=False
    )

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if attrs['end_time'] <= attrs['start_time']:
            raise serializers.ValidationError(
                {'end_time': 'End time must be after start time.'}
            )
        return attrs

"""
Serializers for Community Events and RSVPs.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from ..models import CommunityEvent, EventRSVP


class EventRSVPSerializer(serializers.ModelSerializer[EventRSVP]):
    """Read serializer for an event RSVP."""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_first_name = serializers.CharField(source='user.first_name', read_only=True)
    user_last_name = serializers.CharField(source='user.last_name', read_only=True)

    class Meta:
        model = EventRSVP
        fields = [
            'id', 'user_id', 'user_email', 'user_first_name', 'user_last_name',
            'status', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CommunityEventSerializer(serializers.ModelSerializer[CommunityEvent]):
    """Read serializer for a community event."""
    attendee_counts = serializers.SerializerMethodField()
    my_rsvp = serializers.SerializerMethodField()

    class Meta:
        model = CommunityEvent
        fields = [
            'id', 'title', 'description', 'event_type', 'status',
            'starts_at', 'ends_at', 'meeting_url', 'max_attendees',
            'location_address', 'location_lat', 'location_lng',
            'is_recurring', 'recurrence_rule', 'space',
            'attendee_counts', 'my_rsvp',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_attendee_counts(self, obj: CommunityEvent) -> dict[str, int]:
        from ..services.event_service import EventService
        return EventService.get_attendee_count(obj)

    def get_my_rsvp(self, obj: CommunityEvent) -> str | None:
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        rsvp = obj.rsvps.filter(user=request.user).first()
        return rsvp.status if rsvp else None


class CommunityEventCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates creation / update of a community event."""
    title = serializers.CharField(max_length=200)
    description = serializers.CharField(
        max_length=2000, required=False, allow_blank=True, default='',
    )
    event_type = serializers.ChoiceField(
        choices=CommunityEvent.EventType.choices,
        default=CommunityEvent.EventType.LIVE_SESSION,
    )
    starts_at = serializers.DateTimeField()
    ends_at = serializers.DateTimeField()
    meeting_url = serializers.URLField(required=False, allow_blank=True, default='')
    max_attendees = serializers.IntegerField(
        required=False, allow_null=True, default=None, min_value=1,
    )
    location_address = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default='',
    )
    location_lat = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True, default=None,
    )
    location_lng = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True, default=None,
    )
    is_recurring = serializers.BooleanField(default=False)
    recurrence_rule = serializers.JSONField(required=False, default=dict)
    space = serializers.IntegerField(required=False, allow_null=True, default=None)

    def validate(self, data: dict[str, Any]) -> dict[str, Any]:
        if data['ends_at'] <= data['starts_at']:
            raise serializers.ValidationError("ends_at must be after starts_at.")
        return data


class EventRSVPCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates an RSVP action."""
    status = serializers.ChoiceField(choices=EventRSVP.RSVPStatus.choices)

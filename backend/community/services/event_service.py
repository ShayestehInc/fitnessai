"""
Service layer for Community Events:
RSVP management, capacity checks, status transitions.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

from django.db.models import Count, QuerySet
from django.utils import timezone

from users.models import User
from ..models import CommunityEvent, EventRSVP

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class RSVPResult:
    rsvp: EventRSVP
    created: bool
    at_capacity: bool


class EventService:
    """Handles event RSVP and status management."""

    @staticmethod
    def rsvp(event: CommunityEvent, user: User, status: str) -> RSVPResult:
        """
        Create or update an RSVP for an event.
        Enforces max_attendees capacity for 'going' status.
        """
        if status == EventRSVP.RSVPStatus.GOING and event.max_attendees is not None:
            going_count = event.rsvps.filter(
                status=EventRSVP.RSVPStatus.GOING,
            ).exclude(user=user).count()
            if going_count >= event.max_attendees:
                # Still save as 'maybe' but flag capacity
                rsvp, created = EventRSVP.objects.update_or_create(
                    event=event,
                    user=user,
                    defaults={'status': EventRSVP.RSVPStatus.MAYBE},
                )
                return RSVPResult(rsvp=rsvp, created=created, at_capacity=True)

        rsvp, created = EventRSVP.objects.update_or_create(
            event=event,
            user=user,
            defaults={'status': status},
        )
        return RSVPResult(rsvp=rsvp, created=created, at_capacity=False)

    @staticmethod
    def cancel_rsvp(event: CommunityEvent, user: User) -> bool:
        """Remove a user's RSVP. Returns True if deleted."""
        deleted_count, _ = EventRSVP.objects.filter(
            event=event, user=user,
        ).delete()
        return deleted_count > 0

    @staticmethod
    def get_attendee_count(event: CommunityEvent) -> dict[str, int]:
        """Return RSVP counts by status."""
        counts = (
            event.rsvps
            .values('status')
            .annotate(count=Count('id'))
        )
        result = {'going': 0, 'maybe': 0, 'not_going': 0}
        for row in counts:
            result[row['status']] = row['count']
        return result

    @staticmethod
    def transition_status(event: CommunityEvent, new_status: str) -> CommunityEvent:
        """Transition an event's status (e.g. scheduled → live → completed)."""
        event.status = new_status
        event.save(update_fields=['status', 'updated_at'])
        logger.info("Event %s transitioned to %s", event.title, new_status)
        return event

    @staticmethod
    def get_upcoming_events(
        trainer: User,
        limit: int = 10,
    ) -> QuerySet[CommunityEvent]:
        """Return upcoming events for a trainer's community."""
        return CommunityEvent.objects.filter(
            trainer=trainer,
            status__in=[
                CommunityEvent.EventStatus.SCHEDULED,
                CommunityEvent.EventStatus.LIVE,
            ],
            ends_at__gte=timezone.now(),
        ).order_by('starts_at')[:limit]

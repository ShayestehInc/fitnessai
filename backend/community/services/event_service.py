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
        Raises ValueError for cancelled/completed events.
        """
        if event.status in (
            CommunityEvent.EventStatus.CANCELLED,
            CommunityEvent.EventStatus.COMPLETED,
        ):
            raise ValueError(f"Cannot RSVP to a {event.status} event.")

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

    @staticmethod
    def _get_non_banned_trainee_ids(trainer: User) -> list[int]:
        """Return active trainee IDs excluding community-banned users."""
        from ..models import UserBan

        banned_ids = set(
            UserBan.objects.filter(
                trainer=trainer, is_active=True,
            ).values_list('user_id', flat=True)
        )

        trainee_ids = list(
            User.objects.filter(
                parent_trainer=trainer,
                role=User.Role.TRAINEE,
                is_active=True,
            ).values_list('id', flat=True)
        )

        if banned_ids:
            trainee_ids = [uid for uid in trainee_ids if uid not in banned_ids]

        return trainee_ids

    @staticmethod
    def _get_rsvpd_user_ids(event: CommunityEvent) -> list[int]:
        """Return user IDs with going or maybe RSVP for an event."""
        return list(
            EventRSVP.objects.filter(
                event=event,
                status__in=[
                    EventRSVP.RSVPStatus.GOING,
                    EventRSVP.RSVPStatus.MAYBE,
                ],
            ).values_list('user_id', flat=True)
        )

    @staticmethod
    def notify_event_created(event: CommunityEvent) -> None:
        """Push notification to all trainer's trainees about a new event."""
        try:
            from core.services.notification_service import send_push_to_group

            trainee_ids = EventService._get_non_banned_trainee_ids(event.trainer)
            if not trainee_ids:
                return

            send_push_to_group(
                user_ids=trainee_ids,
                title='New Event',
                body=event.title,
                data={
                    'type': 'community_event_created',
                    'event_id': str(event.id),
                },
                category='community_event',
            )
        except Exception:
            logger.warning("Failed to send event created notifications", exc_info=True)

    @staticmethod
    def notify_event_updated(
        event: CommunityEvent,
        changed_fields: set[str],
    ) -> None:
        """Push notification to RSVP'd users (going/maybe) about an event update."""
        try:
            from core.services.notification_service import send_push_to_group

            rsvpd_user_ids = EventService._get_rsvpd_user_ids(event)
            if not rsvpd_user_ids:
                return

            # Build a descriptive body based on what changed
            change_parts: list[str] = []
            if changed_fields & {'starts_at', 'ends_at'}:
                change_parts.append('time changed')
            if 'meeting_url' in changed_fields:
                change_parts.append('meeting link updated')
            change_desc = ' — ' + ', '.join(change_parts) if change_parts else ''

            send_push_to_group(
                user_ids=rsvpd_user_ids,
                title='Event Updated',
                body=f'{event.title}{change_desc}',
                data={
                    'type': 'community_event_updated',
                    'event_id': str(event.id),
                },
                category='community_event',
            )
        except Exception:
            logger.warning("Failed to send event updated notifications", exc_info=True)

    @staticmethod
    def notify_event_cancelled(event: CommunityEvent) -> None:
        """Push notification to RSVP'd users (going/maybe) that an event was cancelled."""
        try:
            from core.services.notification_service import send_push_to_group

            rsvpd_user_ids = EventService._get_rsvpd_user_ids(event)
            if not rsvpd_user_ids:
                return

            send_push_to_group(
                user_ids=rsvpd_user_ids,
                title='Event Cancelled',
                body=event.title,
                data={
                    'type': 'community_event_cancelled',
                    'event_id': str(event.id),
                },
                category='community_event',
            )
        except Exception:
            logger.warning("Failed to send event cancelled notifications", exc_info=True)

    @staticmethod
    def send_event_reminders() -> int:
        """
        Send push notifications to users with 'going' RSVP for events
        starting in 10-15 minutes from now.

        The cron schedule should be `*/5 * * * *` (every 5 minutes).
        Using a 5-minute window (10-15 min before start) ensures each
        event matches exactly one cron run, preventing duplicate sends.
        Users receive the reminder approximately 10-15 minutes before start.

        Returns the number of events for which reminders were sent.
        """
        from core.services.notification_service import send_push_to_group

        now = timezone.now()
        reminder_window_start = now + timezone.timedelta(minutes=10)
        reminder_window_end = now + timezone.timedelta(minutes=15)

        events = list(
            CommunityEvent.objects.filter(
                status=CommunityEvent.EventStatus.SCHEDULED,
                starts_at__gt=reminder_window_start,
                starts_at__lte=reminder_window_end,
            ).select_related('trainer')
        )

        if not events:
            return 0

        # Batch: fetch all RSVPs for matched events in one query
        event_ids = [e.id for e in events]
        rsvps = (
            EventRSVP.objects.filter(
                event_id__in=event_ids,
                status=EventRSVP.RSVPStatus.GOING,
            ).values_list('event_id', 'user_id')
        )
        event_user_map: dict[int, list[int]] = {}
        for event_id, user_id in rsvps:
            event_user_map.setdefault(event_id, []).append(user_id)

        reminded_count = 0
        for event in events:
            going_user_ids = event_user_map.get(event.id, [])
            if not going_user_ids:
                continue
            try:
                send_push_to_group(
                    user_ids=going_user_ids,
                    title='Event Reminder',
                    body=f'{event.title} starts soon',
                    data={
                        'type': 'community_event_reminder',
                        'event_id': str(event.id),
                    },
                    category='community_event',
                )
                reminded_count += 1
            except Exception:
                logger.warning(
                    "Failed to send reminder for event %d", event.id, exc_info=True,
                )

        return reminded_count

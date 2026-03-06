"""
Management command to send push notifications for upcoming community events.

Sends reminders to users with 'going' RSVP for events starting within 15 minutes.
Designed to be run on a cron schedule: */5 * * * * (every 5 minutes).
"""
from __future__ import annotations

from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Send push notification reminders for community events starting within 15 minutes.'

    def handle(self, *args: object, **options: object) -> None:
        from community.services.event_service import EventService

        reminded_count = EventService.send_event_reminders()
        self.stdout.write(
            self.style.SUCCESS(f'Sent reminders for {reminded_count} event(s).')
        )

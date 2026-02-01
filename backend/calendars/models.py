from __future__ import annotations

import base64
from datetime import timedelta
from typing import Optional

from cryptography.fernet import Fernet
from django.conf import settings
from django.db import models
from django.utils import timezone


def get_encryption_key() -> bytes:
    """Get or create encryption key for token storage."""
    key = getattr(settings, 'CALENDAR_ENCRYPTION_KEY', None)
    if key:
        return key.encode() if isinstance(key, str) else key
    # Fallback to a derived key from SECRET_KEY (not ideal for production)
    secret = settings.SECRET_KEY.encode()
    return base64.urlsafe_b64encode(secret[:32].ljust(32, b'0'))


class CalendarConnection(models.Model):
    """
    Stores OAuth tokens for calendar integrations.
    Tokens are encrypted at rest for security.
    """

    class Provider(models.TextChoices):
        GOOGLE = 'google', 'Google Calendar'
        MICROSOFT = 'microsoft', 'Microsoft Outlook'

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending Authorization'
        CONNECTED = 'connected', 'Connected'
        EXPIRED = 'expired', 'Token Expired'
        REVOKED = 'revoked', 'Access Revoked'
        ERROR = 'error', 'Connection Error'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='calendar_connections',
        limit_choices_to={'role': 'TRAINER'}
    )
    provider = models.CharField(max_length=20, choices=Provider.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    # Encrypted token storage
    _access_token = models.TextField(blank=True, db_column='access_token')
    _refresh_token = models.TextField(blank=True, db_column='refresh_token')

    # Token metadata
    token_expires_at = models.DateTimeField(null=True, blank=True)
    scopes = models.JSONField(default=list)

    # Calendar info
    calendar_id = models.CharField(max_length=255, blank=True)
    calendar_email = models.EmailField(blank=True)
    calendar_name = models.CharField(max_length=255, blank=True)

    # Sync settings
    sync_enabled = models.BooleanField(default=True)
    last_synced_at = models.DateTimeField(null=True, blank=True)
    sync_error = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [['user', 'provider']]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.user.email} - {self.get_provider_display()}"

    def _encrypt(self, value: str) -> str:
        """Encrypt a value for storage."""
        if not value:
            return ''
        f = Fernet(get_encryption_key())
        return f.encrypt(value.encode()).decode()

    def _decrypt(self, value: str) -> str:
        """Decrypt a stored value."""
        if not value:
            return ''
        try:
            f = Fernet(get_encryption_key())
            return f.decrypt(value.encode()).decode()
        except Exception:
            return ''

    @property
    def access_token(self) -> str:
        return self._decrypt(self._access_token)

    @access_token.setter
    def access_token(self, value: str) -> None:
        self._access_token = self._encrypt(value)

    @property
    def refresh_token(self) -> str:
        return self._decrypt(self._refresh_token)

    @refresh_token.setter
    def refresh_token(self, value: str) -> None:
        self._refresh_token = self._encrypt(value)

    @property
    def is_token_expired(self) -> bool:
        if not self.token_expires_at:
            return True
        return timezone.now() >= self.token_expires_at

    @property
    def is_connected(self) -> bool:
        return self.status == self.Status.CONNECTED and not self.is_token_expired

    def update_tokens(
        self,
        access_token: str,
        refresh_token: Optional[str] = None,
        expires_in: Optional[int] = None,
    ) -> None:
        """Update OAuth tokens after refresh or initial auth."""
        self.access_token = access_token
        if refresh_token:
            self.refresh_token = refresh_token
        if expires_in:
            self.token_expires_at = timezone.now() + timedelta(seconds=expires_in)
        self.status = self.Status.CONNECTED
        self.sync_error = ''
        self.save()

    def mark_expired(self) -> None:
        """Mark the connection as expired."""
        self.status = self.Status.EXPIRED
        self.save()

    def mark_error(self, error_message: str) -> None:
        """Mark the connection as having an error."""
        self.status = self.Status.ERROR
        self.sync_error = error_message
        self.save()

    def disconnect(self) -> None:
        """Disconnect and clear tokens."""
        self.status = self.Status.REVOKED
        self._access_token = ''
        self._refresh_token = ''
        self.token_expires_at = None
        self.save()


class CalendarEvent(models.Model):
    """
    Cached calendar events for display and scheduling.
    """

    class EventType(models.TextChoices):
        SESSION = 'session', 'Training Session'
        AVAILABILITY = 'availability', 'Available Slot'
        BLOCKED = 'blocked', 'Blocked Time'
        EXTERNAL = 'external', 'External Event'

    connection = models.ForeignKey(
        CalendarConnection,
        on_delete=models.CASCADE,
        related_name='events'
    )

    # External calendar reference
    external_id = models.CharField(max_length=255)
    external_link = models.URLField(blank=True)

    # Event details
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    location = models.CharField(max_length=500, blank=True)

    # Timing
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    all_day = models.BooleanField(default=False)
    timezone = models.CharField(max_length=50, default='UTC')

    # Classification
    event_type = models.CharField(
        max_length=20,
        choices=EventType.choices,
        default=EventType.EXTERNAL
    )

    # Attendees (for training sessions)
    trainee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='calendar_sessions'
    )

    # Metadata
    is_recurring = models.BooleanField(default=False)
    recurrence_rule = models.CharField(max_length=255, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    synced_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [['connection', 'external_id']]
        ordering = ['start_time']

    def __str__(self) -> str:
        return f"{self.title} ({self.start_time.strftime('%Y-%m-%d %H:%M')})"


class TrainerAvailability(models.Model):
    """
    Trainer's recurring availability schedule.
    """

    class DayOfWeek(models.IntegerChoices):
        MONDAY = 0, 'Monday'
        TUESDAY = 1, 'Tuesday'
        WEDNESDAY = 2, 'Wednesday'
        THURSDAY = 3, 'Thursday'
        FRIDAY = 4, 'Friday'
        SATURDAY = 5, 'Saturday'
        SUNDAY = 6, 'Sunday'

    trainer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='availability_slots',
        limit_choices_to={'role': 'TRAINER'}
    )

    day_of_week = models.IntegerField(choices=DayOfWeek.choices)
    start_time = models.TimeField()
    end_time = models.TimeField()

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['day_of_week', 'start_time']

    def __str__(self) -> str:
        return f"{self.trainer.email} - {self.get_day_of_week_display()} {self.start_time}-{self.end_time}"

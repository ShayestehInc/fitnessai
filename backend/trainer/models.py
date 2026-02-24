"""
Trainer-specific models for managing trainees, invitations, and impersonation sessions.
"""
from __future__ import annotations

import os
import re
import secrets
import uuid
from datetime import timedelta
from typing import Any, Optional

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


HEX_COLOR_REGEX: re.Pattern[str] = re.compile(r'^#[0-9A-Fa-f]{6}$')


class TraineeInvitation(models.Model):
    """Invitation for new trainees to join a trainer."""

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACCEPTED = 'accepted', 'Accepted'
        EXPIRED = 'expired', 'Expired'
        CANCELLED = 'cancelled', 'Cancelled'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='sent_invitations',
        limit_choices_to={'role': 'TRAINER'}
    )
    email = models.EmailField()
    invitation_code = models.CharField(max_length=64, unique=True)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    program_template = models.ForeignKey(
        'workouts.ProgramTemplate',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Optional program template to assign upon acceptance"
    )
    message = models.TextField(
        blank=True,
        help_text="Personal message from trainer to include in invitation"
    )
    expires_at = models.DateTimeField()
    accepted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'trainee_invitations'
        indexes = [
            models.Index(fields=['invitation_code']),
            models.Index(fields=['email']),
            models.Index(fields=['trainer', 'status']),
        ]

    def __str__(self) -> str:
        return f"Invitation to {self.email} from {self.trainer.email}"

    def save(self, *args: Any, **kwargs: Any) -> None:
        if not self.invitation_code:
            self.invitation_code = secrets.token_urlsafe(32)
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(days=7)
        super().save(*args, **kwargs)

    @property
    def is_expired(self) -> bool:
        return timezone.now() > self.expires_at

    def mark_accepted(self) -> None:
        """Mark invitation as accepted."""
        self.status = self.Status.ACCEPTED
        self.accepted_at = timezone.now()
        self.save()


class TrainerSession(models.Model):
    """
    Tracks 'Login as Trainee' (impersonation) sessions for audit purposes.
    Allows trainers to view their trainee's app experience.
    """
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='impersonation_sessions',
        limit_choices_to={'role': 'TRAINER'}
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='impersonated_sessions',
        limit_choices_to={'role': 'TRAINEE'}
    )
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    # Actions taken during session for audit trail
    # Structure: [{"action": "view_log", "timestamp": "...", "details": {...}}]
    actions_log = models.JSONField(default=list)

    is_read_only = models.BooleanField(
        default=True,
        help_text="If True, trainer can only view data. If False, can make changes."
    )

    class Meta:
        db_table = 'trainer_sessions'
        indexes = [
            models.Index(fields=['trainer']),
            models.Index(fields=['trainee']),
            models.Index(fields=['started_at']),
        ]
        ordering = ['-started_at']

    def __str__(self) -> str:
        return f"{self.trainer.email} as {self.trainee.email} at {self.started_at}"

    @property
    def is_active(self) -> bool:
        return self.ended_at is None

    @property
    def duration_minutes(self) -> int:
        end = self.ended_at or timezone.now()
        return int((end - self.started_at).total_seconds() / 60)

    def log_action(self, action: str, details: Optional[dict[str, Any]] = None) -> None:
        """Log an action taken during the session."""
        self.actions_log.append({
            'action': action,
            'timestamp': timezone.now().isoformat(),
            'details': details or {}
        })
        self.save(update_fields=['actions_log'])

    def end_session(self) -> None:
        """End the impersonation session."""
        self.ended_at = timezone.now()
        self.save(update_fields=['ended_at'])


class TraineeActivitySummary(models.Model):
    """
    Cached daily summary of trainee activity for efficient dashboard display.
    Updated via signals or periodic tasks.
    """
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='activity_summaries',
        limit_choices_to={'role': 'TRAINEE'}
    )
    date = models.DateField()

    # Workout metrics
    workouts_completed = models.PositiveIntegerField(default=0)
    total_sets = models.PositiveIntegerField(default=0)
    total_volume = models.FloatField(
        default=0,
        help_text="Total weight x reps in kg"
    )

    # Nutrition metrics
    calories_consumed = models.PositiveIntegerField(default=0)
    protein_consumed = models.PositiveIntegerField(default=0)
    carbs_consumed = models.PositiveIntegerField(default=0)
    fat_consumed = models.PositiveIntegerField(default=0)

    # Compliance flags
    logged_food = models.BooleanField(default=False)
    logged_workout = models.BooleanField(default=False)
    hit_protein_goal = models.BooleanField(default=False)
    hit_calorie_goal = models.BooleanField(default=False)

    # Health metrics
    steps = models.PositiveIntegerField(default=0)
    sleep_hours = models.FloatField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'trainee_activity_summaries'
        unique_together = [['trainee', 'date']]
        indexes = [
            models.Index(fields=['trainee', 'date']),
            models.Index(fields=['date']),
        ]
        ordering = ['-date']

    def __str__(self) -> str:
        return f"{self.trainee.email} - {self.date}"


class TrainerNotification(models.Model):
    """
    In-app notifications for trainers.
    Used to notify trainers about trainee activity, survey results, etc.
    """

    class NotificationType(models.TextChoices):
        TRAINEE_READINESS = 'trainee_readiness', 'Trainee Readiness'
        WORKOUT_COMPLETED = 'workout_completed', 'Workout Completed'
        WORKOUT_MISSED = 'workout_missed', 'Workout Missed'
        GOAL_HIT = 'goal_hit', 'Goal Hit'
        CHECK_IN = 'check_in', 'Check In'
        MESSAGE = 'message', 'Message'
        GENERAL = 'general', 'General'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='trainer_notifications',
        limit_choices_to={'role': 'TRAINER'}
    )
    notification_type = models.CharField(
        max_length=30,
        choices=NotificationType.choices,
        default=NotificationType.GENERAL
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    data = models.JSONField(
        default=dict,
        help_text="Additional data associated with the notification"
    )
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'trainer_notifications'
        indexes = [
            models.Index(fields=['trainer', 'is_read']),
            models.Index(fields=['trainer', '-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.notification_type}: {self.title}"

    def mark_read(self) -> None:
        """Mark notification as read."""
        self.is_read = True
        self.read_at = timezone.now()
        self.save(update_fields=['is_read', 'read_at'])


class WorkoutLayoutConfig(models.Model):
    """
    Per-trainee workout layout configuration.
    Trainers choose which workout UI their trainees see: classic table, card swipe, or minimal list.
    """

    class LayoutType(models.TextChoices):
        CLASSIC = 'classic', 'Classic'
        CARD = 'card', 'Card'
        MINIMAL = 'minimal', 'Minimal'

    trainee = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='workout_layout_config',
        limit_choices_to={'role': 'TRAINEE'}
    )
    layout_type = models.CharField(
        max_length=20,
        choices=LayoutType.choices,
        default=LayoutType.CLASSIC,
        help_text="Which workout UI the trainee sees: classic (table), card (swipe), minimal (list)"
    )
    config_options = models.JSONField(
        default=dict,
        blank=True,
        help_text="Future per-layout settings (show_previous, auto_rest_timer, etc.)"
    )
    configured_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='configured_layouts',
        limit_choices_to={'role': 'TRAINER'}
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'workout_layout_configs'
        indexes = [
            models.Index(fields=['trainee']),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} — {self.layout_type}"


def _branding_logo_upload_path(instance: 'TrainerBranding', filename: str) -> str:
    """Generate a safe upload path for branding logos using UUID.

    Prevents path traversal attacks by ignoring the client-supplied filename
    and generating a UUID-based name with the original file extension.
    """
    ext = os.path.splitext(filename)[1].lower()
    # Only allow known image extensions as a safety belt
    if ext not in ('.jpg', '.jpeg', '.png', '.webp'):
        ext = '.png'
    safe_name = f"{uuid.uuid4().hex}{ext}"
    return f"branding/{safe_name}"


def validate_hex_color(value: str) -> None:
    """Validate that a value is a valid hex color string like #6366F1."""
    if not HEX_COLOR_REGEX.match(value):
        raise ValidationError(
            f"'{value}' is not a valid hex color. Use format #RRGGBB (e.g. #6366F1)."
        )


class TrainerBranding(models.Model):
    """
    Per-trainer white-label branding configuration.
    Trainers customize colors, logo, and app name that their trainees see.
    """

    DEFAULT_PRIMARY_COLOR: str = '#6366F1'
    DEFAULT_SECONDARY_COLOR: str = '#818CF8'
    DEFAULT_APP_NAME: str = ''

    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='branding',
        limit_choices_to={'role': 'TRAINER'},
    )
    app_name = models.CharField(
        max_length=50,
        blank=True,
        default='',
        help_text="Custom app name shown to trainees (e.g. 'FitPro by Coach Jane')",
    )
    primary_color = models.CharField(
        max_length=7,
        default=DEFAULT_PRIMARY_COLOR,
        validators=[validate_hex_color],
        help_text="Primary brand color in hex format (e.g. #6366F1)",
    )
    secondary_color = models.CharField(
        max_length=7,
        default=DEFAULT_SECONDARY_COLOR,
        validators=[validate_hex_color],
        help_text="Secondary brand color in hex format (e.g. #818CF8)",
    )
    logo = models.ImageField(
        upload_to=_branding_logo_upload_path,
        blank=True,
        null=True,
        help_text="Trainer logo image (JPEG/PNG/WebP, max 2MB, 128x128 to 1024x1024)",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'trainer_branding'

    def __str__(self) -> str:
        label = self.app_name or 'Default'
        return f"{self.trainer.email} — {label}"

    @classmethod
    def get_or_create_for_trainer(cls, trainer: 'User') -> tuple['TrainerBranding', bool]:
        """Get or create branding for a trainer with sensible defaults."""
        return cls.objects.get_or_create(
            trainer=trainer,
            defaults={
                'primary_color': cls.DEFAULT_PRIMARY_COLOR,
                'secondary_color': cls.DEFAULT_SECONDARY_COLOR,
            },
        )


class AIChatThread(models.Model):
    """
    Persistent AI chat thread for a trainer.

    Each thread stores a conversation with the AI assistant, optionally
    scoped to a specific trainee for context.
    """

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='ai_chat_threads',
        limit_choices_to={'role': 'TRAINER'},
    )
    trainee_context = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ai_chat_context_threads',
        limit_choices_to={'role': 'TRAINEE'},
        help_text="Optional trainee to scope AI context to",
    )
    title = models.CharField(max_length=200, default='New conversation')
    last_message_at = models.DateTimeField(null=True, blank=True)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ai_chat_threads'
        indexes = [
            models.Index(fields=['trainer', '-last_message_at']),
            models.Index(fields=['trainer', 'is_deleted']),
        ]
        ordering = ['-last_message_at']

    def __str__(self) -> str:
        return f"{self.trainer.email} — {self.title}"


class AIChatMessage(models.Model):
    """
    A single message in an AI chat thread.

    Stores both user and assistant messages for full conversation replay.
    """

    class Role(models.TextChoices):
        USER = 'user', 'User'
        ASSISTANT = 'assistant', 'Assistant'

    thread = models.ForeignKey(
        AIChatThread,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    role = models.CharField(max_length=10, choices=Role.choices)
    content = models.TextField()
    provider = models.CharField(max_length=50, blank=True, default='')
    model_name = models.CharField(max_length=100, blank=True, default='')
    usage_metadata = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_chat_messages'
        indexes = [
            models.Index(fields=['thread', 'created_at']),
        ]
        ordering = ['created_at']

    def __str__(self) -> str:
        preview = self.content[:50] if self.content else ''
        return f"[{self.role}] {preview}"

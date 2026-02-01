"""
Trainer-specific models for managing trainees, invitations, and impersonation sessions.
"""
from __future__ import annotations

import secrets
from datetime import timedelta
from typing import Any, Optional

from django.db import models
from django.utils import timezone


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

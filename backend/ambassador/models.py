"""
Ambassador models for referral tracking and commission management.
"""
from __future__ import annotations

import secrets
import string
from decimal import Decimal
from typing import TYPE_CHECKING

from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import IntegrityError, models
from django.utils import timezone

if TYPE_CHECKING:
    from users.models import User

REFERRAL_CODE_LENGTH = 8
REFERRAL_CODE_ALPHABET = string.ascii_uppercase + string.digits


def generate_referral_code() -> str:
    """Generate a unique 8-character alphanumeric referral code."""
    return ''.join(secrets.choice(REFERRAL_CODE_ALPHABET) for _ in range(REFERRAL_CODE_LENGTH))


class AmbassadorProfile(models.Model):
    """
    Extended profile for ambassador users.
    Stores referral code, commission rate, and cached aggregate stats.
    """
    user = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='ambassador_profile',
        limit_choices_to={'role': 'AMBASSADOR'},
    )
    referral_code = models.CharField(
        max_length=20,
        unique=True,
        help_text="Unique 4-20 char alphanumeric referral code (auto-generated or custom)",
    )
    commission_rate = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        default=Decimal('0.20'),
        validators=[MinValueValidator(Decimal('0.00')), MaxValueValidator(Decimal('1.00'))],
        help_text="Commission rate as decimal (0.20 = 20%)",
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Whether the ambassador can earn new commissions",
    )
    total_referrals = models.PositiveIntegerField(
        default=0,
        help_text="Cached count of total referrals",
    )
    total_earnings = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Cached total lifetime earnings",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ambassador_profiles'
        indexes = [
            models.Index(fields=['referral_code']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} ({self.referral_code})"

    def save(self, *args: object, **kwargs: object) -> None:
        if not self.referral_code:
            self.referral_code = self._generate_unique_code()
        # Retry with a new code on unique constraint collision (concurrent generation race)
        max_retries = 3
        for attempt in range(max_retries):
            try:
                super().save(*args, **kwargs)
                return
            except IntegrityError as exc:
                is_code_collision = 'referral_code' in str(exc)
                if attempt < max_retries - 1 and is_code_collision:
                    self.referral_code = self._generate_unique_code()
                else:
                    raise

    def _generate_unique_code(self) -> str:
        """Generate a referral code that doesn't exist yet."""
        for _ in range(100):
            code = generate_referral_code()
            if not AmbassadorProfile.objects.filter(referral_code=code).exists():
                return code
        raise RuntimeError("Could not generate unique referral code after 100 attempts")

    def refresh_cached_stats(self) -> None:
        """Recalculate cached total_referrals and total_earnings from source data."""
        self.total_referrals = self.referrals.count()
        earnings = self.commissions.filter(
            status__in=[AmbassadorCommission.Status.APPROVED, AmbassadorCommission.Status.PAID],
        ).aggregate(total=models.Sum('commission_amount'))
        self.total_earnings = earnings['total'] or Decimal('0.00')
        self.save(update_fields=['total_referrals', 'total_earnings'])


class AmbassadorReferral(models.Model):
    """
    Tracks each trainer referred by an ambassador.
    Created when a trainer registers with a valid referral code.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        ACTIVE = 'ACTIVE', 'Active'
        CHURNED = 'CHURNED', 'Churned'

    ambassador = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='ambassador_referrals',
        limit_choices_to={'role': 'AMBASSADOR'},
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='referred_by',
        limit_choices_to={'role': 'TRAINER'},
    )
    ambassador_profile = models.ForeignKey(
        AmbassadorProfile,
        on_delete=models.CASCADE,
        related_name='referrals',
    )
    referral_code_used = models.CharField(
        max_length=20,
        help_text="The referral code that was used at registration time",
    )
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
    )
    referred_at = models.DateTimeField(auto_now_add=True)
    activated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Set when trainer's first subscription payment clears",
    )
    churned_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Set when trainer cancels subscription",
    )

    class Meta:
        db_table = 'ambassador_referrals'
        constraints = [
            models.UniqueConstraint(
                fields=['ambassador', 'trainer'],
                name='unique_ambassador_trainer_referral',
            ),
        ]
        indexes = [
            models.Index(fields=['ambassador', 'status']),
            models.Index(fields=['trainer']),
            models.Index(fields=['referral_code_used']),
            models.Index(fields=['referred_at']),
        ]
        ordering = ['-referred_at']

    def __str__(self) -> str:
        return f"{self.ambassador.email} → {self.trainer.email} ({self.status})"

    def activate(self) -> None:
        """Mark referral as active when trainer's first payment clears."""
        self.status = self.Status.ACTIVE
        self.activated_at = timezone.now()
        self.save(update_fields=['status', 'activated_at'])

    def mark_churned(self) -> None:
        """Mark referral as churned when trainer cancels."""
        self.status = self.Status.CHURNED
        self.churned_at = timezone.now()
        self.save(update_fields=['status', 'churned_at'])

    def reactivate(self) -> None:
        """Reactivate a churned referral when trainer resubscribes."""
        self.status = self.Status.ACTIVE
        self.churned_at = None
        self.save(update_fields=['status', 'churned_at'])


class AmbassadorCommission(models.Model):
    """
    Monthly commission record for an ambassador from a referred trainer's subscription.
    Rate is snapshot at creation time so admin rate changes don't affect history.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        PAID = 'PAID', 'Paid'

    ambassador = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='ambassador_commissions',
        limit_choices_to={'role': 'AMBASSADOR'},
    )
    referral = models.ForeignKey(
        AmbassadorReferral,
        on_delete=models.CASCADE,
        related_name='commissions',
    )
    ambassador_profile = models.ForeignKey(
        AmbassadorProfile,
        on_delete=models.CASCADE,
        related_name='commissions',
    )
    commission_rate = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        help_text="Snapshot of commission rate at time of charge",
    )
    base_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Trainer's subscription payment amount",
    )
    commission_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Calculated commission: base_amount * commission_rate",
    )
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
    )
    period_start = models.DateField(
        help_text="Start of the billing period this commission covers",
    )
    period_end = models.DateField(
        help_text="End of the billing period this commission covers",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ambassador_commissions'
        constraints = [
            models.UniqueConstraint(
                fields=['referral', 'period_start', 'period_end'],
                name='unique_commission_per_referral_period',
            ),
        ]
        indexes = [
            models.Index(fields=['ambassador', 'status']),
            models.Index(fields=['referral']),
            models.Index(fields=['period_start', 'period_end']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"${self.commission_amount} for {self.ambassador.email} ({self.status})"

    def approve(self) -> None:
        """Mark commission as approved.

        Raises:
            ValueError: If current status is not PENDING.
        """
        if self.status != self.Status.PENDING:
            raise ValueError(
                f"Cannot approve commission in '{self.status}' state; must be PENDING."
            )
        self.status = self.Status.APPROVED
        self.save(update_fields=['status'])

    def mark_paid(self) -> None:
        """Mark commission as paid.

        Raises:
            ValueError: If current status is not APPROVED.
        """
        if self.status != self.Status.APPROVED:
            raise ValueError(
                f"Cannot mark commission as paid in '{self.status}' state; must be APPROVED."
            )
        self.status = self.Status.PAID
        self.save(update_fields=['status'])

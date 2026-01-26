"""
Subscription models for Trainer billing tiers.
"""
from django.db import models
from django.core.validators import MinValueValidator
from django.utils import timezone
from decimal import Decimal
from typing import Optional


class Subscription(models.Model):
    """
    Subscription model for Trainers.

    Tiers:
    - FREE: $0/mo, up to 3 active trainees, 14-day trial
    - STARTER: $29/mo, up to 10 active trainees, Basic features
    - PRO: $79/mo, up to 50 active trainees, Advanced AI features
    - ENTERPRISE: $199/mo, Unlimited trainees, White-label options
    """
    class Tier(models.TextChoices):
        FREE = 'FREE', 'Free'
        STARTER = 'STARTER', 'Starter ($29/mo)'
        PRO = 'PRO', 'Pro ($79/mo)'
        ENTERPRISE = 'ENTERPRISE', 'Enterprise ($199/mo)'

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        PAST_DUE = 'past_due', 'Past Due'
        CANCELED = 'canceled', 'Canceled'
        TRIALING = 'trialing', 'Trialing'
        SUSPENDED = 'suspended', 'Suspended'

    # Tier pricing (in dollars)
    TIER_PRICING = {
        'FREE': Decimal('0.00'),
        'STARTER': Decimal('29.00'),
        'PRO': Decimal('79.00'),
        'ENTERPRISE': Decimal('199.00'),
    }

    # Tier trainee limits
    TIER_LIMITS = {
        'FREE': 3,
        'STARTER': 10,
        'PRO': 50,
        'ENTERPRISE': float('inf'),  # Unlimited
    }

    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='subscription',
        limit_choices_to={'role': 'TRAINER'}
    )

    tier = models.CharField(
        max_length=20,
        choices=Tier.choices,
        default=Tier.FREE
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.TRIALING
    )

    # Stripe integration
    stripe_subscription_id = models.CharField(
        max_length=255,
        unique=True,
        blank=True,
        null=True,
        help_text="Stripe subscription ID"
    )

    stripe_customer_id = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Stripe customer ID"
    )

    # Billing period
    current_period_start = models.DateTimeField(blank=True, null=True)
    current_period_end = models.DateTimeField(blank=True, null=True)

    # Payment tracking
    next_payment_date = models.DateField(blank=True, null=True)
    last_payment_date = models.DateField(blank=True, null=True)
    last_payment_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True
    )

    # Past due tracking
    past_due_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    past_due_since = models.DateField(blank=True, null=True)
    failed_payment_count = models.PositiveIntegerField(default=0)

    # Trial tracking
    trial_start = models.DateTimeField(blank=True, null=True)
    trial_end = models.DateTimeField(blank=True, null=True)
    trial_used = models.BooleanField(default=False)

    # Admin notes
    admin_notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'subscriptions'
        indexes = [
            models.Index(fields=['trainer']),
            models.Index(fields=['status']),
            models.Index(fields=['tier']),
            models.Index(fields=['next_payment_date']),
            models.Index(fields=['past_due_since']),
        ]

    def __str__(self) -> str:
        return f"{self.trainer.email} - {self.get_tier_display()} ({self.status})"

    def get_max_trainees(self) -> int:
        """Get maximum number of trainees allowed for this tier."""
        return self.TIER_LIMITS.get(self.tier, 0)

    def get_monthly_price(self) -> Decimal:
        """Get the monthly price for this tier."""
        return self.TIER_PRICING.get(self.tier, Decimal('0.00'))

    def can_add_trainee(self) -> bool:
        """Check if trainer can add another trainee based on tier limits."""
        if self.tier == self.Tier.ENTERPRISE:
            return True  # Unlimited

        max_trainees = self.get_max_trainees()
        current_count = self.trainer.get_active_trainees_count()
        return current_count < max_trainees

    def is_past_due(self) -> bool:
        """Check if subscription is past due."""
        return self.status == self.Status.PAST_DUE or self.past_due_amount > 0

    def days_until_payment(self) -> Optional[int]:
        """Get days until next payment."""
        if not self.next_payment_date:
            return None
        delta = self.next_payment_date - timezone.now().date()
        return delta.days

    def days_past_due(self) -> Optional[int]:
        """Get days past due if applicable."""
        if not self.past_due_since:
            return None
        delta = timezone.now().date() - self.past_due_since
        return delta.days


class PaymentHistory(models.Model):
    """
    Payment history for subscriptions.
    """
    class Status(models.TextChoices):
        SUCCEEDED = 'succeeded', 'Succeeded'
        FAILED = 'failed', 'Failed'
        PENDING = 'pending', 'Pending'
        REFUNDED = 'refunded', 'Refunded'

    subscription = models.ForeignKey(
        Subscription,
        on_delete=models.CASCADE,
        related_name='payments'
    )

    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices)

    stripe_payment_intent_id = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    description = models.CharField(max_length=255, blank=True)
    failure_reason = models.TextField(blank=True)

    payment_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payment_history'
        ordering = ['-payment_date']

    def __str__(self) -> str:
        return f"{self.subscription.trainer.email} - ${self.amount} ({self.status})"


class SubscriptionChange(models.Model):
    """
    Audit log for subscription changes (tier upgrades/downgrades).
    """
    class ChangeType(models.TextChoices):
        UPGRADE = 'upgrade', 'Upgrade'
        DOWNGRADE = 'downgrade', 'Downgrade'
        CANCEL = 'cancel', 'Cancel'
        REACTIVATE = 'reactivate', 'Reactivate'
        ADMIN_ADJUST = 'admin_adjust', 'Admin Adjustment'

    subscription = models.ForeignKey(
        Subscription,
        on_delete=models.CASCADE,
        related_name='changes'
    )

    change_type = models.CharField(max_length=20, choices=ChangeType.choices)

    from_tier = models.CharField(max_length=20, blank=True)
    to_tier = models.CharField(max_length=20, blank=True)

    from_status = models.CharField(max_length=20, blank=True)
    to_status = models.CharField(max_length=20, blank=True)

    changed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='subscription_changes_made'
    )

    reason = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'subscription_changes'
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.subscription.trainer.email} - {self.change_type} at {self.created_at}"


class StripeAccount(models.Model):
    """Trainer's connected Stripe account for receiving payments from trainees."""

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACTIVE = 'active', 'Active'
        RESTRICTED = 'restricted', 'Restricted'
        DISABLED = 'disabled', 'Disabled'

    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='stripe_account',
        limit_choices_to={'role': 'TRAINER'}
    )
    stripe_account_id = models.CharField(
        max_length=255,
        unique=True,
        blank=True,
        null=True,
        help_text="Stripe Connect account ID (acct_...)"
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    charges_enabled = models.BooleanField(
        default=False,
        help_text="Whether the account can accept charges"
    )
    payouts_enabled = models.BooleanField(
        default=False,
        help_text="Whether the account can receive payouts"
    )
    details_submitted = models.BooleanField(
        default=False,
        help_text="Whether account details have been submitted"
    )
    onboarding_completed = models.BooleanField(
        default=False,
        help_text="Whether the full onboarding flow is complete"
    )
    default_currency = models.CharField(max_length=3, default='usd')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'stripe_accounts'
        indexes = [
            models.Index(fields=['trainer']),
            models.Index(fields=['status']),
        ]

    def __str__(self) -> str:
        return f"{self.trainer.email} - {self.stripe_account_id or 'Not Connected'}"

    def is_ready_for_payments(self) -> bool:
        """Check if account can receive payments."""
        return self.charges_enabled and self.onboarding_completed


class TrainerPricing(models.Model):
    """Trainer's pricing configuration for trainee services."""

    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='pricing',
        limit_choices_to={'role': 'TRAINER'}
    )
    monthly_subscription_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Monthly coaching subscription price in dollars"
    )
    monthly_subscription_enabled = models.BooleanField(
        default=False,
        help_text="Whether monthly subscriptions are available"
    )
    one_time_consultation_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="One-time consultation price in dollars"
    )
    one_time_consultation_enabled = models.BooleanField(
        default=False,
        help_text="Whether one-time consultations are available"
    )
    stripe_monthly_price_id = models.CharField(
        max_length=255,
        blank=True,
        help_text="Stripe Price ID for recurring subscription"
    )
    currency = models.CharField(max_length=3, default='usd')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'trainer_pricing'
        verbose_name_plural = 'Trainer pricing'

    def __str__(self) -> str:
        return f"{self.trainer.email} - ${self.monthly_subscription_price}/mo"


class TraineePayment(models.Model):
    """Payment record from trainee to trainer."""

    class Type(models.TextChoices):
        SUBSCRIPTION = 'subscription', 'Monthly Subscription'
        ONE_TIME = 'one_time', 'One-Time Purchase'

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        SUCCEEDED = 'succeeded', 'Succeeded'
        FAILED = 'failed', 'Failed'
        REFUNDED = 'refunded', 'Refunded'
        CANCELED = 'canceled', 'Canceled'

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='payments_made',
        limit_choices_to={'role': 'TRAINEE'}
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='payments_received',
        limit_choices_to={'role': 'TRAINER'}
    )
    payment_type = models.CharField(max_length=20, choices=Type.choices)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    platform_fee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Platform fee collected on this payment"
    )
    currency = models.CharField(max_length=3, default='usd')
    stripe_payment_intent_id = models.CharField(
        max_length=255,
        blank=True,
        help_text="Stripe PaymentIntent ID"
    )
    stripe_checkout_session_id = models.CharField(
        max_length=255,
        blank=True,
        help_text="Stripe Checkout Session ID"
    )
    description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'trainee_payments'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee']),
            models.Index(fields=['trainer']),
            models.Index(fields=['status']),
            models.Index(fields=['payment_type']),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} → {self.trainer.email}: ${self.amount} ({self.status})"


class TraineeSubscription(models.Model):
    """Active coaching subscription from trainee to trainer."""

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        PAST_DUE = 'past_due', 'Past Due'
        CANCELED = 'canceled', 'Canceled'
        PAUSED = 'paused', 'Paused'

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='coaching_subscriptions',
        limit_choices_to={'role': 'TRAINEE'}
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='trainee_subscriptions',
        limit_choices_to={'role': 'TRAINER'}
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE
    )
    stripe_subscription_id = models.CharField(
        max_length=255,
        unique=True,
        blank=True,
        null=True,
        help_text="Stripe Subscription ID"
    )
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    currency = models.CharField(max_length=3, default='usd')
    current_period_start = models.DateTimeField(null=True, blank=True)
    current_period_end = models.DateTimeField(null=True, blank=True)
    canceled_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'trainee_subscriptions'
        unique_together = [['trainee', 'trainer']]
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee']),
            models.Index(fields=['trainer']),
            models.Index(fields=['status']),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} → {self.trainer.email}: ${self.amount}/mo ({self.status})"

    def is_active(self) -> bool:
        """Check if subscription is currently active."""
        return self.status == self.Status.ACTIVE

    def days_until_renewal(self) -> Optional[int]:
        """Get days until next renewal."""
        if not self.current_period_end:
            return None
        delta = self.current_period_end - timezone.now()
        return max(0, delta.days)

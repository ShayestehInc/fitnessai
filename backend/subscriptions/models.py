"""
Subscription models for Trainer billing tiers.
"""
from django.db import models
from django.core.validators import MinValueValidator
from typing import Optional


class Subscription(models.Model):
    """
    Subscription model for Trainers.
    
    Tiers:
    - TIER_1: $50/mo, up to 10 active trainees, Basic AI
    - TIER_2: $100/mo, up to 50 active trainees, Advanced AI (Video analysis)
    - TIER_3: $200/mo, Unlimited trainees, White-label options
    """
    class Tier(models.TextChoices):
        TIER_1 = 'TIER_1', 'Tier 1 ($50/mo)'
        TIER_2 = 'TIER_2', 'Tier 2 ($100/mo)'
        TIER_3 = 'TIER_3', 'Tier 3 ($200/mo)'
    
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        PAST_DUE = 'past_due', 'Past Due'
        CANCELED = 'canceled', 'Canceled'
        TRIALING = 'trialing', 'Trialing'
    
    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='subscription',
        limit_choices_to={'role': 'TRAINER'}
    )
    
    tier = models.CharField(
        max_length=10,
        choices=Tier.choices,
        default=Tier.TIER_1
    )
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.TRIALING
    )
    
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
    
    current_period_start = models.DateTimeField(blank=True, null=True)
    current_period_end = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'subscriptions'
        indexes = [
            models.Index(fields=['trainer']),
            models.Index(fields=['status']),
            models.Index(fields=['tier']),
        ]
    
    def __str__(self) -> str:
        return f"{self.trainer.email} - {self.get_tier_display()} ({self.status})"
    
    def get_max_trainees(self) -> int:
        """Get maximum number of trainees allowed for this tier."""
        tier_limits = {
            self.Tier.TIER_1: 10,
            self.Tier.TIER_2: 50,
            self.Tier.TIER_3: float('inf'),  # Unlimited
        }
        return tier_limits.get(self.tier, 0)
    
    def can_add_trainee(self) -> bool:
        """Check if trainer can add another trainee based on tier limits."""
        if self.tier == self.Tier.TIER_3:
            return True  # Unlimited
        
        max_trainees = self.get_max_trainees()
        current_count = self.trainer.get_active_trainees_count()
        return current_count < max_trainees

"""
Serializers for ambassador models and dashboard stats.
"""
from __future__ import annotations

import re
from decimal import Decimal
from typing import Any

from django.core.exceptions import ObjectDoesNotExist
from django.db.models import Sum
from rest_framework import serializers

from .models import AmbassadorCommission, AmbassadorProfile, AmbassadorReferral
from users.models import User


class AmbassadorUserSerializer(serializers.ModelSerializer[User]):
    """Minimal user serializer for ambassador-related responses."""

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'is_active', 'created_at']


class AmbassadorProfileSerializer(serializers.ModelSerializer[AmbassadorProfile]):
    """Serializer for AmbassadorProfile model."""

    user = AmbassadorUserSerializer(read_only=True)

    class Meta:
        model = AmbassadorProfile
        fields = [
            'id', 'user', 'referral_code', 'commission_rate', 'is_active',
            'total_referrals', 'total_earnings', 'created_at', 'updated_at',
        ]
        read_only_fields = ['referral_code', 'total_referrals', 'total_earnings', 'created_at', 'updated_at']


class AmbassadorReferralSerializer(serializers.ModelSerializer[AmbassadorReferral]):
    """Serializer for AmbassadorReferral with trainer details."""

    trainer = AmbassadorUserSerializer(read_only=True)
    trainer_subscription_tier = serializers.SerializerMethodField()
    total_commission_earned = serializers.SerializerMethodField()

    class Meta:
        model = AmbassadorReferral
        fields = [
            'id', 'trainer', 'referral_code_used', 'status',
            'referred_at', 'activated_at', 'churned_at',
            'trainer_subscription_tier', 'total_commission_earned',
        ]

    def get_trainer_subscription_tier(self, obj: AmbassadorReferral) -> str:
        """Get the referred trainer's current subscription tier.

        Subscription is a OneToOneField on the trainer user with related_name='subscription'.
        """
        try:
            return str(obj.trainer.subscription.tier)
        except (AttributeError, ObjectDoesNotExist):
            return 'FREE'

    def get_total_commission_earned(self, obj: AmbassadorReferral) -> str:
        """Get total commission earned from this specific referral.

        Uses annotated `_total_commission` if available (set by the view),
        otherwise falls back to a query.
        """
        annotated = getattr(obj, '_total_commission', None)
        if annotated is not None:
            return str(annotated)
        total = obj.commissions.filter(
            status__in=[AmbassadorCommission.Status.APPROVED, AmbassadorCommission.Status.PAID],
        ).aggregate(total=Sum('commission_amount'))
        return str(total['total'] or Decimal('0.00'))


class AmbassadorCommissionSerializer(serializers.ModelSerializer[AmbassadorCommission]):
    """Serializer for AmbassadorCommission model."""

    trainer_email = serializers.CharField(source='referral.trainer.email', read_only=True)

    class Meta:
        model = AmbassadorCommission
        fields = [
            'id', 'trainer_email', 'commission_rate', 'base_amount',
            'commission_amount', 'status', 'period_start', 'period_end', 'created_at',
        ]



class AdminCreateAmbassadorSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin ambassador creation."""

    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    password = serializers.CharField(
        min_length=8,
        max_length=128,
        write_only=True,
        help_text="Temporary password the ambassador will use to log in",
    )
    commission_rate = serializers.DecimalField(
        max_digits=4,
        decimal_places=2,
        default=Decimal('0.20'),
    )

    def validate_email(self, value: str) -> str:
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_commission_rate(self, value: Decimal) -> Decimal:
        if value < Decimal('0.00') or value > Decimal('1.00'):
            raise serializers.ValidationError("Commission rate must be between 0.00 and 1.00.")
        return value


class AdminUpdateAmbassadorSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin ambassador updates."""

    commission_rate = serializers.DecimalField(
        max_digits=4,
        decimal_places=2,
        required=False,
    )
    is_active = serializers.BooleanField(required=False)

    def validate_commission_rate(self, value: Decimal) -> Decimal:
        if value < Decimal('0.00') or value > Decimal('1.00'):
            raise serializers.ValidationError("Commission rate must be between 0.00 and 1.00.")
        return value


class AmbassadorListSerializer(serializers.ModelSerializer[AmbassadorProfile]):
    """Serializer for ambassador list view (admin)."""

    user = AmbassadorUserSerializer(read_only=True)

    class Meta:
        model = AmbassadorProfile
        fields = [
            'id', 'user', 'referral_code', 'commission_rate', 'is_active',
            'total_referrals', 'total_earnings', 'created_at',
        ]


class BulkCommissionActionSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for bulk commission approve/pay actions."""

    commission_ids = serializers.ListField(
        child=serializers.IntegerField(min_value=1),
        min_length=1,
        help_text="List of commission IDs to process",
        error_messages={
            'min_length': 'This field is required and must contain at least one ID.',
            'empty': 'This field is required and must contain at least one ID.',
        },
    )


class CustomReferralCodeSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for updating an ambassador's referral code.

    Uses CharField instead of RegexField so that strip/uppercase
    normalisation can run before the regex validation step.
    """

    referral_code = serializers.CharField(
        min_length=4,
        max_length=20,
        help_text="Custom referral code (4-20 alphanumeric characters, A-Z 0-9)",
    )

    def validate_referral_code(self, value: str) -> str:
        """Strip whitespace, uppercase, validate format and uniqueness."""
        cleaned = value.strip().upper()

        if not re.match(r'^[A-Z0-9]{4,20}$', cleaned):
            raise serializers.ValidationError(
                "Code must be 4-20 alphanumeric characters (A-Z, 0-9)."
            )

        # Check uniqueness excluding the current user's profile
        exclude_profile_id = self.context.get('profile_id')
        existing = AmbassadorProfile.objects.filter(referral_code=cleaned)
        if exclude_profile_id is not None:
            existing = existing.exclude(id=exclude_profile_id)

        if existing.exists():
            raise serializers.ValidationError(
                "This referral code is already in use."
            )

        return cleaned

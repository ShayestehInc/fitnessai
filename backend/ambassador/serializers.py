"""
Serializers for ambassador models and dashboard stats.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Any

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
        """Get the referred trainer's current subscription tier."""
        try:
            return str(obj.trainer.subscription.tier)
        except Exception:
            return 'FREE'

    def get_total_commission_earned(self, obj: AmbassadorReferral) -> str:
        """Get total commission earned from this specific referral."""
        total = obj.commissions.filter(
            status__in=[AmbassadorCommission.Status.APPROVED, AmbassadorCommission.Status.PAID],
        ).aggregate(total=serializers.models.Sum('commission_amount'))
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


@dataclass
class MonthlyEarnings:
    """Monthly earnings data point for dashboard chart."""
    month: str
    earnings: Decimal
    referral_count: int


class DashboardSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for ambassador dashboard response."""

    total_referrals = serializers.IntegerField()
    active_referrals = serializers.IntegerField()
    pending_referrals = serializers.IntegerField()
    churned_referrals = serializers.IntegerField()
    total_earnings = serializers.DecimalField(max_digits=12, decimal_places=2)
    pending_earnings = serializers.DecimalField(max_digits=12, decimal_places=2)
    monthly_earnings = serializers.ListField(child=serializers.DictField())
    recent_referrals = AmbassadorReferralSerializer(many=True)
    referral_code = serializers.CharField()
    commission_rate = serializers.DecimalField(max_digits=4, decimal_places=2)
    is_active = serializers.BooleanField()


class ReferralCodeSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for referral code sharing response."""

    referral_code = serializers.CharField()
    share_message = serializers.CharField()


class AdminCreateAmbassadorSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin ambassador creation."""

    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
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

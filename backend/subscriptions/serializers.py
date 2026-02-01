"""
Serializers for Subscription and Admin management.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any

from rest_framework import serializers

from users.models import User

from .models import (
    Coupon,
    CouponUsage,
    PaymentHistory,
    StripeAccount,
    Subscription,
    SubscriptionChange,
    SubscriptionTier,
    TraineePayment,
    TraineeSubscription,
    TrainerPricing,
)


# ============ Subscription Tier Serializers ============


class SubscriptionTierSerializer(serializers.ModelSerializer[SubscriptionTier]):
    """Full serializer for subscription tiers."""

    trainee_limit_display = serializers.SerializerMethodField()

    class Meta:
        model = SubscriptionTier
        fields = [
            'id', 'name', 'display_name', 'description', 'price',
            'trainee_limit', 'trainee_limit_display', 'features',
            'stripe_price_id', 'is_active', 'sort_order',
            'created_at', 'updated_at'
        ]

    def get_trainee_limit_display(self, obj: SubscriptionTier) -> str:
        return 'Unlimited' if obj.trainee_limit == 0 else str(obj.trainee_limit)


class SubscriptionTierCreateUpdateSerializer(serializers.ModelSerializer[SubscriptionTier]):
    """Serializer for creating/updating subscription tiers."""

    class Meta:
        model = SubscriptionTier
        fields = [
            'name', 'display_name', 'description', 'price',
            'trainee_limit', 'features', 'stripe_price_id',
            'is_active', 'sort_order'
        ]

    def validate_name(self, value: str) -> str:
        # Ensure name is uppercase
        return value.upper()

    def validate_price(self, value: Decimal) -> Decimal:
        if value < 0:
            raise serializers.ValidationError("Price cannot be negative")
        return value

    def validate_trainee_limit(self, value: int) -> int:
        if value < 0:
            raise serializers.ValidationError("Trainee limit cannot be negative")
        return value


class TrainerSummarySerializer(serializers.ModelSerializer[User]):
    """Summary serializer for trainer info."""

    trainee_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'is_active',
                  'created_at', 'trainee_count']

    def get_trainee_count(self, obj: User) -> int:
        return obj.get_active_trainees_count()


class PaymentHistorySerializer(serializers.ModelSerializer[PaymentHistory]):
    """Serializer for payment history."""

    class Meta:
        model = PaymentHistory
        fields = ['id', 'amount', 'status', 'description', 'failure_reason',
                  'payment_date', 'stripe_payment_intent_id']


class SubscriptionChangeSerializer(serializers.ModelSerializer[SubscriptionChange]):
    """Serializer for subscription change audit log."""

    changed_by_email = serializers.CharField(source='changed_by.email', read_only=True)

    class Meta:
        model = SubscriptionChange
        fields = ['id', 'change_type', 'from_tier', 'to_tier', 'from_status',
                  'to_status', 'changed_by_email', 'reason', 'created_at']


class SubscriptionSerializer(serializers.ModelSerializer[Subscription]):
    """Full subscription serializer with trainer details."""

    trainer = TrainerSummarySerializer(read_only=True)
    trainer_id = serializers.IntegerField(write_only=True, required=False)
    trainee_count = serializers.SerializerMethodField()
    max_trainees = serializers.SerializerMethodField()
    monthly_price = serializers.SerializerMethodField()
    days_until_payment = serializers.SerializerMethodField()
    days_past_due = serializers.SerializerMethodField()
    recent_payments = serializers.SerializerMethodField()
    recent_changes = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = [
            'id', 'trainer', 'trainer_id', 'tier', 'status',
            'trainee_count', 'max_trainees', 'monthly_price',
            'stripe_subscription_id', 'stripe_customer_id',
            'current_period_start', 'current_period_end',
            'next_payment_date', 'last_payment_date', 'last_payment_amount',
            'past_due_amount', 'past_due_since', 'failed_payment_count',
            'days_until_payment', 'days_past_due',
            'trial_start', 'trial_end', 'trial_used',
            'admin_notes', 'created_at', 'updated_at',
            'recent_payments', 'recent_changes'
        ]
        read_only_fields = ['trainer', 'created_at', 'updated_at']

    def get_trainee_count(self, obj: Subscription) -> int:
        return obj.trainer.get_active_trainees_count()

    def get_max_trainees(self, obj: Subscription) -> int:
        limit = obj.get_max_trainees()
        return -1 if limit == float('inf') else int(limit)  # -1 means unlimited

    def get_monthly_price(self, obj: Subscription) -> str:
        return str(obj.get_monthly_price())

    def get_days_until_payment(self, obj: Subscription) -> int | None:
        return obj.days_until_payment()

    def get_days_past_due(self, obj: Subscription) -> int | None:
        return obj.days_past_due()

    def get_recent_payments(self, obj: Subscription) -> list[dict[str, Any]]:
        payments = obj.payments.all()[:5]
        return PaymentHistorySerializer(payments, many=True).data  # type: ignore[return-value]

    def get_recent_changes(self, obj: Subscription) -> list[dict[str, Any]]:
        changes = obj.changes.all()[:5]
        return SubscriptionChangeSerializer(changes, many=True).data  # type: ignore[return-value]


class SubscriptionListSerializer(serializers.ModelSerializer[Subscription]):
    """Lightweight serializer for subscription lists."""

    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    trainer_name = serializers.SerializerMethodField()
    trainee_count = serializers.SerializerMethodField()
    max_trainees = serializers.SerializerMethodField()
    monthly_price = serializers.SerializerMethodField()
    days_until_payment = serializers.SerializerMethodField()
    days_past_due = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = [
            'id', 'trainer_email', 'trainer_name', 'tier', 'status',
            'trainee_count', 'max_trainees', 'monthly_price',
            'next_payment_date', 'past_due_amount', 'past_due_since',
            'days_until_payment', 'days_past_due', 'created_at'
        ]

    def get_trainer_name(self, obj: Subscription) -> str:
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_trainee_count(self, obj: Subscription) -> int:
        return obj.trainer.get_active_trainees_count()

    def get_max_trainees(self, obj: Subscription) -> int:
        limit = obj.get_max_trainees()
        return -1 if limit == float('inf') else int(limit)

    def get_monthly_price(self, obj: Subscription) -> str:
        return str(obj.get_monthly_price())

    def get_days_until_payment(self, obj: Subscription) -> int | None:
        return obj.days_until_payment()

    def get_days_past_due(self, obj: Subscription) -> int | None:
        return obj.days_past_due()


class AdminChangeTierSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin tier change request."""

    new_tier = serializers.ChoiceField(choices=Subscription.Tier.choices)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AdminChangeStatusSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin status change request."""

    new_status = serializers.ChoiceField(choices=Subscription.Status.choices)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AdminUpdateNotesSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for updating admin notes."""

    admin_notes = serializers.CharField(max_length=2000, required=False, allow_blank=True)


class AdminDashboardStatsSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for admin dashboard statistics."""

    total_trainers = serializers.IntegerField()
    active_trainers = serializers.IntegerField()
    total_trainees = serializers.IntegerField()

    # Subscription breakdown
    tier_breakdown = serializers.DictField()
    status_breakdown = serializers.DictField()

    # Financial
    monthly_recurring_revenue = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_past_due = serializers.DecimalField(max_digits=10, decimal_places=2)

    # Upcoming payments
    payments_due_today = serializers.IntegerField()
    payments_due_this_week = serializers.IntegerField()
    payments_due_this_month = serializers.IntegerField()

    # Past due
    past_due_count = serializers.IntegerField()


# ============ Payment Serializers (Stripe Connect) ============


class StripeAccountSerializer(serializers.ModelSerializer[StripeAccount]):
    """Serializer for trainer's connected Stripe account."""

    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    is_ready_for_payments = serializers.SerializerMethodField()

    class Meta:
        model = StripeAccount
        fields = [
            'id', 'trainer_email', 'stripe_account_id', 'status',
            'charges_enabled', 'payouts_enabled', 'details_submitted',
            'onboarding_completed', 'default_currency', 'is_ready_for_payments',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['stripe_account_id', 'charges_enabled', 'payouts_enabled',
                           'details_submitted', 'onboarding_completed']

    def get_is_ready_for_payments(self, obj: StripeAccount) -> bool:
        return obj.is_ready_for_payments()


class TrainerPricingSerializer(serializers.ModelSerializer[TrainerPricing]):
    """Serializer for trainer's pricing configuration."""

    trainer_email = serializers.CharField(source='trainer.email', read_only=True)

    class Meta:
        model = TrainerPricing
        fields = [
            'id', 'trainer_email', 'monthly_subscription_price',
            'monthly_subscription_enabled', 'one_time_consultation_price',
            'one_time_consultation_enabled', 'stripe_monthly_price_id',
            'currency', 'created_at', 'updated_at'
        ]
        read_only_fields = ['stripe_monthly_price_id', 'created_at', 'updated_at']


class TrainerPricingUpdateSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for updating trainer pricing."""

    monthly_subscription_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False
    )
    monthly_subscription_enabled = serializers.BooleanField(required=False)
    one_time_consultation_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False
    )
    one_time_consultation_enabled = serializers.BooleanField(required=False)
    currency = serializers.CharField(max_length=3, required=False)


class TraineePaymentSerializer(serializers.ModelSerializer[TraineePayment]):
    """Serializer for trainee payment records."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    trainer_name = serializers.SerializerMethodField()

    class Meta:
        model = TraineePayment
        fields = [
            'id', 'trainee_email', 'trainer_email', 'trainer_name',
            'payment_type', 'status', 'amount', 'platform_fee',
            'currency', 'description', 'created_at', 'paid_at'
        ]

    def get_trainer_name(self, obj: TraineePayment) -> str:
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email


class TraineeSubscriptionSerializer(serializers.ModelSerializer[TraineeSubscription]):
    """Serializer for trainee coaching subscription."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    trainer_name = serializers.SerializerMethodField()
    days_until_renewal = serializers.SerializerMethodField()
    is_active = serializers.SerializerMethodField()

    class Meta:
        model = TraineeSubscription
        fields = [
            'id', 'trainee_email', 'trainer_email', 'trainer_name',
            'status', 'amount', 'currency', 'current_period_start',
            'current_period_end', 'days_until_renewal', 'is_active',
            'canceled_at', 'created_at', 'updated_at'
        ]

    def get_trainer_name(self, obj: TraineeSubscription) -> str:
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_days_until_renewal(self, obj: TraineeSubscription) -> int | None:
        return obj.days_until_renewal()

    def get_is_active(self, obj: TraineeSubscription) -> bool:
        return obj.is_active()


class CreateCheckoutSessionSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for creating a Stripe Checkout session."""

    trainer_id = serializers.IntegerField()
    payment_type = serializers.ChoiceField(choices=['subscription', 'one_time'])
    success_url = serializers.URLField(required=False)
    cancel_url = serializers.URLField(required=False)


class TrainerPublicPricingSerializer(serializers.ModelSerializer[TrainerPricing]):
    """Public pricing info for trainees to view."""

    trainer_id = serializers.IntegerField(source='trainer.id', read_only=True)
    trainer_name = serializers.SerializerMethodField()
    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    has_stripe_account = serializers.SerializerMethodField()

    class Meta:
        model = TrainerPricing
        fields = [
            'trainer_id', 'trainer_name', 'trainer_email',
            'monthly_subscription_price', 'monthly_subscription_enabled',
            'one_time_consultation_price', 'one_time_consultation_enabled',
            'currency', 'has_stripe_account'
        ]

    def get_trainer_name(self, obj: TrainerPricing) -> str:
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_has_stripe_account(self, obj: TrainerPricing) -> bool:
        return hasattr(obj.trainer, 'stripe_account') and obj.trainer.stripe_account.is_ready_for_payments()


# ============ Coupon Serializers ============


class CouponUsageSerializer(serializers.ModelSerializer[CouponUsage]):
    """Serializer for coupon usage records."""

    user_email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = CouponUsage
        fields = ['id', 'user_email', 'discount_amount', 'used_at']


class CouponSerializer(serializers.ModelSerializer[Coupon]):
    """Full serializer for coupons."""

    created_by_trainer_email = serializers.CharField(
        source='created_by_trainer.email', read_only=True
    )
    created_by_admin_email = serializers.CharField(
        source='created_by_admin.email', read_only=True
    )
    is_currently_valid = serializers.SerializerMethodField()
    usage_count = serializers.SerializerMethodField()
    recent_usages = serializers.SerializerMethodField()

    class Meta:
        model = Coupon
        fields = [
            'id', 'code', 'description', 'coupon_type', 'discount_value',
            'applies_to', 'status', 'created_by_trainer', 'created_by_trainer_email',
            'created_by_admin', 'created_by_admin_email', 'applicable_tiers',
            'max_uses', 'max_uses_per_user', 'current_uses', 'usage_count',
            'valid_from', 'valid_until', 'stripe_coupon_id', 'is_currently_valid',
            'recent_usages', 'created_at', 'updated_at'
        ]
        read_only_fields = ['current_uses', 'created_at', 'updated_at']

    def get_is_currently_valid(self, obj: Coupon) -> bool:
        return bool(obj.is_valid())

    def get_usage_count(self, obj: Coupon) -> int:
        return obj.current_uses

    def get_recent_usages(self, obj: Coupon) -> list[dict[str, Any]]:
        usages = obj.usages.all()[:5]
        return CouponUsageSerializer(usages, many=True).data  # type: ignore[return-value]


class CouponListSerializer(serializers.ModelSerializer[Coupon]):
    """Lightweight serializer for coupon lists."""

    is_currently_valid = serializers.SerializerMethodField()
    created_by_name = serializers.SerializerMethodField()

    class Meta:
        model = Coupon
        fields = [
            'id', 'code', 'description', 'coupon_type', 'discount_value',
            'applies_to', 'status', 'max_uses', 'current_uses',
            'valid_from', 'valid_until', 'is_currently_valid', 'created_by_name', 'created_at'
        ]

    def get_is_currently_valid(self, obj: Coupon) -> bool:
        return bool(obj.is_valid())

    def get_created_by_name(self, obj: Coupon) -> str:
        if obj.created_by_trainer:
            return f"{obj.created_by_trainer.first_name} {obj.created_by_trainer.last_name}".strip() or obj.created_by_trainer.email
        if obj.created_by_admin:
            return f"Admin: {obj.created_by_admin.email}"
        return "System"


class CouponCreateSerializer(serializers.ModelSerializer[Coupon]):
    """Serializer for creating coupons."""

    class Meta:
        model = Coupon
        fields = [
            'code', 'description', 'coupon_type', 'discount_value',
            'applies_to', 'applicable_tiers', 'max_uses', 'max_uses_per_user',
            'valid_from', 'valid_until'
        ]

    def validate_code(self, value: str) -> str:
        # Ensure code is uppercase and alphanumeric
        code = value.upper().replace(' ', '')
        if not code.isalnum():
            raise serializers.ValidationError("Code must be alphanumeric")
        return code

    def validate_discount_value(self, value: Decimal) -> Decimal:
        if value <= 0:
            raise serializers.ValidationError("Discount value must be positive")
        return value

    def validate(self, data: dict[str, Any]) -> dict[str, Any]:
        # Validate percent discounts are <= 100
        if data.get('coupon_type') == 'percent' and data.get('discount_value', 0) > 100:
            raise serializers.ValidationError({
                'discount_value': "Percentage discount cannot exceed 100%"
            })
        return data


class CouponUpdateSerializer(serializers.ModelSerializer[Coupon]):
    """Serializer for updating coupons."""

    class Meta:
        model = Coupon
        fields = [
            'description', 'discount_value', 'applicable_tiers',
            'max_uses', 'max_uses_per_user', 'valid_until', 'status'
        ]

    def validate_discount_value(self, value: Decimal) -> Decimal:
        if value <= 0:
            raise serializers.ValidationError("Discount value must be positive")
        return value


class ApplyCouponSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for applying a coupon."""

    code = serializers.CharField(max_length=50)

    def validate_code(self, value: str) -> str:
        return value.upper().replace(' ', '')

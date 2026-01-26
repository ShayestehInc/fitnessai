"""
Serializers for Subscription and Admin management.
"""
from rest_framework import serializers
from .models import (
    Subscription, PaymentHistory, SubscriptionChange,
    StripeAccount, TrainerPricing, TraineePayment, TraineeSubscription
)
from users.models import User


class TrainerSummarySerializer(serializers.ModelSerializer):
    """Summary serializer for trainer info."""
    trainee_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'is_active',
                  'created_at', 'trainee_count']

    def get_trainee_count(self, obj):
        return obj.get_active_trainees_count()


class PaymentHistorySerializer(serializers.ModelSerializer):
    """Serializer for payment history."""
    class Meta:
        model = PaymentHistory
        fields = ['id', 'amount', 'status', 'description', 'failure_reason',
                  'payment_date', 'stripe_payment_intent_id']


class SubscriptionChangeSerializer(serializers.ModelSerializer):
    """Serializer for subscription change audit log."""
    changed_by_email = serializers.CharField(source='changed_by.email', read_only=True)

    class Meta:
        model = SubscriptionChange
        fields = ['id', 'change_type', 'from_tier', 'to_tier', 'from_status',
                  'to_status', 'changed_by_email', 'reason', 'created_at']


class SubscriptionSerializer(serializers.ModelSerializer):
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

    def get_trainee_count(self, obj):
        return obj.trainer.get_active_trainees_count()

    def get_max_trainees(self, obj):
        limit = obj.get_max_trainees()
        return -1 if limit == float('inf') else limit  # -1 means unlimited

    def get_monthly_price(self, obj):
        return str(obj.get_monthly_price())

    def get_days_until_payment(self, obj):
        return obj.days_until_payment()

    def get_days_past_due(self, obj):
        return obj.days_past_due()

    def get_recent_payments(self, obj):
        payments = obj.payments.all()[:5]
        return PaymentHistorySerializer(payments, many=True).data

    def get_recent_changes(self, obj):
        changes = obj.changes.all()[:5]
        return SubscriptionChangeSerializer(changes, many=True).data


class SubscriptionListSerializer(serializers.ModelSerializer):
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

    def get_trainer_name(self, obj):
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_trainee_count(self, obj):
        return obj.trainer.get_active_trainees_count()

    def get_max_trainees(self, obj):
        limit = obj.get_max_trainees()
        return -1 if limit == float('inf') else limit

    def get_monthly_price(self, obj):
        return str(obj.get_monthly_price())

    def get_days_until_payment(self, obj):
        return obj.days_until_payment()

    def get_days_past_due(self, obj):
        return obj.days_past_due()


class AdminChangeTierSerializer(serializers.Serializer):
    """Serializer for admin tier change request."""
    new_tier = serializers.ChoiceField(choices=Subscription.Tier.choices)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AdminChangeStatusSerializer(serializers.Serializer):
    """Serializer for admin status change request."""
    new_status = serializers.ChoiceField(choices=Subscription.Status.choices)
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class AdminUpdateNotesSerializer(serializers.Serializer):
    """Serializer for updating admin notes."""
    admin_notes = serializers.CharField(max_length=2000, required=False, allow_blank=True)


class AdminDashboardStatsSerializer(serializers.Serializer):
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

class StripeAccountSerializer(serializers.ModelSerializer):
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

    def get_is_ready_for_payments(self, obj):
        return obj.is_ready_for_payments()


class TrainerPricingSerializer(serializers.ModelSerializer):
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


class TrainerPricingUpdateSerializer(serializers.Serializer):
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


class TraineePaymentSerializer(serializers.ModelSerializer):
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

    def get_trainer_name(self, obj):
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email


class TraineeSubscriptionSerializer(serializers.ModelSerializer):
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

    def get_trainer_name(self, obj):
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_days_until_renewal(self, obj):
        return obj.days_until_renewal()

    def get_is_active(self, obj):
        return obj.is_active()


class CreateCheckoutSessionSerializer(serializers.Serializer):
    """Serializer for creating a Stripe Checkout session."""
    trainer_id = serializers.IntegerField()
    payment_type = serializers.ChoiceField(choices=['subscription', 'one_time'])
    success_url = serializers.URLField(required=False)
    cancel_url = serializers.URLField(required=False)


class TrainerPublicPricingSerializer(serializers.ModelSerializer):
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

    def get_trainer_name(self, obj):
        return f"{obj.trainer.first_name} {obj.trainer.last_name}".strip() or obj.trainer.email

    def get_has_stripe_account(self, obj):
        return hasattr(obj.trainer, 'stripe_account') and obj.trainer.stripe_account.is_ready_for_payments()

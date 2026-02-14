"""
Tests for ambassador commission webhook logic in StripeWebhookView.

Covers:
- _handle_invoice_paid with platform Subscription (ambassador commission creation)
- _handle_invoice_paid with TraineeSubscription (existing behavior, no commission)
- _handle_subscription_deleted with platform Subscription (trainer churn)
- _handle_checkout_completed for platform subscription
- _create_ambassador_commission with no referral (should not create)
- _create_ambassador_commission with active referral (should create)
- _create_ambassador_commission with inactive ambassador (should not create)
- _create_ambassador_commission with zero amount (should not create)
- _create_ambassador_commission with missing period dates (should not create)
- Duplicate commission prevention
- Edge cases: non-existent subscription, non-existent trainer
"""
from __future__ import annotations

import time
from datetime import timedelta
from decimal import Decimal
from typing import Any
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone

from ambassador.models import AmbassadorCommission, AmbassadorProfile, AmbassadorReferral
from subscriptions.models import Subscription, TraineeSubscription
from subscriptions.views.payment_views import StripeWebhookView
from users.models import User


def _create_ambassador_with_profile(
    email: str = 'ambassador@test.com',
    commission_rate: Decimal = Decimal('0.20'),
    is_active: bool = True,
) -> tuple[User, AmbassadorProfile]:
    """Create an ambassador user with an active profile."""
    ambassador = User.objects.create_user(
        email=email,
        password='testpass123',
        role='AMBASSADOR',
    )
    profile = AmbassadorProfile.objects.create(
        user=ambassador,
        commission_rate=commission_rate,
        is_active=is_active,
    )
    return ambassador, profile


def _create_referral(
    ambassador: User,
    trainer: User,
    profile: AmbassadorProfile,
    referral_status: str = AmbassadorReferral.Status.ACTIVE,
) -> AmbassadorReferral:
    """Create an AmbassadorReferral."""
    referral = AmbassadorReferral.objects.create(
        ambassador=ambassador,
        trainer=trainer,
        ambassador_profile=profile,
        referral_code_used=profile.referral_code,
        status=referral_status,
    )
    if referral_status == AmbassadorReferral.Status.ACTIVE:
        referral.activated_at = timezone.now()
        referral.save(update_fields=['activated_at'])
    return referral


class HandleInvoicePaidPlatformSubscriptionTests(TestCase):
    """Tests for _handle_invoice_paid with platform Subscription (ambassador commissions)."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@invoice.com',
            password='testpass123',
            role='TRAINER',
        )
        self.ambassador, self.profile = _create_ambassador_with_profile()
        self.referral = _create_referral(
            self.ambassador, self.trainer, self.profile,
        )
        self.platform_sub = Subscription.objects.create(
            trainer=self.trainer,
            tier=Subscription.Tier.PRO,
            status=Subscription.Status.ACTIVE,
            stripe_subscription_id='sub_platform_123',
        )
        self.view = StripeWebhookView()

        now = timezone.now()
        self.invoice: dict[str, Any] = {
            'subscription': 'sub_platform_123',
            'period_start': int(now.timestamp()),
            'period_end': int((now + timedelta(days=30)).timestamp()),
            'amount_paid': 7900,  # $79.00 in cents
            'payment_intent': 'pi_test_123',
        }

    def test_invoice_paid_creates_ambassador_commission(self) -> None:
        self.view._handle_invoice_paid(self.invoice)

        commissions = AmbassadorCommission.objects.filter(
            ambassador=self.ambassador,
        )
        self.assertEqual(commissions.count(), 1)

        commission = commissions.first()
        self.assertIsNotNone(commission)
        self.assertEqual(commission.base_amount, Decimal('79.00'))
        self.assertEqual(commission.commission_rate, Decimal('0.20'))
        self.assertEqual(commission.commission_amount, Decimal('15.80'))
        self.assertEqual(commission.status, AmbassadorCommission.Status.PENDING)

    def test_invoice_paid_updates_platform_sub_status(self) -> None:
        self.platform_sub.status = Subscription.Status.PAST_DUE
        self.platform_sub.save()

        self.view._handle_invoice_paid(self.invoice)

        self.platform_sub.refresh_from_db()
        self.assertEqual(self.platform_sub.status, Subscription.Status.ACTIVE)

    def test_invoice_paid_updates_platform_sub_payment_fields(self) -> None:
        self.view._handle_invoice_paid(self.invoice)

        self.platform_sub.refresh_from_db()
        self.assertIsNotNone(self.platform_sub.last_payment_date)
        self.assertEqual(self.platform_sub.last_payment_amount, Decimal('79.00'))

    def test_invoice_paid_updates_period_dates(self) -> None:
        self.view._handle_invoice_paid(self.invoice)

        self.platform_sub.refresh_from_db()
        self.assertIsNotNone(self.platform_sub.current_period_start)
        self.assertIsNotNone(self.platform_sub.current_period_end)

    def test_invoice_paid_no_subscription_id_returns_early(self) -> None:
        invoice_no_sub: dict[str, Any] = {'amount_paid': 7900}
        self.view._handle_invoice_paid(invoice_no_sub)
        # Should not raise, no commission created
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_invoice_paid_unknown_subscription_id_logs_warning(self) -> None:
        invoice: dict[str, Any] = {
            'subscription': 'sub_unknown_999',
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 5000,
        }
        # Should not raise
        self.view._handle_invoice_paid(invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)


class HandleInvoicePaidTraineeSubscriptionTests(TestCase):
    """Tests for _handle_invoice_paid with TraineeSubscription (existing behavior)."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@trainee-invoice.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@trainee-invoice.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.trainee_sub = TraineeSubscription.objects.create(
            trainee=self.trainee,
            trainer=self.trainer,
            status=TraineeSubscription.Status.ACTIVE,
            stripe_subscription_id='sub_trainee_456',
            amount=Decimal('49.99'),
            currency='usd',
        )
        self.view = StripeWebhookView()

    def test_invoice_paid_for_trainee_sub_updates_status(self) -> None:
        invoice: dict[str, Any] = {
            'subscription': 'sub_trainee_456',
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 4999,
            'payment_intent': 'pi_trainee_123',
        }
        self.view._handle_invoice_paid(invoice)

        self.trainee_sub.refresh_from_db()
        self.assertEqual(self.trainee_sub.status, TraineeSubscription.Status.ACTIVE)
        self.assertIsNotNone(self.trainee_sub.current_period_start)
        self.assertIsNotNone(self.trainee_sub.current_period_end)

    def test_invoice_paid_for_trainee_sub_does_not_create_commission(self) -> None:
        """Trainee-to-trainer payments should NOT trigger ambassador commissions."""
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@trainee-invoice.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        invoice: dict[str, Any] = {
            'subscription': 'sub_trainee_456',
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 4999,
        }
        self.view._handle_invoice_paid(invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)


class HandleSubscriptionDeletedTests(TestCase):
    """Tests for _handle_subscription_deleted with platform Subscription (trainer churn)."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@churn.com',
            password='testpass123',
            role='TRAINER',
        )
        self.ambassador, self.profile = _create_ambassador_with_profile(
            email='ambassador@churn.com',
        )
        self.referral = _create_referral(
            self.ambassador, self.trainer, self.profile,
        )
        self.platform_sub = Subscription.objects.create(
            trainer=self.trainer,
            tier=Subscription.Tier.PRO,
            status=Subscription.Status.ACTIVE,
            stripe_subscription_id='sub_delete_123',
        )
        self.view = StripeWebhookView()

    def test_subscription_deleted_marks_platform_sub_canceled(self) -> None:
        data: dict[str, Any] = {'id': 'sub_delete_123'}
        self.view._handle_subscription_deleted(data)

        self.platform_sub.refresh_from_db()
        self.assertEqual(self.platform_sub.status, Subscription.Status.CANCELED)

    def test_subscription_deleted_marks_referral_churned(self) -> None:
        data: dict[str, Any] = {'id': 'sub_delete_123'}
        self.view._handle_subscription_deleted(data)

        self.referral.refresh_from_db()
        self.assertEqual(self.referral.status, AmbassadorReferral.Status.CHURNED)
        self.assertIsNotNone(self.referral.churned_at)

    def test_subscription_deleted_trainee_sub_does_not_churn_referral(self) -> None:
        """Trainee subscription cancellation should NOT churn ambassador referrals."""
        trainee = User.objects.create_user(
            email='trainee@churn.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        trainee_sub = TraineeSubscription.objects.create(
            trainee=trainee,
            trainer=self.trainer,
            status=TraineeSubscription.Status.ACTIVE,
            stripe_subscription_id='sub_trainee_del_123',
            amount=Decimal('49.99'),
        )

        data: dict[str, Any] = {'id': 'sub_trainee_del_123'}
        self.view._handle_subscription_deleted(data)

        trainee_sub.refresh_from_db()
        self.assertEqual(trainee_sub.status, TraineeSubscription.Status.CANCELED)

        # Referral should NOT be churned
        self.referral.refresh_from_db()
        self.assertEqual(self.referral.status, AmbassadorReferral.Status.ACTIVE)

    def test_subscription_deleted_unknown_id_no_error(self) -> None:
        data: dict[str, Any] = {'id': 'sub_unknown_999'}
        # Should not raise
        self.view._handle_subscription_deleted(data)

    def test_subscription_deleted_with_no_active_referral(self) -> None:
        """If referral is already churned or pending, nothing changes."""
        self.referral.status = AmbassadorReferral.Status.CHURNED
        self.referral.save()

        data: dict[str, Any] = {'id': 'sub_delete_123'}
        self.view._handle_subscription_deleted(data)

        self.platform_sub.refresh_from_db()
        self.assertEqual(self.platform_sub.status, Subscription.Status.CANCELED)

        # Referral status should still be churned (handle_trainer_churn only updates ACTIVE)
        self.referral.refresh_from_db()
        self.assertEqual(self.referral.status, AmbassadorReferral.Status.CHURNED)


class HandleCheckoutCompletedPlatformTests(TestCase):
    """Tests for _handle_checkout_completed for platform subscription."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@checkout.com',
            password='testpass123',
            role='TRAINER',
        )
        self.ambassador, self.profile = _create_ambassador_with_profile(
            email='ambassador@checkout.com',
        )
        self.referral = _create_referral(
            self.ambassador, self.trainer, self.profile,
            referral_status=AmbassadorReferral.Status.PENDING,
        )
        self.view = StripeWebhookView()

    def test_checkout_completed_creates_platform_subscription(self) -> None:
        session: dict[str, Any] = {
            'id': 'cs_test_123',
            'metadata': {
                'payment_type': 'platform_subscription',
                'trainer_id': str(self.trainer.id),
            },
            'subscription': 'sub_new_platform_123',
            'amount_total': 7900,
        }
        self.view._handle_checkout_completed(session)

        platform_sub = Subscription.objects.get(trainer=self.trainer)
        self.assertEqual(platform_sub.stripe_subscription_id, 'sub_new_platform_123')
        self.assertEqual(platform_sub.status, Subscription.Status.ACTIVE)

    def test_checkout_completed_creates_ambassador_commission(self) -> None:
        session: dict[str, Any] = {
            'id': 'cs_test_123',
            'metadata': {
                'payment_type': 'platform_subscription',
                'trainer_id': str(self.trainer.id),
            },
            'subscription': 'sub_new_platform_456',
            'amount_total': 7900,
        }
        self.view._handle_checkout_completed(session)

        commissions = AmbassadorCommission.objects.filter(
            ambassador=self.ambassador,
        )
        self.assertEqual(commissions.count(), 1)
        commission = commissions.first()
        self.assertIsNotNone(commission)
        self.assertEqual(commission.base_amount, Decimal('79.00'))

    def test_checkout_completed_non_platform_type_ignored(self) -> None:
        """Regular trainee payment checkout should be handled by TraineePayment path."""
        trainee = User.objects.create_user(
            email='trainee@checkout.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        session: dict[str, Any] = {
            'id': 'cs_trainee_123',
            'metadata': {
                'payment_type': 'subscription',
                'trainee_id': str(trainee.id),
                'trainer_id': str(self.trainer.id),
            },
            'subscription': 'sub_trainee_789',
        }
        # Should not create a platform Subscription since no TraineePayment matches
        self.view._handle_checkout_completed(session)
        self.assertFalse(
            Subscription.objects.filter(trainer=self.trainer).exists()
        )

    def test_checkout_completed_nonexistent_trainer_handled(self) -> None:
        session: dict[str, Any] = {
            'id': 'cs_test_bad_trainer',
            'metadata': {
                'payment_type': 'platform_subscription',
                'trainer_id': '99999',
            },
            'subscription': 'sub_nope_123',
            'amount_total': 7900,
        }
        # Should not raise
        self.view._handle_checkout_completed(session)
        self.assertEqual(Subscription.objects.count(), 0)

    def test_checkout_completed_updates_existing_subscription(self) -> None:
        """If trainer already has a Subscription, update_or_create updates it."""
        Subscription.objects.create(
            trainer=self.trainer,
            tier=Subscription.Tier.STARTER,
            status=Subscription.Status.TRIALING,
            stripe_subscription_id='sub_old_123',
        )
        session: dict[str, Any] = {
            'id': 'cs_test_update',
            'metadata': {
                'payment_type': 'platform_subscription',
                'trainer_id': str(self.trainer.id),
            },
            'subscription': 'sub_upgraded_123',
            'amount_total': 7900,
        }
        self.view._handle_checkout_completed(session)

        subs = Subscription.objects.filter(trainer=self.trainer)
        self.assertEqual(subs.count(), 1)
        sub = subs.first()
        self.assertIsNotNone(sub)
        self.assertEqual(sub.stripe_subscription_id, 'sub_upgraded_123')
        self.assertEqual(sub.status, Subscription.Status.ACTIVE)


class CreateAmbassadorCommissionTests(TestCase):
    """Tests for _create_ambassador_commission helper method."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@commission.com',
            password='testpass123',
            role='TRAINER',
        )
        self.view = StripeWebhookView()
        now = timezone.now()
        self.invoice: dict[str, Any] = {
            'period_start': int(now.timestamp()),
            'period_end': int((now + timedelta(days=30)).timestamp()),
            'amount_paid': 7900,
        }

    def test_no_referral_does_not_create_commission(self) -> None:
        """Trainer without an ambassador referral should not get commission."""
        self.view._create_ambassador_commission(self.trainer, self.invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_active_referral_creates_commission(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-active.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        self.view._create_ambassador_commission(self.trainer, self.invoice)

        commissions = AmbassadorCommission.objects.all()
        self.assertEqual(commissions.count(), 1)
        commission = commissions.first()
        self.assertIsNotNone(commission)
        self.assertEqual(commission.ambassador, ambassador)
        self.assertEqual(commission.base_amount, Decimal('79.00'))
        self.assertEqual(commission.commission_rate, Decimal('0.20'))
        self.assertEqual(commission.commission_amount, Decimal('15.80'))

    def test_pending_referral_creates_commission_and_activates(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-pending.com',
        )
        referral = _create_referral(
            ambassador, self.trainer, profile,
            referral_status=AmbassadorReferral.Status.PENDING,
        )

        self.view._create_ambassador_commission(self.trainer, self.invoice)

        referral.refresh_from_db()
        self.assertEqual(referral.status, AmbassadorReferral.Status.ACTIVE)
        self.assertEqual(AmbassadorCommission.objects.count(), 1)

    def test_inactive_ambassador_does_not_create_commission(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-inactive.com',
            is_active=False,
        )
        _create_referral(ambassador, self.trainer, profile)

        self.view._create_ambassador_commission(self.trainer, self.invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_zero_amount_does_not_create_commission(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-zero.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        invoice_zero: dict[str, Any] = {
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 0,
        }
        self.view._create_ambassador_commission(self.trainer, invoice_zero)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_missing_period_dates_does_not_create_commission(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-noperiod.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        invoice_no_period: dict[str, Any] = {
            'amount_paid': 7900,
        }
        self.view._create_ambassador_commission(self.trainer, invoice_no_period)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_missing_period_end_does_not_create_commission(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-noend.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        invoice_no_end: dict[str, Any] = {
            'period_start': int(timezone.now().timestamp()),
            'amount_paid': 7900,
        }
        self.view._create_ambassador_commission(self.trainer, invoice_no_end)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

    def test_duplicate_commission_for_same_period_prevented(self) -> None:
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-dup.com',
        )
        _create_referral(ambassador, self.trainer, profile)

        self.view._create_ambassador_commission(self.trainer, self.invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 1)

        # Same invoice (same period) should not create a second commission
        self.view._create_ambassador_commission(self.trainer, self.invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 1)

    def test_commission_uses_actual_invoice_amount(self) -> None:
        """Commission should be based on actual paid amount, not subscription tier price."""
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-amount.com',
            commission_rate=Decimal('0.10'),
        )
        _create_referral(ambassador, self.trainer, profile)

        invoice_discount: dict[str, Any] = {
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 5000,  # $50.00 (discounted)
        }
        self.view._create_ambassador_commission(self.trainer, invoice_discount)

        commission = AmbassadorCommission.objects.first()
        self.assertIsNotNone(commission)
        self.assertEqual(commission.base_amount, Decimal('50.00'))
        self.assertEqual(commission.commission_amount, Decimal('5.00'))

    def test_commission_with_different_rates(self) -> None:
        """Different commission rates should calculate correctly."""
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-rate.com',
            commission_rate=Decimal('0.30'),
        )
        _create_referral(ambassador, self.trainer, profile)

        self.view._create_ambassador_commission(self.trainer, self.invoice)

        commission = AmbassadorCommission.objects.first()
        self.assertIsNotNone(commission)
        self.assertEqual(commission.commission_rate, Decimal('0.30'))
        # $79.00 * 0.30 = $23.70
        self.assertEqual(commission.commission_amount, Decimal('23.70'))

    def test_churned_referral_does_not_create_commission(self) -> None:
        """Churned referrals should not be found by the lookup
        (only PENDING and ACTIVE are searched)."""
        ambassador, profile = _create_ambassador_with_profile(
            email='ambassador@commission-churned.com',
        )
        referral = AmbassadorReferral.objects.create(
            ambassador=ambassador,
            trainer=self.trainer,
            ambassador_profile=profile,
            referral_code_used=profile.referral_code,
            status=AmbassadorReferral.Status.CHURNED,
        )

        self.view._create_ambassador_commission(self.trainer, self.invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)


class FullWebhookFlowTests(TestCase):
    """End-to-end flow tests combining checkout, invoice, and cancellation."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@fullflow.com',
            password='testpass123',
            role='TRAINER',
        )
        self.ambassador, self.profile = _create_ambassador_with_profile(
            email='ambassador@fullflow.com',
        )
        self.referral = _create_referral(
            self.ambassador, self.trainer, self.profile,
            referral_status=AmbassadorReferral.Status.PENDING,
        )
        self.view = StripeWebhookView()

    def test_full_lifecycle_checkout_invoice_cancel(self) -> None:
        """Test complete lifecycle: checkout -> invoice paid -> cancel."""
        # Step 1: Checkout completed (creates subscription)
        checkout_session: dict[str, Any] = {
            'id': 'cs_lifecycle_123',
            'metadata': {
                'payment_type': 'platform_subscription',
                'trainer_id': str(self.trainer.id),
            },
            'subscription': 'sub_lifecycle_123',
            'amount_total': 7900,
        }
        self.view._handle_checkout_completed(checkout_session)

        # Subscription created
        platform_sub = Subscription.objects.get(trainer=self.trainer)
        self.assertEqual(platform_sub.status, Subscription.Status.ACTIVE)

        # Commission created for first payment
        self.assertEqual(AmbassadorCommission.objects.count(), 1)

        # Referral should be activated
        self.referral.refresh_from_db()
        self.assertEqual(self.referral.status, AmbassadorReferral.Status.ACTIVE)

        # Step 2: Recurring invoice paid (next month)
        now = timezone.now()
        next_month_start = now + timedelta(days=30)
        next_month_end = now + timedelta(days=60)
        invoice: dict[str, Any] = {
            'subscription': 'sub_lifecycle_123',
            'period_start': int(next_month_start.timestamp()),
            'period_end': int(next_month_end.timestamp()),
            'amount_paid': 7900,
            'payment_intent': 'pi_lifecycle_123',
        }
        self.view._handle_invoice_paid(invoice)

        # Second commission created
        self.assertEqual(AmbassadorCommission.objects.count(), 2)

        # Step 3: Subscription canceled
        cancel_data: dict[str, Any] = {'id': 'sub_lifecycle_123'}
        self.view._handle_subscription_deleted(cancel_data)

        platform_sub.refresh_from_db()
        self.assertEqual(platform_sub.status, Subscription.Status.CANCELED)

        self.referral.refresh_from_db()
        self.assertEqual(self.referral.status, AmbassadorReferral.Status.CHURNED)

    def test_invoice_paid_fallback_trainee_first_then_platform(self) -> None:
        """When invoice comes in, system tries TraineeSubscription first, then Subscription."""
        # Create both a trainee sub and a platform sub with different stripe IDs
        trainee = User.objects.create_user(
            email='trainee@fallback.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        TraineeSubscription.objects.create(
            trainee=trainee,
            trainer=self.trainer,
            status=TraineeSubscription.Status.ACTIVE,
            stripe_subscription_id='sub_trainee_fallback',
            amount=Decimal('49.99'),
        )
        Subscription.objects.create(
            trainer=self.trainer,
            tier=Subscription.Tier.PRO,
            status=Subscription.Status.ACTIVE,
            stripe_subscription_id='sub_platform_fallback',
        )

        # Invoice for trainee sub should NOT create commission
        trainee_invoice: dict[str, Any] = {
            'subscription': 'sub_trainee_fallback',
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 4999,
        }
        self.view._handle_invoice_paid(trainee_invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 0)

        # Invoice for platform sub SHOULD create commission
        platform_invoice: dict[str, Any] = {
            'subscription': 'sub_platform_fallback',
            'period_start': int(timezone.now().timestamp()),
            'period_end': int((timezone.now() + timedelta(days=30)).timestamp()),
            'amount_paid': 7900,
        }
        self.view._handle_invoice_paid(platform_invoice)
        self.assertEqual(AmbassadorCommission.objects.count(), 1)

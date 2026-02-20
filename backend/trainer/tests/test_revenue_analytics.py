"""
Tests for Trainer Revenue Analytics (Pipeline 28).

Covers:
- RevenueAnalyticsView: response shape, aggregation, period filtering, permissions
- Service layer: MRR calculation, monthly breakdown, subscriber list, recent payments
"""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal
from typing import cast

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from subscriptions.models import TraineePayment, TraineeSubscription
from users.models import User


def _create_trainer(email: str = 'trainer@test.com') -> User:
    return User.objects.create_user(
        email=email,
        password='testpass123',
        role=User.Role.TRAINER,
        first_name='Test',
        last_name='Trainer',
    )


def _create_trainee(trainer: User, email: str = 'trainee@test.com') -> User:
    return User.objects.create_user(
        email=email,
        password='testpass123',
        role=User.Role.TRAINEE,
        parent_trainer=trainer,
        first_name='Test',
        last_name='Trainee',
    )


def _auth_client(user: User) -> APIClient:
    client = APIClient()
    token = cast(str, str(RefreshToken.for_user(user).access_token))
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    return client


def _create_subscription(
    trainee: User,
    trainer: User,
    amount: Decimal = Decimal('49.99'),
    sub_status: str = TraineeSubscription.Status.ACTIVE,
) -> TraineeSubscription:
    return TraineeSubscription.objects.create(
        trainee=trainee,
        trainer=trainer,
        amount=amount,
        currency='usd',
        status=sub_status,
    )


def _create_payment(
    trainee: User,
    trainer: User,
    amount: Decimal = Decimal('49.99'),
    pay_status: str = TraineePayment.Status.SUCCEEDED,
    payment_type: str = TraineePayment.Type.SUBSCRIPTION,
    paid_at: timezone.datetime | None = None,
) -> TraineePayment:
    payment = TraineePayment.objects.create(
        trainee=trainee,
        trainer=trainer,
        amount=amount,
        currency='usd',
        status=pay_status,
        payment_type=payment_type,
        description=f'{payment_type} payment',
    )
    if paid_at is not None:
        TraineePayment.objects.filter(pk=payment.pk).update(paid_at=paid_at)
        payment.refresh_from_db()
    elif pay_status == TraineePayment.Status.SUCCEEDED:
        TraineePayment.objects.filter(pk=payment.pk).update(paid_at=timezone.now())
        payment.refresh_from_db()
    return payment


class RevenueAnalyticsViewTests(TestCase):
    """Tests for GET /api/trainer/analytics/revenue/."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.client = _auth_client(self.trainer)
        self.url = '/api/trainer/analytics/revenue/'

    # ── Authentication & Authorization ──

    def test_requires_authentication(self) -> None:
        """Unauthenticated requests are rejected."""
        client = APIClient()
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_requires_trainer_role(self) -> None:
        """Non-trainer users are rejected."""
        trainee_client = _auth_client(self.trainee)
        resp = trainee_client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_returns_200_for_trainer(self) -> None:
        """Authenticated trainer gets 200."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    # ── Response Shape ──

    def test_response_has_all_fields(self) -> None:
        """Response contains all expected top-level fields."""
        resp = self.client.get(self.url)
        expected_fields = [
            'period_days', 'mrr', 'total_revenue', 'active_subscribers',
            'avg_revenue_per_subscriber', 'monthly_revenue', 'subscribers',
            'recent_payments',
        ]
        for field in expected_fields:
            self.assertIn(field, resp.data, f"Missing field: {field}")

    def test_monthly_revenue_is_list(self) -> None:
        """monthly_revenue is a list."""
        resp = self.client.get(self.url)
        self.assertIsInstance(resp.data['monthly_revenue'], list)

    def test_subscribers_is_list(self) -> None:
        """subscribers is a list."""
        resp = self.client.get(self.url)
        self.assertIsInstance(resp.data['subscribers'], list)

    def test_recent_payments_is_list(self) -> None:
        """recent_payments is a list."""
        resp = self.client.get(self.url)
        self.assertIsInstance(resp.data['recent_payments'], list)

    # ── Days Parameter ──

    def test_days_defaults_to_30(self) -> None:
        """Days parameter defaults to 30."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['period_days'], 30)

    def test_days_param_accepted(self) -> None:
        """Custom days parameter is accepted."""
        resp = self.client.get(self.url, {'days': 90})
        self.assertEqual(resp.data['period_days'], 90)

    def test_days_clamped_min(self) -> None:
        """Days below 1 are clamped to 1."""
        resp = self.client.get(self.url, {'days': -5})
        self.assertEqual(resp.data['period_days'], 1)

    def test_days_clamped_max(self) -> None:
        """Days above 365 are clamped to 365."""
        resp = self.client.get(self.url, {'days': 9999})
        self.assertEqual(resp.data['period_days'], 365)

    def test_days_invalid_string_defaults_to_30(self) -> None:
        """Invalid days string falls back to 30."""
        resp = self.client.get(self.url, {'days': 'abc'})
        self.assertEqual(resp.data['period_days'], 30)

    # ── MRR Calculation ──

    def test_mrr_with_no_subscribers(self) -> None:
        """MRR is 0.00 when no active subscriptions."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], '0.00')

    def test_mrr_with_active_subscribers(self) -> None:
        """MRR sums active subscription amounts."""
        trainee2 = _create_trainee(self.trainer, email='t2@test.com')
        _create_subscription(self.trainee, self.trainer, Decimal('49.99'))
        _create_subscription(trainee2, self.trainer, Decimal('29.99'))
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], '79.98')

    def test_mrr_excludes_canceled_subs(self) -> None:
        """MRR does not include canceled subscriptions."""
        _create_subscription(self.trainee, self.trainer, Decimal('49.99'),
                             sub_status=TraineeSubscription.Status.CANCELED)
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], '0.00')

    def test_mrr_excludes_paused_subs(self) -> None:
        """MRR does not include paused subscriptions."""
        _create_subscription(self.trainee, self.trainer, Decimal('49.99'),
                             sub_status=TraineeSubscription.Status.PAUSED)
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], '0.00')

    # ── Active Subscribers Count ──

    def test_active_subscribers_count(self) -> None:
        """active_subscribers counts only active subscriptions."""
        trainee2 = _create_trainee(self.trainer, email='t2@test.com')
        _create_subscription(self.trainee, self.trainer)
        _create_subscription(trainee2, self.trainer)
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['active_subscribers'], 2)

    def test_active_subscribers_zero_when_none(self) -> None:
        """active_subscribers is 0 when no subscriptions."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['active_subscribers'], 0)

    # ── Average Revenue Per Subscriber ──

    def test_avg_revenue_per_subscriber(self) -> None:
        """avg_revenue_per_subscriber is MRR / active count."""
        trainee2 = _create_trainee(self.trainer, email='t2@test.com')
        _create_subscription(self.trainee, self.trainer, Decimal('60.00'))
        _create_subscription(trainee2, self.trainer, Decimal('40.00'))
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['avg_revenue_per_subscriber'], '50.00')

    def test_avg_zero_when_no_subscribers(self) -> None:
        """avg_revenue_per_subscriber is 0.00 when no subscribers."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['avg_revenue_per_subscriber'], '0.00')

    # ── Total Revenue (Period-Filtered) ──

    def test_total_revenue_in_period(self) -> None:
        """total_revenue sums succeeded payments within the period."""
        now = timezone.now()
        _create_payment(self.trainee, self.trainer, Decimal('49.99'),
                        paid_at=now - timedelta(days=5))
        _create_payment(self.trainee, self.trainer, Decimal('49.99'),
                        paid_at=now - timedelta(days=15))
        resp = self.client.get(self.url, {'days': 30})
        self.assertEqual(resp.data['total_revenue'], '99.98')

    def test_total_revenue_excludes_outside_period(self) -> None:
        """Payments outside the period are excluded."""
        now = timezone.now()
        _create_payment(self.trainee, self.trainer, Decimal('49.99'),
                        paid_at=now - timedelta(days=5))
        _create_payment(self.trainee, self.trainer, Decimal('100.00'),
                        paid_at=now - timedelta(days=60))
        resp = self.client.get(self.url, {'days': 30})
        self.assertEqual(resp.data['total_revenue'], '49.99')

    def test_total_revenue_excludes_failed_payments(self) -> None:
        """Failed payments are not counted."""
        _create_payment(self.trainee, self.trainer, Decimal('49.99'),
                        pay_status=TraineePayment.Status.FAILED)
        resp = self.client.get(self.url, {'days': 30})
        self.assertEqual(resp.data['total_revenue'], '0.00')

    def test_total_revenue_excludes_refunded_payments(self) -> None:
        """Refunded payments are not counted."""
        _create_payment(self.trainee, self.trainer, Decimal('49.99'),
                        pay_status=TraineePayment.Status.REFUNDED)
        resp = self.client.get(self.url, {'days': 30})
        self.assertEqual(resp.data['total_revenue'], '0.00')

    # ── Monthly Revenue Breakdown ──

    def test_monthly_revenue_has_12_months(self) -> None:
        """monthly_revenue contains 12+ months (zero-filled)."""
        resp = self.client.get(self.url)
        self.assertGreaterEqual(len(resp.data['monthly_revenue']), 12)

    def test_monthly_revenue_point_shape(self) -> None:
        """Each monthly revenue point has month and amount."""
        resp = self.client.get(self.url)
        for point in resp.data['monthly_revenue']:
            self.assertIn('month', point)
            self.assertIn('amount', point)

    def test_monthly_revenue_aggregation(self) -> None:
        """Payments are correctly grouped by month."""
        now = timezone.now()
        _create_payment(self.trainee, self.trainer, Decimal('50.00'), paid_at=now)
        _create_payment(self.trainee, self.trainer, Decimal('30.00'), paid_at=now)
        resp = self.client.get(self.url)
        current_month = now.strftime('%Y-%m')
        current_point = next(
            (p for p in resp.data['monthly_revenue'] if p['month'] == current_month),
            None,
        )
        self.assertIsNotNone(current_point)
        self.assertEqual(current_point['amount'], '80.00')

    # ── Subscribers List ──

    def test_subscriber_fields(self) -> None:
        """Subscriber entries have all expected fields."""
        _create_subscription(self.trainee, self.trainer)
        resp = self.client.get(self.url)
        self.assertEqual(len(resp.data['subscribers']), 1)
        sub = resp.data['subscribers'][0]
        expected_fields = [
            'trainee_id', 'trainee_email', 'trainee_name', 'amount',
            'currency', 'current_period_end', 'days_until_renewal',
            'subscribed_since',
        ]
        for field in expected_fields:
            self.assertIn(field, sub, f"Missing subscriber field: {field}")

    def test_subscriber_trainee_name(self) -> None:
        """Subscriber trainee_name is the full name."""
        _create_subscription(self.trainee, self.trainer)
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['subscribers'][0]['trainee_name'], 'Test Trainee')

    # ── Recent Payments ──

    def test_recent_payments_max_10(self) -> None:
        """Only the 10 most recent payments are returned."""
        for i in range(15):
            _create_payment(self.trainee, self.trainer, Decimal('10.00'))
        resp = self.client.get(self.url)
        self.assertEqual(len(resp.data['recent_payments']), 10)

    def test_recent_payments_includes_all_statuses(self) -> None:
        """Recent payments include all statuses (not just succeeded)."""
        _create_payment(self.trainee, self.trainer, pay_status=TraineePayment.Status.SUCCEEDED)
        _create_payment(self.trainee, self.trainer, pay_status=TraineePayment.Status.FAILED)
        _create_payment(self.trainee, self.trainer, pay_status=TraineePayment.Status.PENDING)
        resp = self.client.get(self.url)
        self.assertEqual(len(resp.data['recent_payments']), 3)
        statuses = {p['status'] for p in resp.data['recent_payments']}
        self.assertIn('succeeded', statuses)
        self.assertIn('failed', statuses)
        self.assertIn('pending', statuses)

    def test_recent_payment_fields(self) -> None:
        """Payment entries have all expected fields."""
        _create_payment(self.trainee, self.trainer)
        resp = self.client.get(self.url)
        self.assertEqual(len(resp.data['recent_payments']), 1)
        pay = resp.data['recent_payments'][0]
        expected_fields = [
            'id', 'trainee_email', 'trainee_name', 'payment_type', 'status',
            'amount', 'currency', 'description', 'paid_at', 'created_at',
        ]
        for field in expected_fields:
            self.assertIn(field, pay, f"Missing payment field: {field}")

    # ── Row-Level Security ──

    def test_trainer_isolation_subscriptions(self) -> None:
        """Trainer only sees their own trainees' subscriptions."""
        other_trainer = _create_trainer(email='other@test.com')
        other_trainee = _create_trainee(other_trainer, email='other-trainee@test.com')
        _create_subscription(other_trainee, other_trainer)

        resp = self.client.get(self.url)
        self.assertEqual(resp.data['active_subscribers'], 0)
        self.assertEqual(len(resp.data['subscribers']), 0)

    def test_trainer_isolation_payments(self) -> None:
        """Trainer only sees their own payments."""
        other_trainer = _create_trainer(email='other@test.com')
        other_trainee = _create_trainee(other_trainer, email='other-trainee@test.com')
        _create_payment(other_trainee, other_trainer)

        resp = self.client.get(self.url)
        self.assertEqual(resp.data['total_revenue'], '0.00')
        self.assertEqual(len(resp.data['recent_payments']), 0)

    # ── Edge Cases ──

    def test_no_data_returns_zeros(self) -> None:
        """Empty state returns all zero values."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], '0.00')
        self.assertEqual(resp.data['total_revenue'], '0.00')
        self.assertEqual(resp.data['active_subscribers'], 0)
        self.assertEqual(resp.data['avg_revenue_per_subscriber'], '0.00')
        self.assertEqual(len(resp.data['subscribers']), 0)
        self.assertEqual(len(resp.data['recent_payments']), 0)

    def test_one_subscriber(self) -> None:
        """With one subscriber, avg equals MRR."""
        _create_subscription(self.trainee, self.trainer, Decimal('99.99'))
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['mrr'], resp.data['avg_revenue_per_subscriber'])

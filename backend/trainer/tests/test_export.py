"""
Tests for CSV Data Export endpoints (Pipeline 29).

Covers:
- PaymentExportView: auth, content type, headers, CSV content, period filtering
- SubscriberExportView: auth, content type, headers, CSV content, all statuses
- TraineeExportView: auth, content type, headers, CSV content, profile/program data
- Row-level security: trainer isolation across all three endpoints
- Edge cases: empty data, special characters, null fields
"""
from __future__ import annotations

import csv
import io
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


def _create_trainer(email: str = "trainer@test.com") -> User:
    return User.objects.create_user(
        email=email,
        password="testpass123",
        role=User.Role.TRAINER,
        first_name="Test",
        last_name="Trainer",
    )


def _create_trainee(
    trainer: User,
    email: str = "trainee@test.com",
    first_name: str = "Test",
    last_name: str = "Trainee",
) -> User:
    return User.objects.create_user(
        email=email,
        password="testpass123",
        role=User.Role.TRAINEE,
        parent_trainer=trainer,
        first_name=first_name,
        last_name=last_name,
    )


def _auth_client(user: User) -> APIClient:
    client = APIClient()
    token = cast(str, str(RefreshToken.for_user(user).access_token))
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _create_payment(
    trainee: User,
    trainer: User,
    amount: Decimal = Decimal("49.99"),
    pay_status: str = TraineePayment.Status.SUCCEEDED,
    payment_type: str = TraineePayment.Type.SUBSCRIPTION,
    paid_at: timezone.datetime | None = None,
    description: str = "",
) -> TraineePayment:
    payment = TraineePayment.objects.create(
        trainee=trainee,
        trainer=trainer,
        amount=amount,
        currency="usd",
        status=pay_status,
        payment_type=payment_type,
        description=description or f"{payment_type} payment",
    )
    if paid_at is not None:
        TraineePayment.objects.filter(pk=payment.pk).update(paid_at=paid_at)
        payment.refresh_from_db()
    elif pay_status == TraineePayment.Status.SUCCEEDED:
        TraineePayment.objects.filter(pk=payment.pk).update(paid_at=timezone.now())
        payment.refresh_from_db()
    return payment


def _create_subscription(
    trainee: User,
    trainer: User,
    amount: Decimal = Decimal("49.99"),
    sub_status: str = TraineeSubscription.Status.ACTIVE,
) -> TraineeSubscription:
    return TraineeSubscription.objects.create(
        trainee=trainee,
        trainer=trainer,
        amount=amount,
        currency="usd",
        status=sub_status,
    )


def _parse_csv(content: bytes) -> list[list[str]]:
    """Parse CSV content from response bytes into a list of rows."""
    text = content.decode("utf-8")
    reader = csv.reader(io.StringIO(text))
    return list(reader)


# ─────────────────────────────────────────────
# Payment Export Tests
# ─────────────────────────────────────────────


class PaymentExportAuthTests(TestCase):
    """Auth tests for GET /api/trainer/export/payments/."""

    url = "/api/trainer/export/payments/"

    def test_unauthenticated_returns_401(self) -> None:
        client = APIClient()
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_non_trainer_returns_403(self) -> None:
        trainer = _create_trainer()
        trainee = _create_trainee(trainer)
        client = _auth_client(trainee)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_returns_200(self) -> None:
        trainer = _create_trainer()
        client = _auth_client(trainer)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)


class PaymentExportResponseTests(TestCase):
    """Response format tests for payment export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/payments/"

    def test_content_type_is_csv(self) -> None:
        resp = self.client.get(self.url)
        self.assertEqual(resp["Content-Type"], "text/csv")

    def test_content_disposition_has_filename(self) -> None:
        resp = self.client.get(self.url)
        today = timezone.now().strftime("%Y-%m-%d")
        self.assertIn(f'filename="payments_{today}.csv"', resp["Content-Disposition"])

    def test_csv_header_row(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(
            rows[0],
            ["Date", "Trainee", "Email", "Type", "Amount", "Currency", "Status", "Description"],
        )


class PaymentExportDataTests(TestCase):
    """Data correctness tests for payment export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer, first_name="Alice", last_name="Smith")
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/payments/"

    def test_payment_appears_in_csv(self) -> None:
        _create_payment(
            self.trainee,
            self.trainer,
            amount=Decimal("99.00"),
            pay_status=TraineePayment.Status.SUCCEEDED,
            description="Monthly coaching",
        )
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)  # header + 1 data row
        row = rows[1]
        self.assertEqual(row[1], "Alice Smith")
        self.assertEqual(row[2], "trainee@test.com")
        self.assertEqual(row[4], "99.00")
        self.assertEqual(row[5], "USD")
        self.assertEqual(row[6], "Succeeded")
        self.assertEqual(row[7], "Monthly coaching")

    def test_all_payment_statuses_appear(self) -> None:
        """Export includes all statuses, not just succeeded."""
        for pay_status in [
            TraineePayment.Status.SUCCEEDED,
            TraineePayment.Status.FAILED,
            TraineePayment.Status.REFUNDED,
            TraineePayment.Status.PENDING,
            TraineePayment.Status.CANCELED,
        ]:
            _create_payment(self.trainee, self.trainer, pay_status=pay_status)
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 6)  # header + 5 data rows

    def test_payment_type_display(self) -> None:
        _create_payment(
            self.trainee,
            self.trainer,
            payment_type=TraineePayment.Type.ONE_TIME,
        )
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(rows[1][3], "One-Time Purchase")

    def test_empty_data_returns_header_only(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)  # header only

    def test_days_30_filters_recent(self) -> None:
        """Payments older than 30 days are excluded with default days=30."""
        _create_payment(self.trainee, self.trainer)
        old = _create_payment(self.trainee, self.trainer)
        TraineePayment.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - timedelta(days=60),
            paid_at=timezone.now() - timedelta(days=60),
        )
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)  # header + 1 recent

    def test_days_365_includes_old(self) -> None:
        """Wider period includes older payments."""
        _create_payment(self.trainee, self.trainer)
        old = _create_payment(self.trainee, self.trainer)
        TraineePayment.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - timedelta(days=60),
            paid_at=timezone.now() - timedelta(days=60),
        )
        resp = self.client.get(f"{self.url}?days=365")
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 3)  # header + 2 rows

    def test_invalid_days_defaults_to_30(self) -> None:
        _create_payment(self.trainee, self.trainer)
        old = _create_payment(self.trainee, self.trainer)
        TraineePayment.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - timedelta(days=60),
            paid_at=timezone.now() - timedelta(days=60),
        )
        resp = self.client.get(f"{self.url}?days=abc")
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)  # header + 1 recent (same as days=30)

    def test_null_paid_at_uses_created_at(self) -> None:
        """When paid_at is null, date column uses created_at."""
        payment = _create_payment(
            self.trainee,
            self.trainer,
            pay_status=TraineePayment.Status.PENDING,
        )
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertNotEqual(rows[1][0], "")  # date should not be empty


class PaymentExportIsolationTests(TestCase):
    """Row-level security tests for payment export."""

    url = "/api/trainer/export/payments/"

    def test_trainer_a_cannot_see_trainer_b_payments(self) -> None:
        trainer_a = _create_trainer("a@test.com")
        trainer_b = _create_trainer("b@test.com")
        trainee_b = _create_trainee(trainer_b, email="trainee_b@test.com")
        _create_payment(trainee_b, trainer_b)

        client = _auth_client(trainer_a)
        resp = client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)  # header only — no data


# ─────────────────────────────────────────────
# Subscriber Export Tests
# ─────────────────────────────────────────────


class SubscriberExportAuthTests(TestCase):
    """Auth tests for GET /api/trainer/export/subscribers/."""

    url = "/api/trainer/export/subscribers/"

    def test_unauthenticated_returns_401(self) -> None:
        client = APIClient()
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_non_trainer_returns_403(self) -> None:
        trainer = _create_trainer()
        trainee = _create_trainee(trainer)
        client = _auth_client(trainee)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_returns_200(self) -> None:
        trainer = _create_trainer()
        client = _auth_client(trainer)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)


class SubscriberExportResponseTests(TestCase):
    """Response format tests for subscriber export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/subscribers/"

    def test_content_type_is_csv(self) -> None:
        resp = self.client.get(self.url)
        self.assertEqual(resp["Content-Type"], "text/csv")

    def test_content_disposition_has_filename(self) -> None:
        resp = self.client.get(self.url)
        today = timezone.now().strftime("%Y-%m-%d")
        self.assertIn(f'filename="subscribers_{today}.csv"', resp["Content-Disposition"])

    def test_csv_header_row(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(
            rows[0],
            [
                "Trainee", "Email", "Amount (monthly)", "Currency",
                "Status", "Renewal Date", "Days Until Renewal", "Subscribed Since",
            ],
        )


class SubscriberExportDataTests(TestCase):
    """Data correctness tests for subscriber export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer, first_name="Bob", last_name="Jones")
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/subscribers/"

    def test_subscriber_appears_in_csv(self) -> None:
        _create_subscription(self.trainee, self.trainer, amount=Decimal("79.99"))
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)
        row = rows[1]
        self.assertEqual(row[0], "Bob Jones")
        self.assertEqual(row[1], "trainee@test.com")
        self.assertEqual(row[2], "79.99")
        self.assertEqual(row[3], "USD")
        self.assertEqual(row[4], "Active")

    def test_all_subscription_statuses_appear(self) -> None:
        """Export includes all statuses for bookkeeping."""
        emails = ["a@t.com", "b@t.com", "c@t.com", "d@t.com"]
        statuses = [
            TraineeSubscription.Status.ACTIVE,
            TraineeSubscription.Status.PAUSED,
            TraineeSubscription.Status.CANCELED,
            TraineeSubscription.Status.PAST_DUE,
        ]
        for email, sub_status in zip(emails, statuses):
            trainee = _create_trainee(self.trainer, email=email)
            _create_subscription(trainee, self.trainer, sub_status=sub_status)
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 5)  # header + 4

    def test_empty_data_returns_header_only(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)

    def test_null_period_end_shows_empty(self) -> None:
        """Null current_period_end shows empty string, not 'None'."""
        _create_subscription(self.trainee, self.trainer)
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        # Renewal Date and Days Until Renewal should be empty
        self.assertEqual(rows[1][5], "")  # Renewal Date
        self.assertEqual(rows[1][6], "")  # Days Until Renewal


class SubscriberExportIsolationTests(TestCase):
    """Row-level security tests for subscriber export."""

    url = "/api/trainer/export/subscribers/"

    def test_trainer_a_cannot_see_trainer_b_subscribers(self) -> None:
        trainer_a = _create_trainer("a@test.com")
        trainer_b = _create_trainer("b@test.com")
        trainee_b = _create_trainee(trainer_b, email="trainee_b@test.com")
        _create_subscription(trainee_b, trainer_b)

        client = _auth_client(trainer_a)
        resp = client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)  # header only


# ─────────────────────────────────────────────
# Trainee Export Tests
# ─────────────────────────────────────────────


class TraineeExportAuthTests(TestCase):
    """Auth tests for GET /api/trainer/export/trainees/."""

    url = "/api/trainer/export/trainees/"

    def test_unauthenticated_returns_401(self) -> None:
        client = APIClient()
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_non_trainer_returns_403(self) -> None:
        trainer = _create_trainer()
        trainee = _create_trainee(trainer)
        client = _auth_client(trainee)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_returns_200(self) -> None:
        trainer = _create_trainer()
        client = _auth_client(trainer)
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)


class TraineeExportResponseTests(TestCase):
    """Response format tests for trainee export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/trainees/"

    def test_content_type_is_csv(self) -> None:
        resp = self.client.get(self.url)
        self.assertEqual(resp["Content-Type"], "text/csv")

    def test_content_disposition_has_filename(self) -> None:
        resp = self.client.get(self.url)
        today = timezone.now().strftime("%Y-%m-%d")
        self.assertIn(f'filename="trainees_{today}.csv"', resp["Content-Disposition"])

    def test_csv_header_row(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(
            rows[0],
            ["Name", "Email", "Active", "Profile Complete", "Last Activity", "Current Program", "Joined"],
        )


class TraineeExportDataTests(TestCase):
    """Data correctness tests for trainee export."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.client = _auth_client(self.trainer)
        self.url = "/api/trainer/export/trainees/"

    def test_trainee_appears_in_csv(self) -> None:
        _create_trainee(self.trainer, first_name="Carol", last_name="Davis")
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)
        row = rows[1]
        self.assertEqual(row[0], "Carol Davis")
        self.assertEqual(row[1], "trainee@test.com")
        self.assertEqual(row[2], "Yes")  # is_active
        self.assertEqual(row[3], "No")  # no profile
        self.assertEqual(row[4], "")  # no logs
        self.assertEqual(row[5], "")  # no program

    def test_multiple_trainees(self) -> None:
        _create_trainee(self.trainer, email="a@test.com", first_name="A")
        _create_trainee(self.trainer, email="b@test.com", first_name="B")
        _create_trainee(self.trainer, email="c@test.com", first_name="C")
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 4)  # header + 3

    def test_empty_data_returns_header_only(self) -> None:
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)

    def test_joined_date_format(self) -> None:
        """Joined date is formatted as YYYY-MM-DD."""
        _create_trainee(self.trainer)
        resp = self.client.get(self.url)
        rows = _parse_csv(resp.content)
        joined = rows[1][6]
        self.assertRegex(joined, r"^\d{4}-\d{2}-\d{2}$")


class TraineeExportIsolationTests(TestCase):
    """Row-level security tests for trainee export."""

    url = "/api/trainer/export/trainees/"

    def test_trainer_a_cannot_see_trainer_b_trainees(self) -> None:
        trainer_a = _create_trainer("a@test.com")
        trainer_b = _create_trainer("b@test.com")
        _create_trainee(trainer_b, email="trainee_b@test.com")

        client = _auth_client(trainer_a)
        resp = client.get(self.url)
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 1)  # header only


# ─────────────────────────────────────────────
# Special Character / Edge Case Tests
# ─────────────────────────────────────────────


class CsvSpecialCharacterTests(TestCase):
    """Verify CSV properly escapes special characters (RFC 4180)."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.client = _auth_client(self.trainer)

    def test_comma_in_name_is_escaped(self) -> None:
        _create_trainee(
            self.trainer,
            first_name="O'Brien,",
            last_name='"DJ" Martinez',
        )
        resp = self.client.get("/api/trainer/export/trainees/")
        rows = _parse_csv(resp.content)
        self.assertEqual(len(rows), 2)
        # Python csv module handles quoting automatically
        self.assertIn("O'Brien,", rows[1][0])
        self.assertIn('"DJ" Martinez', rows[1][0])

    def test_description_with_commas(self) -> None:
        trainee = _create_trainee(self.trainer)
        _create_payment(
            trainee,
            self.trainer,
            description='Coaching plan, premium tier',
        )
        resp = self.client.get("/api/trainer/export/payments/")
        rows = _parse_csv(resp.content)
        self.assertEqual(rows[1][7], "Coaching plan, premium tier")

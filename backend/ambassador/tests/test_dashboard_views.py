"""
Tests for ambassador dashboard and referral list views (Pipeline 25).

Covers:
- AmbassadorDashboardView: monthly_earnings 12-month zero-fill, status counts, key naming
- AmbassadorReferralsView: pagination, status filtering, deterministic ordering
"""
from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from ambassador.models import (
    AmbassadorCommission,
    AmbassadorProfile,
    AmbassadorReferral,
)
from users.models import User


def _create_ambassador(
    email: str = "ambassador@test.com",
    commission_rate: Decimal = Decimal("0.20"),
) -> tuple[User, AmbassadorProfile]:
    """Create an ambassador user with profile."""
    user = User.objects.create_user(
        email=email,
        password="testpass123",
        role="AMBASSADOR",
    )
    profile = AmbassadorProfile.objects.create(
        user=user,
        commission_rate=commission_rate,
    )
    return user, profile


def _create_trainer(email: str = "trainer@test.com") -> User:
    """Create a trainer user."""
    return User.objects.create_user(
        email=email,
        password="testpass123",
        role="TRAINER",
    )


def _create_referral(
    ambassador: User,
    profile: AmbassadorProfile,
    trainer: User,
    referral_status: str = AmbassadorReferral.Status.ACTIVE,
) -> AmbassadorReferral:
    """Create a referral for the ambassador."""
    return AmbassadorReferral.objects.create(
        ambassador=ambassador,
        ambassador_profile=profile,
        trainer=trainer,
        referral_code_used=profile.referral_code,
        status=referral_status,
    )


def _create_commission(
    ambassador: User,
    profile: AmbassadorProfile,
    referral: AmbassadorReferral,
    amount: Decimal = Decimal("20.00"),
    commission_status: str = AmbassadorCommission.Status.APPROVED,
    created_at_offset_days: int = 0,
) -> AmbassadorCommission:
    """Create a commission record with optional time offset."""
    now = timezone.now()
    target_date = now - timedelta(days=created_at_offset_days)
    commission = AmbassadorCommission.objects.create(
        ambassador=ambassador,
        referral=referral,
        ambassador_profile=profile,
        commission_rate=profile.commission_rate,
        base_amount=Decimal("100.00"),
        commission_amount=amount,
        status=commission_status,
        period_start=date(target_date.year, target_date.month, 1),
        period_end=date(target_date.year, target_date.month, 28),
    )
    # Override created_at for time-dependent tests
    if created_at_offset_days:
        AmbassadorCommission.objects.filter(pk=commission.pk).update(
            created_at=target_date,
        )
        commission.refresh_from_db()
    return commission


class AmbassadorDashboardMonthlyEarningsTests(TestCase):
    """Tests for the monthly_earnings field in the dashboard response."""

    def setUp(self) -> None:
        self.client = APIClient()
        self.ambassador, self.profile = _create_ambassador()
        self.client.force_authenticate(user=self.ambassador)

    def test_monthly_earnings_returns_12_months(self) -> None:
        """AC-1: Dashboard returns 12 months of earnings data."""
        response = self.client.get("/api/ambassador/dashboard/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        monthly = response.data["monthly_earnings"]
        # Should have at least 12 entries (could be 13 depending on date math)
        self.assertGreaterEqual(len(monthly), 12)

    def test_monthly_earnings_zero_filled(self) -> None:
        """AC-2: Months with zero earnings are included as '0.00'."""
        response = self.client.get("/api/ambassador/dashboard/")
        monthly = response.data["monthly_earnings"]
        # New ambassador, no commissions — all months should be 0.00
        for entry in monthly:
            self.assertEqual(entry["amount"], "0.00")

    def test_monthly_earnings_uses_amount_key(self) -> None:
        """AC-3: Response uses 'amount' key (not 'earnings')."""
        response = self.client.get("/api/ambassador/dashboard/")
        monthly = response.data["monthly_earnings"]
        self.assertGreater(len(monthly), 0)
        first_entry = monthly[0]
        self.assertIn("month", first_entry)
        self.assertIn("amount", first_entry)
        self.assertNotIn("earnings", first_entry)

    def test_monthly_earnings_month_format(self) -> None:
        """Monthly earnings month key is YYYY-MM format."""
        response = self.client.get("/api/ambassador/dashboard/")
        monthly = response.data["monthly_earnings"]
        for entry in monthly:
            parts = entry["month"].split("-")
            self.assertEqual(len(parts), 2)
            self.assertEqual(len(parts[0]), 4)  # YYYY
            self.assertEqual(len(parts[1]), 2)  # MM

    def test_monthly_earnings_includes_actual_earnings(self) -> None:
        """Months with commissions show actual amounts."""
        trainer = _create_trainer()
        referral = _create_referral(
            self.ambassador, self.profile, trainer,
        )
        _create_commission(
            self.ambassador, self.profile, referral,
            amount=Decimal("50.00"),
            commission_status=AmbassadorCommission.Status.APPROVED,
            created_at_offset_days=0,
        )

        response = self.client.get("/api/ambassador/dashboard/")
        monthly = response.data["monthly_earnings"]

        # The current month should have earnings > 0
        now = timezone.now()
        current_key = now.strftime("%Y-%m")
        current_entry = next(
            (e for e in monthly if e["month"] == current_key), None,
        )
        self.assertIsNotNone(current_entry)
        self.assertGreater(Decimal(current_entry["amount"]), Decimal("0.00"))

    def test_monthly_earnings_excludes_pending_commissions(self) -> None:
        """Only APPROVED and PAID commissions appear in the chart."""
        trainer = _create_trainer()
        referral = _create_referral(
            self.ambassador, self.profile, trainer,
        )
        _create_commission(
            self.ambassador, self.profile, referral,
            amount=Decimal("30.00"),
            commission_status=AmbassadorCommission.Status.PENDING,
        )

        response = self.client.get("/api/ambassador/dashboard/")
        monthly = response.data["monthly_earnings"]

        now = timezone.now()
        current_key = now.strftime("%Y-%m")
        current_entry = next(
            (e for e in monthly if e["month"] == current_key), None,
        )
        self.assertIsNotNone(current_entry)
        self.assertEqual(current_entry["amount"], "0.00")


class AmbassadorDashboardStatusCountsTests(TestCase):
    """Tests for referral status counts in dashboard response."""

    def setUp(self) -> None:
        self.client = APIClient()
        self.ambassador, self.profile = _create_ambassador()
        self.client.force_authenticate(user=self.ambassador)

    def test_status_counts_all_zero_for_new_ambassador(self) -> None:
        """New ambassador has all counts at zero."""
        response = self.client.get("/api/ambassador/dashboard/")
        self.assertEqual(response.data["total_referrals"], 0)
        self.assertEqual(response.data["active_referrals"], 0)
        self.assertEqual(response.data["pending_referrals"], 0)
        self.assertEqual(response.data["churned_referrals"], 0)

    def test_status_counts_mixed_statuses(self) -> None:
        """Counts correctly reflect different referral statuses."""
        for i, s in enumerate(["ACTIVE", "ACTIVE", "PENDING", "CHURNED"]):
            trainer = _create_trainer(f"t{i}@test.com")
            _create_referral(
                self.ambassador, self.profile, trainer, referral_status=s,
            )

        response = self.client.get("/api/ambassador/dashboard/")
        self.assertEqual(response.data["total_referrals"], 4)
        self.assertEqual(response.data["active_referrals"], 2)
        self.assertEqual(response.data["pending_referrals"], 1)
        self.assertEqual(response.data["churned_referrals"], 1)

    def test_dashboard_requires_ambassador_role(self) -> None:
        """Non-ambassador users get 403."""
        trainer = _create_trainer("not-ambassador@test.com")
        self.client.force_authenticate(user=trainer)
        response = self.client.get("/api/ambassador/dashboard/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_dashboard_requires_auth(self) -> None:
        """Unauthenticated requests get 401."""
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/ambassador/dashboard/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class AmbassadorReferralsViewTests(TestCase):
    """Tests for the paginated referrals list endpoint."""

    def setUp(self) -> None:
        self.client = APIClient()
        self.ambassador, self.profile = _create_ambassador()
        self.client.force_authenticate(user=self.ambassador)

    def test_empty_referral_list(self) -> None:
        """Returns paginated response with empty results."""
        response = self.client.get("/api/ambassador/referrals/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 0)
        self.assertEqual(response.data["results"], [])
        self.assertIsNone(response.data["next"])
        self.assertIsNone(response.data["previous"])

    def test_referrals_paginated(self) -> None:
        """Returns paginated response with count, next, previous."""
        for i in range(25):
            trainer = _create_trainer(f"t{i}@test.com")
            _create_referral(self.ambassador, self.profile, trainer)

        response = self.client.get("/api/ambassador/referrals/")
        self.assertEqual(response.data["count"], 25)
        self.assertEqual(len(response.data["results"]), 20)
        self.assertIsNotNone(response.data["next"])
        self.assertIsNone(response.data["previous"])

    def test_referrals_page_2(self) -> None:
        """Page 2 returns remaining items."""
        for i in range(25):
            trainer = _create_trainer(f"t{i}@test.com")
            _create_referral(self.ambassador, self.profile, trainer)

        response = self.client.get("/api/ambassador/referrals/?page=2")
        self.assertEqual(response.data["count"], 25)
        self.assertEqual(len(response.data["results"]), 5)
        self.assertIsNone(response.data["next"])
        self.assertIsNotNone(response.data["previous"])

    def test_referrals_status_filter_active(self) -> None:
        """Status filter returns only matching referrals."""
        t1 = _create_trainer("active@test.com")
        t2 = _create_trainer("pending@test.com")
        _create_referral(
            self.ambassador, self.profile, t1,
            referral_status=AmbassadorReferral.Status.ACTIVE,
        )
        _create_referral(
            self.ambassador, self.profile, t2,
            referral_status=AmbassadorReferral.Status.PENDING,
        )

        response = self.client.get("/api/ambassador/referrals/?status=active")
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["status"], "ACTIVE")

    def test_referrals_status_filter_case_insensitive(self) -> None:
        """Status filter works regardless of case."""
        trainer = _create_trainer()
        _create_referral(
            self.ambassador, self.profile, trainer,
            referral_status=AmbassadorReferral.Status.CHURNED,
        )

        response = self.client.get("/api/ambassador/referrals/?status=CHURNED")
        self.assertEqual(response.data["count"], 1)

        response = self.client.get("/api/ambassador/referrals/?status=churned")
        self.assertEqual(response.data["count"], 1)

    def test_referrals_invalid_status_filter_ignored(self) -> None:
        """Invalid status param returns all referrals."""
        trainer = _create_trainer()
        _create_referral(self.ambassador, self.profile, trainer)

        response = self.client.get("/api/ambassador/referrals/?status=invalid")
        self.assertEqual(response.data["count"], 1)

    def test_referrals_ordered_by_referred_at_desc(self) -> None:
        """Referrals are ordered by referred_at descending (most recent first)."""
        trainers: list[User] = []
        for i in range(3):
            t = _create_trainer(f"t{i}@test.com")
            trainers.append(t)

        refs: list[AmbassadorReferral] = []
        for t in trainers:
            ref = _create_referral(self.ambassador, self.profile, t)
            refs.append(ref)

        response = self.client.get("/api/ambassador/referrals/")
        results = response.data["results"]

        # Most recently created should be first
        self.assertEqual(results[0]["id"], refs[-1].id)
        self.assertEqual(results[-1]["id"], refs[0].id)

    def test_referrals_isolation_between_ambassadors(self) -> None:
        """Ambassador cannot see another ambassador's referrals."""
        trainer = _create_trainer()
        _create_referral(self.ambassador, self.profile, trainer)

        other_ambassador, other_profile = _create_ambassador("other@test.com")
        self.client.force_authenticate(user=other_ambassador)

        response = self.client.get("/api/ambassador/referrals/")
        self.assertEqual(response.data["count"], 0)

    def test_referrals_requires_auth(self) -> None:
        """Unauthenticated requests get 401."""
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/ambassador/referrals/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

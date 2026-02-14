"""
Business logic for ambassador referrals and commission calculation.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from django.db import transaction
from django.utils import timezone

from ambassador.models import AmbassadorCommission, AmbassadorProfile, AmbassadorReferral
from users.models import User

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ReferralResult:
    """Result of processing a referral code during registration."""
    success: bool
    referral: Optional[AmbassadorReferral]
    message: str


@dataclass(frozen=True)
class CommissionResult:
    """Result of creating a commission record."""
    success: bool
    commission: Optional[AmbassadorCommission]
    message: str


class ReferralService:
    """Handles referral code processing and commission creation."""

    @staticmethod
    def process_referral_code(
        trainer: User,
        referral_code: str,
    ) -> ReferralResult:
        """
        Process a referral code during trainer registration.

        Rules:
        - Code must belong to an active ambassador
        - Trainer cannot already have a referral
        - Ambassador cannot refer themselves
        - Invalid codes are silently ignored (don't block registration)
        """
        referral_code = referral_code.strip().upper()

        if not referral_code:
            return ReferralResult(success=False, referral=None, message="Empty referral code")

        try:
            profile = AmbassadorProfile.objects.select_related('user').get(
                referral_code=referral_code,
                is_active=True,
            )
        except AmbassadorProfile.DoesNotExist:
            logger.warning("Invalid or inactive referral code used: %s", referral_code)
            return ReferralResult(success=False, referral=None, message="Invalid referral code")

        # Ambassador cannot refer themselves
        if profile.user_id == trainer.id:
            logger.warning("Ambassador %s tried to refer themselves", profile.user.email)
            return ReferralResult(success=False, referral=None, message="Cannot refer yourself")

        # Check if trainer already has a referral (first referral wins)
        if AmbassadorReferral.objects.filter(trainer=trainer).exists():
            logger.info("Trainer %s already has a referral, ignoring code %s", trainer.email, referral_code)
            return ReferralResult(success=False, referral=None, message="Trainer already referred")

        with transaction.atomic():
            referral = AmbassadorReferral.objects.create(
                ambassador=profile.user,
                trainer=trainer,
                ambassador_profile=profile,
                referral_code_used=referral_code,
                status=AmbassadorReferral.Status.PENDING,
            )

        # Update cached stats outside transaction to avoid extra queries in txn
        profile.total_referrals = profile.referrals.count()
        profile.save(update_fields=['total_referrals', 'updated_at'])

        logger.info(
            "Referral created: ambassador=%s, trainer=%s, code=%s",
            profile.user.email, trainer.email, referral_code,
        )
        return ReferralResult(success=True, referral=referral, message="Referral recorded")

    @staticmethod
    def create_commission(
        referral: AmbassadorReferral,
        base_amount: Decimal,
        period_start: timezone.datetime,
        period_end: timezone.datetime,
    ) -> CommissionResult:
        """
        Create a commission record when a referred trainer's subscription payment succeeds.

        On first payment, also activates the referral.
        Commission rate is snapshot from the ambassador profile at time of charge.
        """
        profile = referral.ambassador_profile

        if not profile.is_active:
            logger.info(
                "Skipping commission for inactive ambassador %s",
                referral.ambassador.email,
            )
            return CommissionResult(
                success=False, commission=None, message="Ambassador is inactive",
            )

        commission_rate = profile.commission_rate
        commission_amount = (base_amount * commission_rate).quantize(Decimal('0.01'))

        with transaction.atomic():
            # Activate referral on first payment
            if referral.status == AmbassadorReferral.Status.PENDING:
                referral.activate()

            # Reactivate churned referral if trainer resubscribes
            if referral.status == AmbassadorReferral.Status.CHURNED:
                referral.reactivate()

            commission = AmbassadorCommission.objects.create(
                ambassador=referral.ambassador,
                referral=referral,
                ambassador_profile=profile,
                commission_rate=commission_rate,
                base_amount=base_amount,
                commission_amount=commission_amount,
                status=AmbassadorCommission.Status.PENDING,
                period_start=period_start.date() if hasattr(period_start, 'date') else period_start,
                period_end=period_end.date() if hasattr(period_end, 'date') else period_end,
            )

        # Update cached earnings outside transaction
        profile.refresh_cached_stats()

        logger.info(
            "Commission created: ambassador=%s, amount=$%s, referral=%s",
            referral.ambassador.email, commission_amount, referral.id,
        )
        return CommissionResult(
            success=True, commission=commission, message="Commission created",
        )

    @staticmethod
    def handle_trainer_churn(trainer: User) -> None:
        """Mark all referrals for a trainer as churned when they cancel subscription."""
        referrals = AmbassadorReferral.objects.filter(
            trainer=trainer,
            status=AmbassadorReferral.Status.ACTIVE,
        )
        for referral in referrals:
            referral.mark_churned()
            logger.info(
                "Referral churned: ambassador=%s, trainer=%s",
                referral.ambassador.email, trainer.email,
            )

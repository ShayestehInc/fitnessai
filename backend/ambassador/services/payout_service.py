"""
Stripe Connect payout service for ambassador commissions.

Handles onboarding ambassadors to Stripe Express accounts and executing payouts
via Stripe Transfers.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Sequence

from django.conf import settings
from django.db import transaction

from ambassador.models import (
    AmbassadorCommission,
    AmbassadorProfile,
    AmbassadorStripeAccount,
    PayoutRecord,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class OnboardingResult:
    """Result of Stripe Connect onboarding link generation."""
    success: bool
    onboarding_url: str
    message: str


@dataclass(frozen=True)
class ConnectStatusResult:
    """Current status of ambassador's Stripe Connect account."""
    has_account: bool
    stripe_account_id: str | None
    charges_enabled: bool
    payouts_enabled: bool
    details_submitted: bool
    onboarding_completed: bool


@dataclass(frozen=True)
class PayoutResult:
    """Result of executing a payout."""
    success: bool
    message: str
    payout_record_id: int | None
    amount: Decimal


class PayoutService:
    """Handles Stripe Connect onboarding and payout execution."""

    @staticmethod
    def get_connect_status(ambassador_profile_id: int) -> ConnectStatusResult:
        """
        Get the current Stripe Connect account status for an ambassador.

        Raises
        ------
        AmbassadorProfile.DoesNotExist
            If the ambassador profile is not found.
        """
        profile = AmbassadorProfile.objects.get(id=ambassador_profile_id)

        try:
            stripe_account = AmbassadorStripeAccount.objects.get(
                ambassador_profile=profile,
            )
        except AmbassadorStripeAccount.DoesNotExist:
            return ConnectStatusResult(
                has_account=False,
                stripe_account_id=None,
                charges_enabled=False,
                payouts_enabled=False,
                details_submitted=False,
                onboarding_completed=False,
            )

        return ConnectStatusResult(
            has_account=True,
            stripe_account_id=stripe_account.stripe_account_id,
            charges_enabled=stripe_account.charges_enabled,
            payouts_enabled=stripe_account.payouts_enabled,
            details_submitted=stripe_account.details_submitted,
            onboarding_completed=stripe_account.onboarding_completed,
        )

    @staticmethod
    def create_connect_account(
        ambassador_profile_id: int,
        return_url: str,
        refresh_url: str,
    ) -> OnboardingResult:
        """
        Create a Stripe Express account for the ambassador and return an
        onboarding link.

        If the ambassador already has a Stripe account but hasn't completed
        onboarding, generates a new account link for the existing account.

        Raises
        ------
        AmbassadorProfile.DoesNotExist
            If the ambassador profile is not found.
        RuntimeError
            If Stripe API call fails.
        """
        import stripe  # type: ignore[import-untyped]

        stripe.api_key = settings.STRIPE_SECRET_KEY
        if not stripe.api_key:
            raise RuntimeError("STRIPE_SECRET_KEY is not configured.")

        profile = AmbassadorProfile.objects.select_related('user').get(
            id=ambassador_profile_id,
        )

        stripe_account, created = AmbassadorStripeAccount.objects.get_or_create(
            ambassador_profile=profile,
        )

        # Create Stripe account if not yet created
        if not stripe_account.stripe_account_id:
            account = stripe.Account.create(
                type='express',
                email=profile.user.email,
                metadata={
                    'ambassador_profile_id': str(profile.id),
                    'user_id': str(profile.user_id),
                },
            )
            stripe_account.stripe_account_id = account.id
            stripe_account.save(update_fields=['stripe_account_id', 'updated_at'])
            logger.info(
                "Created Stripe Express account %s for ambassador %s",
                account.id, profile.user.email,
            )

        # Generate account link for onboarding
        account_link = stripe.AccountLink.create(
            account=stripe_account.stripe_account_id,
            refresh_url=refresh_url,
            return_url=return_url,
            type='account_onboarding',
        )

        return OnboardingResult(
            success=True,
            onboarding_url=account_link.url,
            message="Onboarding link generated.",
        )

    @staticmethod
    def sync_account_status(ambassador_profile_id: int) -> ConnectStatusResult:
        """
        Sync the Stripe account status from the Stripe API.

        Raises
        ------
        AmbassadorStripeAccount.DoesNotExist
            If no Stripe account exists for this ambassador.
        RuntimeError
            If Stripe API call fails.
        """
        import stripe  # type: ignore[import-untyped]

        stripe.api_key = settings.STRIPE_SECRET_KEY
        if not stripe.api_key:
            raise RuntimeError("STRIPE_SECRET_KEY is not configured.")

        stripe_account = AmbassadorStripeAccount.objects.select_related(
            'ambassador_profile',
        ).get(ambassador_profile_id=ambassador_profile_id)

        if not stripe_account.stripe_account_id:
            raise RuntimeError("Stripe account ID is not set.")

        account = stripe.Account.retrieve(stripe_account.stripe_account_id)

        stripe_account.charges_enabled = account.charges_enabled
        stripe_account.payouts_enabled = account.payouts_enabled
        stripe_account.details_submitted = account.details_submitted
        stripe_account.onboarding_completed = (
            account.charges_enabled and account.details_submitted
        )
        stripe_account.save(update_fields=[
            'charges_enabled', 'payouts_enabled',
            'details_submitted', 'onboarding_completed', 'updated_at',
        ])

        return ConnectStatusResult(
            has_account=True,
            stripe_account_id=stripe_account.stripe_account_id,
            charges_enabled=stripe_account.charges_enabled,
            payouts_enabled=stripe_account.payouts_enabled,
            details_submitted=stripe_account.details_submitted,
            onboarding_completed=stripe_account.onboarding_completed,
        )

    @staticmethod
    def execute_payout(
        ambassador_profile_id: int,
        commission_ids: Sequence[int] | None = None,
    ) -> PayoutResult:
        """
        Execute a payout to the ambassador for approved commissions.

        If commission_ids is None, pays out ALL approved commissions.
        Uses Stripe Transfer to send funds to the ambassador's Express account.

        Raises
        ------
        AmbassadorProfile.DoesNotExist
            If the ambassador profile is not found.
        RuntimeError
            If Stripe API or configuration error occurs.
        """
        import stripe  # type: ignore[import-untyped]

        stripe.api_key = settings.STRIPE_SECRET_KEY
        if not stripe.api_key:
            raise RuntimeError("STRIPE_SECRET_KEY is not configured.")

        with transaction.atomic():
            profile = AmbassadorProfile.objects.select_for_update().get(
                id=ambassador_profile_id,
            )

            # Verify Stripe account is ready
            try:
                stripe_account = AmbassadorStripeAccount.objects.get(
                    ambassador_profile=profile,
                )
            except AmbassadorStripeAccount.DoesNotExist:
                return PayoutResult(
                    success=False,
                    message="Ambassador has no Stripe Connect account.",
                    payout_record_id=None,
                    amount=Decimal('0.00'),
                )

            if not stripe_account.payouts_enabled:
                return PayoutResult(
                    success=False,
                    message="Stripe Connect account is not ready for payouts.",
                    payout_record_id=None,
                    amount=Decimal('0.00'),
                )

            # Lock and fetch approved commissions
            commission_qs = (
                AmbassadorCommission.objects
                .select_for_update()
                .filter(
                    ambassador_profile=profile,
                    status=AmbassadorCommission.Status.APPROVED,
                )
            )
            if commission_ids is not None:
                commission_qs = commission_qs.filter(id__in=commission_ids)

            commissions = list(commission_qs)

            if not commissions:
                return PayoutResult(
                    success=False,
                    message="No approved commissions to pay out.",
                    payout_record_id=None,
                    amount=Decimal('0.00'),
                )

            total_amount = sum(c.commission_amount for c in commissions)

            # Create payout record first (pending)
            payout_record = PayoutRecord.objects.create(
                ambassador_profile=profile,
                amount=total_amount,
                status=PayoutRecord.Status.PENDING,
            )
            payout_record.commissions_included.set(commissions)

            # Execute Stripe transfer
            try:
                transfer = stripe.Transfer.create(
                    amount=int(total_amount * 100),  # Convert to cents
                    currency='usd',
                    destination=stripe_account.stripe_account_id,
                    metadata={
                        'payout_record_id': str(payout_record.id),
                        'ambassador_profile_id': str(profile.id),
                        'commission_count': str(len(commissions)),
                    },
                )

                # Mark payout as completed
                payout_record.stripe_transfer_id = transfer.id
                payout_record.status = PayoutRecord.Status.COMPLETED
                payout_record.save(update_fields=[
                    'stripe_transfer_id', 'status',
                ])

                # Mark commissions as paid
                commission_ids_to_pay = [c.id for c in commissions]
                AmbassadorCommission.objects.filter(
                    id__in=commission_ids_to_pay,
                ).update(status=AmbassadorCommission.Status.PAID)

                # Refresh cached stats
                profile.refresh_cached_stats()

                logger.info(
                    "Payout %s completed: $%s to ambassador %s via transfer %s",
                    payout_record.id, total_amount, profile.user.email, transfer.id,
                )

                return PayoutResult(
                    success=True,
                    message=f"Payout of ${total_amount} completed successfully.",
                    payout_record_id=payout_record.id,
                    amount=total_amount,
                )

            except stripe.error.StripeError as e:
                payout_record.status = PayoutRecord.Status.FAILED
                payout_record.error_message = str(e)
                payout_record.save(update_fields=['status', 'error_message'])

                logger.error(
                    "Stripe transfer failed for payout %s: %s",
                    payout_record.id, e,
                )

                return PayoutResult(
                    success=False,
                    message=f"Stripe transfer failed: {e}",
                    payout_record_id=payout_record.id,
                    amount=total_amount,
                )

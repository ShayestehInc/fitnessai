"""
Business logic for commission approval and payment workflows.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Sequence

from django.db import transaction

from ambassador.models import AmbassadorCommission, AmbassadorProfile

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class CommissionActionResult:
    """Result of a single commission action (approve or pay)."""
    success: bool
    message: str


@dataclass(frozen=True)
class BulkActionResult:
    """Result of a bulk commission action (bulk approve or bulk pay)."""
    success: bool
    processed_count: int
    skipped_count: int
    message: str


def _refresh_ambassador_stats(ambassador_profile_id: int) -> None:
    """Safely refresh cached stats for an ambassador profile.

    Handles the case where the profile does not exist (e.g. deleted between
    the commission update and the stats refresh) by logging a warning rather
    than letting a DoesNotExist propagate as a 500.
    """
    try:
        profile = AmbassadorProfile.objects.get(id=ambassador_profile_id)
    except AmbassadorProfile.DoesNotExist:
        logger.warning(
            "Cannot refresh cached stats: AmbassadorProfile %d not found",
            ambassador_profile_id,
        )
        return
    profile.refresh_cached_stats()


class CommissionService:
    """Handles commission approval and payment workflows."""

    @staticmethod
    def approve_commission(
        commission_id: int,
        ambassador_profile_id: int,
    ) -> CommissionActionResult:
        """
        Approve a single PENDING commission.

        Uses select_for_update() to prevent concurrent double-processing.
        After approval, refreshes the ambassador's cached stats.

        Raises:
            AmbassadorCommission.DoesNotExist: If commission not found for this ambassador.
        """
        with transaction.atomic():
            try:
                commission = (
                    AmbassadorCommission.objects
                    .select_for_update()
                    .get(
                        id=commission_id,
                        ambassador_profile_id=ambassador_profile_id,
                    )
                )
            except AmbassadorCommission.DoesNotExist:
                return CommissionActionResult(
                    success=False,
                    message="Commission not found.",
                )

            if commission.status == AmbassadorCommission.Status.APPROVED:
                return CommissionActionResult(
                    success=False,
                    message="Commission is already approved.",
                )

            if commission.status == AmbassadorCommission.Status.PAID:
                return CommissionActionResult(
                    success=False,
                    message="Commission is already paid.",
                )

            if commission.status != AmbassadorCommission.Status.PENDING:
                return CommissionActionResult(
                    success=False,
                    message=f"Commission has unexpected status: {commission.status}.",
                )

            commission.status = AmbassadorCommission.Status.APPROVED
            commission.save(update_fields=["status"])

            # Refresh cached stats inside the transaction so the aggregation
            # reads a consistent snapshot while the lock is still held.
            _refresh_ambassador_stats(ambassador_profile_id)

        logger.info(
            "Commission %d approved for ambassador profile %d",
            commission_id,
            ambassador_profile_id,
        )
        return CommissionActionResult(success=True, message="Commission approved.")

    @staticmethod
    def pay_commission(
        commission_id: int,
        ambassador_profile_id: int,
    ) -> CommissionActionResult:
        """
        Mark a single APPROVED commission as PAID.

        Uses select_for_update() to prevent concurrent double-processing.
        After payment, refreshes the ambassador's cached stats.

        Raises:
            AmbassadorCommission.DoesNotExist: If commission not found for this ambassador.
        """
        with transaction.atomic():
            try:
                commission = (
                    AmbassadorCommission.objects
                    .select_for_update()
                    .get(
                        id=commission_id,
                        ambassador_profile_id=ambassador_profile_id,
                    )
                )
            except AmbassadorCommission.DoesNotExist:
                return CommissionActionResult(
                    success=False,
                    message="Commission not found.",
                )

            if commission.status == AmbassadorCommission.Status.PAID:
                return CommissionActionResult(
                    success=False,
                    message="Commission is already paid.",
                )

            if commission.status == AmbassadorCommission.Status.PENDING:
                return CommissionActionResult(
                    success=False,
                    message="Commission must be approved before it can be marked as paid.",
                )

            if commission.status != AmbassadorCommission.Status.APPROVED:
                return CommissionActionResult(
                    success=False,
                    message=f"Commission has unexpected status: {commission.status}.",
                )

            commission.status = AmbassadorCommission.Status.PAID
            commission.save(update_fields=["status"])

            # Refresh cached stats inside the transaction so the aggregation
            # reads a consistent snapshot while the lock is still held.
            _refresh_ambassador_stats(ambassador_profile_id)

        logger.info(
            "Commission %d marked paid for ambassador profile %d",
            commission_id,
            ambassador_profile_id,
        )
        return CommissionActionResult(success=True, message="Commission marked as paid.")

    @staticmethod
    def bulk_approve(
        commission_ids: Sequence[int],
        ambassador_profile_id: int,
    ) -> BulkActionResult:
        """
        Approve all PENDING commissions in the given list for the specified ambassador.

        Commissions that are not PENDING are skipped (not errored).
        Uses select_for_update() to lock rows and prevent concurrent processing.
        """
        with transaction.atomic():
            # Force evaluation of the locked queryset by materialising the IDs.
            # This ensures the SELECT FOR UPDATE is executed and locks are held
            # before the subsequent UPDATE runs.
            locked_ids: list[int] = list(
                AmbassadorCommission.objects
                .select_for_update()
                .filter(
                    id__in=commission_ids,
                    ambassador_profile_id=ambassador_profile_id,
                )
                .values_list('id', flat=True)
            )

            total_found = len(locked_ids)
            approved_count = (
                AmbassadorCommission.objects
                .filter(
                    id__in=locked_ids,
                    status=AmbassadorCommission.Status.PENDING,
                )
                .update(status=AmbassadorCommission.Status.APPROVED)
            )
            skipped_count = total_found - approved_count

            # Refresh cached stats inside the transaction so the aggregation
            # reads a consistent snapshot while the lock is still held.
            _refresh_ambassador_stats(ambassador_profile_id)

        logger.info(
            "Bulk approved %d commissions (%d skipped) for ambassador profile %d",
            approved_count,
            skipped_count,
            ambassador_profile_id,
        )

        if approved_count == 0 and skipped_count == 0:
            message = "No matching commissions found."
        elif approved_count == 0:
            message = "No pending commissions to approve."
        else:
            message = f"{approved_count} commission(s) approved."

        return BulkActionResult(
            success=True,
            processed_count=approved_count,
            skipped_count=skipped_count,
            message=message,
        )

    @staticmethod
    def bulk_pay(
        commission_ids: Sequence[int],
        ambassador_profile_id: int,
    ) -> BulkActionResult:
        """
        Mark all APPROVED commissions in the given list as PAID for the specified ambassador.

        Commissions that are not APPROVED are skipped (not errored).
        Uses select_for_update() to lock rows and prevent concurrent processing.
        """
        with transaction.atomic():
            # Force evaluation of the locked queryset by materialising the IDs.
            # This ensures the SELECT FOR UPDATE is executed and locks are held
            # before the subsequent UPDATE runs.
            locked_ids: list[int] = list(
                AmbassadorCommission.objects
                .select_for_update()
                .filter(
                    id__in=commission_ids,
                    ambassador_profile_id=ambassador_profile_id,
                )
                .values_list('id', flat=True)
            )

            total_found = len(locked_ids)
            paid_count = (
                AmbassadorCommission.objects
                .filter(
                    id__in=locked_ids,
                    status=AmbassadorCommission.Status.APPROVED,
                )
                .update(status=AmbassadorCommission.Status.PAID)
            )
            skipped_count = total_found - paid_count

            # Refresh cached stats inside the transaction so the aggregation
            # reads a consistent snapshot while the lock is still held.
            _refresh_ambassador_stats(ambassador_profile_id)

        logger.info(
            "Bulk paid %d commissions (%d skipped) for ambassador profile %d",
            paid_count,
            skipped_count,
            ambassador_profile_id,
        )

        if paid_count == 0 and skipped_count == 0:
            message = "No matching commissions found."
        elif paid_count == 0:
            message = "No approved commissions to mark as paid."
        else:
            message = f"{paid_count} commission(s) marked as paid."

        return BulkActionResult(
            success=True,
            processed_count=paid_count,
            skipped_count=skipped_count,
            message=message,
        )

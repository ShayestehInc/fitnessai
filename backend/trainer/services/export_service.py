"""
Service for generating CSV exports of trainer data:
payments, subscribers, and trainees.
"""
from __future__ import annotations

import csv
import io
from dataclasses import dataclass
from datetime import timedelta
from typing import TYPE_CHECKING

from django.utils import timezone

if TYPE_CHECKING:
    from users.models import User


@dataclass(frozen=True)
class CsvExportResult:
    """Immutable result of a CSV export operation."""
    content: str
    filename: str
    row_count: int


PAYMENT_HEADERS = [
    "Date", "Trainee", "Email", "Type", "Amount",
    "Currency", "Status", "Description",
]

SUBSCRIBER_HEADERS = [
    "Trainee", "Email", "Amount (monthly)", "Currency",
    "Status", "Renewal Date", "Days Until Renewal", "Subscribed Since",
]

TRAINEE_HEADERS = [
    "Name", "Email", "Active", "Profile Complete",
    "Last Activity", "Current Program", "Joined",
]


def _format_date(dt: object) -> str:
    """Format a datetime as YYYY-MM-DD HH:MM:SS, or return empty string for None."""
    if dt is None:
        return ""
    return dt.strftime("%Y-%m-%d %H:%M:%S")  # type: ignore[union-attr]


def _format_date_only(dt: object) -> str:
    """Format a datetime/date as YYYY-MM-DD, or return empty string for None."""
    if dt is None:
        return ""
    return dt.strftime("%Y-%m-%d")  # type: ignore[union-attr]


def _safe_str(value: object) -> str:
    """Convert value to string, returning empty string for None."""
    if value is None:
        return ""
    return str(value)


def export_payments_csv(trainer: User, days: int) -> CsvExportResult:
    """
    Export all payments for a trainer within the given day range as CSV.

    Args:
        trainer: The authenticated trainer.
        days: Number of days to look back (1-365).

    Returns:
        CsvExportResult with CSV content, filename, and row count.
    """
    from subscriptions.models import TraineePayment

    start_date = timezone.now() - timedelta(days=days)
    payments = (
        TraineePayment.objects.filter(
            trainer=trainer,
            created_at__gte=start_date,
        )
        .select_related("trainee")
        .order_by("-created_at")
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(PAYMENT_HEADERS)

    row_count = 0
    for payment in payments:
        trainee = payment.trainee
        name = f"{trainee.first_name} {trainee.last_name}".strip()
        date_val = payment.paid_at if payment.paid_at else payment.created_at
        writer.writerow([
            _format_date(date_val),
            name or trainee.email,
            trainee.email,
            payment.get_payment_type_display(),
            str(payment.amount),
            payment.currency.upper(),
            payment.get_status_display(),
            payment.description,
        ])
        row_count += 1

    today = timezone.now().strftime("%Y-%m-%d")
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f"payments_{today}.csv",
        row_count=row_count,
    )


def export_subscribers_csv(trainer: User) -> CsvExportResult:
    """
    Export all subscriptions for a trainer as CSV.

    Includes all statuses (active, paused, canceled, past_due) for
    complete bookkeeping records.

    Args:
        trainer: The authenticated trainer.

    Returns:
        CsvExportResult with CSV content, filename, and row count.
    """
    from subscriptions.models import TraineeSubscription

    subscriptions = (
        TraineeSubscription.objects.filter(trainer=trainer)
        .select_related("trainee")
        .order_by("-created_at")
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(SUBSCRIBER_HEADERS)

    row_count = 0
    for sub in subscriptions:
        trainee = sub.trainee
        name = f"{trainee.first_name} {trainee.last_name}".strip()
        renewal_days = sub.days_until_renewal()
        writer.writerow([
            name or trainee.email,
            trainee.email,
            str(sub.amount),
            sub.currency.upper(),
            sub.get_status_display(),
            _format_date(sub.current_period_end),
            _safe_str(renewal_days),
            _format_date(sub.created_at),
        ])
        row_count += 1

    today = timezone.now().strftime("%Y-%m-%d")
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f"subscribers_{today}.csv",
        row_count=row_count,
    )


def export_trainees_csv(trainer: User) -> CsvExportResult:
    """
    Export all trainees for a trainer as CSV.

    Args:
        trainer: The authenticated trainer.

    Returns:
        CsvExportResult with CSV content, filename, and row count.
    """
    from users.models import User as UserModel

    trainees = (
        UserModel.objects.filter(
            parent_trainer=trainer,
            role=UserModel.Role.TRAINEE,
        )
        .select_related("profile")
        .prefetch_related("programs", "daily_logs")
        .order_by("-created_at")
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(TRAINEE_HEADERS)

    row_count = 0
    for trainee in trainees:
        name = f"{trainee.first_name} {trainee.last_name}".strip()

        # Profile complete check
        try:
            profile_complete = trainee.profile.onboarding_completed
        except UserModel.profile.RelatedObjectDoesNotExist:  # type: ignore[union-attr]
            profile_complete = False

        # Last activity from prefetched daily_logs
        logs = list(trainee.daily_logs.all())
        last_activity = str(max(log.date for log in logs)) if logs else ""

        # Current program from prefetched programs
        active_program = next(
            (p for p in trainee.programs.all() if p.is_active),
            None,
        )
        program_name = active_program.name if active_program else ""

        writer.writerow([
            name or trainee.email,
            trainee.email,
            "Yes" if trainee.is_active else "No",
            "Yes" if profile_complete else "No",
            last_activity,
            program_name,
            _format_date_only(trainee.created_at),
        ])
        row_count += 1

    today = timezone.now().strftime("%Y-%m-%d")
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f"trainees_{today}.csv",
        row_count=row_count,
    )

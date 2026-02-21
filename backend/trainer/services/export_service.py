"""
Service for generating CSV exports of trainer data:
payments, subscribers, and trainees.
"""
from __future__ import annotations

import csv
import io
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import TYPE_CHECKING

from django.db.models import Max, Prefetch
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


def _format_date(dt: datetime | None) -> str:
    """Format a datetime as YYYY-MM-DD HH:MM:SS, or return empty string for None."""
    if dt is None:
        return ""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _format_date_only(dt: datetime | date | None) -> str:
    """Format a datetime/date as YYYY-MM-DD, or return empty string for None."""
    if dt is None:
        return ""
    return dt.strftime("%Y-%m-%d")


_CSV_FORMULA_PREFIXES = ("=", "+", "-", "@", "\t", "\r")


def _sanitize_csv_value(value: str) -> str:
    """
    Sanitize a string for safe CSV output by neutralizing formula injection.

    Spreadsheet applications (Excel, Google Sheets, LibreOffice Calc) interpret
    cells starting with =, +, -, @, \\t, or \\r as formulas. A malicious user
    could set their name or description to something like '=HYPERLINK(...)' to
    trigger code execution when a trainer opens the CSV.

    Mitigation: prefix dangerous values with a single-quote (') which forces
    the cell to be treated as a text literal in all major spreadsheet apps.

    See OWASP CSV Injection: https://owasp.org/www-community/attacks/CSV_Injection
    """
    if value and value[0] in _CSV_FORMULA_PREFIXES:
        return f"'{value}"
    return value


def _safe_str(value: object) -> str:
    """Convert value to string, returning empty string for None. Sanitizes against CSV injection."""
    if value is None:
        return ""
    return _sanitize_csv_value(str(value))


def _format_amount(amount: Decimal) -> str:
    """Format a Decimal amount with exactly 2 decimal places."""
    return f"{amount:.2f}"


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
            _sanitize_csv_value(name or trainee.email),
            _sanitize_csv_value(trainee.email),
            _safe_str(payment.get_payment_type_display()),
            _format_amount(payment.amount),
            payment.currency.upper(),
            _safe_str(payment.get_status_display()),
            _sanitize_csv_value(payment.description),
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
            _sanitize_csv_value(name or trainee.email),
            _sanitize_csv_value(trainee.email),
            _format_amount(sub.amount),
            sub.currency.upper(),
            _safe_str(sub.get_status_display()),
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

    Uses annotation for last_log_date instead of prefetching all daily_logs
    to avoid unbounded memory usage.

    Args:
        trainer: The authenticated trainer.

    Returns:
        CsvExportResult with CSV content, filename, and row count.
    """
    from users.models import User as UserModel
    from workouts.models import Program

    trainees = (
        UserModel.objects.filter(
            parent_trainer=trainer,
            role=UserModel.Role.TRAINEE,
        )
        .select_related("profile")
        .prefetch_related(
            Prefetch(
                "programs",
                queryset=Program.objects.filter(is_active=True),
                to_attr="active_programs",
            )
        )
        .annotate(last_log_date=Max("daily_logs__date"))
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

        # Last activity from annotated Max
        last_activity = _format_date_only(trainee.last_log_date)  # type: ignore[attr-defined]

        # Current program from filtered prefetch
        active_programs: list[Program] = trainee.active_programs  # type: ignore[attr-defined]
        program_name = active_programs[0].name if active_programs else ""

        writer.writerow([
            _sanitize_csv_value(name or trainee.email),
            _sanitize_csv_value(trainee.email),
            "Yes" if trainee.is_active else "No",
            "Yes" if profile_complete else "No",
            last_activity,
            _sanitize_csv_value(program_name),
            _format_date_only(trainee.created_at),
        ])
        row_count += 1

    today = timezone.now().strftime("%Y-%m-%d")
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f"trainees_{today}.csv",
        row_count=row_count,
    )

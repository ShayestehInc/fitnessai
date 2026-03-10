"""
Audit + trainee data export service — v6.5 Step 16.

CSV exports for:
- Decision logs (audit trail)
- Trainee workout history (LiftSetLog)
- Trainee nutrition history (TraineeActivitySummary)
- Trainee progress (weight check-ins + e1RM history)
"""
from __future__ import annotations

import csv
import io
import re
from datetime import timedelta
from typing import TYPE_CHECKING, Any

from django.db.models import Q
from django.utils import timezone

from trainer.models import TraineeActivitySummary
from trainer.services.export_service import CsvExportResult, _format_date, _safe_str, _sanitize_csv_value
from users.models import User
from workouts.models import DecisionLog, LiftMax, LiftSetLog, WeightCheckIn

if TYPE_CHECKING:
    pass


# ---------------------------------------------------------------------------
# Decision Log Export
# ---------------------------------------------------------------------------

DECISION_LOG_HEADERS = [
    "Timestamp", "Actor Type", "Actor Email", "Decision Type",
    "Context", "Final Choice", "Reason Codes", "Reverted",
]


def export_decision_logs_csv(
    trainer: User,
    days: int = 30,
) -> CsvExportResult:
    """Export DecisionLog entries visible to this trainer as CSV."""
    days = max(1, min(365, days))
    start_date = timezone.now() - timedelta(days=days)

    trainee_subquery = User.objects.filter(
        parent_trainer=trainer,
    ).values('id')

    logs = (
        DecisionLog.objects.filter(
            Q(actor=trainer) | Q(actor_id__in=trainee_subquery),
            timestamp__gte=start_date,
        )
        .select_related('actor', 'undo_snapshot')
        .order_by('-timestamp')
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(DECISION_LOG_HEADERS)

    row_count = 0
    for log in logs:
        is_reverted = (
            log.undo_snapshot is not None
            and log.undo_snapshot.is_reverted
        )
        writer.writerow([
            _format_date(log.timestamp),
            _safe_str(log.actor_type),
            _sanitize_csv_value(log.actor.email if log.actor else 'system'),
            _safe_str(log.decision_type),
            _safe_str(_summarize_json(log.context)),
            _safe_str(_summarize_json(log.final_choice)),
            _safe_str(', '.join(log.reason_codes or [])),
            'Yes' if is_reverted else 'No',
        ])
        row_count += 1

    today = timezone.now().strftime('%Y-%m-%d')
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f'decision_logs_{today}.csv',
        row_count=row_count,
    )


# ---------------------------------------------------------------------------
# Trainee Workout History Export
# ---------------------------------------------------------------------------

WORKOUT_HISTORY_HEADERS = [
    "Date", "Exercise", "Set #", "Entered Load", "Unit",
    "Reps", "RPE", "Canonical Load (kg)", "Workload",
]


def export_trainee_workout_csv(
    trainer: User,
    trainee_id: int,
    days: int = 90,
) -> CsvExportResult:
    """Export a trainee's workout history as CSV."""
    days = max(1, min(365, days))
    trainee = _get_trainee_or_raise(trainer, trainee_id)
    start_date = timezone.now().date() - timedelta(days=days)

    logs = (
        LiftSetLog.objects.filter(
            trainee=trainee,
            session_date__gte=start_date,
        )
        .select_related('exercise')
        .order_by('-session_date', 'exercise__name', 'set_number')
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(WORKOUT_HISTORY_HEADERS)

    row_count = 0
    for log in logs:
        canonical = float(log.canonical_external_load_value or 0)
        reps = log.completed_reps or 0
        workload = round(canonical * reps, 1)
        writer.writerow([
            str(log.session_date),
            _sanitize_csv_value(log.exercise.name),
            log.set_number,
            str(log.entered_load_value),
            log.entered_load_unit,
            reps,
            str(log.rpe) if log.rpe else '',
            f'{canonical:.1f}',
            f'{workload:.1f}',
        ])
        row_count += 1

    today = timezone.now().strftime('%Y-%m-%d')
    trainee_name = _safe_trainee_name(trainee)
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f'workout_history_{trainee_name}_{today}.csv',
        row_count=row_count,
    )


# ---------------------------------------------------------------------------
# Trainee Nutrition History Export
# ---------------------------------------------------------------------------

NUTRITION_HISTORY_HEADERS = [
    "Date", "Logged Food", "Logged Workout",
    "Calories", "Protein (g)", "Carbs (g)", "Fat (g)",
    "Hit Protein Goal", "Hit Calorie Goal",
    "Sleep (hrs)", "Steps", "Total Volume",
]


def export_trainee_nutrition_csv(
    trainer: User,
    trainee_id: int,
    days: int = 90,
) -> CsvExportResult:
    """Export a trainee's nutrition/activity history as CSV."""
    days = max(1, min(365, days))
    trainee = _get_trainee_or_raise(trainer, trainee_id)
    start_date = timezone.now().date() - timedelta(days=days)

    summaries = (
        TraineeActivitySummary.objects.filter(
            trainee=trainee,
            date__gte=start_date,
        )
        .order_by('-date')
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(NUTRITION_HISTORY_HEADERS)

    row_count = 0
    for s in summaries:
        writer.writerow([
            str(s.date),
            'Yes' if s.logged_food else 'No',
            'Yes' if s.logged_workout else 'No',
            s.calories_consumed,
            s.protein_consumed,
            s.carbs_consumed,
            s.fat_consumed,
            'Yes' if s.hit_protein_goal else 'No',
            'Yes' if s.hit_calorie_goal else 'No',
            s.sleep_hours,
            s.steps,
            s.total_volume,
        ])
        row_count += 1

    today = timezone.now().strftime('%Y-%m-%d')
    trainee_name = _safe_trainee_name(trainee)
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f'nutrition_history_{trainee_name}_{today}.csv',
        row_count=row_count,
    )


# ---------------------------------------------------------------------------
# Trainee Progress Export (weight + e1RM)
# ---------------------------------------------------------------------------

PROGRESS_HEADERS = [
    "Date", "Type", "Exercise", "Value", "Unit", "Notes",
]


def export_trainee_progress_csv(
    trainer: User,
    trainee_id: int,
    days: int = 180,
) -> CsvExportResult:
    """Export a trainee's progress data: weight check-ins + e1RM history."""
    days = max(1, min(365, days))
    trainee = _get_trainee_or_raise(trainer, trainee_id)
    start_date = timezone.now().date() - timedelta(days=days)

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(PROGRESS_HEADERS)

    row_count = 0

    # Weight check-ins
    checkins = (
        WeightCheckIn.objects.filter(
            trainee=trainee,
            date__gte=start_date,
        )
        .order_by('-date')
    )
    for wc in checkins:
        writer.writerow([
            str(wc.date),
            'Weight Check-in',
            '',
            str(wc.weight_kg),
            'kg',
            _sanitize_csv_value(wc.notes) if wc.notes else '',
        ])
        row_count += 1

    # e1RM history from LiftMax
    lift_maxes = (
        LiftMax.objects.filter(trainee=trainee)
        .select_related('exercise')
    )
    start_str = str(start_date)
    for lm in lift_maxes:
        history = lm.e1rm_history or []
        for entry in history:
            entry_date = entry.get('date', '')
            if entry_date and entry_date >= start_str:
                writer.writerow([
                    entry_date,
                    'e1RM',
                    _sanitize_csv_value(lm.exercise.name),
                    entry.get('value', ''),
                    'kg',
                    '',
                ])
                row_count += 1

    today = timezone.now().strftime('%Y-%m-%d')
    trainee_name = _safe_trainee_name(trainee)
    return CsvExportResult(
        content=buffer.getvalue(),
        filename=f'progress_{trainee_name}_{today}.csv',
        row_count=row_count,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_trainee_or_raise(trainer: User, trainee_id: int) -> User:
    """Fetch a trainee belonging to this trainer, or raise ValueError."""
    try:
        return User.objects.get(
            pk=trainee_id,
            parent_trainer=trainer,
            role='TRAINEE',
        )
    except User.DoesNotExist:
        raise ValueError('Trainee not found.')


def _safe_trainee_name(trainee: User) -> str:
    """Return a filesystem-safe trainee identifier."""
    name = trainee.get_full_name() or trainee.email.split('@')[0]
    return re.sub(r'[^a-zA-Z0-9_-]', '_', name)[:30]


def _summarize_json(data: dict[str, Any] | list[Any] | None) -> str:
    """Summarize a JSON field into a compact string for CSV."""
    if not data:
        return ''
    if isinstance(data, dict):
        parts = [f'{k}={v}' for k, v in list(data.items())[:5]]
        return '; '.join(parts)
    if isinstance(data, list):
        return f'{len(data)} items'
    return str(data)

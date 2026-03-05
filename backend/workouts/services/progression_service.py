"""
Smart progression suggestion service.
Analyzes workout history to suggest weight/rep/set increases.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

from django.db.models import QuerySet

from workouts.models import DailyLog, Exercise, Program, ProgressionSuggestion

logger = logging.getLogger(__name__)

ANALYSIS_WEEKS = 4
MIN_SESSIONS_FOR_SUGGESTION = 3
WEIGHT_INCREMENT_LBS = 5.0
WEIGHT_INCREMENT_KG = 2.5


@dataclass(frozen=True)
class ExerciseHistory:
    """Aggregated exercise history for progression analysis."""

    exercise_id: int
    exercise_name: str
    sessions: list[dict[str, Any]]
    avg_weight: float
    max_weight: float
    avg_reps: float
    total_sets: int
    trend: str  # 'improving', 'plateau', 'declining'


def _extract_exercise_history(
    logs: QuerySet[DailyLog],
    exercise_id: int,
) -> ExerciseHistory | None:
    """Extract and aggregate history for a single exercise from daily logs."""
    sessions: list[dict[str, Any]] = []

    for log in logs:
        workout_data = log.workout_data
        if not isinstance(workout_data, dict):
            continue

        exercises = workout_data.get("exercises", [])
        if not isinstance(exercises, list):
            continue

        for ex in exercises:
            if not isinstance(ex, dict):
                continue
            if ex.get("exercise_id") != exercise_id:
                continue

            sets = ex.get("sets", [])
            if not isinstance(sets, list) or not sets:
                continue

            completed_sets = [
                s for s in sets
                if isinstance(s, dict) and s.get("completed", True)
            ]
            if not completed_sets:
                continue

            weights = [
                float(s.get("weight", 0))
                for s in completed_sets
                if isinstance(s.get("weight"), (int, float))
            ]
            reps_list = [
                int(s.get("reps", 0))
                for s in completed_sets
                if isinstance(s.get("reps"), (int, float))
            ]

            if weights and reps_list:
                sessions.append({
                    "date": str(log.date),
                    "max_weight": max(weights),
                    "avg_weight": sum(weights) / len(weights),
                    "avg_reps": sum(reps_list) / len(reps_list),
                    "sets": len(completed_sets),
                    "unit": completed_sets[0].get("unit", "lbs"),
                })

    if len(sessions) < MIN_SESSIONS_FOR_SUGGESTION:
        return None

    all_weights = [s["max_weight"] for s in sessions]
    all_reps = [s["avg_reps"] for s in sessions]

    # Determine trend: compare first half to second half
    mid = len(sessions) // 2
    first_half_avg = sum(all_weights[:mid]) / max(mid, 1)
    second_half_avg = sum(all_weights[mid:]) / max(len(all_weights) - mid, 1)

    if second_half_avg > first_half_avg * 1.02:
        trend = "improving"
    elif second_half_avg < first_half_avg * 0.98:
        trend = "declining"
    else:
        trend = "plateau"

    exercise = Exercise.objects.filter(id=exercise_id).first()
    exercise_name = exercise.name if exercise else f"Exercise #{exercise_id}"

    return ExerciseHistory(
        exercise_id=exercise_id,
        exercise_name=exercise_name,
        sessions=sessions,
        avg_weight=round(sum(all_weights) / len(all_weights), 1),
        max_weight=max(all_weights),
        avg_reps=round(sum(all_reps) / len(all_reps), 1),
        total_sets=sum(s["sets"] for s in sessions),
        trend=trend,
    )


def generate_suggestions(program: Program) -> list[ProgressionSuggestion]:
    """
    Analyze a trainee's workout history and generate progression suggestions.

    Args:
        program: The active program to generate suggestions for.

    Returns:
        List of created ProgressionSuggestion objects.
    """
    trainee = program.trainee
    cutoff_date = date.today() - timedelta(weeks=ANALYSIS_WEEKS)

    logs = DailyLog.objects.filter(
        trainee=trainee,
        date__gte=cutoff_date,
    ).order_by("date")

    # Extract unique exercise IDs from the program schedule
    exercise_ids = _get_program_exercise_ids(program)
    if not exercise_ids:
        return []

    suggestions: list[ProgressionSuggestion] = []

    for exercise_id in exercise_ids:
        history = _extract_exercise_history(logs, exercise_id)
        if history is None:
            continue

        suggestion_data = _build_suggestion(history)
        if suggestion_data is None:
            continue

        # Don't create duplicate pending suggestions
        existing = ProgressionSuggestion.objects.filter(
            program=program,
            exercise_id=exercise_id,
            status=ProgressionSuggestion.Status.PENDING,
        ).exists()
        if existing:
            continue

        suggestion = ProgressionSuggestion.objects.create(
            program=program,
            trainee=trainee,
            exercise_id=exercise_id,
            suggestion_data=suggestion_data,
            status=ProgressionSuggestion.Status.PENDING,
        )
        suggestions.append(suggestion)

    return suggestions


def _get_program_exercise_ids(program: Program) -> list[int]:
    """Extract all exercise IDs from a program schedule."""
    exercise_ids: set[int] = set()
    schedule = program.schedule
    if not isinstance(schedule, dict):
        return []

    weeks = schedule.get("weeks", [])
    if not isinstance(weeks, list):
        return []

    for week in weeks:
        if not isinstance(week, dict):
            continue
        days = week.get("days", [])
        if not isinstance(days, list):
            continue
        for day in days:
            if not isinstance(day, dict):
                continue
            exercises = day.get("exercises", [])
            if not isinstance(exercises, list):
                continue
            for ex in exercises:
                if isinstance(ex, dict) and isinstance(ex.get("exercise_id"), int):
                    exercise_ids.add(ex["exercise_id"])

    return list(exercise_ids)


def _build_suggestion(history: ExerciseHistory) -> dict[str, Any] | None:
    """Build a suggestion dict based on exercise history analysis."""
    unit = history.sessions[-1].get("unit", "lbs") if history.sessions else "lbs"
    increment = WEIGHT_INCREMENT_LBS if unit == "lbs" else WEIGHT_INCREMENT_KG

    if history.trend == "improving":
        # Already improving — suggest continuing with small increase
        suggested_weight = round(history.max_weight + increment, 1)
        rationale = (
            f"Consistent improvement over {len(history.sessions)} sessions. "
            f"Average weight progressed from earlier sessions. "
            f"Ready for {increment}{unit} increase."
        )
    elif history.trend == "plateau":
        # Plateau — suggest weight increase or rep increase
        if history.avg_reps >= 10:
            suggested_weight = round(history.max_weight + increment, 1)
            rationale = (
                f"Plateau detected at {history.max_weight}{unit} with "
                f"avg {history.avg_reps:.0f} reps. Rep target exceeded — "
                f"increase weight by {increment}{unit}."
            )
        else:
            # Suggest adding reps instead
            return {
                "current_weight": history.max_weight,
                "suggested_weight": history.max_weight,
                "current_reps": round(history.avg_reps),
                "suggested_reps": round(history.avg_reps) + 2,
                "rationale": (
                    f"Plateau at {history.max_weight}{unit}. "
                    f"Add 2 reps before increasing weight."
                ),
                "confidence": 0.7,
                "unit": unit,
                "type": "reps",
            }
    elif history.trend == "declining":
        # Declining — don't suggest increase
        return None
    else:
        return None

    return {
        "current_weight": history.max_weight,
        "suggested_weight": suggested_weight,
        "current_reps": round(history.avg_reps),
        "suggested_reps": round(history.avg_reps),
        "rationale": rationale,
        "confidence": 0.8 if history.trend == "improving" else 0.6,
        "unit": unit,
        "type": "weight",
    }


def apply_suggestion(suggestion: ProgressionSuggestion, reviewer_id: int) -> None:
    """
    Apply a progression suggestion to the program schedule.

    Args:
        suggestion: The suggestion to apply.
        reviewer_id: The user ID of the person applying it.

    Raises:
        ValueError: If suggestion is not in PENDING or APPROVED status.
    """
    if suggestion.status not in (
        ProgressionSuggestion.Status.PENDING,
        ProgressionSuggestion.Status.APPROVED,
    ):
        raise ValueError(f"Cannot apply suggestion with status {suggestion.status}")

    program = suggestion.program
    schedule = program.schedule
    if not isinstance(schedule, dict):
        raise ValueError("Program has no valid schedule")

    data = suggestion.suggestion_data
    new_weight = data.get("suggested_weight")
    new_reps = data.get("suggested_reps")
    exercise_id = suggestion.exercise_id

    # Update all occurrences of this exercise in the schedule
    weeks = schedule.get("weeks", [])
    for week in weeks:
        if not isinstance(week, dict):
            continue
        for day in week.get("days", []):
            if not isinstance(day, dict):
                continue
            for ex in day.get("exercises", []):
                if not isinstance(ex, dict):
                    continue
                if ex.get("exercise_id") == exercise_id:
                    if new_weight is not None:
                        ex["weight"] = new_weight
                    if new_reps is not None:
                        ex["reps"] = new_reps

    program.schedule = schedule
    program.save(update_fields=["schedule", "updated_at"])

    suggestion.status = ProgressionSuggestion.Status.APPLIED
    suggestion.reviewed_by_id = reviewer_id
    suggestion.save(update_fields=["status", "reviewed_by", "updated_at"])

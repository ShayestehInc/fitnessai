"""
Deload week auto-detection service.
Analyzes training volume and intensity to recommend deload weeks.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

from workouts.models import DailyLog, Program, ProgramWeek

logger = logging.getLogger(__name__)

ANALYSIS_WEEKS = 6
VOLUME_INCREASE_THRESHOLD = 1.15  # 15% volume increase triggers deload check
FATIGUE_INDICATORS = {
    "declining_reps": -0.1,  # 10% rep decline
    "declining_weight": -0.05,  # 5% weight decline
    "poor_recovery": 50,  # recovery score below 50
}


@dataclass(frozen=True)
class DeloadRecommendation:
    """Recommendation for whether a trainee needs a deload week."""

    needs_deload: bool
    confidence: float
    rationale: str
    suggested_intensity_modifier: float
    suggested_volume_modifier: float
    weekly_volume_trend: list[float]
    fatigue_signals: list[str]


def check_deload_needed(program: Program) -> DeloadRecommendation:
    """
    Analyze a trainee's recent training data to determine if a deload is needed.

    Args:
        program: The active program to analyze.

    Returns:
        DeloadRecommendation with analysis results.
    """
    trainee = program.trainee
    today = date.today()
    start_date = today - timedelta(weeks=ANALYSIS_WEEKS)

    logs = list(
        DailyLog.objects.filter(
            trainee=trainee,
            date__gte=start_date,
            date__lte=today,
        ).order_by("date")
    )

    if len(logs) < 6:
        return DeloadRecommendation(
            needs_deload=False,
            confidence=0.3,
            rationale="Insufficient training data for deload analysis (need at least 6 sessions).",
            suggested_intensity_modifier=1.0,
            suggested_volume_modifier=1.0,
            weekly_volume_trend=[],
            fatigue_signals=[],
        )

    # Calculate weekly volume
    weekly_volumes = _calculate_weekly_volumes(logs, start_date, today)
    fatigue_signals = _detect_fatigue_signals(logs)

    # Determine if deload is needed
    needs_deload = False
    confidence = 0.5
    rationale_parts: list[str] = []

    # Check sustained volume increase
    if len(weekly_volumes) >= 4:
        recent_avg = sum(weekly_volumes[-2:]) / 2
        earlier_avg = sum(weekly_volumes[:2]) / max(len(weekly_volumes[:2]), 1)
        if earlier_avg > 0 and recent_avg / earlier_avg > VOLUME_INCREASE_THRESHOLD:
            needs_deload = True
            confidence += 0.2
            rationale_parts.append(
                f"Training volume increased {((recent_avg / earlier_avg - 1) * 100):.0f}% "
                f"over the past {ANALYSIS_WEEKS} weeks."
            )

    # Check fatigue signals
    if len(fatigue_signals) >= 2:
        needs_deload = True
        confidence += 0.15
        rationale_parts.append(
            f"Detected {len(fatigue_signals)} fatigue signal(s): {', '.join(fatigue_signals)}."
        )

    # Check consecutive weeks without deload
    last_deload = ProgramWeek.objects.filter(
        program=program,
        is_deload=True,
    ).order_by("-week_number").first()

    current_week = _get_current_week_number(program)
    weeks_since_deload = (
        current_week - last_deload.week_number if last_deload else current_week
    )
    if weeks_since_deload >= 5:
        needs_deload = True
        confidence += 0.1
        rationale_parts.append(
            f"{weeks_since_deload} weeks since last deload (recommended every 4-5 weeks)."
        )

    if not needs_deload:
        rationale_parts.append("Training load is manageable. No deload needed at this time.")

    return DeloadRecommendation(
        needs_deload=needs_deload,
        confidence=min(confidence, 0.95),
        rationale=" ".join(rationale_parts),
        suggested_intensity_modifier=0.6 if needs_deload else 1.0,
        suggested_volume_modifier=0.5 if needs_deload else 1.0,
        weekly_volume_trend=weekly_volumes,
        fatigue_signals=fatigue_signals,
    )


def apply_deload(program: Program, week_number: int) -> ProgramWeek:
    """
    Apply deload settings to a specific week of a program.

    Args:
        program: The program to modify.
        week_number: The week number to set as deload.

    Returns:
        The created/updated ProgramWeek.

    Raises:
        ValueError: If week_number is invalid.
    """
    if week_number < 1:
        raise ValueError("Week number must be positive")

    week, _ = ProgramWeek.objects.update_or_create(
        program=program,
        week_number=week_number,
        defaults={
            "is_deload": True,
            "intensity_modifier": 0.6,
            "volume_modifier": 0.5,
            "notes": "Auto-detected deload week. Reduced intensity and volume for recovery.",
        },
    )
    return week


def _calculate_weekly_volumes(
    logs: list[DailyLog],
    start_date: date,
    end_date: date,
) -> list[float]:
    """Calculate total training volume per week."""
    weekly_volumes: list[float] = []
    current_week_start = start_date

    while current_week_start <= end_date:
        week_end = current_week_start + timedelta(days=6)
        week_volume = 0.0

        for log in logs:
            if current_week_start <= log.date <= week_end:
                week_volume += _calculate_log_volume(log)

        weekly_volumes.append(round(week_volume, 1))
        current_week_start = week_end + timedelta(days=1)

    return weekly_volumes


def _calculate_log_volume(log: DailyLog) -> float:
    """Calculate total volume (weight * reps * sets) from a daily log."""
    workout_data = log.workout_data
    if not isinstance(workout_data, dict):
        return 0.0

    exercises = workout_data.get("exercises", [])
    if not isinstance(exercises, list):
        return 0.0

    total = 0.0
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        sets = ex.get("sets", [])
        if not isinstance(sets, list):
            continue
        for s in sets:
            if not isinstance(s, dict) or not s.get("completed", True):
                continue
            weight = s.get("weight", 0)
            reps = s.get("reps", 0)
            if isinstance(weight, (int, float)) and isinstance(reps, (int, float)):
                total += weight * reps

    return total


def _detect_fatigue_signals(logs: list[DailyLog]) -> list[str]:
    """Detect fatigue indicators from training data."""
    signals: list[str] = []

    # Check recovery scores
    recovery_scores = [
        log.recovery_score
        for log in logs
        if log.recovery_score is not None
    ]
    if recovery_scores:
        recent_recovery = recovery_scores[-3:] if len(recovery_scores) >= 3 else recovery_scores
        avg_recent = sum(recent_recovery) / len(recent_recovery)
        if avg_recent < FATIGUE_INDICATORS["poor_recovery"]:
            signals.append(f"low recovery scores (avg {avg_recent:.0f}/100)")

    # Check sleep
    sleep_data = [log.sleep_hours for log in logs if log.sleep_hours > 0]
    if len(sleep_data) >= 5:
        recent_sleep = sleep_data[-5:]
        avg_sleep = sum(recent_sleep) / len(recent_sleep)
        if avg_sleep < 6.0:
            signals.append(f"poor sleep quality (avg {avg_sleep:.1f}h)")

    return signals


def _get_current_week_number(program: Program) -> int:
    """Calculate the current week number based on program start date."""
    if not program.start_date:
        return 1
    days_elapsed = (date.today() - program.start_date).days
    return max(1, (days_elapsed // 7) + 1)

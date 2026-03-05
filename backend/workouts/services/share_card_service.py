"""
Workout share card service.
Generates structured data for workout sharing cards.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from workouts.models import DailyLog


@dataclass(frozen=True)
class ShareCardData:
    """Structured data for rendering a workout share card."""

    workout_name: str
    date: str
    exercise_count: int
    total_sets: int
    total_volume: float
    volume_unit: str
    duration: str
    exercises: list[dict[str, Any]]
    trainee_name: str
    trainer_branding: dict[str, Any]


def generate_share_card(daily_log: DailyLog) -> ShareCardData:
    """
    Generate share card data from a DailyLog entry.

    Args:
        daily_log: The workout log to create a share card for.

    Returns:
        ShareCardData with all fields needed for mobile rendering.

    Raises:
        ValueError: If the daily log has no workout data.
    """
    workout_data = daily_log.workout_data
    if not isinstance(workout_data, dict) or not workout_data:
        raise ValueError("Daily log has no workout data to share")

    exercises_raw = workout_data.get("exercises", [])
    if not isinstance(exercises_raw, list):
        exercises_raw = []

    exercise_summaries: list[dict[str, Any]] = []
    total_sets = 0
    total_volume = 0.0
    volume_unit = "lbs"

    for ex in exercises_raw:
        if not isinstance(ex, dict):
            continue
        sets = ex.get("sets", [])
        if not isinstance(sets, list):
            continue

        completed_sets = [s for s in sets if isinstance(s, dict) and s.get("completed", True)]
        set_count = len(completed_sets)
        total_sets += set_count

        best_weight = 0.0
        best_reps = 0
        ex_volume = 0.0
        for s in completed_sets:
            weight = float(s.get("weight", 0))
            reps = int(s.get("reps", 0))
            if weight > best_weight:
                best_weight = weight
                best_reps = reps
            ex_volume += weight * reps
            if s.get("unit"):
                volume_unit = s["unit"]

        total_volume += ex_volume
        exercise_summaries.append({
            "name": ex.get("exercise_name", "Unknown"),
            "sets": set_count,
            "best_set": f"{best_weight:.0f}{volume_unit} x {best_reps}" if best_weight > 0 else None,
            "volume": round(ex_volume, 1),
        })

    trainee = daily_log.trainee
    trainee_name = f"{trainee.first_name or ''} {trainee.last_name or ''}".strip()
    if not trainee_name:
        trainee_name = trainee.email.split("@")[0]

    # Get trainer branding if available
    branding: dict[str, Any] = {}
    if hasattr(trainee, "parent_trainer") and trainee.parent_trainer:
        trainer = trainee.parent_trainer
        if hasattr(trainer, "branding"):
            brand = trainer.branding
            branding = {
                "business_name": getattr(brand, "business_name", ""),
                "primary_color": getattr(brand, "primary_color", "#000000"),
                "logo_url": getattr(brand, "logo_url", None),
            }

    return ShareCardData(
        workout_name=workout_data.get("workout_name", "Workout"),
        date=str(daily_log.date),
        exercise_count=len(exercise_summaries),
        total_sets=total_sets,
        total_volume=round(total_volume, 1),
        volume_unit=volume_unit,
        duration=workout_data.get("duration", "0:00"),
        exercises=exercise_summaries,
        trainee_name=trainee_name,
        trainer_branding=branding,
    )

"""
Habit tracking service.
Provides streak calculation and completion rate analytics.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta

from django.db.models import Count, Q

from workouts.models import Habit, HabitLog

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class HabitStreak:
    """Streak data for a single habit."""

    habit_id: int
    habit_name: str
    current_streak: int
    longest_streak: int
    completion_rate_30d: float


def calculate_streak(habit: Habit, as_of: date | None = None) -> HabitStreak:
    """
    Calculate the current and longest streak for a habit.

    Args:
        habit: The habit to analyze.
        as_of: Date to calculate streak as of (defaults to today).

    Returns:
        HabitStreak with current/longest streaks and 30-day completion rate.
    """
    target_date = as_of or date.today()

    logs = list(
        HabitLog.objects.filter(
            habit=habit,
            completed=True,
        )
        .values_list("date", flat=True)
        .order_by("-date")
    )
    completed_dates = set(logs)

    # Calculate current streak (consecutive days ending at target_date)
    current_streak = 0
    check_date = target_date
    while check_date in completed_dates:
        current_streak += 1
        check_date -= timedelta(days=1)

    # Calculate longest streak
    longest_streak = 0
    if completed_dates:
        sorted_dates = sorted(completed_dates)
        streak = 1
        for i in range(1, len(sorted_dates)):
            if sorted_dates[i] - sorted_dates[i - 1] == timedelta(days=1):
                streak += 1
            else:
                longest_streak = max(longest_streak, streak)
                streak = 1
        longest_streak = max(longest_streak, streak)

    # 30-day completion rate
    thirty_days_ago = target_date - timedelta(days=30)
    completed_in_30d = HabitLog.objects.filter(
        habit=habit,
        completed=True,
        date__gte=thirty_days_ago,
        date__lte=target_date,
    ).count()
    completion_rate = round(completed_in_30d / 30.0, 2)

    return HabitStreak(
        habit_id=habit.id,
        habit_name=habit.name,
        current_streak=current_streak,
        longest_streak=longest_streak,
        completion_rate_30d=completion_rate,
    )


def get_daily_habits(trainee_id: int, target_date: date | None = None) -> list[dict[str, object]]:
    """
    Get all active habits for a trainee with their completion status for a given date.

    Args:
        trainee_id: The trainee's user ID.
        target_date: The date to check (defaults to today).

    Returns:
        List of habit dicts with completion status.
    """
    target = target_date or date.today()
    day_name = target.strftime("%A")

    habits = Habit.objects.filter(
        trainee_id=trainee_id,
        is_active=True,
    ).select_related("trainer")

    result: list[dict[str, object]] = []
    for habit in habits:
        # Check if this habit applies to the given day
        if habit.frequency == Habit.Frequency.WEEKDAYS and day_name in ("Saturday", "Sunday"):
            continue
        if habit.frequency == Habit.Frequency.CUSTOM and day_name not in habit.custom_days:
            continue

        log = HabitLog.objects.filter(habit=habit, date=target).first()
        result.append({
            "habit_id": habit.id,
            "name": habit.name,
            "description": habit.description,
            "icon": habit.icon,
            "completed": log.completed if log else False,
        })

    return result


def get_completion_rate(trainee_id: int, days: int = 30) -> float:
    """
    Calculate overall habit completion rate for a trainee.

    Args:
        trainee_id: The trainee's user ID.
        days: Number of days to look back.

    Returns:
        Completion rate as a float (0.0 to 1.0).
    """
    target_date = date.today()
    start_date = target_date - timedelta(days=days)

    active_habits = Habit.objects.filter(
        trainee_id=trainee_id,
        is_active=True,
    ).count()

    if active_habits == 0:
        return 0.0

    completed = HabitLog.objects.filter(
        trainee_id=trainee_id,
        completed=True,
        date__gte=start_date,
        date__lte=target_date,
    ).count()

    expected = active_habits * days
    return round(completed / expected, 2) if expected > 0 else 0.0

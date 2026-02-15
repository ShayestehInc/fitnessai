"""
Service layer for DailyLog business logic.

Handles weekly progress calculation, meal entry editing/deleting,
and nutrition totals recalculation.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

from django.db.models import Q, QuerySet

from workouts.models import DailyLog, Program


@dataclass(frozen=True)
class WeeklyProgress:
    """Result of weekly progress calculation."""
    total_days: int
    completed_days: int
    percentage: int
    week_start: date
    week_end: date
    has_program: bool


class DailyLogService:
    """Business logic for daily log operations."""

    @staticmethod
    def get_weekly_progress(trainee_id: int) -> WeeklyProgress:
        """
        Calculate weekly workout progress for a trainee (Mon-Sun).

        A "completed day" is any day with non-empty workout_data.
        Total days comes from the active program schedule.
        """
        today = date.today()
        monday = today - timedelta(days=today.weekday())
        sunday = monday + timedelta(days=6)

        active_program = Program.objects.filter(
            trainee_id=trainee_id,
            is_active=True,
        ).first()

        if active_program is None:
            return WeeklyProgress(
                total_days=0,
                completed_days=0,
                percentage=0,
                week_start=monday,
                week_end=sunday,
                has_program=False,
            )

        total_days = DailyLogService._count_weekly_workout_days(active_program)

        completed_days: int = (
            DailyLog.objects.filter(
                trainee_id=trainee_id,
                date__range=(monday, sunday),
            )
            .exclude(workout_data={})
            .exclude(workout_data__isnull=True)
            .count()
        )

        percentage = round((completed_days / total_days) * 100) if total_days > 0 else 0

        return WeeklyProgress(
            total_days=total_days,
            completed_days=completed_days,
            percentage=min(percentage, 100),
            week_start=monday,
            week_end=sunday,
            has_program=True,
        )

    @staticmethod
    def _count_weekly_workout_days(program: Program) -> int:
        """Count non-rest workout days per week from program schedule."""
        schedule = program.schedule
        if not schedule:
            return 0

        weeks: list[Any] = []
        if isinstance(schedule, list) and schedule:
            weeks = schedule
        elif isinstance(schedule, dict):
            if 'weeks' in schedule and isinstance(schedule['weeks'], list):
                weeks = schedule['weeks']

        if not weeks:
            return 0

        first_week = weeks[0]
        if not isinstance(first_week, dict):
            return 0

        days = first_week.get('days', [])
        if not isinstance(days, list):
            return 0

        workout_days = 0
        for day in days:
            if not isinstance(day, dict):
                continue
            is_rest = day.get('is_rest_day', False)
            day_name = day.get('name', '')
            is_rest_by_name = isinstance(day_name, str) and 'rest' in day_name.lower()
            if not is_rest and not is_rest_by_name:
                workout_days += 1

        return workout_days

    @staticmethod
    def get_workout_history_queryset(trainee_id: int) -> QuerySet[DailyLog]:
        """
        Build a filtered, ordered queryset of DailyLogs that contain actual
        workout data for the given trainee.

        Excludes logs where workout_data is null, empty dict, or has an empty
        exercises list. Includes logs that use either the 'exercises' or
        'sessions' key format. Defers nutrition_data since it is not needed
        for history summaries.

        Returns the queryset ordered newest-first.
        """
        return (
            DailyLog.objects.filter(trainee_id=trainee_id)
            .exclude(workout_data__isnull=True)
            .exclude(workout_data={})
            .filter(
                Q(workout_data__has_key='exercises')
                | Q(workout_data__has_key='sessions'),
            )
            .exclude(
                # Only exclude empty exercises for records that actually have
                # the key. Records with only 'sessions' must NOT be excluded.
                Q(workout_data__has_key='exercises')
                & Q(workout_data__exercises=[]),
            )
            .defer('nutrition_data')
            .order_by('-date')
        )

    @staticmethod
    def edit_meal_entry(
        daily_log: DailyLog,
        entry_index: int,
        data: dict[str, Any],
    ) -> DailyLog:
        """
        Edit a food entry in a DailyLog's nutrition_data by flat index.

        Raises ValueError if the entry_index is out of bounds.
        Returns the updated DailyLog.
        """
        nutrition_data: dict[str, Any] = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        if entry_index < 0 or entry_index >= len(meals):
            raise ValueError(f"Invalid entry_index {entry_index}: out of range (0-{len(meals) - 1})")

        existing_entry = meals[entry_index]
        if isinstance(existing_entry, dict):
            existing_entry.update(data)
        else:
            meals[entry_index] = data

        nutrition_data['totals'] = DailyLogService.recalculate_nutrition_totals(meals)
        daily_log.nutrition_data = nutrition_data
        daily_log.save(update_fields=['nutrition_data', 'updated_at'])
        return daily_log

    @staticmethod
    def delete_meal_entry(
        daily_log: DailyLog,
        entry_index: int,
    ) -> DailyLog:
        """
        Delete a food entry from a DailyLog's nutrition_data by flat index.

        Raises ValueError if the entry_index is out of bounds.
        Returns the updated DailyLog.
        """
        nutrition_data: dict[str, Any] = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        if entry_index < 0 or entry_index >= len(meals):
            raise ValueError(f"Invalid entry_index {entry_index}: out of range (0-{len(meals) - 1})")

        meals.pop(entry_index)

        nutrition_data['totals'] = DailyLogService.recalculate_nutrition_totals(meals)
        daily_log.nutrition_data = nutrition_data
        daily_log.save(update_fields=['nutrition_data', 'updated_at'])
        return daily_log

    @staticmethod
    def recalculate_nutrition_totals(meals: list[dict[str, Any]]) -> dict[str, int]:
        """Recalculate nutrition totals from a list of meal entries."""
        return {
            'protein': sum(
                m.get('protein', 0) for m in meals if isinstance(m, dict)
            ),
            'carbs': sum(
                m.get('carbs', 0) for m in meals if isinstance(m, dict)
            ),
            'fat': sum(
                m.get('fat', 0) for m in meals if isinstance(m, dict)
            ),
            'calories': sum(
                m.get('calories', 0) for m in meals if isinstance(m, dict)
            ),
        }

"""
Achievement checking and awarding service.

Called after workout completion, weight check-in, nutrition logging,
and program completion. Failures are caught and never block the parent operation.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import TYPE_CHECKING

from django.db import IntegrityError
from django.db.models import Q
from django.utils import timezone

from community.models import Achievement, UserAchievement

if TYPE_CHECKING:
    from users.models import User

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class AwardedAchievement:
    """Returned to the caller so the API response can include new_achievements."""
    user_achievement_id: int
    achievement_id: int
    name: str
    description: str
    icon_name: str
    earned_at: str  # ISO 8601


def check_and_award_achievements(
    user: User,
    trigger: str,
) -> list[UserAchievement]:
    """
    Check whether *user* qualifies for any unearned achievements based on *trigger*.

    Parameters
    ----------
    user : User
        The trainee whose activity was just recorded.
    trigger : str
        One of: ``workout_completed``, ``weight_checkin``,
        ``nutrition_logged``, ``program_completed``.

    Returns
    -------
    list[UserAchievement]
        Newly earned UserAchievement rows (empty if nothing new).
    """
    try:
        return _check_and_award(user, trigger)
    except Exception:
        logger.exception(
            "Achievement check failed for user %s trigger %s",
            user.id, trigger,
        )
        return []


# ---------------------------------------------------------------------------
# Internal implementation
# ---------------------------------------------------------------------------

_TRIGGER_TO_CRITERIA: dict[str, list[str]] = {
    'workout_completed': [
        Achievement.CriteriaType.WORKOUT_COUNT,
        Achievement.CriteriaType.WORKOUT_STREAK,
    ],
    'weight_checkin': [
        Achievement.CriteriaType.WEIGHT_CHECKIN_STREAK,
    ],
    'nutrition_logged': [
        Achievement.CriteriaType.NUTRITION_STREAK,
    ],
    'program_completed': [
        Achievement.CriteriaType.PROGRAM_COMPLETED,
    ],
}


def _check_and_award(user: User, trigger: str) -> list[UserAchievement]:
    criteria_types = _TRIGGER_TO_CRITERIA.get(trigger)
    if not criteria_types:
        return []

    # Achievements the user has NOT yet earned for the relevant criteria types
    earned_ids = set(
        UserAchievement.objects.filter(user=user)
        .values_list('achievement_id', flat=True)
    )
    candidates = Achievement.objects.filter(
        criteria_type__in=criteria_types,
    ).exclude(id__in=earned_ids)

    if not candidates.exists():
        return []

    # Pre-compute the user's current stats for each criteria type
    stats: dict[str, int] = {}
    for ct in criteria_types:
        stats[ct] = _compute_stat(user, ct)

    newly_earned: list[UserAchievement] = []
    for achievement in candidates:
        required = achievement.criteria_value
        current = stats.get(achievement.criteria_type, 0)
        if current >= required:
            ua = _try_award(user, achievement)
            if ua is not None:
                newly_earned.append(ua)

    return newly_earned


def _try_award(user: User, achievement: Achievement) -> UserAchievement | None:
    """Attempt to create a UserAchievement, handling concurrent calls gracefully."""
    try:
        ua, created = UserAchievement.objects.get_or_create(
            user=user,
            achievement=achievement,
        )
        return ua if created else None
    except IntegrityError:
        # Race condition: another request already inserted this row.
        return None


def _compute_stat(user: User, criteria_type: str) -> int:
    """Return the current count/streak for a given criteria type."""
    from workouts.models import DailyLog, WeightCheckIn

    if criteria_type == Achievement.CriteriaType.WORKOUT_COUNT:
        return _workout_count(user)
    elif criteria_type == Achievement.CriteriaType.WORKOUT_STREAK:
        return _workout_streak(user)
    elif criteria_type == Achievement.CriteriaType.WEIGHT_CHECKIN_STREAK:
        return _weight_checkin_streak(user)
    elif criteria_type == Achievement.CriteriaType.NUTRITION_STREAK:
        return _nutrition_streak(user)
    elif criteria_type == Achievement.CriteriaType.PROGRAM_COMPLETED:
        return _programs_completed(user)
    return 0


def _workout_count(user: User) -> int:
    """Total distinct dates with non-empty workout_data."""
    from workouts.models import DailyLog

    return (
        DailyLog.objects.filter(trainee=user)
        .exclude(workout_data={})
        .exclude(workout_data__isnull=True)
        .values('date')
        .distinct()
        .count()
    )


def _workout_streak(user: User) -> int:
    """Consecutive calendar days (ending today or yesterday) with workout_data."""
    from workouts.models import DailyLog

    dates = set(
        DailyLog.objects.filter(trainee=user)
        .exclude(workout_data={})
        .exclude(workout_data__isnull=True)
        .values_list('date', flat=True)
    )
    return _consecutive_days(dates)


def _weight_checkin_streak(user: User) -> int:
    """Consecutive calendar days with weight check-ins."""
    from workouts.models import WeightCheckIn

    dates = set(
        WeightCheckIn.objects.filter(trainee=user)
        .values_list('date', flat=True)
    )
    return _consecutive_days(dates)


def _nutrition_streak(user: User) -> int:
    """Consecutive calendar days with non-empty nutrition_data."""
    from workouts.models import DailyLog

    dates = set(
        DailyLog.objects.filter(trainee=user)
        .exclude(nutrition_data={})
        .exclude(nutrition_data__isnull=True)
        .values_list('date', flat=True)
    )
    return _consecutive_days(dates)


def _programs_completed(user: User) -> int:
    """Number of programs that have ended (end_date <= today)."""
    from workouts.models import Program

    today = timezone.now().date()
    return Program.objects.filter(
        trainee=user,
        end_date__lte=today,
    ).count()


def _consecutive_days(dates: set[date]) -> int:
    """
    Compute the current streak of consecutive calendar days ending on today
    or yesterday. A gap of 1+ days resets the streak.
    """
    if not dates:
        return 0

    today = timezone.now().date()
    # Streak can start from today or yesterday (if today's entry hasn't happened yet)
    current = today
    if current not in dates:
        current = today - timedelta(days=1)
        if current not in dates:
            return 0

    streak = 0
    while current in dates:
        streak += 1
        current -= timedelta(days=1)

    return streak

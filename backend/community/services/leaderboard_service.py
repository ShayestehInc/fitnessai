"""
Leaderboard computation service.

Computes ranked entries for trainer-scoped leaderboards from DailyLog aggregates.
Supports workout_count and current_streak metrics over weekly or monthly periods.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Sequence

from django.db.models import Count, Q
from django.utils import timezone

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class LeaderboardEntry:
    """A single row on the leaderboard."""
    rank: int
    user_id: int
    first_name: str
    last_name: str
    profile_image: str | None
    value: int


def compute_leaderboard(
    trainer_id: int,
    metric_type: str,
    time_period: str,
    *,
    limit: int = 25,
) -> list[LeaderboardEntry]:
    """
    Compute leaderboard entries for a trainer's group.

    Only includes trainees who have leaderboard_opt_in=True.

    Parameters
    ----------
    trainer_id : int
        The trainer's user id.
    metric_type : str
        One of 'workout_count' or 'current_streak'.
    time_period : str
        One of 'weekly' or 'monthly'.
    limit : int
        Max entries to return (default 25).

    Returns
    -------
    list[LeaderboardEntry]
        Ranked entries, highest value first.
    """
    from users.models import User

    # Get opted-in trainees for this trainer
    trainees = list(
        User.objects.filter(
            parent_trainer_id=trainer_id,
            role=User.Role.TRAINEE,
            is_active=True,
            profile__leaderboard_opt_in=True,
        ).select_related('profile').only(
            'id', 'first_name', 'last_name', 'profile_image',
        )
    )

    if not trainees:
        return []

    trainee_ids = [t.id for t in trainees]
    start_date = _period_start(time_period)

    if metric_type == 'workout_count':
        values = _compute_workout_counts(trainee_ids, start_date)
    elif metric_type == 'current_streak':
        values = _compute_current_streaks(trainee_ids)
    else:
        logger.warning("Unknown metric_type: %s", metric_type)
        return []

    # Build entries with trainee info
    trainee_map = {t.id: t for t in trainees}
    raw_entries: list[tuple[int, int]] = []
    for uid in trainee_ids:
        val = values.get(uid, 0)
        if val > 0:
            raw_entries.append((uid, val))

    # Sort descending by value, then by user_id for deterministic ordering
    raw_entries.sort(key=lambda e: (-e[1], e[0]))
    raw_entries = raw_entries[:limit]

    # Assign ranks with dense ranking (ties get same rank, next rank skips)
    entries: list[LeaderboardEntry] = []
    current_rank = 0
    prev_value: int | None = None
    for idx, (uid, val) in enumerate(raw_entries):
        if val != prev_value:
            current_rank = idx + 1
            prev_value = val
        user = trainee_map[uid]
        entries.append(LeaderboardEntry(
            rank=current_rank,
            user_id=uid,
            first_name=user.first_name,
            last_name=user.last_name,
            profile_image=str(user.profile_image) if user.profile_image else None,
            value=val,
        ))

    return entries


def _period_start(time_period: str) -> date:
    """Return the start date for the given time period."""
    today = timezone.now().date()
    if time_period == 'weekly':
        # Start from Monday of current week
        return today - timedelta(days=today.weekday())
    elif time_period == 'monthly':
        return today.replace(day=1)
    # Fallback to 30 days ago
    return today - timedelta(days=30)


def _compute_workout_counts(
    trainee_ids: Sequence[int],
    start_date: date,
) -> dict[int, int]:
    """Count distinct workout dates per trainee since start_date."""
    from workouts.models import DailyLog

    rows = (
        DailyLog.objects.filter(
            trainee_id__in=trainee_ids,
            date__gte=start_date,
        )
        .exclude(workout_data={})
        .exclude(workout_data__isnull=True)
        .values('trainee_id')
        .annotate(count=Count('date', distinct=True))
    )
    return {row['trainee_id']: row['count'] for row in rows}


def _compute_current_streaks(
    trainee_ids: Sequence[int],
) -> dict[int, int]:
    """Compute current consecutive-day workout streak for each trainee."""
    from workouts.models import DailyLog

    # Fetch all workout dates per trainee (only recent ones for performance)
    cutoff = timezone.now().date() - timedelta(days=90)
    logs = (
        DailyLog.objects.filter(
            trainee_id__in=trainee_ids,
            date__gte=cutoff,
        )
        .exclude(workout_data={})
        .exclude(workout_data__isnull=True)
        .values_list('trainee_id', 'date')
    )

    # Group dates by trainee
    trainee_dates: dict[int, set[date]] = {}
    for uid, log_date in logs:
        trainee_dates.setdefault(uid, set()).add(log_date)

    result: dict[int, int] = {}
    today = timezone.now().date()
    for uid in trainee_ids:
        dates = trainee_dates.get(uid, set())
        result[uid] = _consecutive_days_streak(dates, today)

    return result


def _consecutive_days_streak(dates: set[date], today: date) -> int:
    """Compute streak of consecutive days ending today or yesterday."""
    if not dates:
        return 0

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

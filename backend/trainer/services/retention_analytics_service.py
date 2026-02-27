"""
Service for computing trainee engagement and churn risk analytics.

Calculates a per-trainee engagement score (0-100) and churn risk score (0-100)
over a configurable rolling window, using data from TraineeActivitySummary.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import TYPE_CHECKING

from django.utils import timezone

if TYPE_CHECKING:
    from users.models import User


# ── Risk tier thresholds ──

CRITICAL_THRESHOLD: int = 75
HIGH_THRESHOLD: int = 50
MEDIUM_THRESHOLD: int = 25


def _risk_tier(score: float) -> str:
    if score >= CRITICAL_THRESHOLD:
        return "critical"
    if score >= HIGH_THRESHOLD:
        return "high"
    if score >= MEDIUM_THRESHOLD:
        return "medium"
    return "low"


def _clamp(value: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return max(lo, min(hi, value))


# ── Dataclasses ──


@dataclass(frozen=True)
class TraineeEngagementItem:
    trainee_id: int
    trainee_email: str
    trainee_name: str
    engagement_score: float
    churn_risk_score: float
    risk_tier: str
    days_since_last_activity: int | None
    workout_consistency: float
    nutrition_consistency: float
    last_active_date: str | None


@dataclass(frozen=True)
class RetentionSummary:
    total_trainees: int
    at_risk_count: int
    critical_count: int
    high_count: int
    medium_count: int
    low_count: int
    avg_engagement: float
    retention_rate: float


@dataclass(frozen=True)
class RetentionTrendPoint:
    date: str
    avg_engagement: float
    at_risk_count: int
    total_trainees: int


@dataclass(frozen=True)
class RetentionAnalyticsResult:
    period_days: int
    summary: RetentionSummary
    trainees: list[TraineeEngagementItem]
    trends: list[RetentionTrendPoint]


# ── Scoring helpers ──


def _recency_score(days_inactive: int) -> float:
    """Exponential-style decay: today=100, 1d=85, 2d=65, 3d=45, 5d+=near 0."""
    if days_inactive <= 0:
        return 100.0
    if days_inactive == 1:
        return 85.0
    if days_inactive == 2:
        return 65.0
    if days_inactive == 3:
        return 45.0
    return max(0.0, 100.0 - days_inactive * 20.0)


def _inactivity_signal(days_inactive: int) -> float:
    """Convert days inactive to a 0-100 signal for churn risk."""
    if days_inactive <= 1:
        return 0.0
    if days_inactive == 2:
        return 20.0
    if days_inactive == 3:
        return 40.0
    if days_inactive == 4:
        return 60.0
    if days_inactive == 5:
        return 80.0
    return 100.0


def _compute_scores(
    *,
    days_logged_workout: int,
    days_logged_food: int,
    days_hit_protein: int,
    days_hit_calorie: int,
    lookback_days: int,
    days_since_last_activity: int,
    first_half_engagement: float,
    second_half_engagement: float,
    current_volume: int,
    previous_volume: int,
    is_new_trainee: bool,
) -> tuple[float, float]:
    """Return (engagement_score, churn_risk_score), both 0-100."""
    safe_lookback = max(lookback_days, 1)

    workout_consistency = (days_logged_workout / safe_lookback) * 100.0
    nutrition_consistency = (days_logged_food / safe_lookback) * 100.0
    goal_adherence = (
        (days_hit_protein + days_hit_calorie) / (2.0 * safe_lookback) * 100.0
    )
    recency = _recency_score(days_since_last_activity)

    engagement = (
        workout_consistency * 0.30
        + nutrition_consistency * 0.25
        + goal_adherence * 0.25
        + recency * 0.20
    )
    engagement = _clamp(engagement)

    # ── Churn risk ──
    inactivity = _inactivity_signal(days_since_last_activity)

    # Declining trend: compare first half vs second half of window
    if first_half_engagement > 0:
        decline_pct = max(0.0, (first_half_engagement - second_half_engagement) / first_half_engagement)
    else:
        decline_pct = 0.0
    declining_trend = decline_pct * 100.0

    # Low volume signal: compare current window vs previous equivalent window
    if previous_volume > 0:
        vol_drop_pct = max(0.0, (previous_volume - current_volume) / previous_volume)
    else:
        vol_drop_pct = 0.0
    low_volume = vol_drop_pct * 100.0

    churn_risk = _clamp(
        (100.0 - engagement) * 0.40
        + inactivity * 0.30
        + declining_trend * 0.20
        + low_volume * 0.10
    )

    # New trainee guard: cap risk at Medium (50) if truly new with zero activity
    if is_new_trainee:
        churn_risk = min(churn_risk, 50.0)

    return round(engagement, 1), round(churn_risk, 1)


# ── Main service function ──


def get_retention_analytics(
    trainer: User,
    days: int,
) -> RetentionAnalyticsResult:
    """
    Compute retention analytics for all active trainees of a trainer.

    Args:
        trainer: The authenticated trainer user.
        days: Lookback window in days (clamped to 3-365 by caller).

    Returns:
        Frozen dataclass with summary, per-trainee engagement/risk, and daily trends.
    """
    from trainer.models import TraineeActivitySummary
    from users.models import User as UserModel

    now = timezone.now()
    today = now.date()
    lookback_days = max(days, 3)
    start_date = today - timedelta(days=lookback_days)
    prev_start = start_date - timedelta(days=lookback_days)
    half_point = today - timedelta(days=lookback_days // 2)

    # ── Fetch trainees with aggregated activity data ──
    trainees_qs = (
        UserModel.objects.filter(
            parent_trainer=trainer,
            role=UserModel.Role.TRAINEE,
            is_active=True,
        )
        .select_related('profile')
        .order_by('id')
    )

    trainee_list = list(trainees_qs[:100])
    if not trainee_list:
        return RetentionAnalyticsResult(
            period_days=lookback_days,
            summary=RetentionSummary(
                total_trainees=0,
                at_risk_count=0,
                critical_count=0,
                high_count=0,
                medium_count=0,
                low_count=0,
                avg_engagement=0.0,
                retention_rate=100.0,
            ),
            trainees=[],
            trends=[],
        )

    trainee_ids = [t.id for t in trainee_list]

    # ── Bulk fetch activity summaries for the window + previous window ──
    summaries = list(
        TraineeActivitySummary.objects.filter(
            trainee_id__in=trainee_ids,
            date__gte=prev_start,
        )
        .values(
            'trainee_id',
            'date',
            'logged_workout',
            'logged_food',
            'hit_protein_goal',
            'hit_calorie_goal',
            'workouts_completed',
        )
        .order_by('trainee_id', 'date')
    )

    # ── Index summaries by trainee ──
    summaries_by_trainee: dict[int, list[dict]] = {}
    for s in summaries:
        summaries_by_trainee.setdefault(s['trainee_id'], []).append(s)

    # ── Compute per-trainee scores ──
    items: list[TraineeEngagementItem] = []
    tier_counts: dict[str, int] = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    total_engagement = 0.0

    for trainee in trainee_list:
        trainee_summaries = summaries_by_trainee.get(trainee.id, [])

        # Split into current window and previous window
        current_window = [s for s in trainee_summaries if s['date'] >= start_date]
        previous_window = [s for s in trainee_summaries if s['date'] < start_date]

        # Current window metrics
        days_logged_workout = sum(1 for s in current_window if s['logged_workout'])
        days_logged_food = sum(1 for s in current_window if s['logged_food'])
        days_hit_protein = sum(1 for s in current_window if s['hit_protein_goal'])
        days_hit_calorie = sum(1 for s in current_window if s['hit_calorie_goal'])

        # Days since last activity
        active_dates = [
            s['date'] for s in current_window
            if s['logged_workout'] or s['logged_food']
        ]
        if active_dates:
            last_active = max(active_dates)
            days_since_last = (today - last_active).days
        else:
            # Check if there's any activity at all in the full range
            all_active = [
                s['date'] for s in trainee_summaries
                if s['logged_workout'] or s['logged_food']
            ]
            if all_active:
                last_active = max(all_active)
                days_since_last = (today - last_active).days
            else:
                last_active = None
                days_since_last = lookback_days

        # First half vs second half engagement (for declining trend)
        first_half = [s for s in current_window if s['date'] < half_point]
        second_half = [s for s in current_window if s['date'] >= half_point]

        def _half_engagement(half: list[dict], half_days: int) -> float:
            if half_days <= 0:
                return 0.0
            w = sum(1 for s in half if s['logged_workout'])
            f = sum(1 for s in half if s['logged_food'])
            return ((w + f) / (2.0 * half_days)) * 100.0

        first_half_days = max((half_point - start_date).days, 1)
        second_half_days = max((today - half_point).days, 1)
        first_eng = _half_engagement(first_half, first_half_days)
        second_eng = _half_engagement(second_half, second_half_days)

        # Volume comparison
        current_volume = sum(s['workouts_completed'] for s in current_window)
        previous_volume = sum(s['workouts_completed'] for s in previous_window)

        # New trainee detection
        is_new = (
            trainee.date_joined.date() >= start_date
            and len(current_window) == 0
        )

        engagement, churn_risk = _compute_scores(
            days_logged_workout=days_logged_workout,
            days_logged_food=days_logged_food,
            days_hit_protein=days_hit_protein,
            days_hit_calorie=days_hit_calorie,
            lookback_days=lookback_days,
            days_since_last_activity=days_since_last,
            first_half_engagement=first_eng,
            second_half_engagement=second_eng,
            current_volume=current_volume,
            previous_volume=previous_volume,
            is_new_trainee=is_new,
        )

        tier = _risk_tier(churn_risk)
        tier_counts[tier] += 1
        total_engagement += engagement

        name = f"{trainee.first_name} {trainee.last_name}".strip()
        safe_lookback_for_consistency = max(lookback_days, 1)

        items.append(
            TraineeEngagementItem(
                trainee_id=trainee.id,
                trainee_email=trainee.email,
                trainee_name=name or trainee.email,
                engagement_score=engagement,
                churn_risk_score=churn_risk,
                risk_tier=tier,
                days_since_last_activity=days_since_last if last_active else None,
                workout_consistency=round(
                    days_logged_workout / safe_lookback_for_consistency * 100.0, 1
                ),
                nutrition_consistency=round(
                    days_logged_food / safe_lookback_for_consistency * 100.0, 1
                ),
                last_active_date=last_active.isoformat() if last_active else None,
            )
        )

    total_trainees = len(trainee_list)
    at_risk_count = tier_counts["critical"] + tier_counts["high"]
    avg_engagement = round(total_engagement / total_trainees, 1) if total_trainees > 0 else 0.0
    retention_rate = round(
        ((total_trainees - at_risk_count) / total_trainees) * 100.0, 1
    ) if total_trainees > 0 else 100.0

    # Sort by churn risk descending (most at-risk first)
    items.sort(key=lambda x: x.churn_risk_score, reverse=True)

    # ── Daily trend data ──
    trends: list[RetentionTrendPoint] = []
    # Group current-window summaries by date
    summaries_by_date: dict[date, list[dict]] = {}
    for s in summaries:
        if s['date'] >= start_date:
            summaries_by_date.setdefault(s['date'], []).append(s)

    cursor = start_date
    while cursor <= today:
        day_summaries = summaries_by_date.get(cursor, [])

        if day_summaries:
            day_eng_total = 0.0
            day_at_risk = 0
            active_on_day = set()
            for s in day_summaries:
                active_on_day.add(s['trainee_id'])
                # Simple daily engagement: did they log workout or food?
                score = 0.0
                if s['logged_workout']:
                    score += 50.0
                if s['logged_food']:
                    score += 50.0
                day_eng_total += score
                if score < 25.0:
                    day_at_risk += 1

            # Trainees without summaries on this date count as inactive
            inactive_count = total_trainees - len(active_on_day)
            day_at_risk += inactive_count

            avg_day_eng = round(day_eng_total / total_trainees, 1) if total_trainees > 0 else 0.0
        else:
            avg_day_eng = 0.0
            day_at_risk = total_trainees

        trends.append(
            RetentionTrendPoint(
                date=cursor.isoformat(),
                avg_engagement=avg_day_eng,
                at_risk_count=day_at_risk,
                total_trainees=total_trainees,
            )
        )
        cursor += timedelta(days=1)

    return RetentionAnalyticsResult(
        period_days=lookback_days,
        summary=RetentionSummary(
            total_trainees=total_trainees,
            at_risk_count=at_risk_count,
            critical_count=tier_counts["critical"],
            high_count=tier_counts["high"],
            medium_count=tier_counts["medium"],
            low_count=tier_counts["low"],
            avg_engagement=avg_engagement,
            retention_rate=retention_rate,
        ),
        trainees=items,
        trends=trends,
    )

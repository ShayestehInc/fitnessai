"""
Correlation Analytics Service — v6.5 Step 15.

Computes cross-metric correlations and pattern detection for trainers:
- Protein adherence ↔ strength gains
- Sleep ↔ volume tolerance
- Calorie adherence ↔ weight change
- Workout consistency ↔ nutrition logging
- Exercise-specific progression patterns
- Cohort analysis (high vs low adherence)
"""
from __future__ import annotations

import math
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from django.db.models import Avg, Count, F, Q, Sum
from django.db.models.functions import TruncWeek
from django.utils import timezone

from trainer.models import TraineeActivitySummary
from users.models import User
from workouts.models import LiftMax, LiftSetLog, WeightCheckIn


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class CorrelationPoint:
    """Single correlation result."""
    metric_a: str
    metric_b: str
    correlation: float  # Pearson r: -1 to 1
    sample_size: int
    interpretation: str  # "strong_positive", "moderate_positive", "weak", etc.


@dataclass(frozen=True)
class TraineeInsight:
    """Pattern detected for a specific trainee."""
    trainee_id: int
    trainee_name: str
    insight_type: str  # "strength_plateau", "adherence_boost", "overtraining_risk", etc.
    severity: str  # "info", "warning", "alert"
    message: str
    data: dict[str, Any]


@dataclass(frozen=True)
class CohortComparison:
    """Comparison between high and low adherence cohorts."""
    metric: str
    high_adherence_avg: float
    low_adherence_avg: float
    difference_pct: float
    high_count: int
    low_count: int


@dataclass(frozen=True)
class ExerciseProgression:
    """Progression stats for a specific exercise."""
    exercise_id: int
    exercise_name: str
    trainee_id: int
    e1rm_start: float
    e1rm_current: float
    change_pct: float
    sessions_count: int
    trend: str  # "gaining", "plateau", "declining"


@dataclass(frozen=True)
class CorrelationOverview:
    """Full correlation analytics for a trainer."""
    period_days: int
    correlations: list[CorrelationPoint]
    insights: list[TraineeInsight]
    cohort_comparisons: list[CohortComparison]


@dataclass(frozen=True)
class TraineePatterns:
    """Per-trainee pattern analysis."""
    trainee_id: int
    trainee_name: str
    period_days: int
    insights: list[TraineeInsight]
    exercise_progressions: list[ExerciseProgression]
    adherence_stats: dict[str, float]


# ---------------------------------------------------------------------------
# Main entry points
# ---------------------------------------------------------------------------

def get_correlation_overview(
    *,
    trainer: User,
    days: int = 30,
) -> CorrelationOverview:
    """
    Compute cross-metric correlations across all trainees.
    Returns overall correlations, insights, and cohort comparisons.
    """
    days = max(7, min(365, days))
    start_date = timezone.now().date() - timedelta(days=days)

    trainees = User.objects.filter(
        parent_trainer=trainer,
        role='TRAINEE',
        is_active=True,
    )
    trainee_ids = list(trainees.values_list('pk', flat=True))

    if not trainee_ids:
        return CorrelationOverview(
            period_days=days,
            correlations=[],
            insights=[],
            cohort_comparisons=[],
        )

    # Gather data
    summaries = _get_activity_summaries(trainee_ids, start_date)
    strength_data = _get_strength_data(trainee_ids, start_date)

    # Compute correlations
    correlations = _compute_correlations(summaries, strength_data, trainee_ids)

    # Generate insights
    insights = _generate_insights(summaries, strength_data, trainee_ids, trainees)

    # Cohort comparison
    cohort_comparisons = _compute_cohort_comparisons(
        summaries, strength_data, trainee_ids,
    )

    return CorrelationOverview(
        period_days=days,
        correlations=correlations,
        insights=insights,
        cohort_comparisons=cohort_comparisons,
    )


def get_trainee_patterns(
    *,
    trainer: User,
    trainee_id: int,
    days: int = 30,
) -> TraineePatterns:
    """
    Compute per-trainee pattern analysis.
    Returns insights and exercise progressions.
    """
    days = max(7, min(365, days))
    start_date = timezone.now().date() - timedelta(days=days)

    try:
        trainee = User.objects.get(
            pk=trainee_id,
            parent_trainer=trainer,
            role='TRAINEE',
        )
    except User.DoesNotExist:
        raise ValueError("Trainee not found.")

    trainee_name = trainee.get_full_name() or trainee.email

    summaries = _get_activity_summaries([trainee_id], start_date)
    strength_data = _get_strength_data([trainee_id], start_date)

    # Per-trainee insights
    insights = _generate_trainee_insights(
        trainee_id, trainee_name, summaries, strength_data,
    )

    # Exercise progressions
    progressions = _get_exercise_progressions(trainee_id, start_date)

    # Adherence stats
    trainee_summaries = summaries.get(trainee_id, [])
    adherence = _compute_adherence_stats(trainee_summaries)

    return TraineePatterns(
        trainee_id=trainee_id,
        trainee_name=trainee_name,
        period_days=days,
        insights=insights,
        exercise_progressions=progressions,
        adherence_stats=adherence,
    )


def get_cohort_analysis(
    *,
    trainer: User,
    days: int = 30,
    threshold: float = 70.0,
) -> list[CohortComparison]:
    """
    Compare high-adherence (>=threshold) vs low-adherence (<threshold) trainees.
    """
    days = max(7, min(365, days))
    start_date = timezone.now().date() - timedelta(days=days)

    trainee_ids = list(
        User.objects.filter(
            parent_trainer=trainer, role='TRAINEE', is_active=True,
        ).values_list('pk', flat=True)
    )

    if not trainee_ids:
        return []

    summaries = _get_activity_summaries(trainee_ids, start_date)
    strength_data = _get_strength_data(trainee_ids, start_date)

    return _compute_cohort_comparisons(
        summaries, strength_data, trainee_ids, threshold=threshold,
    )


# ---------------------------------------------------------------------------
# Data gathering
# ---------------------------------------------------------------------------

def _get_activity_summaries(
    trainee_ids: list[int],
    start_date: date,
) -> dict[int, list[dict[str, Any]]]:
    """Fetch TraineeActivitySummary grouped by trainee."""
    qs = TraineeActivitySummary.objects.filter(
        trainee_id__in=trainee_ids,
        date__gte=start_date,
    ).values(
        'trainee_id', 'date',
        'logged_food', 'logged_workout',
        'hit_protein_goal', 'hit_calorie_goal',
        'calories_consumed', 'protein_consumed', 'carbs_consumed', 'fat_consumed',
        'workouts_completed', 'total_sets', 'total_volume',
        'steps', 'sleep_hours',
    ).order_by('trainee_id', 'date')

    result: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for row in qs:
        result[row['trainee_id']].append(row)
    return dict(result)


def _get_strength_data(
    trainee_ids: list[int],
    start_date: date,
) -> dict[int, list[dict[str, Any]]]:
    """Fetch weekly workload totals per trainee."""
    qs = (
        LiftSetLog.objects.filter(
            trainee_id__in=trainee_ids,
            session_date__gte=start_date,
            workload_eligible=True,
        )
        .annotate(week=TruncWeek('session_date'))
        .values('trainee_id', 'week')
        .annotate(
            total_volume=Sum(
                F('canonical_external_load_value') * F('completed_reps')
            ),
            total_sets=Count('id'),
            avg_rpe=Avg('rpe'),
        )
        .order_by('trainee_id', 'week')
    )

    result: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for row in qs:
        result[row['trainee_id']].append({
            'week': row['week'],
            'total_volume': float(row['total_volume'] or 0),
            'total_sets': row['total_sets'],
            'avg_rpe': float(row['avg_rpe'] or 0),
        })
    return dict(result)


# ---------------------------------------------------------------------------
# Correlation computation
# ---------------------------------------------------------------------------

def _pearson_r(xs: list[float], ys: list[float]) -> float:
    """Compute Pearson correlation coefficient. Returns 0 if insufficient data."""
    n = len(xs)
    if n < 3 or n != len(ys):
        return 0.0

    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    cov = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    std_x = math.sqrt(sum((x - mean_x) ** 2 for x in xs))
    std_y = math.sqrt(sum((y - mean_y) ** 2 for y in ys))

    if std_x == 0 or std_y == 0:
        return 0.0

    return cov / (std_x * std_y)


def _interpret_r(r: float) -> str:
    """Interpret Pearson r magnitude."""
    ar = abs(r)
    if ar >= 0.7:
        direction = "positive" if r > 0 else "negative"
        return f"strong_{direction}"
    if ar >= 0.4:
        direction = "positive" if r > 0 else "negative"
        return f"moderate_{direction}"
    return "weak"


def _compute_correlations(
    summaries: dict[int, list[dict[str, Any]]],
    strength_data: dict[int, list[dict[str, Any]]],
    trainee_ids: list[int],
) -> list[CorrelationPoint]:
    """Compute cross-metric correlations across all trainees."""
    results: list[CorrelationPoint] = []

    # 1. Protein adherence ↔ weekly volume
    protein_rates: list[float] = []
    volume_avgs: list[float] = []
    for tid in trainee_ids:
        days = summaries.get(tid, [])
        if not days:
            continue
        protein_rate = sum(1 for d in days if d.get('hit_protein_goal')) / len(days) * 100
        weeks = strength_data.get(tid, [])
        if weeks:
            avg_vol = sum(w['total_volume'] for w in weeks) / len(weeks)
        else:
            avg_vol = 0
        protein_rates.append(protein_rate)
        volume_avgs.append(avg_vol)

    if len(protein_rates) >= 3:
        r = _pearson_r(protein_rates, volume_avgs)
        results.append(CorrelationPoint(
            metric_a='protein_adherence_pct',
            metric_b='avg_weekly_volume',
            correlation=round(r, 3),
            sample_size=len(protein_rates),
            interpretation=_interpret_r(r),
        ))

    # 2. Calorie adherence ↔ workout consistency
    cal_rates: list[float] = []
    workout_rates: list[float] = []
    for tid in trainee_ids:
        days = summaries.get(tid, [])
        if not days:
            continue
        cal_rate = sum(1 for d in days if d.get('hit_calorie_goal')) / len(days) * 100
        wo_rate = sum(1 for d in days if d.get('logged_workout')) / len(days) * 100
        cal_rates.append(cal_rate)
        workout_rates.append(wo_rate)

    if len(cal_rates) >= 3:
        r = _pearson_r(cal_rates, workout_rates)
        results.append(CorrelationPoint(
            metric_a='calorie_adherence_pct',
            metric_b='workout_consistency_pct',
            correlation=round(r, 3),
            sample_size=len(cal_rates),
            interpretation=_interpret_r(r),
        ))

    # 3. Sleep ↔ next-day volume
    sleep_vals: list[float] = []
    next_vol_vals: list[float] = []
    for tid in trainee_ids:
        days = summaries.get(tid, [])
        for i in range(len(days) - 1):
            sleep = days[i].get('sleep_hours')
            next_vol = days[i + 1].get('total_volume')
            if sleep and next_vol:
                sleep_vals.append(float(sleep))
                next_vol_vals.append(float(next_vol))

    if len(sleep_vals) >= 5:
        r = _pearson_r(sleep_vals, next_vol_vals)
        results.append(CorrelationPoint(
            metric_a='sleep_hours',
            metric_b='next_day_volume',
            correlation=round(r, 3),
            sample_size=len(sleep_vals),
            interpretation=_interpret_r(r),
        ))

    # 4. Nutrition logging ↔ workout logging
    food_rates: list[float] = []
    wo_log_rates: list[float] = []
    for tid in trainee_ids:
        days = summaries.get(tid, [])
        if not days:
            continue
        food_rate = sum(1 for d in days if d.get('logged_food')) / len(days) * 100
        wo_rate = sum(1 for d in days if d.get('logged_workout')) / len(days) * 100
        food_rates.append(food_rate)
        wo_log_rates.append(wo_rate)

    if len(food_rates) >= 3:
        r = _pearson_r(food_rates, wo_log_rates)
        results.append(CorrelationPoint(
            metric_a='food_logging_pct',
            metric_b='workout_logging_pct',
            correlation=round(r, 3),
            sample_size=len(food_rates),
            interpretation=_interpret_r(r),
        ))

    return results


# ---------------------------------------------------------------------------
# Insight generation
# ---------------------------------------------------------------------------

def _generate_insights(
    summaries: dict[int, list[dict[str, Any]]],
    strength_data: dict[int, list[dict[str, Any]]],
    trainee_ids: list[int],
    trainees: Any,
) -> list[TraineeInsight]:
    """Generate actionable insights across all trainees."""
    insights: list[TraineeInsight] = []
    trainee_map = {t.pk: t for t in trainees}

    for tid in trainee_ids:
        trainee = trainee_map.get(tid)
        if not trainee:
            continue
        name = trainee.get_full_name() or trainee.email
        days = summaries.get(tid, [])
        weeks = strength_data.get(tid, [])

        trainee_insights = _generate_trainee_insights(tid, name, summaries, strength_data)
        insights.extend(trainee_insights)

    return insights


def _generate_trainee_insights(
    trainee_id: int,
    trainee_name: str,
    summaries: dict[int, list[dict[str, Any]]],
    strength_data: dict[int, list[dict[str, Any]]],
) -> list[TraineeInsight]:
    """Generate insights for a single trainee."""
    insights: list[TraineeInsight] = []
    days = summaries.get(trainee_id, [])
    weeks = strength_data.get(trainee_id, [])

    if not days:
        return insights

    # High adherence detection
    protein_rate = sum(1 for d in days if d.get('hit_protein_goal')) / len(days)
    calorie_rate = sum(1 for d in days if d.get('hit_calorie_goal')) / len(days)
    workout_rate = sum(1 for d in days if d.get('logged_workout')) / len(days)

    if protein_rate >= 0.8 and calorie_rate >= 0.8:
        insights.append(TraineeInsight(
            trainee_id=trainee_id,
            trainee_name=trainee_name,
            insight_type='high_adherence',
            severity='info',
            message=f'{trainee_name} has excellent nutrition adherence '
                    f'(protein: {protein_rate*100:.0f}%, calories: {calorie_rate*100:.0f}%).',
            data={
                'protein_adherence_pct': round(protein_rate * 100, 1),
                'calorie_adherence_pct': round(calorie_rate * 100, 1),
            },
        ))

    # Low adherence warning
    if protein_rate < 0.4 and len(days) >= 7:
        insights.append(TraineeInsight(
            trainee_id=trainee_id,
            trainee_name=trainee_name,
            insight_type='low_protein_adherence',
            severity='warning',
            message=f'{trainee_name} is only hitting protein goals {protein_rate*100:.0f}% of the time.',
            data={'protein_adherence_pct': round(protein_rate * 100, 1)},
        ))

    # Volume plateau detection
    if len(weeks) >= 3:
        recent_3 = weeks[-3:]
        volumes = [w['total_volume'] for w in recent_3]
        if volumes[0] > 0:
            change = (volumes[-1] - volumes[0]) / volumes[0]
            if abs(change) < 0.05:  # Less than 5% change over 3 weeks
                insights.append(TraineeInsight(
                    trainee_id=trainee_id,
                    trainee_name=trainee_name,
                    insight_type='volume_plateau',
                    severity='warning',
                    message=f'{trainee_name} volume has plateaued over the last 3 weeks '
                            f'({volumes[0]:.0f} → {volumes[-1]:.0f}).',
                    data={
                        'volume_start': round(volumes[0]),
                        'volume_end': round(volumes[-1]),
                        'change_pct': round(change * 100, 1),
                    },
                ))

    # RPE spike detection (overtraining risk)
    if len(weeks) >= 2:
        prev_rpe = weeks[-2].get('avg_rpe', 0)
        curr_rpe = weeks[-1].get('avg_rpe', 0)
        if prev_rpe > 0 and curr_rpe > 0:
            rpe_increase = curr_rpe - prev_rpe
            if rpe_increase >= 1.5:
                insights.append(TraineeInsight(
                    trainee_id=trainee_id,
                    trainee_name=trainee_name,
                    insight_type='overtraining_risk',
                    severity='alert',
                    message=f'{trainee_name} RPE jumped from {prev_rpe:.1f} to {curr_rpe:.1f} '
                            f'— possible overtraining or accumulated fatigue.',
                    data={
                        'prev_rpe': round(prev_rpe, 1),
                        'curr_rpe': round(curr_rpe, 1),
                        'rpe_increase': round(rpe_increase, 1),
                    },
                ))

    # Sleep drop detection
    if len(days) >= 14:
        first_week = [d.get('sleep_hours') for d in days[:7] if d.get('sleep_hours')]
        last_week = [d.get('sleep_hours') for d in days[-7:] if d.get('sleep_hours')]
        if first_week and last_week:
            avg_first = sum(first_week) / len(first_week)
            avg_last = sum(last_week) / len(last_week)
            if avg_first > 0 and (avg_first - avg_last) >= 1.5:
                insights.append(TraineeInsight(
                    trainee_id=trainee_id,
                    trainee_name=trainee_name,
                    insight_type='sleep_declining',
                    severity='warning',
                    message=f'{trainee_name} sleep dropped from {avg_first:.1f}h to {avg_last:.1f}h '
                            f'over the period.',
                    data={
                        'sleep_start_avg': round(avg_first, 1),
                        'sleep_end_avg': round(avg_last, 1),
                    },
                ))

    return insights


# ---------------------------------------------------------------------------
# Cohort comparison
# ---------------------------------------------------------------------------

def _compute_cohort_comparisons(
    summaries: dict[int, list[dict[str, Any]]],
    strength_data: dict[int, list[dict[str, Any]]],
    trainee_ids: list[int],
    threshold: float = 70.0,
) -> list[CohortComparison]:
    """Compare high vs low adherence cohorts."""
    high_ids: list[int] = []
    low_ids: list[int] = []

    for tid in trainee_ids:
        days = summaries.get(tid, [])
        if not days:
            continue
        adherence = sum(
            1 for d in days
            if d.get('logged_food') or d.get('logged_workout')
        ) / len(days) * 100
        if adherence >= threshold:
            high_ids.append(tid)
        else:
            low_ids.append(tid)

    if not high_ids or not low_ids:
        return []

    comparisons: list[CohortComparison] = []

    # Compare weekly volume
    def _avg_weekly_volume(ids: list[int]) -> float:
        total = 0.0
        count = 0
        for tid in ids:
            weeks = strength_data.get(tid, [])
            for w in weeks:
                total += w['total_volume']
                count += 1
        return total / count if count > 0 else 0

    high_vol = _avg_weekly_volume(high_ids)
    low_vol = _avg_weekly_volume(low_ids)
    diff = ((high_vol - low_vol) / low_vol * 100) if low_vol > 0 else 0

    comparisons.append(CohortComparison(
        metric='avg_weekly_volume',
        high_adherence_avg=round(high_vol, 1),
        low_adherence_avg=round(low_vol, 1),
        difference_pct=round(diff, 1),
        high_count=len(high_ids),
        low_count=len(low_ids),
    ))

    # Compare protein hit rate
    def _avg_protein_rate(ids: list[int]) -> float:
        total = 0.0
        count = 0
        for tid in ids:
            days = summaries.get(tid, [])
            if days:
                rate = sum(1 for d in days if d.get('hit_protein_goal')) / len(days)
                total += rate
                count += 1
        return (total / count * 100) if count > 0 else 0

    high_protein = _avg_protein_rate(high_ids)
    low_protein = _avg_protein_rate(low_ids)
    diff_p = high_protein - low_protein

    comparisons.append(CohortComparison(
        metric='protein_adherence_pct',
        high_adherence_avg=round(high_protein, 1),
        low_adherence_avg=round(low_protein, 1),
        difference_pct=round(diff_p, 1),
        high_count=len(high_ids),
        low_count=len(low_ids),
    ))

    # Compare workout consistency
    def _avg_workout_rate(ids: list[int]) -> float:
        total = 0.0
        count = 0
        for tid in ids:
            days = summaries.get(tid, [])
            if days:
                rate = sum(1 for d in days if d.get('logged_workout')) / len(days)
                total += rate
                count += 1
        return (total / count * 100) if count > 0 else 0

    high_wo = _avg_workout_rate(high_ids)
    low_wo = _avg_workout_rate(low_ids)
    diff_w = high_wo - low_wo

    comparisons.append(CohortComparison(
        metric='workout_consistency_pct',
        high_adherence_avg=round(high_wo, 1),
        low_adherence_avg=round(low_wo, 1),
        difference_pct=round(diff_w, 1),
        high_count=len(high_ids),
        low_count=len(low_ids),
    ))

    return comparisons


# ---------------------------------------------------------------------------
# Exercise progressions
# ---------------------------------------------------------------------------

def _get_exercise_progressions(
    trainee_id: int,
    start_date: date,
) -> list[ExerciseProgression]:
    """Get e1RM progression for each exercise the trainee trained."""
    lift_maxes = LiftMax.objects.filter(
        trainee_id=trainee_id,
    ).select_related('exercise')

    # Batch session counts to avoid N+1 queries
    session_counts_qs = (
        LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            session_date__gte=start_date,
        )
        .values('exercise_id')
        .annotate(session_count=Count('session_date', distinct=True))
    )
    session_count_map: dict[int, int] = {
        row['exercise_id']: row['session_count']
        for row in session_counts_qs
    }

    progressions: list[ExerciseProgression] = []

    for lm in lift_maxes:
        history = lm.e1rm_history or []
        # Filter to entries within the period
        relevant = [
            h for h in history
            if h.get('date') and h['date'] >= str(start_date)
        ]

        if len(relevant) < 2:
            continue

        e1rm_start = float(relevant[0].get('value', 0))
        e1rm_current = float(relevant[-1].get('value', 0))

        if e1rm_start <= 0:
            continue

        change_pct = ((e1rm_current - e1rm_start) / e1rm_start) * 100
        session_count = session_count_map.get(lm.exercise_id, 0)

        if abs(change_pct) < 2:
            trend = 'plateau'
        elif change_pct > 0:
            trend = 'gaining'
        else:
            trend = 'declining'

        progressions.append(ExerciseProgression(
            exercise_id=lm.exercise_id,
            exercise_name=lm.exercise.name,
            trainee_id=trainee_id,
            e1rm_start=round(e1rm_start, 1),
            e1rm_current=round(e1rm_current, 1),
            change_pct=round(change_pct, 1),
            sessions_count=session_count,
            trend=trend,
        ))

    # Sort by change_pct descending
    progressions.sort(key=lambda p: p.change_pct, reverse=True)
    return progressions


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _compute_adherence_stats(
    days: list[dict[str, Any]],
) -> dict[str, float]:
    """Compute adherence summary stats for a trainee."""
    if not days:
        return {
            'food_logging_pct': 0,
            'workout_logging_pct': 0,
            'protein_adherence_pct': 0,
            'calorie_adherence_pct': 0,
            'avg_sleep_hours': 0,
            'avg_daily_volume': 0,
            'total_days': 0,
        }

    n = len(days)
    sleep_vals = [d.get('sleep_hours') for d in days if d.get('sleep_hours')]
    vol_vals = [d.get('total_volume') for d in days if d.get('total_volume')]

    return {
        'food_logging_pct': round(sum(1 for d in days if d.get('logged_food')) / n * 100, 1),
        'workout_logging_pct': round(sum(1 for d in days if d.get('logged_workout')) / n * 100, 1),
        'protein_adherence_pct': round(sum(1 for d in days if d.get('hit_protein_goal')) / n * 100, 1),
        'calorie_adherence_pct': round(sum(1 for d in days if d.get('hit_calorie_goal')) / n * 100, 1),
        'avg_sleep_hours': round(sum(sleep_vals) / len(sleep_vals), 1) if sleep_vals else 0,
        'avg_daily_volume': round(sum(float(v) for v in vol_vals) / len(vol_vals), 1) if vol_vals else 0,
        'total_days': n,
    }

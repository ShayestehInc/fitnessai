"""
Workload Engine — aggregation, trends, comparable matching, and fact selection.

Computes exercise, session, and weekly workload totals from LiftSetLog data.
Distributes workload across muscle groups and movement patterns using ExerciseCard tags.
Provides trend analysis (ACWR, spike/dip detection, week-over-week deltas).
Selects deterministic cool facts from WorkloadFactTemplate library.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

from django.db.models import Sum, Count, F, Q, QuerySet


# ---------------------------------------------------------------------------
# Result dataclasses — never return raw dicts
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class ExerciseWorkload:
    """Aggregated workload for one exercise in one session."""
    exercise_id: int
    exercise_name: str
    session_date: date
    total_workload: Decimal
    unit: str
    set_count: int
    rep_total: int
    mixed_units: bool  # True if sets have different workload units
    comparison_delta: Decimal | None  # vs last exposure, as percentage
    comparison_date: date | None
    fact_text: str | None


@dataclass(frozen=True)
class SessionWorkload:
    """Aggregated workload for an entire session."""
    trainee_id: int
    session_date: date
    total_workload: Decimal
    unit: str
    mixed_units: bool
    exercise_count: int
    total_sets: int
    total_reps: int
    top_exercises: list[dict[str, Any]]  # [{exercise_name, workload, unit}]
    week_to_date_workload: Decimal
    comparison_delta: Decimal | None
    comparison_date: date | None
    fact_text: str | None


@dataclass(frozen=True)
class WeeklyWorkload:
    """Aggregated workload for a week."""
    trainee_id: int
    week_start: date
    week_end: date
    total_workload: Decimal
    unit: str
    session_count: int
    by_muscle_group: dict[str, Decimal]
    by_pattern: dict[str, Decimal]
    prior_week_delta: Decimal | None  # percentage change
    daily_breakdown: dict[str, Decimal]  # {date_str: workload}


@dataclass(frozen=True)
class WorkloadTrend:
    """Trend snapshot for a trainee."""
    trainee_id: int
    as_of_date: date
    rolling_7_day: Decimal
    rolling_28_day: Decimal
    acute_chronic_ratio: Decimal | None  # null if < 28 days of data
    trend_direction: str  # 'rising', 'stable', 'declining'
    spike_flag: bool
    dip_flag: bool
    weekly_deltas: list[dict[str, Any]]  # [{week_start, workload, delta_percent}]


# ---------------------------------------------------------------------------
# Workload Aggregation Service
# ---------------------------------------------------------------------------

class WorkloadAggregationService:
    """
    Computes workload aggregates from LiftSetLog data.

    Rules from v6.5 spec:
    - Only workload_eligible sets are included
    - Warm-up exclusion is the default (include_warmups param for override)
    - Preserves native unit context (lb_reps or kg_reps)
    - Uses muscle_contribution_map to distribute workload across muscles
    """

    @staticmethod
    def _detect_mixed_units(sets: QuerySet) -> bool:
        """Check if a queryset contains sets with different workload units."""
        distinct_units = sets.values_list('set_workload_unit', flat=True).distinct()
        return distinct_units.count() > 1

    @staticmethod
    def _get_eligible_sets(
        trainee_id: int,
        session_date: date | None = None,
        exercise_id: int | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
    ) -> QuerySet:
        """Get workload-eligible LiftSetLog entries with filters."""
        from workouts.models import LiftSetLog

        qs = LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            workload_eligible=True,
        ).select_related('exercise')

        if session_date is not None:
            qs = qs.filter(session_date=session_date)
        if exercise_id is not None:
            qs = qs.filter(exercise_id=exercise_id)
        if date_from is not None:
            qs = qs.filter(session_date__gte=date_from)
        if date_to is not None:
            qs = qs.filter(session_date__lte=date_to)

        return qs

    @classmethod
    def compute_exercise_workload(
        cls,
        trainee_id: int,
        exercise_id: int,
        session_date: date,
        trainer_id: int | None = None,
    ) -> ExerciseWorkload:
        """Compute total workload for one exercise in one session."""
        sets = cls._get_eligible_sets(
            trainee_id=trainee_id,
            session_date=session_date,
            exercise_id=exercise_id,
        )

        agg = sets.aggregate(
            total_workload=Sum('set_workload_value'),
            set_count=Count('id'),
            rep_total=Sum('completed_reps'),
        )

        total_workload = agg['total_workload'] or Decimal('0')
        set_count = agg['set_count'] or 0
        rep_total = agg['rep_total'] or 0

        # Determine unit and check for mixed units
        first_set = sets.first()
        unit = first_set.set_workload_unit if first_set else 'lb_reps'
        exercise_name = first_set.exercise.name if first_set else ''
        mixed_units = cls._detect_mixed_units(sets) if set_count > 0 else False

        # Find comparable: last time this exercise was done before this session
        comparison_delta, comparison_date = cls._find_exercise_comparison(
            trainee_id, exercise_id, session_date, total_workload,
        )

        # Select fact
        fact_text = WorkloadFactService.select_and_render(
            scope='exercise',
            context={
                'exercise_name': exercise_name,
                'total_workload': total_workload,
                'total_reps': rep_total,
                'set_count': set_count,
                'unit': unit,
                'delta_percent': comparison_delta,
            },
            trainer_id=trainer_id,
        )

        return ExerciseWorkload(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            session_date=session_date,
            total_workload=total_workload,
            unit=unit,
            set_count=set_count,
            rep_total=rep_total,
            mixed_units=mixed_units,
            comparison_delta=comparison_delta,
            comparison_date=comparison_date,
            fact_text=fact_text,
        )

    @classmethod
    def _find_exercise_comparison(
        cls,
        trainee_id: int,
        exercise_id: int,
        session_date: date,
        current_workload: Decimal,
    ) -> tuple[Decimal | None, date | None]:
        """Find the last comparable exercise exposure and compute delta."""
        from workouts.models import LiftSetLog

        prev_date = (
            LiftSetLog.objects.filter(
                trainee_id=trainee_id,
                exercise_id=exercise_id,
                workload_eligible=True,
                session_date__lt=session_date,
            )
            .values_list('session_date', flat=True)
            .order_by('-session_date')
            .first()
        )

        if prev_date is None:
            return None, None

        prev_agg = LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            exercise_id=exercise_id,
            workload_eligible=True,
            session_date=prev_date,
        ).aggregate(total=Sum('set_workload_value'))

        prev_total = prev_agg['total'] or Decimal('0')
        if prev_total <= 0:
            return None, prev_date

        delta = ((current_workload - prev_total) / prev_total * 100).quantize(
            Decimal('0.1'), rounding=ROUND_HALF_UP,
        )
        return delta, prev_date

    @classmethod
    def _find_comparable_session(
        cls,
        trainee_id: int,
        exercise_id: int,
        session_date: date,
        current_workload: Decimal,
    ) -> tuple[Decimal | None, date | None, int, str]:
        """
        Find a comparable exercise exposure using a 3-tier cascade (v6.5 §23.5).

        Returns: (delta_pct, comparison_date, tier, confidence)
        Tier 1: Same exercise (exact match)
        Tier 2: Same pattern + same role + same rep bucket
        Tier 3: Same primary muscle + same intent + same rep bucket
        """
        from workouts.models import Exercise, LiftSetLog

        # Tier 1: Same exercise (existing logic)
        delta, prev_date = cls._find_exercise_comparison(
            trainee_id, exercise_id, session_date, current_workload,
        )
        if delta is not None:
            return delta, prev_date, 1, 'high'

        # Get the exercise's tags for fallback matching
        try:
            exercise = Exercise.objects.get(pk=exercise_id)
        except Exercise.DoesNotExist:
            return None, None, 0, 'none'

        pattern_tags = exercise.pattern_tags or []
        primary_muscle = exercise.primary_muscle_group or ''

        if not pattern_tags and not primary_muscle:
            return None, None, 0, 'none'

        # Tier 2: Same pattern tag + find any exercise with overlap
        if pattern_tags:
            similar_exercises = list(
                Exercise.objects.filter(
                    pattern_tags__overlap=pattern_tags,
                )
                .exclude(pk=exercise_id)
                .values_list('pk', flat=True)[:20]
            )
            if similar_exercises:
                prev = (
                    LiftSetLog.objects.filter(
                        trainee_id=trainee_id,
                        exercise_id__in=similar_exercises,
                        workload_eligible=True,
                        session_date__lt=session_date,
                    )
                    .order_by('-session_date')
                    .first()
                )
                if prev:
                    prev_agg = LiftSetLog.objects.filter(
                        trainee_id=trainee_id,
                        exercise_id=prev.exercise_id,
                        workload_eligible=True,
                        session_date=prev.session_date,
                    ).aggregate(total=Sum('set_workload_value'))
                    prev_total = prev_agg['total'] or Decimal('0')
                    if prev_total > 0:
                        d = ((current_workload - prev_total) / prev_total * 100).quantize(
                            Decimal('0.1'), rounding=ROUND_HALF_UP,
                        )
                        return d, prev.session_date, 2, 'medium'

        # Tier 3: Same primary muscle
        if primary_muscle:
            muscle_exercises = list(
                Exercise.objects.filter(
                    primary_muscle_group=primary_muscle,
                )
                .exclude(pk=exercise_id)
                .values_list('pk', flat=True)[:20]
            )
            if muscle_exercises:
                prev = (
                    LiftSetLog.objects.filter(
                        trainee_id=trainee_id,
                        exercise_id__in=muscle_exercises,
                        workload_eligible=True,
                        session_date__lt=session_date,
                    )
                    .order_by('-session_date')
                    .first()
                )
                if prev:
                    prev_agg = LiftSetLog.objects.filter(
                        trainee_id=trainee_id,
                        exercise_id=prev.exercise_id,
                        workload_eligible=True,
                        session_date=prev.session_date,
                    ).aggregate(total=Sum('set_workload_value'))
                    prev_total = prev_agg['total'] or Decimal('0')
                    if prev_total > 0:
                        d = ((current_workload - prev_total) / prev_total * 100).quantize(
                            Decimal('0.1'), rounding=ROUND_HALF_UP,
                        )
                        return d, prev.session_date, 3, 'low'

        return None, None, 0, 'none'

    @classmethod
    def compute_session_workload(
        cls,
        trainee_id: int,
        session_date: date,
        trainer_id: int | None = None,
    ) -> SessionWorkload:
        """Compute total workload for an entire session (all exercises)."""
        sets = cls._get_eligible_sets(
            trainee_id=trainee_id,
            session_date=session_date,
        )

        agg = sets.aggregate(
            total_workload=Sum('set_workload_value'),
            total_sets=Count('id'),
            total_reps=Sum('completed_reps'),
        )

        total_workload = agg['total_workload'] or Decimal('0')
        total_sets = agg['total_sets'] or 0
        total_reps = agg['total_reps'] or 0

        # Unit from first set + mixed units check
        first_set = sets.first()
        unit = first_set.set_workload_unit if first_set else 'lb_reps'
        mixed_units = cls._detect_mixed_units(sets) if total_sets > 0 else False

        # Top exercises by workload
        exercise_totals = (
            sets.values('exercise_id', exercise_name=F('exercise__name'))
            .annotate(workload=Sum('set_workload_value'))
            .order_by('-workload')[:5]
        )
        top_exercises = [
            {
                'exercise_name': e['exercise_name'],
                'workload': str(e['workload']),
                'unit': unit,
            }
            for e in exercise_totals
        ]

        exercise_count = sets.values('exercise_id').distinct().count()

        # Week-to-date: Monday of the session_date's week through session_date
        week_start = session_date - timedelta(days=session_date.weekday())
        wtd_agg = cls._get_eligible_sets(
            trainee_id=trainee_id,
            date_from=week_start,
            date_to=session_date,
        ).aggregate(total=Sum('set_workload_value'))
        week_to_date = wtd_agg['total'] or Decimal('0')

        # Find comparable session: last session before this one
        from workouts.models import LiftSetLog
        prev_session_date = (
            LiftSetLog.objects.filter(
                trainee_id=trainee_id,
                workload_eligible=True,
                session_date__lt=session_date,
            )
            .values_list('session_date', flat=True)
            .order_by('-session_date')
            .first()
        )

        comparison_delta: Decimal | None = None
        comparison_date: date | None = prev_session_date

        if prev_session_date is not None:
            prev_agg = cls._get_eligible_sets(
                trainee_id=trainee_id,
                session_date=prev_session_date,
            ).aggregate(total=Sum('set_workload_value'))
            prev_total = prev_agg['total'] or Decimal('0')
            if prev_total > 0:
                comparison_delta = (
                    (total_workload - prev_total) / prev_total * 100
                ).quantize(Decimal('0.1'), rounding=ROUND_HALF_UP)

        # Select fact
        fact_text = WorkloadFactService.select_and_render(
            scope='session',
            context={
                'total_workload': total_workload,
                'total_reps': total_reps,
                'set_count': total_sets,
                'unit': unit,
                'exercise_count': exercise_count,
                'top_exercise': top_exercises[0]['exercise_name'] if top_exercises else '',
                'week_total': week_to_date,
                'delta_percent': comparison_delta,
            },
            trainer_id=trainer_id,
        )

        return SessionWorkload(
            trainee_id=trainee_id,
            session_date=session_date,
            total_workload=total_workload,
            unit=unit,
            mixed_units=mixed_units,
            exercise_count=exercise_count,
            total_sets=total_sets,
            total_reps=total_reps,
            top_exercises=top_exercises,
            week_to_date_workload=week_to_date,
            comparison_delta=comparison_delta,
            comparison_date=comparison_date,
            fact_text=fact_text,
        )

    @classmethod
    def compute_weekly_workload(
        cls,
        trainee_id: int,
        week_start: date | None = None,
        week_end: date | None = None,
    ) -> WeeklyWorkload:
        """Compute workload for a week with muscle-group and pattern breakdowns."""
        today = date.today()
        if week_start is None:
            week_start = today - timedelta(days=today.weekday())
        if week_end is None:
            week_end = week_start + timedelta(days=6)

        sets = cls._get_eligible_sets(
            trainee_id=trainee_id,
            date_from=week_start,
            date_to=week_end,
        )

        agg = sets.aggregate(
            total_workload=Sum('set_workload_value'),
        )
        total_workload = agg['total_workload'] or Decimal('0')

        first_set = sets.first()
        unit = first_set.set_workload_unit if first_set else 'lb_reps'

        session_count = sets.values('session_date').distinct().count()

        # Daily breakdown
        daily = (
            sets.values('session_date')
            .annotate(workload=Sum('set_workload_value'))
            .order_by('session_date')
        )
        daily_breakdown = {
            str(d['session_date']): str(d['workload']) for d in daily
        }

        # Muscle group and pattern breakdowns
        by_muscle, by_pattern = cls._compute_distributions(sets)

        # Prior week comparison
        prior_start = week_start - timedelta(days=7)
        prior_end = week_start - timedelta(days=1)
        prior_agg = cls._get_eligible_sets(
            trainee_id=trainee_id,
            date_from=prior_start,
            date_to=prior_end,
        ).aggregate(total=Sum('set_workload_value'))
        prior_total = prior_agg['total'] or Decimal('0')

        prior_week_delta: Decimal | None = None
        if prior_total > 0:
            prior_week_delta = (
                (total_workload - prior_total) / prior_total * 100
            ).quantize(Decimal('0.1'), rounding=ROUND_HALF_UP)

        return WeeklyWorkload(
            trainee_id=trainee_id,
            week_start=week_start,
            week_end=week_end,
            total_workload=total_workload,
            unit=unit,
            session_count=session_count,
            by_muscle_group=by_muscle,
            by_pattern=by_pattern,
            prior_week_delta=prior_week_delta,
            daily_breakdown=daily_breakdown,
        )

    @staticmethod
    def _compute_distributions(
        sets: QuerySet,
    ) -> tuple[dict[str, Decimal], dict[str, Decimal]]:
        """
        Single-pass computation of both muscle group and pattern distributions.

        Muscle: uses muscle_contribution_map, falls back to primary_muscle_group.
        Pattern: splits workload evenly across all pattern_tags.
        """
        muscle_totals: dict[str, Decimal] = {}
        pattern_totals: dict[str, Decimal] = {}

        for s in sets.iterator(chunk_size=500):
            exercise = s.exercise
            workload = s.set_workload_value

            if workload <= 0:
                continue

            # Muscle distribution
            contrib_map = exercise.muscle_contribution_map
            if contrib_map:
                for muscle, weight in contrib_map.items():
                    w = Decimal(str(weight))
                    muscle_totals[muscle] = muscle_totals.get(muscle, Decimal('0')) + workload * w
            elif exercise.primary_muscle_group:
                mg = exercise.primary_muscle_group
                muscle_totals[mg] = muscle_totals.get(mg, Decimal('0')) + workload
            else:
                muscle_totals['unclassified'] = (
                    muscle_totals.get('unclassified', Decimal('0')) + workload
                )

            # Pattern distribution
            tags = exercise.pattern_tags
            if tags:
                share = workload / Decimal(len(tags))
                for tag in tags:
                    pattern_totals[tag] = pattern_totals.get(tag, Decimal('0')) + share

        quantize = Decimal('0.01')
        muscle_result = {
            k: v.quantize(quantize, rounding=ROUND_HALF_UP)
            for k, v in sorted(muscle_totals.items(), key=lambda x: x[1], reverse=True)
        }
        pattern_result = {
            k: v.quantize(quantize, rounding=ROUND_HALF_UP)
            for k, v in sorted(pattern_totals.items(), key=lambda x: x[1], reverse=True)
        }
        return muscle_result, pattern_result


# ---------------------------------------------------------------------------
# Workload Trend Service
# ---------------------------------------------------------------------------

class WorkloadTrendService:
    """
    Trend analysis: acute:chronic workload ratio, spike/dip detection,
    week-over-week deltas.
    """

    # Default spike/dip thresholds
    SPIKE_ACWR_THRESHOLD: Decimal = Decimal('1.3')
    DIP_ACWR_THRESHOLD: Decimal = Decimal('0.8')
    MIN_CHRONIC_DAYS: int = 28  # Need 28 days of data for ACWR

    @classmethod
    def compute_trend(
        cls,
        trainee_id: int,
        as_of_date: date | None = None,
        weeks_back: int = 8,
    ) -> WorkloadTrend:
        """Compute full trend snapshot."""
        if as_of_date is None:
            as_of_date = date.today()

        rolling_7 = cls._rolling_workload(trainee_id, as_of_date, days=7)
        rolling_28 = cls._rolling_workload(trainee_id, as_of_date, days=28)

        # ACWR = acute (7d) / chronic weekly average (28d / 4)
        acwr: Decimal | None = None
        chronic_weekly = rolling_28 / Decimal('4') if rolling_28 > 0 else Decimal('0')

        # Check if we have enough data (at least 28 days of training history)
        from workouts.models import LiftSetLog
        earliest = (
            LiftSetLog.objects.filter(trainee_id=trainee_id, workload_eligible=True)
            .values_list('session_date', flat=True)
            .order_by('session_date')
            .first()
        )

        has_enough_data = (
            earliest is not None
            and (as_of_date - earliest).days >= cls.MIN_CHRONIC_DAYS
        )

        if has_enough_data and chronic_weekly > 0:
            acwr = (rolling_7 / chronic_weekly).quantize(
                Decimal('0.01'), rounding=ROUND_HALF_UP,
            )

        spike = acwr is not None and acwr > cls.SPIKE_ACWR_THRESHOLD
        dip = acwr is not None and acwr < cls.DIP_ACWR_THRESHOLD

        # Trend direction from last 2 weeks
        prev_7 = cls._rolling_workload(
            trainee_id, as_of_date - timedelta(days=7), days=7,
        )
        if prev_7 > 0:
            change = (rolling_7 - prev_7) / prev_7
            if change > Decimal('0.05'):
                direction = 'rising'
            elif change < Decimal('-0.05'):
                direction = 'declining'
            else:
                direction = 'stable'
        else:
            direction = 'stable' if rolling_7 == 0 else 'rising'

        # Weekly deltas
        weekly_deltas = cls._get_weekly_deltas(trainee_id, as_of_date, weeks_back)

        return WorkloadTrend(
            trainee_id=trainee_id,
            as_of_date=as_of_date,
            rolling_7_day=rolling_7,
            rolling_28_day=rolling_28,
            acute_chronic_ratio=acwr,
            trend_direction=direction,
            spike_flag=spike,
            dip_flag=dip,
            weekly_deltas=weekly_deltas,
        )

    @staticmethod
    def _rolling_workload(trainee_id: int, end_date: date, days: int) -> Decimal:
        """Sum workload over the last N days ending on end_date."""
        from workouts.models import LiftSetLog

        start = end_date - timedelta(days=days - 1)
        agg = LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            workload_eligible=True,
            session_date__gte=start,
            session_date__lte=end_date,
        ).aggregate(total=Sum('set_workload_value'))
        return agg['total'] or Decimal('0')

    @classmethod
    def _get_weekly_deltas(
        cls,
        trainee_id: int,
        as_of_date: date,
        weeks_back: int,
    ) -> list[dict[str, Any]]:
        """Compute week-over-week workload with delta percentages."""
        results: list[dict[str, Any]] = []
        prev_workload: Decimal | None = None

        for i in range(weeks_back, -1, -1):
            week_end = as_of_date - timedelta(weeks=i)
            week_start = week_end - timedelta(days=6)
            workload = cls._rolling_workload(trainee_id, week_end, days=7)

            delta: Decimal | None = None
            if prev_workload is not None and prev_workload > 0:
                delta = (
                    (workload - prev_workload) / prev_workload * 100
                ).quantize(Decimal('0.1'), rounding=ROUND_HALF_UP)

            results.append({
                'week_start': str(week_start),
                'week_end': str(week_end),
                'workload': str(workload),
                'delta_percent': str(delta) if delta is not None else None,
            })
            prev_workload = workload

        return results


# ---------------------------------------------------------------------------
# Workload Fact Service
# ---------------------------------------------------------------------------

class WorkloadFactService:
    """
    Deterministic fact selection and rendering from WorkloadFactTemplate library.

    Selection algorithm:
    1. Filter active templates matching the scope
    2. Evaluate condition_rules against the context
    3. Sort by priority (ascending — lower = higher priority)
    4. Pick the first match
    5. Render template text with context data
    """

    # Max templates to evaluate for fact selection (prevents DoS)
    MAX_TEMPLATES_EVALUATED: int = 50

    @classmethod
    def select_and_render(
        cls,
        scope: str,
        context: dict[str, Any],
        trainer_id: int | None = None,
    ) -> str | None:
        """
        Select the best matching fact template and render it.

        Templates are scoped: system defaults (created_by=null) + trainer's own.
        """
        from workouts.models import WorkloadFactTemplate

        qs = WorkloadFactTemplate.objects.filter(
            scope=scope,
            is_active=True,
        )

        # Scope by trainer: system defaults + trainer's own templates
        if trainer_id is not None:
            qs = qs.filter(Q(created_by__isnull=True) | Q(created_by_id=trainer_id))
        else:
            qs = qs.filter(created_by__isnull=True)

        templates = qs.order_by('priority')[:cls.MAX_TEMPLATES_EVALUATED]

        for template in templates:
            if cls._evaluate_conditions(template.condition_rules, context):
                return cls._render(template.template_text, context)

        return None

    @staticmethod
    def _evaluate_conditions(
        rules: dict[str, Any],
        context: dict[str, Any],
    ) -> bool:
        """
        Evaluate condition rules against context data.

        Supported rules:
        - min_workload: total_workload >= value
        - max_workload: total_workload <= value
        - has_comparison: delta_percent is not None
        - delta_positive: delta_percent > 0
        - min_sets: set_count >= value
        - always: true (always matches — use for fallback templates)
        """
        if not rules:
            # Empty rules = always matches (fallback)
            return True

        if rules.get('always'):
            return True

        total_workload = context.get('total_workload', Decimal('0'))
        if isinstance(total_workload, str):
            total_workload = Decimal(total_workload)

        min_wl = rules.get('min_workload')
        if min_wl is not None and total_workload < Decimal(str(min_wl)):
            return False

        max_wl = rules.get('max_workload')
        if max_wl is not None and total_workload > Decimal(str(max_wl)):
            return False

        if rules.get('has_comparison') and context.get('delta_percent') is None:
            return False

        if rules.get('delta_positive'):
            delta = context.get('delta_percent')
            if delta is None or delta <= 0:
                return False

        min_sets = rules.get('min_sets')
        if min_sets is not None:
            set_count = context.get('set_count', 0)
            if set_count < min_sets:
                return False

        return True

    # Regex to match {word_chars_only} — no dots, underscores are OK
    _PLACEHOLDER_RE = re.compile(r'\{(\w+)\}')

    @classmethod
    def _render(cls, template_text: str, context: dict[str, Any]) -> str:
        """
        Render template text with context placeholders using safe regex substitution.

        Only supports simple {key} placeholders — no attribute access, format specs,
        or nested lookups. This prevents injection via trainer-authored templates.
        Missing keys become empty strings.
        """
        # Build safe context with string conversions
        safe: dict[str, str] = {}
        for key, value in context.items():
            if value is None:
                safe[key] = ''
            elif isinstance(value, Decimal):
                safe[key] = str(value.quantize(Decimal('0.1'), rounding=ROUND_HALF_UP))
            else:
                safe[key] = str(value)

        def replacer(match: re.Match[str]) -> str:
            return safe.get(match.group(1), '')

        return cls._PLACEHOLDER_RE.sub(replacer, template_text)

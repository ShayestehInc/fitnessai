"""
Progression Engine Service — v6.5 Step 7.

Deterministic progression computation for training plan slots.
Supports 5 progression styles from the packet:
- Staircase Percent: increase % of TM weekly
- Rep Staircase: hold load, climb reps, bump load at top
- Double Progression: earn reps in range, increase load
- Linear: straight line load increases
- Wave-by-Month: 4-week accumulation/build/intensify/deload waves

All decisions logged via DecisionLog. All suggestions return dataclasses.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from django.db import transaction
from django.db.models import Q

from workouts.models import (
    DecisionLog,
    Exercise,
    LiftMax,
    LiftSetLog,
    PlanSlot,
    ProgressionEvent,
    ProgressionProfile,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class NextPrescription:
    """Computed next-session prescription for a slot."""
    slot_id: str
    exercise_id: int
    exercise_name: str
    progression_type: str
    event_type: str  # progression, deload, failure, hold, reset
    sets: int
    reps_min: int
    reps_max: int
    load_value: Decimal | None  # Prescribed load (None if no TM)
    load_unit: str
    load_percentage: Decimal | None  # % of TM
    reason_codes: list[str]
    reason_display: str  # Human-readable explanation
    confidence: str  # high, medium, low


@dataclass(frozen=True)
class ProgressionReadiness:
    """Evaluation of whether a slot is ready for progression."""
    slot_id: str
    is_ready: bool
    blockers: list[str]  # e.g., ['no_max', 'insufficient_history', 'gap_detected']
    recent_sessions: int
    last_session_date: str | None
    avg_rpe: Decimal | None
    sets_completed_rate: Decimal | None  # % of prescribed sets completed
    consecutive_failures: int


@dataclass(frozen=True)
class ProgressionEventResult:
    """Result of applying a progression."""
    event_id: str
    slot_id: str
    event_type: str
    old_prescription: dict[str, Any]
    new_prescription: dict[str, Any]
    reason_codes: list[str]
    decision_log_id: str


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_LOOKBACK_DAYS = 28  # 4 weeks
_MIN_SESSIONS_FOR_PROGRESSION = 2
_GAP_THRESHOLD_DAYS = 14  # 2 weeks gap triggers deload
_DEFAULT_ROUNDING_INCREMENT = Decimal('2.5')
_RPE_TARGET_TOLERANCE = Decimal('1.0')  # ±1 RPE from target


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_effective_profile(slot: PlanSlot) -> ProgressionProfile | None:
    """Resolve the effective progression profile for a slot (slot override > plan default)."""
    if slot.progression_profile_id:
        return slot.progression_profile
    plan = slot.session.week.plan
    if plan.default_progression_profile_id:
        return plan.default_progression_profile
    return None


def _get_recent_sets(
    trainee_id: int,
    exercise_id: int,
    days: int = _LOOKBACK_DAYS,
) -> list[LiftSetLog]:
    """Fetch recent LiftSetLog entries for an exercise."""
    cutoff = date.today() - timedelta(days=days)
    return list(
        LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            exercise_id=exercise_id,
            session_date__gte=cutoff,
        ).order_by('-session_date', 'set_number')[:500]
    )


def _get_lift_max(trainee_id: int, exercise_id: int) -> LiftMax | None:
    """Fetch the LiftMax for a trainee/exercise pair."""
    try:
        return LiftMax.objects.get(trainee_id=trainee_id, exercise_id=exercise_id)
    except LiftMax.DoesNotExist:
        return None


def _round_load(load: Decimal, increment: Decimal = _DEFAULT_ROUNDING_INCREMENT) -> Decimal:
    """Round load to nearest equipment increment."""
    if increment <= 0:
        return load
    return (load / increment).quantize(Decimal('1')) * increment


def _group_sets_by_session(sets: list[LiftSetLog]) -> list[list[LiftSetLog]]:
    """Group sets by session_date."""
    sessions: dict[date, list[LiftSetLog]] = {}
    for s in sets:
        sessions.setdefault(s.session_date, []).append(s)
    return [session_sets for _, session_sets in sorted(sessions.items(), reverse=True)]


def _slot_prescription_dict(slot: PlanSlot) -> dict[str, Any]:
    """Extract current prescription from slot as dict."""
    return {
        'sets': slot.sets,
        'reps_min': slot.reps_min,
        'reps_max': slot.reps_max,
        'load_prescription_pct': str(slot.load_prescription_pct) if slot.load_prescription_pct else None,
        'rest_seconds': slot.rest_seconds,
    }


def _check_completion(
    session_sets: list[LiftSetLog],
    prescribed_sets: int,
    prescribed_reps_min: int,
) -> bool:
    """Check if a session met the prescribed sets and reps."""
    if len(session_sets) < prescribed_sets:
        return False
    for s in session_sets[:prescribed_sets]:
        if s.completed_reps < prescribed_reps_min:
            return False
    return True


def _avg_rpe(session_sets: list[LiftSetLog]) -> Decimal | None:
    """Compute average RPE for a session's sets."""
    rpe_values = [s.rpe for s in session_sets if s.rpe is not None and s.rpe > 0]
    if not rpe_values:
        return None
    return (sum(rpe_values) / len(rpe_values)).quantize(Decimal('0.1'))


def _count_consecutive_failures(
    sessions: list[list[LiftSetLog]],
    prescribed_sets: int,
    prescribed_reps_min: int,
) -> int:
    """Count consecutive failing sessions (most recent first)."""
    failures = 0
    for session_sets in sessions:
        if _check_completion(session_sets, prescribed_sets, prescribed_reps_min):
            break
        failures += 1
    return failures


# ---------------------------------------------------------------------------
# Progression Evaluators (one per type)
# ---------------------------------------------------------------------------

def _evaluate_staircase_percent(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Staircase Percent: increase % of TM per step week.
    Rules: {step_pct, work_weeks, start_pct}
    """
    rules = profile.rules
    step_pct = Decimal(str(rules.get('step_pct', 2.5)))
    work_weeks = int(rules.get('work_weeks', 4))
    start_pct = Decimal(str(rules.get('start_pct', 75)))
    deload_rules = profile.deload_rules
    failure_rules = profile.failure_rules
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Determine current week in cycle from progression events
    events = list(
        ProgressionEvent.objects.filter(plan_slot=slot)
        .order_by('-created_at')[:work_weeks + 1]
    )
    progression_count = len([e for e in events if e.event_type == 'progression'])
    current_step = progression_count % work_weeks

    # Check for failures
    consecutive_failures = _count_consecutive_failures(
        sessions, slot.sets, slot.reps_min,
    )
    max_failures = int(failure_rules.get('consecutive_failures_for_deload', 2))

    if consecutive_failures >= max_failures:
        # Trigger deload
        deload_intensity_drop = Decimal(str(deload_rules.get('intensity_drop_pct', 10)))
        new_pct = start_pct - deload_intensity_drop
        load_value = None
        if lift_max and lift_max.tm_current:
            load_value = _round_load(lift_max.tm_current * new_pct / 100)

        return NextPrescription(
            slot_id=str(slot.pk),
            exercise_id=slot.exercise_id,
            exercise_name=slot.exercise.name,
            progression_type='staircase_percent',
            event_type='deload',
            sets=max(1, slot.sets - 1),
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
            load_value=load_value,
            load_unit=load_unit,
            load_percentage=new_pct,
            reason_codes=['consecutive_failures', 'deload_triggered'],
            reason_display=f"Deload: {consecutive_failures} consecutive failures. Dropping to {new_pct}% TM.",
            confidence='high',
        )

    # Normal progression: advance to next step (M6 fix: first week uses start_pct)
    new_pct = start_pct + (step_pct * current_step)
    if new_pct > Decimal('100'):
        new_pct = Decimal('100')

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * new_pct / 100)

    # Check if it's deload week (step == work_weeks)
    is_deload_step = current_step >= work_weeks - 1
    if is_deload_step:
        deload_pct = Decimal(str(deload_rules.get('deload_pct', 65)))
        volume_drop = Decimal(str(deload_rules.get('volume_drop_pct', 40)))
        deload_sets = max(1, int(slot.sets * (100 - volume_drop) / 100))
        load_value_deload = None
        if lift_max and lift_max.tm_current:
            load_value_deload = _round_load(lift_max.tm_current * deload_pct / 100)

        return NextPrescription(
            slot_id=str(slot.pk),
            exercise_id=slot.exercise_id,
            exercise_name=slot.exercise.name,
            progression_type='staircase_percent',
            event_type='deload',
            sets=deload_sets,
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
            load_value=load_value_deload,
            load_unit=load_unit,
            load_percentage=deload_pct,
            reason_codes=['scheduled_deload', f'week_{current_step + 1}_of_{work_weeks}'],
            reason_display=f"Scheduled deload week ({current_step + 1}/{work_weeks}). {deload_pct}% TM.",
            confidence='high',
        )

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='staircase_percent',
        event_type='progression',
        sets=slot.sets,
        reps_min=slot.reps_min,
        reps_max=slot.reps_max,
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=new_pct,
        reason_codes=['step_progression', f'step_{current_step + 1}'],
        reason_display=f"Step {current_step + 1}: {new_pct}% TM.",
        confidence='high' if lift_max else 'low',
    )


def _evaluate_rep_staircase(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Rep Staircase: hold load, climb reps weekly.
    At top rung → increase load, reset reps.
    """
    rules = profile.rules
    rep_step = int(rules.get('rep_step', 1))
    load_increment_upper = Decimal(str(rules.get('load_increment_upper_lb', 5)))
    load_increment_lower = Decimal(str(rules.get('load_increment_lower_lb', 10)))
    failure_rules = profile.failure_rules

    # Determine body region for load increment
    _LOWER_BODY_MUSCLES = {
        'quads', 'hamstrings', 'glutes', 'calves', 'hip_adductors', 'hip_abductors',
        'hip_flexors', 'spinal_erectors', 'lower_back',
    }
    is_lower = (
        slot.slot_role in ('primary_compound', 'secondary_compound')
        and slot.exercise.primary_muscle_group in _LOWER_BODY_MUSCLES
    )
    load_increment = load_increment_lower if is_lower else load_increment_upper
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Get last session's performance
    if not sessions:
        return _hold_prescription(slot, 'rep_staircase', ['no_history'])

    last_session = sessions[0]
    completed = _check_completion(last_session, slot.sets, slot.reps_min)

    # Check consecutive failures
    consecutive_failures = _count_consecutive_failures(sessions, slot.sets, slot.reps_min)
    max_failures = int(failure_rules.get('consecutive_failures_for_deload', 2))

    if consecutive_failures >= max_failures:
        # Failure rule: drop load or micro-reset
        action = failure_rules.get('action', 'reduce_load')
        reduction_pct = Decimal(str(failure_rules.get('load_reduction_pct', 5)))

        current_load = _get_last_load(last_session)
        if current_load and action == 'reduce_load':
            new_load = _round_load(current_load * (100 - reduction_pct) / 100)
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='rep_staircase',
                event_type='failure',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_min,  # Reset to bottom rung
                load_value=new_load,
                load_unit=load_unit,
                load_percentage=None,
                reason_codes=['consecutive_failures', 'load_reduced'],
                reason_display=f"Failure: reducing load {reduction_pct}% and resetting reps.",
                confidence='high',
            )

    if completed:
        # Check if at top rung
        max_reps_in_last = max(s.completed_reps for s in last_session[:slot.sets])
        if max_reps_in_last >= slot.reps_max:
            # Top rung reached — increase load, reset reps
            current_load = _get_last_load(last_session)
            new_load = _round_load((current_load or Decimal('0')) + load_increment)
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='rep_staircase',
                event_type='progression',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_min,  # Reset to bottom rung
                load_value=new_load,
                load_unit=load_unit,
                load_percentage=None,
                reason_codes=['top_rung_reached', 'load_increased'],
                reason_display=f"Top rung reached ({max_reps_in_last} reps). Load +{load_increment}lb, reps reset to {slot.reps_min}.",
                confidence='high',
            )
        else:
            # Climb reps
            new_reps = min(slot.reps_max, max_reps_in_last + rep_step)
            current_load = _get_last_load(last_session)
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='rep_staircase',
                event_type='progression',
                sets=slot.sets,
                reps_min=new_reps,
                reps_max=new_reps,
                load_value=current_load,
                load_unit=load_unit,
                load_percentage=None,
                reason_codes=['rep_climb', f'reps_{new_reps}'],
                reason_display=f"Rep staircase: {max_reps_in_last} → {new_reps} reps.",
                confidence='high',
            )

    # Not completed — hold
    return _hold_prescription(slot, 'rep_staircase', ['incomplete_session'])


def _evaluate_double_progression(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Double Progression: earn reps in range, then increase load.
    When all sets hit reps_max at target RIR → increase load, reps reset to reps_min.
    """
    rules = profile.rules
    load_increment = Decimal(str(rules.get('load_increment_lb', 5)))
    target_rpe = Decimal(str(rules.get('target_rpe', 8)))  # RPE 8 = ~2 RIR
    lock_in = rules.get('lock_in', 'practical')  # strict, practical, hybrid
    failure_rules = profile.failure_rules
    load_unit = _resolve_load_unit(lift_max, sessions)

    if not sessions:
        return _hold_prescription(slot, 'double_progression', ['no_history'])

    last_session = sessions[0]

    # Check if all sets hit reps_max
    working_sets = last_session[:slot.sets]
    all_hit_top = all(s.completed_reps >= slot.reps_max for s in working_sets)

    # Check RPE/effort on target
    avg = _avg_rpe(working_sets)
    effort_ok = avg is not None and abs(avg - target_rpe) <= _RPE_TARGET_TOLERANCE

    if all_hit_top and (effort_ok or avg is None):
        # Progression: increase load, reset reps
        current_load = _get_last_load(last_session)
        new_load = _round_load((current_load or Decimal('0')) + load_increment)
        return NextPrescription(
            slot_id=str(slot.pk),
            exercise_id=slot.exercise_id,
            exercise_name=slot.exercise.name,
            progression_type='double_progression',
            event_type='progression',
            sets=slot.sets,
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
            load_value=new_load,
            load_unit=load_unit,
            load_percentage=None,
            reason_codes=['all_sets_at_top', 'effort_on_target', 'load_increased'],
            reason_display=f"All sets hit {slot.reps_max} reps. Load +{load_increment}lb → {new_load}.",
            confidence='high',
        )

    # Check failures
    consecutive_failures = _count_consecutive_failures(sessions, slot.sets, slot.reps_min)
    max_failures = int(failure_rules.get('consecutive_failures_for_deload', 2))

    if consecutive_failures >= max_failures:
        reduction_pct = Decimal(str(failure_rules.get('load_reduction_pct', 5)))
        current_load = _get_last_load(last_session)
        if current_load:
            new_load = _round_load(current_load * (100 - reduction_pct) / 100)
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='double_progression',
                event_type='failure',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_max,
                load_value=new_load,
                load_unit=load_unit,
                load_percentage=None,
                reason_codes=['consecutive_failures', 'load_reduced'],
                reason_display=f"Regression: reducing load {reduction_pct}%.",
                confidence='high',
            )

    # Hold — keep working in the rep range
    current_load = _get_last_load(last_session)
    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='double_progression',
        event_type='hold',
        sets=slot.sets,
        reps_min=slot.reps_min,
        reps_max=slot.reps_max,
        load_value=current_load,
        load_unit=load_unit,
        load_percentage=None,
        reason_codes=['working_in_range'],
        reason_display=f"Continue working in {slot.reps_min}-{slot.reps_max} rep range.",
        confidence='medium',
    )


def _evaluate_linear(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Linear Progression: add weight each session/week.
    If fail twice, deload 5-10% and rebuild.
    """
    rules = profile.rules
    increment = Decimal(str(rules.get('increment_lb', 5)))
    frequency = rules.get('frequency', 'session')  # session or weekly
    failure_rules = profile.failure_rules
    load_unit = _resolve_load_unit(lift_max, sessions)

    if not sessions:
        return _hold_prescription(slot, 'linear', ['no_history'])

    last_session = sessions[0]
    completed = _check_completion(last_session, slot.sets, slot.reps_min)

    consecutive_failures = _count_consecutive_failures(sessions, slot.sets, slot.reps_min)
    max_failures = int(failure_rules.get('consecutive_failures_for_deload', 2))

    if consecutive_failures >= max_failures:
        deload_pct = Decimal(str(failure_rules.get('deload_pct', 10)))
        current_load = _get_last_load(last_session)
        if current_load:
            new_load = _round_load(current_load * (100 - deload_pct) / 100)
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='linear',
                event_type='deload',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_max,
                load_value=new_load,
                load_unit=load_unit,
                load_percentage=None,
                reason_codes=['consecutive_failures', 'deload_triggered'],
                reason_display=f"Deload: {consecutive_failures} failures. Dropping {deload_pct}%.",
                confidence='high',
            )

    if completed:
        current_load = _get_last_load(last_session)
        new_load = _round_load((current_load or Decimal('0')) + increment)
        return NextPrescription(
            slot_id=str(slot.pk),
            exercise_id=slot.exercise_id,
            exercise_name=slot.exercise.name,
            progression_type='linear',
            event_type='progression',
            sets=slot.sets,
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
            load_value=new_load,
            load_unit=load_unit,
            load_percentage=None,
            reason_codes=['session_completed', 'load_increased'],
            reason_display=f"Completed. Load +{increment}lb → {new_load}.",
            confidence='high',
        )

    return _hold_prescription(slot, 'linear', ['incomplete_session'])


def _evaluate_wave_by_month(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Wave-by-Month: 4-week wave with accumulation→build→intensify→deload.
    Rules: {week_percentages: [75, 80, 85, 65], week_reps: [10, 8, 5, 10]}
    """
    rules = profile.rules
    week_percentages = rules.get('week_percentages', [75, 80, 85, 65])
    week_reps = rules.get('week_reps', [10, 8, 5, 10])
    week_sets = rules.get('week_sets', [5, 4, 5, 3])
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Determine current week in wave from progression events (only count progression/deload)
    events = list(
        ProgressionEvent.objects.filter(
            plan_slot=slot,
            event_type__in=['progression', 'deload'],
        ).order_by('-created_at')[:8]
    )
    progression_count = len(events)
    wave_length = len(week_percentages)
    current_week = progression_count % wave_length

    target_pct = Decimal(str(week_percentages[current_week]))
    target_reps = int(week_reps[current_week]) if current_week < len(week_reps) else slot.reps_min
    target_sets = int(week_sets[current_week]) if current_week < len(week_sets) else slot.sets
    is_deload = current_week == wave_length - 1

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * target_pct / 100)

    event_type = 'deload' if is_deload else 'progression'
    week_names = ['Accumulation', 'Build', 'Intensify', 'Deload']
    week_name = week_names[current_week] if current_week < len(week_names) else f'Week {current_week + 1}'

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='wave_by_month',
        event_type=event_type,
        sets=target_sets,
        reps_min=target_reps,
        reps_max=target_reps,
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=target_pct,
        reason_codes=[f'wave_week_{current_week + 1}', week_name.lower()],
        reason_display=f"{week_name}: {target_sets}×{target_reps} @ {target_pct}% TM.",
        confidence='high' if lift_max else 'low',
    )


# ---------------------------------------------------------------------------
# Helper: hold/no-change prescription
# ---------------------------------------------------------------------------

def _hold_prescription(
    slot: PlanSlot,
    progression_type: str,
    reason_codes: list[str],
    load_unit: str = 'lb',
) -> NextPrescription:
    """Return a hold prescription (no changes)."""
    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type=progression_type,
        event_type='hold',
        sets=slot.sets,
        reps_min=slot.reps_min,
        reps_max=slot.reps_max,
        load_value=None,
        load_unit=load_unit,
        load_percentage=slot.load_prescription_pct,
        reason_codes=reason_codes,
        reason_display="Hold: no changes to current prescription.",
        confidence='low',
    )


def _get_last_load(session_sets: list[LiftSetLog]) -> Decimal | None:
    """Get the canonical load from the most recent session's working sets."""
    for s in session_sets:
        if s.canonical_external_load_value and s.canonical_external_load_value > 0:
            return s.canonical_external_load_value
    return None


def _resolve_load_unit(
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> str:
    """Determine load unit from LiftMax or recent set logs. Defaults to 'lb'."""
    if lift_max and hasattr(lift_max, 'load_unit') and lift_max.load_unit:
        return str(lift_max.load_unit)
    for session_sets in sessions:
        for s in session_sets:
            if hasattr(s, 'canonical_external_load_unit') and s.canonical_external_load_unit:
                return str(s.canonical_external_load_unit)
    return 'lb'


# ---------------------------------------------------------------------------
# Evaluator dispatch
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Periodization evaluators (v6.5 §8B)
# ---------------------------------------------------------------------------

def _evaluate_dup(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Daily Undulating Periodization: pick emphasis based on session's day-of-week
    within the training week (uses session index as proxy).
    """
    rules = profile.rules
    rotation: list[str] = rules.get('day_emphasis_rotation', ['strength', 'hypertrophy', 'power'])
    rep_ranges: dict[str, list[int]] = rules.get('rep_ranges', {})
    intensity_map: dict[str, int] = rules.get('intensity_pct', {})
    sets_map: dict[str, int] = rules.get('sets', {})
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Determine which emphasis slot based on session order within week
    session_index = slot.session.order if slot.session else 0
    emphasis = rotation[session_index % len(rotation)]

    reps = rep_ranges.get(emphasis, [6, 10])
    pct = Decimal(str(intensity_map.get(emphasis, 75)))
    target_sets = sets_map.get(emphasis, 4)

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * pct / 100)

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='dup',
        event_type='progression',
        sets=target_sets,
        reps_min=reps[0],
        reps_max=reps[1] if len(reps) > 1 else reps[0],
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=pct,
        reason_codes=['dup', f'emphasis_{emphasis}'],
        reason_display=f"DUP {emphasis.title()} day — {target_sets}x{reps[0]}-{reps[1] if len(reps) > 1 else reps[0]} @{pct}%",
        confidence='high',
    )


def _evaluate_wup(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Weekly Undulating Periodization: pick emphasis based on week number in cycle.
    """
    rules = profile.rules
    rotation: list[str] = rules.get('week_emphasis_rotation', ['volume', 'moderate', 'heavy', 'deload'])
    week_config: dict[str, dict[str, int]] = rules.get('week_config', {})
    load_unit = _resolve_load_unit(lift_max, sessions)

    week_index = (slot.session.week.week_number - 1) % len(rotation) if slot.session and slot.session.week else 0
    emphasis = rotation[week_index]
    config = week_config.get(emphasis, {'sets': 3, 'reps': 8, 'pct': 70})

    pct = Decimal(str(config.get('pct', 70)))
    target_sets = config.get('sets', 3)
    target_reps = config.get('reps', 8)

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * pct / 100)

    event_type = 'deload' if emphasis == 'deload' else 'progression'

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='wup',
        event_type=event_type,
        sets=target_sets,
        reps_min=target_reps,
        reps_max=target_reps,
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=pct,
        reason_codes=['wup', f'week_{emphasis}'],
        reason_display=f"WUP {emphasis.title()} week — {target_sets}x{target_reps} @{pct}%",
        confidence='high',
    )


def _evaluate_block(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Block Periodization: determine current block from absolute week number.
    """
    rules = profile.rules
    blocks: list[dict[str, object]] = rules.get('blocks', [])
    load_unit = _resolve_load_unit(lift_max, sessions)

    absolute_week = slot.session.week.week_number if slot.session and slot.session.week else 1

    # Determine which block we're in
    accumulated = 0
    current_block = blocks[-1] if blocks else {'name': 'accumulation', 'weeks': 4, 'intensity_range_pct': [65, 75], 'rep_range': [6, 12], 'volume_multiplier': 1.0}
    for block in blocks:
        block_weeks = int(block.get('weeks', 4))  # type: ignore[arg-type]
        if absolute_week <= accumulated + block_weeks:
            current_block = block
            break
        accumulated += block_weeks

    intensity_range: list[int] = current_block.get('intensity_range_pct', [70, 80])  # type: ignore[assignment]
    rep_range: list[int] = current_block.get('rep_range', [6, 10])  # type: ignore[assignment]
    vol_mult = Decimal(str(current_block.get('volume_multiplier', 1.0)))
    block_name: str = str(current_block.get('name', 'unknown'))

    # Use midpoint of intensity range
    pct = Decimal(str((intensity_range[0] + intensity_range[1]) // 2))
    target_sets = max(1, int(slot.sets * vol_mult))

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * pct / 100)

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='block',
        event_type='progression',
        sets=target_sets,
        reps_min=rep_range[0],
        reps_max=rep_range[1] if len(rep_range) > 1 else rep_range[0],
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=pct,
        reason_codes=['block', f'phase_{block_name}'],
        reason_display=f"Block {block_name.title()} — {target_sets}x{rep_range[0]}-{rep_range[1] if len(rep_range) > 1 else rep_range[0]} @{pct}%",
        confidence='high',
    )


def _evaluate_concurrent(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Concurrent: determine quality from session family/role, apply double progression
    for primary quality and hold for secondary.
    """
    rules = profile.rules
    qualities: list[dict[str, object]] = rules.get('qualities', [])
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Match slot's session family to a quality
    session_family = slot.session.session_family if slot.session else 'strength'
    matched_quality: dict[str, object] | None = None
    for q in qualities:
        if str(q.get('name', '')).lower() in session_family.lower():
            matched_quality = q
            break
    if matched_quality is None and qualities:
        matched_quality = qualities[0]

    is_primary = matched_quality is not None and int(matched_quality.get('priority', 99)) == 1  # type: ignore[arg-type]

    # Primary quality: progress (use double progression logic)
    # Secondary quality: hold current prescription
    if is_primary and sessions:
        last_session = sessions[0]
        avg_rpe = _avg_rpe(last_session)
        completed = _check_completion(last_session, slot.sets, slot.reps_min)
        if completed and avg_rpe is not None and avg_rpe <= Decimal('9'):
            load_value = None
            if lift_max and lift_max.tm_current:
                load_value = _round_load(lift_max.tm_current * Decimal('0.80'))
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type='concurrent',
                event_type='progression',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_max,
                load_value=load_value,
                load_unit=load_unit,
                load_percentage=Decimal('80'),
                reason_codes=['concurrent', 'primary_quality', 'progress'],
                reason_display="Concurrent primary quality — progressing.",
                confidence='high',
            )

    return _hold_prescription(slot, 'concurrent', ['concurrent', 'hold_secondary'])


def _evaluate_conjugate(
    slot: PlanSlot,
    profile: ProgressionProfile,
    lift_max: LiftMax | None,
    sessions: list[list[LiftSetLog]],
) -> NextPrescription:
    """
    Conjugate (ME/DE/RE): determine effort type from session stress/family.
    ME: heavy top set. DE: speed work. RE: higher reps.
    """
    rules = profile.rules
    rotations: dict[str, dict[str, object]] = rules.get('rotations', {})
    load_unit = _resolve_load_unit(lift_max, sessions)

    # Determine effort type from session day_stress
    day_stress = slot.session.day_stress if slot.session else 'high_neural'
    if day_stress == 'high_neural':
        effort = 'max_effort'
    elif day_stress == 'low_neural':
        effort = 'repeated_effort'
    else:
        effort = 'dynamic_effort'

    config = rotations.get(effort, {})
    rep_range: list[int] = config.get('rep_range', [3, 5])  # type: ignore[assignment]

    if effort == 'max_effort':
        pct = Decimal('90')
        target_sets = 1
        reps = rep_range
    elif effort == 'dynamic_effort':
        pct = Decimal(str(config.get('intensity_pct', 60)))
        set_rep_str = str(config.get('set_rep', '8x3'))
        parts = set_rep_str.split('x')
        target_sets = int(parts[0]) if len(parts) > 1 else 8
        reps = [int(parts[1])] * 2 if len(parts) > 1 else [3, 3]
    else:
        pct = Decimal('70')
        target_sets = 3
        reps = rep_range

    load_value = None
    if lift_max and lift_max.tm_current:
        load_value = _round_load(lift_max.tm_current * pct / 100)

    return NextPrescription(
        slot_id=str(slot.pk),
        exercise_id=slot.exercise_id,
        exercise_name=slot.exercise.name,
        progression_type='conjugate',
        event_type='progression',
        sets=target_sets,
        reps_min=reps[0],
        reps_max=reps[1] if len(reps) > 1 else reps[0],
        load_value=load_value,
        load_unit=load_unit,
        load_percentage=pct,
        reason_codes=['conjugate', f'{effort}'],
        reason_display=f"Conjugate {effort.replace('_', ' ').title()} — {target_sets}x{reps[0]} @{pct}%",
        confidence='high',
    )


_EVALUATORS = {
    'staircase_percent': _evaluate_staircase_percent,
    'rep_staircase': _evaluate_rep_staircase,
    'double_progression': _evaluate_double_progression,
    'linear': _evaluate_linear,
    'wave_by_month': _evaluate_wave_by_month,
    'dup': _evaluate_dup,
    'wup': _evaluate_wup,
    'block': _evaluate_block,
    'concurrent': _evaluate_concurrent,
    'conjugate': _evaluate_conjugate,
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def compute_next_prescription(
    slot: PlanSlot,
    trainee_id: int,
) -> NextPrescription:
    """
    Compute the next session prescription for a slot based on its progression profile.

    Reads LiftSetLog history and LiftMax, evaluates the progression profile rules,
    and returns a deterministic NextPrescription.
    """
    profile = _get_effective_profile(slot)
    if profile is None:
        return _hold_prescription(slot, 'none', ['no_progression_profile'])

    # Check for gap in training (>2 weeks since last session)
    recent_sets = _get_recent_sets(trainee_id, slot.exercise_id, days=_LOOKBACK_DAYS)
    sessions = _group_sets_by_session(recent_sets)

    if sessions:
        last_date = sessions[0][0].session_date
        gap_days = (date.today() - last_date).days
        if gap_days > _GAP_THRESHOLD_DAYS:
            # Deload after long gap
            lift_max = _get_lift_max(trainee_id, slot.exercise_id)
            gap_load_unit = _resolve_load_unit(lift_max, sessions)
            load_value = None
            if lift_max and lift_max.tm_current:
                load_value = _round_load(lift_max.tm_current * Decimal('0.90'))
            return NextPrescription(
                slot_id=str(slot.pk),
                exercise_id=slot.exercise_id,
                exercise_name=slot.exercise.name,
                progression_type=profile.progression_type,
                event_type='deload',
                sets=slot.sets,
                reps_min=slot.reps_min,
                reps_max=slot.reps_max,
                load_value=load_value,
                load_unit=gap_load_unit,
                load_percentage=Decimal('90'),
                reason_codes=['training_gap', f'gap_{gap_days}_days'],
                reason_display=f"Training gap ({gap_days} days). Resuming at 90% TM.",
                confidence='medium',
            )

    lift_max = _get_lift_max(trainee_id, slot.exercise_id)

    evaluator = _EVALUATORS.get(profile.progression_type)
    if evaluator is None:
        return _hold_prescription(slot, profile.progression_type, ['unsupported_type'])

    return evaluator(slot, profile, lift_max, sessions)


def evaluate_progression_readiness(
    slot: PlanSlot,
    trainee_id: int,
) -> ProgressionReadiness:
    """Evaluate whether a slot is ready for progression."""
    blockers: list[str] = []

    profile = _get_effective_profile(slot)
    if profile is None:
        blockers.append('no_progression_profile')

    lift_max = _get_lift_max(trainee_id, slot.exercise_id)
    if lift_max is None:
        blockers.append('no_max')

    recent_sets = _get_recent_sets(trainee_id, slot.exercise_id)
    sessions = _group_sets_by_session(recent_sets)

    if len(sessions) < _MIN_SESSIONS_FOR_PROGRESSION:
        blockers.append('insufficient_history')

    last_date: str | None = None
    gap_detected = False
    if sessions:
        last_date = str(sessions[0][0].session_date)
        gap_days = (date.today() - sessions[0][0].session_date).days
        if gap_days > _GAP_THRESHOLD_DAYS:
            blockers.append('gap_detected')
            gap_detected = True

    # Average RPE from most recent session
    avg = None
    if sessions:
        avg = _avg_rpe(sessions[0])

    # Completion rate
    completion_rate = None
    if sessions:
        completed_count = sum(
            1 for sess in sessions
            if _check_completion(sess, slot.sets, slot.reps_min)
        )
        completion_rate = Decimal(str(completed_count)) / Decimal(str(len(sessions))) * 100

    consecutive_failures = 0
    if sessions:
        consecutive_failures = _count_consecutive_failures(sessions, slot.sets, slot.reps_min)

    # Check deload week
    if slot.session.week.is_deload:
        blockers.append('deload_week')

    return ProgressionReadiness(
        slot_id=str(slot.pk),
        is_ready=len(blockers) == 0,
        blockers=blockers,
        recent_sessions=len(sessions),
        last_session_date=last_date,
        avg_rpe=avg,
        sets_completed_rate=completion_rate,
        consecutive_failures=consecutive_failures,
    )


def apply_progression(
    *,
    slot: PlanSlot,
    prescription: NextPrescription,
    actor_id: int | None = None,
    trainee_id: int,
    actor_type: str = 'user',
    reason: str = '',
) -> ProgressionEventResult:
    """
    Apply a computed prescription to a slot. Creates ProgressionEvent + DecisionLog.
    """
    profile = _get_effective_profile(slot)

    with transaction.atomic():
        old_prescription = _slot_prescription_dict(slot)

        new_prescription = {
            'sets': prescription.sets,
            'reps_min': prescription.reps_min,
            'reps_max': prescription.reps_max,
            'load_value': str(prescription.load_value) if prescription.load_value else None,
            'load_unit': prescription.load_unit,
            'load_percentage': str(prescription.load_percentage) if prescription.load_percentage else None,
        }

        # Update slot prescription
        slot.sets = prescription.sets
        slot.reps_min = prescription.reps_min
        slot.reps_max = prescription.reps_max
        slot.load_prescription_pct = prescription.load_percentage
        slot.save(update_fields=[
            'sets', 'reps_min', 'reps_max', 'load_prescription_pct', 'updated_at',
        ])

        # Create DecisionLog
        resolved_actor_type = (
            DecisionLog.ActorType.SYSTEM if actor_type == 'system'
            else DecisionLog.ActorType.USER
        )
        log = DecisionLog.objects.create(
            actor_type=resolved_actor_type,
            actor_id=actor_id,
            decision_type='progression_applied',
            context={
                'slot_id': str(slot.pk),
                'exercise_id': slot.exercise_id,
                'trainee_id': trainee_id,
                'reason': reason,
            },
            inputs_snapshot={
                'progression_type': prescription.progression_type,
                'event_type': prescription.event_type,
                'old_prescription': old_prescription,
            },
            constraints_applied={
                'profile_id': str(profile.pk) if profile else None,
                'profile_name': profile.name if profile else None,
            },
            options_considered=[],
            final_choice=new_prescription,
            reason_codes=prescription.reason_codes,
        )

        # Create ProgressionEvent
        event = ProgressionEvent.objects.create(
            trainee_id=trainee_id,
            exercise_id=slot.exercise_id,
            plan_slot=slot,
            event_type=prescription.event_type,
            old_prescription=old_prescription,
            new_prescription=new_prescription,
            reason_codes=prescription.reason_codes,
            decision_log=log,
            progression_profile=profile,
        )

    return ProgressionEventResult(
        event_id=str(event.pk),
        slot_id=str(slot.pk),
        event_type=prescription.event_type,
        old_prescription=old_prescription,
        new_prescription=new_prescription,
        reason_codes=prescription.reason_codes,
        decision_log_id=str(log.pk),
    )


def get_progression_history(slot: PlanSlot) -> list[ProgressionEvent]:
    """Get all progression events for a slot, ordered newest first."""
    return list(
        ProgressionEvent.objects.filter(plan_slot=slot)
        .select_related('decision_log', 'progression_profile')
        .order_by('-created_at')[:50]
    )

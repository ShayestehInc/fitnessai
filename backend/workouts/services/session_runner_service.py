"""
Session Runner Service — v6.5 Step 8.

Runtime engine for trainee workout sessions. Manages the lifecycle of an
ActiveSession from start through set-by-set logging to completion/abandonment.

All decisions are logged via DecisionLog. All state transitions use
select_for_update() to prevent race conditions.
"""
from __future__ import annotations

import datetime
import logging
from dataclasses import dataclass
from datetime import timedelta
from decimal import Decimal
from typing import Any

from django.db import IntegrityError, transaction
from django.utils import timezone

from workouts.models import (
    ActiveSession,
    ActiveSetLog,
    DecisionLog,
    Exercise,
    LiftSetLog,
    PlanSession,
    PlanSlot,
)
from workouts.services.progression_engine_service import (
    NextPrescription,
    ProgressionEventResult,
    apply_progression,
    compute_next_prescription,
)
from workouts.services.rest_timer_service import get_rest_duration

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_STALE_SESSION_HOURS = 4


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SetStatus:
    """Status of a single set within a slot."""
    set_log_id: str
    set_number: int
    status: str  # pending | completed | skipped
    prescribed_reps_min: int
    prescribed_reps_max: int
    prescribed_load: Decimal | None
    prescribed_load_unit: str
    completed_reps: int | None
    completed_load_value: Decimal | None
    completed_load_unit: str
    rpe: Decimal | None
    rest_prescribed_seconds: int
    rest_actual_seconds: int | None
    notes: str


@dataclass(frozen=True)
class SlotStatus:
    """Status of a slot (exercise) within a session."""
    slot_id: str
    exercise_name: str
    exercise_id: int
    order: int
    slot_role: str
    is_current: bool
    sets: list[SetStatus]


@dataclass(frozen=True)
class SessionStatus:
    """Full status of an active session."""
    active_session_id: str
    status: str
    trainee_id: int
    plan_session_id: str | None
    plan_session_label: str
    current_slot_index: int
    total_slots: int
    slots: list[SlotStatus]
    started_at: str | None
    completed_at: str | None
    progress_pct: float
    total_sets: int
    completed_sets: int
    skipped_sets: int
    pending_sets: int
    elapsed_seconds: int | None


@dataclass(frozen=True)
class SessionSummary:
    """Summary returned on session completion/abandonment."""
    active_session_id: str
    status: str
    total_sets: int
    completed_sets: int
    skipped_sets: int
    duration_seconds: int | None
    progression_results: list[dict[str, Any]]


# ---------------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------------

class SessionError(Exception):
    """Base error for session runner operations."""

    def __init__(self, error_code: str, message: str, extra: dict[str, Any] | None = None) -> None:
        self.error_code = error_code
        self.message = message
        self.extra = extra or {}
        super().__init__(message)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def start_session(
    trainee_id: int,
    plan_session_id: str,
) -> SessionStatus:
    """
    Start a new workout session for a trainee.

    Pre-populates ActiveSetLog entries from PlanSlot prescriptions using
    the progression engine. Enforces one active session per trainee.

    Raises SessionError on validation failures.
    """
    # Auto-abandon stale sessions first
    _auto_abandon_stale_sessions(trainee_id)

    # Check for existing active session
    existing = ActiveSession.objects.filter(
        trainee_id=trainee_id,
        status=ActiveSession.Status.IN_PROGRESS,
    ).first()
    if existing is not None:
        raise SessionError(
            error_code='active_session_exists',
            message='You have an active session. Complete or abandon it first.',
            extra={'active_session_id': str(existing.pk)},
        )

    # Validate plan session and ownership (C1: IDOR fix)
    try:
        plan_session = PlanSession.objects.select_related('week__plan').get(
            pk=plan_session_id,
        )
    except PlanSession.DoesNotExist:
        raise SessionError(
            error_code='plan_session_not_found',
            message='Plan session not found.',
        )

    # Verify the plan session belongs to this trainee via PlanSession -> PlanWeek -> TrainingPlan
    if plan_session.week.plan.trainee_id != trainee_id:
        raise SessionError(
            error_code='plan_session_not_found',
            message='Plan session not found.',
        )

    # Validate plan session has slots
    slots = list(
        PlanSlot.objects.filter(session=plan_session)
        .select_related('exercise', 'set_structure_modality', 'progression_profile')
        .order_by('order')
    )
    if not slots:
        raise SessionError(
            error_code='no_exercises_in_session',
            message='This session has no exercises and cannot be started.',
        )

    now = timezone.now()

    with transaction.atomic():
        try:
            active_session = ActiveSession.objects.create(
                trainee_id=trainee_id,
                plan_session=plan_session,
                status=ActiveSession.Status.IN_PROGRESS,
                started_at=now,
                current_slot_index=0,
            )
        except IntegrityError:
            # Race condition: another request created an active session concurrently
            raise SessionError(
                error_code='active_session_exists',
                message='You have an active session. Complete or abandon it first.',
            )

        # Pre-populate set logs from slot prescriptions
        set_logs_to_create: list[ActiveSetLog] = []
        for slot in slots:
            prescription = _get_prescription_for_slot(slot, trainee_id)
            for set_num in range(1, slot.sets + 1):
                is_last = (set_num == slot.sets)
                rest = get_rest_duration(
                    plan_slot=slot,
                    set_number=set_num,
                    is_last_set_of_slot=is_last,
                )
                set_logs_to_create.append(
                    ActiveSetLog(
                        active_session=active_session,
                        plan_slot=slot,
                        exercise=slot.exercise,
                        set_number=set_num,
                        prescribed_reps_min=prescription.reps_min,
                        prescribed_reps_max=prescription.reps_max,
                        prescribed_load=prescription.load_value,
                        prescribed_load_unit=prescription.load_unit,
                        completed_load_unit=prescription.load_unit,
                        rest_prescribed_seconds=rest.rest_seconds,
                        status=ActiveSetLog.Status.PENDING,
                    )
                )
        ActiveSetLog.objects.bulk_create(set_logs_to_create)

        # Create DecisionLog
        DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.USER,
            actor_id=trainee_id,
            decision_type='session_started',
            context={
                'active_session_id': str(active_session.pk),
                'plan_session_id': str(plan_session.pk),
                'plan_session_label': plan_session.label,
            },
            inputs_snapshot={
                'total_slots': len(slots),
                'total_sets': len(set_logs_to_create),
            },
            final_choice={'action': 'start_session'},
            reason_codes=['session_started'],
        )

    return get_session_status(str(active_session.pk))


def get_session_status(active_session_id: str) -> SessionStatus:
    """
    Get the full status of an active session including all slots and sets.
    """
    session = _get_session_with_logs(active_session_id)
    return _build_session_status(session)


def get_active_session(trainee_id: int) -> SessionStatus | None:
    """
    Get the trainee's current in-progress session, or None.
    Auto-abandons stale sessions first.
    """
    _auto_abandon_stale_sessions(trainee_id)

    session = (
        ActiveSession.objects
        .filter(trainee_id=trainee_id, status=ActiveSession.Status.IN_PROGRESS)
        .first()
    )
    if session is None:
        return None
    return get_session_status(str(session.pk))


def log_set(
    active_session_id: str,
    *,
    slot_id: str,
    set_number: int,
    completed_reps: int,
    load_value: Decimal | None = None,
    load_unit: str = 'lb',
    rpe: Decimal | None = None,
    rest_actual_seconds: int | None = None,
    notes: str = '',
) -> SessionStatus:
    """
    Log a completed set in an active session.

    Validates session is in_progress, finds the matching pending ActiveSetLog,
    marks it completed with actual performance data, and auto-advances the
    current_slot_index when all sets for the current slot are done.

    Returns updated full session status.
    """
    with transaction.atomic():
        session = (
            ActiveSession.objects
            .select_for_update(of=('self',))
            .select_related('plan_session', 'trainee')
            .get(pk=active_session_id)
        )
        _validate_session_mutable(session)

        set_log, all_set_logs = _fetch_and_find_pending_set(session, slot_id, set_number)

        now = timezone.now()
        set_log.status = ActiveSetLog.Status.COMPLETED
        set_log.completed_reps = completed_reps
        set_log.completed_load_value = load_value
        set_log.completed_load_unit = load_unit
        set_log.rpe = rpe
        set_log.rest_actual_seconds = rest_actual_seconds
        set_log.notes = notes
        set_log.set_completed_at = now
        set_log.save(update_fields=[
            'status', 'completed_reps', 'completed_load_value',
            'completed_load_unit', 'rpe', 'rest_actual_seconds',
            'notes', 'set_completed_at',
        ])

        # Auto-advance current_slot_index using in-memory set_logs (M2 fix)
        _maybe_advance_slot_index(session, set_logs=all_set_logs)

    # Build status using the in-memory set_logs to avoid a stale re-fetch
    return _build_session_status(session, set_logs=all_set_logs)


def skip_set(
    active_session_id: str,
    *,
    slot_id: str,
    set_number: int,
    reason: str = '',
) -> SessionStatus:
    """
    Skip a set in an active session.
    """
    with transaction.atomic():
        session = (
            ActiveSession.objects
            .select_for_update(of=('self',))
            .select_related('plan_session', 'trainee')
            .get(pk=active_session_id)
        )
        _validate_session_mutable(session)

        set_log, all_set_logs = _fetch_and_find_pending_set(session, slot_id, set_number)

        set_log.status = ActiveSetLog.Status.SKIPPED
        set_log.skip_reason = reason
        set_log.set_completed_at = timezone.now()
        set_log.save(update_fields=['status', 'skip_reason', 'set_completed_at'])

        # Use in-memory set_logs (M2 fix)
        _maybe_advance_slot_index(session, set_logs=all_set_logs)

    # Build status using the in-memory set_logs to avoid a stale re-fetch
    return _build_session_status(session, set_logs=all_set_logs)


def complete_session(
    active_session_id: str,
    actor_id: int,
) -> SessionSummary:
    """
    Complete an active session.

    Validates all sets are completed or skipped. Creates LiftSetLog entries
    for completed sets and triggers progression evaluation per slot.
    """
    with transaction.atomic():
        session = (
            ActiveSession.objects
            .select_for_update(of=('self',))
            .select_related('plan_session')
            .get(pk=active_session_id)
        )
        _validate_session_mutable(session)

        set_logs = list(
            ActiveSetLog.objects
            .filter(active_session=session)
            .select_related('plan_slot', 'plan_slot__exercise', 'exercise',
                            'plan_slot__progression_profile')
            .order_by('plan_slot__order', 'set_number')
        )

        pending_count = sum(1 for sl in set_logs if sl.status == ActiveSetLog.Status.PENDING)
        if pending_count > 0:
            raise SessionError(
                error_code='pending_sets_remaining',
                message=f'{pending_count} sets are still pending. Complete or skip them first.',
                extra={'count': pending_count},
            )

        now = timezone.now()
        session.status = ActiveSession.Status.COMPLETED
        session.completed_at = now
        session.save(update_fields=['status', 'completed_at'])

        # Create LiftSetLog entries for completed sets
        completed_logs = [sl for sl in set_logs if sl.status == ActiveSetLog.Status.COMPLETED]
        session_date = (session.started_at or now).date()

        lift_set_logs = _create_lift_set_logs(completed_logs, session.trainee_id, session_date)

        # Trigger progression evaluation per slot (only slots with completed sets)
        progression_results = _run_progression_evaluation(
            set_logs=set_logs,
            trainee_id=session.trainee_id,
            actor_id=actor_id,
            lift_set_logs=lift_set_logs,
        )

        # DecisionLog
        DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.USER,
            actor_id=actor_id,
            decision_type='session_completed',
            context={
                'active_session_id': str(session.pk),
                'plan_session_id': str(session.plan_session_id) if session.plan_session_id else None,
            },
            inputs_snapshot={
                'total_sets': len(set_logs),
                'completed_sets': len(completed_logs),
                'skipped_sets': len(set_logs) - len(completed_logs),
            },
            final_choice={'action': 'complete_session'},
            reason_codes=['session_completed'],
        )

    duration = None
    if session.started_at and session.completed_at:
        duration = int((session.completed_at - session.started_at).total_seconds())

    return SessionSummary(
        active_session_id=str(session.pk),
        status=session.status,
        total_sets=len(set_logs),
        completed_sets=len(completed_logs),
        skipped_sets=len(set_logs) - len(completed_logs),
        duration_seconds=duration,
        progression_results=progression_results,
    )


def abandon_session(
    active_session_id: str,
    actor_id: int,
    reason: str = '',
) -> SessionSummary:
    """
    Abandon an active session. Saves completed sets to LiftSetLog but does
    NOT trigger progression evaluation.
    """
    with transaction.atomic():
        session = (
            ActiveSession.objects
            .select_for_update(of=('self',))
            .select_related('plan_session')
            .get(pk=active_session_id)
        )
        _validate_session_mutable(session)

        now = timezone.now()
        session.status = ActiveSession.Status.ABANDONED
        session.completed_at = now
        session.abandon_reason = reason
        session.save(update_fields=['status', 'completed_at', 'abandon_reason'])

        set_logs = list(
            ActiveSetLog.objects
            .filter(active_session=session)
            .select_related('plan_slot', 'exercise')
            .order_by('plan_slot__order', 'set_number')
        )

        # Save completed sets to LiftSetLog (partial data is real data)
        completed_logs = [sl for sl in set_logs if sl.status == ActiveSetLog.Status.COMPLETED]
        session_date = (session.started_at or now).date()
        _create_lift_set_logs(completed_logs, session.trainee_id, session_date)

        # Do NOT run progression evaluation on abandonment
        skipped_count = sum(1 for sl in set_logs if sl.status == ActiveSetLog.Status.SKIPPED)

        DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.USER,
            actor_id=actor_id,
            decision_type='session_abandoned',
            context={
                'active_session_id': str(session.pk),
                'plan_session_id': str(session.plan_session_id) if session.plan_session_id else None,
                'reason': reason,
            },
            inputs_snapshot={
                'total_sets': len(set_logs),
                'completed_sets': len(completed_logs),
                'skipped_sets': skipped_count,
                'pending_sets': len(set_logs) - len(completed_logs) - skipped_count,
            },
            final_choice={'action': 'abandon_session'},
            reason_codes=['session_abandoned'],
        )

    duration = None
    if session.started_at and session.completed_at:
        duration = int((session.completed_at - session.started_at).total_seconds())

    return SessionSummary(
        active_session_id=str(session.pk),
        status=session.status,
        total_sets=len(set_logs),
        completed_sets=len(completed_logs),
        skipped_sets=skipped_count,
        duration_seconds=duration,
        progression_results=[],
    )


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _get_session_with_logs(active_session_id: str) -> ActiveSession:
    """Fetch an ActiveSession with all related set logs, prefetched."""
    return (
        ActiveSession.objects
        .select_related('plan_session', 'trainee')
        .prefetch_related(
            'set_logs__plan_slot',
            'set_logs__exercise',
        )
        .get(pk=active_session_id)
    )


def _build_session_status(
    session: ActiveSession,
    set_logs: list[ActiveSetLog] | None = None,
) -> SessionStatus:
    """Build a SessionStatus dataclass from an ActiveSession.

    If ``set_logs`` is provided, uses them directly (avoids a redundant DB
    query when the caller already holds the data — e.g. inside log_set/skip_set).
    Otherwise falls back to ``session.set_logs.all()`` which uses the prefetch
    cache if populated, or hits the DB.
    """
    all_set_logs: list[ActiveSetLog] = set_logs if set_logs is not None else list(session.set_logs.all())

    # Group by slot
    slot_map: dict[str | None, list[ActiveSetLog]] = {}
    for sl in all_set_logs:
        key = str(sl.plan_slot_id) if sl.plan_slot_id else None
        slot_map.setdefault(key, []).append(sl)

    # Build slot statuses — order by plan_slot.order
    # Get unique slots in order
    seen_slots: dict[str | None, tuple[int, str, int, str]] = {}
    for sl in all_set_logs:
        key = str(sl.plan_slot_id) if sl.plan_slot_id else None
        if key not in seen_slots:
            order = sl.plan_slot.order if sl.plan_slot else 0
            exercise_name = sl.exercise.name if sl.exercise else 'Unknown'
            exercise_id = sl.exercise_id
            slot_role = sl.plan_slot.slot_role if sl.plan_slot else 'accessory'
            seen_slots[key] = (order, exercise_name, exercise_id, slot_role)

    sorted_slot_keys = sorted(seen_slots.keys(), key=lambda k: seen_slots[k][0] if k else 0)

    slot_statuses: list[SlotStatus] = []
    for idx, slot_key in enumerate(sorted_slot_keys):
        order, exercise_name, exercise_id, slot_role = seen_slots[slot_key]
        slot_set_logs = sorted(
            slot_map.get(slot_key, []),
            key=lambda s: s.set_number,
        )
        sets = [
            SetStatus(
                set_log_id=str(sl.pk),
                set_number=sl.set_number,
                status=sl.status,
                prescribed_reps_min=sl.prescribed_reps_min,
                prescribed_reps_max=sl.prescribed_reps_max,
                prescribed_load=sl.prescribed_load,
                prescribed_load_unit=sl.prescribed_load_unit,
                completed_reps=sl.completed_reps,
                completed_load_value=sl.completed_load_value,
                completed_load_unit=sl.completed_load_unit,
                rpe=sl.rpe,
                rest_prescribed_seconds=sl.rest_prescribed_seconds,
                rest_actual_seconds=sl.rest_actual_seconds,
                notes=sl.notes,
            )
            for sl in slot_set_logs
        ]
        slot_statuses.append(SlotStatus(
            slot_id=slot_key or '',
            exercise_name=exercise_name,
            exercise_id=exercise_id,
            order=order,
            slot_role=slot_role,
            is_current=(idx == session.current_slot_index),
            sets=sets,
        ))

    total_sets = len(all_set_logs)
    completed = sum(1 for sl in all_set_logs if sl.status == ActiveSetLog.Status.COMPLETED)
    skipped = sum(1 for sl in all_set_logs if sl.status == ActiveSetLog.Status.SKIPPED)
    pending = total_sets - completed - skipped
    done = completed + skipped
    progress_pct = round((done / total_sets * 100), 1) if total_sets > 0 else 0.0

    elapsed: int | None = None
    if session.started_at:
        end = session.completed_at or timezone.now()
        elapsed = int((end - session.started_at).total_seconds())

    return SessionStatus(
        active_session_id=str(session.pk),
        status=session.status,
        trainee_id=session.trainee_id,
        plan_session_id=str(session.plan_session_id) if session.plan_session_id else None,
        plan_session_label=session.plan_session.label if session.plan_session else 'Unknown',
        current_slot_index=session.current_slot_index,
        total_slots=len(slot_statuses),
        slots=slot_statuses,
        started_at=session.started_at.isoformat() if session.started_at else None,
        completed_at=session.completed_at.isoformat() if session.completed_at else None,
        progress_pct=progress_pct,
        total_sets=total_sets,
        completed_sets=completed,
        skipped_sets=skipped,
        pending_sets=pending,
        elapsed_seconds=elapsed,
    )


def _fetch_and_find_pending_set(
    session: ActiveSession,
    slot_id: str,
    set_number: int,
) -> tuple[ActiveSetLog, list[ActiveSetLog]]:
    """Fetch all set logs for a session and locate a specific pending set.

    Returns ``(target_set_log, all_set_logs)`` or raises ``SessionError``.
    The returned ``all_set_logs`` can be reused by callers to avoid further queries.
    """
    all_set_logs = list(
        ActiveSetLog.objects
        .select_for_update(of=('self',))
        .filter(active_session=session)
        .select_related('plan_slot', 'exercise')
        .order_by('plan_slot__order', 'set_number')
    )

    target: ActiveSetLog | None = None
    for sl in all_set_logs:
        if str(sl.plan_slot_id) == str(slot_id) and sl.set_number == set_number:
            target = sl
            break

    if target is None:
        raise SessionError(
            error_code='set_not_found',
            message=f'Set {set_number} for slot {slot_id} not found.',
        )

    if target.status != ActiveSetLog.Status.PENDING:
        raise SessionError(
            error_code='set_already_logged',
            message=f'Set {set_number} has already been {target.status}.',
        )

    return target, all_set_logs


def _validate_session_mutable(session: ActiveSession) -> None:
    """Validate that a session can be mutated (logged, skipped, completed, abandoned)."""
    if session.status == ActiveSession.Status.COMPLETED:
        raise SessionError(
            error_code='session_already_completed',
            message='This session is already completed.',
        )
    if session.status == ActiveSession.Status.ABANDONED:
        raise SessionError(
            error_code='session_already_abandoned',
            message='This session was abandoned.',
        )
    if session.status == ActiveSession.Status.NOT_STARTED:
        raise SessionError(
            error_code='session_not_started',
            message='This session has not been started yet.',
        )


def _get_prescription_for_slot(slot: PlanSlot, trainee_id: int) -> NextPrescription:
    """
    Get load/rep prescription for a slot using the progression engine.
    Falls back to the slot's base prescription if no progression profile exists.
    """
    try:
        return compute_next_prescription(slot=slot, trainee_id=trainee_id)
    except (ValueError, LookupError, TypeError, AttributeError) as exc:
        logger.error(
            "Progression engine failed for slot %s: %s — falling back to base prescription.",
            slot.pk,
            str(exc),
            exc_info=True,
        )
        return NextPrescription(
            slot_id=str(slot.pk),
            exercise_id=slot.exercise_id,
            exercise_name=slot.exercise.name,
            progression_type='none',
            event_type='hold',
            sets=slot.sets,
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
            load_value=None,
            load_unit='lb',
            load_percentage=None,
            reason_codes=['fallback'],
            reason_display='Using base prescription (no progression profile).',
            confidence='low',
        )


def _auto_abandon_stale_sessions(trainee_id: int) -> None:
    """Auto-abandon in_progress sessions older than 4 hours.

    Uses transaction.atomic() with select_for_update() to prevent
    concurrent requests from creating duplicate LiftSetLog entries (C4 fix).
    """
    cutoff = timezone.now() - timedelta(hours=_STALE_SESSION_HOURS)

    with transaction.atomic():
        stale_sessions = list(
            ActiveSession.objects
            .select_for_update(of=('self',))
            .filter(
                trainee_id=trainee_id,
                status=ActiveSession.Status.IN_PROGRESS,
                started_at__lt=cutoff,
            )
        )

        for session in stale_sessions:
            now = timezone.now()
            session.status = ActiveSession.Status.ABANDONED
            session.completed_at = now
            session.abandon_reason = 'auto_abandoned_stale'
            session.save(update_fields=['status', 'completed_at', 'abandon_reason'])

            # Save any completed sets from stale session
            completed_logs = list(
                ActiveSetLog.objects
                .filter(
                    active_session=session,
                    status=ActiveSetLog.Status.COMPLETED,
                )
                .select_related('plan_slot', 'exercise')
            )
            if completed_logs:
                session_date = (session.started_at or now).date()
                _create_lift_set_logs(completed_logs, trainee_id, session_date)

            logger.info(
                "Auto-abandoned stale session %s for trainee %s",
                session.pk, trainee_id,
            )


def _maybe_advance_slot_index(
    session: ActiveSession,
    set_logs: list[ActiveSetLog] | None = None,
) -> None:
    """
    Check if all sets for the current slot are done (completed or skipped).
    If so, advance current_slot_index to the next slot with pending sets.

    If ``set_logs`` is provided, uses them instead of hitting the DB again (M2 fix).
    """
    if set_logs is None:
        set_logs = list(
            ActiveSetLog.objects
            .filter(active_session=session)
            .select_related('plan_slot')
            .order_by('plan_slot__order', 'set_number')
        )

    # Group by slot order
    slot_orders: list[int] = []
    seen: set[int] = set()
    for sl in set_logs:
        order = sl.plan_slot.order if sl.plan_slot else 0
        if order not in seen:
            slot_orders.append(order)
            seen.add(order)

    slot_orders.sort()

    # Find the first slot with pending sets
    for idx, order_val in enumerate(slot_orders):
        has_pending = any(
            sl for sl in set_logs
            if (sl.plan_slot.order if sl.plan_slot else 0) == order_val
            and sl.status == ActiveSetLog.Status.PENDING
        )
        if has_pending:
            if session.current_slot_index != idx:
                session.current_slot_index = idx
                session.save(update_fields=['current_slot_index'])
            return

    # All slots done — set to last index
    if slot_orders:
        final_idx = len(slot_orders) - 1
        if session.current_slot_index != final_idx:
            session.current_slot_index = final_idx
            session.save(update_fields=['current_slot_index'])


def _create_lift_set_logs(
    completed_logs: list[ActiveSetLog],
    trainee_id: int,
    session_date: datetime.date,
) -> list[LiftSetLog]:
    """
    Create permanent LiftSetLog entries from completed ActiveSetLog entries.
    Uses bulk_create for efficiency (M3 fix), then updates LiftMax per entry.
    Returns the created LiftSetLog objects.
    """
    from workouts.services.max_load_service import MaxLoadService

    if not completed_logs:
        return []

    lsl_objects: list[LiftSetLog] = []
    for asl in completed_logs:
        load_value = asl.completed_load_value or Decimal('0')
        load_unit = asl.completed_load_unit or 'lb'
        reps = asl.completed_reps or 0

        lsl_objects.append(LiftSetLog(
            trainee_id=trainee_id,
            exercise=asl.exercise,
            session_date=session_date,
            set_number=asl.set_number,
            entered_load_value=load_value,
            entered_load_unit=load_unit,
            load_entry_mode=LiftSetLog.LoadEntryMode.TOTAL_LOAD,
            completed_reps=reps,
            rpe=asl.rpe,
            notes=asl.notes,
            standardization_pass=True,
        ))

    lift_set_logs = LiftSetLog.objects.bulk_create(lsl_objects)

    # Update LiftMax from qualifying sets (must be done per-entry)
    for lsl in lift_set_logs:
        MaxLoadService.update_max_from_set(lsl)

    return lift_set_logs


def _run_progression_evaluation(
    *,
    set_logs: list[ActiveSetLog],
    trainee_id: int,
    actor_id: int,
    lift_set_logs: list[LiftSetLog],
) -> list[dict[str, Any]]:
    """
    Run progression evaluation for each slot that had completed sets.
    Returns a list of progression result dicts.
    """
    results: list[dict[str, Any]] = []

    # Group set logs by slot
    slot_map: dict[str | None, list[ActiveSetLog]] = {}
    for sl in set_logs:
        key = str(sl.plan_slot_id) if sl.plan_slot_id else None
        slot_map.setdefault(key, []).append(sl)

    for slot_key, slot_logs in slot_map.items():
        if slot_key is None:
            continue

        # Only evaluate slots that have at least one completed set
        completed_in_slot = [sl for sl in slot_logs if sl.status == ActiveSetLog.Status.COMPLETED]
        if not completed_in_slot:
            continue

        # Get the slot
        plan_slot = completed_in_slot[0].plan_slot
        if plan_slot is None:
            continue

        try:
            prescription = compute_next_prescription(
                slot=plan_slot,
                trainee_id=trainee_id,
            )
            event_result: ProgressionEventResult = apply_progression(
                slot=plan_slot,
                prescription=prescription,
                actor_id=actor_id,
                trainee_id=trainee_id,
                actor_type='system',
                reason='session_completed',
            )
            results.append({
                'slot_id': event_result.slot_id,
                'event_type': event_result.event_type,
                'old_prescription': event_result.old_prescription,
                'new_prescription': event_result.new_prescription,
                'reason_codes': event_result.reason_codes,
            })
        except (ValueError, LookupError, TypeError, AttributeError) as exc:
            logger.error(
                "Progression evaluation failed for slot %s: %s",
                slot_key,
                str(exc),
                exc_info=True,
            )
            # Record the failure in DecisionLog for audit trail (M4 fix)
            DecisionLog.objects.create(
                actor_type=DecisionLog.ActorType.SYSTEM,
                actor_id=actor_id,
                decision_type='progression_evaluation_failed',
                context={
                    'slot_id': slot_key,
                    'exercise_id': plan_slot.exercise_id,
                    'error': str(exc),
                },
                inputs_snapshot={
                    'trainee_id': trainee_id,
                    'completed_sets': len(completed_in_slot),
                },
                final_choice={'action': 'progression_skipped'},
                reason_codes=['progression_error'],
            )
            # Include failure in results so the user knows (M4 fix)
            results.append({
                'slot_id': slot_key,
                'event_type': 'error',
                'old_prescription': {},
                'new_prescription': {},
                'reason_codes': ['progression_evaluation_failed'],
            })

    return results

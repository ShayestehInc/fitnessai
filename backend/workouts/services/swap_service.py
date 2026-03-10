"""
Exercise Swap Service — v6.5 Step 5.

Provides three-tab swap options for plan slots and executes swaps
with full DecisionLog + UndoSnapshot support.

Tabs:
    1. Same Muscle — exercises sharing primary_muscle_group
    2. Same Pattern — exercises sharing pattern_tags
    3. Explore All — all exercises matching equipment constraints
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from workouts.models import (
    DecisionLog,
    Exercise,
    PlanSlot,
    UndoSnapshot,
)

logger = logging.getLogger(__name__)

_MAX_RESULTS_PER_TAB: int = 15


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SwapCandidate:
    """A single exercise swap candidate."""
    exercise_id: int
    exercise_name: str
    primary_muscle_group: str
    pattern_tags: list[str]
    difficulty_level: str
    equipment_required: list[str]


@dataclass(frozen=True)
class SwapOptions:
    """Three-tab swap options for a plan slot."""
    slot_id: str
    current_exercise_id: int
    current_exercise_name: str
    same_muscle: list[SwapCandidate]
    same_pattern: list[SwapCandidate]
    explore_all: list[SwapCandidate]


@dataclass(frozen=True)
class SwapResult:
    """Result of executing a swap."""
    slot_id: str
    old_exercise_id: int
    old_exercise_name: str
    new_exercise_id: int
    new_exercise_name: str
    decision_log_id: str


# ---------------------------------------------------------------------------
# Swap Options
# ---------------------------------------------------------------------------

def get_swap_options(
    slot: PlanSlot,
    trainer_id: int | None = None,
) -> SwapOptions:
    """
    Compute three-tab swap options for a plan slot.

    Uses cached swap_options_cache when available, falls back to
    dynamic queries.
    """
    exercise = slot.exercise
    current_exercise_id = exercise.pk
    current_exercise_name = exercise.name

    # Get IDs of exercises already in this session to exclude
    session_exercise_ids = set(
        PlanSlot.objects.filter(
            session=slot.session,
        ).exclude(
            pk=slot.pk,
        ).values_list('exercise_id', flat=True)
    )
    session_exercise_ids.add(current_exercise_id)

    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    base_exclude = Q(pk__in=session_exercise_ids)

    # Check cache first
    cache = slot.swap_options_cache or {}
    cached_muscle_ids = cache.get('same_muscle', [])
    cached_pattern_ids = cache.get('same_pattern', [])
    cached_explore_ids = cache.get('explore', [])

    # Tab 1: Same Muscle
    # Always apply privacy_q even on cached IDs to prevent cross-trainer leakage
    if cached_muscle_ids:
        same_muscle_exercises = list(
            Exercise.objects.filter(
                privacy_q,
                pk__in=cached_muscle_ids,
            ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
        )
    else:
        same_muscle_exercises = list(
            Exercise.objects.filter(
                privacy_q,
                primary_muscle_group=exercise.primary_muscle_group,
            ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
        ) if exercise.primary_muscle_group else []

    # Tab 2: Same Pattern
    if cached_pattern_ids:
        same_pattern_exercises = list(
            Exercise.objects.filter(
                privacy_q,
                pk__in=cached_pattern_ids,
            ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
        )
    else:
        if exercise.pattern_tags:
            same_pattern_exercises = list(
                Exercise.objects.filter(
                    privacy_q,
                    pattern_tags__overlap=exercise.pattern_tags,
                ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
            )
        else:
            same_pattern_exercises = []

    # Tab 3: Explore All
    if cached_explore_ids:
        explore_exercises = list(
            Exercise.objects.filter(
                privacy_q,
                pk__in=cached_explore_ids,
            ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
        )
    else:
        explore_exercises = list(
            Exercise.objects.filter(
                privacy_q,
            ).exclude(base_exclude)[:_MAX_RESULTS_PER_TAB]
        )

    return SwapOptions(
        slot_id=str(slot.pk),
        current_exercise_id=current_exercise_id,
        current_exercise_name=current_exercise_name,
        same_muscle=[_to_candidate(ex) for ex in same_muscle_exercises],
        same_pattern=[_to_candidate(ex) for ex in same_pattern_exercises],
        explore_all=[_to_candidate(ex) for ex in explore_exercises],
    )


def _to_candidate(exercise: Exercise) -> SwapCandidate:
    """Convert an Exercise model to a SwapCandidate dataclass."""
    return SwapCandidate(
        exercise_id=exercise.pk,
        exercise_name=exercise.name,
        primary_muscle_group=exercise.primary_muscle_group or '',
        pattern_tags=exercise.pattern_tags or [],
        difficulty_level=exercise.difficulty_level or '',
        equipment_required=exercise.equipment_required or [],
    )


# ---------------------------------------------------------------------------
# Swap Execution
# ---------------------------------------------------------------------------

def execute_swap(
    slot: PlanSlot,
    new_exercise_id: int,
    actor_id: int | None = None,
    reason: str = '',
    plan_id: str = '',
    week_id: str = '',
    session_id: str = '',
    trainer_id: int | None = None,
) -> SwapResult:
    """
    Execute an exercise swap on a plan slot.

    Creates a DecisionLog + UndoSnapshot for audit trail and undo support.
    Preserves the existing set/rep/rest prescription.

    Raises:
        ValueError: If new exercise doesn't exist, is private, or is already in the session.
    """
    # Privacy check: only allow swapping to public or trainer-owned exercises
    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    try:
        new_exercise = Exercise.objects.get(privacy_q, pk=new_exercise_id)
    except Exercise.DoesNotExist:
        raise ValueError(f"Exercise with id={new_exercise_id} not found or not accessible.")

    # Check for duplicate in same session
    session_exercise_ids = set(
        PlanSlot.objects.filter(
            session=slot.session,
        ).exclude(
            pk=slot.pk,
        ).values_list('exercise_id', flat=True)
    )
    if new_exercise_id in session_exercise_ids:
        raise ValueError(
            f"Exercise '{new_exercise.name}' is already in this session. "
            "Choose a different exercise."
        )

    old_exercise = slot.exercise
    old_exercise_id = old_exercise.pk
    old_exercise_name = old_exercise.name

    with transaction.atomic():
        # Create UndoSnapshot
        before_state = {
            'slot_id': str(slot.pk),
            'exercise_id': old_exercise_id,
            'exercise_name': old_exercise_name,
            'slot_role': slot.slot_role,
            'sets': slot.sets,
            'reps_min': slot.reps_min,
            'reps_max': slot.reps_max,
            'rest_seconds': slot.rest_seconds,
            'swap_options_cache': slot.swap_options_cache,
        }

        # Update slot
        slot.exercise = new_exercise
        # Prescription is preserved — intentionally not changing sets/reps/rest

        after_state = {
            'slot_id': str(slot.pk),
            'exercise_id': new_exercise.pk,
            'exercise_name': new_exercise.name,
            'slot_role': slot.slot_role,
            'sets': slot.sets,
            'reps_min': slot.reps_min,
            'reps_max': slot.reps_max,
            'rest_seconds': slot.rest_seconds,
        }

        undo_snapshot = UndoSnapshot.objects.create(
            scope=UndoSnapshot.Scope.SLOT,
            before_state=before_state,
            after_state=after_state,
        )

        # Create DecisionLog
        decision_log = DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.TRAINER
                if actor_id else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='exercise_swap',
            context={
                'plan_id': plan_id or str(slot.session_id),
                'week_id': week_id or str(slot.session_id),
                'session_id': session_id or str(slot.session_id),
                'slot_id': str(slot.pk),
            },
            inputs_snapshot={
                'old_exercise_id': old_exercise_id,
                'old_exercise_name': old_exercise_name,
                'reason': reason,
            },
            constraints_applied={},
            options_considered=[
                {
                    'exercise_id': new_exercise.pk,
                    'exercise_name': new_exercise.name,
                },
            ],
            final_choice={
                'exercise_id': new_exercise.pk,
                'exercise_name': new_exercise.name,
            },
            reason_codes=['manual_swap'],
            undo_snapshot=undo_snapshot,
        )

        # Clear swap cache (will be recomputed on next fetch)
        slot.swap_options_cache = {}
        slot.save()

    return SwapResult(
        slot_id=str(slot.pk),
        old_exercise_id=old_exercise_id,
        old_exercise_name=old_exercise_name,
        new_exercise_id=new_exercise.pk,
        new_exercise_name=new_exercise.name,
        decision_log_id=str(decision_log.pk),
    )


def undo_swap(decision_log: DecisionLog) -> bool:
    """
    Undo a swap by restoring the slot to its before_state.

    Returns True if undo succeeded, False if not undoable.

    Raises:
        ValueError: If the decision log is not an exercise_swap or not undoable.
    """
    if decision_log.decision_type != 'exercise_swap':
        raise ValueError("Can only undo exercise_swap decisions.")

    if not decision_log.is_undoable:
        raise ValueError("This decision cannot be undone (already reverted or no snapshot).")

    snapshot = decision_log.undo_snapshot
    before = snapshot.before_state

    slot_id = before.get('slot_id')
    if not slot_id:
        raise ValueError("Undo snapshot missing slot_id.")

    with transaction.atomic():
        try:
            slot = PlanSlot.objects.select_for_update().get(pk=slot_id)
        except PlanSlot.DoesNotExist:
            raise ValueError(f"PlanSlot {slot_id} no longer exists.")

        old_exercise_id = before.get('exercise_id')
        if not old_exercise_id:
            raise ValueError("Undo snapshot missing exercise_id.")

        slot.exercise_id = old_exercise_id
        slot.swap_options_cache = before.get('swap_options_cache', {})
        slot.save()

        snapshot.reverted_at = timezone.now()
        snapshot.save()

    return True

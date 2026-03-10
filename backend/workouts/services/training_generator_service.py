"""
Training Generator Pipeline — v6.5 Step 5.

Seven-step deterministic pipeline for generating structured training plans.
Each step creates a DecisionLog entry for full auditability.

Pipeline Steps:
    A1: SELECT_PROGRAM_LENGTH — pick weeks count
    A2: SELECT_SPLIT_TEMPLATE — pick split based on frequency/goal
    A3: BUILD_WEEKLY_SLOT_SKELETON — create PlanWeek/PlanSession records + SlotSpec list
    A4: ASSIGN_SLOT_ROLE — tag each spec (primary_compound, secondary, accessory, isolation)
    A5: SET_SET_STRUCTURE — assign sets/reps/rest per role and goal
    A6: SELECT_EXERCISE — fill specs from exercise pool
    A7: BUILD_SWAP_RECOMMENDATIONS — pre-compute swap candidates per spec
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from django.db import transaction
from django.db.models import Q

from workouts.models import (
    DecisionLog,
    Exercise,
    PlanSession,
    PlanSlot,
    PlanWeek,
    SetStructureModality,
    SplitTemplate,
    TrainingPlan,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class GeneratePlanRequest:
    """Input for the training plan generator pipeline."""
    trainee_id: int
    goal: str
    difficulty: str
    days_per_week: int
    duration_weeks: int | None = None  # None → auto-select via A1
    split_template_id: str | None = None  # None → auto-select via A2
    trainer_id: int | None = None
    training_day_indices: list[int] = field(default_factory=list)  # 0=Mon..6=Sun


@dataclass(frozen=True)
class GeneratePlanResult:
    """Output from the training plan generator pipeline."""
    plan_id: str
    plan_name: str
    weeks_count: int
    sessions_count: int
    slots_count: int
    decision_log_ids: list[str]


@dataclass
class SlotSpec:
    """
    In-memory slot specification used during pipeline construction.
    Avoids creating PlanSlot model instances with null exercise_id.
    Converted to PlanSlot only after A6 assigns an exercise.
    """
    session: PlanSession
    order: int
    slot_role: str
    sets: int
    reps_min: int
    reps_max: int
    rest_seconds: int
    exercise: Exercise | None = None
    swap_options_cache: dict[str, Any] = field(default_factory=dict)
    set_structure_modality: SetStructureModality | None = None
    modality_volume_contribution: Decimal = field(default_factory=lambda: Decimal('0.00'))


# ---------------------------------------------------------------------------
# Scheme tables: (goal, slot_role) → (sets, reps_min, reps_max, rest_seconds)
# ---------------------------------------------------------------------------

_SCHEME: dict[tuple[str, str], tuple[int, int, int, int]] = {
    # Build Muscle
    ('build_muscle', 'primary_compound'): (4, 6, 10, 120),
    ('build_muscle', 'secondary_compound'): (3, 8, 12, 90),
    ('build_muscle', 'accessory'): (3, 10, 15, 60),
    ('build_muscle', 'isolation'): (3, 12, 15, 45),
    # Strength
    ('strength', 'primary_compound'): (5, 3, 5, 180),
    ('strength', 'secondary_compound'): (4, 4, 6, 150),
    ('strength', 'accessory'): (3, 6, 8, 90),
    ('strength', 'isolation'): (3, 8, 10, 60),
    # Fat Loss
    ('fat_loss', 'primary_compound'): (3, 10, 15, 45),
    ('fat_loss', 'secondary_compound'): (3, 12, 15, 45),
    ('fat_loss', 'accessory'): (3, 12, 20, 30),
    ('fat_loss', 'isolation'): (2, 15, 20, 30),
    # Endurance
    ('endurance', 'primary_compound'): (3, 15, 20, 30),
    ('endurance', 'secondary_compound'): (3, 15, 20, 30),
    ('endurance', 'accessory'): (2, 15, 25, 30),
    ('endurance', 'isolation'): (2, 15, 20, 30),
    # Recomp
    ('recomp', 'primary_compound'): (4, 8, 12, 90),
    ('recomp', 'secondary_compound'): (3, 8, 12, 75),
    ('recomp', 'accessory'): (3, 10, 15, 60),
    ('recomp', 'isolation'): (3, 12, 15, 45),
    # General Fitness
    ('general_fitness', 'primary_compound'): (3, 8, 12, 75),
    ('general_fitness', 'secondary_compound'): (3, 10, 12, 60),
    ('general_fitness', 'accessory'): (3, 10, 15, 45),
    ('general_fitness', 'isolation'): (2, 12, 15, 45),
}

# Fallback if goal not in scheme table
_DEFAULT_SCHEME: dict[str, tuple[int, int, int, int]] = {
    'primary_compound': (4, 6, 10, 120),
    'secondary_compound': (3, 8, 12, 90),
    'accessory': (3, 10, 15, 60),
    'isolation': (3, 12, 15, 45),
}

# Compound categories (from KILO database)
_COMPOUND_CATEGORIES: set[str] = {
    'squat', 'deadlift', 'bench press', 'press', 'row', 'pull-up',
    'pull up', 'chin-up', 'chin up', 'hip hinge', 'lunge',
    'overhead press', 'clean', 'snatch', 'dip',
}

# Default day indices per days_per_week
_DEFAULT_DAY_INDICES: dict[int, list[int]] = {
    1: [0],
    2: [0, 3],
    3: [0, 2, 4],
    4: [0, 1, 3, 4],
    5: [0, 1, 2, 3, 4],
    6: [0, 1, 2, 3, 4, 5],
    7: [0, 1, 2, 3, 4, 5, 6],
}

# Duration weeks recommendations based on goal
_GOAL_DURATION: dict[str, int] = {
    'build_muscle': 8,
    'strength': 8,
    'fat_loss': 6,
    'endurance': 6,
    'recomp': 8,
    'general_fitness': 6,
}

# Max swap candidates per tab
_MAX_SWAP_PER_TAB: int = 10


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _is_compound(exercise: Exercise) -> bool:
    """Determine if an exercise is a compound movement."""
    cat = (exercise.category or '').lower().strip()
    name = exercise.name.lower()
    for keyword in _COMPOUND_CATEGORIES:
        if keyword in cat or keyword in name:
            return True
    return False


def _log_decision(
    *,
    decision_type: str,
    actor_id: int | None,
    context: dict[str, Any],
    inputs_snapshot: dict[str, Any],
    constraints: dict[str, Any],
    options: list[dict[str, Any]],
    final_choice: dict[str, Any],
    reason_codes: list[str],
    total_options_count: int | None = None,
) -> DecisionLog:
    """Create a DecisionLog entry for a pipeline step."""
    stored_options = options[:20]
    if total_options_count is not None and total_options_count > 20:
        final_choice['_total_options_count'] = total_options_count
    return DecisionLog.objects.create(
        actor_type=DecisionLog.ActorType.SYSTEM,
        actor_id=actor_id,
        decision_type=decision_type,
        context=context,
        inputs_snapshot=inputs_snapshot,
        constraints_applied=constraints,
        options_considered=stored_options,
        final_choice=final_choice,
        reason_codes=reason_codes,
    )


def _slot_count_for_muscles(muscle_count: int) -> int:
    """Determine how many exercise slots for a session based on muscle group count."""
    if muscle_count <= 1:
        return 5
    elif muscle_count == 2:
        return 6
    elif muscle_count <= 4:
        return 7
    else:
        return 8  # Full body


def _pick_exercise(
    pool: list[Exercise],
    slot_role: str,
    used_ids: set[int],
) -> Exercise | None:
    """Pick the best exercise from pool for the given slot role."""
    available = [ex for ex in pool if ex.id not in used_ids]
    if not available:
        available = list(pool)
    if not available:
        return None

    is_compound_role = slot_role in (
        PlanSlot.SlotRole.PRIMARY_COMPOUND,
        PlanSlot.SlotRole.SECONDARY_COMPOUND,
    )

    if is_compound_role:
        compounds = [ex for ex in available if _is_compound(ex)]
        if compounds:
            return compounds[0]

    if slot_role == PlanSlot.SlotRole.ISOLATION:
        isolations = [ex for ex in available if not _is_compound(ex)]
        if isolations:
            return isolations[0]

    return available[0]


def _prefetch_exercise_pool(
    session_defs: list[dict[str, Any]],
    difficulty: str,
    trainer_id: int | None,
) -> tuple[dict[str, list[Exercise]], list[Exercise]]:
    """
    Prefetch ALL exercises for the plan in a single query.
    Returns (pool_by_muscle_group, all_exercises).
    """
    all_muscle_groups: set[str] = set()
    for sdef in session_defs:
        for mg in sdef.get('muscle_groups', []):
            all_muscle_groups.add(mg)

    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    diff_q = Q(difficulty_level=difficulty) | Q(difficulty_level__isnull=True) | Q(difficulty_level='')
    exercises = list(
        Exercise.objects.filter(
            Q(primary_muscle_group__in=all_muscle_groups) & privacy_q & diff_q
        ).only(
            'id', 'name', 'primary_muscle_group', 'category',
            'pattern_tags', 'swap_seed_ids', 'equipment_required',
        )
    )

    pool: dict[str, list[Exercise]] = {}
    for ex in exercises:
        pool.setdefault(ex.primary_muscle_group, []).append(ex)

    # Fallback to legacy muscle_group if v6.5 field is empty
    if not pool:
        legacy_exercises = list(
            Exercise.objects.filter(
                Q(muscle_group__in=all_muscle_groups) & privacy_q
            ).only('id', 'name', 'muscle_group', 'category', 'pattern_tags', 'swap_seed_ids')
        )
        for ex in legacy_exercises:
            pool.setdefault(ex.muscle_group, []).append(ex)
        exercises = legacy_exercises

    if not pool:
        raise ValueError(
            "No exercises found in database matching the required muscle groups. "
            "Seed exercises before generating a plan."
        )

    return pool, exercises


# ---------------------------------------------------------------------------
# Pipeline Steps
# ---------------------------------------------------------------------------

def _a1_select_program_length(
    request: GeneratePlanRequest,
) -> tuple[int, DecisionLog]:
    """A1: Select program duration in weeks."""
    if request.duration_weeks is not None:
        weeks = max(1, min(request.duration_weeks, 52))
        reason = 'user_specified'
    else:
        weeks = _GOAL_DURATION.get(request.goal, 6)
        reason = 'goal_default'

    log = _log_decision(
        decision_type='plan_generation_a1_program_length',
        actor_id=request.trainer_id,
        context={'trainee_id': request.trainee_id},
        inputs_snapshot={
            'goal': request.goal,
            'requested_weeks': request.duration_weeks,
        },
        constraints={},
        options=[{'weeks': weeks, 'reason': reason}],
        final_choice={'weeks': weeks},
        reason_codes=[reason],
    )
    return weeks, log


def _a2_select_split_template(
    request: GeneratePlanRequest,
) -> tuple[SplitTemplate, DecisionLog]:
    """A2: Select or retrieve the split template."""
    if request.split_template_id:
        try:
            template = SplitTemplate.objects.get(pk=request.split_template_id)
        except SplitTemplate.DoesNotExist:
            raise ValueError(
                f"SplitTemplate with id={request.split_template_id} not found."
            )

        log = _log_decision(
            decision_type='plan_generation_a2_split_template',
            actor_id=request.trainer_id,
            context={'trainee_id': request.trainee_id},
            inputs_snapshot={'split_template_id': request.split_template_id},
            constraints={},
            options=[{'template_id': str(template.pk), 'name': template.name}],
            final_choice={'template_id': str(template.pk), 'name': template.name},
            reason_codes=['user_specified'],
        )
        return template, log

    # Auto-select: find best match by days_per_week and goal
    candidates = list(
        SplitTemplate.objects.filter(
            Q(is_system=True) | Q(created_by_id=request.trainer_id),
            days_per_week=request.days_per_week,
        ).order_by('-is_system', 'name')[:20]
    )

    if not candidates:
        candidates = list(
            SplitTemplate.objects.filter(
                is_system=True,
                days_per_week=request.days_per_week,
            ).order_by('name')[:10]
        )

    if not candidates:
        raise ValueError(
            f"No SplitTemplate found for {request.days_per_week} days/week. "
            "Seed system templates first."
        )

    goal_match = [c for c in candidates if c.goal_type == request.goal]
    selected = goal_match[0] if goal_match else candidates[0]

    options = [
        {'template_id': str(c.pk), 'name': c.name, 'goal_match': c.goal_type == request.goal}
        for c in candidates[:10]
    ]

    log = _log_decision(
        decision_type='plan_generation_a2_split_template',
        actor_id=request.trainer_id,
        context={'trainee_id': request.trainee_id},
        inputs_snapshot={
            'days_per_week': request.days_per_week,
            'goal': request.goal,
        },
        constraints={'days_per_week': request.days_per_week},
        options=options,
        final_choice={'template_id': str(selected.pk), 'name': selected.name},
        reason_codes=['goal_match' if selected in goal_match else 'default_selection'],
        total_options_count=len(candidates),
    )
    return selected, log


def _a3_build_skeleton(
    plan: TrainingPlan,
    split_template: SplitTemplate,
    weeks_count: int,
    day_indices: list[int],
    trainer_id: int | None,
) -> tuple[list[PlanWeek], list[PlanSession], list[SlotSpec], DecisionLog]:
    """A3: Create PlanWeek and PlanSession records, return SlotSpec list (no PlanSlot yet)."""
    session_defs: list[dict[str, Any]] = split_template.session_definitions
    if not isinstance(session_defs, list) or not session_defs:
        raise ValueError(
            f"SplitTemplate {split_template.pk} has invalid session_definitions."
        )

    if not day_indices:
        day_indices = _DEFAULT_DAY_INDICES.get(
            split_template.days_per_week,
            list(range(split_template.days_per_week)),
        )

    all_weeks: list[PlanWeek] = []
    all_sessions: list[PlanSession] = []
    all_specs: list[SlotSpec] = []

    for wk_num in range(1, weeks_count + 1):
        is_deload = weeks_count >= 4 and wk_num % 4 == 0
        intensity_mod = Decimal('0.60') if is_deload else Decimal('1.00')
        volume_mod = Decimal('0.60') if is_deload else Decimal('1.00')

        week = PlanWeek(
            plan=plan,
            week_number=wk_num,
            is_deload=is_deload,
            intensity_modifier=intensity_mod,
            volume_modifier=volume_mod,
        )
        all_weeks.append(week)

    PlanWeek.objects.bulk_create(all_weeks)

    for week in all_weeks:
        for session_idx, session_def in enumerate(session_defs):
            day_idx = day_indices[session_idx % len(day_indices)]
            label = session_def.get('label', f'Session {session_idx + 1}')

            session = PlanSession(
                week=week,
                day_of_week=day_idx,
                label=label,
                order=session_idx,
            )
            all_sessions.append(session)

    PlanSession.objects.bulk_create(all_sessions)

    # Build SlotSpec (not PlanSlot) for each session
    for session in all_sessions:
        session_def = session_defs[session.order % len(session_defs)]
        muscle_groups: list[str] = session_def.get('muscle_groups', [])
        slot_count = _slot_count_for_muscles(len(muscle_groups))

        for slot_idx in range(slot_count):
            spec = SlotSpec(
                session=session,
                order=slot_idx + 1,
                slot_role=PlanSlot.SlotRole.ACCESSORY,  # Assigned in A4
                sets=3,
                reps_min=8,
                reps_max=12,
                rest_seconds=60,
            )
            all_specs.append(spec)

    log = _log_decision(
        decision_type='plan_generation_a3_skeleton',
        actor_id=trainer_id,
        context={'plan_id': str(plan.pk)},
        inputs_snapshot={
            'weeks_count': weeks_count,
            'session_defs_count': len(session_defs),
            'day_indices': day_indices,
        },
        constraints={},
        options=[],
        final_choice={
            'weeks': len(all_weeks),
            'sessions': len(all_sessions),
            'slots_planned': len(all_specs),
        },
        reason_codes=['skeleton_built'],
    )
    return all_weeks, all_sessions, all_specs, log


def _a4_assign_slot_roles(
    all_specs: list[SlotSpec],
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A4: Tag each slot with a role based on position in session."""
    role_map = {
        1: PlanSlot.SlotRole.PRIMARY_COMPOUND,
        2: PlanSlot.SlotRole.SECONDARY_COMPOUND,
    }

    assignments: list[dict[str, Any]] = []

    for spec in all_specs:
        if spec.order <= 2:
            role = role_map.get(spec.order, PlanSlot.SlotRole.ACCESSORY)
        elif spec.order <= 4:
            role = PlanSlot.SlotRole.ACCESSORY
        else:
            role = PlanSlot.SlotRole.ISOLATION

        spec.slot_role = role
        assignments.append({'slot_order': spec.order, 'role': role})

    log = _log_decision(
        decision_type='plan_generation_a4_slot_roles',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'total_slots': len(all_specs)},
        constraints={},
        options=[],
        final_choice={'assignments': assignments[:50]},
        reason_codes=['position_based'],
        total_options_count=len(assignments),
    )
    return log


def _a5_set_structure(
    all_specs: list[SlotSpec],
    goal: str,
    trainer_id: int | None,
    plan_id: str,
    deload_week_numbers: set[int],
    modality_by_slug: dict[str, SetStructureModality],
) -> DecisionLog:
    """A5: Assign sets/reps/rest and default modality based on slot role and goal."""
    from workouts.services.modality_service import (
        assign_default_modality_to_specs,
        compute_volume_contribution,
        get_default_modality_slug,
    )

    structures: list[dict[str, Any]] = []

    for spec in all_specs:
        key = (goal, spec.slot_role)
        scheme = _SCHEME.get(key)
        if scheme is None:
            scheme = _DEFAULT_SCHEME.get(spec.slot_role, (3, 8, 12, 60))

        sets, reps_min, reps_max, rest = scheme
        spec.sets = sets
        spec.reps_min = reps_min
        spec.reps_max = reps_max
        spec.rest_seconds = rest

    # Assign default modalities (mutates specs in place)
    assign_default_modality_to_specs(
        all_specs=all_specs,
        goal=goal,
        deload_week_numbers=deload_week_numbers,
        modality_by_slug=modality_by_slug,
    )

    for spec in all_specs:
        modality_slug = spec.set_structure_modality.slug if spec.set_structure_modality else 'straight-sets'
        structures.append({
            'slot_order': spec.order,
            'role': spec.slot_role,
            'sets': spec.sets,
            'reps': f'{spec.reps_min}-{spec.reps_max}',
            'rest': spec.rest_seconds,
            'modality': modality_slug,
            'volume_contribution': str(spec.modality_volume_contribution),
        })

    log = _log_decision(
        decision_type='plan_generation_a5_set_structure',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'goal': goal, 'total_slots': len(all_specs)},
        constraints={'modalities_available': list(modality_by_slug.keys())},
        options=[],
        final_choice={'structures': structures[:50]},
        reason_codes=['goal_based_scheme', 'modality_assigned'],
        total_options_count=len(structures),
    )
    return log


def _a6_select_exercises(
    all_specs: list[SlotSpec],
    all_sessions: list[PlanSession],
    session_defs: list[dict[str, Any]],
    pool: dict[str, list[Exercise]],
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A6: Fill each spec with an exercise from the pool.

    Used_ids resets per week to allow exercise repetition across weeks
    while ensuring variety within a single week.
    """
    assignments: list[dict[str, Any]] = []

    # Group specs by session
    session_spec_map: dict[str, list[SlotSpec]] = {}
    for spec in all_specs:
        session_spec_map.setdefault(str(spec.session.pk), []).append(spec)

    # Group sessions by week for per-week used_ids reset
    week_session_map: dict[str, list[PlanSession]] = {}
    for session in all_sessions:
        week_session_map.setdefault(str(session.week_id), []).append(session)

    for _week_id, week_sessions in week_session_map.items():
        # Reset used_ids per week — exercises repeat across weeks (same program)
        # but stay unique within a single week for variety
        used_ids: set[int] = set()

        for session in week_sessions:
            session_def = session_defs[session.order % len(session_defs)]
            muscle_groups: list[str] = session_def.get('muscle_groups', [])
            specs = session_spec_map.get(str(session.pk), [])

            if not muscle_groups:
                continue

            for i, spec in enumerate(specs):
                mg = muscle_groups[i % len(muscle_groups)]
                mg_pool = pool.get(mg, [])

                exercise = _pick_exercise(mg_pool, spec.slot_role, used_ids)

                if exercise is None:
                    for alt_mg in muscle_groups:
                        exercise = _pick_exercise(pool.get(alt_mg, []), spec.slot_role, used_ids)
                        if exercise:
                            break

                if exercise is None:
                    for any_pool in pool.values():
                        exercise = _pick_exercise(any_pool, spec.slot_role, set())
                        if exercise:
                            break

                if exercise is None:
                    raise ValueError(
                        f"Cannot fill slot {spec.order} for session '{session.label}'. "
                        "Insufficient exercises in database."
                    )

                spec.exercise = exercise
                used_ids.add(exercise.id)
                assignments.append({
                    'session_label': session.label,
                    'slot_order': spec.order,
                    'exercise_id': exercise.id,
                    'exercise_name': exercise.name,
                    'muscle_group': mg,
                })

    log = _log_decision(
        decision_type='plan_generation_a6_exercise_selection',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={
            'muscle_groups': sorted(pool.keys()),
            'pool_size': sum(len(v) for v in pool.values()),
        },
        constraints={'privacy': 'public_or_trainer'},
        options=[],
        final_choice={'assignments': assignments[:100]},
        reason_codes=['pool_selection'],
        total_options_count=len(assignments),
    )
    return log


def _a7_build_swap_recommendations(
    all_specs: list[SlotSpec],
    all_exercises: list[Exercise],
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A7: Pre-compute swap candidates for each spec.

    Uses in-memory exercise pool instead of per-slot DB queries.
    Falls back to swap_seed_ids when available.
    """
    exercises_by_id: dict[int, Exercise] = {ex.id: ex for ex in all_exercises}
    plan_exercise_ids: set[int] = {
        spec.exercise.id for spec in all_specs if spec.exercise
    }

    # Build in-memory pools for batch swap computation
    by_muscle: dict[str, list[int]] = {}
    by_pattern: dict[str, list[int]] = {}
    all_ids: list[int] = []

    for ex in all_exercises:
        all_ids.append(ex.id)
        if ex.primary_muscle_group:
            by_muscle.setdefault(ex.primary_muscle_group, []).append(ex.id)
        for tag in (ex.pattern_tags or []):
            by_pattern.setdefault(tag, []).append(ex.id)

    swap_count = 0

    for spec in all_specs:
        if not spec.exercise:
            continue

        exercise = spec.exercise
        seeds = exercises_by_id.get(exercise.id)
        seed_data = (seeds.swap_seed_ids or {}) if seeds else {}

        # Same muscle
        same_muscle_ids = seed_data.get('recommended_same_muscle_ids', [])
        if not same_muscle_ids and exercise.primary_muscle_group:
            same_muscle_ids = [
                eid for eid in by_muscle.get(exercise.primary_muscle_group, [])
                if eid != exercise.id and eid not in plan_exercise_ids
            ]

        # Same pattern
        same_pattern_ids = seed_data.get('recommended_same_pattern_ids', [])
        if not same_pattern_ids and exercise.pattern_tags:
            seen: set[int] = set()
            same_pattern_ids = []
            for tag in exercise.pattern_tags:
                for eid in by_pattern.get(tag, []):
                    if eid != exercise.id and eid not in plan_exercise_ids and eid not in seen:
                        same_pattern_ids.append(eid)
                        seen.add(eid)

        # Explore all
        explore_ids = [
            eid for eid in all_ids
            if eid != exercise.id and eid not in plan_exercise_ids
        ]

        spec.swap_options_cache = {
            'same_muscle': same_muscle_ids[:_MAX_SWAP_PER_TAB],
            'same_pattern': same_pattern_ids[:_MAX_SWAP_PER_TAB],
            'explore': explore_ids[:_MAX_SWAP_PER_TAB],
        }
        swap_count += 1

    log = _log_decision(
        decision_type='plan_generation_a7_swap_recommendations',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'total_slots': len(all_specs)},
        constraints={},
        options=[],
        final_choice={'slots_with_swaps': swap_count},
        reason_codes=['swap_cache_built'],
    )
    return log


def _specs_to_plan_slots(all_specs: list[SlotSpec]) -> list[PlanSlot]:
    """Convert SlotSpecs to PlanSlot model instances for bulk_create."""
    slots: list[PlanSlot] = []
    for spec in all_specs:
        if spec.exercise is None:
            raise ValueError(
                f"SlotSpec at order={spec.order} has no exercise assigned. "
                "Pipeline step A6 must run before creating PlanSlots."
            )
        slots.append(PlanSlot(
            session=spec.session,
            exercise=spec.exercise,
            order=spec.order,
            slot_role=spec.slot_role,
            sets=spec.sets,
            reps_min=spec.reps_min,
            reps_max=spec.reps_max,
            rest_seconds=spec.rest_seconds,
            swap_options_cache=spec.swap_options_cache,
            set_structure_modality=spec.set_structure_modality,
            modality_volume_contribution=spec.modality_volume_contribution,
        ))
    return slots


# ---------------------------------------------------------------------------
# Main Pipeline
# ---------------------------------------------------------------------------

def generate_training_plan(request: GeneratePlanRequest) -> GeneratePlanResult:
    """
    Execute the full 7-step training plan generation pipeline.

    All steps run inside a single transaction. If any step fails,
    all changes are rolled back.

    Raises:
        ValueError: If inputs are invalid or insufficient exercises exist.
    """
    decision_log_ids: list[str] = []

    with transaction.atomic():
        # A1: Select program length
        weeks_count, log_a1 = _a1_select_program_length(request)
        decision_log_ids.append(str(log_a1.pk))

        # A2: Select split template
        split_template, log_a2 = _a2_select_split_template(request)
        decision_log_ids.append(str(log_a2.pk))

        # Create the TrainingPlan record
        plan = TrainingPlan.objects.create(
            trainee_id=request.trainee_id,
            name=f"{split_template.name} — {request.goal.replace('_', ' ').title()}",
            goal=request.goal,
            status=TrainingPlan.Status.DRAFT,
            split_template=split_template,
            difficulty=request.difficulty,
            duration_weeks=weeks_count,
            created_by_id=request.trainer_id,
        )

        # Resolve day indices
        day_indices = request.training_day_indices
        if not day_indices:
            day_indices = _DEFAULT_DAY_INDICES.get(
                split_template.days_per_week,
                list(range(split_template.days_per_week)),
            )

        session_defs: list[dict[str, Any]] = split_template.session_definitions

        # Prefetch exercise pool once (shared between A6 and A7)
        pool, all_exercises = _prefetch_exercise_pool(
            session_defs=session_defs,
            difficulty=request.difficulty,
            trainer_id=request.trainer_id,
        )

        # A3: Build skeleton (weeks + sessions + SlotSpecs)
        all_weeks, all_sessions, all_specs, log_a3 = _a3_build_skeleton(
            plan=plan,
            split_template=split_template,
            weeks_count=weeks_count,
            day_indices=day_indices,
            trainer_id=request.trainer_id,
        )
        decision_log_ids.append(str(log_a3.pk))

        # A4: Assign slot roles
        log_a4 = _a4_assign_slot_roles(
            all_specs=all_specs,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a4.pk))

        # Prefetch system modalities for A5 modality assignment
        from workouts.services.modality_service import prefetch_system_modalities
        modality_by_slug = prefetch_system_modalities()

        # Collect deload week numbers
        deload_week_numbers: set[int] = {
            w.week_number for w in all_weeks if w.is_deload
        }

        # A5: Set set structure + assign modalities
        log_a5 = _a5_set_structure(
            all_specs=all_specs,
            goal=request.goal,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
            deload_week_numbers=deload_week_numbers,
            modality_by_slug=modality_by_slug,
        )
        decision_log_ids.append(str(log_a5.pk))

        # A6: Select exercises
        log_a6 = _a6_select_exercises(
            all_specs=all_specs,
            all_sessions=all_sessions,
            session_defs=session_defs,
            pool=pool,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a6.pk))

        # A7: Build swap recommendations (uses shared pool, no per-slot queries)
        log_a7 = _a7_build_swap_recommendations(
            all_specs=all_specs,
            all_exercises=all_exercises,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a7.pk))

        # Convert specs to PlanSlot model instances and bulk_create
        plan_slots = _specs_to_plan_slots(all_specs)
        PlanSlot.objects.bulk_create(plan_slots)

    return GeneratePlanResult(
        plan_id=str(plan.pk),
        plan_name=plan.name,
        weeks_count=weeks_count,
        sessions_count=len(all_sessions),
        slots_count=len(plan_slots),
        decision_log_ids=decision_log_ids,
    )

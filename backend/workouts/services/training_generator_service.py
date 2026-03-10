"""
Training Generator Pipeline — v6.5 Step 5.

Seven-step deterministic pipeline for generating structured training plans.
Each step creates a DecisionLog entry for full auditability.

Pipeline Steps:
    A1: SELECT_PROGRAM_LENGTH — pick weeks count
    A2: SELECT_SPLIT_TEMPLATE — pick split based on frequency/goal
    A3: BUILD_WEEKLY_SLOT_SKELETON — create PlanWeek/PlanSession/PlanSlot records
    A4: ASSIGN_SLOT_ROLE — tag each slot (primary_compound, secondary, accessory, isolation)
    A5: SET_SET_STRUCTURE — assign sets/reps/rest per role and goal
    A6: SELECT_EXERCISE — fill slots from exercise pool
    A7: BUILD_SWAP_RECOMMENDATIONS — pre-compute swap candidates per slot
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
    SplitTemplate,
    TrainingPlan,
    UndoSnapshot,
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
    1: [0],  # Mon
    2: [0, 3],  # Mon, Thu
    3: [0, 2, 4],  # Mon, Wed, Fri
    4: [0, 1, 3, 4],  # Mon, Tue, Thu, Fri
    5: [0, 1, 2, 3, 4],  # Mon–Fri
    6: [0, 1, 2, 3, 4, 5],  # Mon–Sat
    7: [0, 1, 2, 3, 4, 5, 6],  # Every day
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
) -> DecisionLog:
    """Create a DecisionLog entry for a pipeline step."""
    return DecisionLog.objects.create(
        actor_type=DecisionLog.ActorType.SYSTEM,
        actor_id=actor_id,
        decision_type=decision_type,
        context=context,
        inputs_snapshot=inputs_snapshot,
        constraints_applied=constraints,
        options_considered=options[:20],  # Cap stored options
        final_choice=final_choice,
        reason_codes=reason_codes,
    )


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
        options=[
            {'weeks': weeks, 'reason': reason},
        ],
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
        # Widen search: any template with matching days
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

    # Prefer goal match
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
    )
    return selected, log


def _a3_build_skeleton(
    plan: TrainingPlan,
    split_template: SplitTemplate,
    weeks_count: int,
    day_indices: list[int],
    trainer_id: int | None,
) -> tuple[list[PlanWeek], list[PlanSession], list[PlanSlot], DecisionLog]:
    """A3: Create PlanWeek, PlanSession, PlanSlot skeleton records."""
    session_defs: list[dict[str, Any]] = split_template.session_definitions
    if not isinstance(session_defs, list) or not session_defs:
        raise ValueError(
            f"SplitTemplate {split_template.pk} has invalid session_definitions."
        )

    # Ensure we have enough day indices
    if not day_indices:
        day_indices = _DEFAULT_DAY_INDICES.get(
            split_template.days_per_week,
            list(range(split_template.days_per_week)),
        )

    all_weeks: list[PlanWeek] = []
    all_sessions: list[PlanSession] = []
    all_slots: list[PlanSlot] = []

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

    # Build sessions for each week
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

    # Build empty slots per session based on muscle groups in session_def
    for session in all_sessions:
        # Find the matching session_def
        session_def = session_defs[session.order % len(session_defs)]
        muscle_groups: list[str] = session_def.get('muscle_groups', [])

        # Determine slot count based on muscle group count
        slot_count = _slot_count_for_muscles(len(muscle_groups))

        for slot_idx in range(slot_count):
            slot = PlanSlot(
                session=session,
                exercise_id=None,  # Filled in A6
                order=slot_idx + 1,
                slot_role=PlanSlot.SlotRole.ACCESSORY,  # Assigned in A4
                sets=3,  # Set in A5
                reps_min=8,  # Set in A5
                reps_max=12,  # Set in A5
                rest_seconds=60,  # Set in A5
            )
            all_slots.append(slot)

    # We can't bulk_create slots yet because exercise is required (PROTECT).
    # We'll create them after A6. Store as list for now.

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
            'slots_planned': len(all_slots),
        },
        reason_codes=['skeleton_built'],
    )
    return all_weeks, all_sessions, all_slots, log


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


def _a4_assign_slot_roles(
    all_slots: list[PlanSlot],
    session_defs: list[dict[str, Any]],
    all_sessions: list[PlanSession],
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A4: Tag each slot with a role based on position in session."""
    role_map = {
        0: PlanSlot.SlotRole.PRIMARY_COMPOUND,
        1: PlanSlot.SlotRole.SECONDARY_COMPOUND,
    }

    assignments: list[dict[str, Any]] = []

    for slot in all_slots:
        if slot.order <= 2:
            role = role_map.get(slot.order - 1, PlanSlot.SlotRole.ACCESSORY)
        elif slot.order <= 4:
            role = PlanSlot.SlotRole.ACCESSORY
        else:
            role = PlanSlot.SlotRole.ISOLATION

        slot.slot_role = role
        assignments.append({
            'slot_order': slot.order,
            'role': role,
        })

    log = _log_decision(
        decision_type='plan_generation_a4_slot_roles',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'total_slots': len(all_slots)},
        constraints={},
        options=[],
        final_choice={'assignments': assignments[:50]},
        reason_codes=['position_based'],
    )
    return log


def _a5_set_structure(
    all_slots: list[PlanSlot],
    goal: str,
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A5: Assign sets/reps/rest based on slot role and goal."""
    structures: list[dict[str, Any]] = []

    for slot in all_slots:
        key = (goal, slot.slot_role)
        scheme = _SCHEME.get(key)
        if scheme is None:
            scheme = _DEFAULT_SCHEME.get(
                slot.slot_role, (3, 8, 12, 60)
            )

        sets, reps_min, reps_max, rest = scheme
        slot.sets = sets
        slot.reps_min = reps_min
        slot.reps_max = reps_max
        slot.rest_seconds = rest

        structures.append({
            'slot_order': slot.order,
            'role': slot.slot_role,
            'sets': sets,
            'reps': f'{reps_min}-{reps_max}',
            'rest': rest,
        })

    log = _log_decision(
        decision_type='plan_generation_a5_set_structure',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'goal': goal, 'total_slots': len(all_slots)},
        constraints={},
        options=[],
        final_choice={'structures': structures[:50]},
        reason_codes=['goal_based_scheme'],
    )
    return log


def _a6_select_exercises(
    all_slots: list[PlanSlot],
    all_sessions: list[PlanSession],
    session_defs: list[dict[str, Any]],
    difficulty: str,
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A6: Fill each slot with an exercise from the pool."""
    # Collect all needed muscle groups
    all_muscle_groups: set[str] = set()
    for sdef in session_defs:
        for mg in sdef.get('muscle_groups', []):
            all_muscle_groups.add(mg)

    # Prefetch exercise pool using primary_muscle_group (v6.5 field)
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

    # Build pool by primary_muscle_group
    pool: dict[str, list[Exercise]] = {}
    for ex in exercises:
        pool.setdefault(ex.primary_muscle_group, []).append(ex)

    # Also build fallback pool by legacy muscle_group
    if not pool:
        legacy_exercises = list(
            Exercise.objects.filter(
                Q(muscle_group__in=all_muscle_groups) & privacy_q
            ).only('id', 'name', 'muscle_group', 'category', 'pattern_tags', 'swap_seed_ids')
        )
        for ex in legacy_exercises:
            pool.setdefault(ex.muscle_group, []).append(ex)

    if not pool:
        raise ValueError(
            "No exercises found in database matching the required muscle groups. "
            "Seed exercises before generating a plan."
        )

    used_ids: set[int] = set()
    assignments: list[dict[str, Any]] = []

    # Group slots by session
    session_slot_map: dict[str, list[PlanSlot]] = {}
    for slot in all_slots:
        session_slot_map.setdefault(str(slot.session_id), []).append(slot)

    for session in all_sessions:
        session_def = session_defs[session.order % len(session_defs)]
        muscle_groups: list[str] = session_def.get('muscle_groups', [])
        slots = session_slot_map.get(str(session.pk), [])

        if not muscle_groups:
            continue

        # Distribute slots across muscle groups
        for i, slot in enumerate(slots):
            mg = muscle_groups[i % len(muscle_groups)]
            mg_pool = pool.get(mg, [])

            # Pick best available exercise
            exercise = _pick_exercise(mg_pool, slot.slot_role, used_ids)

            if exercise is None:
                # Widen: try any muscle group in this session
                for alt_mg in muscle_groups:
                    exercise = _pick_exercise(pool.get(alt_mg, []), slot.slot_role, used_ids)
                    if exercise:
                        break

            if exercise is None:
                # Last resort: pick from any pool
                for any_pool in pool.values():
                    exercise = _pick_exercise(any_pool, slot.slot_role, set())
                    if exercise:
                        break

            if exercise is None:
                raise ValueError(
                    f"Cannot fill slot {slot.order} for session '{session.label}'. "
                    "Insufficient exercises in database."
                )

            slot.exercise = exercise
            used_ids.add(exercise.id)
            assignments.append({
                'session_label': session.label,
                'slot_order': slot.order,
                'exercise_id': exercise.id,
                'exercise_name': exercise.name,
                'muscle_group': mg,
            })

    log = _log_decision(
        decision_type='plan_generation_a6_exercise_selection',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={
            'difficulty': difficulty,
            'muscle_groups': sorted(all_muscle_groups),
            'pool_size': len(exercises),
        },
        constraints={'privacy': 'public_or_trainer'},
        options=[],
        final_choice={'assignments': assignments[:100]},
        reason_codes=['pool_selection'],
    )
    return log


def _pick_exercise(
    pool: list[Exercise],
    slot_role: str,
    used_ids: set[int],
) -> Exercise | None:
    """Pick the best exercise from pool for the given slot role."""
    # Prefer unused exercises
    available = [ex for ex in pool if ex.id not in used_ids]
    if not available:
        available = list(pool)
    if not available:
        return None

    # For compound roles, prefer compound exercises
    is_compound_role = slot_role in (
        PlanSlot.SlotRole.PRIMARY_COMPOUND,
        PlanSlot.SlotRole.SECONDARY_COMPOUND,
    )

    if is_compound_role:
        compounds = [ex for ex in available if _is_compound(ex)]
        if compounds:
            return compounds[0]

    # For isolation roles, prefer non-compounds
    if slot_role == PlanSlot.SlotRole.ISOLATION:
        isolations = [ex for ex in available if not _is_compound(ex)]
        if isolations:
            return isolations[0]

    return available[0]


def _a7_build_swap_recommendations(
    all_slots: list[PlanSlot],
    trainer_id: int | None,
    plan_id: str,
) -> DecisionLog:
    """A7: Pre-compute swap candidates for each slot."""
    # Collect all exercise IDs to fetch swap_seed_ids
    exercise_ids = [slot.exercise_id for slot in all_slots if slot.exercise_id]
    exercises_by_id: dict[int, Exercise] = {}

    if exercise_ids:
        exercises = Exercise.objects.filter(
            pk__in=exercise_ids,
        ).only(
            'id', 'primary_muscle_group', 'pattern_tags', 'swap_seed_ids',
        )
        exercises_by_id = {ex.id: ex for ex in exercises}

    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    # Track used exercise IDs within the plan to prevent duplicates
    plan_exercise_ids = set(exercise_ids)
    swap_count = 0

    for slot in all_slots:
        if not slot.exercise_id:
            continue

        exercise = exercises_by_id.get(slot.exercise_id)
        if not exercise:
            continue

        # Use pre-computed swap_seed_ids if available
        seeds = exercise.swap_seed_ids or {}
        same_muscle_ids = seeds.get('recommended_same_muscle_ids', [])
        same_pattern_ids = seeds.get('recommended_same_pattern_ids', [])

        # If no seeds, compute dynamically
        if not same_muscle_ids and exercise.primary_muscle_group:
            same_muscle_qs = Exercise.objects.filter(
                privacy_q,
                primary_muscle_group=exercise.primary_muscle_group,
            ).exclude(
                pk=exercise.pk,
            ).exclude(
                pk__in=plan_exercise_ids,
            ).values_list('pk', flat=True)[:_MAX_SWAP_PER_TAB]
            same_muscle_ids = list(same_muscle_qs)

        if not same_pattern_ids and exercise.pattern_tags:
            same_pattern_qs = Exercise.objects.filter(
                privacy_q,
                pattern_tags__overlap=exercise.pattern_tags,
            ).exclude(
                pk=exercise.pk,
            ).exclude(
                pk__in=plan_exercise_ids,
            ).values_list('pk', flat=True)[:_MAX_SWAP_PER_TAB]
            same_pattern_ids = list(same_pattern_qs)

        # Explore all: broader search
        explore_qs = Exercise.objects.filter(
            privacy_q,
        ).exclude(
            pk=exercise.pk,
        ).exclude(
            pk__in=plan_exercise_ids,
        ).values_list('pk', flat=True)[:_MAX_SWAP_PER_TAB]
        explore_ids = list(explore_qs)

        slot.swap_options_cache = {
            'same_muscle': same_muscle_ids[:_MAX_SWAP_PER_TAB],
            'same_pattern': same_pattern_ids[:_MAX_SWAP_PER_TAB],
            'explore': explore_ids[:_MAX_SWAP_PER_TAB],
        }
        swap_count += 1

    log = _log_decision(
        decision_type='plan_generation_a7_swap_recommendations',
        actor_id=trainer_id,
        context={'plan_id': plan_id},
        inputs_snapshot={'total_slots': len(all_slots)},
        constraints={},
        options=[],
        final_choice={'slots_with_swaps': swap_count},
        reason_codes=['swap_cache_built'],
    )
    return log


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

        # A3: Build skeleton
        all_weeks, all_sessions, all_slots, log_a3 = _a3_build_skeleton(
            plan=plan,
            split_template=split_template,
            weeks_count=weeks_count,
            day_indices=day_indices,
            trainer_id=request.trainer_id,
        )
        decision_log_ids.append(str(log_a3.pk))

        # A4: Assign slot roles
        log_a4 = _a4_assign_slot_roles(
            all_slots=all_slots,
            session_defs=session_defs,
            all_sessions=all_sessions,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a4.pk))

        # A5: Set set structure
        log_a5 = _a5_set_structure(
            all_slots=all_slots,
            goal=request.goal,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a5.pk))

        # A6: Select exercises
        log_a6 = _a6_select_exercises(
            all_slots=all_slots,
            all_sessions=all_sessions,
            session_defs=session_defs,
            difficulty=request.difficulty,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a6.pk))

        # A7: Build swap recommendations
        log_a7 = _a7_build_swap_recommendations(
            all_slots=all_slots,
            trainer_id=request.trainer_id,
            plan_id=str(plan.pk),
        )
        decision_log_ids.append(str(log_a7.pk))

        # Now bulk_create all slots (exercise is assigned)
        PlanSlot.objects.bulk_create(all_slots)

    return GeneratePlanResult(
        plan_id=str(plan.pk),
        plan_name=plan.name,
        weeks_count=weeks_count,
        sessions_count=len(all_sessions),
        slots_count=len(all_slots),
        decision_log_ids=decision_log_ids,
    )

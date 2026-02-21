"""
Smart Program Generator service.

Generates complete training programs based on split type, difficulty, goal,
and duration. Uses exercise database with difficulty classifications to pick
appropriate exercises for each training day.
"""
from __future__ import annotations

import logging
import random
from dataclasses import dataclass, field
from typing import Any, Literal

from django.db.models import Q

from workouts.models import Exercise

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────
# Type Aliases
# ──────────────────────────────────────────────────────────────────────────

SplitType = Literal['ppl', 'upper_lower', 'full_body', 'bro_split', 'custom']
DifficultyLevel = Literal['beginner', 'intermediate', 'advanced']
GoalType = Literal[
    'build_muscle', 'fat_loss', 'strength', 'endurance', 'recomp', 'general_fitness'
]


# ──────────────────────────────────────────────────────────────────────────
# Dataclasses (per project rules — no dicts returned from services)
# ──────────────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class CustomDayConfig:
    """Trainer-defined day configuration for custom splits."""
    day_name: str
    label: str
    muscle_groups: list[str]


@dataclass(frozen=True)
class GenerateProgramRequest:
    """Input for program generation."""
    split_type: SplitType
    difficulty: DifficultyLevel
    goal: GoalType
    duration_weeks: int
    training_days_per_week: int
    custom_day_config: list[CustomDayConfig] = field(default_factory=list)
    trainer_id: int | None = None


@dataclass(frozen=True)
class GeneratedExercise:
    """Single exercise in a generated program day."""
    exercise_id: int
    exercise_name: str
    muscle_group: str
    sets: int
    reps: str  # Can be "8-10" or "12"
    rest_seconds: int
    is_compound: bool


@dataclass(frozen=True)
class GeneratedDay:
    """Single training day in a generated program."""
    day_name: str
    label: str
    is_rest_day: bool
    exercises: list[GeneratedExercise]


@dataclass(frozen=True)
class GeneratedWeek:
    """Single week in a generated program."""
    week_number: int
    is_deload: bool
    days: list[GeneratedDay]
    intensity_modifier: float
    volume_modifier: float


@dataclass(frozen=True)
class NutritionDayTemplate:
    """Macro template for a single day type."""
    calories: int
    protein: int
    carbs: int
    fat: int


@dataclass(frozen=True)
class NutritionTemplate:
    """Nutrition recommendation for the generated program."""
    training_day: NutritionDayTemplate
    rest_day: NutritionDayTemplate
    note: str


@dataclass(frozen=True)
class GeneratedProgram:
    """Complete generated program output."""
    name: str
    description: str
    schedule: dict[str, Any]  # JSON-serializable, matches Program.schedule format
    nutrition_template: dict[str, Any]  # JSON-serializable
    difficulty_level: str
    goal_type: str
    duration_weeks: int


# ──────────────────────────────────────────────────────────────────────────
# Split Configurations
# ──────────────────────────────────────────────────────────────────────────

# Maps split type + day index → (day_label, [muscle_groups])
_SPLIT_CONFIGS: dict[SplitType, list[tuple[str, list[str]]]] = {
    'ppl': [
        ('Push', ['chest', 'shoulders', 'arms']),
        ('Pull', ['back', 'arms']),
        ('Legs', ['legs', 'glutes']),
    ],
    'upper_lower': [
        ('Upper Body', ['chest', 'back', 'shoulders', 'arms']),
        ('Lower Body', ['legs', 'glutes', 'core']),
    ],
    'full_body': [
        ('Full Body', ['chest', 'back', 'shoulders', 'arms', 'legs', 'glutes', 'core']),
    ],
    'bro_split': [
        ('Chest', ['chest']),
        ('Back', ['back']),
        ('Shoulders', ['shoulders']),
        ('Arms', ['arms']),
        ('Legs', ['legs', 'glutes']),
    ],
}

DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

# Categories that indicate compound movements (from KILO database)
_COMPOUND_CATEGORIES: set[str] = {
    'squat', 'deadlift', 'bench press', 'press', 'row', 'pull-up',
    'pull up', 'chin-up', 'chin up', 'hip hinge', 'lunge',
    'overhead press', 'clean', 'snatch', 'dip',
}


# ──────────────────────────────────────────────────────────────────────────
# Sets / Reps / Rest Scheme Tables
# ──────────────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class ExerciseScheme:
    """Sets, reps, and rest for an exercise based on goal + difficulty."""
    sets: int
    reps: str
    rest_seconds: int


# (goal, difficulty) → (compound_scheme, isolation_scheme)
_SCHEME_TABLE: dict[tuple[GoalType, DifficultyLevel], tuple[ExerciseScheme, ExerciseScheme]] = {
    # Build Muscle
    ('build_muscle', 'beginner'): (
        ExerciseScheme(3, '10-12', 90),
        ExerciseScheme(3, '12-15', 60),
    ),
    ('build_muscle', 'intermediate'): (
        ExerciseScheme(4, '8-10', 90),
        ExerciseScheme(3, '10-12', 60),
    ),
    ('build_muscle', 'advanced'): (
        ExerciseScheme(4, '6-10', 120),
        ExerciseScheme(4, '10-12', 60),
    ),
    # Strength
    ('strength', 'beginner'): (
        ExerciseScheme(3, '5', 180),
        ExerciseScheme(3, '8-10', 90),
    ),
    ('strength', 'intermediate'): (
        ExerciseScheme(4, '4-6', 180),
        ExerciseScheme(3, '6-8', 90),
    ),
    ('strength', 'advanced'): (
        ExerciseScheme(5, '3-5', 240),
        ExerciseScheme(3, '6-8', 90),
    ),
    # Fat Loss (same across difficulties)
    ('fat_loss', 'beginner'): (
        ExerciseScheme(3, '12-15', 45),
        ExerciseScheme(3, '15-20', 30),
    ),
    ('fat_loss', 'intermediate'): (
        ExerciseScheme(3, '12-15', 45),
        ExerciseScheme(3, '15-20', 30),
    ),
    ('fat_loss', 'advanced'): (
        ExerciseScheme(3, '12-15', 45),
        ExerciseScheme(3, '15-20', 30),
    ),
    # Endurance
    ('endurance', 'beginner'): (
        ExerciseScheme(2, '15-20', 30),
        ExerciseScheme(2, '15-20', 30),
    ),
    ('endurance', 'intermediate'): (
        ExerciseScheme(3, '15-20', 30),
        ExerciseScheme(3, '15-20', 30),
    ),
    ('endurance', 'advanced'): (
        ExerciseScheme(4, '15-20', 30),
        ExerciseScheme(3, '15-20', 30),
    ),
    # Recomp — blend of muscle building and fat loss
    ('recomp', 'beginner'): (
        ExerciseScheme(3, '10-12', 75),
        ExerciseScheme(3, '12-15', 45),
    ),
    ('recomp', 'intermediate'): (
        ExerciseScheme(4, '8-12', 75),
        ExerciseScheme(3, '10-12', 45),
    ),
    ('recomp', 'advanced'): (
        ExerciseScheme(4, '8-10', 90),
        ExerciseScheme(3, '10-12', 60),
    ),
    # General Fitness — moderate
    ('general_fitness', 'beginner'): (
        ExerciseScheme(3, '10-12', 60),
        ExerciseScheme(2, '12-15', 45),
    ),
    ('general_fitness', 'intermediate'): (
        ExerciseScheme(3, '8-12', 60),
        ExerciseScheme(3, '10-12', 45),
    ),
    ('general_fitness', 'advanced'): (
        ExerciseScheme(4, '8-10', 75),
        ExerciseScheme(3, '10-12', 60),
    ),
}


# ──────────────────────────────────────────────────────────────────────────
# Nutrition Templates
# ──────────────────────────────────────────────────────────────────────────

_NUTRITION_TEMPLATES: dict[GoalType, NutritionTemplate] = {
    'build_muscle': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2800, protein=200, carbs=350, fat=80),
        rest_day=NutritionDayTemplate(calories=2400, protein=200, carbs=250, fat=80),
        note="Adjust based on trainee body weight. General guideline: 1g protein per lb bodyweight.",
    ),
    'fat_loss': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2000, protein=200, carbs=200, fat=60),
        rest_day=NutritionDayTemplate(calories=1700, protein=200, carbs=120, fat=60),
        note="Adjust deficit based on trainee body weight. Aim for 500-750cal deficit from TDEE.",
    ),
    'strength': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2600, protein=180, carbs=300, fat=85),
        rest_day=NutritionDayTemplate(calories=2300, protein=180, carbs=230, fat=85),
        note="Prioritize pre/post workout carbs for performance. Slight surplus recommended.",
    ),
    'endurance': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2400, protein=150, carbs=350, fat=65),
        rest_day=NutritionDayTemplate(calories=2100, protein=150, carbs=260, fat=65),
        note="Higher carb ratio for sustained energy. Hydration is critical.",
    ),
    'recomp': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2400, protein=200, carbs=275, fat=70),
        rest_day=NutritionDayTemplate(calories=2000, protein=200, carbs=175, fat=70),
        note="Training day surplus, rest day deficit. Adjust based on body weight trends.",
    ),
    'general_fitness': NutritionTemplate(
        training_day=NutritionDayTemplate(calories=2300, protein=170, carbs=275, fat=75),
        rest_day=NutritionDayTemplate(calories=2000, protein=170, carbs=200, fat=75),
        note="Balanced macros for general health. Adjust to maintain body weight.",
    ),
}


# ──────────────────────────────────────────────────────────────────────────
# Helper Functions
# ──────────────────────────────────────────────────────────────────────────

def _is_compound(exercise: Exercise) -> bool:
    """Determine if an exercise is a compound movement based on category/name."""
    cat = (exercise.category or '').lower().strip()
    name = exercise.name.lower()

    for keyword in _COMPOUND_CATEGORIES:
        if keyword in cat or keyword in name:
            return True
    return False



def _pick_exercises_from_pool(
    pool: list[Exercise],
    count: int,
    exclude_ids: set[int],
) -> list[Exercise]:
    """
    Pick N exercises from a pre-fetched pool, ensuring variety by category.
    Prefers exercises not already used (exclude_ids).
    """
    available = [ex for ex in pool if ex.id not in exclude_ids]

    if not available:
        # If all excluded, allow repeats from the full pool
        available = list(pool)

    if not available:
        # No exercises at all for this muscle group
        return []

    # Group by category for variety
    by_category: dict[str, list[Exercise]] = {}
    for ex in available:
        cat = (ex.category or 'uncategorized').strip()
        by_category.setdefault(cat, []).append(ex)

    picked: list[Exercise] = []
    categories = list(by_category.keys())
    random.shuffle(categories)

    # Round-robin pick from different categories
    cat_idx = 0
    while len(picked) < count and categories:
        cat = categories[cat_idx % len(categories)]
        exercises_in_cat = by_category[cat]
        if exercises_in_cat:
            ex = random.choice(exercises_in_cat)
            picked.append(ex)
            exercises_in_cat.remove(ex)
            if not exercises_in_cat:
                categories.remove(cat)
        else:
            categories.remove(cat)
        cat_idx += 1

    return picked[:count]


def _prefetch_exercise_pool(
    muscle_groups: set[str],
    difficulty: DifficultyLevel,
    trainer_id: int | None,
) -> dict[str, list[Exercise]]:
    """
    Fetch ALL exercises needed for the split's muscle groups in a single query.
    Returns a dict keyed by muscle_group -> list of Exercise objects.
    Falls back to adjacent difficulty levels if not enough exercises.
    """
    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    # Determine all difficulty levels to consider
    adjacent_map: dict[DifficultyLevel, list[str]] = {
        'beginner': ['intermediate'],
        'intermediate': ['beginner', 'advanced'],
        'advanced': ['intermediate'],
    }
    all_difficulties = [difficulty] + adjacent_map.get(difficulty, [])

    # Single query: fetch all exercises for all muscle groups at relevant difficulties
    all_exercises = list(
        Exercise.objects.filter(
            Q(muscle_group__in=muscle_groups) & privacy_q &
            Q(difficulty_level__in=all_difficulties)
        )
    )

    # Build pool keyed by muscle_group
    pool: dict[str, list[Exercise]] = {mg: [] for mg in muscle_groups}
    # Prefer exact difficulty match first
    exact_match_ids: set[int] = set()
    for ex in all_exercises:
        if ex.difficulty_level == difficulty:
            pool.setdefault(ex.muscle_group, []).append(ex)
            exact_match_ids.add(ex.id)

    # For muscle groups with too few exercises at exact difficulty, include adjacent
    for mg in muscle_groups:
        if len(pool.get(mg, [])) < 3:
            for ex in all_exercises:
                if ex.muscle_group == mg and ex.id not in exact_match_ids:
                    pool.setdefault(mg, []).append(ex)

    # Last resort: for muscle groups with zero exercises, fetch any difficulty
    empty_groups = [mg for mg in muscle_groups if not pool.get(mg)]
    if empty_groups:
        fallback_exercises = list(
            Exercise.objects.filter(
                Q(muscle_group__in=empty_groups) & privacy_q
            ).exclude(difficulty_level__isnull=True)
        )
        for ex in fallback_exercises:
            pool.setdefault(ex.muscle_group, []).append(ex)

    return pool


def _get_exercise_counts_for_day(
    muscle_groups: list[str],
) -> dict[str, int]:
    """
    Determine how many exercises per muscle group for a training day.
    Primary groups get more exercises than secondary ones.
    """
    total = len(muscle_groups)
    counts: dict[str, int] = {}

    if total == 1:
        counts[muscle_groups[0]] = 5
    elif total == 2:
        counts[muscle_groups[0]] = 3
        counts[muscle_groups[1]] = 3
    elif total == 3:
        counts[muscle_groups[0]] = 3
        counts[muscle_groups[1]] = 2
        counts[muscle_groups[2]] = 2
    else:
        # Many groups (full body) — 1-2 each
        for i, mg in enumerate(muscle_groups):
            counts[mg] = 2 if i < 3 else 1

    return counts


_MAX_EXTRA_SETS: int = 3
_MAX_EXTRA_REPS: int = 5


def _apply_progressive_overload(
    base_sets: int,
    base_reps: str,
    week_number: int,
    duration_weeks: int,
) -> tuple[int, str]:
    """
    Apply progressive overload adjustments based on week number.
    +1 rep every 2 weeks, +1 set every 3 weeks on compounds.
    Deload weeks reset the overload counters (effective week resets every 4-week block).
    Extra sets capped at _MAX_EXTRA_SETS, extra reps capped at _MAX_EXTRA_REPS.
    """
    # Reset counters after deload weeks: use position within current 4-week block
    effective_week = ((week_number - 1) % 4) + 1

    extra_sets = min((effective_week - 1) // 3, _MAX_EXTRA_SETS)
    extra_reps = min((effective_week - 1) // 2, _MAX_EXTRA_REPS)

    adjusted_sets = base_sets + extra_sets

    # Parse reps with error handling for unexpected formats
    try:
        if '-' in base_reps:
            parts = base_reps.split('-')
            low = int(parts[0]) + extra_reps
            high = int(parts[1]) + extra_reps
            adjusted_reps = f"{low}-{high}"
        else:
            adjusted_reps = str(int(base_reps) + extra_reps)
    except (ValueError, IndexError):
        logger.warning("Could not parse base_reps '%s', using as-is.", base_reps)
        adjusted_reps = base_reps

    return adjusted_sets, adjusted_reps


def _is_deload_week(week_number: int, duration_weeks: int) -> bool:
    """Every 4th week is deload for programs 4+ weeks."""
    if duration_weeks < 4:
        return False
    return week_number % 4 == 0


# ──────────────────────────────────────────────────────────────────────────
# Main Generator
# ──────────────────────────────────────────────────────────────────────────

def generate_program(request: GenerateProgramRequest) -> GeneratedProgram:
    """
    Generate a complete training program based on the request parameters.

    Raises:
        ValueError: If the request is invalid (e.g., too few exercises in DB).
    """
    # Determine day layout based on split type
    if request.split_type == 'custom':
        if not request.custom_day_config:
            raise ValueError("custom_day_config is required for custom split type.")
        day_templates = [
            (cfg.label, cfg.muscle_groups) for cfg in request.custom_day_config
        ]
    else:
        base_config = _SPLIT_CONFIGS[request.split_type]
        day_templates = []
        # Repeat the split pattern to fill training_days_per_week
        for i in range(request.training_days_per_week):
            template_idx = i % len(base_config)
            day_templates.append(base_config[template_idx])

    # Get scheme for this goal + difficulty
    scheme_key = (request.goal, request.difficulty)
    compound_scheme, isolation_scheme = _SCHEME_TABLE.get(
        scheme_key,
        _SCHEME_TABLE[('build_muscle', 'intermediate')],
    )

    # Collect all muscle groups across all day templates for prefetching
    all_muscle_groups: set[str] = set()
    for _label, mgs in day_templates:
        all_muscle_groups.update(mgs)

    # Prefetch ALL exercises in a single query (fixes N+1)
    exercise_pool = _prefetch_exercise_pool(
        muscle_groups=all_muscle_groups,
        difficulty=request.difficulty,
        trainer_id=request.trainer_id,
    )

    # Track used exercises across ALL weeks for variety (M1 fix)
    used_exercise_ids: set[int] = set()

    # Build weeks
    weeks: list[GeneratedWeek] = []

    for week_num in range(1, request.duration_weeks + 1):
        is_deload = _is_deload_week(week_num, request.duration_weeks)
        intensity_mod = 0.6 if is_deload else 1.0
        volume_mod = 0.6 if is_deload else 1.0

        days: list[GeneratedDay] = []
        training_day_idx = 0

        for day_idx in range(7):
            day_name = DAY_NAMES[day_idx]

            if training_day_idx < len(day_templates):
                label, muscle_groups = day_templates[training_day_idx]
                training_day_idx += 1

                # Build exercises for this day
                exercise_counts = _get_exercise_counts_for_day(muscle_groups)
                day_exercises: list[GeneratedExercise] = []

                for mg, count in exercise_counts.items():
                    mg_pool = exercise_pool.get(mg, [])
                    picked = _pick_exercises_from_pool(
                        pool=mg_pool,
                        count=count,
                        exclude_ids=used_exercise_ids,
                    )

                    for ex in picked:
                        used_exercise_ids.add(ex.id)
                        compound = _is_compound(ex)
                        scheme = compound_scheme if compound else isolation_scheme

                        if is_deload:
                            # Deload: reduce sets and use lower end of reps
                            deload_sets = max(2, int(scheme.sets * volume_mod))
                            deload_reps = scheme.reps
                            gen_ex = GeneratedExercise(
                                exercise_id=ex.id,
                                exercise_name=ex.name,
                                muscle_group=mg,
                                sets=deload_sets,
                                reps=deload_reps,
                                rest_seconds=scheme.rest_seconds,
                                is_compound=compound,
                            )
                        else:
                            # Apply progressive overload
                            adj_sets, adj_reps = _apply_progressive_overload(
                                scheme.sets, scheme.reps,
                                week_num, request.duration_weeks,
                            )
                            gen_ex = GeneratedExercise(
                                exercise_id=ex.id,
                                exercise_name=ex.name,
                                muscle_group=mg,
                                sets=adj_sets,
                                reps=adj_reps,
                                rest_seconds=scheme.rest_seconds,
                                is_compound=compound,
                            )
                        day_exercises.append(gen_ex)

                # Sort: compounds first, then isolation
                day_exercises.sort(key=lambda e: (not e.is_compound, e.muscle_group))

                days.append(GeneratedDay(
                    day_name=day_name,
                    label=label,
                    is_rest_day=False,
                    exercises=day_exercises,
                ))
            else:
                # Rest day
                days.append(GeneratedDay(
                    day_name=day_name,
                    label='Rest',
                    is_rest_day=True,
                    exercises=[],
                ))

        weeks.append(GeneratedWeek(
            week_number=week_num,
            is_deload=is_deload,
            days=days,
            intensity_modifier=intensity_mod,
            volume_modifier=volume_mod,
        ))

    # Build nutrition template
    nutrition = _NUTRITION_TEMPLATES.get(
        request.goal,
        _NUTRITION_TEMPLATES['build_muscle'],
    )

    # Construct name and description
    split_labels = {
        'ppl': 'Push/Pull/Legs',
        'upper_lower': 'Upper/Lower',
        'full_body': 'Full Body',
        'bro_split': 'Bro Split',
        'custom': 'Custom Split',
    }
    goal_labels = {
        'build_muscle': 'Muscle Building',
        'fat_loss': 'Fat Loss',
        'strength': 'Strength',
        'endurance': 'Endurance',
        'recomp': 'Body Recomposition',
        'general_fitness': 'General Fitness',
    }

    name = f"{split_labels[request.split_type]} — {goal_labels[request.goal]}"
    description = (
        f"{request.duration_weeks}-week {request.difficulty} "
        f"{goal_labels[request.goal].lower()} program using a "
        f"{split_labels[request.split_type].lower()} split, "
        f"{request.training_days_per_week} days per week."
    )

    # Convert to JSON-serializable schedule format (matching Program.schedule)
    schedule = _to_schedule_json(weeks)
    nutrition_json = _to_nutrition_json(nutrition)

    return GeneratedProgram(
        name=name,
        description=description,
        schedule=schedule,
        nutrition_template=nutrition_json,
        difficulty_level=request.difficulty,
        goal_type=request.goal,
        duration_weeks=request.duration_weeks,
    )


# ──────────────────────────────────────────────────────────────────────────
# JSON Serialization Helpers
# ──────────────────────────────────────────────────────────────────────────

def _to_schedule_json(weeks: list[GeneratedWeek]) -> dict[str, Any]:
    """Convert generated weeks to Program.schedule JSON format."""
    return {
        'weeks': [
            {
                'week_number': week.week_number,
                'is_deload': week.is_deload,
                'intensity_modifier': week.intensity_modifier,
                'volume_modifier': week.volume_modifier,
                'days': [
                    {
                        'day': day.day_name,
                        'name': day.label,
                        'is_rest_day': day.is_rest_day,
                        'exercises': [
                            {
                                'exercise_id': ex.exercise_id,
                                'exercise_name': ex.exercise_name,
                                'muscle_group': ex.muscle_group,
                                'sets': ex.sets,
                                'reps': ex.reps,
                                'rest_seconds': ex.rest_seconds,
                                'weight': 0,
                                'unit': 'lbs',
                            }
                            for ex in day.exercises
                        ],
                    }
                    for day in week.days
                ],
            }
            for week in weeks
        ],
    }


def _to_nutrition_json(nutrition: NutritionTemplate) -> dict[str, Any]:
    """Convert nutrition template to JSON format."""
    return {
        'training_day': {
            'calories': nutrition.training_day.calories,
            'protein': nutrition.training_day.protein,
            'carbs': nutrition.training_day.carbs,
            'fat': nutrition.training_day.fat,
        },
        'rest_day': {
            'calories': nutrition.rest_day.calories,
            'protein': nutrition.rest_day.protein,
            'carbs': nutrition.rest_day.carbs,
            'fat': nutrition.rest_day.fat,
        },
        'note': nutrition.note,
    }

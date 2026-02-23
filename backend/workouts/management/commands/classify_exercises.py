"""
Management command to classify exercises by difficulty level and training goals.

Uses the configured AI provider (Anthropic/OpenAI/Google via LangChain) to
classify each exercise with:
  - difficulty_level: beginner / intermediate / advanced
  - suitable_for_goals: list of training goals the exercise is suited for

Processes exercises in batches of BATCH_SIZE, grouped by muscle_group.
Falls back to heuristic pattern-matching when AI is unavailable or fails.
Idempotent: by default only processes unclassified exercises.
"""
from __future__ import annotations

import json
import logging
import re
import time
from dataclasses import dataclass
from typing import Any

from django.core.management.base import BaseCommand, CommandParser
from django.db.models import Q, QuerySet

from workouts.models import Exercise

logger = logging.getLogger(__name__)

BATCH_SIZE = 25

VALID_LEVELS = frozenset({'beginner', 'intermediate', 'advanced'})
VALID_GOALS = frozenset({
    'build_muscle', 'fat_loss', 'strength',
    'endurance', 'recomp', 'general_fitness',
})

# ──────────────────────────────────────────────────────────────────────────
# Dataclass for classification results
# ──────────────────────────────────────────────────────────────────────────

@dataclass
class ExerciseClassification:
    """Classification result for a single exercise."""
    difficulty_level: str
    suitable_for_goals: list[str]


# ──────────────────────────────────────────────────────────────────────────
# Heuristic Fallback
# ──────────────────────────────────────────────────────────────────────────

_BEGINNER_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'\bmachine\b', re.IGNORECASE),
    re.compile(r'\bcable\b', re.IGNORECASE),
    re.compile(r'\bsmith\b', re.IGNORECASE),
    re.compile(r'\bleg press\b', re.IGNORECASE),
    re.compile(r'\bleg curl\b', re.IGNORECASE),
    re.compile(r'\bleg extension\b', re.IGNORECASE),
    re.compile(r'\blat pulldown\b', re.IGNORECASE),
    re.compile(r'\bpulldown\b', re.IGNORECASE),
    re.compile(r'\bseated row\b', re.IGNORECASE),
    re.compile(r'\bpec deck\b', re.IGNORECASE),
    re.compile(r'\bchest press\b', re.IGNORECASE),
    re.compile(r'\bhack squat\b', re.IGNORECASE),
    re.compile(r'\bassisted\b', re.IGNORECASE),
    re.compile(r'\bpulley\b', re.IGNORECASE),
]

_ADVANCED_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'\bsnatch\b', re.IGNORECASE),
    re.compile(r'\bclean\b', re.IGNORECASE),
    re.compile(r'\bjerk\b', re.IGNORECASE),
    re.compile(r'\bpistol\b', re.IGNORECASE),
    re.compile(r'\bmuscle.?up\b', re.IGNORECASE),
    re.compile(r'\bdeficit\b', re.IGNORECASE),
    re.compile(r'\bplyometric\b', re.IGNORECASE),
    re.compile(r'\bplyo\b', re.IGNORECASE),
    re.compile(r'\bexplosive\b', re.IGNORECASE),
    re.compile(r'\bfront squat\b', re.IGNORECASE),
    re.compile(r'\boverhead squat\b', re.IGNORECASE),
    re.compile(r'\bthick bar\b', re.IGNORECASE),
    re.compile(r'\bpin touch\b', re.IGNORECASE),
    re.compile(r'\bpin press\b', re.IGNORECASE),
]

# Compound movement patterns (for goal classification)
_COMPOUND_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'\bpress\b', re.IGNORECASE),
    re.compile(r'\bsquat\b', re.IGNORECASE),
    re.compile(r'\bdeadlift\b', re.IGNORECASE),
    re.compile(r'\brow\b', re.IGNORECASE),
    re.compile(r'\bpull.?up\b', re.IGNORECASE),
    re.compile(r'\bchin.?up\b', re.IGNORECASE),
    re.compile(r'\blunge\b', re.IGNORECASE),
    re.compile(r'\bthrust\b', re.IGNORECASE),
    re.compile(r'\bdip\b', re.IGNORECASE),
]


def _classify_difficulty_heuristic(name: str, category: str) -> str:
    """Classify difficulty using name/category pattern matching."""
    combined = f"{name} {category}".lower()

    for pattern in _BEGINNER_PATTERNS:
        if pattern.search(combined):
            return 'beginner'
    for pattern in _ADVANCED_PATTERNS:
        if pattern.search(combined):
            return 'advanced'

    return 'intermediate'


def _classify_goals_heuristic(name: str, category: str, difficulty: str) -> list[str]:
    """Classify training goals using heuristics."""
    combined = f"{name} {category}".lower()
    goals: list[str] = []

    is_compound = any(p.search(combined) for p in _COMPOUND_PATTERNS)

    # Almost all exercises can build muscle
    goals.append('build_muscle')

    if is_compound:
        goals.append('strength')
        goals.append('recomp')
        goals.append('fat_loss')
    else:
        goals.append('general_fitness')

    if difficulty == 'beginner':
        goals.append('endurance')
        if 'general_fitness' not in goals:
            goals.append('general_fitness')

    # Deduplicate and limit
    return list(dict.fromkeys(goals))[:4]


def _classify_heuristic(name: str, category: str) -> ExerciseClassification:
    """Full heuristic classification for one exercise."""
    difficulty = _classify_difficulty_heuristic(name, category)
    goals = _classify_goals_heuristic(name, category, difficulty)
    return ExerciseClassification(difficulty_level=difficulty, suitable_for_goals=goals)


# ──────────────────────────────────────────────────────────────────────────
# AI Classification
# ──────────────────────────────────────────────────────────────────────────

def _classify_batch_with_ai(
    exercises: list[dict[str, Any]],
) -> dict[str, ExerciseClassification]:
    """
    Classify a batch of exercises using the configured AI provider.

    Returns:
        Dict mapping exercise ID (str) -> ExerciseClassification.

    Raises:
        RuntimeError: If AI call fails or response is unparseable.
    """
    from trainer.ai_config import get_ai_config, get_api_key, AIModelConfig
    from trainer.ai_chat import get_chat_model
    from langchain_core.messages import HumanMessage
    from workouts.ai_prompts import get_exercise_classification_prompt

    config = get_ai_config()
    api_key = get_api_key(config.provider)
    if not api_key:
        raise RuntimeError(f"No API key configured for {config.provider.value}.")

    # Use low temperature for consistent classification
    gen_config = AIModelConfig(
        provider=config.provider,
        model_name=config.model_name,
        temperature=0.1,
        max_tokens=4096,
    )

    prompt = get_exercise_classification_prompt(exercises)
    llm = get_chat_model(gen_config)
    response = llm.invoke([HumanMessage(content=prompt)])

    content = str(response.content).strip()
    if not content:
        raise RuntimeError("AI returned empty response.")

    # Strip markdown code fences if present
    if content.startswith("```"):
        content = re.sub(r'^```(?:json)?\s*', '', content)
        content = re.sub(r'\s*```$', '', content)

    parsed: list[dict[str, Any]] = json.loads(content)
    result: dict[str, ExerciseClassification] = {}

    for item in parsed:
        exercise_id = str(item.get("id", ""))
        level = item.get("difficulty_level", "")
        goals_raw = item.get("suitable_for_goals", [])

        if level not in VALID_LEVELS:
            continue

        goals = [g for g in goals_raw if g in VALID_GOALS]
        if not goals:
            goals = ['build_muscle', 'general_fitness']

        result[exercise_id] = ExerciseClassification(
            difficulty_level=level,
            suitable_for_goals=goals,
        )

    return result


# ──────────────────────────────────────────────────────────────────────────
# Management Command
# ──────────────────────────────────────────────────────────────────────────

class Command(BaseCommand):
    help = (
        "Classify exercises by difficulty level and training goals. "
        "Uses the configured AI provider by default, or --heuristic for "
        "pattern-based fallback. Classifies both difficulty_level and "
        "suitable_for_goals fields."
    )

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show classifications without saving to database.",
        )
        parser.add_argument(
            "--heuristic",
            action="store_true",
            help="Use name-pattern heuristic instead of AI.",
        )
        parser.add_argument(
            "--muscle-group",
            type=str,
            default=None,
            help="Only classify exercises in this muscle group (e.g., 'chest').",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Re-classify ALL exercises, even those already classified.",
        )
        parser.add_argument(
            "--batch-size",
            type=int,
            default=BATCH_SIZE,
            help=f"Number of exercises per AI batch (default: {BATCH_SIZE}).",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        dry_run: bool = options["dry_run"]
        use_heuristic: bool = options["heuristic"]
        muscle_group_filter: str | None = options["muscle_group"]
        force: bool = options["force"]
        batch_size: int = options["batch_size"]

        # Build queryset
        qs: QuerySet[Exercise] = Exercise.objects.all()

        if not force:
            # Only exercises missing difficulty OR goals
            qs = qs.filter(
                Q(difficulty_level__isnull=True)
                | Q(difficulty_level='')
                | Q(suitable_for_goals=[])
            )

        if muscle_group_filter:
            valid_groups = {c[0] for c in Exercise.MuscleGroup.choices}
            if muscle_group_filter not in valid_groups:
                self.stderr.write(
                    self.style.ERROR(
                        f"Invalid muscle_group '{muscle_group_filter}'. "
                        f"Valid: {', '.join(sorted(valid_groups))}"
                    )
                )
                return
            qs = qs.filter(muscle_group=muscle_group_filter)

        total = qs.count()
        if total == 0:
            self.stdout.write(self.style.SUCCESS("All exercises are already classified."))
            return

        method = "heuristic" if use_heuristic else "AI"
        self.stdout.write(
            f"{'[DRY RUN] ' if dry_run else ''}"
            f"Classifying {total} exercises using {method}..."
        )

        if use_heuristic:
            self._classify_heuristic(qs, dry_run)
        else:
            self._classify_ai(qs, dry_run, batch_size)

    def _classify_heuristic(
        self, qs: QuerySet[Exercise], dry_run: bool
    ) -> None:
        """Classify exercises using name/category pattern matching."""
        updates: list[Exercise] = []
        counts: dict[str, int] = {'beginner': 0, 'intermediate': 0, 'advanced': 0}

        for exercise in qs.iterator():
            result = _classify_heuristic(exercise.name, exercise.category)
            counts[result.difficulty_level] += 1

            if dry_run:
                self.stdout.write(
                    f"  [{exercise.muscle_group}] {exercise.name}"
                    f" → {result.difficulty_level}"
                    f" | goals: {', '.join(result.suitable_for_goals)}"
                )
            else:
                exercise.difficulty_level = result.difficulty_level
                exercise.suitable_for_goals = result.suitable_for_goals
                updates.append(exercise)

        if not dry_run and updates:
            Exercise.objects.bulk_update(
                updates, ['difficulty_level', 'suitable_for_goals'], batch_size=200
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"\n{'[DRY RUN] ' if dry_run else ''}"
                f"Heuristic classification complete: "
                f"beginner={counts['beginner']}, "
                f"intermediate={counts['intermediate']}, "
                f"advanced={counts['advanced']}, "
                f"total={sum(counts.values())}"
            )
        )

    def _classify_ai(
        self, qs: QuerySet[Exercise], dry_run: bool, batch_size: int
    ) -> None:
        """Classify exercises using AI, batched by muscle_group."""
        muscle_groups = list(
            qs.values_list('muscle_group', flat=True)
            .distinct()
            .order_by('muscle_group')
        )

        total_classified = 0
        total_ai_ok = 0
        total_heuristic_fallback = 0
        counts: dict[str, int] = {'beginner': 0, 'intermediate': 0, 'advanced': 0}
        goal_counts: dict[str, int] = {g: 0 for g in VALID_GOALS}

        for mg in muscle_groups:
            mg_exercises = list(
                qs.filter(muscle_group=mg)
                .values('id', 'name', 'muscle_group', 'category')
            )
            self.stdout.write(f"\n  {mg.upper()}: {len(mg_exercises)} exercises")

            for i in range(0, len(mg_exercises), batch_size):
                batch = mg_exercises[i:i + batch_size]
                batch_num = i // batch_size + 1
                total_batches = (len(mg_exercises) + batch_size - 1) // batch_size
                self.stdout.write(
                    f"    Batch {batch_num}/{total_batches} "
                    f"({len(batch)} exercises)...",
                    ending="",
                )

                batch_data = [
                    {
                        'id': str(ex['id']),
                        'name': ex['name'],
                        'muscle_group': ex['muscle_group'],
                        'category': ex['category'] or '',
                    }
                    for ex in batch
                ]

                # Try AI classification
                ai_results: dict[str, ExerciseClassification] = {}
                try:
                    ai_results = _classify_batch_with_ai(batch_data)
                    self.stdout.write(f" AI OK ({len(ai_results)}/{len(batch)} parsed)")
                except Exception as exc:
                    self.stderr.write(
                        self.style.WARNING(
                            f" AI failed: {exc}. Using heuristic fallback."
                        )
                    )

                # Apply results (AI with heuristic fallback per exercise)
                updates: list[Exercise] = []
                for ex_dict in batch:
                    ex_id = str(ex_dict['id'])
                    name = ex_dict['name']
                    category = ex_dict.get('category', '')

                    ai_result = ai_results.get(ex_id)
                    if ai_result:
                        classification = ai_result
                        total_ai_ok += 1
                    else:
                        classification = _classify_heuristic(name, category)
                        total_heuristic_fallback += 1

                    counts[classification.difficulty_level] += 1
                    for g in classification.suitable_for_goals:
                        goal_counts[g] = goal_counts.get(g, 0) + 1

                    if dry_run:
                        src = "AI" if ai_result else "heuristic"
                        self.stdout.write(
                            f"      [{ex_id}] {name}"
                            f" → {classification.difficulty_level}"
                            f" | {', '.join(classification.suitable_for_goals)}"
                            f" ({src})"
                        )
                    else:
                        ex_obj = Exercise(id=int(ex_id))
                        ex_obj.difficulty_level = classification.difficulty_level
                        ex_obj.suitable_for_goals = classification.suitable_for_goals
                        updates.append(ex_obj)
                        total_classified += 1

                if not dry_run and updates:
                    Exercise.objects.bulk_update(
                        updates,
                        ['difficulty_level', 'suitable_for_goals'],
                        batch_size=200,
                    )

                # Rate-limit between batches to avoid API throttling
                if i + batch_size < len(mg_exercises):
                    time.sleep(1)

        # Summary
        self.stdout.write("")
        self.stdout.write(
            self.style.SUCCESS(
                f"{'[DRY RUN] ' if dry_run else ''}"
                f"Classification complete!"
            )
        )
        self.stdout.write(f"  Difficulty: "
                          f"beginner={counts['beginner']}, "
                          f"intermediate={counts['intermediate']}, "
                          f"advanced={counts['advanced']}")
        self.stdout.write(f"  Goals: " + ", ".join(
            f"{g}={c}" for g, c in sorted(goal_counts.items()) if c > 0
        ))
        self.stdout.write(f"  Total: {sum(counts.values())} exercises")
        self.stdout.write(f"  AI classified: {total_ai_ok}")
        self.stdout.write(f"  Heuristic fallback: {total_heuristic_fallback}")

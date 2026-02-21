"""
Management command to classify exercises by difficulty level.

Supports AI-powered classification via OpenAI GPT-4o and a local heuristic fallback.
Idempotent: only processes exercises where difficulty_level is NULL.
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any

from django.conf import settings
from django.core.management.base import BaseCommand, CommandParser
from django.db.models import QuerySet

from workouts.models import Exercise

logger = logging.getLogger(__name__)

# Batch size for OpenAI API calls (grouped by muscle_group)
BATCH_SIZE = 30

# Heuristic patterns for fallback classification
_BEGINNER_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'\bmachine\b', re.IGNORECASE),
    re.compile(r'\bcable\b', re.IGNORECASE),
    re.compile(r'\bsmith\b', re.IGNORECASE),
    re.compile(r'\bleg press\b', re.IGNORECASE),
    re.compile(r'\bleg curl\b', re.IGNORECASE),
    re.compile(r'\bleg extension\b', re.IGNORECASE),
    re.compile(r'\blat pulldown\b', re.IGNORECASE),
    re.compile(r'\bseated row\b', re.IGNORECASE),
    re.compile(r'\bpec deck\b', re.IGNORECASE),
    re.compile(r'\bchest press\b', re.IGNORECASE),
    re.compile(r'\bshoulder press machine\b', re.IGNORECASE),
    re.compile(r'\bhack squat\b', re.IGNORECASE),
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
    re.compile(r'\bkettlebell swing\b', re.IGNORECASE),
    re.compile(r'\bfront squat\b', re.IGNORECASE),
    re.compile(r'\boverhead squat\b', re.IGNORECASE),
    re.compile(r'\bpower clean\b', re.IGNORECASE),
    re.compile(r'\bsumo deadlift\b', re.IGNORECASE),
]

_BEGINNER_CATEGORIES: set[str] = {
    'cable fly', 'cable crossover', 'cable curl', 'cable tricep',
    'machine press', 'machine fly', 'machine row', 'machine curl',
    'leg press', 'leg curl', 'leg extension', 'calf raise machine',
    'lat pulldown', 'seated row', 'pec deck',
}

_ADVANCED_CATEGORIES: set[str] = {
    'snatch', 'clean', 'jerk', 'clean and jerk', 'power clean',
    'muscle up', 'pistol squat', 'plyo',
}

VALID_LEVELS = frozenset({'beginner', 'intermediate', 'advanced'})


def _classify_by_heuristic(name: str, category: str) -> str:
    """Classify an exercise using name/category pattern matching."""
    combined = f"{name} {category}".lower()

    # Check category-based overrides first
    cat_lower = category.lower().strip()
    if cat_lower in _BEGINNER_CATEGORIES:
        return 'beginner'
    if cat_lower in _ADVANCED_CATEGORIES:
        return 'advanced'

    # Check name patterns
    for pattern in _BEGINNER_PATTERNS:
        if pattern.search(combined):
            return 'beginner'
    for pattern in _ADVANCED_PATTERNS:
        if pattern.search(combined):
            return 'advanced'

    # Default: intermediate (free weight compounds and isolation)
    return 'intermediate'


def _classify_batch_with_openai(
    exercises: list[dict[str, str]],
) -> dict[str, str]:
    """
    Classify a batch of exercises using OpenAI GPT-4o.

    Returns:
        Dict mapping exercise name -> difficulty_level.

    Raises:
        RuntimeError: If OpenAI API call fails or response is unparseable.
    """
    import openai

    from workouts.ai_prompts import get_exercise_classification_prompt

    api_key = getattr(settings, 'OPENAI_API_KEY', None)
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not configured in settings.")

    client = openai.OpenAI(api_key=api_key)
    prompt = get_exercise_classification_prompt(exercises)

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1,
        max_tokens=4096,
    )

    content = response.choices[0].message.content
    if not content:
        raise RuntimeError("OpenAI returned empty response.")

    # Strip markdown code fences if present
    content = content.strip()
    if content.startswith("```"):
        content = re.sub(r'^```(?:json)?\s*', '', content)
        content = re.sub(r'\s*```$', '', content)

    parsed: list[dict[str, str]] = json.loads(content)
    result: dict[str, str] = {}
    for item in parsed:
        name = item.get("name", "")
        level = item.get("difficulty_level", "")
        if name and level in VALID_LEVELS:
            result[name] = level
    return result


class Command(BaseCommand):
    help = (
        "Classify exercises by difficulty level (beginner/intermediate/advanced). "
        "Uses OpenAI by default, or --heuristic for pattern-based fallback."
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
            help="Use name-pattern heuristic instead of OpenAI API.",
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
            help="Re-classify exercises that already have a difficulty_level.",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        dry_run: bool = options["dry_run"]
        use_heuristic: bool = options["heuristic"]
        muscle_group_filter: str | None = options["muscle_group"]
        force: bool = options["force"]

        # Build queryset
        qs: QuerySet[Exercise] = Exercise.objects.filter(is_public=True)

        if not force:
            qs = qs.filter(difficulty_level__isnull=True)

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
            self.stdout.write(self.style.SUCCESS("No exercises to classify."))
            return

        self.stdout.write(
            f"{'[DRY RUN] ' if dry_run else ''}"
            f"Classifying {total} exercises "
            f"using {'heuristic' if use_heuristic else 'OpenAI GPT-4o'}..."
        )

        if use_heuristic:
            self._classify_heuristic(qs, dry_run)
        else:
            self._classify_openai(qs, dry_run)

    def _classify_heuristic(
        self, qs: QuerySet[Exercise], dry_run: bool
    ) -> None:
        """Classify exercises using name/category pattern matching."""
        updates: list[Exercise] = []
        counts: dict[str, int] = {'beginner': 0, 'intermediate': 0, 'advanced': 0}

        for exercise in qs.iterator():
            level = _classify_by_heuristic(exercise.name, exercise.category)
            counts[level] += 1

            if dry_run:
                self.stdout.write(
                    f"  [{exercise.muscle_group}] {exercise.name} → {level}"
                )
            else:
                exercise.difficulty_level = level
                updates.append(exercise)

        if not dry_run and updates:
            Exercise.objects.bulk_update(updates, ['difficulty_level'], batch_size=200)

        self.stdout.write(
            self.style.SUCCESS(
                f"{'[DRY RUN] ' if dry_run else ''}"
                f"Classification complete: "
                f"beginner={counts['beginner']}, "
                f"intermediate={counts['intermediate']}, "
                f"advanced={counts['advanced']}"
            )
        )

    def _classify_openai(
        self, qs: QuerySet[Exercise], dry_run: bool
    ) -> None:
        """Classify exercises using OpenAI, batched by muscle_group."""
        # Group exercises by muscle_group for better context
        muscle_groups = (
            qs.values_list('muscle_group', flat=True).distinct().order_by('muscle_group')
        )

        total_classified = 0
        total_failed = 0
        counts: dict[str, int] = {'beginner': 0, 'intermediate': 0, 'advanced': 0}

        for mg in muscle_groups:
            mg_exercises = list(
                qs.filter(muscle_group=mg).values('id', 'name', 'muscle_group', 'category')
            )
            self.stdout.write(f"\n  Processing {mg}: {len(mg_exercises)} exercises")

            # Process in batches
            for i in range(0, len(mg_exercises), BATCH_SIZE):
                batch = mg_exercises[i:i + BATCH_SIZE]
                batch_data = [
                    {
                        'name': ex['name'],
                        'muscle_group': ex['muscle_group'],
                        'category': ex['category'] or '',
                    }
                    for ex in batch
                ]

                try:
                    classifications = _classify_batch_with_openai(batch_data)
                except Exception as exc:
                    self.stderr.write(
                        self.style.WARNING(
                            f"    OpenAI failed for batch {i // BATCH_SIZE + 1}: {exc}. "
                            f"Falling back to heuristic for {len(batch)} exercises."
                        )
                    )
                    # Heuristic fallback for this batch
                    classifications = {
                        ex['name']: _classify_by_heuristic(ex['name'], ex['category'] or '')
                        for ex in batch
                    }

                # Apply classifications
                updates: list[Exercise] = []
                for ex_dict in batch:
                    name = ex_dict['name']
                    level = classifications.get(name)
                    if not level or level not in VALID_LEVELS:
                        # Fallback to heuristic if AI missed this exercise
                        level = _classify_by_heuristic(name, ex_dict.get('category', ''))

                    counts[level] += 1

                    if dry_run:
                        self.stdout.write(f"    {name} → {level}")
                    else:
                        # Find matching exercise in batch
                        matching = [e for e in batch if e['name'] == name]
                        if matching:
                            ex_obj = Exercise(id=matching[0]['id'])
                            ex_obj.difficulty_level = level
                            updates.append(ex_obj)
                            total_classified += 1

                if not dry_run and updates:
                    Exercise.objects.bulk_update(updates, ['difficulty_level'], batch_size=200)

        self.stdout.write(
            self.style.SUCCESS(
                f"\n{'[DRY RUN] ' if dry_run else ''}"
                f"Classification complete: "
                f"beginner={counts['beginner']}, "
                f"intermediate={counts['intermediate']}, "
                f"advanced={counts['advanced']}, "
                f"total={sum(counts.values())}"
            )
        )

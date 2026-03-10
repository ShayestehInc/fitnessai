"""
Management command to backfill existing exercises with v6.5 tag data.

Maps the legacy muscle_group field to:
  - primary_muscle_group (DetailedMuscleGroup)
  - muscle_contribution_map (approximate)
  - pattern_tags (based on category/name heuristics)

This is a best-effort backfill. Trainers should review and refine tags.

Usage:
    python manage.py backfill_exercise_tags
    python manage.py backfill_exercise_tags --dry-run
"""
from __future__ import annotations

from django.core.management.base import BaseCommand, CommandParser

from workouts.models import Exercise


# Mapping legacy muscle_group → primary DetailedMuscleGroup + default contribution map
LEGACY_TO_DETAILED: dict[str, dict[str, object]] = {
    'chest': {
        'primary': 'chest',
        'contribution': {'chest': 0.6, 'front_delts': 0.2, 'triceps': 0.2},
    },
    'back': {
        'primary': 'lats',
        'contribution': {'lats': 0.4, 'mid_back': 0.3, 'biceps': 0.2, 'rear_delts': 0.1},
    },
    'shoulders': {
        'primary': 'side_delts',
        'contribution': {'side_delts': 0.4, 'front_delts': 0.3, 'rear_delts': 0.3},
    },
    'arms': {
        'primary': 'biceps',
        'contribution': {'biceps': 0.4, 'triceps': 0.4, 'forearms_and_grip': 0.2},
    },
    'legs': {
        'primary': 'quads',
        'contribution': {'quads': 0.4, 'hamstrings': 0.3, 'glutes': 0.2, 'calves': 0.1},
    },
    'glutes': {
        'primary': 'glutes',
        'contribution': {'glutes': 0.6, 'hamstrings': 0.3, 'quads': 0.1},
    },
    'core': {
        'primary': 'abs_rectus',
        'contribution': {'abs_rectus': 0.4, 'obliques': 0.3, 'deep_core': 0.3},
    },
    'full_body': {
        'primary': 'quads',
        'contribution': {'quads': 0.2, 'glutes': 0.2, 'chest': 0.15, 'lats': 0.15, 'abs_rectus': 0.15, 'front_delts': 0.15},
    },
}

# Name-based heuristics for pattern_tags
NAME_TO_PATTERN: dict[str, list[str]] = {
    'squat': ['knee_dominant'],
    'lunge': ['knee_dominant'],
    'leg press': ['knee_dominant'],
    'leg extension': ['knee_dominant'],
    'step up': ['knee_dominant'],
    'deadlift': ['hip_dominant'],
    'hip thrust': ['hip_dominant'],
    'rdl': ['hip_dominant'],
    'romanian': ['hip_dominant'],
    'good morning': ['hip_dominant'],
    'glute bridge': ['hip_dominant'],
    'hamstring curl': ['hip_dominant'],
    'bench press': ['horizontal_push'],
    'push up': ['horizontal_push'],
    'pushup': ['horizontal_push'],
    'chest press': ['horizontal_push'],
    'dumbbell press': ['horizontal_push'],
    'incline press': ['horizontal_push'],
    'dip': ['horizontal_push'],
    'row': ['horizontal_pull'],
    'cable row': ['horizontal_pull'],
    'bent over row': ['horizontal_pull'],
    'face pull': ['horizontal_pull'],
    'overhead press': ['vertical_push'],
    'military press': ['vertical_push'],
    'shoulder press': ['vertical_push'],
    'lateral raise': ['vertical_push'],
    'pull up': ['vertical_pull'],
    'pullup': ['vertical_pull'],
    'chin up': ['vertical_pull'],
    'lat pulldown': ['vertical_pull'],
    'pulldown': ['vertical_pull'],
    'plank': ['trunk_anti_extension'],
    'dead bug': ['trunk_anti_extension'],
    'crunch': ['pelvis_flexion_emphasis'],
    'sit up': ['pelvis_flexion_emphasis'],
    'back extension': ['pelvis_extension_emphasis'],
    'russian twist': ['trunk_rotation'],
    'wood chop': ['trunk_rotation'],
    'pallof': ['trunk_anti_rotation'],
    'side plank': ['trunk_anti_lateral_flexion'],
    'farmer': ['carries'],
    'carry': ['carries'],
    'suitcase': ['carries'],
    'walk': ['locomotion'],
    'run': ['locomotion'],
    'sprint': ['locomotion'],
}


class Command(BaseCommand):
    help = "Backfill existing exercises with v6.5 tag data based on legacy muscle_group and name heuristics."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help="Show what would be updated without saving.",
        )

    def handle(self, *args: object, **options: object) -> None:
        dry_run = bool(options.get('dry_run', False))
        total_count = Exercise.objects.count()
        to_update: list[Exercise] = []
        update_fields = {'primary_muscle_group', 'muscle_contribution_map', 'pattern_tags'}

        for exercise in Exercise.objects.iterator(chunk_size=500):
            changed = False
            name_lower = exercise.name.lower()

            # Map legacy muscle_group → primary_muscle_group + contribution map
            if not exercise.primary_muscle_group and exercise.muscle_group in LEGACY_TO_DETAILED:
                mapping = LEGACY_TO_DETAILED[exercise.muscle_group]
                exercise.primary_muscle_group = str(mapping['primary'])
                if not exercise.muscle_contribution_map:
                    exercise.muscle_contribution_map = dict(mapping['contribution'])  # type: ignore[arg-type]
                changed = True

            # Name-based pattern_tags
            if not exercise.pattern_tags:
                tags: list[str] = []
                for keyword, pattern_list in NAME_TO_PATTERN.items():
                    if keyword in name_lower:
                        tags.extend(pattern_list)
                if tags:
                    exercise.pattern_tags = list(set(tags))
                    changed = True

            if changed:
                if dry_run:
                    self.stdout.write(
                        f"  [DRY RUN] {exercise.name}: "
                        f"primary={exercise.primary_muscle_group}, "
                        f"tags={exercise.pattern_tags}, "
                        f"map_keys={list(exercise.muscle_contribution_map.keys()) if exercise.muscle_contribution_map else []}"
                    )
                to_update.append(exercise)

        if not dry_run and to_update:
            Exercise.objects.bulk_update(to_update, list(update_fields), batch_size=200)

        action = "Would update" if dry_run else "Updated"
        self.stdout.write(self.style.SUCCESS(
            f"{action} {len(to_update)} of {total_count} exercises."
        ))

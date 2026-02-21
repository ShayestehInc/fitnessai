"""
Management command to seed exercises from the KILO Strength Society Exercise Database 2023.
Imports 800+ exercises organized by muscle group with KILO category metadata.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from django.core.management.base import BaseCommand

from workouts.models import Exercise


class Command(BaseCommand):
    help = "Seeds the database with exercises from the KILO Exercise Database 2023"

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be imported without making changes",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        fixture_path = (
            Path(__file__).resolve().parent.parent.parent
            / "fixtures"
            / "kilo_exercises.json"
        )

        if not fixture_path.exists():
            self.stderr.write(
                self.style.ERROR(f"Fixture file not found: {fixture_path}")
            )
            return

        with open(fixture_path, "r") as f:
            exercises_data: list[dict[str, str]] = json.load(f)

        dry_run: bool = options["dry_run"]

        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f"DRY RUN: Would import {len(exercises_data)} exercises"
                )
            )
            for ex in exercises_data:
                self.stdout.write(
                    f"  [{ex['muscle_group']}] {ex['name']} "
                    f"(category: {ex['category']})"
                )
            return

        created_count = 0
        updated_count = 0
        skipped_count = 0

        # Compute valid groups once outside the loop
        valid_groups: set[str] = {c[0] for c in Exercise.MuscleGroup.choices}

        for exercise_data in exercises_data:
            name = exercise_data["name"]
            muscle_group = exercise_data["muscle_group"]
            category = exercise_data["category"]
            video_url = exercise_data.get("video_url") or None

            # Validate muscle_group against model choices
            if muscle_group not in valid_groups:
                self.stderr.write(
                    self.style.WARNING(
                        f"Skipping '{name}': invalid muscle_group '{muscle_group}'"
                    )
                )
                skipped_count += 1
                continue

            description = f"KILO category: {category}"

            defaults: dict[str, Any] = {
                "muscle_group": muscle_group,
                "category": category,
                "is_public": True,
                "created_by": None,
            }

            # Only set description if creating new (don't overwrite existing descriptions)
            # Only set video_url if we have one and the exercise is new or has no video
            exercise, created = Exercise.objects.get_or_create(
                name=name,
                defaults={
                    **defaults,
                    "description": description,
                    "video_url": video_url,
                },
            )

            if created:
                created_count += 1
            else:
                # Update muscle_group if it was 'other' (placeholder)
                changed = False
                if exercise.muscle_group == Exercise.MuscleGroup.OTHER:
                    exercise.muscle_group = muscle_group
                    changed = True
                if video_url and not exercise.video_url:
                    exercise.video_url = video_url
                    changed = True
                if not exercise.category and category:
                    exercise.category = category
                    changed = True
                if changed:
                    exercise.save()
                    updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"KILO Exercise Database import complete: "
                f"{created_count} created, {updated_count} updated, "
                f"{skipped_count} skipped. "
                f"Total public exercises: "
                f"{Exercise.objects.filter(is_public=True).count()}"
            )
        )

"""
Management command to fetch high-quality exercise images from Pexels
using AI-optimized search queries.

Usage:
    python manage.py fetch_exercise_images --pexels-key YOUR_KEY
    python manage.py fetch_exercise_images --pexels-key YOUR_KEY --force
    python manage.py fetch_exercise_images --pexels-key YOUR_KEY --dry-run

Or set PEXELS_API_KEY environment variable:
    export PEXELS_API_KEY=YOUR_KEY
    python manage.py fetch_exercise_images
"""
from __future__ import annotations

import os
import time
import uuid
from pathlib import Path
from typing import Any

import httpx
from openai import OpenAI

from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.core.management.base import BaseCommand, CommandError
from django.utils.text import slugify

from workouts.models import Exercise


PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"
# Pexels rate limit: 200 requests/hour.
# Use 3s delay — faster, recovers from 429s with a 60s wait.
PEXELS_REQUEST_DELAY = 3.0
OPENAI_BATCH_SIZE = 25  # exercises per OpenAI batch call


class Command(BaseCommand):
    help = "Fetches high-quality exercise images from Pexels using AI-optimized search queries"

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            "--pexels-key",
            type=str,
            default="",
            help="Pexels API key (or set PEXELS_API_KEY env var)",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Re-fetch images even if exercise already has a local image",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be done without downloading",
        )
        parser.add_argument(
            "--skip-ai",
            action="store_true",
            help="Skip OpenAI query optimization, use exercise name directly",
        )
        parser.add_argument(
            "--limit",
            type=int,
            default=0,
            help="Limit number of exercises to process (0 = all)",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        pexels_key = options["pexels_key"] or os.environ.get("PEXELS_API_KEY", "")
        if not pexels_key:
            raise CommandError(
                "Pexels API key required. Use --pexels-key or set PEXELS_API_KEY env var.\n"
                "Get a free key at: https://www.pexels.com/api/"
            )

        force: bool = options["force"]
        dry_run: bool = options["dry_run"]
        skip_ai: bool = options["skip_ai"]
        limit: int = options["limit"]

        # Get exercises to process
        exercises = list(
            Exercise.objects.filter(is_public=True).order_by("muscle_group", "name")
        )

        if not force:
            # Skip exercises that already have a locally-stored image
            media_url = getattr(settings, "MEDIA_URL", "media/")
            exercises = [
                ex for ex in exercises
                if not ex.image_url or not ex.image_url.startswith(media_url)
            ]

        if limit > 0:
            exercises = exercises[:limit]

        if not exercises:
            self.stdout.write(self.style.SUCCESS("All exercises already have images. Use --force to re-fetch."))
            return

        self.stdout.write(f"Processing {len(exercises)} exercises...")

        # Step 1: Generate optimized search queries
        if skip_ai:
            search_queries = {
                ex.name: f"{ex.name} exercise gym fitness"
                for ex in exercises
            }
            self.stdout.write("Using exercise names as search queries (--skip-ai)")
        else:
            search_queries = self._generate_search_queries(exercises)

        # Step 2: Search Pexels and download images
        media_root = Path(settings.MEDIA_ROOT)
        exercises_dir = media_root / "exercises"
        exercises_dir.mkdir(parents=True, exist_ok=True)

        success_count = 0
        fail_count = 0
        skip_count = 0

        with httpx.Client(timeout=30.0) as client:
            for i, exercise in enumerate(exercises, 1):
                query = search_queries.get(exercise.name, f"{exercise.name} exercise")
                self.stdout.write(
                    f"[{i}/{len(exercises)}] {exercise.name} -> \"{query}\""
                )

                if dry_run:
                    self.stdout.write(self.style.NOTICE("  (dry-run) Would search and download"))
                    continue

                try:
                    image_url = self._search_pexels(client, pexels_key, query)
                    if not image_url:
                        # Retry with simpler query
                        fallback_query = f"{exercise.muscle_group} exercise gym"
                        self.stdout.write(
                            self.style.WARNING(f"  No results, trying fallback: \"{fallback_query}\"")
                        )
                        image_url = self._search_pexels(client, pexels_key, fallback_query)

                    if not image_url:
                        self.stdout.write(self.style.ERROR(f"  No image found, skipping"))
                        fail_count += 1
                        continue

                    # Download the image
                    saved_path = self._download_and_save(client, exercise, image_url)
                    if saved_path:
                        # Build the full URL that the app will serve
                        full_url = f"{settings.MEDIA_URL}{saved_path}"
                        old_url = exercise.image_url
                        exercise.image_url = full_url
                        exercise.save(update_fields=["image_url"])
                        self.stdout.write(self.style.SUCCESS(f"  Saved: {saved_path}"))

                        # Clean up old local file if it was in media/exercises/
                        if old_url and "exercises/" in old_url and old_url != full_url:
                            old_path = old_url.replace(settings.MEDIA_URL, "", 1)
                            if default_storage.exists(old_path):
                                default_storage.delete(old_path)

                        success_count += 1
                    else:
                        fail_count += 1

                except httpx.HTTPStatusError as e:
                    if e.response.status_code == 429:
                        self.stdout.write(self.style.ERROR(
                            "  Rate limited by Pexels! Waiting 60s..."
                        ))
                        time.sleep(60)
                        fail_count += 1
                    else:
                        self.stdout.write(self.style.ERROR(f"  HTTP error: {e}"))
                        fail_count += 1
                except (httpx.RequestError, OSError) as e:
                    self.stdout.write(self.style.ERROR(f"  Error: {e}"))
                    fail_count += 1

                # Rate limit delay
                time.sleep(PEXELS_REQUEST_DELAY)

        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS(
            f"Done! Success: {success_count}, Failed: {fail_count}, Skipped: {skip_count}"
        ))

    def _generate_search_queries(
        self, exercises: list[Exercise]
    ) -> dict[str, str]:
        """Use OpenAI to generate optimized Pexels search queries for exercises."""
        openai_key = os.environ.get("OPENAI_API_KEY", "")
        if not openai_key:
            self.stdout.write(self.style.WARNING(
                "OPENAI_API_KEY not set, using exercise names as search queries"
            ))
            return {
                ex.name: f"{ex.name} exercise gym fitness"
                for ex in exercises
            }

        client = OpenAI(api_key=openai_key)
        queries: dict[str, str] = {}

        # Process in batches
        for batch_start in range(0, len(exercises), OPENAI_BATCH_SIZE):
            batch = exercises[batch_start:batch_start + OPENAI_BATCH_SIZE]
            exercise_list = "\n".join(
                f"- {ex.name} (muscle group: {ex.muscle_group})"
                for ex in batch
            )

            self.stdout.write(
                f"Generating search queries for batch "
                f"{batch_start // OPENAI_BATCH_SIZE + 1}/"
                f"{(len(exercises) - 1) // OPENAI_BATCH_SIZE + 1}..."
            )

            try:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    temperature=0.3,
                    messages=[
                        {
                            "role": "system",
                            "content": (
                                "You are an expert at finding stock photography. "
                                "Given a list of gym/fitness exercises, generate the best "
                                "Pexels search query for each that will return a high-quality "
                                "photo showing that specific exercise being performed.\n\n"
                                "Rules:\n"
                                "- Keep queries to 3-6 words\n"
                                "- Focus on the exercise movement, not equipment brand names\n"
                                "- Use common photography terms that stock photo sites index well\n"
                                "- Include 'gym' or 'fitness' when it helps find relevant results\n"
                                "- For machine exercises, describe the movement pattern\n"
                                "- For bodyweight exercises, describe the position\n\n"
                                "Return ONLY a JSON object mapping exercise name to search query. "
                                "No markdown formatting, no code blocks, just raw JSON."
                            ),
                        },
                        {
                            "role": "user",
                            "content": f"Generate Pexels search queries for:\n{exercise_list}",
                        },
                    ],
                )

                content = response.choices[0].message.content or ""
                # Strip markdown code blocks if present
                content = content.strip()
                if content.startswith("```"):
                    content = content.split("\n", 1)[1] if "\n" in content else content[3:]
                if content.endswith("```"):
                    content = content[:-3]
                content = content.strip()

                import json
                batch_queries = json.loads(content)
                queries.update(batch_queries)

            except Exception as e:
                self.stdout.write(self.style.WARNING(
                    f"  OpenAI batch failed ({e}), using exercise names"
                ))
                for ex in batch:
                    queries[ex.name] = f"{ex.name} exercise gym fitness"

        return queries

    def _search_pexels(
        self,
        client: httpx.Client,
        api_key: str,
        query: str,
    ) -> str | None:
        """Search Pexels for an image and return the medium-size URL."""
        response = client.get(
            PEXELS_SEARCH_URL,
            headers={"Authorization": api_key},
            params={
                "query": query,
                "per_page": 5,
                "orientation": "square",
                "size": "medium",
            },
        )
        response.raise_for_status()
        data = response.json()

        photos = data.get("photos", [])
        if not photos:
            return None

        # Pick the first (most relevant) photo, use medium size (350x350-ish)
        photo = photos[0]
        return photo["src"].get("medium") or photo["src"].get("large")

    def _download_and_save(
        self,
        client: httpx.Client,
        exercise: Exercise,
        image_url: str,
    ) -> str | None:
        """Download image from URL and save to local media storage."""
        response = client.get(image_url, follow_redirects=True)
        response.raise_for_status()

        content_type = response.headers.get("content-type", "")
        if "jpeg" in content_type or "jpg" in content_type:
            ext = ".jpg"
        elif "png" in content_type:
            ext = ".png"
        elif "webp" in content_type:
            ext = ".webp"
        else:
            ext = ".jpg"  # Default to jpg for Pexels

        slug = slugify(exercise.name)[:50]
        short_id = uuid.uuid4().hex[:8]
        filename = f"exercises/{slug}-{short_id}{ext}"

        saved_path = default_storage.save(filename, ContentFile(response.content))
        return saved_path

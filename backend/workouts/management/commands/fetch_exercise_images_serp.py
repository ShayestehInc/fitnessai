"""
Temporary management command to fetch exercise images via SerpAPI Google Images,
verify quality/relevance using OpenAI GPT-4o vision, and generate comprehensive
exercise descriptions.

Usage:
    python manage.py fetch_exercise_images_serp                        # full run
    python manage.py fetch_exercise_images_serp --dry-run              # search + score, no save
    python manage.py fetch_exercise_images_serp --limit 5              # first 5 exercises only
    python manage.py fetch_exercise_images_serp --force                # re-fetch even if image exists
    python manage.py fetch_exercise_images_serp --skip-ai              # skip OpenAI image verification
    python manage.py fetch_exercise_images_serp --skip-description     # skip description generation
"""
from __future__ import annotations

import json
import time
from dataclasses import dataclass
from typing import Any

import httpx
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from openai import OpenAI
from serpapi import GoogleSearch

from workouts.models import Exercise

_ALLOWED_CONTENT_TYPES = frozenset({
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/gif",
})


@dataclass(frozen=True)
class ScoredCandidate:
    url: str
    score: int
    reason: str


class Command(BaseCommand):
    help = (
        "Fetch exercise images from SerpAPI Google Images, "
        "optionally verify with OpenAI GPT-4o vision, and save to storage."
    )

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            "--force",
            action="store_true",
            help="Re-fetch images even for exercises that already have one.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Search and score but do not download or save.",
        )
        parser.add_argument(
            "--limit",
            type=int,
            default=0,
            help="Only process the first N exercises (0 = all).",
        )
        parser.add_argument(
            "--skip-ai",
            action="store_true",
            help="Skip OpenAI vision verification; use first SerpAPI result.",
        )
        parser.add_argument(
            "--skip-description",
            action="store_true",
            help="Skip AI-generated exercise description update.",
        )
        parser.add_argument(
            "--simplify-query",
            action="store_true",
            help="Simplify KILO-style exercise names to base movement for search.",
        )

    # ------------------------------------------------------------------
    # Entry point
    # ------------------------------------------------------------------

    def handle(self, *args: Any, **options: Any) -> None:
        force: bool = options["force"]
        dry_run: bool = options["dry_run"]
        limit: int = options["limit"]
        skip_ai: bool = options["skip_ai"]
        skip_description: bool = options["skip_description"]
        simplify_query: bool = options["simplify_query"]

        serpapi_key: str = settings.SERPAPI_KEY
        if not serpapi_key:
            raise CommandError(
                "SERPAPI_KEY is not set. Add it to your .env file."
            )

        needs_openai = not skip_ai or not skip_description
        openai_key: str = settings.OPENAI_API_KEY
        if needs_openai and not openai_key:
            raise CommandError(
                "OPENAI_API_KEY is not set. Either set the key or use "
                "--skip-ai --skip-description."
            )

        openai_client: OpenAI | None = None
        if needs_openai:
            openai_client = OpenAI(api_key=openai_key)

        exercises = Exercise.objects.filter(is_public=True).order_by("id")
        if not force:
            exercises = exercises.exclude(image_url__startswith="http")
            exercises = exercises.order_by("id")

        if limit > 0:
            exercises = exercises[:limit]

        exercise_list: list[Exercise] = list(exercises)
        total = len(exercise_list)

        if total == 0:
            self.stdout.write(self.style.WARNING("No exercises to process."))
            return

        self.stdout.write(
            f"Processing {total} exercise(s)  "
            f"[force={force}, dry_run={dry_run}, skip_ai={skip_ai}, "
            f"skip_description={skip_description}]"
        )

        success_count = 0
        skip_count = 0
        fail_count = 0

        for idx, exercise in enumerate(exercise_list, start=1):
            self.stdout.write(
                f"\n[{idx}/{total}] {exercise.name} (id={exercise.pk})"
            )

            candidate_urls = self._search_images(
                exercise_name=exercise.name,
                serpapi_key=serpapi_key,
                simplify=simplify_query,
            )
            if not candidate_urls:
                self.stdout.write(self.style.WARNING("  No image results from SerpAPI."))
                fail_count += 1
                self._rate_limit_pause()
                continue

            if skip_ai:
                best = ScoredCandidate(url=candidate_urls[0], score=10, reason="skip-ai")
            else:
                assert openai_client is not None
                best = self._pick_best_candidate(
                    exercise_name=exercise.name,
                    candidate_urls=candidate_urls,
                    client=openai_client,
                )

            if best is None or best.score < 7:
                score_info = f"score={best.score}" if best else "no candidates scored"
                self.stdout.write(
                    self.style.WARNING(f"  Skipped — {score_info}.")
                )
                skip_count += 1
                self._rate_limit_pause()
                continue

            self.stdout.write(
                f"  Best: score={best.score}/10 — {best.reason}"
            )

            # --- Generate description ---
            new_description: str | None = None
            if not skip_description:
                assert openai_client is not None
                new_description = self._generate_description(
                    exercise_name=exercise.name,
                    muscle_group=exercise.muscle_group,
                    client=openai_client,
                )
                if new_description:
                    preview = new_description[:120].replace("\n", " ")
                    self.stdout.write(f"  Description: {preview}...")
                else:
                    self.stdout.write(
                        self.style.WARNING("  Description generation failed.")
                    )

            if dry_run:
                self.stdout.write(self.style.NOTICE(f"  [DRY RUN] Would save image: {best.url}"))
                if new_description:
                    self.stdout.write(self.style.NOTICE("  [DRY RUN] Would update description."))
                success_count += 1
                self._rate_limit_pause()
                continue

            # --- Verify image URL is reachable (try all candidates) ---
            verified_url: str | None = None
            if skip_ai:
                for candidate_url in candidate_urls:
                    if self._verify_image_url(candidate_url):
                        verified_url = candidate_url
                        break
                    self.stdout.write(f"    Trying next candidate...")
            else:
                if self._verify_image_url(best.url):
                    verified_url = best.url

            if verified_url is None:
                self.stdout.write(self.style.WARNING("  No reachable image URL found, skipping."))
                fail_count += 1
                self._rate_limit_pause()
                continue

            # --- Persist both fields ---
            update_fields: list[str] = ["image_url"]
            exercise.image_url = verified_url
            if new_description:
                exercise.description = new_description
                update_fields.append("description")

            exercise.save(update_fields=update_fields)
            self.stdout.write(self.style.SUCCESS(f"  Saved image: {verified_url}"))
            if new_description:
                self.stdout.write(self.style.SUCCESS("  Saved description."))
            success_count += 1

            self._rate_limit_pause()

        self.stdout.write(
            f"\nDone. success={success_count}, skipped={skip_count}, failed={fail_count}"
        )

    # ------------------------------------------------------------------
    # SerpAPI image search
    # ------------------------------------------------------------------

    @staticmethod
    def _simplify_exercise_name(name: str) -> str:
        """Simplify KILO-style names to a base movement for better search results.

        Examples:
            "Press - 55° Incline - Pin Touch - Thick Bar - Wide Grip" → "Incline Press"
            "Curl - Scott - Thick Angled Bar - Close Grip" → "Scott Curl"
            "Row - Bent-Over - DB - One-Arm" → "Bent-Over Dumbbell Row"
            "Pulldown - Neutral - One-Arm" → "Neutral Pulldown"
            "Barbell Bench Press" → "Barbell Bench Press" (unchanged)
        """
        if " - " not in name:
            return name

        parts = [p.strip() for p in name.split(" - ")]

        # Common abbreviation expansions
        abbrevs = {
            "DB": "Dumbbell",
            "BB": "Barbell",
        }

        # Drop modifier parts: grip types, bar types, range, angles with °
        drop_keywords = {
            "close grip", "medium grip", "wide grip", "narrow grip",
            "pronated", "supinated", "semi-pronated", "semi-supinated", "neutral",
            "thick bar", "thick ez bar", "thick multi-angled bar",
            "thick angled bar", "thin bar",
            "top range", "mid range", "bottom range", "full range",
            "pin touch", "offset",
        }

        base_movement = parts[0]  # e.g., "Press", "Curl", "Row"
        kept: list[str] = []

        for part in parts[1:]:
            lower = part.lower()
            # Skip angle modifiers like "55°", "25° Decline" → keep "Decline" only
            if "°" in part:
                angle_stripped = part.split("°")[-1].strip()
                if angle_stripped:
                    kept.append(angle_stripped)
                continue
            if lower in drop_keywords:
                continue
            # Expand abbreviations
            kept.append(abbrevs.get(part, part))

        if kept:
            return f"{' '.join(kept)} {base_movement}"
        return base_movement

    def _search_images(
        self,
        exercise_name: str,
        serpapi_key: str,
        num_candidates: int = 5,
        simplify: bool = False,
    ) -> list[str]:
        """Return up to *num_candidates* image URLs from SerpAPI Google Images."""
        search_name = self._simplify_exercise_name(exercise_name) if simplify else exercise_name
        query = f"{search_name} exercise gym"
        self.stdout.write(f'  Searching: "{query}"')

        params: dict[str, Any] = {
            "engine": "google_images",
            "q": query,
            "tbs": "itp:photo,isz:l",
            "num": 10,
            "api_key": serpapi_key,
        }

        try:
            search = GoogleSearch(params)
            results: dict[str, Any] = search.get_dict()
        except Exception as exc:
            self.stdout.write(self.style.ERROR(f"  SerpAPI error: {exc}"))
            return []

        images_results: list[dict[str, Any]] = results.get("images_results", [])
        urls: list[str] = []
        for item in images_results:
            original: str | None = item.get("original")
            if original and original.startswith("http"):
                urls.append(original)
            if len(urls) >= num_candidates:
                break

        self.stdout.write(f"  Found {len(urls)} candidate(s)")
        return urls

    # ------------------------------------------------------------------
    # OpenAI GPT-4o vision scoring
    # ------------------------------------------------------------------

    def _score_candidate(
        self,
        exercise_name: str,
        image_url: str,
        client: OpenAI,
    ) -> ScoredCandidate:
        """Ask GPT-4o vision to score a single image 1-10 for relevance/quality."""
        prompt = (
            f"You are evaluating an image for the exercise \"{exercise_name}\".\n\n"
            "Score this image from 1 to 10 based on:\n"
            "- Relevance: Does it clearly show someone performing THIS specific exercise?\n"
            "- Quality: Is it well-lit, high-resolution, and professionally shot?\n"
            "- Appropriateness: Is it suitable for a fitness app (no logos, watermarks, "
            "memes, collages, or inappropriate content)?\n\n"
            "Respond with ONLY a JSON object, no markdown:\n"
            '{"score": <int 1-10>, "reason": "<one sentence>"}'
        )

        try:
            response = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {"url": image_url, "detail": "low"},
                            },
                        ],
                    }
                ],
                max_tokens=150,
                temperature=0,
            )
            raw: str = response.choices[0].message.content or ""
            # Strip possible markdown fences
            raw = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()

            data: dict[str, Any] = json.loads(raw)
            score = int(data.get("score", 0))
            reason = str(data.get("reason", ""))
            return ScoredCandidate(url=image_url, score=score, reason=reason)
        except Exception as exc:
            self.stdout.write(self.style.WARNING(f"  Vision scoring failed for {image_url}: {exc}"))
            return ScoredCandidate(url=image_url, score=0, reason=f"error: {exc}")

    def _pick_best_candidate(
        self,
        exercise_name: str,
        candidate_urls: list[str],
        client: OpenAI,
    ) -> ScoredCandidate | None:
        """Score all candidates and return the highest-scoring one."""
        scored: list[ScoredCandidate] = []
        for url in candidate_urls:
            result = self._score_candidate(exercise_name, url, client)
            self.stdout.write(f"    Candidate score={result.score}: {result.reason}")
            scored.append(result)

        if not scored:
            return None

        scored.sort(key=lambda c: c.score, reverse=True)
        return scored[0]

    # ------------------------------------------------------------------
    # AI description generation
    # ------------------------------------------------------------------

    def _generate_description(
        self,
        exercise_name: str,
        muscle_group: str,
        client: OpenAI,
    ) -> str | None:
        """Generate a short, plain-text exercise description using GPT-4o."""
        prompt = (
            f"Write a short description for the exercise \"{exercise_name}\" "
            f"(muscle group: {muscle_group}).\n\n"
            "Rules:\n"
            "- 2 to 3 sentences maximum.\n"
            "- First sentence: what the exercise is and which muscles it targets.\n"
            "- Second sentence: one key form cue or how to perform it.\n"
            "- Optional third sentence: a common mistake to avoid or a quick tip.\n"
            "- Plain text only. No bullet points, no numbered lists, no headers, "
            "no bold, no markdown, no emojis.\n"
            "- Write in a direct coaching tone."
        )

        try:
            response = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are an expert personal trainer. You write "
                            "concise, plain-text exercise descriptions for "
                            "a fitness app. Never use formatting."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=150,
                temperature=0.3,
            )
            description: str = (response.choices[0].message.content or "").strip()
            if len(description) < 20:
                self.stdout.write(
                    self.style.WARNING(
                        f"  Description too short ({len(description)} chars), discarding."
                    )
                )
                return None
            return description
        except Exception as exc:
            self.stdout.write(
                self.style.ERROR(f"  Description generation error: {exc}")
            )
            return None

    # ------------------------------------------------------------------
    # Image URL verification
    # ------------------------------------------------------------------

    def _verify_image_url(self, image_url: str) -> bool:
        """HEAD-check that the image URL is reachable and returns an image content type."""
        try:
            with httpx.Client(timeout=15.0, follow_redirects=True) as client:
                resp = client.head(image_url)
                resp.raise_for_status()
            content_type: str = resp.headers.get("content-type", "").split(";")[0].strip().lower()
            if content_type not in _ALLOWED_CONTENT_TYPES:
                self.stdout.write(
                    self.style.WARNING(f"  Unexpected content-type: {content_type}")
                )
                return False
            return True
        except httpx.HTTPError as exc:
            self.stdout.write(self.style.WARNING(f"  HEAD check failed: {exc}"))
            return False

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _rate_limit_pause() -> None:
        """1-second pause between SerpAPI calls to respect rate limits."""
        time.sleep(1)

"""
One-time management command to download externally-hosted exercise images,
upload them to DigitalOcean Spaces, and update the database URLs.

Usage:
    python manage.py rehost_exercise_images                  # full run
    python manage.py rehost_exercise_images --dry-run        # report only
    python manage.py rehost_exercise_images --limit 10       # first 10 only
    python manage.py rehost_exercise_images --concurrency 5  # parallel downloads
"""
from __future__ import annotations

import io
import os
import re
import time
import uuid
from typing import Any

import boto3
import httpx
from botocore.exceptions import ClientError
from django.core.management.base import BaseCommand, CommandError

from workouts.models import Exercise

_CONTENT_TYPE_TO_EXT: dict[str, str] = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}

_ALLOWED_CONTENT_TYPES: frozenset[str] = frozenset(_CONTENT_TYPE_TO_EXT.keys())

_MAX_IMAGE_SIZE: int = 15 * 1024 * 1024  # 15 MB


def _slugify(name: str, max_len: int = 60) -> str:
    """Turn an exercise name into a filesystem-safe slug."""
    slug: str = name.lower().strip()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = slug.strip("-")
    return slug[:max_len]


class Command(BaseCommand):
    help = (
        "Download externally-hosted exercise images, upload to "
        "DigitalOcean Spaces, and update DB references."
    )

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Report what would be downloaded/uploaded; make no changes.",
        )
        parser.add_argument(
            "--limit",
            type=int,
            default=0,
            help="Only process the first N exercises (0 = all).",
        )
        parser.add_argument(
            "--concurrency",
            type=int,
            default=1,
            help="Not yet implemented — reserved for future parallel downloads.",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        dry_run: bool = options["dry_run"]
        limit: int = options["limit"]

        access_key: str = os.getenv("DO_SPACES_KEY", "")
        secret_key: str = os.getenv("DO_SPACES_SECRET", "")
        if not dry_run and (not access_key or not secret_key):
            raise CommandError(
                "DO_SPACES_KEY and DO_SPACES_SECRET must be set in .env."
            )

        bucket: str = os.getenv("DO_SPACES_BUCKET", "fitnessai-bucket")
        endpoint: str = os.getenv(
            "DO_SPACES_ENDPOINT", "https://sfo3.digitaloceanspaces.com"
        )
        region: str = os.getenv("DO_SPACES_REGION", "sfo3")
        base_url: str = f"https://{bucket}.{region}.digitaloceanspaces.com/media"

        # Build S3 client
        s3_client: Any = None
        if not dry_run:
            s3_client = boto3.client(
                "s3",
                region_name=region,
                endpoint_url=endpoint,
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
            )

        # Find exercises with external image URLs (not on Spaces, not empty)
        exercises = (
            Exercise.objects
            .exclude(image_url__isnull=True)
            .exclude(image_url="")
            .exclude(image_url__contains="digitaloceanspaces.com")
            .order_by("id")
        )

        if limit > 0:
            exercises = exercises[:limit]

        exercise_list: list[Exercise] = list(exercises)
        total: int = len(exercise_list)

        if total == 0:
            self.stdout.write(self.style.WARNING(
                "No exercises with external image URLs found."
            ))
            return

        self.stdout.write(
            f"Processing {total} exercise(s) with external images "
            f"[dry_run={dry_run}]"
        )

        success: int = 0
        skipped: int = 0
        failed: int = 0

        http_client = httpx.Client(
            timeout=20.0,
            follow_redirects=True,
            headers={"User-Agent": "FitnessAI-ImageRehost/1.0"},
        )

        try:
            for idx, exercise in enumerate(exercise_list, start=1):
                old_url: str = exercise.image_url or ""
                self.stdout.write(
                    f"\n[{idx}/{total}] pk={exercise.pk} {exercise.name}"
                )
                self.stdout.write(f"  Old URL: {old_url}")

                if dry_run:
                    slug = _slugify(exercise.name)
                    self.stdout.write(
                        f"  [DRY RUN] Would download and rehost as "
                        f"exercises/{slug}-*.ext"
                    )
                    success += 1
                    continue

                # Download the image
                image_bytes, content_type = self._download_image(
                    http_client, old_url
                )
                if image_bytes is None:
                    self.stdout.write(self.style.WARNING("  Download failed, skipping."))
                    failed += 1
                    continue

                # Determine extension
                ext: str = _CONTENT_TYPE_TO_EXT.get(content_type, ".jpg")
                slug: str = _slugify(exercise.name)
                short_uuid: str = uuid.uuid4().hex[:8]
                object_key: str = f"media/exercises/{slug}-{short_uuid}{ext}"

                # Upload to Spaces
                try:
                    s3_client.put_object(
                        Bucket=bucket,
                        Key=object_key,
                        Body=image_bytes,
                        ACL="public-read",
                        ContentType=content_type,
                        CacheControl="max-age=86400",
                    )
                except ClientError as exc:
                    self.stdout.write(
                        self.style.ERROR(f"  S3 upload failed: {exc}")
                    )
                    failed += 1
                    continue

                new_url: str = f"{base_url}/exercises/{slug}-{short_uuid}{ext}"

                # Update DB
                exercise.image_url = new_url
                exercise.save(update_fields=["image_url"])

                self.stdout.write(self.style.SUCCESS(f"  -> {new_url}"))
                success += 1

                # Small pause to be polite to source servers
                if idx % 50 == 0:
                    time.sleep(1)

        finally:
            http_client.close()

        self.stdout.write(
            f"\nDone. success={success}, skipped={skipped}, failed={failed}"
        )
        if failed > 0:
            self.stdout.write(self.style.WARNING(
                f"{failed} image(s) failed. Re-run the command to retry "
                f"(already-rehosted images will be skipped automatically)."
            ))

    def _download_image(
        self, client: httpx.Client, url: str
    ) -> tuple[bytes | None, str]:
        """
        Download an image from a URL. Returns (bytes, content_type) on success,
        or (None, "") on failure.
        """
        try:
            resp: httpx.Response = client.get(url)
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            self.stdout.write(self.style.WARNING(f"  HTTP error: {exc}"))
            return None, ""

        content_type: str = (
            resp.headers.get("content-type", "").split(";")[0].strip().lower()
        )

        # If content-type is missing or generic, try to infer from URL
        if content_type not in _ALLOWED_CONTENT_TYPES:
            url_lower = url.lower()
            if url_lower.endswith(".jpg") or url_lower.endswith(".jpeg"):
                content_type = "image/jpeg"
            elif url_lower.endswith(".png"):
                content_type = "image/png"
            elif url_lower.endswith(".webp"):
                content_type = "image/webp"
            elif url_lower.endswith(".gif"):
                content_type = "image/gif"
            else:
                # Last resort: if it looks like image data, assume JPEG
                if resp.content[:3] == b"\xff\xd8\xff":
                    content_type = "image/jpeg"
                elif resp.content[:8] == b"\x89PNG\r\n\x1a\n":
                    content_type = "image/png"
                else:
                    self.stdout.write(
                        self.style.WARNING(
                            f"  Unexpected content-type: {content_type}"
                        )
                    )
                    return None, ""

        if len(resp.content) > _MAX_IMAGE_SIZE:
            self.stdout.write(
                self.style.WARNING(
                    f"  Image too large: {len(resp.content)} bytes"
                )
            )
            return None, ""

        if len(resp.content) < 100:
            self.stdout.write(
                self.style.WARNING(
                    f"  Image too small ({len(resp.content)} bytes), likely broken"
                )
            )
            return None, ""

        return resp.content, content_type

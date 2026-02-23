"""
One-time management command to migrate local media files to DigitalOcean Spaces
and update URLField database references.

Usage:
    python manage.py migrate_to_spaces                   # full run
    python manage.py migrate_to_spaces --dry-run         # report only, no changes
    python manage.py migrate_to_spaces --skip-upload      # only update DB URLs
    python manage.py migrate_to_spaces --skip-db          # only upload files
"""
from __future__ import annotations

import mimetypes
import os
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import ClientError
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from workouts.models import Exercise, Program, ProgramTemplate


class Command(BaseCommand):
    help = (
        "Migrate local media files to DigitalOcean Spaces and "
        "update URLField database references."
    )

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Scan and report what would be uploaded/updated; make no changes.",
        )
        parser.add_argument(
            "--skip-upload",
            action="store_true",
            help="Skip file uploads; only update DB URL references.",
        )
        parser.add_argument(
            "--skip-db",
            action="store_true",
            help="Skip DB URL updates; only upload files to Spaces.",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        dry_run: bool = options["dry_run"]
        skip_upload: bool = options["skip_upload"]
        skip_db: bool = options["skip_db"]

        # Read credentials from env (same vars as settings.py)
        access_key: str = os.getenv("DO_SPACES_KEY", "")
        secret_key: str = os.getenv("DO_SPACES_SECRET", "")
        needs_credentials: bool = not dry_run and not skip_upload
        if needs_credentials and (not access_key or not secret_key):
            raise CommandError(
                "DO_SPACES_KEY and DO_SPACES_SECRET must be set in .env."
            )

        bucket: str = os.getenv(
            "DO_SPACES_BUCKET", "fitnessai-bucket"
        )
        endpoint: str = os.getenv(
            "DO_SPACES_ENDPOINT", "https://sfo3.digitaloceanspaces.com"
        )
        region: str = os.getenv("DO_SPACES_REGION", "sfo3")

        # Build the public base URL for uploaded files
        # e.g. https://fitnessai-bucket.sfo3.digitaloceanspaces.com/media/
        base_url: str = f"https://{bucket}.{region}.digitaloceanspaces.com/media"

        media_root: Path = Path(settings.MEDIA_ROOT)
        if not media_root.is_dir():
            raise CommandError(f"MEDIA_ROOT does not exist: {media_root}")

        # Create S3 client only when actually uploading
        s3_client: Any = None
        if needs_credentials:
            s3_client = boto3.client(
                "s3",
                region_name=region,
                endpoint_url=endpoint,
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
            )

        # --- Phase 1: Upload files ---
        if not skip_upload:
            self._upload_files(
                s3_client=s3_client,
                media_root=media_root,
                bucket=bucket,
                base_url=base_url,
                dry_run=dry_run,
            )
        else:
            self.stdout.write(self.style.NOTICE("Skipping file uploads (--skip-upload)."))

        # --- Phase 2: Update DB URL references ---
        if not skip_db:
            self._update_db_urls(
                base_url=base_url,
                dry_run=dry_run,
            )
        else:
            self.stdout.write(self.style.NOTICE("Skipping DB updates (--skip-db)."))

        self.stdout.write(self.style.SUCCESS("Done."))

    # ------------------------------------------------------------------
    # Phase 1: Upload local files to Spaces
    # ------------------------------------------------------------------

    def _upload_files(
        self,
        s3_client: Any,
        media_root: Path,
        bucket: str,
        base_url: str,
        dry_run: bool,
    ) -> None:
        """Walk MEDIA_ROOT and upload every file to Spaces."""
        all_files: list[Path] = [
            p for p in media_root.rglob("*") if p.is_file()
        ]

        if not all_files:
            self.stdout.write(self.style.WARNING("No files found in MEDIA_ROOT."))
            return

        self.stdout.write(f"Found {len(all_files)} file(s) in {media_root}")

        uploaded: int = 0
        skipped: int = 0
        failed: int = 0

        for file_path in all_files:
            relative: str = str(file_path.relative_to(media_root))
            object_key: str = f"media/{relative}"

            if dry_run:
                self.stdout.write(f"  [DRY RUN] Would upload: {relative} -> {object_key}")
                uploaded += 1
                continue

            # Check if already uploaded
            if self._object_exists(s3_client, bucket, object_key):
                self.stdout.write(f"  Already exists, skipping: {object_key}")
                skipped += 1
                continue

            content_type: str = (
                mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
            )

            try:
                s3_client.upload_file(
                    Filename=str(file_path),
                    Bucket=bucket,
                    Key=object_key,
                    ExtraArgs={
                        "ACL": "public-read",
                        "ContentType": content_type,
                        "CacheControl": "max-age=86400",
                    },
                )
                self.stdout.write(self.style.SUCCESS(f"  Uploaded: {object_key}"))
                uploaded += 1
            except ClientError as exc:
                self.stdout.write(self.style.ERROR(f"  Upload failed for {relative}: {exc}"))
                failed += 1

        self.stdout.write(
            f"\nUpload summary: uploaded={uploaded}, skipped={skipped}, failed={failed}"
        )

    @staticmethod
    def _object_exists(s3_client: Any, bucket: str, key: str) -> bool:
        """Check if an object already exists in the bucket."""
        try:
            s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except ClientError:
            return False

    # ------------------------------------------------------------------
    # Phase 2: Update URLField values in the database
    # ------------------------------------------------------------------

    def _update_db_urls(self, base_url: str, dry_run: bool) -> None:
        """
        Find URLField rows that point to local /media/ paths and rewrite them
        to the Spaces URL.

        Only updates rows where the URL looks like a local reference
        (contains '/media/' but does NOT start with 'http' pointing elsewhere).
        External URLs (e.g. SerpAPI-fetched) are left as-is.
        """
        url_field_models: list[tuple[type, str]] = [
            (Exercise, "image_url"),
            (Exercise, "video_url"),
            (Program, "image_url"),
            (ProgramTemplate, "image_url"),
        ]

        total_updated: int = 0

        for model_class, field_name in url_field_models:
            model_label: str = f"{model_class.__name__}.{field_name}"

            # Find rows with local media references.
            # These are URLs that contain '/media/' and either:
            #   - don't start with http (relative paths like /media/exercises/...)
            #   - start with http://localhost or http://127.0.0.1
            queryset = model_class.objects.filter(
                **{f"{field_name}__contains": "/media/"}
            ).exclude(
                **{f"{field_name}__isnull": True}
            )

            # Further filter: exclude external URLs (those that start with http
            # but don't point to our local server)
            candidates = []
            for obj in queryset.iterator():
                url: str = getattr(obj, field_name) or ""
                if not url:
                    continue
                if self._is_local_media_url(url):
                    candidates.append(obj)

            if not candidates:
                self.stdout.write(f"  {model_label}: 0 rows to update")
                continue

            self.stdout.write(f"  {model_label}: {len(candidates)} row(s) to update")

            for obj in candidates:
                old_url: str = getattr(obj, field_name)
                new_url: str = self._rewrite_url(old_url, base_url)

                if dry_run:
                    self.stdout.write(
                        f"    [DRY RUN] pk={obj.pk}: {old_url} -> {new_url}"
                    )
                else:
                    setattr(obj, field_name, new_url)
                    obj.save(update_fields=[field_name])
                    self.stdout.write(f"    Updated pk={obj.pk}: {new_url}")

                total_updated += 1

        self.stdout.write(f"\nDB update summary: {total_updated} row(s) updated")

    @staticmethod
    def _is_local_media_url(url: str) -> bool:
        """
        Return True if the URL looks like a local media reference.

        Local references:
          - /media/exercises/foo.jpg  (relative path)
          - media/exercises/foo.jpg   (no leading slash)
          - http://localhost:8000/media/exercises/foo.jpg
          - http://127.0.0.1:8000/media/exercises/foo.jpg

        NOT local:
          - https://www.verywellfit.com/some-image.jpg  (external)
          - https://fitnessai-bucket.sfo3.digitaloceanspaces.com/...  (already migrated)
        """
        if not url:
            return False

        # Already on Spaces — skip
        if "digitaloceanspaces.com" in url:
            return False

        # Relative path starting with /media/ or media/
        if url.startswith("/media/") or url.startswith("media/"):
            return True

        # Absolute localhost URLs
        if url.startswith(("http://localhost", "http://127.0.0.1")):
            return "/media/" in url

        # Any other http(s) URL is external — skip
        if url.startswith(("http://", "https://")):
            return False

        # Catch-all: if it contains /media/ but isn't clearly external
        return "/media/" in url

    @staticmethod
    def _rewrite_url(old_url: str, base_url: str) -> str:
        """
        Convert a local media URL to a Spaces URL.

        Examples:
          /media/exercises/abc.jpg -> https://bucket.sfo3.../media/exercises/abc.jpg
          media/exercises/abc.jpg  -> https://bucket.sfo3.../media/exercises/abc.jpg
          http://localhost:8000/media/exercises/abc.jpg -> same
        """
        # Extract the relative path after 'media/'
        idx: int = old_url.find("/media/")
        if idx >= 0:
            relative: str = old_url[idx + len("/media/"):]
        elif old_url.startswith("media/"):
            relative = old_url[len("media/"):]
        else:
            # Fallback: strip leading slash, use as-is
            relative = old_url.lstrip("/")

        return f"{base_url}/{relative}"

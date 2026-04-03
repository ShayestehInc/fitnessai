"""
Management command to generate exercise thumbnail images using DALL-E 3,
upload them to DigitalOcean Spaces, and update the database.

Usage:
    python manage.py generate_exercise_thumbnails                    # full run
    python manage.py generate_exercise_thumbnails --dry-run          # preview prompts only
    python manage.py generate_exercise_thumbnails --limit 10         # first 10 only
    python manage.py generate_exercise_thumbnails --muscle-group chest  # only chest exercises
    python manage.py generate_exercise_thumbnails --force            # regenerate existing
"""
from __future__ import annotations

import os
import re
import time
import uuid
from dataclasses import dataclass
from typing import Any

import boto3
import httpx
from botocore.exceptions import ClientError
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from workouts.ai_prompts import get_exercise_thumbnail_prompt
from workouts.models import Exercise


@dataclass(frozen=True)
class GenerationResult:
    """Result of a single exercise thumbnail generation attempt."""

    exercise_id: int
    exercise_name: str
    status: str  # 'success', 'skipped', 'failed'
    image_url: str = ''
    error: str = ''


def _slugify(name: str, max_len: int = 60) -> str:
    """Turn an exercise name into a filesystem-safe slug."""
    slug: str = name.lower().strip()
    slug = re.sub(r'[^a-z0-9]+', '-', slug)
    slug = slug.strip('-')
    return slug[:max_len]


class Command(BaseCommand):
    help = (
        'Generate exercise thumbnail images using DALL-E 3, upload to '
        'DigitalOcean Spaces, and update DB references.'
    )

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Generate prompts and log them without calling DALL-E or uploading.',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Regenerate thumbnails even for exercises that already have images.',
        )
        parser.add_argument(
            '--limit',
            type=int,
            default=0,
            help='Only process the first N exercises (0 = all).',
        )
        parser.add_argument(
            '--delay',
            type=int,
            default=15,
            help='Seconds to wait between DALL-E API calls (default: 15).',
        )
        parser.add_argument(
            '--muscle-group',
            type=str,
            default='',
            help='Only process exercises for a specific muscle group.',
        )
        parser.add_argument(
            '--size',
            type=str,
            default='1024x1024',
            choices=['1024x1024', '1792x1024', '1024x1792'],
            help='DALL-E image size (default: 1024x1024).',
        )

    def handle(self, *args: Any, **options: Any) -> None:
        dry_run: bool = options['dry_run']
        force: bool = options['force']
        limit: int = options['limit']
        delay: int = options['delay']
        muscle_group: str = options['muscle_group']
        size: str = options['size']

        # Validate OpenAI API key
        openai_api_key: str = getattr(settings, 'OPENAI_API_KEY', '') or os.getenv('OPENAI_API_KEY', '')
        if not openai_api_key and not dry_run:
            raise CommandError('OPENAI_API_KEY must be set in settings or environment.')

        # Validate DO Spaces credentials
        access_key: str = os.getenv('DO_SPACES_KEY', '')
        secret_key: str = os.getenv('DO_SPACES_SECRET', '')
        if not dry_run and (not access_key or not secret_key):
            raise CommandError('DO_SPACES_KEY and DO_SPACES_SECRET must be set in .env.')

        bucket: str = os.getenv('DO_SPACES_BUCKET', 'fitnessai-bucket')
        endpoint: str = os.getenv('DO_SPACES_ENDPOINT', 'https://sfo3.digitaloceanspaces.com')
        region: str = os.getenv('DO_SPACES_REGION', 'sfo3')
        base_url: str = f'https://{bucket}.{region}.digitaloceanspaces.com/media'

        # Build S3 client
        s3_client: Any = None
        if not dry_run:
            s3_client = boto3.client(
                's3',
                region_name=region,
                endpoint_url=endpoint,
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
            )

        # Build OpenAI client
        openai_client: Any = None
        if not dry_run:
            from openai import OpenAI
            openai_client = OpenAI(api_key=openai_api_key)

        # Query exercises
        exercises = Exercise.objects.filter(is_public=True).order_by('id')

        if not force:
            exercises = exercises.filter(image_url__isnull=True) | exercises.filter(image_url='')
            exercises = exercises.order_by('id')

        if muscle_group:
            exercises = exercises.filter(muscle_group=muscle_group)

        if limit > 0:
            exercises = exercises[:limit]

        exercise_list: list[Exercise] = list(exercises)
        total: int = len(exercise_list)

        if total == 0:
            self.stdout.write(self.style.WARNING('No exercises to process.'))
            return

        self.stdout.write(
            f'Processing {total} exercise(s) [dry_run={dry_run}, force={force}, size={size}]'
        )

        results: list[GenerationResult] = []
        http_client = httpx.Client(
            timeout=30.0,
            follow_redirects=True,
            headers={'User-Agent': 'FitnessAI-ThumbnailGen/1.0'},
        )

        try:
            for idx, exercise in enumerate(exercise_list, start=1):
                result = self._process_exercise(
                    exercise=exercise,
                    idx=idx,
                    total=total,
                    dry_run=dry_run,
                    size=size,
                    openai_client=openai_client,
                    http_client=http_client,
                    s3_client=s3_client,
                    bucket=bucket,
                    base_url=base_url,
                )
                results.append(result)

                # Rate-limit between API calls
                if not dry_run and idx < total and result.status == 'success':
                    self.stdout.write(f'  Waiting {delay}s before next request...')
                    time.sleep(delay)
        finally:
            http_client.close()

        # Summary
        success = sum(1 for r in results if r.status == 'success')
        skipped = sum(1 for r in results if r.status == 'skipped')
        failed = sum(1 for r in results if r.status == 'failed')

        self.stdout.write(
            f'\nDone. success={success}, skipped={skipped}, failed={failed}'
        )
        if failed > 0:
            self.stdout.write(self.style.WARNING(
                f'{failed} image(s) failed. Re-run to retry.'
            ))
            for r in results:
                if r.status == 'failed':
                    self.stdout.write(f'  FAILED: {r.exercise_name} — {r.error}')

    def _process_exercise(
        self,
        exercise: Exercise,
        idx: int,
        total: int,
        dry_run: bool,
        size: str,
        openai_client: Any,
        http_client: httpx.Client,
        s3_client: Any,
        bucket: str,
        base_url: str,
    ) -> GenerationResult:
        """Process a single exercise: generate image, download, upload, update DB."""
        self.stdout.write(f'\n[{idx}/{total}] pk={exercise.pk} {exercise.name}')

        # Build equipment list from model fields
        equipment: list[str] = []
        if hasattr(exercise, 'equipment_required') and exercise.equipment_required:
            equipment = list(exercise.equipment_required)

        prompt = get_exercise_thumbnail_prompt(
            exercise_name=exercise.name,
            muscle_group=exercise.muscle_group,
            equipment=equipment if equipment else None,
        )
        self.stdout.write(f'  Prompt: {prompt[:120]}...')

        if dry_run:
            return GenerationResult(
                exercise_id=exercise.pk,
                exercise_name=exercise.name,
                status='success',
            )

        # Call DALL-E 3
        try:
            response = openai_client.images.generate(
                model='dall-e-3',
                prompt=prompt,
                size=size,
                quality='standard',
                n=1,
            )
            dalle_url: str = response.data[0].url
        except Exception as exc:
            error_msg = str(exc)
            if 'content_policy_violation' in error_msg.lower():
                self.stdout.write(self.style.WARNING(
                    f'  Content policy violation — skipping {exercise.name}'
                ))
                return GenerationResult(
                    exercise_id=exercise.pk,
                    exercise_name=exercise.name,
                    status='skipped',
                    error='content_policy_violation',
                )
            self.stdout.write(self.style.ERROR(f'  DALL-E error: {exc}'))
            return GenerationResult(
                exercise_id=exercise.pk,
                exercise_name=exercise.name,
                status='failed',
                error=error_msg,
            )

        # Download the generated image (DALL-E URLs are temporary)
        image_bytes: bytes | None = None
        try:
            resp = http_client.get(dalle_url)
            resp.raise_for_status()
            image_bytes = resp.content
        except httpx.HTTPError as exc:
            self.stdout.write(self.style.ERROR(f'  Download failed: {exc}'))
            return GenerationResult(
                exercise_id=exercise.pk,
                exercise_name=exercise.name,
                status='failed',
                error=f'download_failed: {exc}',
            )

        if not image_bytes or len(image_bytes) < 100:
            return GenerationResult(
                exercise_id=exercise.pk,
                exercise_name=exercise.name,
                status='failed',
                error='downloaded image too small or empty',
            )

        # Upload to DO Spaces
        slug: str = _slugify(exercise.name)
        short_uuid: str = uuid.uuid4().hex[:8]
        object_key: str = f'media/exercises/thumbnails/{slug}-{short_uuid}.png'

        try:
            s3_client.put_object(
                Bucket=bucket,
                Key=object_key,
                Body=image_bytes,
                ACL='public-read',
                ContentType='image/png',
                CacheControl='max-age=86400',
            )
        except ClientError as exc:
            self.stdout.write(self.style.ERROR(f'  S3 upload failed: {exc}'))
            raise  # Per project rules: no exception silencing

        new_url: str = f'{base_url}/exercises/thumbnails/{slug}-{short_uuid}.png'

        # Update DB
        exercise.image_url = new_url
        exercise.save(update_fields=['image_url'])

        self.stdout.write(self.style.SUCCESS(f'  -> {new_url}'))

        return GenerationResult(
            exercise_id=exercise.pk,
            exercise_name=exercise.name,
            status='success',
            image_url=new_url,
        )

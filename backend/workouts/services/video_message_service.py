"""
Video Message Service — v6.5 §22 Dual Capture.

Manages the lifecycle of video message assets:
start → upload (chunked/resumable) → complete → process → attach.
"""
from __future__ import annotations

import logging
import os
import uuid
from dataclasses import dataclass, field
from typing import Any

from django.conf import settings
from django.core.files.uploadedfile import UploadedFile
from django.db import transaction
from django.utils import timezone

from users.models import User
from workouts.models import DecisionLog, VideoMessageAsset

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class VideoMessageResult:
    """Result of a video message operation."""
    asset_id: str
    upload_status: str
    processing_status: str
    capture_mode: str
    raw_upload_uri: str = ''


def start_recording(
    *,
    owner: User,
    capture_mode: str,
    screen_route_context: dict[str, Any] | None = None,
    trainee_id: int | None = None,
    referenced_object_type: str = '',
    referenced_object_id: str = '',
) -> VideoMessageResult:
    """Create a VideoMessageAsset in pending status when recording starts."""
    asset = VideoMessageAsset.objects.create(
        owner=owner,
        trainee_id=trainee_id,
        trainer_id=owner.pk if owner.role == 'TRAINER' else None,
        capture_mode=capture_mode,
        screen_route_context=screen_route_context or {},
        referenced_object_type=referenced_object_type,
        referenced_object_id=referenced_object_id,
        upload_status=VideoMessageAsset.UploadStatus.PENDING,
        started_at=timezone.now(),
    )

    return VideoMessageResult(
        asset_id=str(asset.pk),
        upload_status=asset.upload_status,
        processing_status=asset.processing_status,
        capture_mode=asset.capture_mode,
    )


def complete_upload(
    *,
    asset_id: str,
    raw_upload_uri: str,
    duration_seconds: float,
    orientation: str = 'portrait',
    camera_layout: dict[str, Any] | None = None,
) -> VideoMessageResult:
    """Mark upload as complete and trigger processing."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)

    asset.raw_upload_uri = raw_upload_uri
    asset.duration_seconds = duration_seconds
    asset.orientation = orientation
    asset.camera_layout = camera_layout or {}
    asset.upload_status = VideoMessageAsset.UploadStatus.UPLOADED
    asset.completed_at = timezone.now()
    asset.save(update_fields=[
        'raw_upload_uri', 'duration_seconds', 'orientation',
        'camera_layout', 'upload_status', 'completed_at',
    ])

    # Trigger async processing (thumbnail + transcript)
    # In production, this would queue a background task
    _process_asset_sync(asset)

    return VideoMessageResult(
        asset_id=str(asset.pk),
        upload_status=asset.upload_status,
        processing_status=asset.processing_status,
        capture_mode=asset.capture_mode,
    )


def attach_to_thread(
    *,
    asset_id: str,
    thread_id: int,
    user: User,
) -> VideoMessageResult:
    """Attach a video message to a messaging thread."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)
    _check_ownership(asset, user)

    asset.thread_id_id = thread_id
    asset.save(update_fields=['thread_id'])

    return VideoMessageResult(
        asset_id=str(asset.pk),
        upload_status=asset.upload_status,
        processing_status=asset.processing_status,
        capture_mode=asset.capture_mode,
    )


def attach_to_checkin(
    *,
    asset_id: str,
    checkin_id: str,
    user: User,
) -> VideoMessageResult:
    """Attach a video message to a check-in submission."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)
    _check_ownership(asset, user)

    asset.check_in_submission_id = checkin_id
    asset.save(update_fields=['check_in_submission_id'])

    return VideoMessageResult(
        asset_id=str(asset.pk),
        upload_status=asset.upload_status,
        processing_status=asset.processing_status,
        capture_mode=asset.capture_mode,
    )


def upload_video_file(
    *,
    asset_id: str,
    video_file: UploadedFile,
    duration_seconds: float,
    orientation: str = 'portrait',
    user: User,
) -> VideoMessageResult:
    """Save the uploaded video file to media storage and mark upload complete."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)
    _check_ownership(asset, user)

    # Save file to media/video_messages/<asset_id>.<ext>
    upload_dir = os.path.join(settings.MEDIA_ROOT, 'video_messages')
    os.makedirs(upload_dir, exist_ok=True)

    ext = os.path.splitext(video_file.name)[1] or '.mp4'
    filename = f'{asset_id}{ext}'
    filepath = os.path.join(upload_dir, filename)

    with open(filepath, 'wb+') as dest:
        for chunk in video_file.chunks():
            dest.write(chunk)

    raw_uri = f'{settings.MEDIA_URL}video_messages/{filename}'

    asset.raw_upload_uri = raw_uri
    asset.duration_seconds = duration_seconds
    asset.orientation = orientation
    asset.upload_status = VideoMessageAsset.UploadStatus.UPLOADED
    asset.completed_at = timezone.now()
    asset.save(update_fields=[
        'raw_upload_uri', 'duration_seconds', 'orientation',
        'upload_status', 'completed_at',
    ])

    _process_asset_sync(asset)

    return VideoMessageResult(
        asset_id=str(asset.pk),
        upload_status=asset.upload_status,
        processing_status=asset.processing_status,
        capture_mode=asset.capture_mode,
        raw_upload_uri=raw_uri,
    )


def get_asset(asset_id: str, user: User) -> VideoMessageAsset:
    """Get a video message asset with permission check."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)

    # Owner always has access
    if asset.owner_id == user.pk:
        return asset

    # Trainer can see their trainees' videos
    if user.role == 'TRAINER' and asset.trainee and asset.trainee.parent_trainer_id == user.pk:
        return asset

    # Admin sees everything
    if user.role == 'ADMIN':
        return asset

    raise PermissionError("You do not have access to this video message.")


def delete_asset(asset_id: str, user: User) -> None:
    """Delete a video message asset (soft — marks as failed)."""
    asset = VideoMessageAsset.objects.get(pk=asset_id)
    _check_ownership(asset, user)

    asset.upload_status = VideoMessageAsset.UploadStatus.FAILED
    asset.error_state = 'Deleted by user.'
    asset.save(update_fields=['upload_status', 'error_state'])


def _check_ownership(asset: VideoMessageAsset, user: User) -> None:
    """Verify user owns the asset or is admin."""
    if asset.owner_id != user.pk and user.role != 'ADMIN':
        raise PermissionError("You do not own this video message.")


def _process_asset_sync(asset: VideoMessageAsset) -> None:
    """
    Process a video asset: generate thumbnail and optional transcript.
    In production, this would be async. For now, it's a synchronous stub.
    """
    try:
        asset.processing_status = VideoMessageAsset.ProcessingStatus.GENERATING_THUMBNAIL
        asset.save(update_fields=['processing_status'])

        # TODO: Generate thumbnail from first frame (ffmpeg)
        # asset.thumbnail_uri = generate_thumbnail(asset.raw_upload_uri)

        # TODO: Transcribe audio if microphone was enabled (Whisper API)
        # if has_audio(asset.raw_upload_uri):
        #     asset.processing_status = 'transcribing'
        #     asset.save(update_fields=['processing_status'])
        #     transcript = transcribe(asset.raw_upload_uri)
        #     asset.transcript_text = transcript.text
        #     asset.transcript_confidence = transcript.confidence

        asset.processing_status = VideoMessageAsset.ProcessingStatus.COMPLETE
        asset.upload_status = VideoMessageAsset.UploadStatus.COMPLETE
        asset.save(update_fields=['processing_status', 'upload_status'])

    except Exception as e:
        logger.exception("Failed to process video message asset %s", asset.pk)
        asset.processing_status = VideoMessageAsset.ProcessingStatus.FAILED
        asset.error_state = str(e)
        asset.save(update_fields=['processing_status', 'error_state'])

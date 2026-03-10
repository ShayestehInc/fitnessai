"""
Video Analysis Service — v6.5 Step 14.

Workflow:
1. Trainee uploads video → VideoAnalysis created (status=uploaded)
2. GPT-4o Vision analyzes exercise form → status=analyzed
3. Trainee reviews + confirms → status=confirmed, DecisionLog created
"""
from __future__ import annotations

import base64
import json
import logging
import os
from dataclasses import dataclass
from typing import Any

from django.core.files.uploadedfile import UploadedFile
from django.db import transaction
from django.db.models.functions import Lower
from django.utils import timezone

from users.models import User
from workouts.models import (
    DecisionLog,
    Exercise,
    UndoSnapshot,
    VideoAnalysis,
)

logger = logging.getLogger(__name__)

ALLOWED_VIDEO_FORMATS = {'mp4', 'mov', 'webm', 'avi'}
MAX_VIDEO_SIZE_BYTES = 50 * 1024 * 1024  # 50MB
ALLOWED_EXTENSIONS = {f'.{fmt}' for fmt in ALLOWED_VIDEO_FORMATS}


@dataclass(frozen=True)
class AnalysisResult:
    """Result of video analysis."""
    analysis_id: str
    status: str
    exercise_detected: str
    exercise_id: int | None
    rep_count: int | None
    form_score: float | None
    observations: list[str]
    confidence: float | None
    error: str


@dataclass(frozen=True)
class ConfirmResult:
    """Result of confirming video analysis."""
    analysis_id: str
    exercise_id: int | None
    rep_count: int | None
    form_score: float | None


# ---------------------------------------------------------------------------
# Upload + Analyze
# ---------------------------------------------------------------------------

def upload_and_analyze(
    *,
    trainee: User,
    video_file: UploadedFile,
) -> AnalysisResult:
    """Upload video, analyze via GPT-4o Vision."""
    _validate_video_file(video_file)

    name = video_file.name or ''
    ext = os.path.splitext(name)[1].lower().lstrip('.')

    analysis = VideoAnalysis.objects.create(
        trainee=trainee,
        video_file=video_file,
        status=VideoAnalysis.Status.UPLOADED,
    )

    try:
        analysis.status = VideoAnalysis.Status.ANALYZING
        analysis.save(update_fields=['status'])

        result = _analyze_video_with_ai(analysis)

        # Match exercise name to library
        exercise_id = _match_exercise(result.get('exercise_detected', ''), trainee)

        analysis.exercise_detected = result.get('exercise_detected', '')
        analysis.exercise_id = exercise_id
        analysis.rep_count = result.get('rep_count')
        analysis.form_score = result.get('form_score')
        analysis.observations = result.get('observations', [])
        analysis.confidence = result.get('confidence')
        analysis.raw_ai_response = result
        analysis.status = VideoAnalysis.Status.ANALYZED
        analysis.save(update_fields=[
            'exercise_detected', 'exercise_id', 'rep_count',
            'form_score', 'observations', 'confidence',
            'raw_ai_response', 'status',
        ])

    except Exception as exc:
        analysis.status = VideoAnalysis.Status.FAILED
        analysis.error_message = f"Analysis failed: {exc}"
        analysis.save(update_fields=['status', 'error_message'])
        logger.error("Video analysis failed: %s", exc, exc_info=True)
        return AnalysisResult(
            analysis_id=str(analysis.pk),
            status=analysis.status,
            exercise_detected='',
            exercise_id=None,
            rep_count=None,
            form_score=None,
            observations=[],
            confidence=None,
            error=analysis.error_message,
        )

    return AnalysisResult(
        analysis_id=str(analysis.pk),
        status=analysis.status,
        exercise_detected=analysis.exercise_detected,
        exercise_id=analysis.exercise_id,
        rep_count=analysis.rep_count,
        form_score=analysis.form_score,
        observations=analysis.observations,
        confidence=analysis.confidence,
        error='',
    )


# ---------------------------------------------------------------------------
# Confirm
# ---------------------------------------------------------------------------

def confirm_analysis(
    *,
    analysis_id: str,
    trainee: User,
) -> ConfirmResult:
    """Confirm video analysis findings. Creates DecisionLog."""
    try:
        analysis = VideoAnalysis.objects.get(pk=analysis_id, trainee=trainee)
    except VideoAnalysis.DoesNotExist:
        raise ValueError("Video analysis not found.")

    if analysis.status != VideoAnalysis.Status.ANALYZED:
        raise ValueError(f"Analysis is not confirmable (status: {analysis.status}).")

    with transaction.atomic():
        analysis.status = VideoAnalysis.Status.CONFIRMED
        analysis.confirmed_at = timezone.now()
        analysis.save(update_fields=['status', 'confirmed_at'])

        DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.AI,
            actor_id=trainee.pk,
            decision_type='video_analysis_confirmed',
            context={
                'analysis_id': str(analysis.pk),
                'exercise_detected': analysis.exercise_detected,
                'exercise_id': analysis.exercise_id,
            },
            inputs_snapshot={
                'rep_count': analysis.rep_count,
                'form_score': analysis.form_score,
                'confidence': analysis.confidence,
                'observations': analysis.observations,
            },
            constraints_applied={},
            options_considered=[],
            final_choice={
                'exercise_detected': analysis.exercise_detected,
                'rep_count': analysis.rep_count,
                'form_score': analysis.form_score,
            },
            reason_codes=['video_analysis_confirmed'],
        )

    return ConfirmResult(
        analysis_id=str(analysis.pk),
        exercise_id=analysis.exercise_id,
        rep_count=analysis.rep_count,
        form_score=analysis.form_score,
    )


# ---------------------------------------------------------------------------
# Read helpers
# ---------------------------------------------------------------------------

def get_video_analysis(
    *,
    analysis_id: str,
    trainee: User,
) -> VideoAnalysis:
    """Get a video analysis by ID, verifying ownership."""
    try:
        return VideoAnalysis.objects.select_related('exercise').get(
            pk=analysis_id, trainee=trainee,
        )
    except VideoAnalysis.DoesNotExist:
        raise ValueError("Video analysis not found.")


def list_video_analyses(
    *,
    trainee: User,
    limit: int = 20,
) -> list[VideoAnalysis]:
    """List recent video analyses."""
    return list(
        VideoAnalysis.objects.filter(trainee=trainee)
        .select_related('exercise')
        .order_by('-created_at')[:limit]
    )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _validate_video_file(video_file: UploadedFile) -> None:
    """Validate video file format and size."""
    if video_file.size is not None and video_file.size > MAX_VIDEO_SIZE_BYTES:
        raise ValueError(
            f"Video file too large ({video_file.size / (1024*1024):.1f}MB). "
            f"Max: {MAX_VIDEO_SIZE_BYTES / (1024*1024):.0f}MB."
        )

    name = video_file.name or ''
    ext = os.path.splitext(name)[1].lower()
    if ext and ext not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"Unsupported video format '{ext}'. "
            f"Allowed: {', '.join(sorted(ALLOWED_VIDEO_FORMATS))}."
        )


def _match_exercise(exercise_name: str, trainee: User) -> int | None:
    """Try to match detected exercise name to the exercise library."""
    if not exercise_name:
        return None

    from django.db.models import Q

    trainer = trainee.parent_trainer
    exercise = (
        Exercise.objects
        .annotate(name_lower=Lower('name'))
        .filter(
            Q(name_lower=exercise_name.lower()) & (
                Q(is_public=True) | Q(created_by=trainer)
            )
        )
        .first()
    )
    return exercise.pk if exercise else None


def _analyze_video_with_ai(analysis: VideoAnalysis) -> dict[str, Any]:
    """
    Call GPT-4o Vision to analyze exercise video.
    Extracts frames and sends to the API.
    """
    from workouts.services.natural_language_parser import get_openai_client
    from workouts.ai_prompts import get_video_analysis_prompt

    client = get_openai_client()
    if client is None:
        raise ValueError("OpenAI client not available. Check API key configuration.")

    # Extract a frame from the video for analysis
    frame_base64 = _extract_video_frame(analysis)
    if not frame_base64:
        raise ValueError("Could not extract frame from video.")

    prompt = get_video_analysis_prompt()

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{frame_base64}",
                        },
                    },
                ],
            }
        ],
        temperature=0.3,
        max_tokens=1500,
    )

    content = response.choices[0].message.content
    if not content:
        raise ValueError("Empty AI response.")

    # Try to parse JSON from response
    try:
        # Handle markdown-wrapped JSON
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0]
        elif '```' in content:
            content = content.split('```')[1].split('```')[0]
        return json.loads(content.strip())
    except json.JSONDecodeError:
        logger.warning("Could not parse video analysis JSON, using raw text")
        return {
            'exercise_detected': '',
            'rep_count': None,
            'form_score': None,
            'observations': [content.strip()],
            'confidence': 0.3,
        }


def _extract_video_frame(analysis: VideoAnalysis) -> str | None:
    """
    Extract a single frame from the video as base64 JPEG.
    Uses ffmpeg if available, otherwise returns None.
    """
    import subprocess
    import tempfile

    try:
        analysis.video_file.seek(0)
        video_data = analysis.video_file.read()
        if not video_data:
            return None

        with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as tmp_video:
            tmp_video.write(video_data)
            tmp_video_path = tmp_video.name

        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp_frame:
            tmp_frame_path = tmp_frame.name

        try:
            # Extract frame at 1 second mark
            subprocess.run(
                [
                    'ffmpeg', '-i', tmp_video_path,
                    '-ss', '1', '-vframes', '1',
                    '-y', tmp_frame_path,
                ],
                capture_output=True,
                timeout=30,
                check=True,
            )

            with open(tmp_frame_path, 'rb') as f:
                frame_data = f.read()

            if frame_data:
                return base64.b64encode(frame_data).decode('utf-8')
            return None

        finally:
            for path in (tmp_video_path, tmp_frame_path):
                try:
                    os.unlink(path)
                except OSError:
                    pass

    except (subprocess.SubprocessError, OSError) as exc:
        logger.warning("Could not extract video frame: %s", exc)
        return None

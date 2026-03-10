"""
Voice Memo Service — v6.5 Step 14.

Workflow:
1. Trainee uploads audio → VoiceMemo created (status=uploaded)
2. OpenAI Whisper transcribes audio → status=transcribed
3. Natural language parser extracts structured data → status=parsed
4. On failure → status=failed with error_message
"""
from __future__ import annotations

import base64
import logging
import os
from dataclasses import dataclass
from typing import Any

from django.core.files.uploadedfile import UploadedFile

from users.models import User
from workouts.models import VoiceMemo

logger = logging.getLogger(__name__)

ALLOWED_AUDIO_FORMATS = {'mp3', 'wav', 'm4a', 'webm', 'ogg', 'flac'}
MAX_AUDIO_SIZE_BYTES = 25 * 1024 * 1024  # 25MB (Whisper limit)
ALLOWED_EXTENSIONS = {f'.{fmt}' for fmt in ALLOWED_AUDIO_FORMATS}


@dataclass(frozen=True)
class TranscriptionResult:
    """Result of voice memo transcription + parsing."""
    memo_id: str
    status: str
    transcript: str
    parsed_result: dict[str, Any]
    error: str


def upload_and_transcribe(
    *,
    trainee: User,
    audio_file: UploadedFile,
) -> TranscriptionResult:
    """
    Upload audio, transcribe via Whisper, parse via NLP.
    Returns the result synchronously.
    """
    # Validate file
    _validate_audio_file(audio_file)

    # Detect format
    name = audio_file.name or ''
    ext = os.path.splitext(name)[1].lower().lstrip('.')
    if ext not in ALLOWED_AUDIO_FORMATS:
        ext = 'mp3'  # default

    # Create VoiceMemo record
    memo = VoiceMemo.objects.create(
        trainee=trainee,
        audio_file=audio_file,
        audio_format=ext,
        status=VoiceMemo.Status.UPLOADED,
    )

    # Transcribe
    try:
        memo.status = VoiceMemo.Status.TRANSCRIBING
        memo.save(update_fields=['status'])

        transcript, confidence, language = _transcribe_audio(memo)

        memo.transcript = transcript
        memo.transcription_confidence = confidence
        memo.transcription_language = language
        memo.status = VoiceMemo.Status.TRANSCRIBED
        memo.save(update_fields=[
            'transcript', 'transcription_confidence',
            'transcription_language', 'status',
        ])
    except Exception as exc:
        memo.status = VoiceMemo.Status.FAILED
        memo.error_message = f"Transcription failed: {exc}"
        memo.save(update_fields=['status', 'error_message'])
        logger.error("Voice memo transcription failed: %s", exc, exc_info=True)
        return TranscriptionResult(
            memo_id=str(memo.pk),
            status=memo.status,
            transcript='',
            parsed_result={},
            error=memo.error_message,
        )

    # Parse transcript via NLP
    if memo.transcript.strip():
        try:
            parsed = _parse_transcript(memo.transcript, trainee)
            memo.parsed_result = parsed
            memo.status = VoiceMemo.Status.PARSED
            memo.save(update_fields=['parsed_result', 'status'])
        except Exception as exc:
            memo.status = VoiceMemo.Status.FAILED
            memo.error_message = f"Parsing failed: {exc}"
            memo.save(update_fields=['status', 'error_message'])
            logger.error("Voice memo parsing failed: %s", exc, exc_info=True)
            return TranscriptionResult(
                memo_id=str(memo.pk),
                status=memo.status,
                transcript=memo.transcript,
                parsed_result={},
                error=memo.error_message,
            )

    return TranscriptionResult(
        memo_id=str(memo.pk),
        status=memo.status,
        transcript=memo.transcript,
        parsed_result=memo.parsed_result,
        error='',
    )


def get_voice_memo(
    *,
    memo_id: str,
    trainee: User,
) -> VoiceMemo:
    """Get a voice memo by ID, verifying ownership."""
    try:
        return VoiceMemo.objects.get(pk=memo_id, trainee=trainee)
    except VoiceMemo.DoesNotExist:
        raise ValueError("Voice memo not found.")


def list_voice_memos(
    *,
    trainee: User,
    limit: int = 20,
) -> list[VoiceMemo]:
    """List recent voice memos for a trainee."""
    return list(
        VoiceMemo.objects.filter(trainee=trainee)
        .order_by('-created_at')[:limit]
    )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _validate_audio_file(audio_file: UploadedFile) -> None:
    """Validate audio file format and size."""
    if audio_file.size is not None and audio_file.size > MAX_AUDIO_SIZE_BYTES:
        raise ValueError(
            f"Audio file too large ({audio_file.size / (1024*1024):.1f}MB). "
            f"Max: {MAX_AUDIO_SIZE_BYTES / (1024*1024):.0f}MB."
        )

    name = audio_file.name or ''
    ext = os.path.splitext(name)[1].lower()
    if ext and ext not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"Unsupported audio format '{ext}'. "
            f"Allowed: {', '.join(sorted(ALLOWED_AUDIO_FORMATS))}."
        )


def _transcribe_audio(memo: VoiceMemo) -> tuple[str, float, str]:
    """
    Call OpenAI Whisper API to transcribe audio.
    Returns (transcript, confidence, language).
    """
    from workouts.services.natural_language_parser import get_openai_client

    client = get_openai_client()
    if client is None:
        raise ValueError("OpenAI client not available. Check API key configuration.")

    # Read the audio file
    memo.audio_file.seek(0)
    audio_data = memo.audio_file.read()

    if not audio_data:
        raise ValueError("Audio file is empty.")

    # Use Whisper API with file-like object
    import io
    audio_buffer = io.BytesIO(audio_data)
    audio_buffer.name = f"audio.{memo.audio_format or 'mp3'}"

    response = client.audio.transcriptions.create(
        model="whisper-1",
        file=audio_buffer,
        response_format="verbose_json",
    )

    transcript = response.text or ''
    language = getattr(response, 'language', 'en') or 'en'
    # Whisper doesn't return per-segment confidence in the standard API;
    # use duration-based heuristic or default to 0.9
    confidence = 0.9 if transcript.strip() else 0.0

    return transcript, confidence, language


def _parse_transcript(transcript: str, trainee: User) -> dict[str, Any]:
    """Feed transcript through the natural language parser."""
    from workouts.services.natural_language_parser import NaturalLanguageParserService

    result = NaturalLanguageParserService.parse_user_input(
        user_input=transcript,
        context=None,
    )

    if result is None:
        return {}

    # Convert Pydantic model to dict
    if hasattr(result, 'model_dump'):
        return result.model_dump()
    elif hasattr(result, 'dict'):
        return result.dict()
    return {}

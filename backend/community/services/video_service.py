"""
Service for video validation and metadata extraction.
Uses ffprobe via subprocess for duration and thumbnail generation.
Gracefully degrades if ffprobe is not available.
"""
from __future__ import annotations

import io
import logging
import shutil
import subprocess
import tempfile
from dataclasses import dataclass

from django.core.files.uploadedfile import UploadedFile

logger = logging.getLogger(__name__)

ALLOWED_VIDEO_TYPES: frozenset[str] = frozenset({
    'video/mp4',
    'video/quicktime',   # .mov
    'video/webm',
})
ALLOWED_VIDEO_EXTENSIONS: frozenset[str] = frozenset({
    '.mp4', '.m4v', '.mov', '.webm',
})
# Magic bytes for video container formats
_VIDEO_MAGIC_BYTES: dict[bytes, str] = {
    b'\x00\x00\x00': 'mp4/mov',       # ftyp box (offset varies, but starts with 00 00 00)
    b'\x1a\x45\xdf\xa3': 'webm/mkv',  # EBML header
}
MAX_VIDEO_SIZE: int = 50 * 1024 * 1024  # 50 MB
MAX_VIDEO_DURATION: float = 60.0  # 60 seconds
MAX_VIDEOS_PER_POST: int = 3


@dataclass(frozen=True)
class VideoMetadata:
    """Result of video validation and metadata extraction."""
    is_valid: bool
    error_message: str | None
    duration: float | None
    file_size: int
    thumbnail_bytes: bytes | None


def _validate_magic_bytes(header: bytes) -> bool:
    """Validate that the file header matches a known video container format."""
    if len(header) < 8:
        return False
    # MP4/MOV: ftyp box — bytes 4-7 should be 'ftyp'
    if header[4:8] == b'ftyp':
        return True
    # WebM/MKV: EBML header
    if header[:4] == b'\x1a\x45\xdf\xa3':
        return True
    return False


def _ffprobe_available() -> bool:
    """Check if ffprobe is available on the system."""
    return shutil.which('ffprobe') is not None


def _ffmpeg_available() -> bool:
    """Check if ffmpeg is available on the system."""
    return shutil.which('ffmpeg') is not None


def _extract_duration(file_path: str) -> float | None:
    """Extract video duration using ffprobe. Returns None on failure."""
    if not _ffprobe_available():
        logger.warning("ffprobe not available — skipping duration extraction")
        return None
    try:
        result = subprocess.run(
            [
                'ffprobe',
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_format',
                file_path,
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            logger.warning("ffprobe failed for %s: %s", file_path, result.stderr)
            return None

        import json
        data = json.loads(result.stdout)
        duration_str = data.get('format', {}).get('duration')
        if duration_str is not None:
            return float(duration_str)
        return None
    except (subprocess.TimeoutExpired, ValueError, KeyError) as exc:
        logger.warning("Duration extraction failed: %s", exc)
        return None


def _extract_thumbnail(file_path: str) -> bytes | None:
    """Extract first frame as JPEG thumbnail using ffmpeg. Returns None on failure."""
    if not _ffmpeg_available():
        logger.warning("ffmpeg not available — skipping thumbnail extraction")
        return None
    try:
        result = subprocess.run(
            [
                'ffmpeg',
                '-i', file_path,
                '-vframes', '1',
                '-f', 'image2pipe',
                '-vcodec', 'mjpeg',
                '-q:v', '5',
                '-vf', 'scale=640:-1',
                '-',
            ],
            capture_output=True,
            timeout=30,
        )
        if result.returncode != 0 or not result.stdout:
            logger.warning("Thumbnail extraction failed for %s", file_path)
            return None
        return result.stdout
    except subprocess.TimeoutExpired:
        logger.warning("Thumbnail extraction timed out for %s", file_path)
        return None


def validate_video(video_file: UploadedFile) -> VideoMetadata:
    """
    Validate a video upload and extract metadata.

    Checks content type, file size, and duration.
    Extracts thumbnail from first frame if ffmpeg is available.
    """
    import os
    file_size = video_file.size or 0
    filename = video_file.name or ''
    ext = os.path.splitext(filename)[1].lower()

    # Check file extension
    if ext not in ALLOWED_VIDEO_EXTENSIONS:
        return VideoMetadata(
            is_valid=False,
            error_message=f'Unsupported video format "{ext}". Use MP4, MOV, or WebM.',
            duration=None,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # Check MIME type (client-provided, first layer)
    content_type = video_file.content_type or ''
    if content_type not in ALLOWED_VIDEO_TYPES:
        return VideoMetadata(
            is_valid=False,
            error_message=f'Unsupported video format "{content_type}". Use MP4, MOV, or WebM.',
            duration=None,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # Magic byte validation (server-side, second layer)
    header = video_file.read(16)
    video_file.seek(0)
    if not _validate_magic_bytes(header):
        return VideoMetadata(
            is_valid=False,
            error_message='File content does not match a supported video format.',
            duration=None,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # Check file size
    if file_size > MAX_VIDEO_SIZE:
        size_mb = file_size / (1024 * 1024)
        return VideoMetadata(
            is_valid=False,
            error_message=f'Video is {size_mb:.1f}MB. Maximum is 50MB.',
            duration=None,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # Write to temp file for ffprobe/ffmpeg processing
    duration: float | None = None
    thumbnail_bytes: bytes | None = None

    try:
        with tempfile.NamedTemporaryFile(suffix=ext or '.mp4', delete=True) as tmp:
            for chunk in video_file.chunks():
                tmp.write(chunk)
            tmp.flush()

            duration = _extract_duration(tmp.name)
            thumbnail_bytes = _extract_thumbnail(tmp.name)

        # Reset file position for subsequent reads (Django storage)
        video_file.seek(0)
    except OSError as exc:
        logger.warning("Temp file handling failed: %s", exc)
        video_file.seek(0)

    # Check duration (only if we could extract it)
    if duration is not None and duration > MAX_VIDEO_DURATION:
        return VideoMetadata(
            is_valid=False,
            error_message=f'Video is {duration:.0f}s. Maximum is 60 seconds.',
            duration=duration,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # Zero or negative duration means corrupt file
    if duration is not None and duration <= 0:
        return VideoMetadata(
            is_valid=False,
            error_message='Invalid video file — could not determine duration.',
            duration=None,
            file_size=file_size,
            thumbnail_bytes=None,
        )

    # If ffprobe is not available, we can't verify duration.
    # Log a warning but allow the upload — the file passed magic byte and
    # extension validation. Duration will be null in the database.
    if duration is None:
        logger.warning(
            "Could not extract video duration (ffprobe unavailable?). "
            "Allowing upload for file '%s' (%d bytes).",
            filename, file_size,
        )

    return VideoMetadata(
        is_valid=True,
        error_message=None,
        duration=duration,
        file_size=file_size,
        thumbnail_bytes=thumbnail_bytes,
    )

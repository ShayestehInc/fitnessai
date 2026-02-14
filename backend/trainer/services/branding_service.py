"""
Service layer for trainer branding operations.

Handles image validation and branding business logic,
keeping views focused on request/response handling.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from django.core.files.uploadedfile import UploadedFile
from PIL import Image as PILImage, UnidentifiedImageError

if TYPE_CHECKING:
    from trainer.models import TrainerBranding
    from users.models import User


ALLOWED_IMAGE_CONTENT_TYPES: list[str] = ['image/jpeg', 'image/png', 'image/webp']
ALLOWED_PIL_FORMATS: set[str] = {'JPEG', 'PNG', 'WEBP'}
MAX_LOGO_SIZE_BYTES: int = 2 * 1024 * 1024  # 2MB
MIN_LOGO_DIMENSION: int = 128
MAX_LOGO_DIMENSION: int = 1024


class LogoValidationError(Exception):
    """Raised when a logo image fails validation."""

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


@dataclass(frozen=True)
class LogoValidationResult:
    """Result of logo image validation."""
    is_valid: bool
    error: str | None = None


def validate_logo_image(image: UploadedFile) -> LogoValidationResult:
    """
    Validate a logo image file for content type, size, format, and dimensions.

    Performs defense-in-depth validation:
    1. Content-type header check
    2. File size check
    3. Pillow format verification (actual file bytes)
    4. Dimension bounds check

    Returns a LogoValidationResult. Callers should check is_valid before proceeding.
    """
    # 1. Validate content type
    if image.content_type not in ALLOWED_IMAGE_CONTENT_TYPES:
        return LogoValidationResult(
            is_valid=False,
            error='Invalid file type. Allowed: JPEG, PNG, WebP.',
        )

    # 2. Validate file size
    if image.size is None or image.size > MAX_LOGO_SIZE_BYTES:
        return LogoValidationResult(
            is_valid=False,
            error='Logo must be under 2MB.',
        )

    # 3. Validate actual image format and dimensions via Pillow
    try:
        pil_image = PILImage.open(image)

        if pil_image.format not in ALLOWED_PIL_FORMATS:
            return LogoValidationResult(
                is_valid=False,
                error='Invalid image format. Allowed: JPEG, PNG, WebP.',
            )

        width, height = pil_image.size
        if width < MIN_LOGO_DIMENSION or height < MIN_LOGO_DIMENSION:
            return LogoValidationResult(
                is_valid=False,
                error=f'Logo must be at least {MIN_LOGO_DIMENSION}x{MIN_LOGO_DIMENSION} pixels.',
            )
        if width > MAX_LOGO_DIMENSION or height > MAX_LOGO_DIMENSION:
            return LogoValidationResult(
                is_valid=False,
                error=f'Logo must be at most {MAX_LOGO_DIMENSION}x{MAX_LOGO_DIMENSION} pixels.',
            )

        # Reset file pointer after reading for subsequent save
        image.seek(0)

    except UnidentifiedImageError:
        return LogoValidationResult(
            is_valid=False,
            error='Could not process image. Please upload a valid image file.',
        )
    except (OSError, ValueError) as exc:
        return LogoValidationResult(
            is_valid=False,
            error='Could not process image. Please upload a valid image file.',
        )

    return LogoValidationResult(is_valid=True)


def upload_trainer_logo(trainer: User, image: UploadedFile) -> TrainerBranding:
    """
    Validate and save a logo image to a trainer's branding record.

    Raises LogoValidationError if the image fails validation.
    Returns the updated TrainerBranding instance.
    """
    from trainer.models import TrainerBranding

    validation = validate_logo_image(image)
    if not validation.is_valid:
        raise LogoValidationError(validation.error or 'Invalid image.')

    branding, _created = TrainerBranding.get_or_create_for_trainer(trainer)

    # Delete old logo file if it exists
    if branding.logo:
        branding.logo.delete(save=False)

    branding.logo = image
    branding.save(update_fields=['logo', 'updated_at'])
    return branding


def remove_trainer_logo(trainer: User) -> TrainerBranding:
    """
    Remove the logo from a trainer's branding record.

    Raises TrainerBranding.DoesNotExist if no branding is configured.
    Returns the updated TrainerBranding instance.
    """
    from trainer.models import TrainerBranding

    branding = TrainerBranding.objects.get(trainer=trainer)

    if branding.logo:
        branding.logo.delete(save=False)
        branding.logo = None
        branding.save(update_fields=['logo', 'updated_at'])

    return branding

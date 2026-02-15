"""
Service for sending trainee invitation emails.
"""
from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from django.conf import settings
from django.core.mail import send_mail
from django.utils.html import escape

if TYPE_CHECKING:
    from users.models import User
    from trainer.models import TraineeInvitation

logger = logging.getLogger(__name__)


def send_invitation_email(invitation: TraineeInvitation) -> None:
    """
    Send an invitation email to the prospective trainee.

    Includes the trainer's name, invite code, registration link, and expiry date.
    Raises on failure — callers should wrap in try/except.

    Args:
        invitation: The TraineeInvitation instance to send the email for.

    Raises:
        Exception: If the email fails to send.
    """
    trainer_name = _get_trainer_display_name(invitation.trainer)
    domain: str = getattr(settings, 'DJOSER', {}).get('DOMAIN', 'localhost:3000')
    site_name: str = getattr(settings, 'DJOSER', {}).get('SITE_NAME', 'FitnessAI')
    invite_code: str = invitation.invitation_code
    expiry_date: str = invitation.expires_at.strftime('%B %d, %Y')

    # Strip port for email domain fallback
    domain_name = domain.split(':')[0]

    # Use HTTPS for production, HTTP for localhost
    protocol = 'http' if 'localhost' in domain or '127.0.0.1' in domain else 'https'
    # Escape the invite code for URL safety (though it's already URL-safe from secrets.token_urlsafe)
    from urllib.parse import quote
    safe_invite_code = quote(invite_code, safe='')
    registration_url = f"{protocol}://{domain}/register?invite={safe_invite_code}"

    subject = f"{trainer_name} invited you to join {site_name}"

    # Plain text version (no escaping needed)
    text_body = (
        f"Hi there!\n\n"
        f"{trainer_name} has invited you to join {site_name} as their trainee.\n\n"
    )

    if invitation.message:
        text_body += f'Personal message from {trainer_name}:\n"{invitation.message}"\n\n'

    text_body += (
        f"Your invitation code: {invite_code}\n\n"
        f"To get started:\n"
        f"1. Download the {site_name} app\n"
        f"2. Create an account at: {registration_url}\n"
        f"3. Enter your invitation code during registration\n\n"
        f"This invitation expires on {expiry_date}.\n\n"
        f"— The {site_name} Team\n"
    )

    # HTML version — escape all user-supplied values to prevent XSS
    safe_trainer_name = escape(trainer_name)
    safe_site_name = escape(site_name)
    safe_invite_code = escape(invite_code)
    safe_expiry_date = escape(expiry_date)

    message_html = ""
    if invitation.message:
        safe_message = escape(invitation.message)
        message_html = (
            f"<blockquote style='border-left: 3px solid #6366f1; "
            f"padding-left: 12px; margin: 16px 0; color: #6b7280; "
            f"font-style: italic;'>{safe_message}</blockquote>"
        )

    html_body = f"""
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #1a1a1a;">You're Invited!</h2>
    <p style="color: #4a4a4a; font-size: 16px;">
        <strong>{safe_trainer_name}</strong> has invited you to join <strong>{safe_site_name}</strong> as their trainee.
    </p>
    {message_html}
    <div style="background-color: #f3f4f6; border-radius: 12px; padding: 20px; margin: 24px 0; text-align: center;">
        <p style="color: #6b7280; font-size: 14px; margin: 0 0 8px 0;">Your invitation code</p>
        <p style="color: #1a1a1a; font-size: 28px; font-weight: bold; letter-spacing: 2px; margin: 0;">{safe_invite_code}</p>
    </div>
    <div style="margin: 24px 0;">
        <p style="color: #4a4a4a; font-size: 15px; font-weight: 600;">To get started:</p>
        <ol style="color: #4a4a4a; font-size: 15px; padding-left: 20px;">
            <li style="margin-bottom: 8px;">Download the {safe_site_name} app</li>
            <li style="margin-bottom: 8px;">Create an account</li>
            <li style="margin-bottom: 8px;">Enter your invitation code during registration</li>
        </ol>
    </div>
    <p style="color: #9ca3af; font-size: 13px;">
        This invitation expires on {safe_expiry_date}.
    </p>
    <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;">
    <p style="color: #9ca3af; font-size: 12px; text-align: center;">
        &mdash; The {safe_site_name} Team
    </p>
</div>
"""

    from_email: str = getattr(settings, 'DEFAULT_FROM_EMAIL', f'noreply@{domain_name}')

    send_mail(
        subject=subject,
        message=text_body,
        from_email=from_email,
        recipient_list=[invitation.email],
        html_message=html_body,
        fail_silently=False,
    )

    logger.info(
        "Invitation email sent to %s (code: %s, trainer: %s)",
        invitation.email,
        invite_code,
        invitation.trainer.email,
    )


def _get_trainer_display_name(trainer: User) -> str:
    """Get a display-friendly name for the trainer."""
    if trainer.first_name:
        parts = [trainer.first_name]
        if trainer.last_name:
            parts.append(trainer.last_name)
        return ' '.join(parts)
    return trainer.email.split('@')[0]

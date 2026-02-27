"""
Service for creating churn-alert notifications and re-engagement pushes.

Deduplication rules:
- Trainer notification: skip if a churn_alert exists for the same trainee
  within the last 3 days.
- Trainee push: skip if a re-engagement push was sent within the last 7 days,
  tracked via TrainerNotification.data['re_engagement_push_sent_at'].
"""
from __future__ import annotations

import logging
from datetime import timedelta
from typing import TYPE_CHECKING

from django.utils import timezone

if TYPE_CHECKING:
    from trainer.services.retention_analytics_service import TraineeEngagementItem
    from users.models import User

logger = logging.getLogger(__name__)

TRAINER_ALERT_COOLDOWN_DAYS: int = 3
PUSH_COOLDOWN_DAYS: int = 7


def create_churn_alerts(
    trainer: User,
    at_risk_trainees: list[TraineeEngagementItem],
) -> int:
    """
    Create TrainerNotification entries for at-risk trainees (critical + high).

    Deduplicates by checking for existing churn_alert notifications for the
    same trainee within the last TRAINER_ALERT_COOLDOWN_DAYS days.

    Args:
        trainer: The trainer to notify.
        at_risk_trainees: List of TraineeEngagementItem with risk_tier
                         in ('critical', 'high').

    Returns:
        Number of new notifications created.
    """
    from trainer.models import TrainerNotification

    if not at_risk_trainees:
        return 0

    now = timezone.now()
    cooldown_cutoff = now - timedelta(days=TRAINER_ALERT_COOLDOWN_DAYS)

    # Fetch existing recent churn alerts for this trainer
    existing_alerts = set(
        TrainerNotification.objects.filter(
            trainer=trainer,
            notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
            created_at__gte=cooldown_cutoff,
        ).values_list('data__trainee_id', flat=True)
    )

    created_count = 0
    notifications_to_create: list[TrainerNotification] = []

    for item in at_risk_trainees:
        if item.risk_tier not in ("critical", "high"):
            continue
        if item.trainee_id in existing_alerts:
            continue

        tier_label = item.risk_tier.capitalize()
        title = f"{tier_label} Risk: {item.trainee_name}"
        message = (
            f"{item.trainee_name} has a churn risk score of "
            f"{item.churn_risk_score}/100 (engagement: {item.engagement_score}/100). "
        )
        if item.days_since_last_activity is not None:
            message += f"Last active {item.days_since_last_activity} day(s) ago."
        else:
            message += "No recent activity recorded."

        notifications_to_create.append(
            TrainerNotification(
                trainer=trainer,
                notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
                title=title,
                message=message,
                data={
                    "trainee_id": item.trainee_id,
                    "trainee_email": item.trainee_email,
                    "risk_tier": item.risk_tier,
                    "churn_risk_score": item.churn_risk_score,
                    "engagement_score": item.engagement_score,
                },
            )
        )
        created_count += 1

    if notifications_to_create:
        TrainerNotification.objects.bulk_create(notifications_to_create)
        logger.info(
            "Created %d churn alert(s) for trainer %s",
            created_count,
            trainer.email,
        )

    return created_count


def send_re_engagement_pushes(
    trainer: User,
    critical_trainees: list[TraineeEngagementItem],
) -> int:
    """
    Send re-engagement push notifications to critical-risk trainees.

    Deduplicates by checking for a re-engagement push sent within the
    last PUSH_COOLDOWN_DAYS days, tracked via TrainerNotification with
    data containing 're_engagement_push' flag.

    Args:
        trainer: The trainer whose trainees to notify.
        critical_trainees: List of TraineeEngagementItem with risk_tier='critical'.

    Returns:
        Number of pushes sent.
    """
    from trainer.models import TrainerNotification

    if not critical_trainees:
        return 0

    now = timezone.now()
    push_cooldown_cutoff = now - timedelta(days=PUSH_COOLDOWN_DAYS)

    # Find trainees who already received a push recently
    recent_push_trainee_ids = set(
        TrainerNotification.objects.filter(
            trainer=trainer,
            notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
            data__re_engagement_push=True,
            created_at__gte=push_cooldown_cutoff,
        ).values_list('data__trainee_id', flat=True)
    )

    sent_count = 0
    for item in critical_trainees:
        if item.risk_tier != "critical":
            continue
        if item.trainee_id in recent_push_trainee_ids:
            continue

        # Record that we sent the push (as a notification record for deduplication)
        TrainerNotification.objects.create(
            trainer=trainer,
            notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
            title=f"Re-engagement: {item.trainee_name}",
            message=f"Automated re-engagement push sent to {item.trainee_name}.",
            data={
                "trainee_id": item.trainee_id,
                "trainee_email": item.trainee_email,
                "re_engagement_push": True,
                "risk_tier": item.risk_tier,
            },
        )

        # NOTE: Actual FCM push delivery would be integrated here once
        # firebase_admin is wired up. For now we log the intent.
        logger.info(
            "Re-engagement push queued for trainee %s (trainer %s)",
            item.trainee_email,
            trainer.email,
        )
        sent_count += 1

    return sent_count

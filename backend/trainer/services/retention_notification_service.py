"""
Service for creating churn-alert notifications and re-engagement pushes.

Deduplication rules:
- Trainer notification: skip if a churn_alert exists for the same trainee
  within the last 3 days.
- Trainee push: skip if a re-engagement push was sent within the last 7 days,
  tracked via TrainerNotification.data['re_engagement_push'] flag.

FCM integration:
- Trainer churn alerts are sent as push notifications (category: churn_alert).
- Trainee re-engagement pushes are sent as push notifications (category: re_engagement).
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


def _send_trainer_churn_push(
    trainer_id: int,
    trainee_id: int,
    title: str,
    message: str,
    risk_tier: str,
) -> bool:
    """Send FCM push to a trainer about an at-risk trainee.

    Returns True if the push was delivered successfully.
    """
    from core.services.notification_service import send_push_notification

    data = {
        "type": "churn_alert",
        "trainee_id": str(trainee_id),
        "risk_tier": risk_tier,
    }

    return send_push_notification(
        user_id=trainer_id,
        title=title,
        body=message,
        data=data,
        category="churn_alert",
    )


def _send_trainee_re_engagement_push(
    trainee_id: int,
    trainer_name: str,
) -> bool:
    """Send FCM push to a trainee encouraging them to come back.

    Returns True if the push was delivered successfully.
    """
    from core.services.notification_service import send_push_notification

    title = "We miss you!"
    body = (
        f"Your trainer {trainer_name} is cheering you on. "
        "Open the app to log a workout and get back on track!"
    )
    data = {
        "type": "re_engagement",
    }

    return send_push_notification(
        user_id=trainee_id,
        title=title,
        body=body,
        data=data,
        category="re_engagement",
    )


def create_churn_alerts(
    trainer: User,
    at_risk_trainees: list[TraineeEngagementItem],
) -> int:
    """
    Create TrainerNotification entries for at-risk trainees (critical + high)
    and send FCM push notifications to the trainer.

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
    # Cast to int for type-safe comparison (JSONB may return str or int)
    existing_alerts = set(
        int(tid)
        for tid in TrainerNotification.objects.filter(
            trainer=trainer,
            notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
            created_at__gte=cooldown_cutoff,
        ).values_list('data__trainee_id', flat=True)
        if tid is not None
    )

    created_count = 0
    notifications_to_create: list[TrainerNotification] = []
    push_payloads: list[tuple[int, str, str, str]] = []

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
        push_payloads.append((item.trainee_id, title, message, item.risk_tier))
        created_count += 1

    if notifications_to_create:
        TrainerNotification.objects.bulk_create(notifications_to_create)
        logger.info(
            "Created %d churn alert(s) for trainer %s",
            created_count,
            trainer.email,
        )

    # Send FCM push notifications to the trainer for each alert
    pushes_sent = 0
    for trainee_id, title, message, risk_tier in push_payloads:
        sent = _send_trainer_churn_push(
            trainer_id=trainer.id,
            trainee_id=trainee_id,
            title=title,
            message=message,
            risk_tier=risk_tier,
        )
        if sent:
            pushes_sent += 1

    if pushes_sent > 0:
        logger.info(
            "Sent %d churn alert FCM push(es) to trainer %s",
            pushes_sent,
            trainer.email,
        )

    return created_count


def send_re_engagement_pushes(
    trainer: User,
    critical_trainees: list[TraineeEngagementItem],
) -> int:
    """
    Send re-engagement push notifications to critical-risk trainees via FCM
    and log the action as a TrainerNotification.

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
    # Cast to int for type-safe comparison (JSONB may return str or int)
    recent_push_trainee_ids = set(
        int(tid)
        for tid in TrainerNotification.objects.filter(
            trainer=trainer,
            notification_type=TrainerNotification.NotificationType.CHURN_ALERT,
            data__re_engagement_push=True,
            created_at__gte=push_cooldown_cutoff,
        ).values_list('data__trainee_id', flat=True)
        if tid is not None
    )

    trainer_name = f"{trainer.first_name} {trainer.last_name}".strip()
    if not trainer_name:
        trainer_name = trainer.email.split("@")[0]

    notifications_to_create: list[TrainerNotification] = []
    trainee_ids_to_push: list[int] = []

    for item in critical_trainees:
        if item.risk_tier != "critical":
            continue
        if item.trainee_id in recent_push_trainee_ids:
            continue

        notifications_to_create.append(
            TrainerNotification(
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
        )
        trainee_ids_to_push.append(item.trainee_id)

    if notifications_to_create:
        TrainerNotification.objects.bulk_create(notifications_to_create)

    # Send FCM pushes to all eligible trainees
    pushes_sent = 0
    for trainee_id in trainee_ids_to_push:
        sent = _send_trainee_re_engagement_push(
            trainee_id=trainee_id,
            trainer_name=trainer_name,
        )
        if sent:
            pushes_sent += 1

    if pushes_sent > 0:
        logger.info(
            "Sent %d re-engagement FCM push(es) for trainer %s",
            pushes_sent,
            trainer.email,
        )

    return len(notifications_to_create)

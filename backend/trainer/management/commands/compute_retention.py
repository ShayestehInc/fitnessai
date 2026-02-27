"""
Management command to compute retention analytics and send churn alerts.

Intended to run daily via cron:
    python manage.py compute_retention
    python manage.py compute_retention --days=14
"""
from __future__ import annotations

import logging
from argparse import ArgumentParser

from django.core.management.base import BaseCommand

from trainer.services.retention_analytics_service import get_retention_analytics
from trainer.services.retention_notification_service import (
    create_churn_alerts,
    send_re_engagement_pushes,
)
from users.models import User

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Compute trainee retention scores and send churn alert notifications."

    def add_arguments(self, parser: ArgumentParser) -> None:
        parser.add_argument(
            "--days",
            type=int,
            default=14,
            help="Lookback window in days (default: 14).",
        )

    def handle(self, *args: object, **options: object) -> None:
        days: int = int(options["days"])  # type: ignore[arg-type]
        days = max(3, min(days, 365))

        trainers = User.objects.filter(
            role=User.Role.TRAINER,
            is_active=True,
        )

        total_alerts = 0
        total_pushes = 0
        trainers_processed = 0

        for trainer in trainers.iterator():
            try:
                result = get_retention_analytics(trainer, days)
                if result.summary.total_trainees == 0:
                    continue

                trainers_processed += 1

                at_risk = [
                    t for t in result.trainees
                    if t.risk_tier in ("critical", "high")
                ]
                critical = [
                    t for t in result.trainees
                    if t.risk_tier == "critical"
                ]

                alerts = create_churn_alerts(trainer, at_risk)
                pushes = send_re_engagement_pushes(trainer, critical)
                total_alerts += alerts
                total_pushes += pushes
            except Exception:
                logger.exception(
                    "Failed to compute retention for trainer %s",
                    trainer.email,
                )
                continue

        self.stdout.write(
            self.style.SUCCESS(
                f"Processed {trainers_processed} trainer(s): "
                f"{total_alerts} alert(s) created, "
                f"{total_pushes} push(es) queued."
            )
        )

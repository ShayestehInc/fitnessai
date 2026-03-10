"""
Daily Digest Service — v6.5 Step 11.

Generates daily summaries of trainee activity for trainers.
Aggregates TraineeActivitySummary data, pain events, and session feedback
into a structured digest with AI-generated narrative.
"""
from __future__ import annotations

import datetime
import logging
from dataclasses import dataclass, field
from typing import Any

from django.db import transaction
from django.db.models import Avg, Count, Q, Sum
from django.utils import timezone

from trainer.models import (
    DailyDigest,
    DigestPreference,
    TraineeActivitySummary,
    TrainerNotification,
)
from users.models import User

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class DigestMetrics:
    """Raw metrics for a trainer's digest."""
    total_trainees: int
    active_trainees: int
    workouts_completed: int
    workouts_missed: int
    pain_reports: int
    avg_compliance_pct: float
    highlights: list[str]
    concerns: list[str]
    action_items: list[str]


@dataclass(frozen=True)
class GenerateDigestResult:
    """Result of generating a daily digest."""
    digest_id: str
    trainer_id: int
    date: str
    summary_text: str
    metrics: DigestMetrics


# ---------------------------------------------------------------------------
# Digest generation
# ---------------------------------------------------------------------------

def generate_daily_digest(
    *,
    trainer: User,
    target_date: datetime.date,
) -> GenerateDigestResult:
    """
    Generate a daily digest for a trainer.
    Aggregates trainee activity, identifies highlights/concerns,
    and generates a narrative summary.
    """
    # Check if digest already exists
    existing = DailyDigest.objects.filter(
        trainer=trainer,
        date=target_date,
    ).first()
    if existing:
        return GenerateDigestResult(
            digest_id=str(existing.pk),
            trainer_id=trainer.pk,
            date=str(target_date),
            summary_text=existing.summary_text,
            metrics=DigestMetrics(
                total_trainees=existing.total_trainees,
                active_trainees=existing.active_trainees,
                workouts_completed=existing.workouts_completed,
                workouts_missed=existing.workouts_missed,
                pain_reports=existing.pain_reports,
                avg_compliance_pct=existing.avg_compliance_pct,
                highlights=existing.highlights,
                concerns=existing.concerns,
                action_items=existing.action_items,
            ),
        )

    # Gather metrics
    metrics = _gather_metrics(trainer, target_date)

    # Generate narrative
    summary_text = _generate_summary_text(trainer, target_date, metrics)

    # Persist
    digest = DailyDigest.objects.create(
        trainer=trainer,
        date=target_date,
        total_trainees=metrics.total_trainees,
        active_trainees=metrics.active_trainees,
        workouts_completed=metrics.workouts_completed,
        workouts_missed=metrics.workouts_missed,
        pain_reports=metrics.pain_reports,
        avg_compliance_pct=metrics.avg_compliance_pct,
        summary_text=summary_text,
        highlights=metrics.highlights,
        concerns=metrics.concerns,
        action_items=metrics.action_items,
    )

    return GenerateDigestResult(
        digest_id=str(digest.pk),
        trainer_id=trainer.pk,
        date=str(target_date),
        summary_text=summary_text,
        metrics=metrics,
    )


def get_digest_history(
    trainer: User,
    limit: int = 30,
) -> list[DailyDigest]:
    """Get recent digests for a trainer."""
    return list(
        DailyDigest.objects.filter(trainer=trainer)
        .order_by('-date')[:limit]
    )


def get_or_create_digest_preference(
    trainer: User,
) -> DigestPreference:
    """Get or create digest preferences for a trainer."""
    pref, _ = DigestPreference.objects.get_or_create(trainer=trainer)
    return pref


def update_digest_preference(
    trainer: User,
    **kwargs: Any,
) -> DigestPreference:
    """Update digest preferences."""
    pref = get_or_create_digest_preference(trainer)
    valid_fields = {
        'delivery_method', 'delivery_hour', 'timezone',
        'include_nutrition', 'include_workouts',
        'include_pain_reports', 'include_at_risk', 'is_active',
    }
    update_fields: list[str] = []
    for key, value in kwargs.items():
        if key in valid_fields:
            setattr(pref, key, value)
            update_fields.append(key)

    if update_fields:
        pref.save(update_fields=update_fields)
    return pref


def mark_digest_read(digest_id: str) -> None:
    """Mark a digest as read."""
    DailyDigest.objects.filter(pk=digest_id).update(
        read_at=timezone.now(),
    )


# ---------------------------------------------------------------------------
# Metrics gathering
# ---------------------------------------------------------------------------

def _gather_metrics(
    trainer: User,
    target_date: datetime.date,
) -> DigestMetrics:
    """Aggregate trainee activity for the target date."""
    from workouts.models import PainEvent, SessionFeedback

    trainees = User.objects.filter(
        parent_trainer=trainer,
        role='TRAINEE',
    )
    total_trainees = trainees.count()

    # Activity summaries for the day
    summaries = TraineeActivitySummary.objects.filter(
        trainee__in=trainees,
        date=target_date,
    )

    agg = summaries.aggregate(
        total_workouts=Sum('workouts_completed'),
        total_logged_food=Count('id', filter=Q(logged_food=True)),
        total_logged_workout=Count('id', filter=Q(logged_workout=True)),
        total_hit_protein=Count('id', filter=Q(hit_protein_goal=True)),
        total_hit_calorie=Count('id', filter=Q(hit_calorie_goal=True)),
    )

    active_trainees = summaries.values('trainee').distinct().count()
    workouts_completed = agg['total_workouts'] or 0

    # Missed = trainees who didn't log a workout (approximation)
    workouts_missed = max(0, total_trainees - (agg['total_logged_workout'] or 0))

    # Pain reports today
    pain_count = PainEvent.objects.filter(
        trainee__in=trainees,
        created_at__date=target_date,
    ).count()

    # Compliance: % of trainees who hit their calorie goal
    if total_trainees > 0:
        compliance_count = agg['total_hit_calorie'] or 0
        avg_compliance = (compliance_count / total_trainees) * 100
    else:
        avg_compliance = 0.0

    # Build highlights
    highlights: list[str] = []
    if workouts_completed > 0:
        highlights.append(f"{workouts_completed} workout(s) completed")
    protein_hits = agg['total_hit_protein'] or 0
    if protein_hits > 0:
        highlights.append(f"{protein_hits} trainee(s) hit protein goal")

    # Build concerns
    concerns: list[str] = []
    if workouts_missed > 0 and workouts_missed >= total_trainees // 2:
        concerns.append(
            f"{workouts_missed} trainee(s) did not log a workout"
        )
    if pain_count > 0:
        concerns.append(f"{pain_count} pain report(s) filed")

    # Recovery concerns from feedback
    recovery_count = SessionFeedback.objects.filter(
        trainee__in=trainees,
        created_at__date=target_date,
        recovery_concern=True,
    ).count()
    if recovery_count > 0:
        concerns.append(f"{recovery_count} recovery concern(s) flagged")

    # Action items
    action_items: list[str] = []
    if pain_count > 0:
        action_items.append("Review pain reports and consider program adjustments")
    if workouts_missed > total_trainees // 2:
        action_items.append("Check in with trainees who missed workouts")
    if recovery_count > 0:
        action_items.append("Follow up on recovery concerns")

    return DigestMetrics(
        total_trainees=total_trainees,
        active_trainees=active_trainees,
        workouts_completed=workouts_completed,
        workouts_missed=workouts_missed,
        pain_reports=pain_count,
        avg_compliance_pct=round(avg_compliance, 1),
        highlights=highlights,
        concerns=concerns,
        action_items=action_items,
    )


def _generate_summary_text(
    trainer: User,
    target_date: datetime.date,
    metrics: DigestMetrics,
) -> str:
    """Generate a human-readable summary from metrics.

    This is a deterministic summary. AI-powered narrative generation
    can be plugged in later by replacing this function.
    """
    trainer_name = trainer.get_full_name() or trainer.email
    date_str = target_date.strftime('%A, %B %d')

    parts: list[str] = [
        f"Daily Digest for {trainer_name} — {date_str}",
        "",
    ]

    # Overview
    parts.append(
        f"{metrics.active_trainees} of {metrics.total_trainees} trainees "
        f"were active today."
    )

    if metrics.workouts_completed > 0:
        parts.append(
            f"{metrics.workouts_completed} workout(s) completed."
        )

    if metrics.avg_compliance_pct > 0:
        parts.append(
            f"Nutrition compliance: {metrics.avg_compliance_pct}%."
        )

    # Highlights
    if metrics.highlights:
        parts.append("")
        parts.append("Highlights:")
        for h in metrics.highlights:
            parts.append(f"  • {h}")

    # Concerns
    if metrics.concerns:
        parts.append("")
        parts.append("Concerns:")
        for c in metrics.concerns:
            parts.append(f"  ⚠ {c}")

    # Action items
    if metrics.action_items:
        parts.append("")
        parts.append("Action Items:")
        for a in metrics.action_items:
            parts.append(f"  → {a}")

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Draft message helper
# ---------------------------------------------------------------------------

def draft_trainee_message(
    *,
    trainer: User,
    trainee: User,
    message_type: str,
    context: str = '',
) -> str:
    """
    Generate a draft message from trainer to trainee.

    Supported message_types:
    - encouragement: positive reinforcement
    - check_in: general check-in
    - missed_workout: follow up on missed workout
    - pain_follow_up: follow up on pain report
    - goal_update: discuss goal changes

    Returns a draft message string. No AI call — uses templates.
    AI-powered drafting can be added later.
    """
    trainee_name = trainee.first_name or trainee.email.split('@')[0]

    templates = {
        'encouragement': (
            f"Hey {trainee_name}! Great work on your recent sessions. "
            f"I can see you've been consistent and that's going to pay off. "
            f"Keep it up! 💪"
        ),
        'check_in': (
            f"Hi {trainee_name}, just checking in to see how everything "
            f"is going. How are you feeling about your training lately? "
            f"Any adjustments you'd like to make?"
        ),
        'missed_workout': (
            f"Hey {trainee_name}, I noticed you missed your workout recently. "
            f"No worries — life happens! Just want to make sure everything is "
            f"okay. Let me know if you need to adjust your schedule."
        ),
        'pain_follow_up': (
            f"Hi {trainee_name}, I saw your pain report and want to follow up. "
            f"How is it feeling now? We may need to modify some exercises or "
            f"adjust your program. Let's chat about it."
        ),
        'goal_update': (
            f"Hey {trainee_name}, based on your recent progress, I think it "
            f"might be a good time to revisit your goals. Want to schedule "
            f"a quick check-in to discuss?"
        ),
    }

    draft = templates.get(message_type, templates['check_in'])

    if context:
        draft += f"\n\n(Context: {context})"

    return draft

"""
Audit trail summary service — v6.5 Step 16.

Provides summary statistics and timeline of DecisionLog entries
scoped to a trainer and their trainees.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import timedelta
from typing import Any

from django.db.models import Count, Q, QuerySet
from django.utils import timezone

from users.models import User
from workouts.models import DecisionLog


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class DecisionSummaryByType:
    """Count of decisions grouped by decision_type."""
    decision_type: str
    count: int


@dataclass(frozen=True)
class DecisionSummaryByActor:
    """Count of decisions grouped by actor_type."""
    actor_type: str
    count: int


@dataclass(frozen=True)
class AuditSummary:
    """Aggregate audit trail summary."""
    total_decisions: int
    recent_decisions_7d: int
    by_type: list[DecisionSummaryByType]
    by_actor: list[DecisionSummaryByActor]
    reverted_count: int
    period_days: int


@dataclass(frozen=True)
class TimelineEntry:
    """Single entry in the audit timeline."""
    decision_id: str
    timestamp: str
    actor_type: str
    actor_email: str
    decision_type: str
    description: str
    is_reverted: bool
    context: dict[str, Any]


# ---------------------------------------------------------------------------
# Queryset helpers
# ---------------------------------------------------------------------------

def _trainer_decision_qs(trainer: User) -> QuerySet[DecisionLog]:
    """
    Return DecisionLog entries visible to this trainer:
    decisions they made + decisions by their trainees.
    """
    trainee_subquery = User.objects.filter(
        parent_trainer=trainer,
    ).values('id')
    return DecisionLog.objects.filter(
        Q(actor=trainer) | Q(actor_id__in=trainee_subquery)
    ).select_related('actor', 'undo_snapshot')


def _describe_decision(log: DecisionLog) -> str:
    """Generate a human-readable description of a decision."""
    actor_name = log.actor.email if log.actor else 'System'
    dtype = log.decision_type.replace('_', ' ').title()

    # Build context hint
    ctx = log.context or {}
    parts: list[str] = []
    if 'exercise_name' in ctx:
        parts.append(f"exercise: {ctx['exercise_name']}")
    if 'plan_id' in ctx:
        parts.append(f"plan #{ctx['plan_id']}")
    if 'slot_id' in ctx:
        parts.append(f"slot #{ctx['slot_id']}")

    context_str = f" ({', '.join(parts)})" if parts else ""
    return f"{actor_name} — {dtype}{context_str}"


# ---------------------------------------------------------------------------
# Main entry points
# ---------------------------------------------------------------------------

def get_audit_summary(
    *,
    trainer: User,
    days: int = 30,
) -> AuditSummary:
    """Compute audit trail summary statistics."""
    days = max(1, min(365, days))
    start_date = timezone.now() - timedelta(days=days)

    base_qs = _trainer_decision_qs(trainer)
    period_qs = base_qs.filter(timestamp__gte=start_date)
    seven_days_ago = timezone.now() - timedelta(days=7)

    total = period_qs.count()
    recent_7d = base_qs.filter(timestamp__gte=seven_days_ago).count()

    by_type_rows = (
        period_qs.values('decision_type')
        .annotate(count=Count('id'))
        .order_by('-count')
    )
    by_type = [
        DecisionSummaryByType(
            decision_type=row['decision_type'],
            count=row['count'],
        )
        for row in by_type_rows
    ]

    by_actor_rows = (
        period_qs.values('actor_type')
        .annotate(count=Count('id'))
        .order_by('-count')
    )
    by_actor = [
        DecisionSummaryByActor(
            actor_type=row['actor_type'],
            count=row['count'],
        )
        for row in by_actor_rows
    ]

    reverted_count = period_qs.filter(
        undo_snapshot__reverted_at__isnull=False,
    ).count()

    return AuditSummary(
        total_decisions=total,
        recent_decisions_7d=recent_7d,
        by_type=by_type,
        by_actor=by_actor,
        reverted_count=reverted_count,
        period_days=days,
    )


def get_audit_timeline(
    *,
    trainer: User,
    days: int = 30,
    limit: int = 50,
    offset: int = 0,
) -> list[TimelineEntry]:
    """
    Return a paginated timeline of recent decisions.
    Most recent first.
    """
    days = max(1, min(365, days))
    limit = max(1, min(100, limit))
    offset = max(0, offset)
    start_date = timezone.now() - timedelta(days=days)

    qs = (
        _trainer_decision_qs(trainer)
        .filter(timestamp__gte=start_date)
        .order_by('-timestamp')
    )[offset:offset + limit]

    entries: list[TimelineEntry] = []
    for log in qs:
        is_reverted = (
            log.undo_snapshot is not None
            and log.undo_snapshot.is_reverted
        )
        entries.append(TimelineEntry(
            decision_id=str(log.id),
            timestamp=log.timestamp.isoformat(),
            actor_type=log.actor_type,
            actor_email=log.actor.email if log.actor else 'system',
            decision_type=log.decision_type,
            description=_describe_decision(log),
            is_reverted=is_reverted,
            context=log.context or {},
        ))

    return entries

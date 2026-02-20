"""
Service for computing trainer revenue analytics from TraineePayment and
TraineeSubscription models.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import timedelta
from decimal import Decimal
from typing import TYPE_CHECKING

from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone

if TYPE_CHECKING:
    from users.models import User


@dataclass(frozen=True)
class RevenueSubscriberItem:
    trainee_id: int
    trainee_email: str
    trainee_name: str
    amount: str
    currency: str
    current_period_end: str | None
    days_until_renewal: int | None
    subscribed_since: str


@dataclass(frozen=True)
class RevenuePaymentItem:
    id: int
    trainee_email: str
    trainee_name: str
    payment_type: str
    status: str
    amount: str
    currency: str
    description: str
    paid_at: str | None
    created_at: str


@dataclass(frozen=True)
class MonthlyRevenuePoint:
    month: str
    amount: str


@dataclass(frozen=True)
class RevenueAnalyticsResult:
    period_days: int
    mrr: str
    total_revenue: str
    active_subscribers: int
    avg_revenue_per_subscriber: str
    monthly_revenue: list[MonthlyRevenuePoint]
    subscribers: list[RevenueSubscriberItem]
    recent_payments: list[RevenuePaymentItem]


def get_revenue_analytics(trainer: User, days: int) -> RevenueAnalyticsResult:
    """
    Compute revenue analytics for a trainer.

    Args:
        trainer: The authenticated trainer user.
        days: Number of days to look back for period-based stats (1-365).

    Returns:
        Frozen dataclass with aggregated revenue metrics, monthly breakdown,
        active subscriber list, and recent payments.
    """
    from subscriptions.models import TraineePayment, TraineeSubscription

    now = timezone.now()
    start_date = now - timedelta(days=days)

    # ── MRR & subscriber count (always current, not period-filtered) ──
    active_subs = TraineeSubscription.objects.filter(
        trainer=trainer,
        status=TraineeSubscription.Status.ACTIVE,
    ).select_related('trainee')

    mrr_agg = active_subs.aggregate(total=Sum('amount'), count=Count('id'))
    mrr = mrr_agg['total'] or Decimal('0.00')
    active_count: int = mrr_agg['count']
    avg_per_sub = (
        (mrr / active_count) if active_count > 0 else Decimal('0.00')
    )

    # ── Total revenue in period (only succeeded payments) ──
    period_payments = TraineePayment.objects.filter(
        trainer=trainer,
        status=TraineePayment.Status.SUCCEEDED,
        paid_at__gte=start_date,
    )
    total_revenue_result = period_payments.aggregate(total=Sum('amount'))
    total_revenue = total_revenue_result['total'] or Decimal('0.00')

    # ── Monthly revenue breakdown (last 12 months, zero-filled) ──
    twelve_months_ago = (now.replace(day=1) - timedelta(days=365)).replace(day=1)
    monthly_data = (
        TraineePayment.objects.filter(
            trainer=trainer,
            status=TraineePayment.Status.SUCCEEDED,
            paid_at__gte=twelve_months_ago,
        )
        .annotate(month=TruncMonth('paid_at'))
        .values('month')
        .annotate(revenue=Sum('amount'))
        .order_by('month')
    )
    revenue_by_month: dict[str, str] = {
        entry['month'].strftime('%Y-%m'): str(entry['revenue'])
        for entry in monthly_data
    }

    monthly_revenue: list[MonthlyRevenuePoint] = []
    cursor = twelve_months_ago
    now_month = now.replace(day=1)
    while cursor <= now_month:
        key = cursor.strftime('%Y-%m')
        monthly_revenue.append(
            MonthlyRevenuePoint(month=key, amount=revenue_by_month.get(key, '0.00'))
        )
        if cursor.month == 12:
            cursor = cursor.replace(year=cursor.year + 1, month=1)
        else:
            cursor = cursor.replace(month=cursor.month + 1)

    # ── Active subscribers list ──
    subscribers: list[RevenueSubscriberItem] = []
    for sub in active_subs.order_by('-created_at'):
        trainee = sub.trainee
        name = f"{trainee.first_name} {trainee.last_name}".strip()
        subscribers.append(
            RevenueSubscriberItem(
                trainee_id=trainee.id,
                trainee_email=trainee.email,
                trainee_name=name or trainee.email,
                amount=str(sub.amount),
                currency=sub.currency,
                current_period_end=(
                    sub.current_period_end.isoformat() if sub.current_period_end else None
                ),
                days_until_renewal=sub.days_until_renewal(),
                subscribed_since=sub.created_at.isoformat(),
            )
        )

    # ── Recent payments (last 10, any status) ──
    recent_qs = (
        TraineePayment.objects.filter(trainer=trainer)
        .select_related('trainee')
        .order_by('-created_at')[:10]
    )
    recent_payments: list[RevenuePaymentItem] = []
    for payment in recent_qs:
        trainee = payment.trainee
        name = f"{trainee.first_name} {trainee.last_name}".strip()
        recent_payments.append(
            RevenuePaymentItem(
                id=payment.id,
                trainee_email=trainee.email,
                trainee_name=name or trainee.email,
                payment_type=payment.payment_type,
                status=payment.status,
                amount=str(payment.amount),
                currency=payment.currency,
                description=payment.description,
                paid_at=payment.paid_at.isoformat() if payment.paid_at else None,
                created_at=payment.created_at.isoformat(),
            )
        )

    return RevenueAnalyticsResult(
        period_days=days,
        mrr=str(mrr),
        total_revenue=str(total_revenue),
        active_subscribers=active_count,
        avg_revenue_per_subscriber=str(avg_per_sub.quantize(Decimal('0.01'))),
        monthly_revenue=monthly_revenue,
        subscribers=subscribers,
        recent_payments=recent_payments,
    )

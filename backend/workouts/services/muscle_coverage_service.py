from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from typing import Optional

from django.db.models import QuerySet

from workouts.models import LiftSetLog


@dataclass(frozen=True)
class MuscleCoverageResult:
    trainee_id: int
    period: str
    start_date: date
    end_date: date
    muscle_intensities: dict[str, float]  # slug -> 0.0-1.0 normalized
    muscle_workloads: dict[str, str]  # slug -> raw workload as string
    total_workload: str
    muscles_trained: int
    muscles_total: int


class MuscleCoverageService:
    """Computes per-muscle training coverage/intensity for anatomy heatmap."""

    TOTAL_MUSCLE_GROUPS = 21  # matches DetailedMuscleGroup count (excluding 'neck')

    @classmethod
    def compute_coverage(
        cls,
        trainee_id: int,
        period: str = 'week',
        session_id: Optional[str] = None,
        session_date: Optional[date] = None,
    ) -> MuscleCoverageResult:
        today = date.today()

        if period == 'session' and session_date:
            start = session_date
            end = session_date
        elif period == 'month':
            start = today.replace(day=1)
            end = today
        else:
            # Default to week (Monday-based)
            start = today - timedelta(days=today.weekday())
            end = today

        sets = LiftSetLog.objects.filter(
            trainee_id=trainee_id,
            session_date__gte=start,
            session_date__lte=end,
            workload_eligible=True,
            set_workload_value__gt=0,
        ).select_related('exercise')

        muscle_totals = cls._distribute_to_muscles(sets)

        # Compute total
        total = sum(muscle_totals.values(), Decimal('0'))

        # Normalize to 0.0-1.0
        max_workload = max(muscle_totals.values()) if muscle_totals else Decimal('0')
        intensities: dict[str, float] = {}
        if max_workload > 0:
            for muscle, workload in muscle_totals.items():
                intensities[muscle] = round(
                    float(workload / max_workload), 3
                )

        quantize = Decimal('0.01')
        raw_workloads = {
            k: str(v.quantize(quantize, rounding=ROUND_HALF_UP))
            for k, v in sorted(muscle_totals.items(), key=lambda x: x[1], reverse=True)
        }

        return MuscleCoverageResult(
            trainee_id=trainee_id,
            period=period,
            start_date=start,
            end_date=end,
            muscle_intensities=dict(sorted(intensities.items(), key=lambda x: x[1], reverse=True)),
            muscle_workloads=raw_workloads,
            total_workload=str(total.quantize(quantize, rounding=ROUND_HALF_UP)),
            muscles_trained=len(muscle_totals),
            muscles_total=cls.TOTAL_MUSCLE_GROUPS,
        )

    @staticmethod
    def _distribute_to_muscles(sets: QuerySet[LiftSetLog]) -> dict[str, Decimal]:
        """Distribute set workload to muscles using muscle_contribution_map."""
        muscle_totals: dict[str, Decimal] = {}

        for s in sets.iterator(chunk_size=500):
            exercise = s.exercise
            workload = s.set_workload_value

            if workload <= 0:
                continue

            contrib_map = exercise.muscle_contribution_map
            if contrib_map:
                for muscle, weight in contrib_map.items():
                    w = Decimal(str(weight))
                    muscle_totals[muscle] = muscle_totals.get(muscle, Decimal('0')) + workload * w
            elif exercise.primary_muscle_group:
                mg = exercise.primary_muscle_group
                muscle_totals[mg] = muscle_totals.get(mg, Decimal('0')) + workload

        return muscle_totals

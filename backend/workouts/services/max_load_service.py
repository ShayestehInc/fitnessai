"""
Max/Load Engine — e1RM estimation, Training Max calculation, and load prescription.

This service powers intelligent load recommendations based on per-set performance data.
Only sets passing standardization criteria are used for e1RM updates.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from typing import TYPE_CHECKING
from uuid import UUID

from django.db import transaction
from django.utils import timezone

if TYPE_CHECKING:
    from workouts.models import LiftMax, LiftSetLog


@dataclass(frozen=True)
class E1RMEstimate:
    """Result of an e1RM estimation."""
    value: Decimal
    formula: str
    source_weight: Decimal
    source_reps: int


@dataclass(frozen=True)
class LoadPrescription:
    """Result of a load prescription calculation."""
    prescribed_load: Decimal
    unit: str
    based_on_tm: Decimal
    target_percentage: Decimal
    rounding_increment: Decimal
    reason: str | None


class MaxLoadService:
    """
    Central service for all max estimation and load prescription logic.

    Key rules from v6.5 spec:
    - Only standardization-passing sets update e1RM
    - Conservative estimation: use lower of Epley/Brzycki
    - Cap estimation reps at 15 (formulas unreliable above that)
    - RPE=10 with 1 rep means weight IS the 1RM
    - Smoothing: new e1RM must beat current by a threshold OR be persistent decline
    """

    # Reps above this threshold make e1RM formulas unreliable
    MAX_ESTIMATION_REPS: int = 15

    # Minimum reps to use formula (1 rep = actual max, not estimated)
    MIN_FORMULA_REPS: int = 2

    # Smoothing: only update if new estimate is within this factor of current
    # Prevents wild swings from bad data
    SMOOTHING_CEILING_FACTOR: Decimal = Decimal("1.15")  # Max 15% increase
    SMOOTHING_FLOOR_FACTOR: Decimal = Decimal("0.90")    # Max 10% decrease per update

    @staticmethod
    def estimate_e1rm_epley(weight: Decimal, reps: int) -> Decimal:
        """
        Epley formula: e1RM = weight × (1 + reps/30)

        Standard for moderate rep ranges (3-10).
        """
        if reps <= 0:
            return Decimal("0")
        if reps == 1:
            return weight
        return weight * (1 + Decimal(reps) / Decimal(30))

    @staticmethod
    def estimate_e1rm_brzycki(weight: Decimal, reps: int) -> Decimal:
        """
        Brzycki formula: e1RM = weight × 36 / (37 - reps)

        More conservative at higher rep ranges.
        """
        if reps <= 0:
            return Decimal("0")
        if reps == 1:
            return weight
        denominator = Decimal(37) - Decimal(reps)
        if denominator <= 0:
            return Decimal("0")
        return weight * Decimal(36) / denominator

    @classmethod
    def estimate_e1rm(
        cls,
        weight: Decimal,
        reps: int,
        rpe: Decimal | None = None,
    ) -> E1RMEstimate:
        """
        Estimate e1RM using the conservative approach (lower of Epley/Brzycki).

        Special cases:
        - 0 reps → e1RM = 0 (invalid set)
        - 1 rep at RPE 10 → e1RM = weight (true max)
        - >15 reps → capped at 15 for estimation
        """
        if reps <= 0 or weight <= 0:
            return E1RMEstimate(
                value=Decimal("0"),
                formula="none",
                source_weight=weight,
                source_reps=reps,
            )

        # True 1RM: 1 rep at RPE 10
        if reps == 1 and rpe is not None and rpe >= Decimal("10"):
            return E1RMEstimate(
                value=weight,
                formula="true_max",
                source_weight=weight,
                source_reps=reps,
            )

        # Cap reps at MAX_ESTIMATION_REPS for formula accuracy
        capped_reps = min(reps, cls.MAX_ESTIMATION_REPS)

        if capped_reps == 1:
            # Single rep (RPE < 10) — use weight as estimate
            return E1RMEstimate(
                value=weight,
                formula="single_rep",
                source_weight=weight,
                source_reps=reps,
            )

        epley = cls.estimate_e1rm_epley(weight, capped_reps)
        brzycki = cls.estimate_e1rm_brzycki(weight, capped_reps)

        # Conservative: take the lower estimate
        if epley <= brzycki:
            return E1RMEstimate(
                value=epley.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
                formula="epley",
                source_weight=weight,
                source_reps=reps,
            )
        return E1RMEstimate(
            value=brzycki.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
            formula="brzycki",
            source_weight=weight,
            source_reps=reps,
        )

    @classmethod
    def smooth_e1rm_update(
        cls,
        current_e1rm: Decimal,
        new_estimate: Decimal,
    ) -> Decimal:
        """
        Apply smoothing to prevent wild e1RM swings.

        Rules:
        - If no current e1RM (0), accept new estimate directly
        - Cap increases at SMOOTHING_CEILING_FACTOR of current
        - Cap decreases at SMOOTHING_FLOOR_FACTOR of current
        - Result is quantized to 2 decimal places
        """
        if current_e1rm <= 0:
            return new_estimate.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        ceiling = current_e1rm * cls.SMOOTHING_CEILING_FACTOR
        floor = current_e1rm * cls.SMOOTHING_FLOOR_FACTOR

        clamped = max(floor, min(new_estimate, ceiling))
        return clamped.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @staticmethod
    def calculate_tm(e1rm: Decimal, percentage: Decimal = Decimal("90")) -> Decimal:
        """
        Calculate Training Max from e1RM.

        TM = e1RM × (percentage / 100)
        Default 90% per v6.5 spec.
        """
        if e1rm <= 0:
            return Decimal("0")
        return (e1rm * percentage / Decimal("100")).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )

    @staticmethod
    def round_to_equipment(load: Decimal, increment: Decimal = Decimal("2.5")) -> Decimal:
        """
        Round load to the nearest equipment increment.

        Default 2.5 lb/kg (standard plate increment).
        Rounds to nearest (not always down) for best accuracy.
        """
        if increment <= 0:
            return load
        return (load / increment).quantize(Decimal("1"), rounding=ROUND_HALF_UP) * increment

    @classmethod
    def prescribe_load(
        cls,
        tm: Decimal,
        target_percentage: Decimal,
        rounding_increment: Decimal = Decimal("2.5"),
        unit: str = "lb",
    ) -> LoadPrescription:
        """
        Prescribe a load for a given target percentage of Training Max.

        Example: prescribe_load(tm=200, target_percentage=80) → 160 lb (rounded)
        """
        if tm <= 0:
            return LoadPrescription(
                prescribed_load=Decimal("0"),
                unit=unit,
                based_on_tm=tm,
                target_percentage=target_percentage,
                rounding_increment=rounding_increment,
                reason="No training max available.",
            )

        raw_load = tm * target_percentage / Decimal("100")
        rounded_load = cls.round_to_equipment(raw_load, rounding_increment)

        return LoadPrescription(
            prescribed_load=rounded_load,
            unit=unit,
            based_on_tm=tm,
            target_percentage=target_percentage,
            rounding_increment=rounding_increment,
            reason=None,
        )

    @classmethod
    @transaction.atomic
    def update_max_from_set(cls, set_log: LiftSetLog) -> LiftMax | None:
        """
        Evaluate a completed set and update the trainee's LiftMax if qualifying.

        A set qualifies for e1RM update when:
        1. standardization_pass = True
        2. completed_reps > 0
        3. canonical_external_load_value > 0

        Returns the updated LiftMax if an update was made, None otherwise.
        """
        from workouts.models import LiftMax as LiftMaxModel

        if not set_log.standardization_pass:
            return None
        if set_log.completed_reps <= 0:
            return None
        if set_log.canonical_external_load_value <= 0:
            return None

        estimate = cls.estimate_e1rm(
            weight=set_log.canonical_external_load_value,
            reps=set_log.completed_reps,
            rpe=set_log.rpe,
        )

        if estimate.value <= 0:
            return None

        lift_max, _created = LiftMaxModel.objects.get_or_create(
            trainee=set_log.trainee,
            exercise=set_log.exercise,
        )

        smoothed = cls.smooth_e1rm_update(lift_max.e1rm_current, estimate.value)

        # Only update if the smoothed value actually changed
        if smoothed == lift_max.e1rm_current and lift_max.e1rm_current > 0:
            return lift_max

        lift_max.e1rm_current = smoothed
        lift_max.e1rm_history.append({
            "date": str(set_log.session_date),
            "value": str(smoothed),
            "source_set_id": str(set_log.id),
            "formula": estimate.formula,
        })

        new_tm = cls.calculate_tm(smoothed, lift_max.tm_percentage)
        if new_tm != lift_max.tm_current:
            lift_max.tm_current = new_tm
            lift_max.tm_history.append({
                "date": str(set_log.session_date),
                "value": str(new_tm),
                "reason": "e1rm_update",
                "trigger": str(set_log.id),
            })

        lift_max.save()
        return lift_max

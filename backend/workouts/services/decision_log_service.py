"""
Service for creating and managing DecisionLog + UndoSnapshot entries.

Every automated decision in the system MUST go through this service to ensure
proper audit trail, undo support, and transparency per v6.5 spec.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any
from uuid import UUID

from django.db import transaction
from django.utils import timezone

from users.models import User
from workouts.models import DecisionLog, UndoSnapshot


@dataclass(frozen=True)
class DecisionResult:
    """Return type for log_decision — never return raw dicts."""
    decision_id: UUID
    undo_snapshot_id: UUID | None
    before_state: dict[str, Any] | None = None


class DecisionLogService:
    """
    Central service for all decision logging.

    Usage:
        result = DecisionLogService.log_decision(
            actor_type=DecisionLog.ActorType.SYSTEM,
            actor=None,
            decision_type="exercise_swap",
            context={"plan_id": 1, "slot_id": 42},
            inputs_snapshot={"current_exercise": 10, "pain_flag": True},
            constraints_applied={"same_pattern": True, "no_high_impact": True},
            options_considered=[
                {"exercise_id": 20, "score": 0.95, "reasons": ["same_muscle", "lower_impact"]},
                {"exercise_id": 30, "score": 0.80, "reasons": ["same_pattern"]},
            ],
            final_choice={"exercise_id": 20},
            reason_codes=["pain_flag", "same_muscle_match"],
            undo_scope=UndoSnapshot.Scope.SLOT,
            before_state={"slot": {"exercise_id": 10, "sets": 3}},
            after_state={"slot": {"exercise_id": 20, "sets": 3}},
        )
    """

    @staticmethod
    @transaction.atomic
    def log_decision(
        *,
        actor_type: str,
        decision_type: str,
        context: dict[str, Any],
        inputs_snapshot: dict[str, Any],
        final_choice: dict[str, Any],
        reason_codes: list[str],
        actor: User | None = None,
        constraints_applied: dict[str, Any] | None = None,
        options_considered: list[dict[str, Any]] | None = None,
        override_info: dict[str, Any] | None = None,
        undo_scope: str | None = None,
        before_state: dict[str, Any] | None = None,
        after_state: dict[str, Any] | None = None,
    ) -> DecisionResult:
        """
        Create a DecisionLog entry with optional UndoSnapshot.

        If undo_scope, before_state, and after_state are all provided,
        an UndoSnapshot is created and linked to the decision.

        Raises ValueError if undo fields are partially provided.
        """
        undo_fields = [undo_scope, before_state, after_state]
        has_any_undo = any(f is not None for f in undo_fields)
        has_all_undo = all(f is not None for f in undo_fields)

        if has_any_undo and not has_all_undo:
            raise ValueError(
                "undo_scope, before_state, and after_state must all be provided "
                "together, or none of them."
            )

        snapshot: UndoSnapshot | None = None
        if has_all_undo:
            assert undo_scope is not None
            assert before_state is not None
            assert after_state is not None
            snapshot = UndoSnapshot.objects.create(
                scope=undo_scope,
                before_state=before_state,
                after_state=after_state,
            )

        decision = DecisionLog.objects.create(
            actor_type=actor_type,
            actor=actor,
            decision_type=decision_type,
            context=context,
            inputs_snapshot=inputs_snapshot,
            constraints_applied=constraints_applied or {},
            options_considered=options_considered or [],
            final_choice=final_choice,
            reason_codes=reason_codes,
            override_info=override_info,
            undo_snapshot=snapshot,
        )

        return DecisionResult(
            decision_id=decision.id,
            undo_snapshot_id=snapshot.id if snapshot else None,
        )

    @staticmethod
    @transaction.atomic
    def undo_decision(
        *,
        decision_id: UUID,
        actor: User | None = None,
    ) -> DecisionResult:
        """
        Mark a decision as reverted and return the before_state.

        This service marks the UndoSnapshot as reverted and logs the undo action,
        but does NOT automatically restore domain objects. The caller must use
        the returned before_state to apply the actual restoration — different
        decision types require different restoration logic.

        Creates a NEW DecisionLog entry recording the undo action itself.

        Raises ValueError if the decision cannot be undone.
        """
        try:
            decision = DecisionLog.objects.select_related('undo_snapshot').get(id=decision_id)
        except DecisionLog.DoesNotExist:
            raise ValueError(f"Decision {decision_id} not found.")

        if decision.undo_snapshot is None:
            raise ValueError("This decision cannot be undone (no undo snapshot).")

        if decision.undo_snapshot.is_reverted:
            raise ValueError("This decision has already been reverted.")

        # Mark the snapshot as reverted
        snapshot = decision.undo_snapshot
        snapshot.reverted_at = timezone.now()
        snapshot.save(update_fields=['reverted_at'])

        # Log the undo itself as a new decision
        actor_type = (
            DecisionLog.ActorType.TRAINER if actor and actor.is_trainer()
            else DecisionLog.ActorType.USER if actor
            else DecisionLog.ActorType.SYSTEM
        )

        undo_log = DecisionLog.objects.create(
            actor_type=actor_type,
            actor=actor,
            decision_type='undo',
            context=decision.context,
            inputs_snapshot={'reverted_decision_id': str(decision_id)},
            constraints_applied={},
            options_considered=[],
            final_choice={'restored_state': snapshot.before_state},
            reason_codes=['manual_undo'],
        )

        return DecisionResult(
            decision_id=undo_log.id,
            undo_snapshot_id=None,
            before_state=snapshot.before_state,
        )

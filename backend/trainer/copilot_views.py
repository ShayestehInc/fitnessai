"""
Trainer Copilot API endpoints — v6.5 §16.1.
"""
from __future__ import annotations

from typing import cast

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from users.models import User
from .services.copilot_service import (
    draft_response,
    explain_decision,
    propose_plan_edit,
    summarize_trainee_checkins,
)


class CopilotViewSet(viewsets.ViewSet):
    """
    AI-powered copilot for trainers.
    Explains decisions, summarizes data, proposes edits, drafts messages.
    """
    permission_classes = [IsAuthenticated]

    def _require_trainer(self, request: Request) -> User:
        user = cast(User, request.user)
        if user.role not in ('TRAINER', 'ADMIN'):
            raise PermissionDenied("Only trainers and admins can use the copilot.")
        return user

    @action(detail=False, methods=['post'], url_path='explain-decision')
    def explain(self, request: Request) -> Response:
        """Explain a DecisionLog entry in plain English."""
        self._require_trainer(request)

        decision_log_id = request.data.get('decision_log_id')
        if not decision_log_id:
            return Response(
                {'detail': 'decision_log_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = explain_decision(str(decision_log_id))

        return Response({
            'decision_log_id': result.decision_log_id,
            'decision_type': result.decision_type,
            'summary': result.summary,
            'inputs_explained': result.inputs_explained,
            'alternatives_explained': result.alternatives_explained,
            'final_choice_explained': result.final_choice_explained,
            'reason_codes': result.reason_codes,
        })

    @action(detail=False, methods=['post'], url_path='summarize-checkins')
    def summarize_checkins(self, request: Request) -> Response:
        """Summarize a trainee's recent check-in responses."""
        trainer = self._require_trainer(request)

        trainee_id = request.data.get('trainee_id')
        days = int(request.data.get('days', 30))
        if not trainee_id:
            return Response(
                {'detail': 'trainee_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = summarize_trainee_checkins(
            trainer=trainer,
            trainee_id=int(trainee_id),
            days=days,
        )

        return Response({
            'trainee_id': result.trainee_id,
            'trainee_name': result.trainee_name,
            'period': result.period,
            'total_checkins': result.total_checkins,
            'highlights': result.highlights,
            'concerns': result.concerns,
            'trends': result.trends,
        })

    @action(detail=False, methods=['post'], url_path='propose-edit')
    def propose_edit(self, request: Request) -> Response:
        """Propose plan edits based on trainer instruction."""
        trainer = self._require_trainer(request)

        plan_id = request.data.get('plan_id')
        instruction = request.data.get('instruction', '')
        if not plan_id or not instruction:
            return Response(
                {'detail': 'plan_id and instruction are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = propose_plan_edit(
            trainer=trainer,
            plan_id=str(plan_id),
            instruction=str(instruction),
        )

        return Response({
            'plan_id': result.plan_id,
            'instruction': result.instruction,
            'proposed_changes': result.proposed_changes,
            'rationale': result.rationale,
            'confidence': result.confidence,
        })

    @action(detail=False, methods=['post'], url_path='draft-response')
    def draft(self, request: Request) -> Response:
        """Draft a message for a trainee."""
        trainer = self._require_trainer(request)

        trainee_id = request.data.get('trainee_id')
        context = request.data.get('context', '')
        if not trainee_id:
            return Response(
                {'detail': 'trainee_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = draft_response(
            trainer=trainer,
            trainee_id=int(trainee_id),
            context=str(context),
        )

        return Response({
            'trainee_id': result.trainee_id,
            'context': result.context,
            'draft_text': result.draft_text,
            'alternatives': result.alternatives,
            'tone': result.tone,
        })

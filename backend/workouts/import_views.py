"""
Views for program import pipeline — v6.5 Step 12.

Two-phase workflow:
1. POST upload CSV → parse & validate → create draft
2. GET draft → review → POST confirm or DELETE reject
"""
from __future__ import annotations

from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import User
from .models import ProgramImportDraft
from .services.program_import_service import (
    confirm_import,
    get_draft,
    list_drafts,
    reject_draft,
    parse_csv_and_create_draft,
)


# ---------------------------------------------------------------------------
# Serializers (inline — small, tightly coupled to these views)
# ---------------------------------------------------------------------------

class UploadCSVSerializer(serializers.Serializer):
    """Input for CSV upload."""
    csv_content = serializers.CharField(
        help_text="Raw CSV content as a string.",
    )
    plan_name = serializers.CharField(
        max_length=200, required=False, default='',
    )
    goal = serializers.CharField(
        max_length=50, required=False, default='strength',
    )
    trainee_id = serializers.IntegerField(
        required=False, default=None, allow_null=True,
    )


class DraftSummarySerializer(serializers.Serializer):
    """Read-only summary of a draft."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    plan_name = serializers.CharField()
    goal = serializers.CharField()
    total_weeks = serializers.IntegerField()
    total_sessions = serializers.IntegerField()
    total_slots = serializers.IntegerField()
    validation_errors = serializers.ListField(child=serializers.CharField())
    validation_warnings = serializers.ListField(child=serializers.CharField())
    parsed_data = serializers.JSONField()
    trainee_id = serializers.IntegerField(allow_null=True)
    training_plan_id = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField()
    confirmed_at = serializers.DateTimeField(allow_null=True)

    def get_training_plan_id(self, obj: ProgramImportDraft) -> str | None:
        if obj.training_plan_id is not None:
            return str(obj.training_plan_id)
        return None


class DraftListItemSerializer(serializers.Serializer):
    """Lightweight list item."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    plan_name = serializers.CharField()
    goal = serializers.CharField()
    total_weeks = serializers.IntegerField()
    total_sessions = serializers.IntegerField()
    total_slots = serializers.IntegerField()
    has_errors = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField()

    def get_has_errors(self, obj: ProgramImportDraft) -> bool:
        return bool(obj.validation_errors)


# ---------------------------------------------------------------------------
# Views
# ---------------------------------------------------------------------------

def _require_trainer(request: Request) -> User:
    """Verify user is a trainer. Raises 403 if not."""
    user = request.user
    if user.role != 'TRAINER':
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied("Only trainers can manage program imports.")
    return user


class ProgramImportUploadView(APIView):
    """POST /program-imports/upload/ — Upload CSV and create a draft."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        trainer = _require_trainer(request)
        ser = UploadCSVSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        result = parse_csv_and_create_draft(
            trainer=trainer,
            csv_content=ser.validated_data['csv_content'],
            plan_name=ser.validated_data.get('plan_name', ''),
            goal=ser.validated_data.get('goal', 'strength'),
            trainee_id=ser.validated_data.get('trainee_id'),
        )

        return Response(
            {
                'draft_id': result.draft_id,
                'status': result.status,
                'total_weeks': result.total_weeks,
                'total_sessions': result.total_sessions,
                'total_slots': result.total_slots,
                'errors': result.errors,
                'warnings': result.warnings,
                'parsed_preview': result.parsed_preview,
            },
            status=status.HTTP_201_CREATED,
        )


class ProgramImportListView(APIView):
    """GET /program-imports/ — List recent drafts."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        trainer = _require_trainer(request)
        limit = min(int(request.query_params.get('limit', '20')), 100)
        drafts = list_drafts(trainer=trainer, limit=limit)
        ser = DraftListItemSerializer(drafts, many=True)
        return Response(ser.data)


class ProgramImportDetailView(APIView):
    """GET /program-imports/{draft_id}/ — Get draft details for review."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, draft_id: str) -> Response:
        trainer = _require_trainer(request)
        try:
            draft = get_draft(draft_id=draft_id, trainer=trainer)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_404_NOT_FOUND,
            )
        ser = DraftSummarySerializer(draft)
        return Response(ser.data)

    def delete(self, request: Request, draft_id: str) -> Response:
        """DELETE /program-imports/{draft_id}/ — Reject/discard a draft."""
        trainer = _require_trainer(request)
        try:
            reject_draft(draft_id=draft_id, trainer=trainer)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProgramImportConfirmView(APIView):
    """POST /program-imports/{draft_id}/confirm/ — Execute the import."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, draft_id: str) -> Response:
        trainer = _require_trainer(request)
        try:
            result = confirm_import(draft_id=draft_id, trainer=trainer)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            {
                'draft_id': result.draft_id,
                'training_plan_id': result.training_plan_id,
                'weeks_created': result.weeks_created,
                'sessions_created': result.sessions_created,
                'slots_created': result.slots_created,
            },
            status=status.HTTP_201_CREATED,
        )

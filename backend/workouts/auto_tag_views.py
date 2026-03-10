"""
Views for exercise auto-tagging pipeline — v6.5 Step 13.

Draft/edit/retry workflow:
- POST /exercises/{id}/auto-tag/ — Request AI tagging
- GET /exercises/{id}/auto-tag-draft/ — Get current draft
- PATCH /exercises/{id}/auto-tag-draft/ — Edit draft
- POST /exercises/{id}/auto-tag-draft/apply/ — Apply draft to exercise
- POST /exercises/{id}/auto-tag-draft/reject/ — Reject draft
- POST /exercises/{id}/auto-tag-draft/retry/ — Retry AI
- GET /exercises/{id}/tag-history/ — Version history
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import User
from .models import ExerciseTagDraft
from .services.auto_tagging_service import (
    apply_draft,
    get_current_draft,
    get_tag_history,
    reject_draft,
    request_auto_tag,
    retry_auto_tag,
    update_draft,
)


# ---------------------------------------------------------------------------
# Serializers
# ---------------------------------------------------------------------------

class TagDraftSerializer(serializers.Serializer):
    """Read-only serializer for tag draft."""
    id = serializers.UUIDField(source='pk')
    exercise_id = serializers.IntegerField()
    status = serializers.CharField()
    pattern_tags = serializers.ListField(child=serializers.CharField())
    athletic_skill_tags = serializers.ListField(child=serializers.CharField())
    athletic_attribute_tags = serializers.ListField(child=serializers.CharField())
    primary_muscle_group = serializers.CharField(allow_blank=True)
    secondary_muscle_groups = serializers.ListField(child=serializers.CharField())
    muscle_contribution_map = serializers.JSONField()
    stance = serializers.CharField(allow_blank=True)
    plane = serializers.CharField(allow_blank=True)
    rom_bias = serializers.CharField(allow_blank=True)
    equipment_required = serializers.ListField(child=serializers.CharField())
    equipment_optional = serializers.ListField(child=serializers.CharField())
    confidence_scores = serializers.JSONField()
    ai_reasoning = serializers.JSONField()
    retry_count = serializers.IntegerField()
    exercise_version_at_creation = serializers.IntegerField()
    created_at = serializers.DateTimeField()
    applied_at = serializers.DateTimeField(allow_null=True)


class TagDraftUpdateSerializer(serializers.Serializer):
    """Input serializer for editing a draft."""
    pattern_tags = serializers.ListField(
        child=serializers.CharField(), required=False,
    )
    athletic_skill_tags = serializers.ListField(
        child=serializers.CharField(), required=False,
    )
    athletic_attribute_tags = serializers.ListField(
        child=serializers.CharField(), required=False,
    )
    primary_muscle_group = serializers.CharField(required=False, allow_blank=True)
    secondary_muscle_groups = serializers.ListField(
        child=serializers.CharField(), required=False,
    )
    muscle_contribution_map = serializers.JSONField(required=False)
    stance = serializers.CharField(required=False, allow_blank=True)
    plane = serializers.CharField(required=False, allow_blank=True)
    rom_bias = serializers.CharField(required=False, allow_blank=True)
    equipment_required = serializers.ListField(
        child=serializers.CharField(), required=False,
    )
    equipment_optional = serializers.ListField(
        child=serializers.CharField(), required=False,
    )


class TagHistoryItemSerializer(serializers.Serializer):
    """Lightweight serializer for tag history."""
    id = serializers.UUIDField(source='pk')
    status = serializers.CharField()
    retry_count = serializers.IntegerField()
    confidence_scores = serializers.JSONField()
    requested_by_email = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField()
    applied_at = serializers.DateTimeField(allow_null=True)

    def get_requested_by_email(self, obj: ExerciseTagDraft) -> str:
        return obj.requested_by.email if obj.requested_by else ''


# ---------------------------------------------------------------------------
# Permission helper
# ---------------------------------------------------------------------------

def _require_trainer_or_admin(request: Request) -> User:
    """Verify user is trainer or admin."""
    user = request.user
    if user.role not in ('TRAINER', 'ADMIN'):
        raise PermissionDenied("Only trainers and admins can manage exercise tags.")
    return user


# ---------------------------------------------------------------------------
# Views
# ---------------------------------------------------------------------------

class RequestAutoTagView(APIView):
    """POST /exercises/{exercise_id}/auto-tag/ — Request AI auto-tagging."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        try:
            result = request_auto_tag(exercise_id=exercise_id, user=user)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            {
                'draft_id': result.draft_id,
                'exercise_id': result.exercise_id,
                'status': result.status,
                'confidence_scores': result.confidence_scores,
                'retry_count': result.retry_count,
            },
            status=status.HTTP_201_CREATED,
        )


class AutoTagDraftView(APIView):
    """
    GET /exercises/{exercise_id}/auto-tag-draft/ — Get current draft.
    PATCH /exercises/{exercise_id}/auto-tag-draft/ — Edit draft.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        draft = get_current_draft(exercise_id=exercise_id, user=user)
        if draft is None:
            return Response(
                {'detail': 'No active draft for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        ser = TagDraftSerializer(draft)
        return Response(ser.data)

    def patch(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        draft = get_current_draft(exercise_id=exercise_id, user=user)
        if draft is None:
            return Response(
                {'detail': 'No active draft for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        ser = TagDraftUpdateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        try:
            updated = update_draft(
                draft_id=str(draft.pk),
                user=user,
                updates=ser.validated_data,
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(TagDraftSerializer(updated).data)


class ApplyDraftView(APIView):
    """POST /exercises/{exercise_id}/auto-tag-draft/apply/ — Apply draft."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        draft = get_current_draft(exercise_id=exercise_id, user=user)
        if draft is None:
            return Response(
                {'detail': 'No active draft for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            result = apply_draft(draft_id=str(draft.pk), user=user)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response({
            'draft_id': result.draft_id,
            'exercise_id': result.exercise_id,
            'new_version': result.new_version,
            'fields_updated': result.fields_updated,
        })


class RejectDraftView(APIView):
    """POST /exercises/{exercise_id}/auto-tag-draft/reject/ — Reject draft."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        draft = get_current_draft(exercise_id=exercise_id, user=user)
        if draft is None:
            return Response(
                {'detail': 'No active draft for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            reject_draft(draft_id=str(draft.pk), user=user)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)


class RetryDraftView(APIView):
    """POST /exercises/{exercise_id}/auto-tag-draft/retry/ — Retry AI tagging."""
    permission_classes = [IsAuthenticated]

    def post(self, request: Request, exercise_id: int) -> Response:
        user = _require_trainer_or_admin(request)
        draft = get_current_draft(exercise_id=exercise_id, user=user)
        if draft is None:
            return Response(
                {'detail': 'No active draft for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            result = retry_auto_tag(draft_id=str(draft.pk), user=user)
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            {
                'draft_id': result.draft_id,
                'exercise_id': result.exercise_id,
                'status': result.status,
                'confidence_scores': result.confidence_scores,
                'retry_count': result.retry_count,
            },
            status=status.HTTP_201_CREATED,
        )


class TagHistoryView(APIView):
    """GET /exercises/{exercise_id}/tag-history/ — Tag version history."""
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, exercise_id: int) -> Response:
        _require_trainer_or_admin(request)
        try:
            limit = min(int(request.query_params.get('limit', '20')), 100)
        except (ValueError, TypeError):
            limit = 20
        history = get_tag_history(exercise_id=exercise_id, limit=limit)
        ser = TagHistoryItemSerializer(history, many=True)
        return Response(ser.data)

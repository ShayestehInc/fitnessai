"""
Audit trail + comprehensive export views — v6.5 Step 16.

Audit:
  GET /audit/summary/   — Decision counts by type/actor, recent activity
  GET /audit/timeline/  — Paginated timeline of recent decisions

Exports:
  GET /export/decision-logs/                — CSV of decision log entries
  GET /export/trainee/{id}/workout-history/ — CSV of workout sets
  GET /export/trainee/{id}/nutrition-history/ — CSV of daily nutrition
  GET /export/trainee/{id}/progress/        — CSV of weight + e1RM history
"""
from __future__ import annotations

from dataclasses import asdict

from django.http import HttpResponse
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsTrainer
from trainer.services.audit_export_service import (
    export_decision_logs_csv,
    export_trainee_nutrition_csv,
    export_trainee_progress_csv,
    export_trainee_workout_csv,
)
from trainer.services.audit_service import (
    get_audit_summary,
    get_audit_timeline,
)


def _parse_int(request: Request, param: str, default: int) -> int:
    """Parse an integer query parameter with fallback."""
    raw = request.query_params.get(param, str(default))
    try:
        return int(raw)
    except (ValueError, TypeError):
        return default


def _csv_response(content: str, filename: str) -> HttpResponse:
    """Build an HttpResponse for a CSV file download."""
    response = HttpResponse(content, content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    response['Cache-Control'] = 'no-store'
    return response


# ---------------------------------------------------------------------------
# Audit endpoints
# ---------------------------------------------------------------------------

class AuditSummaryView(APIView):
    """GET /audit/summary/ — Aggregate audit trail statistics."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        days = _parse_int(request, 'days', 30)
        summary = get_audit_summary(trainer=request.user, days=days)
        return Response({
            'total_decisions': summary.total_decisions,
            'recent_decisions_7d': summary.recent_decisions_7d,
            'by_type': [asdict(t) for t in summary.by_type],
            'by_actor': [asdict(a) for a in summary.by_actor],
            'reverted_count': summary.reverted_count,
            'period_days': summary.period_days,
        }, status=status.HTTP_200_OK)


class AuditTimelineView(APIView):
    """GET /audit/timeline/ — Paginated timeline of recent decisions."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        days = _parse_int(request, 'days', 30)
        limit = _parse_int(request, 'limit', 50)
        offset = _parse_int(request, 'offset', 0)
        entries = get_audit_timeline(
            trainer=request.user,
            days=days,
            limit=limit,
            offset=offset,
        )
        return Response({
            'count': len(entries),
            'entries': [asdict(e) for e in entries],
        }, status=status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# Export endpoints
# ---------------------------------------------------------------------------

class DecisionLogExportView(APIView):
    """GET /export/decision-logs/ — CSV export of decision log entries."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> HttpResponse:
        days = _parse_int(request, 'days', 30)
        result = export_decision_logs_csv(request.user, days)
        return _csv_response(result.content, result.filename)


class TraineeWorkoutExportView(APIView):
    """GET /export/trainee/{id}/workout-history/ — CSV of workout sets."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, trainee_id: int) -> HttpResponse | Response:
        days = _parse_int(request, 'days', 90)
        try:
            result = export_trainee_workout_csv(request.user, trainee_id, days)
        except ValueError as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_404_NOT_FOUND,
            )
        return _csv_response(result.content, result.filename)


class TraineeNutritionExportView(APIView):
    """GET /export/trainee/{id}/nutrition-history/ — CSV of daily nutrition."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, trainee_id: int) -> HttpResponse | Response:
        days = _parse_int(request, 'days', 90)
        try:
            result = export_trainee_nutrition_csv(request.user, trainee_id, days)
        except ValueError as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_404_NOT_FOUND,
            )
        return _csv_response(result.content, result.filename)


class TraineeProgressExportView(APIView):
    """GET /export/trainee/{id}/progress/ — CSV of weight + e1RM history."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, trainee_id: int) -> HttpResponse | Response:
        days = _parse_int(request, 'days', 180)
        try:
            result = export_trainee_progress_csv(request.user, trainee_id, days)
        except ValueError as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_404_NOT_FOUND,
            )
        return _csv_response(result.content, result.filename)

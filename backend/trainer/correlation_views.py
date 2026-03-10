"""
Correlation Analytics views — v6.5 Step 15.

GET /analytics/correlations/          — Overview correlations for trainer's trainees
GET /analytics/trainee/{id}/patterns/ — Per-trainee insights
GET /analytics/cohort/                — Cohort comparison (high vs low adherence)
"""
from __future__ import annotations

from dataclasses import asdict

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsTrainer
from trainer.services.correlation_analytics_service import (
    get_cohort_analysis,
    get_correlation_overview,
    get_trainee_patterns,
)


def _parse_days(request: Request, default: int = 30) -> int:
    """Parse and validate the 'days' query parameter."""
    raw = request.query_params.get('days', str(default))
    try:
        return int(raw)
    except (ValueError, TypeError):
        return default


class CorrelationOverviewView(APIView):
    """GET /analytics/correlations/ — Cross-metric correlations across all trainees."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        days = _parse_days(request)
        overview = get_correlation_overview(trainer=request.user, days=days)
        return Response({
            'period_days': overview.period_days,
            'correlations': [asdict(c) for c in overview.correlations],
            'insights': [asdict(i) for i in overview.insights],
            'cohort_comparisons': [asdict(cc) for cc in overview.cohort_comparisons],
        }, status=status.HTTP_200_OK)


class TraineePatternsView(APIView):
    """GET /analytics/trainee/{id}/patterns/ — Per-trainee insights and progressions."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, trainee_id: int) -> Response:
        days = _parse_days(request)
        try:
            patterns = get_trainee_patterns(
                trainer=request.user,
                trainee_id=trainee_id,
                days=days,
            )
        except ValueError as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({
            'trainee_id': patterns.trainee_id,
            'trainee_name': patterns.trainee_name,
            'period_days': patterns.period_days,
            'insights': [asdict(i) for i in patterns.insights],
            'exercise_progressions': [asdict(p) for p in patterns.exercise_progressions],
            'adherence_stats': patterns.adherence_stats,
        }, status=status.HTTP_200_OK)


class CohortAnalysisView(APIView):
    """GET /analytics/cohort/ — Cohort comparison (high vs low adherence)."""

    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        days = _parse_days(request)
        raw_threshold = request.query_params.get('threshold', '70')
        try:
            threshold = float(raw_threshold)
        except (ValueError, TypeError):
            threshold = 70.0

        comparisons = get_cohort_analysis(
            trainer=request.user,
            days=days,
            threshold=threshold,
        )
        return Response({
            'period_days': days,
            'threshold': threshold,
            'comparisons': [asdict(c) for c in comparisons],
        }, status=status.HTTP_200_OK)

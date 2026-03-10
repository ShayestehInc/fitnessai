"""
Views for Active Session endpoints — v6.5 Step 8.

Separate file to keep the main views.py clean.
"""
from __future__ import annotations

import logging
from dataclasses import asdict
from typing import Any

from django.db.models import QuerySet
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.serializers import BaseSerializer

from .models import ActiveSession, ActiveSetLog
from .session_serializers import (
    AbandonSessionInputSerializer,
    ActiveSessionListSerializer,
    ActiveSessionSerializer,
    LogSetInputSerializer,
    SessionStatusResponseSerializer,
    SessionSummaryResponseSerializer,
    SkipSetInputSerializer,
    StartSessionInputSerializer,
)
from .services.session_runner_service import (
    SessionError,
    SessionStatus,
    SessionSummary,
    abandon_session,
    complete_session,
    get_active_session,
    get_session_status,
    log_set,
    skip_set,
    start_session,
)

logger = logging.getLogger(__name__)


def _session_status_response(session_status: SessionStatus) -> Response:
    """Serialize a SessionStatus dataclass to a Response."""
    serializer = SessionStatusResponseSerializer(asdict(session_status))
    return Response(serializer.data, status=status.HTTP_200_OK)


def _session_summary_response(
    summary: SessionSummary,
    http_status: int = status.HTTP_200_OK,
) -> Response:
    """Serialize a SessionSummary dataclass to a Response."""
    serializer = SessionSummaryResponseSerializer(asdict(summary))
    return Response(serializer.data, status=http_status)


def _error_response(error: SessionError, http_status: int) -> Response:
    """Build a structured error response from a SessionError."""
    data: dict[str, Any] = {
        'error': error.error_code,
        'message': error.message,
    }
    data.update(error.extra)
    return Response(data, status=http_status)


# Map error codes to HTTP status codes
_ERROR_STATUS_MAP: dict[str, int] = {
    'active_session_exists': status.HTTP_409_CONFLICT,
    'plan_session_not_found': status.HTTP_404_NOT_FOUND,
    'no_exercises_in_session': status.HTTP_400_BAD_REQUEST,
    'session_already_completed': status.HTTP_400_BAD_REQUEST,
    'session_already_abandoned': status.HTTP_400_BAD_REQUEST,
    'session_not_started': status.HTTP_400_BAD_REQUEST,
    'set_not_found': status.HTTP_404_NOT_FOUND,
    'set_already_logged': status.HTTP_400_BAD_REQUEST,
    'no_pending_sets': status.HTTP_400_BAD_REQUEST,
    'pending_sets_remaining': status.HTTP_400_BAD_REQUEST,
}


class ActiveSessionPagination(PageNumberPagination):
    page_size = 20
    max_page_size = 100


class ActiveSessionViewSet(viewsets.GenericViewSet[ActiveSession]):
    """
    ViewSet for managing active workout sessions.

    Endpoints:
      - GET  /sessions/            — list trainee's sessions
      - GET  /sessions/{id}/       — full session detail
      - POST /sessions/start/      — start a new session
      - POST /sessions/{id}/log-set/  — log a completed set
      - POST /sessions/{id}/skip-set/ — skip a set
      - POST /sessions/{id}/complete/ — complete the session
      - POST /sessions/{id}/abandon/  — abandon the session
      - GET  /sessions/active/     — get current active session
    """
    permission_classes = [IsAuthenticated]
    pagination_class = ActiveSessionPagination
    lookup_field = 'pk'

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            return ActiveSessionListSerializer
        return ActiveSessionSerializer

    def get_queryset(self) -> QuerySet[ActiveSession]:
        """Row-level security: trainees see own, trainers see their trainees', admin sees all."""
        user = self.request.user
        qs = ActiveSession.objects.select_related(
            'plan_session',
            'trainee',
        ).prefetch_related(
            'set_logs__plan_slot',
            'set_logs__exercise',
        )

        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(trainee__parent_trainer=user)
        else:
            # TRAINEE — only own sessions
            return qs.filter(trainee=user)

    def list(self, request: Request) -> Response:
        """GET /sessions/ — list trainee's sessions with optional status filter."""
        qs = self.get_queryset()

        status_filter = request.query_params.get('status')
        if status_filter:
            valid_statuses = {choice[0] for choice in ActiveSession.Status.choices}
            if status_filter not in valid_statuses:
                return Response(
                    {
                        'error': 'invalid_status',
                        'message': f'Invalid status filter. Must be one of: {", ".join(sorted(valid_statuses))}',
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )
            qs = qs.filter(status=status_filter)

        qs = qs.order_by('-created_at')
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = ActiveSessionListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = ActiveSessionListSerializer(qs, many=True)
        return Response(serializer.data)

    def retrieve(self, request: Request, pk: str | None = None) -> Response:
        """GET /sessions/{id}/ — full session status via service layer."""
        session = self.get_object()
        try:
            session_status = get_session_status(str(session.pk))
            return _session_status_response(session_status)
        except ActiveSession.DoesNotExist:
            return Response(
                {'error': 'session_not_found', 'message': 'Session not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

    @action(detail=False, methods=['post'], url_path='start')
    def start(self, request: Request) -> Response:
        """POST /sessions/start/ — start a new workout session."""
        serializer = StartSessionInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        trainee = self._resolve_trainee(request)

        try:
            session_status = start_session(
                trainee_id=trainee.pk,
                plan_session_id=str(serializer.validated_data['plan_session_id']),
            )
            return _session_status_response(session_status)
        except SessionError as e:
            http_code = _ERROR_STATUS_MAP.get(e.error_code, status.HTTP_400_BAD_REQUEST)
            return _error_response(e, http_code)

    @action(detail=True, methods=['post'], url_path='log-set')
    def log_set_action(self, request: Request, pk: str | None = None) -> Response:
        """POST /sessions/{id}/log-set/ — log a completed set."""
        session = self.get_object()
        serializer = LogSetInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        try:
            session_status = log_set(
                active_session_id=str(session.pk),
                slot_id=str(data['slot_id']),
                set_number=data['set_number'],
                completed_reps=data['completed_reps'],
                load_value=data.get('load_value'),
                load_unit=data.get('load_unit', 'lb'),
                rpe=data.get('rpe'),
                rest_actual_seconds=data.get('rest_actual_seconds'),
                notes=data.get('notes', ''),
            )
            return _session_status_response(session_status)
        except SessionError as e:
            http_code = _ERROR_STATUS_MAP.get(e.error_code, status.HTTP_400_BAD_REQUEST)
            return _error_response(e, http_code)

    @action(detail=True, methods=['post'], url_path='skip-set')
    def skip_set_action(self, request: Request, pk: str | None = None) -> Response:
        """POST /sessions/{id}/skip-set/ — skip a set."""
        session = self.get_object()
        serializer = SkipSetInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        try:
            session_status = skip_set(
                active_session_id=str(session.pk),
                slot_id=str(data['slot_id']),
                set_number=data['set_number'],
                reason=data.get('reason', ''),
            )
            return _session_status_response(session_status)
        except SessionError as e:
            http_code = _ERROR_STATUS_MAP.get(e.error_code, status.HTTP_400_BAD_REQUEST)
            return _error_response(e, http_code)

    @action(detail=True, methods=['post'], url_path='complete')
    def complete(self, request: Request, pk: str | None = None) -> Response:
        """POST /sessions/{id}/complete/ — complete the session."""
        session = self.get_object()
        actor = self._resolve_trainee(request)

        try:
            summary = complete_session(
                active_session_id=str(session.pk),
                actor_id=actor.pk,
            )
            return _session_summary_response(summary)
        except SessionError as e:
            http_code = _ERROR_STATUS_MAP.get(e.error_code, status.HTTP_400_BAD_REQUEST)
            return _error_response(e, http_code)

    @action(detail=True, methods=['post'], url_path='abandon')
    def abandon(self, request: Request, pk: str | None = None) -> Response:
        """POST /sessions/{id}/abandon/ — abandon the session."""
        session = self.get_object()
        serializer = AbandonSessionInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        actor = self._resolve_trainee(request)
        try:
            summary = abandon_session(
                active_session_id=str(session.pk),
                actor_id=actor.pk,
                reason=serializer.validated_data.get('reason', ''),
            )
            return _session_summary_response(summary)
        except SessionError as e:
            http_code = _ERROR_STATUS_MAP.get(e.error_code, status.HTTP_400_BAD_REQUEST)
            return _error_response(e, http_code)

    @action(detail=False, methods=['get'], url_path='active')
    def active(self, request: Request) -> Response:
        """GET /sessions/active/ — get trainee's active session or 404."""
        trainee = self._resolve_trainee(request)
        session_status = get_active_session(trainee_id=trainee.pk)
        if session_status is None:
            return Response(
                {'error': 'no_active_session', 'message': 'No active session found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        return _session_status_response(session_status)

    def _resolve_trainee(self, request: Request) -> Any:
        """
        Resolve the effective trainee for the request.

        Enforces trainee-only access (C2 fix):
        - Impersonation swaps request.user to the trainee via JWT, so
          request.user.role == 'TRAINEE' when impersonating.
        - Non-impersonating trainers/admins get 403.
        """
        user = request.user
        if user.role != 'TRAINEE':
            raise PermissionDenied(
                'Only trainees can access session endpoints. '
                'Use impersonation to act on behalf of a trainee.'
            )
        return user

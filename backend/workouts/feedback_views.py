"""
Views for session feedback, pain events, and trainer routing rules (v6.5 Step 9).
"""
from __future__ import annotations

from typing import Any, cast

from django.db.models import Q, QuerySet
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.serializers import BaseSerializer

from users.models import User
from .models import (
    ActiveSession,
    PainEvent,
    SessionFeedback,
    TrainerRoutingRule,
)
from .feedback_serializers import (
    PainEventInputSerializer,
    PainEventSerializer,
    SessionFeedbackSerializer,
    SubmitFeedbackInputSerializer,
    TrainerRoutingRuleListSerializer,
    TrainerRoutingRuleSerializer,
)
from .services.feedback_service import (
    DEFAULT_ROUTING_RULES,
    create_default_routing_rules,
    get_feedback_history,
    get_pain_history,
    log_pain_event,
    submit_feedback,
)


class FeedbackPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------------------------------------------------------
# Session Feedback ViewSet
# ---------------------------------------------------------------------------

class SessionFeedbackViewSet(
    viewsets.GenericViewSet[SessionFeedback],
    viewsets.mixins.ListModelMixin,
):
    """
    Submit and view session feedback.
    Trainees see only their own. Trainers see their trainees'. Admin sees all.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = SessionFeedbackSerializer
    pagination_class = FeedbackPagination

    def get_queryset(self) -> QuerySet[SessionFeedback]:
        user = cast(User, self.request.user)
        qs = SessionFeedback.objects.select_related('active_session', 'trainee')
        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(trainee__parent_trainer=user)
        else:
            return qs.filter(trainee=user)

    @action(detail=False, methods=['post'], url_path='submit/(?P<session_pk>[^/.]+)')
    def submit(self, request: Request, session_pk: str | None = None) -> Response:
        """Submit feedback for a completed/abandoned session."""
        user = cast(User, request.user)

        # Only trainees can submit feedback
        if user.role != 'TRAINEE':
            raise PermissionDenied("Only trainees can submit session feedback.")

        # Get active session with ownership check
        try:
            active_session = (
                ActiveSession.objects
                .select_related('plan_session__week__plan__trainee')
                .get(pk=session_pk, trainee=user)
            )
        except ActiveSession.DoesNotExist:
            return Response(
                {'detail': 'Session not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Session must be completed or abandoned
        if active_session.status not in ('completed', 'abandoned'):
            return Response(
                {'detail': 'Feedback can only be submitted for completed or abandoned sessions.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check for existing feedback
        if hasattr(active_session, 'feedback'):
            try:
                active_session.feedback  # noqa: B018 — access to trigger DoesNotExist
                return Response(
                    {'detail': 'Feedback already submitted for this session.'},
                    status=status.HTTP_409_CONFLICT,
                )
            except SessionFeedback.DoesNotExist:
                pass

        serializer = SubmitFeedbackInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        result = submit_feedback(
            active_session=active_session,
            trainee=user,
            completion_state=data['completion_state'],
            ratings=data.get('ratings', {}),
            friction_reasons=data.get('friction_reasons', []),
            recovery_concern=data.get('recovery_concern', False),
            notes=data.get('notes', ''),
            pain_events_data=data.get('pain_events', []),
            actor_id=user.pk,
        )

        return Response({
            'feedback_id': result.feedback_id,
            'active_session_id': result.active_session_id,
            'pain_events_created': result.pain_events_created,
            'triggered_rules': [
                {
                    'rule_id': r.rule_id,
                    'rule_type': r.rule_type,
                    'reason': r.reason,
                }
                for r in result.triggered_rules
            ],
        }, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='for-session/(?P<session_pk>[^/.]+)')
    def for_session(self, request: Request, session_pk: str | None = None) -> Response:
        """Get feedback for a specific session."""
        user = cast(User, request.user)

        # Build ownership filter
        qs = SessionFeedback.objects.select_related('active_session', 'trainee')
        if user.role == 'TRAINEE':
            qs = qs.filter(trainee=user)
        elif user.role == 'TRAINER':
            qs = qs.filter(trainee__parent_trainer=user)

        try:
            feedback = qs.get(active_session_id=session_pk)
        except SessionFeedback.DoesNotExist:
            return Response(
                {'detail': 'Feedback not found for this session.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = SessionFeedbackSerializer(feedback)
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Pain Event ViewSet
# ---------------------------------------------------------------------------

class PainEventViewSet(
    viewsets.GenericViewSet[PainEvent],
    viewsets.mixins.ListModelMixin,
    viewsets.mixins.RetrieveModelMixin,
):
    """
    Log and view pain events.
    Trainees see only their own. Trainers see their trainees'. Admin sees all.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = PainEventSerializer
    pagination_class = FeedbackPagination

    def get_queryset(self) -> QuerySet[PainEvent]:
        user = cast(User, self.request.user)
        qs = PainEvent.objects.select_related('exercise', 'active_session')
        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(trainee__parent_trainer=user)
        else:
            return qs.filter(trainee=user)

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """List pain events with optional body_region filter."""
        body_region = request.query_params.get('body_region')
        queryset = self.get_queryset()
        if body_region:
            valid_regions = {c[0] for c in PainEvent.BodyRegion.choices}
            if body_region not in valid_regions:
                return Response(
                    {'detail': f"Invalid body_region: '{body_region}'."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            queryset = queryset.filter(body_region=body_region)
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='log')
    def log(self, request: Request) -> Response:
        """Log a standalone pain event."""
        user = cast(User, request.user)
        if user.role != 'TRAINEE':
            raise PermissionDenied("Only trainees can log pain events.")

        serializer = PainEventInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        result = log_pain_event(
            trainee=user,
            body_region=data['body_region'],
            pain_score=data['pain_score'],
            side=data.get('side', 'midline'),
            sensation_type=data.get('sensation_type', 'other'),
            onset_phase=data.get('onset_phase', ''),
            warmup_effect=data.get('warmup_effect', ''),
            active_session_id=data.get('active_session_id'),
            exercise_id=data.get('exercise_id'),
            notes=data.get('notes', ''),
        )

        return Response({
            'pain_event_id': result.pain_event_id,
            'body_region': result.body_region,
            'pain_score': result.pain_score,
            'triggered_rules': [
                {
                    'rule_id': r.rule_id,
                    'rule_type': r.rule_type,
                    'reason': r.reason,
                }
                for r in result.triggered_rules
            ],
        }, status=status.HTTP_201_CREATED)


# ---------------------------------------------------------------------------
# Trainer Routing Rule ViewSet
# ---------------------------------------------------------------------------

class TrainerRoutingRuleViewSet(viewsets.ModelViewSet[TrainerRoutingRule]):
    """
    CRUD for trainer routing rules.
    Trainers see only their own rules. Admin sees all.
    Trainees have no access.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            return TrainerRoutingRuleListSerializer
        return TrainerRoutingRuleSerializer

    def get_queryset(self) -> QuerySet[TrainerRoutingRule]:
        user = cast(User, self.request.user)
        if user.role == 'ADMIN':
            return TrainerRoutingRule.objects.all()
        elif user.role == 'TRAINER':
            return TrainerRoutingRule.objects.filter(trainer=user)
        else:
            raise PermissionDenied("Trainees cannot access routing rules.")

    def perform_create(self, serializer: BaseSerializer[Any]) -> None:
        user = cast(User, self.request.user)
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot create routing rules.")
        serializer.save(trainer=user)

    def perform_update(self, serializer: BaseSerializer[Any]) -> None:
        user = cast(User, self.request.user)
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot modify routing rules.")
        instance = serializer.instance
        if instance and instance.trainer_id != user.pk and user.role != 'ADMIN':
            raise PermissionDenied("Cannot modify another trainer's rules.")
        serializer.save()

    def perform_destroy(self, instance: TrainerRoutingRule) -> None:
        user = cast(User, self.request.user)
        if instance.trainer_id != user.pk and user.role != 'ADMIN':
            raise PermissionDenied("Cannot delete another trainer's rules.")
        instance.delete()

    @action(detail=False, methods=['get'])
    def defaults(self, request: Request) -> Response:
        """Get default routing rule templates."""
        return Response(DEFAULT_ROUTING_RULES)

    @action(detail=False, methods=['post'], url_path='initialize')
    def initialize(self, request: Request) -> Response:
        """Create default routing rules for the current trainer."""
        user = cast(User, request.user)
        if user.role != 'TRAINER':
            raise PermissionDenied("Only trainers can initialize routing rules.")

        created = create_default_routing_rules(trainer=user)
        serializer = TrainerRoutingRuleSerializer(created, many=True)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

"""
Views for daily digest and message drafting — v6.5 Step 11.
"""
from __future__ import annotations

import datetime
from typing import cast

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import User
from .models import DailyDigest, DigestPreference
from .services.daily_digest_service import (
    draft_trainee_message,
    generate_daily_digest,
    get_digest_history,
    get_or_create_digest_preference,
    mark_digest_read,
    update_digest_preference,
)


class _TrainerOnlyMixin:
    """Ensures only trainers can access these views."""

    def check_trainer(self, request: Request) -> User | Response:
        user = cast(User, request.user)
        if user.role != 'TRAINER':
            return Response(
                {'detail': 'Only trainers can access digests.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return user


class DigestGenerateView(_TrainerOnlyMixin, APIView):
    """POST /api/trainer/ai/daily-digest/generate/

    Generate today's digest (or a specific date's digest).
    Body: {"date": "2026-03-10"} (optional, defaults to yesterday)
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        date_str = request.data.get('date')
        if date_str:
            try:
                target_date = datetime.date.fromisoformat(str(date_str))
            except ValueError:
                return Response(
                    {'detail': 'Invalid date format. Use YYYY-MM-DD.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            target_date = datetime.date.today() - datetime.timedelta(days=1)

        digest_result = generate_daily_digest(
            trainer=trainer,
            target_date=target_date,
        )

        return Response({
            'digest_id': digest_result.digest_id,
            'date': digest_result.date,
            'summary_text': digest_result.summary_text,
            'metrics': {
                'total_trainees': digest_result.metrics.total_trainees,
                'active_trainees': digest_result.metrics.active_trainees,
                'workouts_completed': digest_result.metrics.workouts_completed,
                'workouts_missed': digest_result.metrics.workouts_missed,
                'pain_reports': digest_result.metrics.pain_reports,
                'avg_compliance_pct': digest_result.metrics.avg_compliance_pct,
            },
            'highlights': digest_result.metrics.highlights,
            'concerns': digest_result.metrics.concerns,
            'action_items': digest_result.metrics.action_items,
        }, status=status.HTTP_201_CREATED)


class DigestHistoryView(_TrainerOnlyMixin, APIView):
    """GET /api/trainer/ai/daily-digest/history/

    Get past digests.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        try:
            limit = int(request.query_params.get('limit', '30'))
        except ValueError:
            limit = 30
        limit = min(max(limit, 1), 90)

        digests = get_digest_history(trainer, limit=limit)
        data = [
            {
                'digest_id': str(d.pk),
                'date': str(d.date),
                'total_trainees': d.total_trainees,
                'active_trainees': d.active_trainees,
                'workouts_completed': d.workouts_completed,
                'workouts_missed': d.workouts_missed,
                'pain_reports': d.pain_reports,
                'avg_compliance_pct': d.avg_compliance_pct,
                'summary_text': d.summary_text,
                'highlights': d.highlights,
                'concerns': d.concerns,
                'action_items': d.action_items,
                'read_at': d.read_at.isoformat() if d.read_at else None,
                'created_at': d.created_at.isoformat(),
            }
            for d in digests
        ]
        return Response(data)


class DigestDetailView(_TrainerOnlyMixin, APIView):
    """GET /api/trainer/ai/daily-digest/<digest_id>/

    Get a specific digest and mark as read.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request, digest_id: str) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        try:
            digest = DailyDigest.objects.get(pk=digest_id, trainer=trainer)
        except DailyDigest.DoesNotExist:
            return Response(
                {'detail': 'Digest not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Mark as read on access
        if not digest.read_at:
            mark_digest_read(str(digest.pk))
            digest.refresh_from_db()

        return Response({
            'digest_id': str(digest.pk),
            'date': str(digest.date),
            'total_trainees': digest.total_trainees,
            'active_trainees': digest.active_trainees,
            'workouts_completed': digest.workouts_completed,
            'workouts_missed': digest.workouts_missed,
            'pain_reports': digest.pain_reports,
            'avg_compliance_pct': digest.avg_compliance_pct,
            'summary_text': digest.summary_text,
            'highlights': digest.highlights,
            'concerns': digest.concerns,
            'action_items': digest.action_items,
            'read_at': digest.read_at.isoformat() if digest.read_at else None,
        })


class DigestPreferenceView(_TrainerOnlyMixin, APIView):
    """GET/PATCH /api/trainer/ai/daily-digest/preferences/

    Manage digest delivery preferences.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        pref = get_or_create_digest_preference(trainer)
        return Response({
            'delivery_method': pref.delivery_method,
            'delivery_hour': pref.delivery_hour,
            'timezone': pref.timezone,
            'include_nutrition': pref.include_nutrition,
            'include_workouts': pref.include_workouts,
            'include_pain_reports': pref.include_pain_reports,
            'include_at_risk': pref.include_at_risk,
            'is_active': pref.is_active,
        })

    def patch(self, request: Request) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        pref = update_digest_preference(trainer, **request.data)
        return Response({
            'delivery_method': pref.delivery_method,
            'delivery_hour': pref.delivery_hour,
            'timezone': pref.timezone,
            'include_nutrition': pref.include_nutrition,
            'include_workouts': pref.include_workouts,
            'include_pain_reports': pref.include_pain_reports,
            'include_at_risk': pref.include_at_risk,
            'is_active': pref.is_active,
        })


class DraftMessageView(_TrainerOnlyMixin, APIView):
    """POST /api/trainer/ai/draft-message/

    Generate a draft message from trainer to trainee.
    Body: {"trainee_id": 123, "message_type": "encouragement", "context": "..."}
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        result = self.check_trainer(request)
        if isinstance(result, Response):
            return result
        trainer = result

        trainee_id = request.data.get('trainee_id')
        if not trainee_id:
            return Response(
                {'detail': 'trainee_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message_type = request.data.get('message_type', 'check_in')
        valid_types = {
            'encouragement', 'check_in', 'missed_workout',
            'pain_follow_up', 'goal_update',
        }
        if message_type not in valid_types:
            return Response(
                {'detail': f"Invalid message_type. Valid: {', '.join(sorted(valid_types))}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            trainee = User.objects.get(
                pk=trainee_id,
                role='TRAINEE',
                parent_trainer=trainer,
            )
        except User.DoesNotExist:
            return Response(
                {'detail': 'Trainee not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        context = request.data.get('context', '')
        draft = draft_trainee_message(
            trainer=trainer,
            trainee=trainee,
            message_type=message_type,
            context=str(context),
        )

        return Response({
            'trainee_id': trainee.pk,
            'message_type': message_type,
            'draft': draft,
        })

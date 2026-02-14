"""
Views for workout readiness and post-workout surveys.
Submits survey data, saves workout logs, and notifies trainers.
"""
from __future__ import annotations

import logging
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from typing import Any, cast

from users.models import User
from workouts.models import DailyLog
from trainer.models import TrainerNotification, WorkoutLayoutConfig

logger = logging.getLogger(__name__)


class ReadinessSurveyView(APIView):
    """
    Submit pre-workout readiness survey.
    This notifies the trainer about the trainee's readiness before starting a workout.

    POST /api/workouts/surveys/readiness/
    {
        "workout_name": "Push Day",
        "survey_data": {
            "sleep": 4,
            "mood": 5,
            "energy": 3,
            "stress": 3,
            "soreness": 2
        },
        "survey_type": "readiness"
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)

        workout_name = request.data.get('workout_name', 'Workout')
        survey_data = request.data.get('survey_data', {})

        # Calculate average readiness score
        scores = [
            survey_data.get('sleep', 0),
            survey_data.get('mood', 0),
            survey_data.get('energy', 0),
            survey_data.get('stress', 0),
            survey_data.get('soreness', 0),
        ]
        valid_scores = [s for s in scores if s > 0]
        avg_score = sum(valid_scores) / len(valid_scores) if valid_scores else 0

        # Get trainer to notify (parent_trainer FK on User model)
        trainer = user.parent_trainer

        if trainer is not None:
            self._notify_trainer(
                trainer=trainer,
                trainee=user,
                workout_name=workout_name,
                survey_data=survey_data,
                avg_score=avg_score,
            )

        return Response({
            'success': True,
            'message': 'Readiness survey submitted',
            'average_score': round(avg_score, 1),
        }, status=status.HTTP_201_CREATED)

    def _notify_trainer(
        self,
        trainer: User,
        trainee: User,
        workout_name: str,
        survey_data: dict[str, Any],
        avg_score: float,
    ) -> None:
        """
        Send notification to trainer about trainee's readiness.
        """
        # Get trainee display name
        trainee_name = trainee.get_full_name() or trainee.email.split('@')[0]

        # Determine readiness level
        if avg_score >= 4:
            readiness_level = "excellent"
            emoji = "🟢"
        elif avg_score >= 3:
            readiness_level = "good"
            emoji = "🟡"
        else:
            readiness_level = "low"
            emoji = "🔴"

        # Build notification message
        message = (
            f"{emoji} {trainee_name} is starting {workout_name}\n"
            f"Readiness: {readiness_level} ({avg_score:.1f}/5)\n"
        )

        # Add details for low readiness
        if avg_score < 3:
            low_areas = []
            if survey_data.get('sleep', 5) <= 2:
                low_areas.append("sleep")
            if survey_data.get('energy', 5) <= 2:
                low_areas.append("energy")
            if survey_data.get('mood', 5) <= 2:
                low_areas.append("mood")
            if survey_data.get('stress', 5) <= 2:
                low_areas.append("high stress")
            if survey_data.get('soreness', 5) <= 2:
                low_areas.append("soreness")

            if low_areas:
                message += f"Low areas: {', '.join(low_areas)}"

        try:
            TrainerNotification.objects.create(
                trainer=trainer,
                notification_type='trainee_readiness',
                title=f'{trainee_name} starting workout',
                message=message,
                data={
                    'trainee_id': trainee.id,
                    'trainee_name': trainee_name,
                    'workout_name': workout_name,
                    'readiness_score': avg_score,
                    'survey_data': survey_data,
                },
            )
        except Exception as e:
            logger.error(
                "Failed to create readiness notification for trainer %s: %s",
                trainer.id, e,
            )


class PostWorkoutSurveyView(APIView):
    """
    Submit post-workout survey with workout data.
    This notifies the trainer about how the workout went.

    POST /api/workouts/surveys/post-workout/
    {
        "workout_summary": {
            "workout_name": "Push Day",
            "duration": "45:30",
            "exercises": [...]
        },
        "survey_data": {
            "performance": 4,
            "intensity": 4,
            "energy_after": 3,
            "satisfaction": 5,
            "notes": "Shoulder felt tight"
        },
        "readiness_survey": {...},  // Optional
        "survey_type": "post_workout"
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)

        workout_summary = request.data.get('workout_summary', {})
        survey_data = request.data.get('survey_data', {})
        readiness_survey = request.data.get('readiness_survey')

        workout_name = workout_summary.get('workout_name', 'Workout')
        duration = workout_summary.get('duration', '00:00')
        exercises = workout_summary.get('exercises', [])

        # Calculate stats
        total_sets = sum(len(ex.get('sets', [])) for ex in exercises)
        completed_sets = sum(
            len([s for s in ex.get('sets', []) if s.get('completed')])
            for ex in exercises
        )
        completion_rate = (completed_sets / total_sets * 100) if total_sets > 0 else 100

        # Calculate average survey score
        scores = [
            survey_data.get('performance', 0),
            survey_data.get('intensity', 0),
            survey_data.get('energy_after', 0),
            survey_data.get('satisfaction', 0),
        ]
        valid_scores = [s for s in scores if s > 0]
        avg_score = sum(valid_scores) / len(valid_scores) if valid_scores else 0

        # Save workout data to DailyLog (BUG-1 fix)
        save_error: str | None = None
        try:
            self._save_workout_to_daily_log(
                user=user,
                workout_summary=workout_summary,
                survey_data=survey_data,
                readiness_survey=readiness_survey,
            )
        except Exception as e:
            logger.error(
                "Failed to save workout data for user %s: %s", user.id, e,
            )
            save_error = str(e)

        # Get trainer to notify (parent_trainer FK on User model)
        trainer = user.parent_trainer

        if trainer is not None:
            self._notify_trainer(
                trainer=trainer,
                trainee=user,
                workout_name=workout_name,
                duration=duration,
                completion_rate=completion_rate,
                completed_sets=completed_sets,
                total_sets=total_sets,
                survey_data=survey_data,
                avg_score=avg_score,
                readiness_survey=readiness_survey,
            )

        response_data: dict[str, Any] = {
            'success': True,
            'message': 'Post-workout survey submitted',
            'stats': {
                'completion_rate': round(completion_rate, 1),
                'completed_sets': completed_sets,
                'total_sets': total_sets,
                'average_score': round(avg_score, 1),
            },
        }
        if save_error is not None:
            response_data['warning'] = 'Workout survey saved but workout log persistence failed'

        return Response(response_data, status=status.HTTP_201_CREATED)

    def _save_workout_to_daily_log(
        self,
        user: User,
        workout_summary: dict[str, Any],
        survey_data: dict[str, Any],
        readiness_survey: dict[str, Any] | None,
    ) -> None:
        """
        Save workout data to DailyLog.workout_data.
        Uses get_or_create for today's date to avoid duplicates.
        Stores each workout session separately in a 'sessions' list so
        multiple workouts per day don't overwrite each other.
        Also maintains a flat 'exercises' list for backward compatibility.
        """
        from django.db import transaction

        today = timezone.now().date()

        with transaction.atomic():
            daily_log, _created = DailyLog.objects.get_or_create(
                trainee=user,
                date=today,
            )

            exercises = workout_summary.get('exercises', [])
            workout_name = workout_summary.get('workout_name', 'Workout')
            duration = workout_summary.get('duration', '00:00')
            completed_at = timezone.now().isoformat()

            new_session: dict[str, Any] = {
                'workout_name': workout_name,
                'duration': duration,
                'exercises': exercises,
                'post_survey': survey_data,
                'completed_at': completed_at,
            }
            if readiness_survey is not None:
                new_session['readiness_survey'] = readiness_survey

            existing_data: dict[str, Any] = daily_log.workout_data or {}
            existing_sessions: list[dict[str, Any]] = existing_data.get('sessions', [])
            existing_exercises: list[dict[str, Any]] = existing_data.get('exercises', [])

            # Append new session and merge exercises
            updated_sessions = existing_sessions + [new_session]
            merged_exercises = existing_exercises + exercises

            daily_log.workout_data = {
                'sessions': updated_sessions,
                'exercises': merged_exercises,
                'workout_name': workout_name,
                'duration': duration,
                'post_survey': survey_data,
                'completed_at': completed_at,
            }
            if readiness_survey is not None:
                daily_log.workout_data['readiness_survey'] = readiness_survey

            daily_log.save(update_fields=['workout_data'])

    def _notify_trainer(
        self,
        trainer: User,
        trainee: User,
        workout_name: str,
        duration: str,
        completion_rate: float,
        completed_sets: int,
        total_sets: int,
        survey_data: dict[str, Any],
        avg_score: float,
        readiness_survey: dict[str, Any] | None,
    ) -> None:
        """
        Send notification to trainer about completed workout.
        """
        trainee_name = trainee.get_full_name() or trainee.email.split('@')[0]

        # Determine overall rating
        if avg_score >= 4:
            rating = "Great"
            emoji = "🎉"
        elif avg_score >= 3:
            rating = "Good"
            emoji = "👍"
        else:
            rating = "Struggled"
            emoji = "💪"

        # Build notification message
        message = (
            f"{emoji} {trainee_name} completed {workout_name}!\n"
            f"Duration: {duration} | {completed_sets}/{total_sets} sets ({completion_rate:.0f}%)\n"
            f"Rating: {rating} ({avg_score:.1f}/5)"
        )

        # Add notes if provided
        notes = survey_data.get('notes', '').strip()
        if notes:
            message += f"\nNotes: \"{notes}\""

        # Flag concerns
        concerns = []
        if survey_data.get('intensity', 5) <= 2:
            concerns.append("workout too easy")
        if survey_data.get('intensity', 0) >= 5:
            concerns.append("workout very hard")
        if survey_data.get('energy_after', 5) <= 2:
            concerns.append("very drained")
        if survey_data.get('performance', 5) <= 2:
            concerns.append("struggled with exercises")

        if concerns:
            message += f"\n⚠️ {', '.join(concerns)}"

        try:
            TrainerNotification.objects.create(
                trainer=trainer,
                notification_type='workout_completed',
                title=f'{trainee_name} completed workout',
                message=message,
                data={
                    'trainee_id': trainee.id,
                    'trainee_name': trainee_name,
                    'workout_name': workout_name,
                    'duration': duration,
                    'completion_rate': completion_rate,
                    'completed_sets': completed_sets,
                    'total_sets': total_sets,
                    'survey_score': avg_score,
                    'survey_data': survey_data,
                    'readiness_survey': readiness_survey,
                    'notes': notes,
                },
            )
        except Exception as e:
            logger.error(
                "Failed to create post-workout notification for trainer %s: %s",
                trainer.id, e,
            )


class MyLayoutConfigView(APIView):
    """
    GET /api/workouts/my-layout/

    Returns the authenticated trainee's workout layout configuration.
    If no config exists, returns the default ('classic').
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)

        try:
            config = WorkoutLayoutConfig.objects.get(trainee=user)
            layout_type: str = config.layout_type
            config_options: dict[str, Any] = config.config_options or {}
        except WorkoutLayoutConfig.DoesNotExist:
            layout_type = WorkoutLayoutConfig.LayoutType.CLASSIC
            config_options = {}

        return Response({
            'layout_type': layout_type,
            'config_options': config_options,
        })

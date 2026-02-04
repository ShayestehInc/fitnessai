"""
Views for workout readiness and post-workout surveys.
Submits survey data and notifies trainers.
"""
from __future__ import annotations

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from typing import Any, cast

from users.models import User


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

        # Get trainer to notify
        trainer = getattr(user, 'trainer', None)

        if trainer:
            # Create notification for trainer
            self._notify_trainer(
                trainer=trainer,
                trainee=user,
                workout_name=workout_name,
                survey_data=survey_data,
                avg_score=avg_score,
            )

        # Store survey data (could be saved to a model if needed)
        # For now, we just notify the trainer

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

        # TODO: Send push notification to trainer
        # For now, we could store this in a notifications model
        # or send via email/push notification service

        # Example: Create in-app notification
        try:
            from trainer.models import TrainerNotification
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
        except (ImportError, Exception):
            # Notifications model may not exist yet
            pass


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

        # Get trainer to notify
        trainer = getattr(user, 'trainer', None)

        if trainer:
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

        # TODO: Save workout log to database
        # This could update the DailyLog model with the workout data

        return Response({
            'success': True,
            'message': 'Post-workout survey submitted',
            'stats': {
                'completion_rate': round(completion_rate, 1),
                'completed_sets': completed_sets,
                'total_sets': total_sets,
                'average_score': round(avg_score, 1),
            },
        }, status=status.HTTP_201_CREATED)

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

        # TODO: Send push notification to trainer

        # Create in-app notification
        try:
            from trainer.models import TrainerNotification
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
        except (ImportError, Exception):
            # Notifications model may not exist yet
            pass

"""
Views for workout and nutrition endpoints.
"""
from __future__ import annotations

import logging
import os
import uuid
from rest_framework import viewsets, status

logger = logging.getLogger(__name__)
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.serializers import BaseSerializer
from django.db.models import QuerySet
from django.utils import timezone
from django.core.files.storage import default_storage
from django.conf import settings
from datetime import date, timedelta
from typing import Any, cast

from core.permissions import IsTrainee

from users.models import User
from .models import Exercise, Program, DailyLog, NutritionGoal, WeightCheckIn, MacroPreset
from .serializers import (
    ExerciseSerializer,
    ProgramSerializer,
    DailyLogSerializer,
    NaturalLanguageLogInputSerializer,
    NaturalLanguageLogResponseSerializer,
    ConfirmLogSaveSerializer,
    NutritionGoalSerializer,
    TrainerAdjustGoalSerializer,
    WeightCheckInSerializer,
    MacroPresetSerializer,
    MacroPresetCreateSerializer,
)
from .services.natural_language_parser import NaturalLanguageParserService


class ExerciseViewSet(viewsets.ModelViewSet[Exercise]):
    """
    ViewSet for Exercise CRUD operations.
    Trainers can create custom exercises; all users can view public exercises.
    """
    serializer_class = ExerciseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[Exercise]:
        """Return public exercises + trainer's custom exercises with optional filtering."""
        user = cast(User, self.request.user)

        if user.is_trainer():
            # Trainers see public + their own custom exercises
            queryset = Exercise.objects.filter(
                is_public=True
            ) | Exercise.objects.filter(
                created_by=user
            )
        elif user.is_admin():
            # Admins see all exercises
            queryset = Exercise.objects.all()
        else:
            # Trainees see only public exercises
            queryset = Exercise.objects.filter(is_public=True)

        # Apply filters from query parameters
        muscle_group = self.request.query_params.get('muscle_group')
        if muscle_group:
            queryset = queryset.filter(muscle_group=muscle_group)

        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(name__icontains=search)

        return queryset.order_by('muscle_group', 'name')

    def perform_create(self, serializer: BaseSerializer[Exercise]) -> None:
        """Set created_by to current user if trainer."""
        user = cast(User, self.request.user)
        if user.is_trainer():
            serializer.save(created_by=user, is_public=False)
        else:
            serializer.save(is_public=True)

    @action(detail=True, methods=['post'], url_path='upload-image', parser_classes=[MultiPartParser, FormParser])
    def upload_image(self, request: Request, pk: int = None) -> Response:
        """
        Upload an image for an exercise.

        POST /api/workouts/exercises/{id}/upload-image/
        Content-Type: multipart/form-data
        Body: image file

        Only trainers and admins can upload images.
        """
        user = cast(User, request.user)

        # Check permissions - only trainers and admins can upload
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers and admins can upload exercise images'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the exercise
        try:
            exercise = self.get_object()
        except Exercise.DoesNotExist:
            return Response(
                {'error': 'Exercise not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if image file was provided
        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image file provided. Use "image" as the field name.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        image_file = request.FILES['image']

        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if image_file.content_type not in allowed_types:
            return Response(
                {'error': f'Invalid file type. Allowed types: {", ".join(allowed_types)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file size (max 10MB)
        max_size = 10 * 1024 * 1024  # 10MB
        if image_file.size > max_size:
            return Response(
                {'error': 'File size too large. Maximum size is 10MB.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate unique filename
        file_extension = os.path.splitext(image_file.name)[1].lower()
        if not file_extension:
            # Infer extension from content type
            ext_map = {
                'image/jpeg': '.jpg',
                'image/png': '.png',
                'image/gif': '.gif',
                'image/webp': '.webp',
            }
            file_extension = ext_map.get(image_file.content_type, '.jpg')

        unique_filename = f"exercises/{uuid.uuid4().hex}{file_extension}"

        # Delete old image if it exists and is stored locally
        if exercise.image_url:
            old_url = exercise.image_url
            # Check if it's a local media file
            if old_url.startswith(settings.MEDIA_URL) or '/media/' in old_url:
                old_path = old_url.replace(settings.MEDIA_URL, '').lstrip('/')
                if default_storage.exists(old_path):
                    default_storage.delete(old_path)

        # Save the new image
        saved_path = default_storage.save(unique_filename, image_file)

        # Build the full URL
        image_url = request.build_absolute_uri(f"{settings.MEDIA_URL}{saved_path}")

        # Update exercise with new image URL
        exercise.image_url = image_url
        exercise.save(update_fields=['image_url', 'updated_at'])

        return Response({
            'success': True,
            'image_url': image_url,
            'message': 'Image uploaded successfully'
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='upload-video', parser_classes=[MultiPartParser, FormParser])
    def upload_video(self, request: Request, pk: int = None) -> Response:
        """
        Upload a video for an exercise.

        POST /api/workouts/exercises/{id}/upload-video/
        Content-Type: multipart/form-data
        Body: video file

        Only trainers and admins can upload videos.
        """
        user = cast(User, request.user)

        # Check permissions - only trainers and admins can upload
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers and admins can upload exercise videos'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the exercise
        try:
            exercise = self.get_object()
        except Exercise.DoesNotExist:
            return Response(
                {'error': 'Exercise not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if video file was provided
        if 'video' not in request.FILES:
            return Response(
                {'error': 'No video file provided. Use "video" as the field name.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        video_file = request.FILES['video']

        # Validate file type
        allowed_types = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm', 'video/x-m4v']
        if video_file.content_type not in allowed_types:
            return Response(
                {'error': f'Invalid file type. Allowed types: MP4, MOV, AVI, WebM, M4V'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file size (max 100MB for videos)
        max_size = 100 * 1024 * 1024  # 100MB
        if video_file.size > max_size:
            return Response(
                {'error': 'File size too large. Maximum size is 100MB.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate unique filename
        file_extension = os.path.splitext(video_file.name)[1].lower()
        if not file_extension:
            # Infer extension from content type
            ext_map = {
                'video/mp4': '.mp4',
                'video/quicktime': '.mov',
                'video/x-msvideo': '.avi',
                'video/webm': '.webm',
                'video/x-m4v': '.m4v',
            }
            file_extension = ext_map.get(video_file.content_type, '.mp4')

        unique_filename = f"exercises/videos/{uuid.uuid4().hex}{file_extension}"

        # Delete old video if it exists and is stored locally
        if exercise.video_url:
            old_url = exercise.video_url
            # Check if it's a local media file (not YouTube)
            if (old_url.startswith(settings.MEDIA_URL) or '/media/' in old_url) and 'youtube' not in old_url:
                old_path = old_url.replace(settings.MEDIA_URL, '').lstrip('/')
                if default_storage.exists(old_path):
                    default_storage.delete(old_path)

        # Save the new video
        saved_path = default_storage.save(unique_filename, video_file)

        # Build the full URL
        video_url = request.build_absolute_uri(f"{settings.MEDIA_URL}{saved_path}")

        # Update exercise with new video URL
        exercise.video_url = video_url
        exercise.save(update_fields=['video_url', 'updated_at'])

        return Response({
            'success': True,
            'video_url': video_url,
            'message': 'Video uploaded successfully'
        }, status=status.HTTP_200_OK)


class ProgramViewSet(viewsets.ModelViewSet[Program]):
    """
    ViewSet for Program CRUD operations.
    Trainers create programs for their trainees.
    """
    serializer_class = ProgramSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[Program]:
        """Return programs based on user role."""
        user = cast(User, self.request.user)

        logger.info(f"ProgramViewSet.get_queryset: user={user.email}, role={user.role}, id={user.id}")

        if user.is_trainer():
            # Trainers see programs for their trainees
            queryset = Program.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee', 'created_by')
            logger.info(f"Trainer {user.email}: returning {queryset.count()} programs")
            return queryset
        elif user.is_trainee():
            # Trainees see their own programs
            queryset = Program.objects.filter(
                trainee=user
            ).select_related('trainee', 'created_by')
            logger.info(f"Trainee {user.email}: returning {queryset.count()} programs (user_id={user.id})")
            # Also log all programs to help debug
            all_programs = Program.objects.filter(trainee_id=user.id)
            logger.info(f"Direct query by trainee_id: {all_programs.count()} programs")
            return queryset
        elif user.is_admin():
            # Admins see all programs
            return Program.objects.all().select_related('trainee', 'created_by')
        else:
            logger.warning(f"User {user.email} with role {user.role} - returning empty queryset")
            return Program.objects.none()

    def perform_create(self, serializer: BaseSerializer[Program]) -> None:
        """Set created_by to current user if trainer."""
        user = cast(User, self.request.user)
        if user.is_trainer():
            serializer.save(created_by=user)

    @action(detail=False, methods=['get'])
    def debug(self, request: Request) -> Response:
        """Debug endpoint to diagnose program visibility issues."""
        user = cast(User, request.user)

        # Get all programs where this user is the trainee
        programs_as_trainee = Program.objects.filter(trainee=user)
        # Get all programs where trainee_id matches this user's id
        programs_by_id = Program.objects.filter(trainee_id=user.id)

        return Response({
            'user': {
                'id': user.id,
                'email': user.email,
                'role': user.role,
                'is_trainee': user.is_trainee(),
                'is_trainer': user.is_trainer(),
                'is_admin': user.is_admin(),
                'parent_trainer_id': user.parent_trainer_id,
                'parent_trainer_email': user.parent_trainer.email if user.parent_trainer else None,
            },
            'programs_as_trainee_count': programs_as_trainee.count(),
            'programs_as_trainee': [
                {'id': p.id, 'name': p.name, 'trainee_id': p.trainee_id, 'is_active': p.is_active}
                for p in programs_as_trainee
            ],
            'programs_by_id_count': programs_by_id.count(),
            'queryset_returned': list(self.get_queryset().values('id', 'name', 'trainee_id', 'is_active')),
        })


class DailyLogViewSet(viewsets.ModelViewSet[DailyLog]):
    """
    ViewSet for DailyLog CRUD operations.
    Includes natural language parsing endpoint.
    """
    serializer_class = DailyLogSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[DailyLog]:
        """Return logs based on user role with proper row-level security."""
        user = cast(User, self.request.user)

        if user.is_trainee():
            # Trainees see only their own logs
            queryset = DailyLog.objects.filter(trainee=user).select_related('trainee')
        elif user.is_trainer():
            # Trainers see logs for their trainees only
            queryset = DailyLog.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee')
        elif user.is_admin():
            # Admins see all logs
            queryset = DailyLog.objects.all().select_related('trainee')
        else:
            return DailyLog.objects.none()

        # Support date filtering via query parameter
        date_param = self.request.query_params.get('date')
        if date_param:
            queryset = queryset.filter(date=date_param)

        return queryset
    
    @action(detail=False, methods=['post'], url_path='parse-natural-language')
    def parse_natural_language(self, request: Request) -> Response:
        """
        Parse natural language input into structured log data.

        This endpoint:
        1. Accepts raw user input (text/speech)
        2. Calls AI service to parse it
        3. Returns structured data for UI verification
        4. Does NOT save to database yet (optimistic UI pattern)

        POST /api/workouts/daily-logs/parse-natural-language/
        Body: {"user_input": "I ate a chicken bowl and did 3 sets of bench press at 225"}
        """
        serializer = NaturalLanguageLogInputSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user_input = serializer.validated_data['user_input']
        log_date = serializer.validated_data.get('date', date.today())

        user = cast(User, request.user)

        # Get user context (current program, recent exercises)
        context = self._get_user_context(user, log_date)
        
        # Parse using AI service
        parser_service = NaturalLanguageParserService()
        parsed_data, error_message = parser_service.parse_user_input(
            user_input=user_input,
            context=context
        )
        
        if error_message:
            # If clarification is needed, return it as a response (not an error)
            if parsed_data.get('needs_clarification'):
                response_serializer = NaturalLanguageLogResponseSerializer(data=parsed_data)
                if response_serializer.is_valid():
                    return Response(
                        response_serializer.validated_data,
                        status=status.HTTP_200_OK
                    )
            
            return Response(
                {'error': error_message},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Return parsed data for verification
        response_serializer = NaturalLanguageLogResponseSerializer(data=parsed_data)
        if response_serializer.is_valid():
            return Response(
                response_serializer.validated_data,
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                response_serializer.errors,
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['post'], url_path='confirm-and-save')
    def confirm_and_save(self, request: Request) -> Response:
        """
        Confirm and save parsed log data to database.

        This endpoint:
        1. Accepts the parsed data from parse-natural-language endpoint
        2. Formats it for DailyLog model
        3. Saves to database (creates or updates existing log for the date)

        POST /api/workouts/daily-logs/confirm-and-save/
        Body: {
            "parsed_data": {...},
            "date": "2026-01-23",
            "confirm": true
        }
        """
        serializer = ConfirmLogSaveSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )

        if not serializer.validated_data['confirm']:
            return Response(
                {'error': 'Log save not confirmed'},
                status=status.HTTP_400_BAD_REQUEST
            )

        parsed_data = serializer.validated_data['parsed_data']
        log_date = serializer.validated_data.get('date', date.today())

        user = cast(User, request.user)

        # Ensure user is a trainee
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can create log entries'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Format parsed data for DailyLog
        parser_service = NaturalLanguageParserService()
        formatted_data = parser_service.format_for_daily_log(
            parsed_data=parsed_data,
            trainee_id=user.id
        )

        # Get or create DailyLog for this date
        daily_log, created = DailyLog.objects.get_or_create(
            trainee=user,
            date=log_date,
            defaults={
                'nutrition_data': formatted_data['nutrition_data'],
                'workout_data': formatted_data['workout_data']
            }
        )
        
        if not created:
            # Update existing log (merge data)
            existing_nutrition = daily_log.nutrition_data.get('meals', [])
            existing_workout = daily_log.workout_data.get('exercises', [])
            
            # Merge new meals
            new_meals = formatted_data['nutrition_data'].get('meals', [])
            daily_log.nutrition_data['meals'] = existing_nutrition + new_meals
            
            # Merge new exercises
            new_exercises = formatted_data['workout_data'].get('exercises', [])
            daily_log.workout_data['exercises'] = existing_workout + new_exercises
            
            # Recalculate totals
            daily_log.nutrition_data['totals'] = {
                "protein": sum(meal.get("protein", 0) for meal in daily_log.nutrition_data['meals']),
                "carbs": sum(meal.get("carbs", 0) for meal in daily_log.nutrition_data['meals']),
                "fat": sum(meal.get("fat", 0) for meal in daily_log.nutrition_data['meals']),
                "calories": sum(meal.get("calories", 0) for meal in daily_log.nutrition_data['meals'])
            }
        
        daily_log.save()
        
        # Return saved log
        log_serializer = DailyLogSerializer(daily_log)
        return Response(
            log_serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )
    
    def _get_user_context(self, user: User, log_date: date) -> dict[str, Any]:
        """
        Get user context for AI parsing (current program, recent exercises).
        """
        context: dict[str, Any] = {}

        if user.is_trainee():
            # Get active program
            active_program = Program.objects.filter(
                trainee=user,
                is_active=True,
                start_date__lte=log_date,
                end_date__gte=log_date
            ).first()

            if active_program:
                context['program_name'] = active_program.name
                # Extract recent exercises from program schedule
                schedule = active_program.schedule
                recent_exercises = []
                if isinstance(schedule, dict) and 'weeks' in schedule:
                    for week in schedule.get('weeks', []):
                        for day in week.get('days', []):
                            for exercise in day.get('exercises', []):
                                if 'exercise_name' in exercise:
                                    recent_exercises.append(exercise['exercise_name'])
                context['recent_exercises'] = list(set(recent_exercises))[:10]  # Last 10 unique

        return context

    @action(detail=False, methods=['get'], url_path='nutrition-summary')
    def nutrition_summary(self, request: Request) -> Response:
        """
        Get daily nutrition summary with goals and remaining macros.

        GET /api/workouts/daily-logs/nutrition-summary/?date=2026-01-25

        Returns:
        - goals: Daily macro targets
        - consumed: Current day's totals
        - remaining: Goals minus consumed
        - meals: List of meals logged
        - per_meal_targets: Per-meal macro targets
        """
        date_str = request.query_params.get('date')
        if date_str:
            try:
                target_date = date.fromisoformat(date_str)
            except ValueError:
                return Response(
                    {'error': 'Invalid date format. Use YYYY-MM-DD'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            target_date = date.today()

        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can access nutrition summary'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get nutrition goals
        try:
            nutrition_goal = NutritionGoal.objects.get(trainee=user)
            goals = {
                'protein': nutrition_goal.protein_goal,
                'carbs': nutrition_goal.carbs_goal,
                'fat': nutrition_goal.fat_goal,
                'calories': nutrition_goal.calories_goal,
            }
            per_meal_targets = {
                'protein': nutrition_goal.per_meal_protein,
                'carbs': nutrition_goal.per_meal_carbs,
                'fat': nutrition_goal.per_meal_fat,
            }
        except NutritionGoal.DoesNotExist:
            goals = {'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0}
            per_meal_targets = {'protein': 0, 'carbs': 0, 'fat': 0}

        # Get daily log for the date
        try:
            daily_log = DailyLog.objects.get(trainee=user, date=target_date)
            nutrition_data = daily_log.nutrition_data
            meals = nutrition_data.get('meals', [])
            totals = nutrition_data.get('totals', {})
            consumed = {
                'protein': totals.get('protein', 0),
                'carbs': totals.get('carbs', 0),
                'fat': totals.get('fat', 0),
                'calories': totals.get('calories', 0),
            }
        except DailyLog.DoesNotExist:
            meals = []
            consumed = {'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0}

        # Calculate remaining
        remaining = {
            'protein': max(0, goals['protein'] - consumed['protein']),
            'carbs': max(0, goals['carbs'] - consumed['carbs']),
            'fat': max(0, goals['fat'] - consumed['fat']),
            'calories': max(0, goals['calories'] - consumed['calories']),
        }

        return Response({
            'date': target_date.isoformat(),
            'goals': goals,
            'consumed': consumed,
            'remaining': remaining,
            'meals': meals,
            'per_meal_targets': per_meal_targets,
        })

    @action(detail=False, methods=['get'], url_path='workout-summary')
    def workout_summary(self, request: Request) -> Response:
        """
        Get daily workout summary with program context.

        GET /api/workouts/daily-logs/workout-summary/?date=2026-01-25

        Returns:
        - exercises: List of exercises logged
        - program_context: Current program info if applicable
        """
        date_str = request.query_params.get('date')
        if date_str:
            try:
                target_date = date.fromisoformat(date_str)
            except ValueError:
                return Response(
                    {'error': 'Invalid date format. Use YYYY-MM-DD'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            target_date = date.today()

        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can access workout summary'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get daily log for the date
        try:
            daily_log = DailyLog.objects.get(trainee=user, date=target_date)
            workout_data = daily_log.workout_data
            exercises = workout_data.get('exercises', [])
        except DailyLog.DoesNotExist:
            exercises = []

        # Get program context
        program_context = None
        active_program = Program.objects.filter(
            trainee=user,
            is_active=True,
            start_date__lte=target_date,
            end_date__gte=target_date
        ).first()

        if active_program:
            program_context = {
                'program_id': active_program.id,
                'program_name': active_program.name,
                'start_date': active_program.start_date.isoformat(),
                'end_date': active_program.end_date.isoformat(),
            }

        return Response({
            'date': target_date.isoformat(),
            'exercises': exercises,
            'program_context': program_context,
        })

    @action(detail=False, methods=['get'], url_path='weekly-progress',
            permission_classes=[IsTrainee])
    def weekly_progress(self, request: Request) -> Response:
        """
        Get weekly workout progress for current trainee (Mon-Sun).

        GET /api/workouts/daily-logs/weekly-progress/

        Returns total_days, completed_days, percentage, week_start, week_end.
        A "completed day" is any day with non-empty DailyLog.workout_data.
        """
        user = cast(User, request.user)

        # Calculate current week (Mon-Sun)
        today = date.today()
        monday = today - timedelta(days=today.weekday())  # weekday() 0=Mon
        sunday = monday + timedelta(days=6)

        # Find active program to determine expected workout days
        active_program = Program.objects.filter(
            trainee=user,
            is_active=True,
        ).first()

        if active_program is None:
            return Response({
                'total_days': 0,
                'completed_days': 0,
                'percentage': 0,
                'week_start': monday.isoformat(),
                'week_end': sunday.isoformat(),
                'has_program': False,
            })

        # Count expected workout days per week from program schedule
        total_days = self._count_weekly_workout_days(active_program)

        # Count completed days: days with non-empty workout_data
        completed_days = DailyLog.objects.filter(
            trainee=user,
            date__range=(monday, sunday),
        ).exclude(
            workout_data={},
        ).exclude(
            workout_data__isnull=True,
        ).count()

        percentage = round((completed_days / total_days) * 100) if total_days > 0 else 0

        return Response({
            'total_days': total_days,
            'completed_days': completed_days,
            'percentage': min(percentage, 100),
            'week_start': monday.isoformat(),
            'week_end': sunday.isoformat(),
            'has_program': True,
        })

    @staticmethod
    def _count_weekly_workout_days(program: Program) -> int:
        """Count non-rest workout days per week from program schedule."""
        schedule = program.schedule
        if not schedule:
            return 0

        # Schedule is either a list of weeks or a dict with 'weeks' key
        weeks: list[Any] = []
        if isinstance(schedule, list) and schedule:
            weeks = schedule
        elif isinstance(schedule, dict):
            if 'weeks' in schedule and isinstance(schedule['weeks'], list):
                weeks = schedule['weeks']

        if not weeks:
            return 0

        # Use the first week as representative for expected days per week
        first_week = weeks[0]
        if not isinstance(first_week, dict):
            return 0

        days = first_week.get('days', [])
        if not isinstance(days, list):
            return 0

        workout_days = 0
        for day in days:
            if not isinstance(day, dict):
                continue
            is_rest = day.get('is_rest_day', False)
            day_name = day.get('name', '')
            is_rest_by_name = isinstance(day_name, str) and 'rest' in day_name.lower()
            if not is_rest and not is_rest_by_name:
                workout_days += 1

        return workout_days

    @action(detail=True, methods=['put'], url_path='edit-meal-entry',
            permission_classes=[IsTrainee])
    def edit_meal_entry(self, request: Request, pk: int | None = None) -> Response:
        """
        Edit a food entry in a DailyLog's nutrition_data.

        PUT /api/workouts/daily-logs/<id>/edit-meal-entry/
        Body: {
            "entry_index": 0,
            "data": {"name": "Chicken Bowl", "protein": 50, "carbs": 60, "fat": 20, "calories": 650}
        }

        entry_index is a flat index into the meals array.
        """
        daily_log = self.get_object()
        user = cast(User, request.user)

        # Row-level security: trainee can only edit their own logs
        if daily_log.trainee != user:
            return Response(
                {'error': 'Not authorized to edit this log'},
                status=status.HTTP_403_FORBIDDEN,
            )

        entry_index = request.data.get('entry_index')
        entry_data = request.data.get('data')

        if entry_index is None or entry_data is None:
            return Response(
                {'error': 'entry_index and data are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not isinstance(entry_data, dict):
            return Response(
                {'error': 'data must be an object'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        nutrition_data = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        # entry_index is a flat index into the meals array.
        target_index = entry_index
        if not isinstance(target_index, int) or target_index < 0 or target_index >= len(meals):
            return Response(
                {'error': 'Invalid entry_index: entry not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Validate numeric fields
        for field in ['protein', 'carbs', 'fat', 'calories']:
            if field in entry_data:
                value = entry_data[field]
                if not isinstance(value, (int, float)) or value < 0:
                    return Response(
                        {'error': f'{field} must be a non-negative number'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

        # Whitelist allowed keys to prevent arbitrary key injection
        allowed_keys = {'name', 'protein', 'carbs', 'fat', 'calories', 'timestamp'}
        entry_data = {k: v for k, v in entry_data.items() if k in allowed_keys}

        if not entry_data:
            return Response(
                {'error': 'No valid fields provided'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update the entry, preserving any fields not in data
        existing_entry = meals[target_index]
        if isinstance(existing_entry, dict):
            existing_entry.update(entry_data)
        else:
            meals[target_index] = entry_data

        # Recalculate totals
        nutrition_data['totals'] = self._recalculate_nutrition_totals(meals)
        daily_log.nutrition_data = nutrition_data
        daily_log.save(update_fields=['nutrition_data', 'updated_at'])

        return Response(DailyLogSerializer(daily_log).data)

    @action(detail=True, methods=['post'], url_path='delete-meal-entry',
            permission_classes=[IsTrainee])
    def delete_meal_entry(self, request: Request, pk: int | None = None) -> Response:
        """
        Delete a food entry from a DailyLog's nutrition_data.

        POST /api/workouts/daily-logs/<id>/delete-meal-entry/
        Body: {"entry_index": 0}
        """
        daily_log = self.get_object()
        user = cast(User, request.user)

        # Row-level security
        if daily_log.trainee != user:
            return Response(
                {'error': 'Not authorized to edit this log'},
                status=status.HTTP_403_FORBIDDEN,
            )

        entry_index = request.data.get('entry_index')

        if entry_index is None:
            return Response(
                {'error': 'entry_index is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        nutrition_data = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        target_index = entry_index
        if not isinstance(target_index, int) or target_index < 0 or target_index >= len(meals):
            return Response(
                {'error': 'Invalid entry_index: entry not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Remove the entry
        meals.pop(target_index)

        # Recalculate totals
        nutrition_data['totals'] = self._recalculate_nutrition_totals(meals)
        daily_log.nutrition_data = nutrition_data
        daily_log.save(update_fields=['nutrition_data', 'updated_at'])

        return Response(DailyLogSerializer(daily_log).data)

    @staticmethod
    def _recalculate_nutrition_totals(meals: list[dict[str, Any]]) -> dict[str, int]:
        """Recalculate nutrition totals from a list of meal entries."""
        return {
            'protein': sum(
                m.get('protein', 0) for m in meals if isinstance(m, dict)
            ),
            'carbs': sum(
                m.get('carbs', 0) for m in meals if isinstance(m, dict)
            ),
            'fat': sum(
                m.get('fat', 0) for m in meals if isinstance(m, dict)
            ),
            'calories': sum(
                m.get('calories', 0) for m in meals if isinstance(m, dict)
            ),
        }


class NutritionGoalViewSet(viewsets.ModelViewSet[NutritionGoal]):
    """
    ViewSet for NutritionGoal CRUD operations.
    Trainees see their own goals; Trainers can adjust trainee goals.
    """
    serializer_class = NutritionGoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[NutritionGoal]:
        """Return goals based on user role."""
        user = cast(User, self.request.user)

        if user.is_trainee():
            return NutritionGoal.objects.filter(trainee=user)
        elif user.is_trainer():
            # Trainers see goals for their trainees
            return NutritionGoal.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee', 'adjusted_by')
        elif user.is_admin():
            return NutritionGoal.objects.all().select_related('trainee', 'adjusted_by')
        else:
            return NutritionGoal.objects.none()

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """For trainees, return their single goal as an object."""
        user = cast(User, request.user)
        if user.is_trainee():
            try:
                goal = NutritionGoal.objects.get(trainee=user)
                serializer = self.get_serializer(goal)
                return Response(serializer.data)
            except NutritionGoal.DoesNotExist:
                return Response(
                    {'error': 'No nutrition goals set. Complete onboarding first.'},
                    status=status.HTTP_404_NOT_FOUND
                )
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['post'], url_path='trainer-adjust')
    def trainer_adjust(self, request: Request) -> Response:
        """
        Trainer adjusts a trainee's nutrition goals.

        POST /api/workouts/nutrition-goals/trainer-adjust/
        Body: {
            "trainee_id": 123,
            "protein_goal": 180,
            "carbs_goal": 250,
            "fat_goal": 70,
            "calories_goal": 2500
        }
        """
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can adjust nutrition goals'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = TrainerAdjustGoalSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        trainee_id = serializer.validated_data['trainee_id']

        # Verify trainee belongs to this trainer
        try:
            trainee = User.objects.get(
                id=trainee_id,
                role=User.Role.TRAINEE,
                parent_trainer=user
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get or create nutrition goal
        goal, _ = NutritionGoal.objects.get_or_create(trainee=trainee)

        # Update fields
        for field in ['protein_goal', 'carbs_goal', 'fat_goal', 'calories_goal']:
            if field in serializer.validated_data:
                setattr(goal, field, serializer.validated_data[field])

        goal.is_trainer_adjusted = True
        goal.adjusted_by = user
        goal.save()

        return Response(NutritionGoalSerializer(goal).data)


class WeightCheckInViewSet(viewsets.ModelViewSet[WeightCheckIn]):
    """
    ViewSet for WeightCheckIn CRUD operations.
    """
    serializer_class = WeightCheckInSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[WeightCheckIn]:
        """Return check-ins based on user role."""
        user = cast(User, self.request.user)

        if user.is_trainee():
            return WeightCheckIn.objects.filter(trainee=user)
        elif user.is_trainer():
            return WeightCheckIn.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee')
        elif user.is_admin():
            return WeightCheckIn.objects.all().select_related('trainee')
        else:
            return WeightCheckIn.objects.none()

    def perform_create(self, serializer: BaseSerializer[WeightCheckIn]) -> None:
        """Set trainee to current user."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            serializer.save(trainee=user)
        else:
            serializer.save()

    @action(detail=False, methods=['get'], url_path='latest')
    def latest(self, request: Request) -> Response:
        """
        Get the most recent weight check-in.

        GET /api/workouts/weight-checkins/latest/
        """
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can access their latest check-in'},
                status=status.HTTP_403_FORBIDDEN
            )

        checkin = WeightCheckIn.objects.filter(trainee=user).first()
        if not checkin:
            return Response(
                {'error': 'No weight check-ins found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = self.get_serializer(checkin)
        return Response(serializer.data)


class MacroPresetViewSet(viewsets.ModelViewSet[MacroPreset]):
    """
    ViewSet for MacroPreset CRUD operations.
    Trainers can create/edit presets for their trainees.
    Trainees can view their own presets.
    """
    serializer_class = MacroPresetSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[MacroPreset]:
        """Return presets based on user role."""
        user = cast(User, self.request.user)

        if user.is_trainee():
            return MacroPreset.objects.filter(trainee=user)
        elif user.is_trainer():
            # Trainers see presets for their trainees
            return MacroPreset.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee', 'created_by')
        elif user.is_admin():
            return MacroPreset.objects.all().select_related('trainee', 'created_by')
        else:
            return MacroPreset.objects.none()

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """
        List presets. Can filter by trainee_id for trainers.
        """
        trainee_id = request.query_params.get('trainee_id')
        user = cast(User, request.user)

        if trainee_id and user.is_trainer():
            # Verify trainee belongs to this trainer
            try:
                trainee = User.objects.get(
                    id=trainee_id,
                    role=User.Role.TRAINEE,
                    parent_trainer=user
                )
                queryset = MacroPreset.objects.filter(trainee=trainee)
                serializer = self.get_serializer(queryset, many=True)
                return Response(serializer.data)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Trainee not found or not assigned to you'},
                    status=status.HTTP_404_NOT_FOUND
                )

        return super().list(request, *args, **kwargs)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Create a new macro preset (trainers only)."""
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can create macro presets'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = MacroPresetCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        trainee_id = serializer.validated_data['trainee_id']

        # Verify trainee belongs to this trainer
        try:
            trainee = User.objects.get(
                id=trainee_id,
                role=User.Role.TRAINEE,
                parent_trainer=user
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Create the preset
        preset = MacroPreset.objects.create(
            trainee=trainee,
            name=serializer.validated_data['name'],
            calories=serializer.validated_data['calories'],
            protein=serializer.validated_data['protein'],
            carbs=serializer.validated_data['carbs'],
            fat=serializer.validated_data['fat'],
            frequency_per_week=serializer.validated_data.get('frequency_per_week'),
            is_default=serializer.validated_data.get('is_default', False),
            sort_order=serializer.validated_data.get('sort_order', 0),
            created_by=user
        )

        return Response(
            MacroPresetSerializer(preset).data,
            status=status.HTTP_201_CREATED
        )

    def update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Update a macro preset (trainers only)."""
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can update macro presets'},
                status=status.HTTP_403_FORBIDDEN
            )

        preset = self.get_object()

        # Verify trainer owns this trainee
        if preset.trainee.parent_trainer != user:
            return Response(
                {'error': 'Not authorized to update this preset'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Update fields
        for field in ['name', 'calories', 'protein', 'carbs', 'fat',
                      'frequency_per_week', 'is_default', 'sort_order']:
            if field in request.data:
                setattr(preset, field, request.data[field])

        preset.save()
        return Response(MacroPresetSerializer(preset).data)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Delete a macro preset (trainers only)."""
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can delete macro presets'},
                status=status.HTTP_403_FORBIDDEN
            )

        preset = self.get_object()

        # Verify trainer owns this trainee
        if preset.trainee.parent_trainer != user:
            return Response(
                {'error': 'Not authorized to delete this preset'},
                status=status.HTTP_403_FORBIDDEN
            )

        preset.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def all_presets(self, request: Request) -> Response:
        """
        Get all presets created by this trainer, grouped by trainee.
        Used for importing presets from one trainee to another.
        """
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can access this endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all trainees for this trainer
        trainees = User.objects.filter(
            role=User.Role.TRAINEE,
            parent_trainer=user
        ).order_by('first_name', 'last_name', 'email')

        result = []
        for trainee in trainees:
            presets = MacroPreset.objects.filter(trainee=trainee)
            if presets.exists():
                name = f"{trainee.first_name or ''} {trainee.last_name or ''}".strip()
                if not name:
                    name = trainee.email.split('@')[0]

                result.append({
                    'trainee_id': trainee.id,
                    'trainee_name': name,
                    'trainee_email': trainee.email,
                    'presets': MacroPresetSerializer(presets, many=True).data
                })

        return Response(result)

    @action(detail=True, methods=['post'])
    def copy_to(self, request: Request, pk: int | None = None) -> Response:
        """
        Copy a preset to another trainee.
        POST /api/workouts/macro-presets/{id}/copy_to/
        Body: {"trainee_id": 123}
        """
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can copy presets'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the source preset
        source_preset = self.get_object()

        # Verify trainer owns this preset's trainee
        if source_preset.trainee.parent_trainer != user:
            return Response(
                {'error': 'Not authorized to copy this preset'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get target trainee
        target_trainee_id = request.data.get('trainee_id')
        if not target_trainee_id:
            return Response(
                {'error': 'trainee_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            target_trainee = User.objects.get(
                id=target_trainee_id,
                role=User.Role.TRAINEE,
                parent_trainer=user
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Target trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Create a copy of the preset for the target trainee
        new_preset = MacroPreset.objects.create(
            trainee=target_trainee,
            name=source_preset.name,
            calories=source_preset.calories,
            protein=source_preset.protein,
            carbs=source_preset.carbs,
            fat=source_preset.fat,
            frequency_per_week=source_preset.frequency_per_week,
            is_default=False,  # Don't copy default status
            sort_order=source_preset.sort_order,
            created_by=user
        )

        return Response(
            MacroPresetSerializer(new_preset).data,
            status=status.HTTP_201_CREATED
        )

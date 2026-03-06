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
from .models import (
    CheckInAssignment,
    CheckInResponse,
    CheckInTemplate,
    DailyLog,
    Exercise,
    FoodItem,
    Habit,
    HabitLog,
    MacroPreset,
    MealLog,
    MealLogEntry,
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
    ProgressionSuggestion,
    ProgressPhoto,
    WeightCheckIn,
    WorkoutTemplate,
)
from rest_framework.pagination import PageNumberPagination

from .serializers import (
    CheckInAssignmentSerializer,
    CheckInAssignSerializer,
    CheckInResponseCreateSerializer,
    CheckInResponseSerializer,
    CheckInTemplateSerializer,
    ConfirmLogSaveSerializer,
    DailyLogSerializer,
    DeloadCheckSerializer,
    DeleteMealEntrySerializer,
    EditMealEntrySerializer,
    ExerciseSerializer,
    ExerciseVideoUploadSerializer,
    FoodLookupSerializer,
    HabitCreateSerializer,
    HabitLogSerializer,
    HabitSerializer,
    HabitStreakSerializer,
    HabitToggleSerializer,
    MacroPresetCreateSerializer,
    MacroPresetSerializer,
    NaturalLanguageLogInputSerializer,
    NaturalLanguageLogResponseSerializer,
    NutritionDayPlanOverrideSerializer,
    NutritionDayPlanSerializer,
    NutritionGoalSerializer,
    NutritionTemplateAssignmentCreateSerializer,
    NutritionTemplateAssignmentSerializer,
    NutritionTemplateCreateSerializer,
    NutritionTemplateSerializer,
    ProgressionSuggestionSerializer,
    ProgressPhotoSerializer,
    ProgramSerializer,
    QuickLogSerializer,
    RestDayCompleteSerializer,
    ShareCardSerializer,
    TrainerAdjustGoalSerializer,
    WeightCheckInSerializer,
    WorkoutDetailSerializer,
    WorkoutHistorySummarySerializer,
    WorkoutTemplateSerializer,
    FoodItemCreateSerializer,
    FoodItemSerializer,
    MealLogEntrySerializer,
    MealLogSerializer,
    MealLogSummarySerializer,
    QuickAddEntrySerializer,
)
from core.permissions import IsTrainer as IsTrainerPerm

from .services.daily_log_service import DailyLogService
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

        difficulty_level = self.request.query_params.get('difficulty_level')
        if difficulty_level:
            valid_difficulties = {c[0] for c in Exercise.DifficultyLevel.choices}
            if difficulty_level in valid_difficulties:
                queryset = queryset.filter(difficulty_level=difficulty_level)
            else:
                # Invalid difficulty_level: return empty queryset rather than unfiltered
                return queryset.none()

        goal = self.request.query_params.get('goal')
        if goal:
            valid_goals = {
                'build_muscle', 'fat_loss', 'strength',
                'endurance', 'recomp', 'general_fitness',
            }
            if goal in valid_goals:
                queryset = queryset.filter(suitable_for_goals__contains=[goal])
            else:
                return queryset.none()

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

        # Delete old image if it exists in our storage (local or Spaces)
        if exercise.image_url:
            old_path = self._extract_storage_path(exercise.image_url)
            if old_path and default_storage.exists(old_path):
                default_storage.delete(old_path)

        # Save the new image
        saved_path = default_storage.save(unique_filename, image_file)

        # Build the full URL — default_storage.url() returns the correct URL
        # for both local filesystem and remote backends (e.g. DO Spaces)
        image_url = default_storage.url(saved_path)

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

        # Delete old video if it exists in our storage (local or Spaces)
        if exercise.video_url and 'youtube' not in exercise.video_url:
            old_path = self._extract_storage_path(exercise.video_url)
            if old_path and default_storage.exists(old_path):
                default_storage.delete(old_path)

        # Save the new video
        saved_path = default_storage.save(unique_filename, video_file)

        # Build the full URL — default_storage.url() returns the correct URL
        # for both local filesystem and remote backends (e.g. DO Spaces)
        video_url = default_storage.url(saved_path)

        # Update exercise with new video URL
        exercise.video_url = video_url
        exercise.save(update_fields=['video_url', 'updated_at'])

        return Response({
            'success': True,
            'video_url': video_url,
            'message': 'Video uploaded successfully'
        }, status=status.HTTP_200_OK)

    @staticmethod
    def _extract_storage_path(url: str) -> str | None:
        """
        Extract the default_storage-relative path from a media URL.

        Handles both local paths (/media/exercises/foo.jpg) and
        DO Spaces URLs (https://bucket.sfo3.digitaloceanspaces.com/media/exercises/foo.jpg).

        Returns None for external URLs (YouTube, SerpAPI images, etc.).
        """
        if not url:
            return None

        # DO Spaces URL — extract path after /media/
        if "digitaloceanspaces.com" in url:
            marker = "/media/"
            idx = url.find(marker)
            if idx >= 0:
                return url[idx + len(marker):]
            return None

        # Local relative path: /media/... or media/...
        if url.startswith("/media/"):
            return url[len("/media/"):]
        if url.startswith("media/"):
            return url[len("media/"):]

        # Localhost absolute URL
        if url.startswith(("http://localhost", "http://127.0.0.1")) and "/media/" in url:
            idx = url.find("/media/")
            return url[idx + len("/media/"):]

        # Not our storage
        return None


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

        logger.debug(f"ProgramViewSet.get_queryset: user_id={user.id}, role={user.role}")

        if user.is_trainer():
            # Trainers see programs for their trainees
            return Program.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee', 'created_by')
        elif user.is_trainee():
            # Trainees see their own programs
            return Program.objects.filter(
                trainee=user
            ).select_related('trainee', 'created_by')
        elif user.is_admin():
            # Admins see all programs
            return Program.objects.all().select_related('trainee', 'created_by')
        else:
            logger.warning(f"User id={user.id} with role {user.role} - returning empty queryset")
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

    # --- Phase 3: Progression & Deload Actions ---

    @action(detail=True, methods=['get'], url_path='progression-suggestions')
    def progression_suggestions(self, request: Request, pk: int = None) -> Response:
        """
        Generate and return progression suggestions for a program.
        GET /api/workouts/programs/{id}/progression-suggestions/
        """
        from .services.progression_service import generate_suggestions

        program = self.get_object()
        suggestions = generate_suggestions(program)
        existing = ProgressionSuggestion.objects.filter(
            program=program,
            status=ProgressionSuggestion.Status.PENDING,
        ).select_related('exercise', 'trainee')

        serializer = ProgressionSuggestionSerializer(existing, many=True)
        return Response({
            'suggestions': serializer.data,
            'new_suggestions_generated': len(suggestions),
        })

    @action(detail=True, methods=['get'], url_path='deload-check')
    def deload_check(self, request: Request, pk: int = None) -> Response:
        """
        Check if a trainee needs a deload week.
        GET /api/workouts/programs/{id}/deload-check/
        """
        from .services.deload_detection_service import check_deload_needed

        program = self.get_object()
        recommendation = check_deload_needed(program)

        serializer = DeloadCheckSerializer({
            'needs_deload': recommendation.needs_deload,
            'confidence': recommendation.confidence,
            'rationale': recommendation.rationale,
            'suggested_intensity_modifier': recommendation.suggested_intensity_modifier,
            'suggested_volume_modifier': recommendation.suggested_volume_modifier,
            'weekly_volume_trend': recommendation.weekly_volume_trend,
            'fatigue_signals': recommendation.fatigue_signals,
        })
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='apply-deload')
    def apply_deload(self, request: Request, pk: int = None) -> Response:
        """
        Apply deload to a specific week of the program.
        POST /api/workouts/programs/{id}/apply-deload/
        Body: {week_number: int}
        """
        from .services.deload_detection_service import apply_deload

        program = self.get_object()
        week_number = request.data.get('week_number')
        if not week_number or not isinstance(week_number, int):
            return Response(
                {'error': 'week_number is required and must be an integer'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            week = apply_deload(program, week_number)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'success': True,
            'week_number': week.week_number,
            'is_deload': week.is_deload,
            'intensity_modifier': week.intensity_modifier,
            'volume_modifier': week.volume_modifier,
        })

    @action(detail=True, methods=['get'], url_path='export-pdf')
    def export_pdf(self, request: Request, pk: int = None) -> Response:
        """
        Export program as PDF.
        GET /api/workouts/programs/{id}/export-pdf/
        """
        from django.http import HttpResponse as DjangoHttpResponse

        from .services.pdf_export_service import export_program_pdf

        program = self.get_object()

        try:
            pdf_bytes = export_program_pdf(program)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        response = DjangoHttpResponse(pdf_bytes, content_type='application/pdf')
        filename = f"{program.name.replace(' ', '_')}_program.pdf"
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response


class WorkoutHistoryPagination(PageNumberPagination):
    """Pagination for workout history endpoint."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 50


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

    @action(detail=False, methods=['get'], url_path='workout-history',
            permission_classes=[IsTrainee])
    def workout_history(self, request: Request) -> Response:
        """
        Get paginated workout history for the current trainee.

        Only returns DailyLogs where workout_data contains actual exercise data
        (excludes null, empty dict, and empty exercises list).

        GET /api/workouts/daily-logs/workout-history/?page=1&page_size=20

        Returns paginated list with computed summary fields per log:
        workout_name, exercise_count, total_sets, total_volume_lbs, duration_display.
        """
        user = cast(User, request.user)

        queryset = DailyLogService.get_workout_history_queryset(user.id)

        paginator = WorkoutHistoryPagination()
        page = paginator.paginate_queryset(queryset, request)

        if page is not None:
            serializer = WorkoutHistorySummarySerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = WorkoutHistorySummarySerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='workout-detail',
            permission_classes=[IsTrainee])
    def workout_detail(self, request: Request, pk: int | None = None) -> Response:
        """
        Get full workout detail for a single DailyLog.

        GET /api/workouts/daily-logs/{id}/workout-detail/

        Returns workout_data, date, and notes for the detail screen.
        Row-level security enforced via get_queryset() filtering by trainee=user.
        """
        daily_log = self.get_object()
        serializer = WorkoutDetailSerializer(daily_log)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='parse-natural-language',
            permission_classes=[IsTrainee])
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
    
    @action(detail=False, methods=['post'], url_path='confirm-and-save',
            permission_classes=[IsTrainee])
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

        # Check achievements after nutrition logging (non-blocking)
        try:
            from community.services.achievement_service import check_and_award_achievements
            check_and_award_achievements(user, 'nutrition_logged')
        except Exception:
            logger.exception("Achievement check failed after nutrition save for user %s", user.id)

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

        serializer = EditMealEntrySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST,
            )

        entry_data: dict[str, Any] = serializer.validated_data['data']

        nutrition_data = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        target_index: int = serializer.validated_data['entry_index']
        if target_index >= len(meals):
            return Response(
                {'error': 'Invalid entry_index: entry not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

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

        serializer = DeleteMealEntrySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST,
            )

        nutrition_data = daily_log.nutrition_data or {}
        meals: list[Any] = nutrition_data.get('meals', [])

        target_index: int = serializer.validated_data['entry_index']
        if target_index >= len(meals):
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

    # --- Phase 1 Actions ---

    @action(detail=False, methods=['post'], url_path='quick-log')
    def quick_log(self, request: Request) -> Response:
        """
        Quick-log a non-program workout (cardio, sports, etc.).
        POST /api/workouts/daily-logs/quick-log/
        """
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can quick-log workouts'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = QuickLogSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        log_date = serializer.validated_data.get('date', date.today())
        daily_log, _ = DailyLog.objects.get_or_create(
            trainee=user,
            date=log_date,
        )

        # Append quick-log session to workout_data
        workout_data = daily_log.workout_data or {}
        sessions = workout_data.get('sessions', [])
        if not isinstance(sessions, list):
            sessions = []

        sessions.append({
            'type': 'quick_log',
            'activity_name': serializer.validated_data['activity_name'],
            'category': serializer.validated_data.get('category', 'other'),
            'duration_minutes': serializer.validated_data['duration_minutes'],
            'calories_burned': serializer.validated_data.get('calories_burned', 0),
            'notes': serializer.validated_data.get('notes', ''),
            'template_id': serializer.validated_data.get('template_id'),
            'timestamp': timezone.now().isoformat(),
        })

        workout_data['sessions'] = sessions
        if not workout_data.get('workout_name'):
            workout_data['workout_name'] = serializer.validated_data['activity_name']

        daily_log.workout_data = workout_data
        daily_log.save(update_fields=['workout_data', 'updated_at'])

        return Response(
            DailyLogSerializer(daily_log).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['post'], url_path='complete-rest-day')
    def complete_rest_day(self, request: Request) -> Response:
        """
        Mark a rest day as completed with optional recovery exercises.
        POST /api/workouts/daily-logs/complete-rest-day/
        """
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can complete rest days'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = RestDayCompleteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        log_date = serializer.validated_data.get('date', date.today())
        daily_log, _ = DailyLog.objects.get_or_create(
            trainee=user,
            date=log_date,
        )

        workout_data = daily_log.workout_data or {}
        workout_data['day_type'] = 'rest'
        workout_data['rest_day_completed'] = True
        workout_data['completed_recovery_exercises'] = serializer.validated_data.get(
            'completed_exercises', [],
        )
        workout_data['workout_name'] = 'Rest Day'
        if serializer.validated_data.get('notes'):
            daily_log.notes = serializer.validated_data['notes']

        daily_log.workout_data = workout_data
        daily_log.save(update_fields=['workout_data', 'notes', 'updated_at'])

        return Response(DailyLogSerializer(daily_log).data)

    # --- Phase 2 Actions ---

    @action(detail=False, methods=['get'], url_path='barcode-lookup')
    def barcode_lookup(self, request: Request) -> Response:
        """
        Look up food by barcode.
        GET /api/workouts/daily-logs/barcode-lookup/?barcode=...
        """
        barcode = request.query_params.get('barcode')
        if not barcode:
            return Response(
                {'error': 'barcode query parameter is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from .services.food_lookup_service import lookup_barcode
        import requests as http_requests

        try:
            result = lookup_barcode(barcode)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except http_requests.RequestException as e:
            return Response(
                {'error': f'Food database lookup failed: {str(e)}'},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        serializer = FoodLookupSerializer({
            'barcode': result.barcode,
            'product_name': result.product_name,
            'brand': result.brand,
            'serving_size': result.serving_size,
            'calories': result.calories,
            'protein': result.protein,
            'carbs': result.carbs,
            'fat': result.fat,
            'fiber': result.fiber,
            'sugar': result.sugar,
            'image_url': result.image_url,
            'found': result.found,
        })
        return Response(serializer.data)

    # --- Phase 3 Actions ---

    @action(detail=True, methods=['get'], url_path='share-card')
    def share_card(self, request: Request, pk: int = None) -> Response:
        """
        Get share card data for a workout.
        GET /api/workouts/daily-logs/{id}/share-card/
        """
        daily_log = self.get_object()

        from .services.share_card_service import generate_share_card

        try:
            card_data = generate_share_card(daily_log)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ShareCardSerializer({
            'workout_name': card_data.workout_name,
            'date': card_data.date,
            'exercise_count': card_data.exercise_count,
            'total_sets': card_data.total_sets,
            'total_volume': card_data.total_volume,
            'volume_unit': card_data.volume_unit,
            'duration': card_data.duration,
            'exercises': card_data.exercises,
            'trainee_name': card_data.trainee_name,
            'trainer_branding': card_data.trainer_branding,
        })
        return Response(serializer.data)


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
        """Set trainee to current user and check achievements."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            serializer.save(trainee=user)
            # Check achievements after weight check-in (non-blocking)
            try:
                from community.services.achievement_service import check_and_award_achievements
                check_and_award_achievements(user, 'weight_checkin')
            except Exception:
                logger.exception("Achievement check failed after weight check-in for user %s", user.id)
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


# ============================================================
# Phase 1: Exercise Videos, Quick-Log, Rest Days
# ============================================================


class WorkoutTemplateViewSet(viewsets.ModelViewSet[WorkoutTemplate]):
    """
    ViewSet for WorkoutTemplate CRUD operations.
    Trainers can create custom templates; all users see public templates.
    """
    serializer_class = WorkoutTemplateSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[WorkoutTemplate]:
        """Return public templates + trainer's custom templates."""
        user = cast(User, self.request.user)

        if user.is_trainer():
            return WorkoutTemplate.objects.filter(
                is_public=True
            ) | WorkoutTemplate.objects.filter(
                created_by=user
            )
        elif user.is_admin():
            return WorkoutTemplate.objects.all()
        else:
            return WorkoutTemplate.objects.filter(is_public=True)

    def perform_create(self, serializer: BaseSerializer[WorkoutTemplate]) -> None:
        """Set created_by to current trainer."""
        user = cast(User, self.request.user)
        if user.is_trainer():
            serializer.save(created_by=user, is_public=False)
        else:
            serializer.save(is_public=True)


# ============================================================
# Phase 2: Progress Photos, Barcode Scanner, Habits
# ============================================================


class ProgressPhotoViewSet(viewsets.ModelViewSet[ProgressPhoto]):
    """
    ViewSet for progress photo CRUD.
    Trainees manage their own photos.
    """
    serializer_class = ProgressPhotoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self) -> QuerySet[ProgressPhoto]:
        """Return photos for the current trainee."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            return ProgressPhoto.objects.filter(trainee=user).select_related('trainee')
        elif user.is_trainer():
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                return ProgressPhoto.objects.filter(
                    trainee_id=trainee_id,
                    trainee__parent_trainer=user,
                ).select_related('trainee')
            return ProgressPhoto.objects.filter(
                trainee__parent_trainer=user,
            ).select_related('trainee')
        return ProgressPhoto.objects.none()

    def perform_create(self, serializer: BaseSerializer[ProgressPhoto]) -> None:
        """Set trainee to current user."""
        serializer.save(trainee=self.request.user)

    @action(detail=False, methods=['get'], url_path='compare')
    def compare(self, request: Request) -> Response:
        """
        Compare two progress photos side by side.
        GET /api/workouts/progress-photos/compare/?photo1=ID&photo2=ID
        """
        photo1_id = request.query_params.get('photo1')
        photo2_id = request.query_params.get('photo2')

        if not photo1_id or not photo2_id:
            return Response(
                {'error': 'Both photo1 and photo2 query parameters are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        queryset = self.get_queryset()
        try:
            photo1 = queryset.get(id=photo1_id)
            photo2 = queryset.get(id=photo2_id)
        except ProgressPhoto.DoesNotExist:
            return Response(
                {'error': 'One or both photos not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = ProgressPhotoSerializer(
            [photo1, photo2], many=True, context={'request': request},
        )
        return Response({'photos': serializer.data})


class HabitViewSet(viewsets.ModelViewSet[Habit]):
    """
    ViewSet for Habit CRUD.
    Trainers create and manage habits for their trainees.
    """
    serializer_class = HabitSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[Habit]:
        """Return habits based on user role."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            return Habit.objects.filter(
                trainee=user, is_active=True,
            ).select_related('trainer', 'trainee')
        elif user.is_trainer():
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                return Habit.objects.filter(
                    trainer=user, trainee_id=trainee_id,
                ).select_related('trainer', 'trainee')
            return Habit.objects.filter(
                trainer=user,
            ).select_related('trainer', 'trainee')
        return Habit.objects.none()

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Create a habit for a trainee."""
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can create habits'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = HabitCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        trainee_id = serializer.validated_data['trainee_id']
        try:
            trainee = User.objects.get(
                id=trainee_id, role=User.Role.TRAINEE, parent_trainer=user,
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND,
            )

        habit = Habit.objects.create(
            trainer=user,
            trainee=trainee,
            name=serializer.validated_data['name'],
            description=serializer.validated_data.get('description', ''),
            icon=serializer.validated_data.get('icon', 'check_circle'),
            frequency=serializer.validated_data.get('frequency', 'daily'),
            custom_days=serializer.validated_data.get('custom_days', []),
        )

        return Response(
            HabitSerializer(habit).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['post'], url_path='toggle')
    def toggle(self, request: Request) -> Response:
        """
        Toggle habit completion for a date.
        POST /api/workouts/habits/toggle/
        Body: {habit_id: int, date: "YYYY-MM-DD"}
        """
        serializer = HabitToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = cast(User, request.user)
        habit_id = serializer.validated_data['habit_id']
        target_date = serializer.validated_data.get('date', date.today())

        try:
            habit = Habit.objects.get(id=habit_id, trainee=user, is_active=True)
        except Habit.DoesNotExist:
            return Response(
                {'error': 'Habit not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        log, created = HabitLog.objects.get_or_create(
            habit=habit,
            date=target_date,
            defaults={'trainee': user, 'completed': True},
        )
        if not created:
            log.completed = not log.completed
            log.save(update_fields=['completed'])

        return Response({
            'habit_id': habit.id,
            'date': str(target_date),
            'completed': log.completed,
        })

    @action(detail=False, methods=['get'], url_path='streaks')
    def streaks(self, request: Request) -> Response:
        """
        Get streak data for all active habits.
        GET /api/workouts/habits/streaks/
        """
        from .services.habit_service import calculate_streak

        user = cast(User, request.user)
        if user.is_trainee():
            habits = Habit.objects.filter(trainee=user, is_active=True)
        elif user.is_trainer():
            trainee_id = request.query_params.get('trainee_id')
            if not trainee_id:
                return Response(
                    {'error': 'trainee_id query parameter required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            habits = Habit.objects.filter(
                trainer=user, trainee_id=trainee_id, is_active=True,
            )
        else:
            return Response({'streaks': []})

        streaks = [calculate_streak(habit) for habit in habits]
        serializer = HabitStreakSerializer(
            [
                {
                    'habit_id': s.habit_id,
                    'habit_name': s.habit_name,
                    'current_streak': s.current_streak,
                    'longest_streak': s.longest_streak,
                    'completion_rate_30d': s.completion_rate_30d,
                }
                for s in streaks
            ],
            many=True,
        )
        return Response({'streaks': serializer.data})

    @action(detail=False, methods=['get'], url_path='daily')
    def daily(self, request: Request) -> Response:
        """
        Get today's habits with completion status.
        GET /api/workouts/habits/daily/?date=YYYY-MM-DD
        """
        from .services.habit_service import get_daily_habits

        user = cast(User, request.user)
        date_str = request.query_params.get('date')
        target_date = date.fromisoformat(date_str) if date_str else date.today()

        if user.is_trainee():
            trainee_id = user.id
        elif user.is_trainer():
            trainee_id_param = request.query_params.get('trainee_id')
            if not trainee_id_param:
                return Response(
                    {'error': 'trainee_id required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            trainee_id = int(trainee_id_param)
        else:
            return Response({'habits': []})

        habits = get_daily_habits(trainee_id, target_date)
        return Response({'habits': habits, 'date': str(target_date)})


# ============================================================
# Phase 3: Supersets, Smart Progression, Deload Detection
# ============================================================


class ProgressionSuggestionViewSet(viewsets.ReadOnlyModelViewSet[ProgressionSuggestion]):
    """
    ViewSet for viewing and managing progression suggestions.
    Read-only list/detail + custom actions for approve/dismiss/apply.
    """
    serializer_class = ProgressionSuggestionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[ProgressionSuggestion]:
        """Return suggestions for trainee's programs or trainer's trainees."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            return ProgressionSuggestion.objects.filter(
                trainee=user,
            ).select_related('exercise', 'trainee', 'program', 'reviewed_by')
        elif user.is_trainer():
            return ProgressionSuggestion.objects.filter(
                trainee__parent_trainer=user,
            ).select_related('exercise', 'trainee', 'program', 'reviewed_by')
        return ProgressionSuggestion.objects.none()

    @action(detail=True, methods=['post'], url_path='approve')
    def approve(self, request: Request, pk: int = None) -> Response:
        """Approve a progression suggestion."""
        suggestion = self.get_object()
        if suggestion.status != ProgressionSuggestion.Status.PENDING:
            return Response(
                {'error': f'Cannot approve suggestion with status {suggestion.status}'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        suggestion.status = ProgressionSuggestion.Status.APPROVED
        suggestion.reviewed_by = request.user
        suggestion.save(update_fields=['status', 'reviewed_by', 'updated_at'])
        return Response(ProgressionSuggestionSerializer(suggestion).data)

    @action(detail=True, methods=['post'], url_path='dismiss')
    def dismiss(self, request: Request, pk: int = None) -> Response:
        """Dismiss a progression suggestion."""
        suggestion = self.get_object()
        suggestion.status = ProgressionSuggestion.Status.DISMISSED
        suggestion.reviewed_by = request.user
        suggestion.save(update_fields=['status', 'reviewed_by', 'updated_at'])
        return Response(ProgressionSuggestionSerializer(suggestion).data)

    @action(detail=True, methods=['post'], url_path='apply')
    def apply_suggestion(self, request: Request, pk: int = None) -> Response:
        """Apply a progression suggestion to the program schedule."""
        from .services.progression_service import apply_suggestion

        suggestion = self.get_object()
        user = cast(User, request.user)

        try:
            apply_suggestion(suggestion, user.id)
        except ValueError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(ProgressionSuggestionSerializer(suggestion).data)


# ============================================================
# Phase 4: Check-In Forms
# ============================================================


class CheckInTemplateViewSet(viewsets.ModelViewSet[CheckInTemplate]):
    """
    ViewSet for check-in template CRUD.
    Trainers create and manage check-in forms.
    """
    serializer_class = CheckInTemplateSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[CheckInTemplate]:
        """Return templates created by the current trainer."""
        user = cast(User, self.request.user)
        if user.is_trainer():
            return CheckInTemplate.objects.filter(trainer=user).select_related('trainer')
        return CheckInTemplate.objects.none()

    def perform_create(self, serializer: BaseSerializer[CheckInTemplate]) -> None:
        """Set trainer to current user."""
        serializer.save(trainer=self.request.user)

    @action(detail=True, methods=['post'], url_path='assign')
    def assign(self, request: Request, pk: int = None) -> Response:
        """
        Assign a check-in template to a trainee.
        POST /api/workouts/checkin-templates/{id}/assign/
        Body: {trainee_id: int, next_due_date: "YYYY-MM-DD"}
        """
        template = self.get_object()
        serializer = CheckInAssignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = cast(User, request.user)
        trainee_id = serializer.validated_data['trainee_id']

        try:
            trainee = User.objects.get(
                id=trainee_id, role=User.Role.TRAINEE, parent_trainer=user,
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND,
            )

        assignment = CheckInAssignment.objects.create(
            template=template,
            trainee=trainee,
            next_due_date=serializer.validated_data['next_due_date'],
        )

        return Response(
            CheckInAssignmentSerializer(assignment).data,
            status=status.HTTP_201_CREATED,
        )


class CheckInResponseViewSet(viewsets.ModelViewSet[CheckInResponse]):
    """
    ViewSet for check-in responses.
    Trainees submit responses; trainers view and add notes.
    """
    serializer_class = CheckInResponseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[CheckInResponse]:
        """Return responses based on user role."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            return CheckInResponse.objects.filter(
                trainee=user,
            ).select_related('trainee', 'assignment__template')
        elif user.is_trainer():
            trainee_id = self.request.query_params.get('trainee_id')
            qs = CheckInResponse.objects.filter(
                assignment__template__trainer=user,
            ).select_related('trainee', 'assignment__template')
            if trainee_id:
                qs = qs.filter(trainee_id=trainee_id)
            return qs
        return CheckInResponse.objects.none()

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Submit a check-in response."""
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can submit check-in responses'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CheckInResponseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        assignment_id = serializer.validated_data['assignment_id']
        try:
            assignment = CheckInAssignment.objects.select_related('template').get(
                id=assignment_id, trainee=user, is_active=True,
            )
        except CheckInAssignment.DoesNotExist:
            return Response(
                {'error': 'Check-in assignment not found or inactive'},
                status=status.HTTP_404_NOT_FOUND,
            )

        response_obj = CheckInResponse.objects.create(
            assignment=assignment,
            trainee=user,
            responses=serializer.validated_data['responses'],
        )

        # Advance the next due date based on frequency
        freq = assignment.template.frequency
        if freq == CheckInTemplate.CheckInFrequency.WEEKLY:
            assignment.next_due_date += timedelta(days=7)
        elif freq == CheckInTemplate.CheckInFrequency.BIWEEKLY:
            assignment.next_due_date += timedelta(days=14)
        elif freq == CheckInTemplate.CheckInFrequency.MONTHLY:
            assignment.next_due_date += timedelta(days=30)
        assignment.save(update_fields=['next_due_date', 'updated_at'])

        return Response(
            CheckInResponseSerializer(response_obj).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'], url_path='add-notes')
    def add_notes(self, request: Request, pk: int = None) -> Response:
        """
        Trainer adds notes to a check-in response.
        POST /api/workouts/checkin-responses/{id}/add-notes/
        Body: {trainer_notes: "text"}
        """
        user = cast(User, request.user)
        if not user.is_trainer():
            return Response(
                {'error': 'Only trainers can add notes'},
                status=status.HTTP_403_FORBIDDEN,
            )

        response_obj = self.get_object()
        notes = request.data.get('trainer_notes', '')
        response_obj.trainer_notes = notes
        response_obj.save(update_fields=['trainer_notes', 'updated_at'])

        return Response(CheckInResponseSerializer(response_obj).data)

    @action(detail=False, methods=['get'], url_path='pending')
    def pending(self, request: Request) -> Response:
        """
        Get pending check-in assignments for a trainee.
        GET /api/workouts/checkin-responses/pending/
        """
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response({'assignments': []})

        today = date.today()
        assignments = CheckInAssignment.objects.filter(
            trainee=user,
            is_active=True,
            next_due_date__lte=today,
        ).select_related('template')

        return Response({
            'assignments': CheckInAssignmentSerializer(assignments, many=True).data,
        })


# ---------------------------------------------------------------
# Nutrition Template System (Phase 1)
# ---------------------------------------------------------------

from .services.nutrition_plan_service import NutritionPlanService


class NutritionTemplateViewSet(viewsets.ModelViewSet[NutritionTemplate]):
    """
    CRUD for NutritionTemplates.
    Trainers can create custom templates; system templates are read-only.
    """

    serializer_class = NutritionTemplateSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[NutritionTemplate]:
        user = cast(User, self.request.user)
        if user.is_admin():
            return NutritionTemplate.objects.all().select_related('created_by')
        if user.is_trainer():
            from django.db.models import Q
            return NutritionTemplate.objects.filter(
                Q(is_system=True) | Q(created_by=user),
            ).select_related('created_by')
        # Trainees can list templates (read-only)
        return NutritionTemplate.objects.filter(
            is_system=True,
        ).select_related('created_by')

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers can create nutrition templates.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = NutritionTemplateCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        template = NutritionTemplate.objects.create(
            name=serializer.validated_data['name'],
            template_type=serializer.validated_data['template_type'],
            ruleset=serializer.validated_data['ruleset'],
            created_by=user,
            is_system=False,
        )
        return Response(
            NutritionTemplateSerializer(template).data,
            status=status.HTTP_201_CREATED,
        )

    def update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        template = self.get_object()
        if template.is_system:
            return Response(
                {'error': 'System templates cannot be modified.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        template = self.get_object()
        if template.is_system:
            return Response(
                {'error': 'System templates cannot be deleted.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='system')
    def system_templates(self, request: Request) -> Response:
        """GET /api/workouts/nutrition-templates/system/ — list system templates only."""
        qs = NutritionTemplate.objects.filter(
            is_system=True,
        ).select_related('created_by')
        return Response(NutritionTemplateSerializer(qs, many=True).data)


class NutritionTemplateAssignmentViewSet(viewsets.ModelViewSet[NutritionTemplateAssignment]):
    """
    Assign / update / list template assignments for trainees.
    Trainers assign templates; trainees read their own.
    """

    serializer_class = NutritionTemplateAssignmentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[NutritionTemplateAssignment]:
        user = cast(User, self.request.user)
        qs = NutritionTemplateAssignment.objects.select_related(
            'trainee', 'template',
        )

        if user.is_trainee():
            return qs.filter(trainee=user)

        if user.is_trainer():
            qs = qs.filter(trainee__parent_trainer=user)
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                qs = qs.filter(trainee_id=trainee_id)
            return qs

        # Admin
        trainee_id = self.request.query_params.get('trainee_id')
        if trainee_id:
            qs = qs.filter(trainee_id=trainee_id)
        return qs

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers can assign nutrition templates.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = NutritionTemplateAssignmentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        trainee_id = serializer.validated_data['trainee_id']
        template_id = serializer.validated_data['template_id']

        # Verify trainee belongs to this trainer
        try:
            trainee = User.objects.get(pk=trainee_id, role=User.Role.TRAINEE)
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if user.is_trainer() and trainee.parent_trainer_id != user.pk:
            return Response(
                {'error': 'This trainee does not belong to you.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            template = NutritionTemplate.objects.get(pk=template_id)
        except NutritionTemplate.DoesNotExist:
            return Response(
                {'error': 'Template not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        assignment = NutritionTemplateAssignment(
            trainee=trainee,
            template=template,
            parameters=serializer.validated_data.get('parameters', {}),
            day_type_schedule=serializer.validated_data.get('day_type_schedule', {}),
            fat_mode=serializer.validated_data.get(
                'fat_mode',
                NutritionTemplateAssignment.FatMode.TOTAL_FAT,
            ),
            is_active=True,
        )
        assignment.save()

        return Response(
            NutritionTemplateAssignmentSerializer(assignment).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['get'], url_path='active')
    def active_assignment(self, request: Request) -> Response:
        """GET /api/workouts/nutrition-template-assignments/active/

        Returns the trainee's currently active template assignment.
        """
        user = cast(User, request.user)

        if user.is_trainee():
            trainee = user
        else:
            trainee_id = request.query_params.get('trainee_id')
            if not trainee_id:
                return Response(
                    {'error': 'trainee_id is required for trainers/admins.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            try:
                trainee = User.objects.get(pk=trainee_id, role=User.Role.TRAINEE)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Trainee not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if user.is_trainer() and trainee.parent_trainer_id != user.pk:
                return Response(
                    {'error': 'This trainee does not belong to you.'},
                    status=status.HTTP_403_FORBIDDEN,
                )

        assignment = NutritionTemplateAssignment.objects.filter(
            trainee=trainee, is_active=True,
        ).select_related('trainee', 'template').first()

        if not assignment:
            return Response(
                {'detail': 'No active nutrition template assignment.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(NutritionTemplateAssignmentSerializer(assignment).data)


class NutritionDayPlanViewSet(viewsets.ReadOnlyModelViewSet[NutritionDayPlan]):
    """
    Read-only ViewSet for NutritionDayPlans.
    Plans are auto-generated on read; trainers can override via PATCH.
    """

    serializer_class = NutritionDayPlanSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[NutritionDayPlan]:
        user = cast(User, self.request.user)

        if user.is_trainee():
            return NutritionDayPlan.objects.filter(
                trainee=user,
            ).select_related('trainee')

        if user.is_trainer():
            qs = NutritionDayPlan.objects.filter(
                trainee__parent_trainer=user,
            ).select_related('trainee')
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                qs = qs.filter(trainee_id=trainee_id)
            return qs

        # Admin
        return NutritionDayPlan.objects.all().select_related('trainee')

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """GET /api/workouts/nutrition-day-plans/?date=YYYY-MM-DD

        Auto-generates the plan if it doesn't exist yet.
        """
        user = cast(User, request.user)
        date_str = request.query_params.get('date')
        trainee_id = request.query_params.get('trainee_id')

        if date_str:
            try:
                target_date = date.fromisoformat(date_str)
            except ValueError:
                return Response(
                    {'error': 'Invalid date format. Use YYYY-MM-DD.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if user.is_trainee():
                trainee = user
            elif trainee_id:
                try:
                    trainee = User.objects.get(pk=trainee_id, role=User.Role.TRAINEE)
                except User.DoesNotExist:
                    return Response(
                        {'error': 'Trainee not found.'},
                        status=status.HTTP_404_NOT_FOUND,
                    )
            else:
                return Response(
                    {'error': 'trainee_id is required for trainers/admins.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            service = NutritionPlanService()
            plan = service.get_or_generate_day_plan(trainee, target_date)
            if plan is None:
                return Response(
                    {'detail': 'No nutrition template or goal configured.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            return Response(NutritionDayPlanSerializer(plan).data)

        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='week')
    def week(self, request: Request) -> Response:
        """GET /api/workouts/nutrition-day-plans/week/?start=YYYY-MM-DD"""
        user = cast(User, request.user)
        start_str = request.query_params.get('start')
        trainee_id = request.query_params.get('trainee_id')

        if not start_str:
            return Response(
                {'error': 'start query param is required (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            start_date = date.fromisoformat(start_str)
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use YYYY-MM-DD.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        end_date = start_date + timedelta(days=6)

        if user.is_trainee():
            trainee = user
        elif trainee_id:
            try:
                trainee = User.objects.get(pk=trainee_id, role=User.Role.TRAINEE)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Trainee not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
        else:
            return Response(
                {'error': 'trainee_id is required for trainers/admins.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        service = NutritionPlanService()
        plans = service.regenerate_plans_for_range(trainee, start_date, end_date)
        return Response(NutritionDayPlanSerializer(plans, many=True).data)

    @action(detail=True, methods=['patch'], url_path='override')
    def override(self, request: Request, pk: int = None) -> Response:
        """PATCH /api/workouts/nutrition-day-plans/{id}/override/

        Trainer manually overrides a day's macro plan.
        """
        user = cast(User, request.user)
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers can override day plans.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        plan = self.get_object()
        serializer = NutritionDayPlanOverrideSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        if 'total_protein' in data:
            plan.total_protein = data['total_protein']
        if 'total_carbs' in data:
            plan.total_carbs = data['total_carbs']
        if 'total_fat' in data:
            plan.total_fat = data['total_fat']
        if 'total_calories' in data:
            plan.total_calories = data['total_calories']
        if 'day_type' in data:
            plan.day_type = data['day_type']
        if 'meals' in data:
            plan.meals = data['meals']

        plan.is_overridden = True
        plan.save()

        return Response(NutritionDayPlanSerializer(plan).data)


# ---------------------------------------------------------------
# FoodItem & MealLog System (Phase 2)
# ---------------------------------------------------------------


class FoodItemPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class FoodItemViewSet(viewsets.ModelViewSet[FoodItem]):
    """
    CRUD for FoodItems.
    System items are read-only. Trainers can create custom food items.
    Search via ?search= query param.
    """

    serializer_class = FoodItemSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = FoodItemPagination

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action in ('create', 'update', 'partial_update'):
            return FoodItemCreateSerializer
        return FoodItemSerializer

    def get_queryset(self) -> QuerySet[FoodItem]:
        from django.db.models import Q

        user = cast(User, self.request.user)
        qs = FoodItem.objects.select_related('created_by')

        if user.is_admin():
            pass  # admin sees all
        elif user.is_trainer():
            qs = qs.filter(Q(is_public=True) | Q(created_by=user))
        elif user.is_trainee():
            # Trainee sees system foods + their trainer's custom foods
            qs = qs.filter(
                Q(is_public=True) | Q(created_by=user.parent_trainer),
            )
        else:
            qs = qs.filter(is_public=True)

        # Search filter
        search = self.request.query_params.get('search', '').strip()
        if search and len(search) >= 2:
            qs = qs.filter(
                Q(name__icontains=search) | Q(brand__icontains=search),
            )

        return qs

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers can create food items.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = FoodItemCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        food_item = FoodItem(
            created_by=user,
            is_public=False,
            **serializer.validated_data,
        )
        food_item.save()

        return Response(
            FoodItemSerializer(food_item).data,
            status=status.HTTP_201_CREATED,
        )

    def update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        food_item = self.get_object()
        user = cast(User, request.user)

        if food_item.is_public and not user.is_admin():
            return Response(
                {'error': 'System food items cannot be modified.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not food_item.is_public and food_item.created_by_id != user.pk and not user.is_admin():
            return Response(
                {'error': 'You can only modify your own food items.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().update(request, *args, **kwargs)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        food_item = self.get_object()
        user = cast(User, request.user)

        if food_item.is_public and not user.is_admin():
            return Response(
                {'error': 'System food items cannot be deleted.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not food_item.is_public and food_item.created_by_id != user.pk and not user.is_admin():
            return Response(
                {'error': 'You can only delete your own food items.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        from django.db.models import ProtectedError
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            return Response(
                {'error': 'Cannot delete this food item because it has been used in meal logs.'},
                status=status.HTTP_409_CONFLICT,
            )

    @action(detail=False, methods=['get'], url_path=r'barcode/(?P<barcode>[^/.]+)')
    def barcode_lookup(self, request: Request, barcode: str = '') -> Response:
        """GET /api/workouts/food-items/barcode/<barcode>/"""
        if not barcode.strip():
            return Response(
                {'error': 'Barcode is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from django.db.models import Q

        user = cast(User, request.user)
        qs = FoodItem.objects.filter(barcode=barcode.strip()).select_related('created_by')

        # Apply same visibility rules as get_queryset
        if user.is_trainer():
            qs = qs.filter(Q(is_public=True) | Q(created_by=user))
        elif user.is_trainee():
            qs = qs.filter(
                Q(is_public=True) | Q(created_by=user.parent_trainer),
            )
        elif not user.is_admin():
            qs = qs.filter(is_public=True)

        food_item = qs.first()
        if not food_item:
            return Response(
                {'error': 'No food item found for this barcode.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(FoodItemSerializer(food_item).data)

    @action(detail=False, methods=['get'], url_path='recent')
    def recent(self, request: Request) -> Response:
        """GET /api/workouts/food-items/recent/

        Returns recently used food items for the current user.
        """
        user = cast(User, request.user)

        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can access recent foods.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        from workouts.services.meal_log_service import get_recent_food_item_ids

        unique_ids = get_recent_food_item_ids(trainee=user, limit=20)

        food_items = FoodItem.objects.filter(
            id__in=unique_ids,
        ).select_related('created_by')

        # Preserve the recency order
        id_to_item = {item.id: item for item in food_items}
        ordered = [id_to_item[fid] for fid in unique_ids if fid in id_to_item]

        return Response(FoodItemSerializer(ordered, many=True).data)


class MealLogPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 50


class MealLogViewSet(
    viewsets.mixins.ListModelMixin,
    viewsets.mixins.RetrieveModelMixin,
    viewsets.mixins.DestroyModelMixin,
    viewsets.GenericViewSet[MealLog],
):
    """
    List/retrieve/destroy MealLogs with nested entries.
    Creation is handled exclusively via the quick-add action.
    Trainees manage their own meals; trainers can view their trainees' meals.
    """

    serializer_class = MealLogSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = MealLogPagination

    def get_queryset(self) -> QuerySet[MealLog]:
        user = cast(User, self.request.user)
        qs = MealLog.objects.prefetch_related(
            'entries', 'entries__food_item',
        )

        if user.is_trainee():
            qs = qs.filter(trainee=user)
        elif user.is_trainer():
            qs = qs.filter(trainee__parent_trainer=user)
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                qs = qs.filter(trainee_id=trainee_id)
        elif user.is_admin():
            trainee_id = self.request.query_params.get('trainee_id')
            if trainee_id:
                qs = qs.filter(trainee_id=trainee_id)
        else:
            return qs.none()

        # Date filter
        date_str = self.request.query_params.get('date')
        if date_str:
            try:
                target_date = date.fromisoformat(date_str)
                qs = qs.filter(date=target_date)
            except ValueError:
                logger.warning("Invalid date format in meal-logs query: %s", date_str)
                # Return empty queryset for invalid date
                qs = qs.none()

        return qs

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request: Request) -> Response:
        """GET /api/workouts/meal-logs/summary/?date=YYYY-MM-DD

        Returns aggregated daily macro totals from structured MealLog entries.
        Note: Legacy DailyLog.nutrition_data is available separately via
        the existing /daily-logs/nutrition-summary/ endpoint. The mobile client
        can merge both sources if the trainee has data in both systems.
        """
        user = cast(User, request.user)
        date_str = request.query_params.get('date')

        if not date_str:
            return Response(
                {'error': 'date query param is required (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            target_date = date.fromisoformat(date_str)
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use YYYY-MM-DD.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if user.is_trainee():
            trainee = user
        else:
            trainee_id = request.query_params.get('trainee_id')
            if not trainee_id:
                return Response(
                    {'error': 'trainee_id is required for trainers/admins.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            try:
                trainee = User.objects.get(pk=trainee_id, role=User.Role.TRAINEE)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Trainee not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if user.is_trainer() and trainee.parent_trainer_id != user.pk:
                return Response(
                    {'error': 'This trainee does not belong to you.'},
                    status=status.HTTP_403_FORBIDDEN,
                )

        from dataclasses import asdict

        from workouts.services.meal_log_service import get_daily_summary

        summary = get_daily_summary(trainee=trainee, target_date=target_date)
        return Response(MealLogSummarySerializer(asdict(summary)).data)

    @action(detail=False, methods=['post'], url_path='quick-add')
    def quick_add(self, request: Request) -> Response:
        """POST /api/workouts/meal-logs/quick-add/

        Quick-add a food entry. Auto-creates MealLog if needed.
        """
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can log meals.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        from workouts.services.meal_log_service import (
            FoodItemNotFoundError,
            quick_add_entry,
        )

        serializer = QuickAddEntrySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            result = quick_add_entry(
                trainee=user,
                target_date=data['date'],
                meal_number=data['meal_number'],
                meal_name=data.get('meal_name', ''),
                food_item_id=data.get('food_item_id'),
                custom_name=data.get('custom_name', ''),
                quantity=data.get('quantity', 1.0),
                serving_unit=data.get('serving_unit', FoodItem.ServingUnit.SERVING),
                calories=data.get('calories', 0),
                protein=data.get('protein', 0),
                carbs=data.get('carbs', 0),
                fat=data.get('fat', 0),
                fat_mode=data.get('fat_mode', MealLogEntry.FatMode.TOTAL_FAT),
            )
        except FoodItemNotFoundError:
            return Response(
                {'error': 'Food item not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Return the full meal log with all entries
        meal_log_refreshed = MealLog.objects.prefetch_related(
            'entries', 'entries__food_item',
        ).get(pk=result.meal_log.pk)

        return Response(
            MealLogSerializer(meal_log_refreshed).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['delete'], url_path=r'entries/(?P<entry_id>\d+)')
    def delete_entry(self, request: Request, entry_id: str = '') -> Response:
        """DELETE /api/workouts/meal-logs/entries/<entry_id>/"""
        user = cast(User, request.user)

        try:
            entry = MealLogEntry.objects.select_related(
                'meal_log', 'meal_log__trainee',
            ).get(pk=entry_id)
        except MealLogEntry.DoesNotExist:
            return Response(
                {'error': 'Entry not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Permission check
        if user.is_trainee() and entry.meal_log.trainee_id != user.pk:
            return Response(
                {'error': 'You can only delete your own entries.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if user.is_trainer() and entry.meal_log.trainee.parent_trainer_id != user.pk:
            return Response(
                {'error': 'This trainee does not belong to you.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        entry.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

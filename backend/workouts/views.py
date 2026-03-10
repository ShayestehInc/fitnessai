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
from dataclasses import replace
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Any, cast

from core.permissions import IsTrainee
from rest_framework.exceptions import PermissionDenied

from users.models import User
from .models import (
    CheckInAssignment,
    CheckInResponse,
    CheckInTemplate,
    DailyLog,
    DecisionLog,
    Exercise,
    FoodItem,
    Habit,
    HabitLog,
    LiftMax,
    LiftSetLog,
    MacroPreset,
    PlanSession,
    PlanSlot,
    PlanWeek,
    ProgressionProfile,
    SplitTemplate,
    TrainingPlan,
    WorkloadFactTemplate,
    MealLog,
    MealLogEntry,
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
    ProgressionSuggestion,
    ProgressPhoto,
    SetStructureModality,
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
    DecisionLogSerializer,
    LiftMaxPrescribeSerializer,
    LiftMaxSerializer,
    LiftSetLogSerializer,
    WorkloadFactTemplateSerializer,
    FoodItemCreateSerializer,
    FoodItemSerializer,
    GeneratePlanSerializer,
    MealLogEntrySerializer,
    MealLogSerializer,
    MealLogSummarySerializer,
    PlanSessionSerializer,
    PlanSlotSerializer,
    PlanSlotWriteSerializer,
    QuickAddEntrySerializer,
    SplitTemplateSerializer,
    SwapExecuteSerializer,
    TrainingPlanCreateSerializer,
    TrainingPlanListSerializer,
    TrainingPlanSerializer,
    ProgressionProfileSerializer,
    ProgressionProfileListSerializer,
    ProgressionEventSerializer,
    ApplyProgressionInputSerializer,
)
from core.permissions import IsTrainer as IsTrainerPerm

from .services.daily_log_service import DailyLogService
from .services.decision_log_service import DecisionLogService
from .services.max_load_service import MaxLoadService
from .services.natural_language_parser import NaturalLanguageParserService
from .services.progression_engine_service import NextPrescription
from .services.workload_service import WorkloadAggregationService, WorkloadTrendService


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

        queryset = queryset.select_related('created_by')

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

        # v6.5 tag-based filters
        pattern_tags = self.request.query_params.get('pattern_tags')
        if pattern_tags:
            tag_list = [t.strip() for t in pattern_tags.split(',') if t.strip()]
            queryset = queryset.filter(pattern_tags__overlap=tag_list)

        stance = self.request.query_params.get('stance')
        if stance:
            valid_stances = {c[0] for c in Exercise.Stance.choices}
            if stance in valid_stances:
                queryset = queryset.filter(stance=stance)
            else:
                return queryset.none()

        plane = self.request.query_params.get('plane')
        if plane:
            valid_planes = {c[0] for c in Exercise.Plane.choices}
            if plane in valid_planes:
                queryset = queryset.filter(plane=plane)
            else:
                return queryset.none()

        rom_bias = self.request.query_params.get('rom_bias')
        if rom_bias:
            valid_biases = {c[0] for c in Exercise.RomBias.choices}
            if rom_bias in valid_biases:
                queryset = queryset.filter(rom_bias=rom_bias)
            else:
                return queryset.none()

        primary_muscle = self.request.query_params.get('primary_muscle_group')
        if primary_muscle:
            valid_muscles = {c[0] for c in Exercise.DetailedMuscleGroup.choices}
            if primary_muscle in valid_muscles:
                queryset = queryset.filter(primary_muscle_group=primary_muscle)
            else:
                return queryset.none()

        equipment = self.request.query_params.get('equipment_required')
        if equipment:
            eq_list = [e.strip() for e in equipment.split(',') if e.strip()]
            queryset = queryset.filter(equipment_required__contains=eq_list)

        return queryset.order_by('muscle_group', 'name')

    def perform_create(self, serializer: BaseSerializer[Exercise]) -> None:
        """Only trainers (custom) and admins (public) can create exercises."""
        user = cast(User, self.request.user)
        if user.is_trainer():
            serializer.save(created_by=user, is_public=False)
        elif user.is_admin():
            serializer.save(is_public=True)
        else:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only trainers and admins can create exercises.")

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
        new_achievements: list[object] = []
        try:
            from community.services.achievement_service import check_and_award_achievements
            new_achievements = check_and_award_achievements(user, 'nutrition_logged')
        except Exception:
            logger.exception("Achievement check failed after nutrition save for user %s", user.id)

        # Return saved log with any new achievements
        log_serializer = DailyLogSerializer(daily_log)
        response_data = dict(log_serializer.data)
        if new_achievements:
            from community.serializers import NewAchievementSerializer
            response_data['new_achievements'] = NewAchievementSerializer(
                new_achievements, many=True,
            ).data

        return Response(
            response_data,
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

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Create weight check-in, check achievements, and include new badges in response."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = cast(User, request.user)
        new_achievements: list[object] = []

        if user.is_trainee():
            serializer.save(trainee=user)
            try:
                from community.services.achievement_service import check_and_award_achievements
                new_achievements = check_and_award_achievements(user, 'weight_checkin')
            except Exception:
                logger.exception("Achievement check failed after weight check-in for user %s", user.id)
        else:
            serializer.save()

        response_data = dict(serializer.data)
        if new_achievements:
            from community.serializers import NewAchievementSerializer
            response_data['new_achievements'] = NewAchievementSerializer(
                new_achievements, many=True,
            ).data

        headers = self.get_success_headers(response_data)
        return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)

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


class ProgressPhotoPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 50


class ProgressPhotoViewSet(viewsets.ModelViewSet[ProgressPhoto]):
    """
    ViewSet for progress photo CRUD.
    Trainees manage their own photos. Trainers have read-only access to
    their trainees' photos.

    Query parameters:
    - category: Filter by photo category (front, side, back, other)
    - date_from: Filter photos from this date (YYYY-MM-DD)
    - date_to: Filter photos until this date (YYYY-MM-DD)
    - trainee_id: (Trainer only) Filter by specific trainee
    - page: Page number for pagination
    """
    serializer_class = ProgressPhotoSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    pagination_class = ProgressPhotoPagination

    def get_queryset(self) -> QuerySet[ProgressPhoto]:
        """Return photos filtered by user role and query parameters."""
        user = cast(User, self.request.user)
        if user.is_trainee():
            qs = ProgressPhoto.objects.filter(trainee=user).select_related('trainee')
        elif user.is_trainer():
            trainee_id_str = self.request.query_params.get('trainee_id')
            if trainee_id_str:
                try:
                    trainee_id_int = int(trainee_id_str)
                except ValueError:
                    return ProgressPhoto.objects.none()
                qs = ProgressPhoto.objects.filter(
                    trainee_id=trainee_id_int,
                    trainee__parent_trainer=user,
                ).select_related('trainee')
            else:
                qs = ProgressPhoto.objects.filter(
                    trainee__parent_trainer=user,
                ).select_related('trainee')
        elif user.is_admin():
            trainee_id_str = self.request.query_params.get('trainee_id')
            if trainee_id_str:
                try:
                    trainee_id_int = int(trainee_id_str)
                except ValueError:
                    return ProgressPhoto.objects.none()
                qs = ProgressPhoto.objects.filter(
                    trainee_id=trainee_id_int,
                ).select_related('trainee')
            else:
                qs = ProgressPhoto.objects.all().select_related('trainee')
        else:
            return ProgressPhoto.objects.none()

        # Apply optional filters.
        category = self.request.query_params.get('category')
        if category and category in ProgressPhoto.PhotoCategory.values:
            qs = qs.filter(category=category)

        date_from = self.request.query_params.get('date_from')
        if date_from:
            try:
                datetime.strptime(date_from, '%Y-%m-%d')
                qs = qs.filter(date__gte=date_from)
            except ValueError:
                pass  # Ignore invalid date — returns unfiltered

        date_to = self.request.query_params.get('date_to')
        if date_to:
            try:
                datetime.strptime(date_to, '%Y-%m-%d')
                qs = qs.filter(date__lte=date_to)
            except ValueError:
                pass

        return qs

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        """Only trainees can create progress photos."""
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can upload progress photos.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().create(request, *args, **kwargs)

    def update(self, request: Request, *args: object, **kwargs: object) -> Response:
        """Only trainees can update their own photos."""
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can update progress photos.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request: Request, *args: object, **kwargs: object) -> Response:
        """Only trainees can delete their own photos."""
        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can delete progress photos.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer: BaseSerializer[ProgressPhoto]) -> None:
        """Set trainee to current user."""
        serializer.save(trainee=self.request.user)

    def perform_destroy(self, instance: ProgressPhoto) -> None:
        """Delete the photo file from storage before removing the DB record."""
        if instance.photo and instance.photo.name:
            try:
                default_storage.delete(instance.photo.name)
            except Exception:
                logger.warning(
                    "Failed to delete photo file %s for ProgressPhoto %d",
                    instance.photo.name,
                    instance.pk,
                )
        instance.delete()

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

        try:
            photo1_int = int(photo1_id)
            photo2_int = int(photo2_id)
        except ValueError:
            return Response(
                {'error': 'photo1 and photo2 must be valid integer IDs'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        queryset = self.get_queryset()
        photos = list(queryset.filter(id__in=[photo1_int, photo2_int]))
        if len(photos) != 2:
            return Response(
                {'error': 'One or both photos not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Ensure consistent order: photo1 first, photo2 second.
        photos.sort(key=lambda p: (p.id != photo1_int, p.id))

        serializer = ProgressPhotoSerializer(
            photos, many=True, context={'request': request},
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

        # Scope template lookup: trainers can only use system templates or their own
        template_qs = NutritionTemplate.objects.all()
        if user.is_trainer():
            from django.db.models import Q
            template_qs = template_qs.filter(
                Q(is_system=True) | Q(created_by=user),
            )

        try:
            template = template_qs.get(pk=template_id)
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

    @action(detail=True, methods=['post'], url_path='recalculate')
    def recalculate(self, request: Request, pk: Any = None) -> Response:
        """POST /api/workouts/nutrition-template-assignments/<id>/recalculate/

        Regenerate day plans for the next 7 days after a parameter change.
        Only the assignment owner (trainer) or admin can trigger this.
        """
        user = cast(User, request.user)
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers or admins can recalculate.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            assignment = self.get_queryset().get(pk=pk)
        except NutritionTemplateAssignment.DoesNotExist:
            return Response(
                {'error': 'Assignment not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from workouts.services.nutrition_plan_service import NutritionPlanService

        svc = NutritionPlanService()
        today = date.today()
        end_date = today + timedelta(days=6)
        plans = svc.regenerate_plans_for_range(
            trainee=assignment.trainee,
            start_date=today,
            end_date=end_date,
        )

        return Response({
            'recalculated': len(plans),
            'start_date': today.isoformat(),
            'end_date': end_date.isoformat(),
        })


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
                if user.is_trainer() and trainee.parent_trainer_id != user.pk:
                    return Response(
                        {'error': 'You do not have access to this trainee.'},
                        status=status.HTTP_403_FORBIDDEN,
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
            if user.is_trainer() and trainee.parent_trainer_id != user.pk:
                return Response(
                    {'error': 'You do not have access to this trainee.'},
                    status=status.HTTP_403_FORBIDDEN,
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

    @action(detail=True, methods=['get'], url_path='swaps')
    def swaps(self, request: Request, pk: str | None = None) -> Response:
        """GET /api/workouts/food-items/{id}/swaps/?mode=same_macros&limit=10

        Returns food swap recommendations for this food item.
        """
        from workouts.services.food_swap_service import get_food_swaps

        user = cast(User, request.user)
        mode = request.query_params.get('mode', 'same_macros')
        try:
            limit = int(request.query_params.get('limit', '10'))
        except ValueError:
            limit = 10
        limit = min(max(limit, 1), 50)

        try:
            result = get_food_swaps(
                food_item_id=int(pk),  # type: ignore[arg-type]
                mode=mode,
                limit=limit,
                user=user,
                actor_id=user.pk,
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'source_food_id': result.source_food_id,
            'source_food_name': result.source_food_name,
            'mode': result.mode,
            'candidates': [
                {
                    'food_item_id': c.food_item_id,
                    'name': c.name,
                    'brand': c.brand,
                    'calories': c.calories,
                    'protein': c.protein,
                    'carbs': c.carbs,
                    'fat': c.fat,
                    'serving_size': c.serving_size,
                    'serving_unit': c.serving_unit,
                    'similarity_score': c.similarity_score,
                    'match_reason': c.match_reason,
                }
                for c in result.candidates
            ],
        })


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

    @action(detail=False, methods=['post'], url_path=r'entries/(?P<entry_id>\d+)/swap')
    def swap_entry(self, request: Request, entry_id: str = '') -> Response:
        """POST /api/workouts/meal-logs/entries/<entry_id>/swap/

        Execute a food swap: replace the entry's food with a new one.
        Body: {"new_food_item_id": 123, "quantity": 1.5}
        """
        from workouts.services.food_swap_service import execute_food_swap

        user = cast(User, request.user)
        if not user.is_trainee():
            return Response(
                {'error': 'Only trainees can swap food entries.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        new_food_item_id = request.data.get('new_food_item_id')
        if not new_food_item_id:
            return Response(
                {'error': 'new_food_item_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        quantity = request.data.get('quantity')
        if quantity is not None:
            try:
                quantity = float(quantity)
            except (TypeError, ValueError):
                return Response(
                    {'error': 'quantity must be a number.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        try:
            result = execute_food_swap(
                entry_id=int(entry_id),
                new_food_item_id=int(new_food_item_id),
                quantity=quantity,
                user=user,
                actor_id=user.pk,
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'entry_id': result.entry_id,
            'old_food_name': result.old_food_name,
            'new_food_name': result.new_food_name,
            'old_macros': result.old_macros,
            'new_macros': result.new_macros,
            'undo_snapshot_id': result.undo_snapshot_id,
        })


class DecisionLogPagination(PageNumberPagination):
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 200


class DecisionLogViewSet(viewsets.ReadOnlyModelViewSet[DecisionLog]):
    """
    Read-only ViewSet for DecisionLog entries (v6.5 audit trail).

    Trainers see decisions they made + decisions about their trainees.
    Admins see all. Trainees see only decisions where they are the actor.

    Filtering: ?decision_type=, ?actor_type=, ?date_from=, ?date_to=
    Undo action: POST /api/workouts/decision-logs/{id}/undo/
    """
    serializer_class = DecisionLogSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = DecisionLogPagination

    def get_queryset(self) -> QuerySet[DecisionLog]:
        user = cast(User, self.request.user)

        if user.is_admin():
            queryset = DecisionLog.objects.all()
        elif user.is_trainer():
            # Trainer sees: decisions they made + decisions about their trainees
            # Uses subquery to avoid materializing all trainee IDs into memory
            trainee_subquery = User.objects.filter(
                parent_trainer=user
            ).values('id')
            queryset = DecisionLog.objects.filter(
                models.Q(actor=user)
                | models.Q(actor_id__in=trainee_subquery)
            )
        else:
            # Trainee sees ONLY decisions where they are the actor
            queryset = DecisionLog.objects.filter(actor=user)

        queryset = queryset.select_related('actor', 'undo_snapshot')

        # Filters with validation
        decision_type = self.request.query_params.get('decision_type')
        if decision_type:
            queryset = queryset.filter(decision_type=decision_type)

        actor_type = self.request.query_params.get('actor_type')
        if actor_type:
            valid_actor_types = {c[0] for c in DecisionLog.ActorType.choices}
            if actor_type in valid_actor_types:
                queryset = queryset.filter(actor_type=actor_type)
            else:
                return queryset.none()

        date_from = self.request.query_params.get('date_from')
        if date_from:
            try:
                parsed = datetime.strptime(date_from, '%Y-%m-%d').date()
                queryset = queryset.filter(timestamp__date__gte=parsed)
            except ValueError:
                return queryset.none()

        date_to = self.request.query_params.get('date_to')
        if date_to:
            try:
                parsed = datetime.strptime(date_to, '%Y-%m-%d').date()
                queryset = queryset.filter(timestamp__date__lte=parsed)
            except ValueError:
                return queryset.none()

        return queryset.order_by('-timestamp')

    @action(detail=True, methods=['post'], url_path='undo')
    def undo(self, request: Request, pk: str | None = None) -> Response:
        """
        Mark a decision as reverted and return the before_state for the caller to apply.

        POST /api/workouts/decision-logs/{id}/undo/

        Returns the before_state so the caller (frontend or service) can apply
        the actual state restoration. The undo itself is logged as a new DecisionLog.

        NOTE: This endpoint does NOT automatically restore domain objects. The caller
        must use the returned before_state to update the relevant objects. This is by
        design — different decision types require different restoration logic.
        """
        user = cast(User, request.user)

        # Only trainers and admins can undo
        if not (user.is_trainer() or user.is_admin()):
            return Response(
                {'error': 'Only trainers and admins can undo decisions.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            from uuid import UUID
            decision_uuid = UUID(str(pk))
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid decision ID format.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # IDOR protection: verify the decision is within the user's queryset scope
        if not self.get_queryset().filter(id=decision_uuid).exists():
            return Response(
                {'error': 'Decision not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            result = DecisionLogService.undo_decision(
                decision_id=decision_uuid,
                actor=user,
            )
        except ValueError as e:
            error_msg = str(e)
            if "already been reverted" in error_msg:
                return Response(
                    {'error': error_msg},
                    status=status.HTTP_409_CONFLICT,
                )
            return Response(
                {'error': error_msg},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                'message': 'Decision marked as reverted.',
                'undo_decision_id': str(result.decision_id),
                'before_state': result.before_state,
            },
            status=status.HTTP_200_OK,
        )


class LiftSetLogPagination(PageNumberPagination):
    page_size = 50
    max_page_size = 200


class LiftSetLogViewSet(
    viewsets.GenericViewSet[LiftSetLog],
    viewsets.mixins.CreateModelMixin,
    viewsets.mixins.ListModelMixin,
    viewsets.mixins.RetrieveModelMixin,
):
    """
    Create + Read-only ViewSet for per-set performance tracking (v6.5 Step 3).

    Set logs are historical records — no update or delete to preserve audit integrity.
    Trainees create their own set logs.
    Trainers can read their trainees' set logs.
    Admins can read all.

    Filtering: ?exercise_id=, ?session_date=, ?date_from=, ?date_to=, ?trainee_id= (trainer/admin)
    """
    serializer_class = LiftSetLogSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = LiftSetLogPagination

    def get_queryset(self) -> QuerySet[LiftSetLog]:
        user = cast(User, self.request.user)

        if user.is_admin():
            queryset = LiftSetLog.objects.all()
        elif user.is_trainer():
            trainee_subquery = User.objects.filter(
                parent_trainer=user
            ).values('id')
            queryset = LiftSetLog.objects.filter(trainee_id__in=trainee_subquery)
        else:
            queryset = LiftSetLog.objects.filter(trainee=user)

        queryset = queryset.select_related('exercise', 'trainee')

        # Filters
        exercise_id = self.request.query_params.get('exercise_id')
        if exercise_id:
            queryset = queryset.filter(exercise_id=exercise_id)

        session_date = self.request.query_params.get('session_date')
        if session_date:
            try:
                parsed = datetime.strptime(session_date, '%Y-%m-%d').date()
                queryset = queryset.filter(session_date=parsed)
            except ValueError:
                return queryset.none()

        date_from = self.request.query_params.get('date_from')
        if date_from:
            try:
                parsed = datetime.strptime(date_from, '%Y-%m-%d').date()
                queryset = queryset.filter(session_date__gte=parsed)
            except ValueError:
                return queryset.none()

        date_to = self.request.query_params.get('date_to')
        if date_to:
            try:
                parsed = datetime.strptime(date_to, '%Y-%m-%d').date()
                queryset = queryset.filter(session_date__lte=parsed)
            except ValueError:
                return queryset.none()

        # Trainer/admin can filter by trainee
        trainee_id = self.request.query_params.get('trainee_id')
        if trainee_id and (user.is_trainer() or user.is_admin()):
            queryset = queryset.filter(trainee_id=trainee_id)

        return queryset.order_by('-session_date', 'set_number')

    def perform_create(self, serializer: BaseSerializer[LiftSetLog]) -> None:
        user = cast(User, self.request.user)
        if not user.is_trainee():
            raise serializers.ValidationError(
                "Only trainees can log sets."
            )
        set_log = serializer.save(trainee=user)
        # Auto-update LiftMax if set qualifies
        MaxLoadService.update_max_from_set(set_log)


class LiftMaxPagination(PageNumberPagination):
    page_size = 50
    max_page_size = 200


class LiftMaxViewSet(viewsets.ReadOnlyModelViewSet[LiftMax]):
    """
    Read-only ViewSet for cached estimated maxes (v6.5 Step 3).

    Trainees see their own maxes.
    Trainers see their trainees' maxes.
    Admins see all.

    Custom actions:
    - GET /history/?exercise_id= — e1RM history for charting
    - POST /prescribe/ — get recommended load for exercise+target
    """
    serializer_class = LiftMaxSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = LiftMaxPagination

    def get_queryset(self) -> QuerySet[LiftMax]:
        user = cast(User, self.request.user)

        if user.is_admin():
            queryset = LiftMax.objects.all()
        elif user.is_trainer():
            trainee_subquery = User.objects.filter(
                parent_trainer=user
            ).values('id')
            queryset = LiftMax.objects.filter(trainee_id__in=trainee_subquery)
        else:
            queryset = LiftMax.objects.filter(trainee=user)

        queryset = queryset.select_related('exercise', 'trainee')

        # Optional trainee filter for trainers/admins
        trainee_id = self.request.query_params.get('trainee_id')
        if trainee_id and (user.is_trainer() or user.is_admin()):
            queryset = queryset.filter(trainee_id=trainee_id)

        return queryset.order_by('exercise__name')

    @action(detail=False, methods=['get'], url_path='history')
    def history(self, request: Request) -> Response:
        """
        GET /api/workouts/lift-maxes/history/?exercise_id=123

        Returns the e1RM history array for a specific exercise, for charting.
        """
        exercise_id = request.query_params.get('exercise_id')
        if not exercise_id:
            return Response(
                {'error': 'exercise_id query parameter is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        lift_max = self.get_queryset().filter(exercise_id=exercise_id).first()
        if not lift_max:
            return Response(
                {'error': 'No max data found for this exercise.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({
            'exercise_id': lift_max.exercise_id,
            'exercise_name': lift_max.exercise.name,
            'e1rm_history': lift_max.e1rm_history,
            'tm_history': lift_max.tm_history,
        })

    @action(detail=False, methods=['post'], url_path='prescribe')
    def prescribe(self, request: Request) -> Response:
        """
        POST /api/workouts/lift-maxes/prescribe/

        Get recommended load for a given exercise and target percentage.
        Request body: {exercise_id, target_percentage, rounding_increment?}
        """
        serializer = LiftMaxPrescribeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = cast(User, request.user)
        exercise_id = serializer.validated_data['exercise_id']
        target_percentage = serializer.validated_data['target_percentage']
        rounding_increment = serializer.validated_data.get(
            'rounding_increment', Decimal("2.5")
        )

        # Determine the trainee
        if user.is_trainee():
            trainee = user
        else:
            trainee_id = serializer.validated_data.get('trainee_id')
            if not trainee_id:
                return Response(
                    {'error': 'trainee_id is required for trainers/admins.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            try:
                trainee = User.objects.get(id=trainee_id, role='TRAINEE')
            except User.DoesNotExist:
                return Response(
                    {'error': 'Trainee not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            # Row-level security: trainer can only prescribe for their trainees
            if user.is_trainer() and trainee.parent_trainer_id != user.id:
                return Response(
                    {'error': 'Trainee not found.'},
                    status=status.HTTP_404_NOT_FOUND,
                )

        try:
            prescription = MaxLoadService.prescribe_for_trainee(
                trainee_id=trainee.id,
                exercise_id=exercise_id,
                target_percentage=target_percentage,
                rounding_increment=rounding_increment,
            )
        except LiftMax.DoesNotExist:
            return Response({
                'prescribed_load': None,
                'reason': 'No training max available for this exercise. '
                          'Log qualifying sets to build an estimated max.',
            })

        return Response({
            'prescribed_load': str(prescription.prescribed_load) if prescription.prescribed_load else None,
            'unit': prescription.unit,
            'based_on_tm': str(prescription.based_on_tm),
            'target_percentage': str(prescription.target_percentage),
            'rounding_increment': str(prescription.rounding_increment),
            'exercise_id': prescription.exercise_id,
            'exercise_name': prescription.exercise_name,
            'reason': prescription.reason,
        })


# ---------------------------------------------------------------------------
# Workload Engine ViewSets (v6.5 Step 4)
# ---------------------------------------------------------------------------

class WorkloadFactTemplateViewSet(viewsets.ModelViewSet[WorkloadFactTemplate]):
    """
    CRUD for workload fact templates.

    Trainers manage their own templates. Admins manage all.
    System defaults (created_by=null) are visible to everyone.
    """
    serializer_class = WorkloadFactTemplateSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[WorkloadFactTemplate]:
        user = cast(User, self.request.user)

        if user.is_admin():
            return WorkloadFactTemplate.objects.all()
        elif user.is_trainer():
            # Trainer sees system defaults + their own
            return WorkloadFactTemplate.objects.filter(
                Q(created_by__isnull=True) | Q(created_by=user)
            )
        else:
            # Trainees can read but not modify — see system defaults + their trainer's
            if user.parent_trainer_id is not None:
                return WorkloadFactTemplate.objects.filter(
                    Q(created_by__isnull=True) | Q(created_by_id=user.parent_trainer_id)
                )
            return WorkloadFactTemplate.objects.filter(created_by__isnull=True)

    def perform_create(self, serializer: BaseSerializer[WorkloadFactTemplate]) -> None:
        user = cast(User, self.request.user)
        if user.is_trainee():
            raise PermissionDenied("Only trainers and admins can create fact templates.")
        serializer.save(created_by=user)

    def perform_update(self, serializer: BaseSerializer[WorkloadFactTemplate]) -> None:
        user = cast(User, self.request.user)
        if user.is_trainee():
            raise PermissionDenied("Only trainers and admins can update fact templates.")
        instance = serializer.instance
        if not user.is_admin() and instance and instance.created_by_id != user.id:
            raise PermissionDenied("You can only edit your own templates.")
        serializer.save()

    def perform_destroy(self, instance: WorkloadFactTemplate) -> None:
        user = cast(User, self.request.user)
        if user.is_trainee():
            raise PermissionDenied("Only trainers and admins can delete fact templates.")
        if not user.is_admin() and instance.created_by_id != user.id:
            raise PermissionDenied("You can only delete your own templates.")
        instance.delete()


class WorkloadViewSet(viewsets.ViewSet):
    """
    Workload aggregation and trend endpoints (v6.5 Step 4).

    All endpoints are read-only computations from LiftSetLog data.
    Row-level security: trainees see own data, trainers see their trainees'.

    Endpoints:
    - GET /exercise/?exercise_id=&session_date=&trainee_id= — exercise workload
    - GET /session/?session_date=&trainee_id= — session workload summary
    - GET /weekly/?week_start=&trainee_id= — weekly workload with breakdowns
    - GET /trends/?trainee_id=&weeks_back= — trend data with ACWR
    """
    permission_classes = [IsAuthenticated]

    def _resolve_trainee(self, request: Request) -> User | None:
        """Resolve the trainee for workload computation, enforcing row-level security."""
        user = cast(User, request.user)

        if user.is_trainee():
            return user

        trainee_id = request.query_params.get('trainee_id')
        if not trainee_id:
            return None

        try:
            trainee = User.objects.get(id=int(trainee_id), role='TRAINEE')
        except (User.DoesNotExist, ValueError):
            return None

        # Row-level security: trainer can only see their own trainees
        if user.is_trainer() and trainee.parent_trainer_id != user.id:
            return None

        return trainee

    @action(detail=False, methods=['get'], url_path='exercise')
    def exercise(self, request: Request) -> Response:
        """GET /api/workouts/workload/exercise/?exercise_id=&session_date=&trainee_id="""
        trainee = self._resolve_trainee(request)
        if trainee is None:
            return Response(
                {'error': 'trainee_id is required (or invalid).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        exercise_id = request.query_params.get('exercise_id')
        session_date_str = request.query_params.get('session_date')

        if not exercise_id or not session_date_str:
            return Response(
                {'error': 'exercise_id and session_date are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            parsed_date = datetime.strptime(session_date_str, '%Y-%m-%d').date()
            exercise_id_int = int(exercise_id)
        except ValueError:
            return Response(
                {'error': 'Invalid exercise_id or session_date format (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = WorkloadAggregationService.compute_exercise_workload(
            trainee_id=trainee.id,
            exercise_id=exercise_id_int,
            session_date=parsed_date,
            trainer_id=trainee.parent_trainer_id,
        )

        return Response({
            'exercise_id': result.exercise_id,
            'exercise_name': result.exercise_name,
            'session_date': str(result.session_date),
            'total_workload': str(result.total_workload),
            'unit': result.unit,
            'mixed_units': result.mixed_units,
            'set_count': result.set_count,
            'rep_total': result.rep_total,
            'comparison_delta': str(result.comparison_delta) if result.comparison_delta is not None else None,
            'comparison_date': str(result.comparison_date) if result.comparison_date else None,
            'fact_text': result.fact_text,
        })

    @action(detail=False, methods=['get'], url_path='session')
    def session(self, request: Request) -> Response:
        """GET /api/workouts/workload/session/?session_date=&trainee_id="""
        trainee = self._resolve_trainee(request)
        if trainee is None:
            return Response(
                {'error': 'trainee_id is required (or invalid).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        session_date_str = request.query_params.get('session_date')
        if not session_date_str:
            return Response(
                {'error': 'session_date is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            parsed_date = datetime.strptime(session_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Invalid session_date format (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = WorkloadAggregationService.compute_session_workload(
            trainee_id=trainee.id,
            session_date=parsed_date,
            trainer_id=trainee.parent_trainer_id,
        )

        return Response({
            'trainee_id': result.trainee_id,
            'session_date': str(result.session_date),
            'total_workload': str(result.total_workload),
            'unit': result.unit,
            'mixed_units': result.mixed_units,
            'exercise_count': result.exercise_count,
            'total_sets': result.total_sets,
            'total_reps': result.total_reps,
            'top_exercises': result.top_exercises,
            'week_to_date_workload': str(result.week_to_date_workload),
            'comparison_delta': str(result.comparison_delta) if result.comparison_delta is not None else None,
            'comparison_date': str(result.comparison_date) if result.comparison_date else None,
            'fact_text': result.fact_text,
        })

    @action(detail=False, methods=['get'], url_path='weekly')
    def weekly(self, request: Request) -> Response:
        """GET /api/workouts/workload/weekly/?week_start=&trainee_id="""
        trainee = self._resolve_trainee(request)
        if trainee is None:
            return Response(
                {'error': 'trainee_id is required (or invalid).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        week_start: date | None = None
        week_start_str = request.query_params.get('week_start')
        if week_start_str:
            try:
                week_start = datetime.strptime(week_start_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {'error': 'Invalid week_start format (YYYY-MM-DD).'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        result = WorkloadAggregationService.compute_weekly_workload(
            trainee_id=trainee.id,
            week_start=week_start,
        )

        return Response({
            'trainee_id': result.trainee_id,
            'week_start': str(result.week_start),
            'week_end': str(result.week_end),
            'total_workload': str(result.total_workload),
            'unit': result.unit,
            'session_count': result.session_count,
            'by_muscle_group': {k: str(v) for k, v in result.by_muscle_group.items()},
            'by_pattern': {k: str(v) for k, v in result.by_pattern.items()},
            'prior_week_delta': str(result.prior_week_delta) if result.prior_week_delta is not None else None,
            'daily_breakdown': result.daily_breakdown,
        })

    @action(detail=False, methods=['get'], url_path='trends')
    def trends(self, request: Request) -> Response:
        """GET /api/workouts/workload/trends/?trainee_id=&weeks_back="""
        trainee = self._resolve_trainee(request)
        if trainee is None:
            return Response(
                {'error': 'trainee_id is required (or invalid).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        weeks_back = 8
        weeks_str = request.query_params.get('weeks_back')
        if weeks_str:
            try:
                weeks_back = max(1, min(int(weeks_str), 52))  # 1-52 weeks
            except ValueError:
                weeks_back = 8

        result = WorkloadTrendService.compute_trend(
            trainee_id=trainee.id,
            weeks_back=weeks_back,
        )

        return Response({
            'trainee_id': result.trainee_id,
            'as_of_date': str(result.as_of_date),
            'rolling_7_day': str(result.rolling_7_day),
            'rolling_28_day': str(result.rolling_28_day),
            'acute_chronic_ratio': str(result.acute_chronic_ratio) if result.acute_chronic_ratio is not None else None,
            'trend_direction': result.trend_direction,
            'spike_flag': result.spike_flag,
            'dip_flag': result.dip_flag,
            'weekly_deltas': result.weekly_deltas,
        })


# ---------------------------------------------------------------------------
# v6.5 Step 5: Training Generator + Swap System
# ---------------------------------------------------------------------------


class TrainingPlanPagination(PageNumberPagination):
    page_size = 20
    max_page_size = 50


class TrainingPlanViewSet(viewsets.ModelViewSet[TrainingPlan]):
    """
    CRUD for TrainingPlans with nested hierarchy.
    Trainers see plans for their trainees. Trainees see their own. Admins see all.
    """
    permission_classes = [IsAuthenticated]
    pagination_class = TrainingPlanPagination

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            return TrainingPlanListSerializer
        if self.action in ('create',):
            return TrainingPlanCreateSerializer
        return TrainingPlanSerializer

    def get_queryset(self) -> QuerySet[TrainingPlan]:
        from django.db.models import Count

        user = self.request.user

        # List: lightweight query with annotated weeks_count, no deep prefetch
        if self.action == 'list':
            qs = TrainingPlan.objects.select_related(
                'trainee', 'split_template',
            ).annotate(
                weeks_count=Count('weeks'),
            )
        else:
            # Detail: full hierarchy prefetch for nested serializer
            qs = TrainingPlan.objects.select_related(
                'trainee', 'split_template', 'created_by',
            ).prefetch_related(
                'weeks__sessions__slots__exercise',
                'weeks__sessions__slots__set_structure_modality',
            )

        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(trainee__parent_trainer=user)
        else:
            return qs.filter(trainee=user)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Create a plan manually (not via generator). Returns detail serializer."""
        serializer = TrainingPlanCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        trainee = self._resolve_trainee(data['trainee_id'])

        plan = TrainingPlan.objects.create(
            trainee=trainee,
            name=data['name'],
            description=data.get('description', ''),
            goal=data['goal'],
            difficulty=data['difficulty'],
            duration_weeks=data['duration_weeks'],
            split_template_id=data.get('split_template_id'),
            created_by=request.user if request.user.role in ('TRAINER', 'ADMIN') else None,
        )

        response_serializer = TrainingPlanSerializer(plan)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    def _resolve_trainee(self, trainee_id: int) -> User:
        """Resolve and authorize access to the trainee."""
        user = self.request.user
        try:
            trainee = User.objects.get(pk=trainee_id, role='TRAINEE')
        except User.DoesNotExist:
            raise PermissionDenied("Trainee not found.")

        if user.role == 'TRAINEE':
            if trainee.pk != user.pk:
                raise PermissionDenied("Cannot access other trainees' data.")
        elif user.role == 'TRAINER':
            if trainee.parent_trainer_id != user.pk:
                raise PermissionDenied("This trainee is not assigned to you.")

        return trainee

    @action(detail=False, methods=['post'], url_path='generate')
    def generate(self, request: Request) -> Response:
        """Generate a training plan using the 7-step pipeline."""
        from .services.training_generator_service import (
            GeneratePlanRequest,
            generate_training_plan,
        )

        serializer = GeneratePlanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        trainee = self._resolve_trainee(data['trainee_id'])

        gen_request = GeneratePlanRequest(
            trainee_id=trainee.pk,
            goal=data['goal'],
            difficulty=data['difficulty'],
            days_per_week=data['days_per_week'],
            duration_weeks=data.get('duration_weeks'),
            split_template_id=str(data['split_template_id']) if data.get('split_template_id') else None,
            trainer_id=request.user.pk if request.user.role in ('TRAINER', 'ADMIN') else None,
            training_day_indices=data.get('training_day_indices', []),
        )

        result = generate_training_plan(gen_request)

        return Response({
            'plan_id': result.plan_id,
            'plan_name': result.plan_name,
            'weeks_count': result.weeks_count,
            'sessions_count': result.sessions_count,
            'slots_count': result.slots_count,
            'decision_log_ids': result.decision_log_ids,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='activate')
    def activate(self, request: Request, pk: str | None = None) -> Response:
        """Set plan status to active. Completes other active plans for the trainee."""
        plan = self.get_object()

        # Complete other active plans for this trainee (not archive — they were used)
        TrainingPlan.objects.filter(
            trainee=plan.trainee,
            status=TrainingPlan.Status.ACTIVE,
        ).exclude(pk=plan.pk).update(status=TrainingPlan.Status.COMPLETED)

        plan.status = TrainingPlan.Status.ACTIVE
        plan.save(update_fields=['status', 'updated_at'])

        return Response({'status': 'active', 'plan_id': str(plan.pk)})

    @action(detail=True, methods=['post'], url_path='archive')
    def archive(self, request: Request, pk: str | None = None) -> Response:
        """Archive a plan."""
        plan = self.get_object()
        plan.status = TrainingPlan.Status.ARCHIVED
        plan.save(update_fields=['status', 'updated_at'])
        return Response({'status': 'archived', 'plan_id': str(plan.pk)})


class PlanSlotViewSet(
    viewsets.GenericViewSet[PlanSlot],
    viewsets.mixins.RetrieveModelMixin,
    viewsets.mixins.UpdateModelMixin,
):
    """
    Retrieve and update plan slots. Supports swap operations.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = PlanSlotSerializer

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action in ('update', 'partial_update'):
            return PlanSlotWriteSerializer
        return PlanSlotSerializer

    def get_queryset(self) -> QuerySet[PlanSlot]:
        user = self.request.user
        qs = PlanSlot.objects.select_related(
            'exercise',
            'set_structure_modality',
            'progression_profile',
            'session__week__plan__trainee',
            'session__week__plan__default_progression_profile',
        )

        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(session__week__plan__trainee__parent_trainer=user)
        else:
            return qs.filter(session__week__plan__trainee=user)

    @action(detail=True, methods=['get'], url_path='swap-options')
    def swap_options(self, request: Request, pk: str | None = None) -> Response:
        """Get three-tab swap options for this slot."""
        from .services.swap_service import get_swap_options

        slot = self.get_object()
        trainer_id = (
            request.user.pk
            if request.user.role in ('TRAINER', 'ADMIN')
            else slot.session.week.plan.trainee.parent_trainer_id
        )

        options = get_swap_options(slot=slot, trainer_id=trainer_id)

        return Response({
            'slot_id': options.slot_id,
            'current_exercise_id': options.current_exercise_id,
            'current_exercise_name': options.current_exercise_name,
            'same_muscle': [
                {
                    'exercise_id': c.exercise_id,
                    'exercise_name': c.exercise_name,
                    'primary_muscle_group': c.primary_muscle_group,
                    'pattern_tags': c.pattern_tags,
                    'difficulty_level': c.difficulty_level,
                    'equipment_required': c.equipment_required,
                }
                for c in options.same_muscle
            ],
            'same_pattern': [
                {
                    'exercise_id': c.exercise_id,
                    'exercise_name': c.exercise_name,
                    'primary_muscle_group': c.primary_muscle_group,
                    'pattern_tags': c.pattern_tags,
                    'difficulty_level': c.difficulty_level,
                    'equipment_required': c.equipment_required,
                }
                for c in options.same_pattern
            ],
            'explore_all': [
                {
                    'exercise_id': c.exercise_id,
                    'exercise_name': c.exercise_name,
                    'primary_muscle_group': c.primary_muscle_group,
                    'pattern_tags': c.pattern_tags,
                    'difficulty_level': c.difficulty_level,
                    'equipment_required': c.equipment_required,
                }
                for c in options.explore_all
            ],
        })

    @action(detail=True, methods=['post'], url_path='swap')
    def swap(self, request: Request, pk: str | None = None) -> Response:
        """Execute an exercise swap on this slot."""
        from .services.swap_service import execute_swap

        slot = self.get_object()
        serializer = SwapExecuteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        # Resolve trainer_id for privacy check
        swap_trainer_id = (
            request.user.pk
            if request.user.role in ('TRAINER', 'ADMIN')
            else slot.session.week.plan.trainee.parent_trainer_id
        )

        result = execute_swap(
            slot=slot,
            new_exercise_id=data['new_exercise_id'],
            actor_id=request.user.pk,
            reason=data.get('reason', ''),
            plan_id=str(slot.session.week.plan_id),
            week_id=str(slot.session.week_id),
            session_id=str(slot.session_id),
            trainer_id=swap_trainer_id,
        )

        return Response({
            'slot_id': result.slot_id,
            'old_exercise_id': result.old_exercise_id,
            'old_exercise_name': result.old_exercise_name,
            'new_exercise_id': result.new_exercise_id,
            'new_exercise_name': result.new_exercise_name,
            'decision_log_id': result.decision_log_id,
        })

    @action(detail=True, methods=['get'], url_path='modality-recommendations')
    def modality_recommendations(self, request: Request, pk: str | None = None) -> Response:
        """Get ranked modality recommendations for this slot."""
        from .services.modality_service import get_modality_recommendations

        slot = self.get_object()
        plan = slot.session.week.plan
        goal = plan.goal

        recommendations = get_modality_recommendations(
            slot_role=slot.slot_role,
            goal=goal,
            exercise=slot.exercise,
            reps_min=slot.reps_min,
            reps_max=slot.reps_max,
        )

        return Response({
            'slot_id': str(slot.pk),
            'recommendations': [
                {
                    'modality_id': r.modality_id,
                    'modality_name': r.modality_name,
                    'modality_slug': r.modality_slug,
                    'volume_multiplier': r.volume_multiplier,
                    'score': r.score,
                    'is_valid': r.is_valid,
                    'violations': [
                        {
                            'guardrail_id': v.guardrail_id,
                            'rule_type': v.rule_type,
                            'error_message': v.error_message,
                        }
                        for v in r.violations
                    ],
                }
                for r in recommendations
            ],
        })

    @action(detail=True, methods=['post'], url_path='set-modality')
    def set_modality(self, request: Request, pk: str | None = None) -> Response:
        """Apply a modality to this slot with guardrail validation."""
        from .serializers import SetModalityInputSerializer
        from .services.modality_service import apply_modality_to_slot

        slot = self.get_object()
        serializer = SetModalityInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        # Scope modality lookup to user's visible modalities (row-level security)
        user = request.user
        visibility_q = Q(is_system=True)
        if user.role == 'ADMIN':
            visibility_q = Q()  # Admin sees all
        elif user.role == 'TRAINER':
            visibility_q = Q(is_system=True) | Q(created_by=user)
        else:
            # Trainee: system + their trainer's
            if user.parent_trainer_id is not None:
                visibility_q |= Q(created_by_id=user.parent_trainer_id)

        try:
            modality = SetStructureModality.objects.prefetch_related(
                'guardrails',
            ).filter(visibility_q).get(pk=data['modality_id'])
        except SetStructureModality.DoesNotExist:
            return Response(
                {'detail': f"Modality with id={data['modality_id']} not found or not accessible."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Restrict guardrail override to TRAINER/ADMIN
        override = data.get('override_guardrails', False)
        if override and user.role == 'TRAINEE':
            return Response(
                {'detail': 'Trainees cannot override guardrails.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            result = apply_modality_to_slot(
                slot=slot,
                modality=modality,
                actor_id=request.user.pk,
                override_guardrails=override,
                modality_details=data.get('modality_details'),
                reason=data.get('reason', ''),
            )
        except ValueError as exc:
            return Response(
                {'detail': str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'slot_id': result.slot_id,
            'modality_id': result.modality_id,
            'modality_name': result.modality_name,
            'volume_contribution': result.volume_contribution,
            'decision_log_id': result.decision_log_id,
            'guardrails_overridden': result.guardrails_overridden,
        })

    @action(detail=True, methods=['get'], url_path='next-prescription')
    def next_prescription(self, request: Request, pk: str | None = None) -> Response:
        """Compute the next session prescription for this slot."""
        from .services.progression_engine_service import compute_next_prescription

        slot = self.get_object()
        trainee = slot.session.week.plan.trainee
        prescription = compute_next_prescription(slot=slot, trainee_id=trainee.pk)

        return Response({
            'slot_id': prescription.slot_id,
            'exercise_id': prescription.exercise_id,
            'exercise_name': prescription.exercise_name,
            'progression_type': prescription.progression_type,
            'event_type': prescription.event_type,
            'sets': prescription.sets,
            'reps_min': prescription.reps_min,
            'reps_max': prescription.reps_max,
            'load_value': str(prescription.load_value) if prescription.load_value else None,
            'load_unit': prescription.load_unit,
            'load_percentage': str(prescription.load_percentage) if prescription.load_percentage else None,
            'reason_codes': prescription.reason_codes,
            'reason_display': prescription.reason_display,
            'confidence': prescription.confidence,
        })

    @action(detail=True, methods=['post'], url_path='apply-progression')
    def apply_progression(self, request: Request, pk: str | None = None) -> Response:
        """Compute and apply the next progression to this slot."""
        from .services.progression_engine_service import (
            apply_progression as apply_prog,
            compute_next_prescription,
        )

        slot = self.get_object()
        trainee = slot.session.week.plan.trainee
        user = request.user

        # Only trainers and admins can apply progression
        if user.role == 'TRAINEE':
            raise PermissionDenied("Only trainers and admins can apply progression.")

        serializer = ApplyProgressionInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        overrides = serializer.validated_data

        prescription = compute_next_prescription(slot=slot, trainee_id=trainee.pk)

        # Apply trainer overrides if provided
        override_kwargs: dict[str, Any] = {}
        if overrides.get('override_sets') is not None:
            override_kwargs['sets'] = overrides['override_sets']
        if overrides.get('override_reps_min') is not None:
            override_kwargs['reps_min'] = overrides['override_reps_min']
        if overrides.get('override_reps_max') is not None:
            override_kwargs['reps_max'] = overrides['override_reps_max']
        if overrides.get('override_load') is not None:
            override_kwargs['load_value'] = overrides['override_load']
        if override_kwargs:
            prescription = replace(prescription, **override_kwargs)

        result = apply_prog(
            slot=slot,
            prescription=prescription,
            actor_id=user.pk,
            trainee_id=trainee.pk,
            reason=overrides.get('reason', ''),
        )

        return Response({
            'event_id': result.event_id,
            'slot_id': result.slot_id,
            'event_type': result.event_type,
            'old_prescription': result.old_prescription,
            'new_prescription': result.new_prescription,
            'reason_codes': result.reason_codes,
            'decision_log_id': result.decision_log_id,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='progression-history')
    def progression_history(self, request: Request, pk: str | None = None) -> Response:
        """Get progression event history for this slot."""
        from .services.progression_engine_service import get_progression_history

        slot = self.get_object()
        events = get_progression_history(slot=slot)
        serializer = ProgressionEventSerializer(events, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='progression-readiness')
    def progression_readiness(self, request: Request, pk: str | None = None) -> Response:
        """Evaluate whether this slot is ready for progression."""
        from .services.progression_engine_service import evaluate_progression_readiness

        slot = self.get_object()
        trainee = slot.session.week.plan.trainee
        readiness = evaluate_progression_readiness(slot=slot, trainee_id=trainee.pk)

        return Response({
            'slot_id': readiness.slot_id,
            'is_ready': readiness.is_ready,
            'blockers': readiness.blockers,
            'recent_sessions': readiness.recent_sessions,
            'last_session_date': readiness.last_session_date,
            'avg_rpe': str(readiness.avg_rpe) if readiness.avg_rpe else None,
            'sets_completed_rate': str(readiness.sets_completed_rate) if readiness.sets_completed_rate else None,
            'consecutive_failures': readiness.consecutive_failures,
        })


class SetStructureModalityViewSet(viewsets.ModelViewSet[SetStructureModality]):
    """
    CRUD for set structure modalities.
    System modalities visible to all. Trainer-created visible to creator + their trainees.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            from .serializers import SetStructureModalityListSerializer
            return SetStructureModalityListSerializer
        from .serializers import SetStructureModalitySerializer
        return SetStructureModalitySerializer

    def get_queryset(self) -> QuerySet[SetStructureModality]:
        user = self.request.user
        if user.role == 'ADMIN':
            return SetStructureModality.objects.prefetch_related('guardrails').all()
        elif user.role == 'TRAINER':
            return SetStructureModality.objects.prefetch_related('guardrails').filter(
                Q(is_system=True) | Q(created_by=user)
            )
        else:
            # Trainee: system + their trainer's
            q = Q(is_system=True)
            if user.parent_trainer_id is not None:
                q |= Q(created_by_id=user.parent_trainer_id)
            return SetStructureModality.objects.prefetch_related('guardrails').filter(q)

    def perform_create(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot create modalities.")
        if user.role == 'ADMIN':
            serializer.save(is_system=True, created_by=user)
        else:
            serializer.save(is_system=False, created_by=user)

    def perform_update(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot modify modalities.")
        instance = serializer.instance
        if instance and instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot modify system modalities.")
        serializer.save()

    def perform_destroy(self, instance: SetStructureModality) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot delete modalities.")
        if instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot delete system modalities.")
        instance.delete()


class PlanSessionViewSet(
    viewsets.GenericViewSet[PlanSession],
    viewsets.mixins.RetrieveModelMixin,
):
    """
    Retrieve plan sessions. Supports volume summary action.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = PlanSessionSerializer

    def get_queryset(self) -> QuerySet[PlanSession]:
        user = self.request.user
        qs = PlanSession.objects.select_related('week__plan__trainee')
        if user.role == 'ADMIN':
            return qs
        elif user.role == 'TRAINER':
            return qs.filter(week__plan__trainee__parent_trainer=user)
        else:
            return qs.filter(week__plan__trainee=user)

    @action(detail=True, methods=['get'], url_path='volume-summary')
    def volume_summary(self, request: Request, pk: str | None = None) -> Response:
        """Get per-muscle volume summary for this session."""
        from .services.modality_service import get_session_volume_summary

        session = self.get_object()
        summary = get_session_volume_summary(session=session)

        return Response({
            'session_id': summary.session_id,
            'session_label': summary.session_label,
            'total_raw_sets': summary.total_raw_sets,
            'total_adjusted_volume': summary.total_adjusted_volume,
            'by_muscle': [
                {
                    'muscle_group': entry.muscle_group,
                    'raw_sets': entry.raw_sets,
                    'adjusted_volume': entry.adjusted_volume,
                    'slot_count': entry.slot_count,
                }
                for entry in summary.by_muscle
            ],
        })


class SplitTemplateViewSet(viewsets.ModelViewSet[SplitTemplate]):
    """
    CRUD for split templates.
    Trainers see system templates + their own. Admins see all.
    Trainees: read-only access to system + their trainer's templates.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = SplitTemplateSerializer

    def get_queryset(self) -> QuerySet[SplitTemplate]:
        user = self.request.user
        if user.role == 'ADMIN':
            return SplitTemplate.objects.all()
        elif user.role == 'TRAINER':
            return SplitTemplate.objects.filter(
                Q(is_system=True) | Q(created_by=user)
            )
        else:
            # Trainees: system templates + their trainer's (if trainer exists)
            q = Q(is_system=True)
            if user.parent_trainer_id is not None:
                q |= Q(created_by_id=user.parent_trainer_id)
            return SplitTemplate.objects.filter(q)

    def perform_create(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot create split templates.")
        if user.role == 'ADMIN':
            serializer.save(is_system=True, created_by=user)
        else:
            serializer.save(is_system=False, created_by=user)

    def perform_update(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot modify split templates.")
        instance = serializer.instance
        if instance and instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot modify system split templates.")
        serializer.save()

    def perform_destroy(self, instance: SplitTemplate) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot delete split templates.")
        if instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot delete system split templates.")
        instance.delete()


class ProgressionProfileViewSet(viewsets.ModelViewSet[ProgressionProfile]):
    """
    CRUD for progression profiles.
    System profiles visible to all. Trainer-created visible to creator + their trainees.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            return ProgressionProfileListSerializer
        return ProgressionProfileSerializer

    def get_queryset(self) -> QuerySet[ProgressionProfile]:
        user = self.request.user
        if user.role == 'ADMIN':
            return ProgressionProfile.objects.all()
        elif user.role == 'TRAINER':
            return ProgressionProfile.objects.filter(
                Q(is_system=True) | Q(created_by=user)
            )
        else:
            q = Q(is_system=True)
            if user.parent_trainer_id is not None:
                q |= Q(created_by_id=user.parent_trainer_id)
            return ProgressionProfile.objects.filter(q)

    def perform_create(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot create progression profiles.")
        if user.role == 'ADMIN':
            serializer.save(is_system=True, created_by=user)
        else:
            serializer.save(is_system=False, created_by=user)

    def perform_update(self, serializer: BaseSerializer[Any]) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot modify progression profiles.")
        instance = serializer.instance
        if instance and instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot modify system progression profiles.")
        serializer.save()

    def perform_destroy(self, instance: ProgressionProfile) -> None:
        user = self.request.user
        if user.role == 'TRAINEE':
            raise PermissionDenied("Trainees cannot delete progression profiles.")
        if instance.is_system and user.role != 'ADMIN':
            raise PermissionDenied("Cannot delete system progression profiles.")
        instance.delete()

"""
Views for workout and nutrition endpoints.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import date
from typing import Dict, Any, Optional

from .models import Exercise, Program, DailyLog, NutritionGoal, WeightCheckIn
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
)
from .services.natural_language_parser import NaturalLanguageParserService


class ExerciseViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Exercise CRUD operations.
    Trainers can create custom exercises; all users can view public exercises.
    """
    serializer_class = ExerciseSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return public exercises + trainer's custom exercises."""
        user = self.request.user
        
        if user.is_trainer():
            # Trainers see public + their own custom exercises
            return Exercise.objects.filter(
                is_public=True
            ) | Exercise.objects.filter(
                created_by=user
            )
        elif user.is_admin():
            # Admins see all exercises
            return Exercise.objects.all()
        else:
            # Trainees see only public exercises
            return Exercise.objects.filter(is_public=True)
    
    def perform_create(self, serializer):
        """Set created_by to current user if trainer."""
        if self.request.user.is_trainer():
            serializer.save(created_by=self.request.user, is_public=False)
        else:
            serializer.save(is_public=True)


class ProgramViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Program CRUD operations.
    Trainers create programs for their trainees.
    """
    serializer_class = ProgramSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return programs based on user role."""
        user = self.request.user
        
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
            return Program.objects.none()
    
    def perform_create(self, serializer):
        """Set created_by to current user if trainer."""
        if self.request.user.is_trainer():
            serializer.save(created_by=self.request.user)


class DailyLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for DailyLog CRUD operations.
    Includes natural language parsing endpoint.
    """
    serializer_class = DailyLogSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return logs based on user role with proper row-level security."""
        user = self.request.user
        
        if user.is_trainee():
            # Trainees see only their own logs
            return DailyLog.objects.filter(trainee=user).select_related('trainee')
        elif user.is_trainer():
            # Trainers see logs for their trainees only
            return DailyLog.objects.filter(
                trainee__parent_trainer=user
            ).select_related('trainee')
        elif user.is_admin():
            # Admins see all logs
            return DailyLog.objects.all().select_related('trainee')
        else:
            return DailyLog.objects.none()
    
    @action(detail=False, methods=['post'], url_path='parse-natural-language')
    def parse_natural_language(self, request):
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
        
        # Get user context (current program, recent exercises)
        context = self._get_user_context(request.user, log_date)
        
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
    def confirm_and_save(self, request):
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
        
        # Ensure user is a trainee
        if not request.user.is_trainee():
            return Response(
                {'error': 'Only trainees can create log entries'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Format parsed data for DailyLog
        parser_service = NaturalLanguageParserService()
        formatted_data = parser_service.format_for_daily_log(
            parsed_data=parsed_data,
            trainee_id=request.user.id
        )
        
        # Get or create DailyLog for this date
        daily_log, created = DailyLog.objects.get_or_create(
            trainee=request.user,
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
    
    def _get_user_context(self, user, log_date: date) -> Dict[str, Any]:
        """
        Get user context for AI parsing (current program, recent exercises).
        """
        context = {}

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
    def nutrition_summary(self, request):
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

        user = request.user
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
    def workout_summary(self, request):
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

        user = request.user
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


class NutritionGoalViewSet(viewsets.ModelViewSet):
    """
    ViewSet for NutritionGoal CRUD operations.
    Trainees see their own goals; Trainers can adjust trainee goals.
    """
    serializer_class = NutritionGoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return goals based on user role."""
        user = self.request.user

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

    def list(self, request, *args, **kwargs):
        """For trainees, return their single goal as an object."""
        if request.user.is_trainee():
            try:
                goal = NutritionGoal.objects.get(trainee=request.user)
                serializer = self.get_serializer(goal)
                return Response(serializer.data)
            except NutritionGoal.DoesNotExist:
                return Response(
                    {'error': 'No nutrition goals set. Complete onboarding first.'},
                    status=status.HTTP_404_NOT_FOUND
                )
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['post'], url_path='trainer-adjust')
    def trainer_adjust(self, request):
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
        if not request.user.is_trainer():
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
            from users.models import User
            trainee = User.objects.get(
                id=trainee_id,
                role=User.Role.TRAINEE,
                parent_trainer=request.user
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
        goal.adjusted_by = request.user
        goal.save()

        return Response(NutritionGoalSerializer(goal).data)


class WeightCheckInViewSet(viewsets.ModelViewSet):
    """
    ViewSet for WeightCheckIn CRUD operations.
    """
    serializer_class = WeightCheckInSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return check-ins based on user role."""
        user = self.request.user

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

    def perform_create(self, serializer):
        """Set trainee to current user."""
        if self.request.user.is_trainee():
            serializer.save(trainee=self.request.user)
        else:
            serializer.save()

    @action(detail=False, methods=['get'], url_path='latest')
    def latest(self, request):
        """
        Get the most recent weight check-in.

        GET /api/workouts/weight-checkins/latest/
        """
        user = request.user
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

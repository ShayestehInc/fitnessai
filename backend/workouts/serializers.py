"""
Serializers for workout and nutrition models.
"""
from __future__ import annotations

from typing import Any

from rest_framework import serializers

from .models import DailyLog, Exercise, MacroPreset, NutritionGoal, Program, WeightCheckIn


class ExerciseSerializer(serializers.ModelSerializer[Exercise]):
    """Serializer for Exercise model."""

    created_by_email = serializers.CharField(source='created_by.email', read_only=True)

    class Meta:
        model = Exercise
        fields = [
            'id', 'name', 'description', 'video_url', 'image_url', 'muscle_group',
            'is_public', 'created_by', 'created_by_email', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']


class ProgramSerializer(serializers.ModelSerializer[Program]):
    """Serializer for Program model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    trainee_name = serializers.SerializerMethodField()
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    duration_weeks = serializers.SerializerMethodField()
    difficulty_level = serializers.SerializerMethodField()
    goal_type = serializers.SerializerMethodField()

    class Meta:
        model = Program
        fields = [
            'id', 'trainee', 'trainee_email', 'trainee_name', 'name', 'description',
            'start_date', 'end_date', 'schedule', 'is_active', 'image_url',
            'duration_weeks', 'difficulty_level', 'goal_type',
            'created_by', 'created_by_email', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_trainee_name(self, obj: Program) -> str:
        """Get trainee's display name."""
        if obj.trainee:
            name = f"{obj.trainee.first_name or ''} {obj.trainee.last_name or ''}".strip()
            return name if name else obj.trainee.email
        return ''

    def get_duration_weeks(self, obj: Program) -> int | None:
        """Calculate duration in weeks from start and end dates."""
        if obj.start_date and obj.end_date:
            delta = obj.end_date - obj.start_date
            return max(1, delta.days // 7)
        # Try to get from schedule metadata
        if obj.schedule and isinstance(obj.schedule, dict):
            return obj.schedule.get('duration_weeks')
        if obj.schedule and isinstance(obj.schedule, list):
            return len(obj.schedule)
        return None

    def get_difficulty_level(self, obj: Program) -> str | None:
        """Get difficulty level from schedule metadata."""
        if obj.schedule and isinstance(obj.schedule, dict):
            return obj.schedule.get('difficulty_level')
        return None

    def get_goal_type(self, obj: Program) -> str | None:
        """Get goal type from schedule metadata."""
        if obj.schedule and isinstance(obj.schedule, dict):
            return obj.schedule.get('goal_type')
        return None


class DailyLogSerializer(serializers.ModelSerializer[DailyLog]):
    """Serializer for DailyLog model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)

    class Meta:
        model = DailyLog
        fields = [
            'id', 'trainee', 'trainee_email', 'date',
            'nutrition_data', 'workout_data',
            'steps', 'sleep_hours', 'resting_heart_rate', 'recovery_score',
            'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']


class NaturalLanguageLogInputSerializer(serializers.Serializer[dict[str, Any]]):
    """
    Serializer for natural language log input endpoint.
    Accepts raw user input and returns parsed data for verification.
    """

    user_input = serializers.CharField(
        required=True,
        help_text="Natural language input from user (e.g., 'I ate a chicken bowl and did 3 sets of bench press at 225')"
    )
    date = serializers.DateField(
        required=False,
        help_text="Optional date for the log entry (defaults to today)"
    )

    def validate_user_input(self, value: str) -> str:
        """Validate that user input is not empty."""
        if not value or not value.strip():
            raise serializers.ValidationError("User input cannot be empty")
        if len(value) > 2000:
            raise serializers.ValidationError("User input is too long (max 2000 characters)")
        return value.strip()


class NaturalLanguageLogResponseSerializer(serializers.Serializer[dict[str, Any]]):
    """
    Serializer for natural language log response (verification step).
    Returns parsed data before saving to database.
    """

    nutrition = serializers.DictField(
        required=False,
        help_text="Parsed nutrition data with meals array"
    )
    workout = serializers.DictField(
        required=False,
        help_text="Parsed workout data with exercises array"
    )
    confidence = serializers.FloatField(
        required=False,
        min_value=0.0,
        max_value=1.0,
        help_text="AI confidence score (0-1)"
    )
    needs_clarification = serializers.BooleanField(
        required=False,
        help_text="Whether the AI needs clarification from the user"
    )
    clarification_question = serializers.CharField(
        required=False,
        allow_null=True,
        help_text="Question to ask user if clarification is needed"
    )


class ConfirmLogSaveSerializer(serializers.Serializer[dict[str, Any]]):
    """
    Serializer for confirming and saving the parsed log data.
    """

    parsed_data = serializers.DictField(
        required=True,
        help_text="The parsed data returned from the initial parse endpoint"
    )
    date = serializers.DateField(
        required=False,
        help_text="Date for the log entry (defaults to today)"
    )
    confirm = serializers.BooleanField(
        required=True,
        help_text="User confirmation to save the log"
    )


class NutritionGoalSerializer(serializers.ModelSerializer[NutritionGoal]):
    """Serializer for NutritionGoal model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    adjusted_by_email = serializers.CharField(source='adjusted_by.email', read_only=True, allow_null=True)

    class Meta:
        model = NutritionGoal
        fields = [
            'id', 'trainee', 'trainee_email', 'protein_goal', 'carbs_goal',
            'fat_goal', 'calories_goal', 'per_meal_protein', 'per_meal_carbs',
            'per_meal_fat', 'is_trainer_adjusted', 'adjusted_by', 'adjusted_by_email',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['trainee', 'created_at', 'updated_at']


class TrainerAdjustGoalSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for trainer adjusting trainee nutrition goals."""

    trainee_id = serializers.IntegerField(required=True)
    protein_goal = serializers.IntegerField(min_value=0, required=False)
    carbs_goal = serializers.IntegerField(min_value=0, required=False)
    fat_goal = serializers.IntegerField(min_value=0, required=False)
    calories_goal = serializers.IntegerField(min_value=0, required=False)


class WeightCheckInSerializer(serializers.ModelSerializer[WeightCheckIn]):
    """Serializer for WeightCheckIn model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)

    class Meta:
        model = WeightCheckIn
        fields = ['id', 'trainee', 'trainee_email', 'date', 'weight_kg', 'notes', 'created_at']
        read_only_fields = ['trainee', 'created_at']


class MacroPresetSerializer(serializers.ModelSerializer[MacroPreset]):
    """Serializer for MacroPreset model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True, allow_null=True)

    class Meta:
        model = MacroPreset
        fields = [
            'id', 'trainee', 'trainee_email', 'name',
            'calories', 'protein', 'carbs', 'fat',
            'frequency_per_week', 'is_default', 'sort_order',
            'created_by', 'created_by_email', 'created_at', 'updated_at'
        ]
        read_only_fields = ['trainee', 'created_by', 'created_at', 'updated_at']


class MacroPresetCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for creating/updating macro presets."""

    trainee_id = serializers.IntegerField(required=True)
    name = serializers.CharField(max_length=100, required=True)
    calories = serializers.IntegerField(min_value=500, max_value=10000, required=True)
    protein = serializers.IntegerField(min_value=0, max_value=500, required=True)
    carbs = serializers.IntegerField(min_value=0, max_value=1000, required=True)
    fat = serializers.IntegerField(min_value=0, max_value=500, required=True)
    frequency_per_week = serializers.IntegerField(min_value=1, max_value=7, required=False, allow_null=True)
    is_default = serializers.BooleanField(required=False, default=False)
    sort_order = serializers.IntegerField(required=False, default=0)


class EditMealEntrySerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for editing a meal entry in a DailyLog's nutrition_data."""

    entry_index = serializers.IntegerField(
        min_value=0,
        required=True,
        help_text="Flat index into the meals array",
    )
    data = serializers.DictField(
        required=True,
        help_text="Fields to update: name, protein, carbs, fat, calories",
    )

    ALLOWED_DATA_KEYS = frozenset({'name', 'protein', 'carbs', 'fat', 'calories', 'timestamp'})
    NUMERIC_KEYS = frozenset({'protein', 'carbs', 'fat', 'calories'})

    def validate_data(self, value: dict[str, Any]) -> dict[str, Any]:
        """Validate and whitelist the data payload."""
        filtered = {k: v for k, v in value.items() if k in self.ALLOWED_DATA_KEYS}
        if not filtered:
            raise serializers.ValidationError("No valid fields provided. Allowed: name, protein, carbs, fat, calories.")
        for key in self.NUMERIC_KEYS:
            if key in filtered:
                v = filtered[key]
                if not isinstance(v, (int, float)) or v < 0:
                    raise serializers.ValidationError(f"{key} must be a non-negative number.")
        return filtered


class DeleteMealEntrySerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for deleting a meal entry from a DailyLog's nutrition_data."""

    entry_index = serializers.IntegerField(
        min_value=0,
        required=True,
        help_text="Flat index into the meals array",
    )


class NutritionSummarySerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for daily nutrition summary response."""

    date = serializers.DateField()
    goals = serializers.DictField()
    consumed = serializers.DictField()
    remaining = serializers.DictField()
    meals = serializers.ListField()
    per_meal_targets = serializers.DictField()


class WorkoutSummarySerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for daily workout summary response."""

    date = serializers.DateField()
    exercises = serializers.ListField()
    program_context = serializers.DictField(required=False, allow_null=True)


class WorkoutHistorySummarySerializer(serializers.ModelSerializer[DailyLog]):
    """
    Serializer for workout history list view.
    Returns computed summary fields from workout_data JSON.
    """

    workout_name = serializers.SerializerMethodField()
    exercise_count = serializers.SerializerMethodField()
    total_sets = serializers.SerializerMethodField()
    total_volume_lbs = serializers.SerializerMethodField()
    duration_display = serializers.SerializerMethodField()

    class Meta:
        model = DailyLog
        fields = [
            'id', 'date', 'workout_name', 'exercise_count',
            'total_sets', 'total_volume_lbs', 'duration_display',
            'workout_data',
        ]
        read_only_fields = ['id', 'date', 'workout_data']

    def _get_workout_data(self, obj: DailyLog) -> dict[str, Any]:
        """Safely extract workout_data as a dict."""
        data = obj.workout_data
        if isinstance(data, dict):
            return data
        return {}

    def _get_exercises_list(self, obj: DailyLog) -> list[dict[str, Any]]:
        """Extract exercises from workout_data, handling both formats."""
        data = self._get_workout_data(obj)
        exercises = data.get('exercises', [])
        if isinstance(exercises, list):
            return [e for e in exercises if isinstance(e, dict)]
        return []

    def get_workout_name(self, obj: DailyLog) -> str:
        """Extract workout name from workout_data."""
        data = self._get_workout_data(obj)
        # Top-level workout_name
        name = data.get('workout_name')
        if name and isinstance(name, str):
            return name
        # Try first session name
        sessions = data.get('sessions', [])
        if isinstance(sessions, list) and sessions:
            first_session = sessions[0]
            if isinstance(first_session, dict):
                session_name = first_session.get('workout_name')
                if session_name and isinstance(session_name, str):
                    return session_name
        return 'Workout'

    def get_exercise_count(self, obj: DailyLog) -> int:
        """Count exercises in workout_data."""
        return len(self._get_exercises_list(obj))

    def get_total_sets(self, obj: DailyLog) -> int:
        """Sum all sets across all exercises."""
        total = 0
        for exercise in self._get_exercises_list(obj):
            sets = exercise.get('sets', [])
            if isinstance(sets, list):
                total += len(sets)
        return total

    def get_total_volume_lbs(self, obj: DailyLog) -> float:
        """Sum of (weight * reps) for all completed sets."""
        total = 0.0
        for exercise in self._get_exercises_list(obj):
            sets = exercise.get('sets', [])
            if not isinstance(sets, list):
                continue
            for s in sets:
                if not isinstance(s, dict):
                    continue
                if not s.get('completed', True):
                    continue
                weight = s.get('weight', 0)
                reps = s.get('reps', 0)
                if isinstance(weight, (int, float)) and isinstance(reps, (int, float)):
                    total += weight * reps
        return round(total, 1)

    def get_duration_display(self, obj: DailyLog) -> str:
        """Extract duration from workout_data."""
        data = self._get_workout_data(obj)
        duration = data.get('duration')
        if duration and isinstance(duration, str):
            return duration
        # Try first session
        sessions = data.get('sessions', [])
        if isinstance(sessions, list) and sessions:
            first_session = sessions[0]
            if isinstance(first_session, dict):
                session_duration = first_session.get('duration')
                if session_duration and isinstance(session_duration, str):
                    return session_duration
        return '0:00'

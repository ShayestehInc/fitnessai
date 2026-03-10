"""
Serializers for workout and nutrition models.
"""
from __future__ import annotations

import json
from decimal import Decimal
from typing import Any

from rest_framework import serializers

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
    MealLog,
    MealLogEntry,
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
    ProgressionSuggestion,
    ProgressPhoto,
    UndoSnapshot,
    WeightCheckIn,
    WorkoutTemplate,
)


class ExerciseSerializer(serializers.ModelSerializer[Exercise]):
    """Serializer for Exercise model — includes v6.5 ExerciseCard tag fields."""

    created_by_email = serializers.CharField(source='created_by.email', read_only=True, default=None)

    class Meta:
        model = Exercise
        fields = [
            'id', 'name', 'aliases', 'description', 'video_url', 'image_url',
            'muscle_group', 'difficulty_level', 'suitable_for_goals', 'category',
            # v6.5 tag fields
            'pattern_tags', 'athletic_skill_tags', 'athletic_attribute_tags',
            'primary_muscle_group', 'secondary_muscle_groups',
            'muscle_contribution_map',
            'stance', 'plane', 'rom_bias',
            'equipment_required', 'equipment_optional',
            'athletic_constraints', 'standardization_block', 'swap_seed_ids',
            'version',
            'is_public', 'created_by', 'created_by_email', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at', 'version', 'is_public', 'created_by']

    def validate_muscle_contribution_map(self, value: dict[str, float]) -> dict[str, float]:
        """Validate that muscle contribution weights sum to 1.0."""
        if not value:
            return value

        valid_groups = {c[0] for c in Exercise.DetailedMuscleGroup.choices}
        invalid_keys = set(value.keys()) - valid_groups
        if invalid_keys:
            raise serializers.ValidationError(
                f"Invalid muscle groups: {sorted(invalid_keys)}. "
                f"Valid options: {sorted(valid_groups)}"
            )

        total = sum(value.values())
        if abs(total - 1.0) > 0.01:
            raise serializers.ValidationError(
                f"Muscle contribution weights must sum to 1.0 (got {total:.4f})."
            )

        return value

    def validate_pattern_tags(self, value: list[str]) -> list[str]:
        """Validate pattern tags against allowed choices."""
        if not value:
            return value
        valid_tags = {c[0] for c in Exercise.PatternTag.choices}
        invalid = set(value) - valid_tags
        if invalid:
            raise serializers.ValidationError(
                f"Invalid pattern tags: {sorted(invalid)}. Valid options: {sorted(valid_tags)}"
            )
        return value

    def validate_athletic_skill_tags(self, value: list[str]) -> list[str]:
        """Validate athletic skill tags against allowed choices."""
        if not value:
            return value
        valid_tags = {c[0] for c in Exercise.AthleticSkillTag.choices}
        invalid = set(value) - valid_tags
        if invalid:
            raise serializers.ValidationError(
                f"Invalid athletic skill tags: {sorted(invalid)}. Valid options: {sorted(valid_tags)}"
            )
        return value

    def validate_athletic_attribute_tags(self, value: list[str]) -> list[str]:
        """Validate athletic attribute tags against allowed choices."""
        if not value:
            return value
        valid_tags = {c[0] for c in Exercise.AthleticAttributeTag.choices}
        invalid = set(value) - valid_tags
        if invalid:
            raise serializers.ValidationError(
                f"Invalid athletic attribute tags: {sorted(invalid)}. Valid options: {sorted(valid_tags)}"
            )
        return value


class UndoSnapshotSerializer(serializers.ModelSerializer[UndoSnapshot]):
    """Read-only serializer for UndoSnapshot."""

    is_reverted = serializers.BooleanField(read_only=True)

    class Meta:
        model = UndoSnapshot
        fields = [
            'id', 'scope', 'before_state', 'after_state',
            'created_at', 'reverted_at', 'is_reverted',
        ]
        read_only_fields = fields


class DecisionLogSerializer(serializers.ModelSerializer[DecisionLog]):
    """Read-only serializer for DecisionLog with nested undo snapshot."""

    undo_snapshot = UndoSnapshotSerializer(read_only=True)
    actor_email = serializers.CharField(source='actor.email', read_only=True, default=None)
    is_undoable = serializers.BooleanField(read_only=True)

    class Meta:
        model = DecisionLog
        fields = [
            'id', 'timestamp', 'actor_type', 'actor', 'actor_email',
            'decision_type', 'context',
            'inputs_snapshot', 'constraints_applied',
            'options_considered', 'final_choice', 'reason_codes',
            'override_info', 'undo_snapshot', 'is_undoable',
        ]
        read_only_fields = fields


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
        ]
        read_only_fields = ['id', 'date']

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


class WorkoutDetailSerializer(serializers.ModelSerializer[DailyLog]):
    """
    Restricted serializer for workout detail view.
    Only exposes fields needed by the mobile detail screen —
    no trainee email, no nutrition_data.
    """

    class Meta:
        model = DailyLog
        fields = ['id', 'date', 'workout_data', 'notes']
        read_only_fields = ['id', 'date', 'workout_data', 'notes']


# --- Phase 1: Exercise Videos, Quick-Log, Rest Days ---

class ExerciseVideoUploadSerializer(serializers.Serializer[dict[str, Any]]):
    """Validates exercise video file upload."""

    video = serializers.FileField(required=True)

    ALLOWED_TYPES = {'video/mp4', 'video/quicktime', 'video/webm'}
    MAX_SIZE_MB = 100

    def validate_video(self, value: Any) -> Any:
        """Validate video file type and size."""
        if value.content_type not in self.ALLOWED_TYPES:
            raise serializers.ValidationError(
                f"Invalid file type '{value.content_type}'. Allowed: mp4, mov, webm."
            )
        max_bytes = self.MAX_SIZE_MB * 1024 * 1024
        if value.size > max_bytes:
            raise serializers.ValidationError(
                f"File too large ({value.size / 1024 / 1024:.1f}MB). Max: {self.MAX_SIZE_MB}MB."
            )
        return value


class WorkoutTemplateSerializer(serializers.ModelSerializer[WorkoutTemplate]):
    """Serializer for WorkoutTemplate model."""

    created_by_email = serializers.CharField(source='created_by.email', read_only=True, allow_null=True)

    class Meta:
        model = WorkoutTemplate
        fields = [
            'id', 'name', 'category', 'description',
            'estimated_duration_minutes', 'default_calories_per_minute',
            'is_public', 'created_by', 'created_by_email',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']


class QuickLogSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for quick-logging a non-program workout."""

    template_id = serializers.IntegerField(required=False, allow_null=True)
    activity_name = serializers.CharField(max_length=255, required=True)
    category = serializers.ChoiceField(
        choices=WorkoutTemplate.Category.choices,
        required=False,
        default='other',
    )
    duration_minutes = serializers.IntegerField(min_value=1, max_value=600, required=True)
    calories_burned = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    date = serializers.DateField(required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        """Calculate calories if not provided."""
        if not attrs.get('calories_burned') and attrs.get('template_id'):
            template = WorkoutTemplate.objects.filter(id=attrs['template_id']).first()
            if template:
                attrs['calories_burned'] = int(
                    template.default_calories_per_minute * attrs['duration_minutes']
                )
        if not attrs.get('calories_burned'):
            attrs['calories_burned'] = int(5.0 * attrs['duration_minutes'])
        return attrs


class RestDayCompleteSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for completing a rest day."""

    date = serializers.DateField(required=False)
    completed_exercises = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        default=list,
    )
    notes = serializers.CharField(required=False, allow_blank=True, default='')


# --- Phase 2: Progress Photos, Barcode Scanner, Habits ---

class ProgressPhotoSerializer(serializers.ModelSerializer[ProgressPhoto]):
    """Serializer for ProgressPhoto model."""

    ALLOWED_CONTENT_TYPES = ('image/jpeg', 'image/png', 'image/webp')
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

    ALLOWED_MEASUREMENT_KEYS = frozenset({
        'waist', 'chest', 'arms', 'hips', 'thighs',
        'waist_cm', 'chest_cm', 'arms_cm', 'hips_cm', 'thighs_cm',
    })

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = ProgressPhoto
        fields = [
            'id', 'trainee', 'trainee_email', 'photo', 'photo_url',
            'category', 'date', 'measurements', 'notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['trainee', 'created_at', 'updated_at']

    def validate_photo(self, value: Any) -> Any:
        """Validate uploaded photo file type and size."""
        if hasattr(value, 'content_type'):
            if value.content_type not in self.ALLOWED_CONTENT_TYPES:
                raise serializers.ValidationError(
                    f"Invalid file type '{value.content_type}'. "
                    f"Allowed: JPEG, PNG, WebP."
                )
        if hasattr(value, 'size') and value.size > self.MAX_FILE_SIZE:
            raise serializers.ValidationError(
                f"File too large ({value.size / (1024 * 1024):.1f} MB). "
                f"Maximum allowed: 10 MB."
            )
        return value

    def validate_measurements(self, value: Any) -> dict[str, float]:
        """Validate measurements contains only allowed keys with numeric values."""
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except (json.JSONDecodeError, TypeError):
                raise serializers.ValidationError("Invalid JSON for measurements.")
        if not isinstance(value, dict):
            raise serializers.ValidationError("Measurements must be a JSON object.")
        if len(value) > 10:
            raise serializers.ValidationError("Too many measurement fields (max 10).")
        validated: dict[str, float] = {}
        for key, val in value.items():
            if key not in self.ALLOWED_MEASUREMENT_KEYS:
                raise serializers.ValidationError(
                    f"Unknown measurement key '{key}'. "
                    f"Allowed: {', '.join(sorted(self.ALLOWED_MEASUREMENT_KEYS))}."
                )
            try:
                numeric_val = float(val)
            except (TypeError, ValueError):
                raise serializers.ValidationError(
                    f"Measurement '{key}' must be a number, got '{val}'."
                )
            if numeric_val < 0 or numeric_val > 500:
                raise serializers.ValidationError(
                    f"Measurement '{key}' out of range (0-500)."
                )
            validated[key] = numeric_val
        return validated

    def validate_notes(self, value: str) -> str:
        """Cap notes length server-side."""
        if len(value) > 1000:
            raise serializers.ValidationError("Notes must be 1000 characters or fewer.")
        return value

    def get_photo_url(self, obj: ProgressPhoto) -> str | None:
        """Return full URL for the photo."""
        if obj.photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.photo.url)
            return obj.photo.url
        return None


class FoodLookupSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for barcode food lookup response."""

    barcode = serializers.CharField()
    product_name = serializers.CharField()
    brand = serializers.CharField()
    serving_size = serializers.CharField()
    calories = serializers.FloatField()
    protein = serializers.FloatField()
    carbs = serializers.FloatField()
    fat = serializers.FloatField()
    fiber = serializers.FloatField()
    sugar = serializers.FloatField()
    image_url = serializers.CharField()
    found = serializers.BooleanField()


class HabitSerializer(serializers.ModelSerializer[Habit]):
    """Serializer for Habit model."""

    trainer_email = serializers.CharField(source='trainer.email', read_only=True)
    trainee_email = serializers.CharField(source='trainee.email', read_only=True)

    class Meta:
        model = Habit
        fields = [
            'id', 'trainer', 'trainer_email', 'trainee', 'trainee_email',
            'name', 'description', 'icon', 'frequency', 'custom_days',
            'is_active', 'created_at', 'updated_at',
        ]
        read_only_fields = ['trainer', 'created_at', 'updated_at']


class HabitCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for creating a habit."""

    trainee_id = serializers.IntegerField(required=True)
    name = serializers.CharField(max_length=200, required=True)
    description = serializers.CharField(required=False, allow_blank=True, default='')
    icon = serializers.CharField(max_length=50, required=False, default='check_circle')
    frequency = serializers.ChoiceField(
        choices=Habit.Frequency.choices,
        required=False,
        default='daily',
    )
    custom_days = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        default=list,
    )


class HabitLogSerializer(serializers.ModelSerializer[HabitLog]):
    """Serializer for HabitLog model."""

    habit_name = serializers.CharField(source='habit.name', read_only=True)

    class Meta:
        model = HabitLog
        fields = ['id', 'habit', 'habit_name', 'trainee', 'date', 'completed', 'created_at']
        read_only_fields = ['trainee', 'created_at']


class HabitToggleSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for toggling habit completion."""

    habit_id = serializers.IntegerField(required=True)
    date = serializers.DateField(required=False)


class HabitStreakSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for habit streak response."""

    habit_id = serializers.IntegerField()
    habit_name = serializers.CharField()
    current_streak = serializers.IntegerField()
    longest_streak = serializers.IntegerField()
    completion_rate_30d = serializers.FloatField()


# --- Phase 3: Supersets, Smart Progression, Deload Detection ---

class ProgressionSuggestionSerializer(serializers.ModelSerializer[ProgressionSuggestion]):
    """Serializer for ProgressionSuggestion model."""

    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    reviewed_by_email = serializers.CharField(
        source='reviewed_by.email', read_only=True, allow_null=True,
    )

    class Meta:
        model = ProgressionSuggestion
        fields = [
            'id', 'program', 'trainee', 'trainee_email',
            'exercise', 'exercise_name', 'suggestion_data',
            'status', 'reviewed_by', 'reviewed_by_email',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class DeloadCheckSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for deload check response."""

    needs_deload = serializers.BooleanField()
    confidence = serializers.FloatField()
    rationale = serializers.CharField()
    suggested_intensity_modifier = serializers.FloatField()
    suggested_volume_modifier = serializers.FloatField()
    weekly_volume_trend = serializers.ListField(child=serializers.FloatField())
    fatigue_signals = serializers.ListField(child=serializers.CharField())


# --- Phase 4: Social Sharing, PDF Export, Check-In Forms ---

class ShareCardSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for share card response."""

    workout_name = serializers.CharField()
    date = serializers.CharField()
    exercise_count = serializers.IntegerField()
    total_sets = serializers.IntegerField()
    total_volume = serializers.FloatField()
    volume_unit = serializers.CharField()
    duration = serializers.CharField()
    exercises = serializers.ListField(child=serializers.DictField())
    trainee_name = serializers.CharField()
    trainer_branding = serializers.DictField()


class CheckInTemplateSerializer(serializers.ModelSerializer[CheckInTemplate]):
    """Serializer for CheckInTemplate model."""

    trainer_email = serializers.CharField(source='trainer.email', read_only=True)

    class Meta:
        model = CheckInTemplate
        fields = [
            'id', 'trainer', 'trainer_email', 'name', 'frequency',
            'fields', 'is_active', 'created_at', 'updated_at',
        ]
        read_only_fields = ['trainer', 'created_at', 'updated_at']


class CheckInAssignmentSerializer(serializers.ModelSerializer[CheckInAssignment]):
    """Serializer for CheckInAssignment model."""

    template_name = serializers.CharField(source='template.name', read_only=True)
    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    template_fields = serializers.JSONField(source='template.fields', read_only=True)
    template_frequency = serializers.CharField(source='template.frequency', read_only=True)

    class Meta:
        model = CheckInAssignment
        fields = [
            'id', 'template', 'template_name', 'template_fields', 'template_frequency',
            'trainee', 'trainee_email', 'next_due_date',
            'is_active', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class CheckInAssignSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for assigning a check-in template to a trainee."""

    template_id = serializers.IntegerField(required=True)
    trainee_id = serializers.IntegerField(required=True)
    next_due_date = serializers.DateField(required=True)


class CheckInResponseSerializer(serializers.ModelSerializer[CheckInResponse]):
    """Serializer for CheckInResponse model."""

    trainee_email = serializers.CharField(source='trainee.email', read_only=True)
    template_name = serializers.CharField(source='assignment.template.name', read_only=True)

    class Meta:
        model = CheckInResponse
        fields = [
            'id', 'assignment', 'trainee', 'trainee_email', 'template_name',
            'responses', 'trainer_notes', 'submitted_at', 'updated_at',
        ]
        read_only_fields = ['trainee', 'submitted_at', 'updated_at']


class CheckInResponseCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for submitting a check-in response."""

    assignment_id = serializers.IntegerField(required=True)
    responses = serializers.ListField(
        child=serializers.DictField(),
        required=True,
    )


# --- Nutrition Template System (Phase 1) ---

class NutritionTemplateSerializer(serializers.ModelSerializer[NutritionTemplate]):
    """Read serializer for NutritionTemplate."""

    created_by_email = serializers.CharField(
        source='created_by.email', read_only=True, allow_null=True,
    )

    class Meta:
        model = NutritionTemplate
        fields = [
            'id', 'name', 'template_type', 'version', 'ruleset',
            'is_system', 'created_by', 'created_by_email',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class NutritionTemplateCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validation serializer for creating a custom NutritionTemplate."""

    name = serializers.CharField(max_length=255, required=True)
    template_type = serializers.ChoiceField(
        choices=NutritionTemplate.TemplateType.choices,
        required=False,
        default=NutritionTemplate.TemplateType.CUSTOM,
    )
    ruleset = serializers.JSONField(required=True)

    def validate_name(self, value: str) -> str:
        if not value.strip():
            raise serializers.ValidationError("Template name cannot be blank.")
        return value.strip()

    def validate_ruleset(self, value: Any) -> Any:
        if not isinstance(value, dict):
            raise serializers.ValidationError("Ruleset must be a JSON object.")
        return value


class NutritionTemplateAssignmentSerializer(
    serializers.ModelSerializer[NutritionTemplateAssignment],
):
    """Read serializer for NutritionTemplateAssignment."""

    trainee_email = serializers.CharField(
        source='trainee.email', read_only=True,
    )
    template_name = serializers.CharField(
        source='template.name', read_only=True,
    )
    template_type = serializers.CharField(
        source='template.template_type', read_only=True,
    )

    class Meta:
        model = NutritionTemplateAssignment
        fields = [
            'id', 'trainee', 'trainee_email',
            'template', 'template_name', 'template_type',
            'parameters', 'day_type_schedule', 'fat_mode',
            'is_active', 'activated_at',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['activated_at', 'created_at', 'updated_at']


class NutritionTemplateAssignmentCreateSerializer(
    serializers.Serializer[dict[str, Any]],
):
    """Validation serializer for assigning a template to a trainee."""

    trainee_id = serializers.IntegerField(required=True)
    template_id = serializers.IntegerField(required=True)
    parameters = serializers.JSONField(required=False, default=dict)
    day_type_schedule = serializers.JSONField(required=False, default=dict)
    fat_mode = serializers.ChoiceField(
        choices=NutritionTemplateAssignment.FatMode.choices,
        required=False,
        default=NutritionTemplateAssignment.FatMode.TOTAL_FAT,
    )

    def validate_parameters(self, value: Any) -> Any:
        if not isinstance(value, dict):
            raise serializers.ValidationError("Parameters must be a JSON object.")
        return value

    def validate_day_type_schedule(self, value: Any) -> Any:
        if not isinstance(value, dict):
            raise serializers.ValidationError("Day type schedule must be a JSON object.")
        method = value.get('method')
        if method and method not in ('training_based', 'weekly_rotation'):
            raise serializers.ValidationError(
                "Method must be 'training_based' or 'weekly_rotation'."
            )
        return value


class NutritionDayPlanSerializer(serializers.ModelSerializer[NutritionDayPlan]):
    """Read serializer for NutritionDayPlan."""

    trainee_email = serializers.CharField(
        source='trainee.email', read_only=True,
    )
    day_type_display = serializers.CharField(
        source='get_day_type_display', read_only=True,
    )

    class Meta:
        model = NutritionDayPlan
        fields = [
            'id', 'trainee', 'trainee_email', 'date',
            'day_type', 'day_type_display',
            'template_snapshot',
            'total_protein', 'total_carbs', 'total_fat', 'total_calories',
            'meals', 'fat_mode', 'is_overridden',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class NutritionDayPlanOverrideSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for trainer overriding a day plan."""

    total_protein = serializers.IntegerField(min_value=0, required=False)
    total_carbs = serializers.IntegerField(min_value=0, required=False)
    total_fat = serializers.IntegerField(min_value=0, required=False)
    total_calories = serializers.IntegerField(min_value=0, required=False)
    day_type = serializers.ChoiceField(
        choices=NutritionDayPlan.DayType.choices, required=False,
    )
    meals = serializers.JSONField(required=False)


# --- FoodItem & MealLog System (Phase 2) ---

class FoodItemSerializer(serializers.ModelSerializer[FoodItem]):
    """Read serializer for FoodItem."""

    created_by_email = serializers.CharField(
        source='created_by.email', read_only=True, allow_null=True,
    )

    class Meta:
        model = FoodItem
        fields = [
            'id', 'name', 'brand', 'serving_size', 'serving_unit',
            'calories', 'protein', 'carbs', 'fat',
            'fiber', 'sugar', 'sodium', 'barcode',
            'is_public', 'created_by', 'created_by_email',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at', 'created_by', 'is_public']


class FoodItemCreateSerializer(serializers.Serializer[dict[str, Any]]):
    """Validation serializer for creating a custom FoodItem."""

    name = serializers.CharField(max_length=255, required=True)
    brand = serializers.CharField(max_length=255, required=False, default='')
    serving_size = serializers.FloatField(min_value=0.01, required=False, default=1.0)
    serving_unit = serializers.ChoiceField(
        choices=FoodItem.ServingUnit.choices,
        required=False,
        default=FoodItem.ServingUnit.GRAMS,
    )
    calories = serializers.IntegerField(min_value=0, required=False, default=0)
    protein = serializers.FloatField(min_value=0, required=False, default=0)
    carbs = serializers.FloatField(min_value=0, required=False, default=0)
    fat = serializers.FloatField(min_value=0, required=False, default=0)
    fiber = serializers.FloatField(min_value=0, required=False, default=0)
    sugar = serializers.FloatField(min_value=0, required=False, default=0)
    sodium = serializers.FloatField(min_value=0, required=False, default=0)
    barcode = serializers.CharField(max_length=50, required=False, default='')

    def validate_name(self, value: str) -> str:
        if not value.strip():
            raise serializers.ValidationError("Food item name cannot be blank.")
        return value.strip()


class MealLogEntrySerializer(serializers.ModelSerializer[MealLogEntry]):
    """Read serializer for MealLogEntry, nested inside MealLogSerializer."""

    food_item_name = serializers.CharField(
        source='food_item.name', read_only=True, allow_null=True,
    )
    food_item_brand = serializers.CharField(
        source='food_item.brand', read_only=True, allow_null=True,
    )
    display_name = serializers.SerializerMethodField()

    class Meta:
        model = MealLogEntry
        fields = [
            'id', 'food_item', 'food_item_name', 'food_item_brand',
            'custom_name', 'display_name', 'quantity', 'serving_unit',
            'calories', 'protein', 'carbs', 'fat', 'fat_mode',
            'created_at',
        ]
        read_only_fields = ['created_at']

    def get_display_name(self, obj: MealLogEntry) -> str:
        return obj.display_name


class MealLogSerializer(serializers.ModelSerializer[MealLog]):
    """Read serializer for MealLog with nested entries."""

    entries = MealLogEntrySerializer(many=True, read_only=True)
    total_calories = serializers.SerializerMethodField()
    total_protein = serializers.SerializerMethodField()
    total_carbs = serializers.SerializerMethodField()
    total_fat = serializers.SerializerMethodField()

    class Meta:
        model = MealLog
        fields = [
            'id', 'trainee', 'date', 'meal_number', 'meal_name',
            'entries', 'total_calories', 'total_protein', 'total_carbs', 'total_fat',
            'logged_at',
        ]
        read_only_fields = ['trainee', 'logged_at']

    def _cached_entries(self, obj: MealLog) -> list[MealLogEntry]:
        if not hasattr(obj, '_cached_entry_list'):
            obj._cached_entry_list = list(obj.entries.all())  # type: ignore[attr-defined]
        return obj._cached_entry_list  # type: ignore[attr-defined]

    def get_total_calories(self, obj: MealLog) -> int:
        return sum(e.calories for e in self._cached_entries(obj))

    def get_total_protein(self, obj: MealLog) -> float:
        return round(sum(e.protein for e in self._cached_entries(obj)), 1)

    def get_total_carbs(self, obj: MealLog) -> float:
        return round(sum(e.carbs for e in self._cached_entries(obj)), 1)

    def get_total_fat(self, obj: MealLog) -> float:
        return round(sum(e.fat for e in self._cached_entries(obj)), 1)


class MealLogSummarySerializer(serializers.Serializer[dict[str, Any]]):
    """Response serializer for daily meal log summary."""

    date = serializers.DateField()
    total_calories = serializers.IntegerField()
    total_protein = serializers.FloatField()
    total_carbs = serializers.FloatField()
    total_fat = serializers.FloatField()
    meal_count = serializers.IntegerField()
    entry_count = serializers.IntegerField()


class QuickAddEntrySerializer(serializers.Serializer[dict[str, Any]]):
    """Validation serializer for quick-adding a food entry."""

    date = serializers.DateField(required=True)
    meal_number = serializers.IntegerField(min_value=1, max_value=6, required=True)
    meal_name = serializers.CharField(max_length=100, required=False, default='')

    # Either food_item_id (from database) or freeform entry
    food_item_id = serializers.IntegerField(required=False)
    custom_name = serializers.CharField(max_length=255, required=False, default='')

    quantity = serializers.FloatField(min_value=0.01, required=False, default=1.0)
    serving_unit = serializers.ChoiceField(
        choices=FoodItem.ServingUnit.choices,
        required=False,
        default=FoodItem.ServingUnit.SERVING,
    )

    # Manual macros (for freeform entries)
    calories = serializers.IntegerField(min_value=0, required=False, default=0)
    protein = serializers.FloatField(min_value=0, required=False, default=0)
    carbs = serializers.FloatField(min_value=0, required=False, default=0)
    fat = serializers.FloatField(min_value=0, required=False, default=0)

    fat_mode = serializers.ChoiceField(
        choices=MealLogEntry.FatMode.choices,
        required=False,
        default=MealLogEntry.FatMode.TOTAL_FAT,
    )

    def validate(self, data: dict[str, Any]) -> dict[str, Any]:
        food_item_id = data.get('food_item_id')
        custom_name = data.get('custom_name', '')

        if not food_item_id and not custom_name:
            raise serializers.ValidationError(
                "Either food_item_id or custom_name is required."
            )
        return data


# ---------------------------------------------------------------------------
# LiftSetLog + LiftMax serializers (v6.5 Step 3)
# ---------------------------------------------------------------------------

class LiftSetLogSerializer(serializers.ModelSerializer[LiftSetLog]):
    """
    Serializer for per-set performance logging.

    On create, trainee is auto-set to the requesting user.
    canonical_external_load and workload fields are computed on save — read-only here.
    """

    class Meta:
        model = LiftSetLog
        fields = [
            'id',
            'trainee',
            'exercise',
            'session_date',
            'set_number',
            'entered_load_value',
            'entered_load_unit',
            'load_entry_mode',
            'canonical_external_load_value',
            'canonical_external_load_unit',
            'workload_eligible',
            'completed_reps',
            'completed_time_seconds',
            'completed_distance_meters',
            'rpe',
            'standardization_pass',
            'set_workload_value',
            'set_workload_unit',
            'tempo_modifier',
            'notes',
            'created_at',
        ]
        read_only_fields = [
            'id',
            'trainee',
            'canonical_external_load_value',
            'canonical_external_load_unit',
            'set_workload_value',
            'set_workload_unit',
            'created_at',
        ]

    def validate_entered_load_value(self, value: Decimal) -> Decimal:
        if value < 0:
            raise serializers.ValidationError("Load value cannot be negative.")
        return value


class LiftMaxSerializer(serializers.ModelSerializer[LiftMax]):
    """Read-only serializer for cached estimated maxes."""

    exercise_name = serializers.CharField(source='exercise.name', read_only=True)

    class Meta:
        model = LiftMax
        fields = [
            'id',
            'trainee',
            'exercise',
            'exercise_name',
            'e1rm_current',
            'e1rm_history',
            'tm_current',
            'tm_percentage',
            'tm_history',
            'updated_at',
            'created_at',
        ]
        read_only_fields = fields


class LiftMaxPrescribeSerializer(serializers.Serializer[None]):
    """Input serializer for load prescription endpoint."""

    exercise_id = serializers.IntegerField()
    target_percentage = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        min_value=1,
        max_value=120,
        help_text="Target percentage of Training Max (e.g., 80 for 80%).",
    )
    rounding_increment = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=2.5,
        min_value=0,
        help_text="Round to nearest increment in lb/kg (default 2.5).",
    )
    trainee_id = serializers.IntegerField(
        required=False,
        help_text="Required for trainers/admins. Ignored for trainees.",
    )

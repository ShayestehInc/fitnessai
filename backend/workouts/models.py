"""
Workout and nutrition models for Fitness AI platform.
"""
from __future__ import annotations

from typing import Any

from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Exercise(models.Model):
    """
    Exercise library (Workout Bank).
    Can be system defaults (is_public=True) or trainer custom exercises.
    """
    class MuscleGroup(models.TextChoices):
        CHEST = 'chest', 'Chest'
        BACK = 'back', 'Back'
        SHOULDERS = 'shoulders', 'Shoulders'
        ARMS = 'arms', 'Arms'
        LEGS = 'legs', 'Legs'
        GLUTES = 'glutes', 'Glutes'
        CORE = 'core', 'Core'
        CARDIO = 'cardio', 'Cardio'
        FULL_BODY = 'full_body', 'Full Body'
        OTHER = 'other', 'Other'
    
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    video_url = models.URLField(blank=True, null=True)
    image_url = models.URLField(
        max_length=2048,
        blank=True,
        null=True,
        help_text="Thumbnail image URL for this exercise"
    )
    muscle_group = models.CharField(
        max_length=20,
        choices=MuscleGroup.choices,
        default=MuscleGroup.OTHER
    )
    
    # If is_public=False, this exercise belongs to a specific trainer
    is_public = models.BooleanField(
        default=True,
        help_text="True for system defaults, False for trainer custom exercises"
    )
    
    class DifficultyLevel(models.TextChoices):
        BEGINNER = 'beginner', 'Beginner'
        INTERMEDIATE = 'intermediate', 'Intermediate'
        ADVANCED = 'advanced', 'Advanced'

    difficulty_level = models.CharField(
        max_length=20,
        choices=DifficultyLevel.choices,
        null=True,
        blank=True,
        help_text="Exercise difficulty: beginner (machines/cables), intermediate (free weights), advanced (complex/specialty)"
    )

    suitable_for_goals = models.JSONField(
        default=list,
        blank=True,
        help_text=(
            "Training goals this exercise is best suited for. "
            "Values from: build_muscle, fat_loss, strength, endurance, recomp, general_fitness"
        ),
    )

    category = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text="KILO category or custom classification (e.g., 'Squat', 'Press', 'Cable Fly')"
    )

    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_exercises',
        limit_choices_to={'role': 'TRAINER'},
        help_text="Trainer who created this exercise (null for public/system exercises)"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'exercises'
        indexes = [
            models.Index(fields=['muscle_group']),
            models.Index(fields=['is_public']),
            models.Index(fields=['created_by']),
            models.Index(fields=['muscle_group', 'difficulty_level']),
        ]
    
    def __str__(self) -> str:
        return self.name


class Program(models.Model):
    """
    Training program assigned to a Trainee.
    Schedule is stored as JSON with strict structure for weeks/days.
    """
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='programs',
        limit_choices_to={'role': 'TRAINEE'}
    )
    
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    start_date = models.DateField()
    end_date = models.DateField()
    
    # JSON structure: {
    #   "weeks": [
    #     {
    #       "week_number": 1,
    #       "days": [
    #         {
    #           "day": "Monday",
    #           "exercises": [
    #             {
    #               "exercise_id": 1,
    #               "sets": 3,
    #               "reps": 8,
    #               "weight": 225,
    #               "unit": "lbs",
    #               "rest_seconds": 90
    #             }
    #           ]
    #         }
    #       ]
    #     }
    #   ]
    # }
    schedule = models.JSONField(
        default=dict,
        help_text="Structured program schedule with weeks and days"
    )

    # List of dates that were missed (format: ["2026-01-15", "2026-01-20"])
    missed_dates = models.JSONField(
        default=list,
        blank=True,
        help_text="List of dates when the trainee missed their workout"
    )

    is_active = models.BooleanField(default=True)

    image_url = models.URLField(
        blank=True,
        null=True,
        help_text="Thumbnail image URL for this program"
    )

    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_programs',
        limit_choices_to={'role': 'TRAINER'},
        help_text="Trainer who created this program"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'programs'
        indexes = [
            models.Index(fields=['trainee']),
            models.Index(fields=['is_active']),
            models.Index(fields=['start_date', 'end_date']),
        ]
        ordering = ['-created_at']
    
    def __str__(self) -> str:
        return f"{self.name} - {self.trainee.email}"


class DailyLog(models.Model):
    """
    Daily log entry for a Trainee.
    Contains nutrition data, workout data, and recovery metrics.
    """
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='daily_logs',
        limit_choices_to={'role': 'TRAINEE'}
    )
    
    date = models.DateField()
    
    # Nutrition data structure: {
    #   "meals": [
    #     {
    #       "name": "Chicken Bowl",
    #       "protein": 45,
    #       "carbs": 60,
    #       "fat": 20,
    #       "calories": 650,
    #       "timestamp": "2026-01-23T12:30:00Z"
    #     }
    #   ],
    #   "totals": {
    #     "protein": 150,
    #     "carbs": 200,
    #     "fat": 80,
    #     "calories": 2200
    #   }
    # }
    nutrition_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Nutrition log entries parsed from natural language"
    )
    
    # Workout data structure: {
    #   "exercises": [
    #     {
    #       "exercise_id": 1,
    #       "exercise_name": "Bench Press",
    #       "sets": [
    #         {
    #           "set_number": 1,
    #           "reps": 8,
    #           "weight": 225,
    #           "unit": "lbs",
    #           "completed": true
    #         }
    #       ],
    #       "timestamp": "2026-01-23T18:00:00Z"
    #     }
    #   ]
    # }
    workout_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Workout log entries parsed from natural language"
    )
    
    # Recovery metrics (synced from HealthKit/Health Connect)
    steps = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)]
    )
    
    sleep_hours = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(24.0)]
    )
    
    resting_heart_rate = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0)]
    )
    
    # Calculated recovery score (0-100)
    recovery_score = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Calculated recovery score based on sleep, HR, and activity"
    )
    
    notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'daily_logs'
        indexes = [
            models.Index(fields=['trainee', 'date']),
            models.Index(fields=['date']),
        ]
        unique_together = [['trainee', 'date']]
        ordering = ['-date']
    
    def __str__(self) -> str:
        return f"{self.trainee.email} - {self.date}"


class NutritionGoal(models.Model):
    """
    Daily nutrition macro goals for a trainee.
    Can be auto-calculated from profile or manually adjusted by trainer.
    """
    trainee = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='nutrition_goal',
        limit_choices_to={'role': 'TRAINEE'}
    )

    # Daily macro goals
    protein_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily protein goal in grams"
    )
    carbs_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily carbohydrate goal in grams"
    )
    fat_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily fat goal in grams"
    )
    calories_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily calorie goal"
    )

    # Per-meal targets (calculated from daily goals / meals_per_day)
    per_meal_protein = models.PositiveIntegerField(default=0)
    per_meal_carbs = models.PositiveIntegerField(default=0)
    per_meal_fat = models.PositiveIntegerField(default=0)

    # Trainer adjustment tracking
    is_trainer_adjusted = models.BooleanField(
        default=False,
        help_text="True if a trainer has manually adjusted these goals"
    )
    adjusted_by = models.ForeignKey(
        'users.User',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='adjusted_nutrition_goals',
        limit_choices_to={'role': 'TRAINER'}
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'nutrition_goals'

    def __str__(self) -> str:
        return f"Nutrition goals for {self.trainee.email}"


class MacroPreset(models.Model):
    """
    Macro presets for a trainee (e.g., Training Day, Non-Training Day, Growth Day).
    Trainers can create multiple presets for each trainee.
    """
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='macro_presets',
        limit_choices_to={'role': 'TRAINEE'}
    )

    name = models.CharField(
        max_length=100,
        help_text="Preset name (e.g., 'Training Day', 'Rest Day', 'Growth Day')"
    )

    # Macro values for this preset
    calories = models.PositiveIntegerField(default=2000)
    protein = models.PositiveIntegerField(default=150, help_text="Protein in grams")
    carbs = models.PositiveIntegerField(default=200, help_text="Carbs in grams")
    fat = models.PositiveIntegerField(default=70, help_text="Fat in grams")

    # Optional frequency hint (for display purposes)
    frequency_per_week = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="How many times per week this preset is typically used"
    )

    # Whether this is the default preset for the trainee
    is_default = models.BooleanField(
        default=False,
        help_text="If true, this preset is shown as the primary/default option"
    )

    # Display order
    sort_order = models.PositiveIntegerField(default=0)

    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_macro_presets',
        limit_choices_to={'role': 'TRAINER'}
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'macro_presets'
        ordering = ['sort_order', '-is_default', 'name']
        indexes = [
            models.Index(fields=['trainee']),
            models.Index(fields=['trainee', 'is_default']),
        ]

    def __str__(self) -> str:
        return f"{self.name} - {self.trainee.email}"

    def save(self, *args: Any, **kwargs: Any) -> None:
        # Ensure only one default per trainee
        if self.is_default:
            MacroPreset.objects.filter(
                trainee=self.trainee,
                is_default=True
            ).exclude(pk=self.pk).update(is_default=False)
        super().save(*args, **kwargs)


class WeightCheckIn(models.Model):
    """
    Weight check-in record for tracking progress over time.
    """
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='weight_checkins',
        limit_choices_to={'role': 'TRAINEE'}
    )
    date = models.DateField()
    weight_kg = models.FloatField(
        validators=[MinValueValidator(20.0), MaxValueValidator(500.0)]
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'weight_checkins'
        unique_together = [['trainee', 'date']]
        ordering = ['-date']
        indexes = [
            models.Index(fields=['trainee', 'date']),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} - {self.date}: {self.weight_kg}kg"


class ProgramTemplate(models.Model):
    """
    Reusable program templates for trainers.
    Can be assigned to multiple trainees to create individual Programs.
    """

    class DifficultyLevel(models.TextChoices):
        BEGINNER = 'beginner', 'Beginner'
        INTERMEDIATE = 'intermediate', 'Intermediate'
        ADVANCED = 'advanced', 'Advanced'

    class GoalType(models.TextChoices):
        BUILD_MUSCLE = 'build_muscle', 'Build Muscle'
        FAT_LOSS = 'fat_loss', 'Fat Loss'
        STRENGTH = 'strength', 'Strength'
        ENDURANCE = 'endurance', 'Endurance'
        RECOMP = 'recomp', 'Body Recomposition'
        GENERAL_FITNESS = 'general_fitness', 'General Fitness'

    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    duration_weeks = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(52)],
        help_text="Program duration in weeks"
    )

    # Schedule template structure (same as Program.schedule but as a template)
    schedule_template = models.JSONField(
        default=dict,
        help_text="Weekly workout schedule template"
    )

    # Nutrition template with base macros
    nutrition_template = models.JSONField(
        default=dict,
        help_text="Base nutrition guidelines and macro ratios"
    )

    difficulty_level = models.CharField(
        max_length=20,
        choices=DifficultyLevel.choices,
        default=DifficultyLevel.INTERMEDIATE
    )

    goal_type = models.CharField(
        max_length=20,
        choices=GoalType.choices,
        default=GoalType.BUILD_MUSCLE
    )

    image_url = models.URLField(
        blank=True,
        null=True,
        help_text="Thumbnail image URL for this program template"
    )

    # If public, other trainers can view and clone this template
    is_public = models.BooleanField(
        default=False,
        help_text="If True, template is visible to all trainers"
    )

    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_program_templates',
        limit_choices_to={'role': 'TRAINER'}
    )

    # Usage tracking
    times_used = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'program_templates'
        indexes = [
            models.Index(fields=['created_by']),
            models.Index(fields=['is_public']),
            models.Index(fields=['goal_type']),
            models.Index(fields=['difficulty_level']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.name} ({self.duration_weeks} weeks)"


class ProgramWeek(models.Model):
    """
    Week-specific workout configuration within a Program.
    Allows for progressive overload and periodization.
    """
    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        related_name='weeks'
    )
    week_number = models.PositiveIntegerField()

    # Week-specific workout schedule overrides
    workout_schedule = models.JSONField(
        default=dict,
        help_text="Workout details for this specific week"
    )

    # Nutrition adjustments for this week
    nutrition_adjustments = models.JSONField(
        default=dict,
        help_text="Adjustments to base nutrition (e.g., surplus/deficit changes)"
    )

    # Modifiers for progressive overload
    intensity_modifier = models.FloatField(
        default=1.0,
        validators=[MinValueValidator(0.5), MaxValueValidator(2.0)],
        help_text="Multiplier for weight/intensity (1.0 = 100%)"
    )

    volume_modifier = models.FloatField(
        default=1.0,
        validators=[MinValueValidator(0.5), MaxValueValidator(2.0)],
        help_text="Multiplier for sets/reps volume (1.0 = 100%)"
    )

    is_deload = models.BooleanField(
        default=False,
        help_text="Mark as deload/recovery week"
    )

    notes = models.TextField(
        blank=True,
        help_text="Special instructions or notes for this week"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'program_weeks'
        unique_together = [['program', 'week_number']]
        ordering = ['week_number']
        indexes = [
            models.Index(fields=['program', 'week_number']),
        ]

    def __str__(self) -> str:
        deload = " (Deload)" if self.is_deload else ""
        return f"Week {self.week_number}{deload} - {self.program.name}"


class WeeklyNutritionPlan(models.Model):
    """
    Week-specific nutrition targets within a Program.
    Allows for calorie cycling and periodic adjustments.
    """
    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        related_name='weekly_nutrition_plans'
    )
    week_number = models.PositiveIntegerField()

    # Daily macro targets
    protein_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily protein goal in grams"
    )
    carbs_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily carbohydrate goal in grams"
    )
    fat_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily fat goal in grams"
    )
    calories_goal = models.PositiveIntegerField(
        default=0,
        help_text="Daily calorie goal"
    )

    # Day-type modifiers for carb cycling
    training_day_carbs_modifier = models.FloatField(
        default=1.0,
        validators=[MinValueValidator(0.5), MaxValueValidator(2.0)],
        help_text="Carb multiplier for training days"
    )

    rest_day_carbs_modifier = models.FloatField(
        default=0.8,
        validators=[MinValueValidator(0.5), MaxValueValidator(2.0)],
        help_text="Carb multiplier for rest days"
    )

    # Optional high/low day specific targets
    high_day_calories = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Optional: Calories for high days (refeed)"
    )

    low_day_calories = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Optional: Calories for low days (deficit)"
    )

    notes = models.TextField(
        blank=True,
        help_text="Special dietary notes for this week"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'weekly_nutrition_plans'
        unique_together = [['program', 'week_number']]
        ordering = ['week_number']
        indexes = [
            models.Index(fields=['program', 'week_number']),
        ]

    def __str__(self) -> str:
        return f"Week {self.week_number} Nutrition - {self.program.name}"

    def get_training_day_macros(self) -> dict[str, int]:
        """Get macro targets for training days."""
        return {
            'protein': self.protein_goal,
            'carbs': int(self.carbs_goal * self.training_day_carbs_modifier),
            'fat': self.fat_goal,
            'calories': self.calories_goal
        }

    def get_rest_day_macros(self) -> dict[str, int]:
        """Get macro targets for rest days."""
        adjusted_carbs = int(self.carbs_goal * self.rest_day_carbs_modifier)
        carb_calorie_diff = (self.carbs_goal - adjusted_carbs) * 4
        return {
            'protein': self.protein_goal,
            'carbs': adjusted_carbs,
            'fat': self.fat_goal,
            'calories': self.calories_goal - carb_calorie_diff
        }


class WorkoutTemplate(models.Model):
    """
    Pre-defined workout templates for quick-logging non-program activities
    (e.g., cardio, sports, outdoor, flexibility).
    """

    class Category(models.TextChoices):
        CARDIO = 'cardio', 'Cardio'
        SPORTS = 'sports', 'Sports'
        OUTDOOR = 'outdoor', 'Outdoor'
        FLEXIBILITY = 'flexibility', 'Flexibility'
        OTHER = 'other', 'Other'

    name = models.CharField(max_length=255)
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.OTHER,
    )
    description = models.TextField(blank=True)
    estimated_duration_minutes = models.PositiveIntegerField(default=30)
    default_calories_per_minute = models.FloatField(
        default=5.0,
        validators=[MinValueValidator(0.1), MaxValueValidator(50.0)],
    )
    is_public = models.BooleanField(
        default=False,
        help_text="True for system defaults, False for trainer-created templates",
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_workout_templates',
        limit_choices_to={'role': 'TRAINER'},
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'workout_templates'
        ordering = ['category', 'name']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['is_public']),
            models.Index(fields=['created_by']),
        ]

    def __str__(self) -> str:
        return f"{self.name} ({self.get_category_display()})"


class ProgressPhoto(models.Model):
    """
    Progress photo entries for body composition tracking.
    Supports front/side/back photos with optional body measurements.
    """

    class PhotoCategory(models.TextChoices):
        FRONT = 'front', 'Front'
        SIDE = 'side', 'Side'
        BACK = 'back', 'Back'
        OTHER = 'other', 'Other'

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='progress_photos',
        limit_choices_to={'role': 'TRAINEE'},
    )
    photo = models.ImageField(upload_to='progress_photos/%Y/%m/')
    category = models.CharField(
        max_length=10,
        choices=PhotoCategory.choices,
        default=PhotoCategory.FRONT,
    )
    date = models.DateField()
    measurements = models.JSONField(
        default=dict,
        blank=True,
        help_text="Body measurements: {waist_cm, chest_cm, arms_cm, hips_cm, thighs_cm}",
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'progress_photos'
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['trainee', 'date']),
            models.Index(fields=['trainee', 'category']),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} - {self.date} ({self.get_category_display()})"


class Habit(models.Model):
    """
    Trackable habits assigned by trainers to trainees.
    Supports daily, weekday-only, or custom day schedules.
    """

    class Frequency(models.TextChoices):
        DAILY = 'daily', 'Daily'
        WEEKDAYS = 'weekdays', 'Weekdays'
        CUSTOM = 'custom', 'Custom'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_habits',
        limit_choices_to={'role': 'TRAINER'},
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='habits',
        limit_choices_to={'role': 'TRAINEE'},
    )
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, default='check_circle')
    frequency = models.CharField(
        max_length=20,
        choices=Frequency.choices,
        default=Frequency.DAILY,
    )
    custom_days = models.JSONField(
        default=list,
        blank=True,
        help_text="List of day names for custom frequency, e.g. ['Monday', 'Wednesday', 'Friday']",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'habits'
        ordering = ['name']
        indexes = [
            models.Index(fields=['trainee', 'is_active']),
            models.Index(fields=['trainer']),
        ]

    def __str__(self) -> str:
        return f"{self.name} - {self.trainee.email}"


class HabitLog(models.Model):
    """
    Daily completion log for a habit.
    One entry per habit per date.
    """

    habit = models.ForeignKey(
        Habit,
        on_delete=models.CASCADE,
        related_name='logs',
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='habit_logs',
        limit_choices_to={'role': 'TRAINEE'},
    )
    date = models.DateField()
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'habit_logs'
        unique_together = [['habit', 'date']]
        ordering = ['-date']
        indexes = [
            models.Index(fields=['trainee', 'date']),
            models.Index(fields=['habit', 'date']),
        ]

    def __str__(self) -> str:
        status = 'Done' if self.completed else 'Missed'
        return f"{self.habit.name} - {self.date} ({status})"


class ProgressionSuggestion(models.Model):
    """
    AI-generated progression suggestions for exercises within a program.
    Trainers can approve, dismiss, or auto-apply suggestions.
    """

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        APPROVED = 'approved', 'Approved'
        DISMISSED = 'dismissed', 'Dismissed'
        APPLIED = 'applied', 'Applied'

    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        related_name='progression_suggestions',
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='progression_suggestions',
        limit_choices_to={'role': 'TRAINEE'},
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='progression_suggestions',
    )
    suggestion_data = models.JSONField(
        help_text=(
            "Suggestion details: {current_weight, suggested_weight, current_reps, "
            "suggested_reps, current_sets, suggested_sets, rationale, confidence}"
        ),
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )
    reviewed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_progressions',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'progression_suggestions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['program', 'status']),
            models.Index(fields=['trainee', 'status']),
        ]

    def __str__(self) -> str:
        return f"Progression: {self.exercise.name} for {self.trainee.email} ({self.get_status_display()})"


class CheckInTemplate(models.Model):
    """
    Custom check-in form templates created by trainers.
    Supports multiple field types for flexible client check-ins.
    """

    class CheckInFrequency(models.TextChoices):
        WEEKLY = 'weekly', 'Weekly'
        BIWEEKLY = 'biweekly', 'Biweekly'
        MONTHLY = 'monthly', 'Monthly'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='checkin_templates',
        limit_choices_to={'role': 'TRAINER'},
    )
    name = models.CharField(max_length=200)
    frequency = models.CharField(
        max_length=20,
        choices=CheckInFrequency.choices,
        default=CheckInFrequency.WEEKLY,
    )
    fields = models.JSONField(
        help_text=(
            "Form field definitions: [{id, type: text|number|scale|multi_choice|photo, "
            "label, required, options}]"
        ),
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'checkin_templates'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainer']),
        ]

    def __str__(self) -> str:
        return f"{self.name} ({self.get_frequency_display()})"


class CheckInAssignment(models.Model):
    """
    Assignment of a check-in template to a trainee.
    Tracks next due date for automatic scheduling.
    """

    template = models.ForeignKey(
        CheckInTemplate,
        on_delete=models.CASCADE,
        related_name='assignments',
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='checkin_assignments',
        limit_choices_to={'role': 'TRAINEE'},
    )
    next_due_date = models.DateField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'checkin_assignments'
        ordering = ['next_due_date']
        indexes = [
            models.Index(fields=['trainee', 'is_active']),
            models.Index(fields=['next_due_date']),
        ]

    def __str__(self) -> str:
        return f"{self.template.name} → {self.trainee.email} (due {self.next_due_date})"


class CheckInResponse(models.Model):
    """
    Trainee's response to a check-in form.
    Stores responses as JSON matching the template's field definitions.
    """

    assignment = models.ForeignKey(
        CheckInAssignment,
        on_delete=models.CASCADE,
        related_name='responses',
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='checkin_responses',
        limit_choices_to={'role': 'TRAINEE'},
    )
    responses = models.JSONField(
        help_text="Completed form responses: [{field_id, value}]",
    )
    trainer_notes = models.TextField(blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'checkin_responses'
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['trainee', '-submitted_at']),
            models.Index(fields=['assignment']),
        ]

    def __str__(self) -> str:
        return f"Check-in response by {self.trainee.email} on {self.submitted_at}"


class NutritionTemplate(models.Model):
    """
    Template-driven nutrition system.
    Defines meal structure, macro formulas, and day-type mappings.
    System templates are immutable; trainers can create custom ones.
    """

    class TemplateType(models.TextChoices):
        LEGACY = 'legacy', 'Legacy'
        SHREDDED = 'shredded', 'Shredded'
        MASSIVE = 'massive', 'Massive'
        CARB_CYCLING = 'carb_cycling', 'Carb Cycling'
        MACRO_EBOOK = 'macro_ebook', 'Macro Ebook'
        CUSTOM = 'custom', 'Custom'

    name = models.CharField(max_length=255)
    template_type = models.CharField(
        max_length=20,
        choices=TemplateType.choices,
        default=TemplateType.CUSTOM,
    )
    version = models.PositiveIntegerField(default=1)
    ruleset = models.JSONField(
        default=dict,
        help_text=(
            "Template-type-specific configuration: meal definitions, "
            "formulas, day-type mappings, rounding rules"
        ),
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_nutrition_templates',
        help_text="Trainer who created this template (null for system templates)",
    )
    is_system = models.BooleanField(
        default=False,
        help_text="True for built-in system templates that cannot be edited",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'nutrition_templates'
        ordering = ['name']
        indexes = [
            models.Index(fields=['template_type']),
            models.Index(fields=['is_system']),
            models.Index(fields=['created_by']),
        ]

    def __str__(self) -> str:
        system_tag = " [System]" if self.is_system else ""
        return f"{self.name} ({self.get_template_type_display()}){system_tag}"


class NutritionTemplateAssignment(models.Model):
    """
    Assigns a NutritionTemplate to a trainee with trainee-specific parameters.
    Only one assignment per trainee can be active at a time.
    """

    class FatMode(models.TextChoices):
        TOTAL_FAT = 'total_fat', 'Total Fat'
        ADDED_FAT = 'added_fat', 'Added Fat'

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='nutrition_template_assignments',
        limit_choices_to={'role': 'TRAINEE'},
    )
    template = models.ForeignKey(
        NutritionTemplate,
        on_delete=models.PROTECT,
        related_name='assignments',
    )
    parameters = models.JSONField(
        default=dict,
        help_text=(
            "Trainee-specific parameters: "
            "{body_weight_lbs, body_fat_pct, lbm_lbs, meals_per_day}"
        ),
    )
    day_type_schedule = models.JSONField(
        default=dict,
        help_text=(
            "Day-type scheduling config: "
            "{method: 'training_based', training_days: 'high_carb', rest_days: 'low_carb'} "
            "or {method: 'weekly_rotation', monday: 'high_carb', ...}"
        ),
    )
    fat_mode = models.CharField(
        max_length=20,
        choices=FatMode.choices,
        default=FatMode.TOTAL_FAT,
    )
    is_active = models.BooleanField(default=True)
    activated_at = models.DateTimeField(auto_now_add=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'nutrition_template_assignments'
        ordering = ['-activated_at']
        indexes = [
            models.Index(fields=['trainee', 'is_active']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['trainee'],
                condition=models.Q(is_active=True),
                name='unique_active_nutrition_template_per_trainee',
            ),
        ]

    def __str__(self) -> str:
        status = "Active" if self.is_active else "Inactive"
        return f"{self.template.name} → {self.trainee.email} ({status})"

    def save(self, *args: Any, **kwargs: Any) -> None:
        if self.is_active:
            NutritionTemplateAssignment.objects.filter(
                trainee=self.trainee,
                is_active=True,
            ).exclude(pk=self.pk).update(is_active=False)
        super().save(*args, **kwargs)


class NutritionDayPlan(models.Model):
    """
    Server-generated per-date nutrition plan for a trainee.
    Contains day-type-aware macro targets split across meals.
    """

    class DayType(models.TextChoices):
        TRAINING = 'training', 'Training Day'
        REST = 'rest', 'Rest Day'
        HIGH_CARB = 'high_carb', 'High Carb Day'
        MEDIUM_CARB = 'medium_carb', 'Medium Carb Day'
        LOW_CARB = 'low_carb', 'Low Carb Day'
        REFEED = 'refeed', 'Refeed Day'
        MAINTENANCE = 'maintenance', 'Maintenance Day'
        DIET_BREAK = 'diet_break', 'Diet Break Day'

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='nutrition_day_plans',
        limit_choices_to={'role': 'TRAINEE'},
    )
    date = models.DateField()
    day_type = models.CharField(
        max_length=20,
        choices=DayType.choices,
        default=DayType.TRAINING,
    )
    template_snapshot = models.JSONField(
        default=dict,
        help_text="Frozen copy of template + parameters at generation time",
    )

    total_protein = models.PositiveIntegerField(default=0)
    total_carbs = models.PositiveIntegerField(default=0)
    total_fat = models.PositiveIntegerField(default=0)
    total_calories = models.PositiveIntegerField(default=0)

    meals = models.JSONField(
        default=list,
        help_text=(
            "Per-meal targets: "
            "[{meal_number, name, protein, carbs, fat, calories}, ...]"
        ),
    )
    fat_mode = models.CharField(
        max_length=20,
        choices=NutritionTemplateAssignment.FatMode.choices,
        default=NutritionTemplateAssignment.FatMode.TOTAL_FAT,
    )
    is_overridden = models.BooleanField(
        default=False,
        help_text="True if a trainer manually overrode this day's plan",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'nutrition_day_plans'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['trainee', 'date']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['trainee', 'date'],
                name='unique_nutrition_day_plan_per_date',
            ),
        ]

    def __str__(self) -> str:
        return f"{self.trainee.email} — {self.date} ({self.get_day_type_display()})"


class FoodItem(models.Model):
    """
    Food database item.
    Can be system defaults (is_public=True) or trainer-created custom foods.
    Follows the same visibility pattern as Exercise.
    """

    class ServingUnit(models.TextChoices):
        GRAMS = 'g', 'Grams'
        OUNCES = 'oz', 'Ounces'
        CUPS = 'cup', 'Cups'
        TABLESPOONS = 'tbsp', 'Tablespoons'
        TEASPOONS = 'tsp', 'Teaspoons'
        PIECES = 'piece', 'Pieces'
        SLICES = 'slice', 'Slices'
        ML = 'ml', 'Milliliters'
        FL_OZ = 'fl_oz', 'Fluid Ounces'
        SCOOP = 'scoop', 'Scoops'
        SERVING = 'serving', 'Servings'

    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, blank=True, default='')
    serving_size = models.FloatField(
        default=1.0,
        validators=[MinValueValidator(0.01)],
        help_text="Amount per serving (e.g. 100 for 100g)",
    )
    serving_unit = models.CharField(
        max_length=10,
        choices=ServingUnit.choices,
        default=ServingUnit.GRAMS,
    )

    # Macros per serving
    calories = models.PositiveIntegerField(default=0)
    protein = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Protein per serving in grams",
    )
    carbs = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Carbohydrates per serving in grams",
    )
    fat = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Fat per serving in grams",
    )
    fiber = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Fiber per serving in grams",
    )
    sugar = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Sugar per serving in grams",
    )
    sodium = models.FloatField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Sodium per serving in milligrams",
    )

    barcode = models.CharField(
        max_length=50,
        blank=True,
        default='',
        db_index=True,
        help_text="UPC/EAN barcode for scanning",
    )

    is_public = models.BooleanField(
        default=False,
        help_text="True for system foods, False for trainer-created custom foods",
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_food_items',
        help_text="Trainer who created this food item (null for system foods)",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'food_items'
        ordering = ['name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['is_public']),
            models.Index(fields=['created_by']),
            models.Index(fields=['brand']),
        ]

    def __str__(self) -> str:
        brand_str = f" ({self.brand})" if self.brand else ""
        return f"{self.name}{brand_str}"

    def save(self, *args: Any, **kwargs: Any) -> None:
        # Auto-calculate calories from macros if calories is 0 but macros are set
        if self.calories == 0 and (self.protein > 0 or self.carbs > 0 or self.fat > 0):
            self.calories = int(
                (self.protein * 4) + (self.carbs * 4) + (self.fat * 9)
            )
        super().save(*args, **kwargs)


class MealLog(models.Model):
    """
    Container for a single meal within a day.
    A trainee can have multiple meals per day (e.g. Meal 1 = Breakfast, Meal 2 = Lunch).
    """

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='meal_logs',
        limit_choices_to={'role': 'TRAINEE'},
    )
    date = models.DateField()
    meal_number = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(6)],
        help_text="Meal number (1-6)",
    )
    meal_name = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text="Optional label: Breakfast, Lunch, Snack, etc.",
    )
    logged_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'meal_logs'
        ordering = ['date', 'meal_number']
        indexes = [
            models.Index(fields=['trainee', 'date']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['trainee', 'date', 'meal_number'],
                name='unique_meal_per_day',
            ),
        ]

    def __str__(self) -> str:
        label = self.meal_name or f"Meal {self.meal_number}"
        return f"{self.trainee.email} — {self.date} — {label}"


class MealLogEntry(models.Model):
    """
    Individual food entry within a MealLog.
    Can reference a FoodItem or be a freeform entry (custom_name with manual macros).
    """

    class FatMode(models.TextChoices):
        TOTAL_FAT = 'total_fat', 'Total Fat'
        ADDED_FAT = 'added_fat', 'Added Fat'

    meal_log = models.ForeignKey(
        MealLog,
        on_delete=models.CASCADE,
        related_name='entries',
    )
    food_item = models.ForeignKey(
        FoodItem,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='meal_log_entries',
        help_text="Reference to food database item (null for freeform entries)",
    )
    custom_name = models.CharField(
        max_length=255,
        blank=True,
        default='',
        help_text="Name for freeform entries (used when food_item is null)",
    )
    quantity = models.FloatField(
        default=1.0,
        validators=[MinValueValidator(0.01)],
        help_text="Number of servings consumed",
    )
    serving_unit = models.CharField(
        max_length=10,
        choices=FoodItem.ServingUnit.choices,
        default=FoodItem.ServingUnit.SERVING,
    )

    # Computed macros (quantity * food_item macros, or manually entered for freeform)
    calories = models.PositiveIntegerField(default=0)
    protein = models.FloatField(default=0, validators=[MinValueValidator(0)])
    carbs = models.FloatField(default=0, validators=[MinValueValidator(0)])
    fat = models.FloatField(default=0, validators=[MinValueValidator(0)])

    fat_mode = models.CharField(
        max_length=20,
        choices=FatMode.choices,
        default=FatMode.TOTAL_FAT,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'meal_log_entries'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['meal_log']),
            models.Index(fields=['food_item']),
        ]

    def __str__(self) -> str:
        name = self.food_item.name if self.food_item else self.custom_name
        return f"{name} x{self.quantity}"

    @property
    def display_name(self) -> str:
        if self.food_item:
            return self.food_item.name
        return self.custom_name or "Unknown food"

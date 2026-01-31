"""
Workout and nutrition models for Fitness AI platform.
"""
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from typing import Optional, Dict, Any


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

    def save(self, *args, **kwargs):
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

    def get_training_day_macros(self) -> dict:
        """Get macro targets for training days."""
        return {
            'protein': self.protein_goal,
            'carbs': int(self.carbs_goal * self.training_day_carbs_modifier),
            'fat': self.fat_goal,
            'calories': self.calories_goal
        }

    def get_rest_day_macros(self) -> dict:
        """Get macro targets for rest days."""
        adjusted_carbs = int(self.carbs_goal * self.rest_day_carbs_modifier)
        carb_calorie_diff = (self.carbs_goal - adjusted_carbs) * 4
        return {
            'protein': self.protein_goal,
            'carbs': adjusted_carbs,
            'fat': self.fat_goal,
            'calories': self.calories_goal - carb_calorie_diff
        }

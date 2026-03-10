"""
Workout and nutrition models for Fitness AI platform.
"""
from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any

from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Exercise(models.Model):
    """
    Exercise library (Workout Bank) — the "ExerciseCard" from Trainer Packet v6.5.
    Can be system defaults (is_public=True) or trainer custom exercises.

    Rich tagging enables: exercise selection, swap system, workload-by-muscle analytics,
    program coverage checks, and safety filtering.
    """

    # --- Legacy muscle group (kept for backwards compatibility) ---
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

    # --- v6.5 Tag Taxonomy choices ---

    class PatternTag(models.TextChoices):
        KNEE_DOMINANT = 'knee_dominant', 'Knee Dominant'
        HIP_DOMINANT = 'hip_dominant', 'Hip Dominant'
        HORIZONTAL_PUSH = 'horizontal_push', 'Horizontal Push'
        HORIZONTAL_PULL = 'horizontal_pull', 'Horizontal Pull'
        VERTICAL_PUSH = 'vertical_push', 'Vertical Push'
        VERTICAL_PULL = 'vertical_pull', 'Vertical Pull'
        TRUNK_ANTI_EXTENSION = 'trunk_anti_extension', 'Trunk Anti-Extension'
        TRUNK_ANTI_FLEXION = 'trunk_anti_flexion', 'Trunk Anti-Flexion'
        TRUNK_ANTI_ROTATION = 'trunk_anti_rotation', 'Trunk Anti-Rotation'
        TRUNK_ROTATION = 'trunk_rotation', 'Trunk Rotation'
        TRUNK_LATERAL_FLEXION = 'trunk_lateral_flexion', 'Trunk Lateral Flexion'
        TRUNK_ANTI_LATERAL_FLEXION = 'trunk_anti_lateral_flexion', 'Trunk Anti-Lateral Flexion'
        PELVIS_FLEXION_EMPHASIS = 'pelvis_flexion_emphasis', 'Pelvis Flexion Emphasis'
        PELVIS_EXTENSION_EMPHASIS = 'pelvis_extension_emphasis', 'Pelvis Extension Emphasis'
        LOCOMOTION = 'locomotion', 'Locomotion'
        CARRIES = 'carries', 'Carries'

    class AthleticSkillTag(models.TextChoices):
        JUMP_VERTICAL = 'jump_vertical', 'Jump Vertical'
        JUMP_HORIZONTAL = 'jump_horizontal', 'Jump Horizontal'
        JUMP_LATERAL = 'jump_lateral', 'Jump Lateral'
        HOP_SINGLE_LEG_VERTICAL = 'hop_single_leg_vertical', 'Hop Single-Leg Vertical'
        HOP_SINGLE_LEG_HORIZONTAL = 'hop_single_leg_horizontal', 'Hop Single-Leg Horizontal'
        BOUND_ALTERNATING = 'bound_alternating', 'Bound Alternating'
        LANDING_AND_DECELERATION = 'landing_and_deceleration', 'Landing and Deceleration'
        SPRINT_ACCELERATION = 'sprint_acceleration', 'Sprint Acceleration'
        SPRINT_MAX_VELOCITY = 'sprint_max_velocity', 'Sprint Max Velocity'
        CHANGE_OF_DIRECTION_CUT = 'change_of_direction_cut', 'Change of Direction Cut'
        SHUFFLE_AND_LATERAL = 'shuffle_and_lateral', 'Shuffle and Lateral Movement'
        THROW_OVERHEAD = 'throw_overhead', 'Throw Overhead'
        THROW_ROTATIONAL = 'throw_rotational', 'Throw Rotational'
        THROW_CHEST_PASS = 'throw_chest_pass', 'Throw Chest Pass'
        OLYMPIC_LIFT_DERIVATIVE = 'olympic_lift_derivative', 'Olympic Lift Derivative'
        UPPER_BODY_PLYOMETRIC = 'upper_body_plyometric', 'Upper-Body Plyometric'
        MEDICINE_BALL_SLAM = 'medicine_ball_slam', 'Medicine Ball Slam'
        MEDICINE_BALL_SCOOP_TOSS = 'medicine_ball_scoop_toss', 'Medicine Ball Scoop Toss'
        REACTIVE_AGILITY_CUE_BASED = 'reactive_agility_cue_based', 'Reactive Agility Cue-Based'

    class AthleticAttributeTag(models.TextChoices):
        POWER = 'power', 'Power'
        ELASTICITY = 'elasticity', 'Elasticity'
        RATE_OF_FORCE_DEVELOPMENT = 'rate_of_force_development', 'Rate of Force Development'
        REACTIVE_STRENGTH_INDEX = 'reactive_strength_index', 'Reactive Strength Index'
        SPEED_LINEAR = 'speed_linear', 'Speed Linear'
        AGILITY_MULTI_DIRECTIONAL = 'agility_multi_directional', 'Agility Multi-Directional'
        COORDINATION = 'coordination', 'Coordination'
        STIFFNESS = 'stiffness', 'Stiffness'
        DECELERATION_CAPACITY = 'deceleration_capacity', 'Deceleration Capacity'
        WORK_CAPACITY = 'work_capacity', 'Work Capacity'

    class DetailedMuscleGroup(models.TextChoices):
        QUADS = 'quads', 'Quads'
        HAMSTRINGS = 'hamstrings', 'Hamstrings'
        GLUTES = 'glutes', 'Glutes'
        CALVES = 'calves', 'Calves'
        HIP_ADDUCTORS = 'hip_adductors', 'Hip Adductors'
        HIP_ABDUCTORS = 'hip_abductors', 'Hip Abductors'
        HIP_FLEXORS = 'hip_flexors', 'Hip Flexors'
        SPINAL_ERECTORS = 'spinal_erectors', 'Spinal Erectors'
        LATS = 'lats', 'Lats'
        MID_BACK = 'mid_back', 'Mid-Back'
        UPPER_TRAPS = 'upper_traps', 'Upper Traps'
        REAR_DELTS = 'rear_delts', 'Rear Delts'
        SIDE_DELTS = 'side_delts', 'Side Delts'
        FRONT_DELTS = 'front_delts', 'Front Delts'
        CHEST = 'chest', 'Chest'
        TRICEPS = 'triceps', 'Triceps'
        BICEPS = 'biceps', 'Biceps'
        FOREARMS_AND_GRIP = 'forearms_and_grip', 'Forearms and Grip'
        ABS_RECTUS = 'abs_rectus', 'Abs (Rectus)'
        OBLIQUES = 'obliques', 'Obliques'
        DEEP_CORE = 'deep_core', 'Deep Core'

    class Stance(models.TextChoices):
        SUPINE = 'supine', 'Supine'
        PRONE = 'prone', 'Prone'
        QUADRUPED = 'quadruped', 'Quadruped'
        TALL_KNEELING = 'tall_kneeling', 'Tall-Kneeling'
        HALF_KNEELING = 'half_kneeling', 'Half-Kneeling'
        SEATED_SUPPORTED = 'seated_supported', 'Seated Supported'
        STANDING_SUPPORTED = 'standing_supported', 'Standing (Rack/Machine-Supported)'
        BILATERAL_STANDING = 'bilateral_standing', 'Bilateral Standing (Symmetrical)'
        STAGGERED = 'staggered', 'Staggered (Split-Stance, Both Feet Down)'
        SPLIT_SQUAT_LUNGE = 'split_squat_lunge', 'Split Squat / Lunge (True Unilateral Bias)'
        SINGLE_LEG = 'single_leg', 'Single-Leg (True Single Support)'
        ATHLETIC_MULTIDIRECTIONAL = 'athletic_multidirectional', 'Athletic / Multidirectional'
        HANG_SUPPORT = 'hang_support', 'Hang / Support'

    class Plane(models.TextChoices):
        SAGITTAL = 'sagittal', 'Sagittal (Forward/Back)'
        FRONTAL = 'frontal', 'Frontal (Side-to-Side)'
        TRANSVERSE = 'transverse', 'Transverse (Rotation)'
        MIXED = 'mixed', 'Mixed / Multi-Planar'

    class RomBias(models.TextChoices):
        LENGTHENED = 'lengthened', 'Lengthened Bias (Peak Tension in Stretched Position)'
        MID_RANGE = 'mid_range', 'Mid-Range Bias (Peak Tension Near Middle)'
        SHORTENED = 'shortened', 'Shortened Bias (Peak Tension Near Shortened Position)'
        MIXED = 'mixed', 'Mixed (Unclear or Blended)'

    # --- Core fields ---
    name = models.CharField(max_length=255)
    aliases = ArrayField(
        models.CharField(max_length=255),
        default=list,
        blank=True,
        help_text="Alternative names for this exercise",
    )
    description = models.TextField(blank=True)
    video_url = models.URLField(blank=True, null=True)
    image_url = models.URLField(
        max_length=2048,
        blank=True,
        null=True,
        help_text="Thumbnail image URL for this exercise",
    )
    muscle_group = models.CharField(
        max_length=20,
        choices=MuscleGroup.choices,
        default=MuscleGroup.OTHER,
        help_text="Legacy single muscle group. Use muscle_contribution_map for v6.5+ logic.",
    )

    # If is_public=False, this exercise belongs to a specific trainer
    is_public = models.BooleanField(
        default=True,
        help_text="True for system defaults, False for trainer custom exercises",
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
        help_text="Exercise difficulty: beginner (machines/cables), intermediate (free weights), advanced (complex/specialty)",
    )

    suitable_for_goals = models.JSONField(
        default=list,
        blank=True,
        help_text="Training goals this exercise is best suited for.",
    )

    category = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text="KILO category or custom classification (e.g., 'Squat', 'Press', 'Cable Fly')",
    )

    # --- v6.5 ExerciseCard Tag Fields ---

    pattern_tags = ArrayField(
        models.CharField(max_length=50, choices=PatternTag.choices),
        default=list,
        blank=True,
        help_text="Movement intent tags (e.g., knee_dominant, horizontal_push). Drives program coverage.",
    )

    athletic_skill_tags = ArrayField(
        models.CharField(max_length=50, choices=AthleticSkillTag.choices),
        default=list,
        blank=True,
        help_text="Athletic skill tags (e.g., jump_vertical, sprint_acceleration). Can be empty.",
    )

    athletic_attribute_tags = ArrayField(
        models.CharField(max_length=50, choices=AthleticAttributeTag.choices),
        default=list,
        blank=True,
        help_text="Athletic attribute tags (e.g., power, elasticity). Can be empty.",
    )

    primary_muscle_group = models.CharField(
        max_length=30,
        choices=DetailedMuscleGroup.choices,
        blank=True,
        default='',
        help_text="Primary target muscle from the detailed v6.5 taxonomy.",
    )

    secondary_muscle_groups = ArrayField(
        models.CharField(max_length=30, choices=DetailedMuscleGroup.choices),
        default=list,
        blank=True,
        help_text="Secondary muscles worked by this exercise.",
    )

    muscle_contribution_map = models.JSONField(
        default=dict,
        blank=True,
        help_text="Map of {detailed_muscle_group: weight}. Weights must sum to 1.0. "
                  "E.g., {'quads': 0.6, 'glutes': 0.3, 'calves': 0.1}",
    )

    stance = models.CharField(
        max_length=40,
        choices=Stance.choices,
        blank=True,
        default='',
        help_text="How the user stands/positions during the exercise.",
    )

    plane = models.CharField(
        max_length=20,
        choices=Plane.choices,
        blank=True,
        default='',
        help_text="Primary movement plane (sagittal, frontal, transverse, mixed).",
    )

    rom_bias = models.CharField(
        max_length=20,
        choices=RomBias.choices,
        blank=True,
        default='',
        help_text="Where peak tension occurs in the range of motion.",
    )

    equipment_required = ArrayField(
        models.CharField(max_length=100),
        default=list,
        blank=True,
        help_text="Equipment that MUST be available (e.g., ['barbell', 'squat_rack']).",
    )

    equipment_optional = ArrayField(
        models.CharField(max_length=100),
        default=list,
        blank=True,
        help_text="Equipment that enhances the exercise but isn't required.",
    )

    athletic_constraints = models.JSONField(
        default=dict,
        blank=True,
        help_text="Constraint flags: {impact_level, ground_contacts_level, "
                  "space_required, surface_required, skill_demand}. "
                  "Values: low/moderate/high or true/false or small/medium/large.",
    )

    standardization_block = models.JSONField(
        default=dict,
        blank=True,
        help_text="Execution standards: {what_counts[], feel_checks[], fail_flags[], "
                  "default_dials[], assess_hooks[]}. Defines rep quality and safety.",
    )

    swap_seed_ids = models.JSONField(
        default=dict,
        blank=True,
        help_text="Pre-computed swap candidates: {recommended_same_muscle_ids[], "
                  "recommended_same_pattern_ids[]}.",
    )

    # --- Versioning (per v6.5 spec) ---
    version = models.PositiveIntegerField(
        default=1,
        help_text="Version number, incremented on each edit.",
    )

    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_exercises',
        limit_choices_to={'role': 'TRAINER'},
        help_text="Trainer who created this exercise (null for public/system exercises)",
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
            models.Index(fields=['stance']),
            models.Index(fields=['plane']),
            models.Index(fields=['primary_muscle_group']),
            GinIndex(fields=['pattern_tags'], name='exercises_pattern_tags_gin'),
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


# ---------------------------------------------------------------------------
# v6.5 Foundation: DecisionLog + UndoSnapshot
# Every automated decision must be explainable, overrideable, persisted, and
# logged with undo. These models form the audit backbone for ALL future
# decision-engine features (progression, swaps, deloads, imports, AI summaries).
# ---------------------------------------------------------------------------


class UndoSnapshot(models.Model):
    """
    Stores the before/after state so a decision can be reverted.
    Full-state snapshots (not diffs) for simplicity and reliability.
    """

    class Scope(models.TextChoices):
        SLOT = 'slot', 'Slot'
        SESSION = 'session', 'Session'
        WEEK = 'week', 'Week'
        EXERCISE = 'exercise', 'Exercise'
        NUTRITION_DAY = 'nutrition_day', 'Nutrition Day'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    scope = models.CharField(
        max_length=20,
        choices=Scope.choices,
        help_text="Granularity of what was changed.",
    )
    before_state = models.JSONField(
        help_text="Full state snapshot before the decision was applied.",
    )
    after_state = models.JSONField(
        help_text="Full state snapshot after the decision was applied.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    reverted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Timestamp when this snapshot was used to revert. Null if not yet reverted.",
    )

    class Meta:
        db_table = 'undo_snapshots'
        ordering = ['-created_at']

    def __str__(self) -> str:
        status = "reverted" if self.reverted_at else "active"
        return f"UndoSnapshot({self.scope}, {status}) {self.id}"

    @property
    def is_reverted(self) -> bool:
        return self.reverted_at is not None


class DecisionLog(models.Model):
    """
    Logs every automated decision the system makes.
    Required fields per v6.5 spec:
      inputs_snapshot → options_considered → filters_applied →
      scoring → final_choice → reason_codes → override_events → undo_pointer
    """

    class ActorType(models.TextChoices):
        SYSTEM = 'system', 'System'
        TRAINER = 'trainer', 'Trainer'
        USER = 'user', 'User'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField(auto_now_add=True)

    # Who made the decision
    actor_type = models.CharField(
        max_length=20,
        choices=ActorType.choices,
        help_text="Who/what triggered this decision.",
    )
    actor = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='decision_logs',
        help_text="The user who triggered (null for system-triggered decisions).",
    )

    # What was decided
    decision_type = models.CharField(
        max_length=100,
        help_text="Type of decision: exercise_swap, progression, deload_rewrite, "
                  "load_prescription, plan_generation, undo, etc.",
    )
    context = models.JSONField(
        default=dict,
        help_text="Where the decision applies: {plan_id, week_id, session_id, slot_id} "
                  "or {nutrition_day_id}.",
    )

    # Decision trail
    inputs_snapshot = models.JSONField(
        default=dict,
        help_text="Canonical snapshot of all inputs used to make the decision.",
    )
    constraints_applied = models.JSONField(
        default=dict,
        help_text="Filters and constraints that narrowed the options.",
    )
    options_considered = models.JSONField(
        default=list,
        help_text="Top N options with score breakdown: [{option, score, reasons}, ...].",
    )
    final_choice = models.JSONField(
        default=dict,
        help_text="The option that was selected.",
    )
    reason_codes = ArrayField(
        models.CharField(max_length=100),
        default=list,
        blank=True,
        help_text="Machine-readable reason codes (e.g., ['fatigue_high', 'pain_flag']).",
    )

    # Override tracking
    override_info = models.JSONField(
        null=True,
        blank=True,
        help_text="If a trainer/user overrode this decision: {overridden_by, original_choice, reason}.",
    )

    # Undo support
    undo_snapshot = models.OneToOneField(
        UndoSnapshot,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='decision',
        help_text="Snapshot for reverting this decision. Null if not undoable.",
    )

    class Meta:
        db_table = 'decision_logs'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['decision_type']),
            models.Index(fields=['actor_type']),
            models.Index(fields=['timestamp']),
            models.Index(fields=['actor']),
        ]

    def __str__(self) -> str:
        return f"DecisionLog({self.decision_type}, {self.actor_type}) {self.id}"

    @property
    def is_undoable(self) -> bool:
        return self.undo_snapshot is not None and not self.undo_snapshot.is_reverted


# ---------------------------------------------------------------------------
# v6.5 Step 3: LiftSetLog + LiftMax
# Per-set performance tracking and estimated max system.
# Replaces unstructured DailyLog.workout_data JSON for lift data.
# Powers: workload engine, progression, load prescription, analytics.
# ---------------------------------------------------------------------------


class LiftSetLog(models.Model):
    """
    Records a single completed set during training.
    Every set the trainee performs gets one row — this is the raw performance data
    that feeds e1RM estimation, workload calculation, and progression decisions.
    """

    class LoadEntryMode(models.TextChoices):
        TOTAL_LOAD = 'total_load', 'Total Load'
        PER_HAND = 'per_hand', 'Per Hand'
        BODYWEIGHT_PLUS_EXTERNAL = 'bodyweight_plus_external', 'Bodyweight + External'

    class LoadUnit(models.TextChoices):
        LB = 'lb', 'Pounds'
        KG = 'kg', 'Kilograms'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Who and what
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='lift_set_logs',
        limit_choices_to={'role': 'TRAINEE'},
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='lift_set_logs',
    )
    session_date = models.DateField(
        help_text="The date this set was performed.",
    )
    set_number = models.PositiveIntegerField(
        help_text="Ordinal within the exercise for this session (1-based).",
    )

    # What the user entered
    entered_load_value = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0,
        help_text="The load value as the user typed it.",
    )
    entered_load_unit = models.CharField(
        max_length=5,
        choices=LoadUnit.choices,
        default=LoadUnit.LB,
    )
    load_entry_mode = models.CharField(
        max_length=30,
        choices=LoadEntryMode.choices,
        default=LoadEntryMode.TOTAL_LOAD,
        help_text="How the user entered the load (total, per-hand, bodyweight+external).",
    )

    # Canonical (normalized for workload math)
    canonical_external_load_value = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0,
        help_text="Normalized external load for workload math. "
                  "Per-hand entries are doubled. BW+external is just the external portion.",
    )
    canonical_external_load_unit = models.CharField(
        max_length=5,
        choices=LoadUnit.choices,
        default=LoadUnit.LB,
    )
    workload_eligible = models.BooleanField(
        default=True,
        help_text="False if no valid load×reps representation exists (e.g., timed-only set).",
    )

    # Performance
    completed_reps = models.PositiveIntegerField(
        default=0,
        help_text="Reps actually completed.",
    )
    completed_time_seconds = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Duration for timed sets (planks, carries, etc.).",
    )
    completed_distance_meters = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Distance for carries, sprints, etc.",
    )
    rpe = models.DecimalField(
        max_digits=3,
        decimal_places=1,
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(10)],
        help_text="Rate of Perceived Exertion (1-10, half-points allowed).",
    )
    standardization_pass = models.BooleanField(
        default=False,
        help_text="Did this set meet the exercise's standardization criteria? "
                  "Only passing sets update e1RM. Default False (fail-closed).",
    )

    # Workload (computed, stored for fast queries)
    set_workload_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text="canonical_external_load × completed_reps (or 0 if not workload_eligible).",
    )
    set_workload_unit = models.CharField(
        max_length=10,
        default='lb_reps',
        help_text="Unit of workload: lb_reps or kg_reps.",
    )

    tempo_modifier = models.CharField(
        max_length=20,
        blank=True,
        default='',
        help_text="Tempo prescription if any (e.g., '3-1-2-0' = eccentric-pause-concentric-pause).",
    )

    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'lift_set_logs'
        ordering = ['session_date', 'set_number']
        indexes = [
            models.Index(fields=['trainee', 'session_date']),
            models.Index(fields=['trainee', 'exercise']),
            models.Index(fields=['exercise', 'session_date']),
            models.Index(fields=['session_date']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['trainee', 'exercise', 'session_date', 'set_number'],
                name='unique_set_per_exercise_per_session',
            ),
        ]

    def __str__(self) -> str:
        return (
            f"Set {self.set_number}: {self.exercise.name} "
            f"{self.canonical_external_load_value}{self.canonical_external_load_unit} "
            f"x{self.completed_reps} @ RPE {self.rpe or '?'}"
        )

    def save(self, *args: Any, **kwargs: Any) -> None:
        """Auto-compute canonical load and workload on save."""
        self._compute_canonical_load()
        self._compute_workload()
        super().save(*args, **kwargs)

    def _compute_canonical_load(self) -> None:
        """Normalize entered load to canonical external load."""
        value = self.entered_load_value
        if self.load_entry_mode == self.LoadEntryMode.PER_HAND:
            value = value * 2
        # For bodyweight+external, canonical is just the external portion (already correct)
        self.canonical_external_load_value = value
        self.canonical_external_load_unit = self.entered_load_unit

    def _compute_workload(self) -> None:
        """Compute set workload = canonical_load × completed_reps."""
        if not self.workload_eligible or self.completed_reps == 0:
            self.set_workload_value = 0
            return
        self.set_workload_value = self.canonical_external_load_value * self.completed_reps
        self.set_workload_unit = f"{self.canonical_external_load_unit}_reps"


class LiftMax(models.Model):
    """
    Cached estimated maxes per exercise per trainee.
    Updated automatically when a qualifying LiftSetLog is saved.
    Drives load prescription and progression decisions.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='lift_maxes',
        limit_choices_to={'role': 'TRAINEE'},
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='lift_maxes',
    )

    # Estimated 1RM
    e1rm_current = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0,
        help_text="Current estimated 1RM from best qualifying set.",
    )
    e1rm_history = models.JSONField(
        default=list,
        blank=True,
        help_text="List of {date, value, source_set_id, formula}.",
    )

    # Training max
    tm_current = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0,
        help_text="Training max = e1RM × tm_percentage. Coach-editable.",
    )
    tm_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=90,
        help_text="TM as percentage of e1RM (default 90%). Range: 80-100.",
        validators=[MinValueValidator(80), MaxValueValidator(100)],
    )
    tm_history = models.JSONField(
        default=list,
        blank=True,
        help_text="List of {date, value, reason, trigger}.",
    )

    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'lift_maxes'
        constraints = [
            models.UniqueConstraint(
                fields=['trainee', 'exercise'],
                name='unique_max_per_exercise_per_trainee',
            ),
        ]
        indexes = [
            models.Index(fields=['trainee']),
            models.Index(fields=['exercise']),
        ]

    def __str__(self) -> str:
        return f"LiftMax({self.exercise.name}) e1RM={self.e1rm_current} TM={self.tm_current}"


class WorkloadFactTemplate(models.Model):
    """
    Library of deterministic "cool fact" templates shown to trainees
    after completing an exercise or session.

    Selection is deterministic: same workload data = same fact every time.
    Templates are prioritized — highest priority matching template wins.
    """

    class Scope(models.TextChoices):
        EXERCISE = 'exercise', 'Exercise'
        SESSION = 'session', 'Session'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    scope = models.CharField(
        max_length=10,
        choices=Scope.choices,
        help_text="When this fact is shown: after an exercise or at end of session.",
    )
    template_text = models.TextField(
        help_text="Template with placeholders: {exercise_name}, {total_workload}, "
                  "{total_reps}, {set_count}, {unit}, {delta_percent}, {week_total}, "
                  "{top_exercise}, {muscle_group}.",
    )
    condition_rules = models.JSONField(
        default=dict,
        blank=True,
        help_text="Rules for when to select this template. "
                  "E.g., {'min_workload': 1000, 'has_comparison': true, 'delta_positive': true}.",
    )
    priority = models.PositiveIntegerField(
        default=100,
        help_text="Lower number = higher priority. First matching template wins.",
    )
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='workload_fact_templates',
        help_text="Trainer who created this template (null = system default).",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'workload_fact_templates'
        ordering = ['priority', 'scope']
        indexes = [
            models.Index(fields=['scope', 'is_active', 'priority']),
        ]

    def __str__(self) -> str:
        return f"WorkloadFact({self.scope}, priority={self.priority}): {self.template_text[:60]}"


# ---------------------------------------------------------------------------
# v6.5 Step 5: Training Generator Pipeline + Swap System
# Relational plan hierarchy replacing flat Program.schedule JSON.
# ---------------------------------------------------------------------------


class SplitTemplate(models.Model):
    """
    Reusable split definition: defines how training days are organized.
    System templates (is_system=True) are available to all trainers.
    Trainers can create custom templates for their trainees.
    """

    class GoalType(models.TextChoices):
        BUILD_MUSCLE = 'build_muscle', 'Build Muscle'
        FAT_LOSS = 'fat_loss', 'Fat Loss'
        STRENGTH = 'strength', 'Strength'
        ENDURANCE = 'endurance', 'Endurance'
        RECOMP = 'recomp', 'Recomposition'
        GENERAL_FITNESS = 'general_fitness', 'General Fitness'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    days_per_week = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(7)],
        help_text="Number of training days per week.",
    )
    session_definitions = models.JSONField(
        help_text=(
            "Ordered list of session blueprints. Each entry: "
            "{label: str, muscle_groups: [str], pattern_focus: [str]}. "
            "Length must equal days_per_week."
        ),
    )
    goal_type = models.CharField(
        max_length=20,
        choices=GoalType.choices,
        blank=True,
        default='',
        help_text="Primary goal this split is designed for (blank = general).",
    )
    is_system = models.BooleanField(
        default=False,
        help_text="True for platform-wide defaults (PPL, Upper/Lower, etc.).",
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='split_templates',
        help_text="Trainer who created this template (null = system).",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'split_templates'
        ordering = ['days_per_week', 'name']
        indexes = [
            models.Index(fields=['days_per_week', 'goal_type']),
            models.Index(fields=['is_system']),
        ]

    def __str__(self) -> str:
        return f"SplitTemplate({self.name}, {self.days_per_week}d/wk)"


class TrainingPlan(models.Model):
    """
    Top-level container for a periodized training plan.
    Replaces the flat Program.schedule JSON with a relational hierarchy:
    TrainingPlan → PlanWeek → PlanSession → PlanSlot.
    """

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'
        ARCHIVED = 'archived', 'Archived'

    class GoalType(models.TextChoices):
        BUILD_MUSCLE = 'build_muscle', 'Build Muscle'
        FAT_LOSS = 'fat_loss', 'Fat Loss'
        STRENGTH = 'strength', 'Strength'
        ENDURANCE = 'endurance', 'Endurance'
        RECOMP = 'recomp', 'Recomposition'
        GENERAL_FITNESS = 'general_fitness', 'General Fitness'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='training_plans',
        limit_choices_to={'role': 'TRAINEE'},
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    goal = models.CharField(max_length=20, choices=GoalType.choices)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    split_template = models.ForeignKey(
        SplitTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='training_plans',
        help_text="The split template used to generate this plan.",
    )
    difficulty = models.CharField(
        max_length=20,
        choices=Exercise.DifficultyLevel.choices,
        default='intermediate',
    )
    duration_weeks = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(52)],
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_training_plans',
        help_text="Trainer or admin who created this plan.",
    )
    default_progression_profile = models.ForeignKey(
        'ProgressionProfile',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='training_plans',
        help_text="Default progression profile for all slots in this plan. Overrideable per slot.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'training_plans'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee', 'status']),
            models.Index(fields=['created_by']),
        ]

    def __str__(self) -> str:
        return f"TrainingPlan({self.name}) for {self.trainee_id}"


class PlanWeek(models.Model):
    """
    A single week within a TrainingPlan.
    Contains modifiers for intensity/volume and deload flag.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(
        TrainingPlan,
        on_delete=models.CASCADE,
        related_name='weeks',
    )
    week_number = models.PositiveIntegerField()
    is_deload = models.BooleanField(default=False)
    intensity_modifier = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('1.00'),
        validators=[MinValueValidator(Decimal('0.30')), MaxValueValidator(Decimal('2.00'))],
        help_text="Multiplier for load/intensity (0.30–2.00).",
    )
    volume_modifier = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('1.00'),
        validators=[MinValueValidator(Decimal('0.30')), MaxValueValidator(Decimal('2.00'))],
        help_text="Multiplier for total volume (0.30–2.00).",
    )
    notes = models.TextField(blank=True, default='')

    class Meta:
        db_table = 'plan_weeks'
        ordering = ['week_number']
        constraints = [
            models.UniqueConstraint(
                fields=['plan', 'week_number'],
                name='unique_week_per_plan',
            ),
        ]

    def __str__(self) -> str:
        deload = " (deload)" if self.is_deload else ""
        return f"PlanWeek({self.plan_id}, wk{self.week_number}{deload})"


class PlanSession(models.Model):
    """
    A single training session within a PlanWeek.
    Represents one training day (e.g., "Upper A", "Push Day").
    """

    class DayOfWeek(models.IntegerChoices):
        MONDAY = 0, 'Monday'
        TUESDAY = 1, 'Tuesday'
        WEDNESDAY = 2, 'Wednesday'
        THURSDAY = 3, 'Thursday'
        FRIDAY = 4, 'Friday'
        SATURDAY = 5, 'Saturday'
        SUNDAY = 6, 'Sunday'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    week = models.ForeignKey(
        PlanWeek,
        on_delete=models.CASCADE,
        related_name='sessions',
    )
    day_of_week = models.IntegerField(
        choices=DayOfWeek.choices,
        help_text="0=Monday … 6=Sunday.",
    )
    label = models.CharField(
        max_length=100,
        help_text="Human-readable label, e.g., 'Upper A', 'Push Day'.",
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order within the week.",
    )

    class Meta:
        db_table = 'plan_sessions'
        ordering = ['order', 'day_of_week']
        constraints = [
            models.UniqueConstraint(
                fields=['week', 'day_of_week'],
                name='unique_session_per_day_per_week',
            ),
        ]

    def __str__(self) -> str:
        return f"PlanSession({self.label}, day={self.day_of_week})"


class PlanSlot(models.Model):
    """
    An individual exercise slot within a PlanSession.
    Holds the exercise assignment, set/rep prescription, and cached swap options.
    """

    class SlotRole(models.TextChoices):
        PRIMARY_COMPOUND = 'primary_compound', 'Primary Compound'
        SECONDARY_COMPOUND = 'secondary_compound', 'Secondary Compound'
        ACCESSORY = 'accessory', 'Accessory'
        ISOLATION = 'isolation', 'Isolation'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(
        PlanSession,
        on_delete=models.CASCADE,
        related_name='slots',
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.PROTECT,
        related_name='plan_slots',
        help_text="The assigned exercise for this slot.",
    )
    order = models.PositiveIntegerField(
        help_text="Display order within the session (1-based).",
    )
    slot_role = models.CharField(
        max_length=25,
        choices=SlotRole.choices,
        help_text="Role of this slot in the session structure.",
    )
    sets = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(20)],
    )
    reps_min = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(100)],
        help_text="Minimum reps in the prescribed rep range.",
    )
    reps_max = models.PositiveIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(100)],
        help_text="Maximum reps in the prescribed rep range.",
    )
    rest_seconds = models.PositiveIntegerField(
        default=90,
        validators=[MinValueValidator(0), MaxValueValidator(600)],
    )
    load_prescription_pct = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Percentage of Training Max to prescribe (e.g., 80.00).",
    )
    notes = models.TextField(blank=True, default='')
    swap_options_cache = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Pre-computed swap candidates: "
            "{same_muscle: [id, ...], same_pattern: [id, ...], explore: [id, ...]}."
        ),
    )
    set_structure_modality = models.ForeignKey(
        'SetStructureModality',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='plan_slots',
        help_text="The set structure modality for this slot (e.g., straight sets, drop sets).",
    )
    modality_details = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Modality-specific parameters (e.g., paired_exercise_id for supersets, "
            "tempo for eccentrics, fatigue_override for myo-reps)."
        ),
    )
    modality_volume_contribution = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Computed volume contribution: sets × modality volume_multiplier.",
    )
    progression_profile = models.ForeignKey(
        'ProgressionProfile',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='plan_slots',
        help_text="Slot-level progression profile override. Falls back to plan default if null.",
    )

    class Meta:
        db_table = 'plan_slots'
        ordering = ['order']
        constraints = [
            models.UniqueConstraint(
                fields=['session', 'order'],
                name='unique_slot_order_per_session',
            ),
        ]
        indexes = [
            models.Index(fields=['session', 'order']),
            models.Index(fields=['exercise']),
        ]

    def __str__(self) -> str:
        return (
            f"PlanSlot(order={self.order}, {self.slot_role}, "
            f"exercise={self.exercise_id})"
        )


class SetStructureModality(models.Model):
    """
    A set structure modality defines HOW an exercise should be performed
    (straight sets, drop sets, myo-reps, supersets, etc.).

    Each modality has:
    - Counting rules: volume_multiplier applied to sets for workload counting
    - Use/avoid conditions: JSON descriptions of when to use or avoid
    - Guardrails: related ModalityGuardrail rules for enforcement
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True, default='')
    volume_multiplier = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        default=Decimal('1.00'),
        validators=[MinValueValidator(Decimal('0.01')), MaxValueValidator(Decimal('3.00'))],
        help_text="Multiplier applied to each working set for volume counting (e.g., 0.67 for drop sets).",
    )
    use_when = models.JSONField(
        default=list,
        blank=True,
        help_text="List of conditions describing when to use this modality.",
    )
    avoid_when = models.JSONField(
        default=list,
        blank=True,
        help_text="List of conditions describing when to avoid this modality.",
    )
    is_system = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_modalities',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'set_structure_modalities'
        ordering = ['name']

    def __str__(self) -> str:
        return f"{self.name} ({self.volume_multiplier}x)"


class ModalityGuardrail(models.Model):
    """
    Enforcement rule for a modality. Defines conditions under which a modality
    should NOT be applied (or MUST be applied).

    rule_type:
    - 'avoid': modality should NOT be used when condition is met
    - 'require': modality MUST be used when condition is met

    condition_field: field to check on exercise or slot
    condition_operator: how to compare (has_any, has_none, gt, lt, eq, in)
    condition_value: value to compare against (JSON-encoded)
    """

    class RuleType(models.TextChoices):
        AVOID = 'avoid', 'Avoid'
        REQUIRE = 'require', 'Require'

    class ConditionOperator(models.TextChoices):
        HAS_ANY = 'has_any', 'Has Any'
        HAS_NONE = 'has_none', 'Has None'
        GT = 'gt', 'Greater Than'
        LT = 'lt', 'Less Than'
        EQ = 'eq', 'Equals'
        IN = 'in', 'In List'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    modality = models.ForeignKey(
        SetStructureModality,
        on_delete=models.CASCADE,
        related_name='guardrails',
    )
    rule_type = models.CharField(max_length=10, choices=RuleType.choices)
    condition_field = models.CharField(
        max_length=100,
        help_text="Field to check: 'exercise.athletic_skill_tags', 'slot.reps_max', 'slot.slot_role', etc.",
    )
    condition_operator = models.CharField(max_length=20, choices=ConditionOperator.choices)
    condition_value = models.JSONField(
        help_text="Value to compare against. JSON-encoded.",
    )
    error_message = models.CharField(
        max_length=500,
        help_text="Human-readable message when guardrail is violated.",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'modality_guardrails'
        ordering = ['modality', 'rule_type']
        indexes = [
            models.Index(fields=['modality', 'is_active']),
        ]

    def __str__(self) -> str:
        return f"Guardrail({self.modality.name}: {self.rule_type} when {self.condition_field} {self.condition_operator})"


class ProgressionProfile(models.Model):
    """
    A selectable template defining how progression works for a plan or exercise.

    Stores the progression style (staircase, wave, double progression, etc.) and
    all configuration as structured JSON: rules, deload_rules, failure_rules.
    Versioned, pinned to plan, overrideable per slot.
    """

    class ProgressionType(models.TextChoices):
        STAIRCASE_PERCENT = 'staircase_percent', 'Staircase Percent'
        REP_STAIRCASE = 'rep_staircase', 'Rep Staircase'
        WAVE_BY_MONTH = 'wave_by_month', 'Wave-by-Month'
        DOUBLE_PROGRESSION = 'double_progression', 'Double Progression'
        LINEAR = 'linear', 'Linear'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True, default='')
    progression_type = models.CharField(
        max_length=30,
        choices=ProgressionType.choices,
    )
    rules = models.JSONField(
        default=dict,
        help_text=(
            "Progression rules. Structure varies by type. "
            "E.g., {step_pct: 2.5, work_weeks: 4} for staircase_percent, "
            "{rep_step: 1, load_increment_upper_lb: 5} for rep_staircase."
        ),
    )
    deload_rules = models.JSONField(
        default=dict,
        help_text=(
            "Deload configuration. E.g., {volume_drop_pct: 40, intensity_drop_pct: 10, "
            "trigger_after_weeks: 4}."
        ),
    )
    failure_rules = models.JSONField(
        default=dict,
        help_text=(
            "Failure handling. E.g., {consecutive_failures_for_deload: 2, "
            "load_reduction_pct: 5, action: 'repeat_week'}."
        ),
    )
    is_system = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_progression_profiles',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'progression_profiles'
        ordering = ['name']
        indexes = [
            models.Index(fields=['is_system', 'created_by']),
        ]

    def __str__(self) -> str:
        return f"{self.name} ({self.progression_type})"


class ProgressionEvent(models.Model):
    """
    Records a progression decision for an exercise slot.
    Tracks what changed, why, and links to the DecisionLog for full audit trail.
    """

    class EventType(models.TextChoices):
        PROGRESSION = 'progression', 'Progression'
        DELOAD = 'deload', 'Deload'
        FAILURE = 'failure', 'Failure'
        RESET = 'reset', 'Reset'
        HOLD = 'hold', 'Hold'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='progression_events',
        limit_choices_to={'role': 'TRAINEE'},
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='progression_events',
    )
    plan_slot = models.ForeignKey(
        PlanSlot,
        on_delete=models.CASCADE,
        related_name='progression_events',
    )
    event_type = models.CharField(max_length=20, choices=EventType.choices)
    old_prescription = models.JSONField(
        default=dict,
        help_text="Previous prescription: {sets, reps_min, reps_max, load, percentage}.",
    )
    new_prescription = models.JSONField(
        default=dict,
        help_text="New prescription: {sets, reps_min, reps_max, load, percentage}.",
    )
    reason_codes = models.JSONField(
        default=list,
        help_text="Reason codes for the decision (e.g., ['all_sets_completed', 'rir_on_target']).",
    )
    decision_log = models.ForeignKey(
        DecisionLog,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='progression_events',
    )
    progression_profile = models.ForeignKey(
        ProgressionProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='events',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'progression_events'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee', 'exercise']),
            models.Index(fields=['plan_slot', '-created_at']),
        ]

    def __str__(self) -> str:
        return f"ProgressionEvent({self.event_type}, slot={self.plan_slot_id})"


class ActiveSession(models.Model):
    """
    Tracks an in-progress workout session for a trainee.
    Linked to a PlanSession (the template) and contains ActiveSetLog entries
    for each prescribed set. Only one active (in_progress) session per trainee
    is allowed, enforced by a partial unique constraint.
    """

    class Status(models.TextChoices):
        NOT_STARTED = 'not_started', 'Not Started'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        ABANDONED = 'abandoned', 'Abandoned'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='active_sessions',
        limit_choices_to={'role': 'TRAINEE'},
    )
    plan_session = models.ForeignKey(
        PlanSession,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='active_sessions',
        help_text="The PlanSession template this session was started from. "
                  "SET_NULL so sessions survive plan deletion.",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.NOT_STARTED,
    )
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the trainee started the session.",
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the session was completed or abandoned.",
    )
    abandon_reason = models.CharField(
        max_length=255,
        blank=True,
        default='',
        help_text="Reason for abandonment (e.g., 'auto_abandoned_stale', user-provided).",
    )
    current_slot_index = models.PositiveIntegerField(
        default=0,
        help_text="Zero-based index of the current slot in the session.",
    )
    notes = models.TextField(
        blank=True,
        default='',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'active_sessions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee', 'status']),
            models.Index(fields=['trainee', '-created_at']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['trainee'],
                condition=models.Q(status='in_progress'),
                name='unique_active_session_per_trainee',
            ),
        ]

    def __str__(self) -> str:
        label = self.plan_session.label if self.plan_session else 'unknown'
        return f"ActiveSession({self.status}, {label})"


class ActiveSetLog(models.Model):
    """
    Per-set tracking entry within an active session.
    Pre-populated from PlanSlot prescriptions when a session starts.
    Each row represents one prescribed set — trainee fills in actual performance.
    Completed entries are copied to LiftSetLog on session completion.
    """

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        COMPLETED = 'completed', 'Completed'
        SKIPPED = 'skipped', 'Skipped'

    class LoadUnit(models.TextChoices):
        LB = 'lb', 'Pounds'
        KG = 'kg', 'Kilograms'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    active_session = models.ForeignKey(
        ActiveSession,
        on_delete=models.CASCADE,
        related_name='set_logs',
    )
    plan_slot = models.ForeignKey(
        PlanSlot,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='active_set_logs',
        help_text="The PlanSlot this set belongs to. SET_NULL to survive plan changes.",
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.CASCADE,
        related_name='active_set_logs',
        help_text="Denormalized from PlanSlot for faster reads.",
    )
    set_number = models.PositiveSmallIntegerField(
        help_text="1-based set number within this slot.",
    )

    # Prescription (filled on session start from progression engine)
    prescribed_reps_min = models.PositiveIntegerField(
        help_text="Minimum reps prescribed.",
    )
    prescribed_reps_max = models.PositiveIntegerField(
        help_text="Maximum reps prescribed.",
    )
    prescribed_load = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Prescribed load value (null if no prescription / bodyweight).",
    )
    prescribed_load_unit = models.CharField(
        max_length=5,
        choices=LoadUnit.choices,
        default=LoadUnit.LB,
    )

    # Actual performance (filled by trainee during session)
    completed_reps = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Reps actually completed (can be 0 for failed attempt).",
    )
    completed_load_value = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Actual load used.",
    )
    completed_load_unit = models.CharField(
        max_length=5,
        choices=LoadUnit.choices,
        default=LoadUnit.LB,
    )
    rpe = models.DecimalField(
        max_digits=3,
        decimal_places=1,
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(10)],
        help_text="Rate of Perceived Exertion (1-10).",
    )

    # Rest
    rest_prescribed_seconds = models.PositiveIntegerField(
        default=90,
        help_text="Prescribed rest duration in seconds.",
    )
    rest_actual_seconds = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="Actual rest taken by trainee (tracked by client timer).",
    )

    # Timing
    set_started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the trainee started this set.",
    )
    set_completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the trainee finished this set.",
    )

    # Status
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
    )
    skip_reason = models.CharField(
        max_length=255,
        blank=True,
        default='',
    )
    notes = models.TextField(
        blank=True,
        default='',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'active_set_logs'
        ordering = ['plan_slot__order', 'set_number']
        indexes = [
            models.Index(fields=['active_session', 'status']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['active_session', 'plan_slot', 'set_number'],
                name='unique_set_per_slot_per_session',
            ),
        ]

    def __str__(self) -> str:
        return (
            f"ActiveSetLog(set={self.set_number}, "
            f"exercise={self.exercise_id}, status={self.status})"
        )


# ---------------------------------------------------------------------------
# Session Feedback & Pain Events (v6.5 Step 9)
# ---------------------------------------------------------------------------

class SessionFeedback(models.Model):
    """
    End-of-session feedback from a trainee.
    One feedback per ActiveSession. Drives trainer routing rules.
    """

    class CompletionState(models.TextChoices):
        COMPLETED = 'completed', 'Completed'
        PARTIAL = 'partial', 'Partial'
        ABANDONED = 'abandoned', 'Abandoned'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    active_session = models.OneToOneField(
        ActiveSession,
        on_delete=models.CASCADE,
        related_name='feedback',
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='session_feedbacks',
        limit_choices_to={'role': 'TRAINEE'},
    )
    completion_state = models.CharField(
        max_length=20,
        choices=CompletionState.choices,
    )

    # Ratings (1-5 scale, all optional to allow partial feedback)
    rating_overall = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    rating_muscle_feel = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    rating_energy = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    rating_confidence = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    rating_enjoyment = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    rating_difficulty = models.PositiveSmallIntegerField(
        null=True, blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )

    friction_reasons = models.JSONField(
        default=list,
        help_text=(
            "List of friction reasons: too_heavy, too_light, time_pressure, "
            "pain, form_breakdown, fatigue, equipment_unavailable, other."
        ),
    )
    recovery_concern = models.BooleanField(default=False)
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'session_feedbacks'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee', '-created_at']),
        ]

    def __str__(self) -> str:
        return f"SessionFeedback(session={self.active_session_id}, overall={self.rating_overall})"


class PainEvent(models.Model):
    """
    Records pain or discomfort reported by a trainee.
    Can be linked to a session or logged standalone.
    """

    class BodyRegion(models.TextChoices):
        NECK = 'neck', 'Neck'
        SHOULDER_LEFT = 'shoulder_left', 'Left Shoulder'
        SHOULDER_RIGHT = 'shoulder_right', 'Right Shoulder'
        UPPER_BACK = 'upper_back', 'Upper Back'
        LOWER_BACK = 'lower_back', 'Lower Back'
        CHEST = 'chest', 'Chest'
        ELBOW_LEFT = 'elbow_left', 'Left Elbow'
        ELBOW_RIGHT = 'elbow_right', 'Right Elbow'
        WRIST_LEFT = 'wrist_left', 'Left Wrist'
        WRIST_RIGHT = 'wrist_right', 'Right Wrist'
        HIP_LEFT = 'hip_left', 'Left Hip'
        HIP_RIGHT = 'hip_right', 'Right Hip'
        KNEE_LEFT = 'knee_left', 'Left Knee'
        KNEE_RIGHT = 'knee_right', 'Right Knee'
        ANKLE_LEFT = 'ankle_left', 'Left Ankle'
        ANKLE_RIGHT = 'ankle_right', 'Right Ankle'
        OTHER = 'other', 'Other'

    class Side(models.TextChoices):
        LEFT = 'left', 'Left'
        RIGHT = 'right', 'Right'
        BILATERAL = 'bilateral', 'Bilateral'
        MIDLINE = 'midline', 'Midline'

    class SensationType(models.TextChoices):
        SHARP = 'sharp', 'Sharp'
        DULL = 'dull', 'Dull'
        BURNING = 'burning', 'Burning'
        ACHING = 'aching', 'Aching'
        TIGHTNESS = 'tightness', 'Tightness'
        NUMBNESS = 'numbness', 'Numbness'
        OTHER = 'other', 'Other'

    class OnsetPhase(models.TextChoices):
        WARMUP = 'warmup', 'Warm-up'
        WORKING_SET = 'working_set', 'Working Set'
        BETWEEN_SETS = 'between_sets', 'Between Sets'
        COOLDOWN = 'cooldown', 'Cooldown'
        POST_SESSION = 'post_session', 'Post-Session'

    class WarmupEffect(models.TextChoices):
        BETTER = 'better', 'Better'
        SAME = 'same', 'Same'
        WORSE = 'worse', 'Worse'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='pain_events',
        limit_choices_to={'role': 'TRAINEE'},
    )
    active_session = models.ForeignKey(
        ActiveSession,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pain_events',
    )
    exercise = models.ForeignKey(
        Exercise,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pain_events',
    )
    body_region = models.CharField(max_length=30, choices=BodyRegion.choices)
    side = models.CharField(max_length=20, choices=Side.choices, default=Side.MIDLINE)
    pain_score = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)],
    )
    sensation_type = models.CharField(
        max_length=20,
        choices=SensationType.choices,
        default=SensationType.OTHER,
    )
    onset_phase = models.CharField(
        max_length=20,
        choices=OnsetPhase.choices,
        blank=True,
        default='',
    )
    warmup_effect = models.CharField(
        max_length=20,
        choices=WarmupEffect.choices,
        blank=True,
        default='',
    )
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'pain_events'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainee', '-created_at']),
            models.Index(fields=['trainee', 'body_region']),
        ]

    def __str__(self) -> str:
        return f"PainEvent({self.body_region}, score={self.pain_score})"


class TrainerRoutingRule(models.Model):
    """
    Configurable rules for when to alert a trainer based on trainee feedback.
    Each rule defines a trigger type, threshold, and notification method.
    """

    class RuleType(models.TextChoices):
        LOW_RATING = 'low_rating', 'Low Rating'
        PAIN_REPORT = 'pain_report', 'Pain Report'
        MISSED_SESSIONS = 'missed_sessions', 'Missed Sessions'
        HIGH_DIFFICULTY = 'high_difficulty', 'High Difficulty'
        RECOVERY_CONCERN = 'recovery_concern', 'Recovery Concern'
        FORM_BREAKDOWN = 'form_breakdown', 'Form Breakdown'

    class NotificationMethod(models.TextChoices):
        IN_APP = 'in_app', 'In-App'
        EMAIL = 'email', 'Email'
        BOTH = 'both', 'Both'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='routing_rules',
        limit_choices_to={'role': 'TRAINER'},
    )
    rule_type = models.CharField(max_length=30, choices=RuleType.choices)
    threshold_value = models.JSONField(
        default=dict,
        help_text=(
            "Threshold config. E.g., {min_rating: 2} for low_rating, "
            "{min_pain_score: 7} for pain_report, {consecutive_missed: 3} for missed_sessions."
        ),
    )
    notification_method = models.CharField(
        max_length=20,
        choices=NotificationMethod.choices,
        default=NotificationMethod.IN_APP,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'trainer_routing_rules'
        ordering = ['rule_type']
        constraints = [
            models.UniqueConstraint(
                fields=['trainer', 'rule_type'],
                name='unique_rule_per_trainer_per_type',
            ),
        ]

    def __str__(self) -> str:
        return f"RoutingRule({self.trainer_id}, {self.rule_type})"

"""
Workout and nutrition models for Fitness AI platform.
"""
from __future__ import annotations

import uuid
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

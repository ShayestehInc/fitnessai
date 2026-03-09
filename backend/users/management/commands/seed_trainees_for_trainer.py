"""
Management command to seed mock trainees for an existing trainer.
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.core.management.base import BaseCommand, CommandParser
from django.utils import timezone

from users.models import User, UserProfile
from workouts.models import NutritionGoal, Program


MOCK_TRAINEES: list[dict[str, Any]] = [
    {
        'email': 'alex.rivera@example.com',
        'first_name': 'Alex',
        'last_name': 'Rivera',
        'profile': {
            'sex': 'male',
            'age': 26,
            'height_cm': 178,
            'weight_kg': 84,
            'activity_level': 'very_active',
            'goal': 'build_muscle',
            'diet_type': 'high_carb',
            'meals_per_day': 5,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 200,
            'carbs_goal': 350,
            'fat_goal': 75,
            'calories_goal': 3100,
        },
    },
    {
        'email': 'jessica.chen@example.com',
        'first_name': 'Jessica',
        'last_name': 'Chen',
        'profile': {
            'sex': 'female',
            'age': 29,
            'height_cm': 163,
            'weight_kg': 58,
            'activity_level': 'moderately_active',
            'goal': 'fat_loss',
            'diet_type': 'low_carb',
            'meals_per_day': 4,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 125,
            'carbs_goal': 130,
            'fat_goal': 55,
            'calories_goal': 1550,
        },
    },
    {
        'email': 'marcus.johnson@example.com',
        'first_name': 'Marcus',
        'last_name': 'Johnson',
        'profile': {
            'sex': 'male',
            'age': 34,
            'height_cm': 188,
            'weight_kg': 95,
            'activity_level': 'extremely_active',
            'goal': 'build_muscle',
            'diet_type': 'balanced',
            'meals_per_day': 5,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 220,
            'carbs_goal': 400,
            'fat_goal': 90,
            'calories_goal': 3500,
        },
    },
    {
        'email': 'sophia.martinez@example.com',
        'first_name': 'Sophia',
        'last_name': 'Martinez',
        'profile': {
            'sex': 'female',
            'age': 24,
            'height_cm': 170,
            'weight_kg': 65,
            'activity_level': 'moderately_active',
            'goal': 'recomp',
            'diet_type': 'balanced',
            'meals_per_day': 4,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 140,
            'carbs_goal': 200,
            'fat_goal': 65,
            'calories_goal': 2000,
        },
    },
    {
        'email': 'daniel.kim@example.com',
        'first_name': 'Daniel',
        'last_name': 'Kim',
        'profile': {
            'sex': 'male',
            'age': 31,
            'height_cm': 173,
            'weight_kg': 78,
            'activity_level': 'lightly_active',
            'goal': 'fat_loss',
            'diet_type': 'low_carb',
            'meals_per_day': 3,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 170,
            'carbs_goal': 180,
            'fat_goal': 60,
            'calories_goal': 2000,
        },
    },
    {
        'email': 'emma.wilson@example.com',
        'first_name': 'Emma',
        'last_name': 'Wilson',
        'profile': {
            'sex': 'female',
            'age': 27,
            'height_cm': 160,
            'weight_kg': 55,
            'activity_level': 'very_active',
            'goal': 'build_muscle',
            'diet_type': 'high_carb',
            'meals_per_day': 4,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 120,
            'carbs_goal': 250,
            'fat_goal': 50,
            'calories_goal': 2000,
        },
    },
    {
        'email': 'ryan.patel@example.com',
        'first_name': 'Ryan',
        'last_name': 'Patel',
        'profile': {
            'sex': 'male',
            'age': 22,
            'height_cm': 182,
            'weight_kg': 72,
            'activity_level': 'moderately_active',
            'goal': 'build_muscle',
            'diet_type': 'balanced',
            'meals_per_day': 4,
            'onboarding_completed': False,
        },
        'nutrition_goal': {
            'protein_goal': 160,
            'carbs_goal': 280,
            'fat_goal': 70,
            'calories_goal': 2500,
        },
    },
    {
        'email': 'olivia.nguyen@example.com',
        'first_name': 'Olivia',
        'last_name': 'Nguyen',
        'profile': {
            'sex': 'female',
            'age': 30,
            'height_cm': 167,
            'weight_kg': 61,
            'activity_level': 'very_active',
            'goal': 'recomp',
            'diet_type': 'balanced',
            'meals_per_day': 4,
            'onboarding_completed': True,
        },
        'nutrition_goal': {
            'protein_goal': 135,
            'carbs_goal': 210,
            'fat_goal': 60,
            'calories_goal': 1950,
        },
    },
]

SAMPLE_PROGRAMS: list[dict[str, Any]] = [
    {
        'name': 'Hypertrophy Block A',
        'description': '4-week hypertrophy program — upper/lower split with progressive overload.',
        'schedule': {
            'weeks': [
                {
                    'week_number': 1,
                    'days': [
                        {
                            'day': 'Monday',
                            'name': 'Upper Body',
                            'exercises': [
                                {'exercise_name': 'Barbell Bench Press', 'sets': 4, 'reps': 10, 'weight': 155, 'unit': 'lbs'},
                                {'exercise_name': 'Barbell Bent-Over Row', 'sets': 4, 'reps': 10, 'weight': 135, 'unit': 'lbs'},
                                {'exercise_name': 'Barbell Overhead Press', 'sets': 3, 'reps': 10, 'weight': 85, 'unit': 'lbs'},
                                {'exercise_name': 'Dumbbell Lateral Raises', 'sets': 3, 'reps': 15, 'weight': 15, 'unit': 'lbs'},
                                {'exercise_name': 'Barbell Bicep Curl', 'sets': 3, 'reps': 12, 'weight': 55, 'unit': 'lbs'},
                                {'exercise_name': 'Tricep Pushdown (Rope)', 'sets': 3, 'reps': 12, 'weight': 35, 'unit': 'lbs'},
                            ],
                        },
                        {
                            'day': 'Tuesday',
                            'name': 'Lower Body',
                            'exercises': [
                                {'exercise_name': 'Barbell Back Squat', 'sets': 4, 'reps': 10, 'weight': 185, 'unit': 'lbs'},
                                {'exercise_name': 'Romanian Deadlift', 'sets': 3, 'reps': 10, 'weight': 155, 'unit': 'lbs'},
                                {'exercise_name': 'Leg Press', 'sets': 3, 'reps': 12, 'weight': 300, 'unit': 'lbs'},
                                {'exercise_name': 'Leg Extension Machine', 'sets': 3, 'reps': 15, 'weight': 80, 'unit': 'lbs'},
                                {'exercise_name': 'Standing Calf Raise (Machine)', 'sets': 4, 'reps': 15, 'weight': 120, 'unit': 'lbs'},
                            ],
                        },
                        {'day': 'Wednesday', 'name': 'Rest', 'exercises': []},
                        {
                            'day': 'Thursday',
                            'name': 'Upper Body',
                            'exercises': [
                                {'exercise_name': 'Incline Dumbbell Bench Press', 'sets': 4, 'reps': 10, 'weight': 55, 'unit': 'lbs'},
                                {'exercise_name': 'Lat Pulldown (Wide Grip)', 'sets': 4, 'reps': 10, 'weight': 110, 'unit': 'lbs'},
                                {'exercise_name': 'Arnold Press', 'sets': 3, 'reps': 12, 'weight': 30, 'unit': 'lbs'},
                                {'exercise_name': 'Face Pulls', 'sets': 3, 'reps': 15, 'weight': 25, 'unit': 'lbs'},
                                {'exercise_name': 'Hammer Curls', 'sets': 3, 'reps': 12, 'weight': 25, 'unit': 'lbs'},
                                {'exercise_name': 'Skull Crushers (EZ-Bar)', 'sets': 3, 'reps': 12, 'weight': 50, 'unit': 'lbs'},
                            ],
                        },
                        {
                            'day': 'Friday',
                            'name': 'Lower Body',
                            'exercises': [
                                {'exercise_name': 'Barbell Deadlift', 'sets': 4, 'reps': 6, 'weight': 225, 'unit': 'lbs'},
                                {'exercise_name': 'Bulgarian Split Squat', 'sets': 3, 'reps': 10, 'weight': 40, 'unit': 'lbs'},
                                {'exercise_name': 'Hip Thrust (Barbell)', 'sets': 3, 'reps': 12, 'weight': 135, 'unit': 'lbs'},
                                {'exercise_name': 'Leg Curl Machine', 'sets': 3, 'reps': 12, 'weight': 70, 'unit': 'lbs'},
                                {'exercise_name': 'Standing Calf Raise (Machine)', 'sets': 4, 'reps': 15, 'weight': 130, 'unit': 'lbs'},
                            ],
                        },
                        {'day': 'Saturday', 'name': 'Rest', 'exercises': []},
                        {'day': 'Sunday', 'name': 'Rest', 'exercises': []},
                    ],
                },
                {'week_number': 2, 'note': 'Increase weight by 5lbs on compounds', 'days': []},
                {'week_number': 3, 'note': 'Increase weight by 10lbs on compounds from week 1', 'days': []},
                {'week_number': 4, 'note': 'Deload — reduce weights by 15%, focus on form', 'is_deload': True, 'days': []},
            ],
        },
    },
    {
        'name': 'Fat Loss Conditioning',
        'description': '4-week fat loss program — full body circuits with cardio finishers.',
        'schedule': {
            'weeks': [
                {
                    'week_number': 1,
                    'days': [
                        {
                            'day': 'Monday',
                            'name': 'Full Body Circuit A',
                            'exercises': [
                                {'exercise_name': 'Barbell Back Squat', 'sets': 3, 'reps': 12, 'weight': 135, 'unit': 'lbs'},
                                {'exercise_name': 'Dumbbell Bench Press', 'sets': 3, 'reps': 12, 'weight': 45, 'unit': 'lbs'},
                                {'exercise_name': 'Barbell Bent-Over Row', 'sets': 3, 'reps': 12, 'weight': 95, 'unit': 'lbs'},
                                {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 20},
                            ],
                        },
                        {'day': 'Tuesday', 'name': 'Active Recovery', 'exercises': [
                            {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 30},
                        ]},
                        {
                            'day': 'Wednesday',
                            'name': 'Full Body Circuit B',
                            'exercises': [
                                {'exercise_name': 'Romanian Deadlift', 'sets': 3, 'reps': 12, 'weight': 115, 'unit': 'lbs'},
                                {'exercise_name': 'Barbell Overhead Press', 'sets': 3, 'reps': 12, 'weight': 65, 'unit': 'lbs'},
                                {'exercise_name': 'Lat Pulldown (Wide Grip)', 'sets': 3, 'reps': 12, 'weight': 80, 'unit': 'lbs'},
                                {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 20},
                            ],
                        },
                        {'day': 'Thursday', 'name': 'Rest', 'exercises': []},
                        {
                            'day': 'Friday',
                            'name': 'Full Body Circuit C',
                            'exercises': [
                                {'exercise_name': 'Leg Press', 'sets': 3, 'reps': 15, 'weight': 200, 'unit': 'lbs'},
                                {'exercise_name': 'Incline Dumbbell Bench Press', 'sets': 3, 'reps': 12, 'weight': 35, 'unit': 'lbs'},
                                {'exercise_name': 'Seated Cable Row', 'sets': 3, 'reps': 12, 'weight': 90, 'unit': 'lbs'},
                                {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 20},
                            ],
                        },
                        {'day': 'Saturday', 'name': 'Active Recovery', 'exercises': [
                            {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 40},
                        ]},
                        {'day': 'Sunday', 'name': 'Rest', 'exercises': []},
                    ],
                },
                {'week_number': 2, 'note': 'Add 1 set to each compound', 'days': []},
                {'week_number': 3, 'note': 'Increase cardio finisher to 25 min', 'days': []},
                {'week_number': 4, 'note': 'Deload — reduce weights by 10%', 'is_deload': True, 'days': []},
            ],
        },
    },
]


class Command(BaseCommand):
    help = 'Seeds mock trainees for an existing trainer account'

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            'trainer_email',
            type=str,
            help='Email of the trainer to seed trainees for',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Delete and recreate trainees if they already exist',
        )

    def handle(self, *args: Any, **options: Any) -> None:
        trainer_email: str = options['trainer_email']
        force: bool = options['force']

        trainer = User.objects.filter(email=trainer_email, role=User.Role.TRAINER).first()
        if trainer is None:
            self.stderr.write(
                self.style.ERROR(f'Trainer not found: {trainer_email}')
            )
            return

        self.stdout.write(f'Seeding trainees for trainer: {trainer.email} ({trainer.first_name} {trainer.last_name})')

        created_count = 0
        skipped_count = 0

        for data in MOCK_TRAINEES:
            email = str(data['email'])
            existing = User.objects.filter(email=email).first()

            if existing and not force:
                self.stdout.write(self.style.WARNING(f'  Skipped (exists): {email}'))
                skipped_count += 1
                continue

            if existing and force:
                existing.delete()

            trainee = self._create_trainee(trainer, data)
            self.stdout.write(self.style.SUCCESS(f'  Created: {trainee.email}'))
            created_count += 1

        # Assign programs to some trainees
        trainees_with_programs = User.objects.filter(
            parent_trainer=trainer,
            email__in=[str(d['email']) for d in MOCK_TRAINEES],
        ).exclude(
            profile__onboarding_completed=False,
        )[:6]

        program_count = 0
        for i, trainee in enumerate(trainees_with_programs):
            if not Program.objects.filter(trainee=trainee, is_active=True).exists():
                program_data = SAMPLE_PROGRAMS[i % len(SAMPLE_PROGRAMS)]
                self._create_program(trainer, trainee, program_data)
                program_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'\nDone! Created {created_count} trainees, '
                f'skipped {skipped_count}, '
                f'assigned {program_count} programs.'
            )
        )

    def _create_trainee(self, trainer: User, data: dict[str, Any]) -> User:
        """Create a single mock trainee with profile and nutrition goal."""
        profile_data: dict[str, Any] = data['profile']
        nutrition_data: dict[str, Any] = data['nutrition_goal']

        trainee = User.objects.create_user(
            email=str(data['email']),
            password='MockTrainee123!',
            first_name=str(data['first_name']),
            last_name=str(data['last_name']),
            role=User.Role.TRAINEE,
            parent_trainer=trainer,
            is_active=True,
        )

        UserProfile.objects.create(
            user=trainee,
            sex=str(profile_data['sex']),
            age=int(profile_data['age']),
            height_cm=float(profile_data['height_cm']),
            weight_kg=float(profile_data['weight_kg']),
            activity_level=str(profile_data['activity_level']),
            goal=str(profile_data['goal']),
            diet_type=str(profile_data['diet_type']),
            meals_per_day=int(profile_data['meals_per_day']),
            onboarding_completed=bool(profile_data['onboarding_completed']),
            check_in_days=['monday', 'thursday'],
        )

        meals_per_day = int(profile_data['meals_per_day'])
        NutritionGoal.objects.create(
            trainee=trainee,
            protein_goal=int(nutrition_data['protein_goal']),
            carbs_goal=int(nutrition_data['carbs_goal']),
            fat_goal=int(nutrition_data['fat_goal']),
            calories_goal=int(nutrition_data['calories_goal']),
            per_meal_protein=int(nutrition_data['protein_goal']) // meals_per_day,
            per_meal_carbs=int(nutrition_data['carbs_goal']) // meals_per_day,
            per_meal_fat=int(nutrition_data['fat_goal']) // meals_per_day,
        )

        return trainee

    def _create_program(
        self, trainer: User, trainee: User, program_data: dict[str, Any]
    ) -> Program:
        """Create a program for a trainee."""
        return Program.objects.create(
            trainee=trainee,
            name=str(program_data['name']),
            description=str(program_data['description']),
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + timedelta(weeks=4),
            is_active=True,
            created_by=trainer,
            schedule=program_data['schedule'],
        )

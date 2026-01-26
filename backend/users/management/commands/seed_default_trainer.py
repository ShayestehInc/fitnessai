"""
Management command to seed a default trainer account with demo trainees.
"""
import random
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from users.models import User, UserProfile
from subscriptions.models import Subscription
from workouts.models import NutritionGoal, Program
from trainer.models import TraineeActivitySummary


class Command(BaseCommand):
    help = 'Seeds a default trainer account with demo trainees for testing'

    TRAINER_EMAIL = 'demo.trainer@fitnessai.com'
    TRAINER_PASSWORD = 'TrainerDemo123!'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force recreation of the demo trainer even if it already exists',
        )

    def handle(self, *args, **options):
        force = options['force']

        # Check if trainer already exists
        trainer = User.objects.filter(email=self.TRAINER_EMAIL).first()

        if trainer and not force:
            self.stdout.write(
                self.style.WARNING(
                    f'Demo trainer already exists: {self.TRAINER_EMAIL}. '
                    f'Use --force to recreate.'
                )
            )
            return

        if trainer and force:
            self.stdout.write(f'Deleting existing demo trainer and related data...')
            trainer.delete()

        # Create demo trainer
        trainer = self._create_trainer()
        self.stdout.write(self.style.SUCCESS(f'Created trainer: {trainer.email}'))

        # Create subscription
        subscription = self._create_subscription(trainer)
        self.stdout.write(self.style.SUCCESS(f'Created subscription: {subscription}'))

        # Create demo trainees
        trainees = self._create_demo_trainees(trainer)
        for trainee in trainees:
            self.stdout.write(self.style.SUCCESS(f'Created trainee: {trainee.email}'))

        # Create sample program for first trainee
        if trainees:
            program = self._create_sample_program(trainer, trainees[0])
            self.stdout.write(self.style.SUCCESS(f'Created sample program: {program.name}'))

        self.stdout.write(
            self.style.SUCCESS(
                f'\n{"=" * 50}\n'
                f'Demo Trainer Account Created!\n'
                f'{"=" * 50}\n'
                f'Email: {self.TRAINER_EMAIL}\n'
                f'Password: {self.TRAINER_PASSWORD}\n'
                f'Subscription: Tier 2 (50 trainees)\n'
                f'Demo Trainees: {len(trainees)}\n'
                f'{"=" * 50}'
            )
        )

    def _create_trainer(self) -> User:
        """Create the demo trainer account."""
        trainer = User.objects.create_user(
            email=self.TRAINER_EMAIL,
            password=self.TRAINER_PASSWORD,
            first_name='Demo',
            last_name='Trainer',
            role=User.Role.TRAINER,
            is_active=True
        )
        return trainer

    def _create_subscription(self, trainer: User) -> Subscription:
        """Create a Tier 2 subscription for the trainer."""
        subscription = Subscription.objects.create(
            trainer=trainer,
            tier=Subscription.Tier.TIER_2,
            status=Subscription.Status.ACTIVE,
            current_period_start=timezone.now(),
            current_period_end=timezone.now() + timedelta(days=365),
        )
        return subscription

    def _create_demo_trainees(self, trainer: User) -> list:
        """Create 3 demo trainees assigned to the trainer."""
        trainees_data = [
            {
                'email': 'john.demo@fitnessai.com',
                'first_name': 'John',
                'last_name': 'Demo',
                'profile': {
                    'sex': 'male',
                    'age': 28,
                    'height_cm': 180,
                    'weight_kg': 82,
                    'activity_level': 'moderately_active',
                    'goal': 'build_muscle',
                    'diet_type': 'balanced',
                    'meals_per_day': 4,
                    'onboarding_completed': True,
                },
                'nutrition_goal': {
                    'protein_goal': 180,
                    'carbs_goal': 300,
                    'fat_goal': 80,
                    'calories_goal': 2800,
                }
            },
            {
                'email': 'sarah.demo@fitnessai.com',
                'first_name': 'Sarah',
                'last_name': 'Demo',
                'profile': {
                    'sex': 'female',
                    'age': 32,
                    'height_cm': 165,
                    'weight_kg': 62,
                    'activity_level': 'very_active',
                    'goal': 'fat_loss',
                    'diet_type': 'low_carb',
                    'meals_per_day': 3,
                    'onboarding_completed': True,
                },
                'nutrition_goal': {
                    'protein_goal': 130,
                    'carbs_goal': 150,
                    'fat_goal': 60,
                    'calories_goal': 1700,
                }
            },
            {
                'email': 'mike.demo@fitnessai.com',
                'first_name': 'Mike',
                'last_name': 'Demo',
                'profile': {
                    'sex': 'male',
                    'age': 25,
                    'height_cm': 175,
                    'weight_kg': 75,
                    'activity_level': 'lightly_active',
                    'goal': 'recomp',
                    'diet_type': 'balanced',
                    'meals_per_day': 4,
                    'onboarding_completed': False,  # One trainee still in onboarding
                },
                'nutrition_goal': {
                    'protein_goal': 165,
                    'carbs_goal': 250,
                    'fat_goal': 70,
                    'calories_goal': 2400,
                }
            },
        ]

        trainees = []
        for data in trainees_data:
            # Delete existing trainee if exists
            User.objects.filter(email=data['email']).delete()

            # Create trainee
            trainee = User.objects.create_user(
                email=data['email'],
                password='TraineeDemo123!',
                first_name=data['first_name'],
                last_name=data['last_name'],
                role=User.Role.TRAINEE,
                parent_trainer=trainer,
                is_active=True
            )

            # Create profile
            profile_data = data['profile']
            UserProfile.objects.create(
                user=trainee,
                sex=profile_data['sex'],
                age=profile_data['age'],
                height_cm=profile_data['height_cm'],
                weight_kg=profile_data['weight_kg'],
                activity_level=profile_data['activity_level'],
                goal=profile_data['goal'],
                diet_type=profile_data['diet_type'],
                meals_per_day=profile_data['meals_per_day'],
                onboarding_completed=profile_data['onboarding_completed'],
                check_in_days=['monday', 'thursday']
            )

            # Create nutrition goal
            nutrition_data = data['nutrition_goal']
            NutritionGoal.objects.create(
                trainee=trainee,
                protein_goal=nutrition_data['protein_goal'],
                carbs_goal=nutrition_data['carbs_goal'],
                fat_goal=nutrition_data['fat_goal'],
                calories_goal=nutrition_data['calories_goal'],
                per_meal_protein=nutrition_data['protein_goal'] // profile_data['meals_per_day'],
                per_meal_carbs=nutrition_data['carbs_goal'] // profile_data['meals_per_day'],
                per_meal_fat=nutrition_data['fat_goal'] // profile_data['meals_per_day'],
            )

            trainees.append(trainee)

        return trainees

    def _create_sample_program(self, trainer: User, trainee: User) -> Program:
        """Create a sample 4-week program for a trainee."""
        program = Program.objects.create(
            trainee=trainee,
            name='Strength Building Program',
            description='4-week progressive overload program focusing on compound movements.',
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + timedelta(weeks=4),
            is_active=True,
            created_by=trainer,
            schedule={
                'weeks': [
                    {
                        'week_number': 1,
                        'days': [
                            {
                                'day': 'Monday',
                                'name': 'Push Day',
                                'exercises': [
                                    {'exercise_name': 'Barbell Bench Press', 'sets': 4, 'reps': 8, 'weight': 135, 'unit': 'lbs'},
                                    {'exercise_name': 'Incline Dumbbell Bench Press', 'sets': 3, 'reps': 10, 'weight': 50, 'unit': 'lbs'},
                                    {'exercise_name': 'Barbell Overhead Press', 'sets': 3, 'reps': 8, 'weight': 95, 'unit': 'lbs'},
                                    {'exercise_name': 'Dumbbell Lateral Raises', 'sets': 3, 'reps': 12, 'weight': 20, 'unit': 'lbs'},
                                    {'exercise_name': 'Tricep Pushdown (Rope)', 'sets': 3, 'reps': 12, 'weight': 40, 'unit': 'lbs'},
                                ]
                            },
                            {
                                'day': 'Tuesday',
                                'name': 'Pull Day',
                                'exercises': [
                                    {'exercise_name': 'Barbell Deadlift', 'sets': 4, 'reps': 6, 'weight': 225, 'unit': 'lbs'},
                                    {'exercise_name': 'Barbell Bent-Over Row', 'sets': 4, 'reps': 8, 'weight': 135, 'unit': 'lbs'},
                                    {'exercise_name': 'Lat Pulldown (Wide Grip)', 'sets': 3, 'reps': 10, 'weight': 100, 'unit': 'lbs'},
                                    {'exercise_name': 'Face Pulls', 'sets': 3, 'reps': 15, 'weight': 30, 'unit': 'lbs'},
                                    {'exercise_name': 'Barbell Bicep Curl', 'sets': 3, 'reps': 10, 'weight': 65, 'unit': 'lbs'},
                                ]
                            },
                            {
                                'day': 'Wednesday',
                                'name': 'Rest',
                                'exercises': []
                            },
                            {
                                'day': 'Thursday',
                                'name': 'Legs',
                                'exercises': [
                                    {'exercise_name': 'Barbell Back Squat', 'sets': 4, 'reps': 8, 'weight': 185, 'unit': 'lbs'},
                                    {'exercise_name': 'Romanian Deadlift', 'sets': 3, 'reps': 10, 'weight': 155, 'unit': 'lbs'},
                                    {'exercise_name': 'Leg Press', 'sets': 3, 'reps': 12, 'weight': 270, 'unit': 'lbs'},
                                    {'exercise_name': 'Leg Extension Machine', 'sets': 3, 'reps': 12, 'weight': 90, 'unit': 'lbs'},
                                    {'exercise_name': 'Standing Calf Raise (Machine)', 'sets': 4, 'reps': 15, 'weight': 135, 'unit': 'lbs'},
                                ]
                            },
                            {
                                'day': 'Friday',
                                'name': 'Upper Body',
                                'exercises': [
                                    {'exercise_name': 'Dumbbell Bench Press', 'sets': 4, 'reps': 10, 'weight': 60, 'unit': 'lbs'},
                                    {'exercise_name': 'Seated Cable Row', 'sets': 4, 'reps': 10, 'weight': 120, 'unit': 'lbs'},
                                    {'exercise_name': 'Arnold Press', 'sets': 3, 'reps': 10, 'weight': 35, 'unit': 'lbs'},
                                    {'exercise_name': 'Hammer Curls', 'sets': 3, 'reps': 12, 'weight': 30, 'unit': 'lbs'},
                                    {'exercise_name': 'Skull Crushers (EZ-Bar)', 'sets': 3, 'reps': 12, 'weight': 55, 'unit': 'lbs'},
                                ]
                            },
                            {
                                'day': 'Saturday',
                                'name': 'Rest',
                                'exercises': []
                            },
                            {
                                'day': 'Sunday',
                                'name': 'Active Recovery',
                                'exercises': [
                                    {'exercise_name': 'Treadmill Walking (Incline)', 'sets': 1, 'reps': 1, 'duration_minutes': 30},
                                ]
                            },
                        ]
                    },
                    {
                        'week_number': 2,
                        'note': 'Increase weight by 5lbs on main lifts',
                        'days': []  # Same structure, referenced with modifier
                    },
                    {
                        'week_number': 3,
                        'note': 'Increase weight by 10lbs on main lifts from week 1',
                        'days': []
                    },
                    {
                        'week_number': 4,
                        'note': 'Deload week - reduce weights by 10%, focus on form',
                        'is_deload': True,
                        'days': []
                    },
                ]
            }
        )
        return program

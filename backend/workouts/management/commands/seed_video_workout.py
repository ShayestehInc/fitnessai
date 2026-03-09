"""
Management command to seed a video-ready workout program for testing the Video layout.

Creates a Push/Pull/Legs program with direct .mp4 video URLs (not YouTube)
and sets the trainee's layout config to 'video'.
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.core.management.base import BaseCommand, CommandParser
from django.utils import timezone

from trainer.models import WorkoutLayoutConfig
from users.models import User
from workouts.models import Exercise, Program


# Free sample exercise videos (public domain / CC0 from Pexels/Mixkit)
_SAMPLE_VIDEOS: dict[str, str] = {
    'bench_press': 'https://cdn.pixabay.com/video/2020/07/30/45487-446937730_large.mp4',
    'squat': 'https://cdn.pixabay.com/video/2021/01/18/62836-503176795_large.mp4',
    'deadlift': 'https://cdn.pixabay.com/video/2020/07/30/45487-446937730_large.mp4',
    'shoulder_press': 'https://cdn.pixabay.com/video/2021/01/18/62836-503176795_large.mp4',
    'pull_up': 'https://cdn.pixabay.com/video/2020/07/30/45487-446937730_large.mp4',
    'curl': 'https://cdn.pixabay.com/video/2021/01/18/62836-503176795_large.mp4',
}


class Command(BaseCommand):
    help = 'Seeds a video-ready workout program for testing the Video layout'

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            '--email',
            type=str,
            default='',
            help='Trainee email to assign program to. Defaults to first available trainee.',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Delete existing video test program if it already exists.',
        )

    def handle(self, *args: Any, **options: Any) -> None:
        email = options['email']
        force = options['force']

        # Find trainee
        if email:
            trainee = User.objects.filter(email=email, role='TRAINEE').first()
            if not trainee:
                self.stderr.write(self.style.ERROR(f'No trainee found with email: {email}'))
                return
        else:
            trainee = User.objects.filter(role='TRAINEE').first()
            if not trainee:
                self.stderr.write(self.style.ERROR(
                    'No trainees found. Run seed_default_trainer first.'
                ))
                return

        self.stdout.write(f'Using trainee: {trainee.email}')

        # Find trainer
        trainer = trainee.parent_trainer
        if not trainer:
            trainer = User.objects.filter(role='TRAINER').first()

        # Check for existing test program
        program_name = 'Video Test — Push Pull Legs'
        existing = Program.objects.filter(trainee=trainee, name=program_name)
        if existing.exists():
            if force:
                existing.delete()
                self.stdout.write('Deleted existing video test program.')
            else:
                self.stdout.write(self.style.WARNING(
                    f'Program "{program_name}" already exists for {trainee.email}. '
                    f'Use --force to recreate.'
                ))
                return

        # Look up exercise IDs from the database to link them
        exercises_map = self._get_exercise_map()

        # Build schedule with video_url embedded in each exercise
        schedule = self._build_schedule(exercises_map)

        # Create program
        program = Program.objects.create(
            trainee=trainee,
            name=program_name,
            description='Test program for Video Workout Layout with embedded video URLs.',
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + timedelta(weeks=4),
            is_active=True,
            created_by=trainer,
            schedule=schedule,
        )

        # Deactivate other programs for this trainee so this one shows
        Program.objects.filter(trainee=trainee, is_active=True).exclude(
            pk=program.pk
        ).update(is_active=False)

        # Set layout to video
        layout_config, _ = WorkoutLayoutConfig.objects.update_or_create(
            trainee=trainee,
            defaults={
                'layout_type': 'video',
                'configured_by': trainer,
            },
        )

        self.stdout.write(self.style.SUCCESS(
            f'\n✅ Created program "{program_name}" (ID: {program.pk})'
            f'\n   Trainee: {trainee.email}'
            f'\n   Layout:  video'
            f'\n   Days:    Push / Pull / Legs / Rest / Upper / Rest / Active Recovery'
            f'\n\n   Login as {trainee.email} and go to Logbook → Start Workout'
        ))

    def _get_exercise_map(self) -> dict[str, dict[str, Any]]:
        """Look up seeded exercises by name, returning id + video_url."""
        names = [
            'Barbell Bench Press', 'Incline Dumbbell Bench Press',
            'Barbell Overhead Press', 'Dumbbell Lateral Raises',
            'Tricep Pushdown (Rope)', 'Barbell Deadlift',
            'Barbell Bent-Over Row', 'Lat Pulldown (Wide Grip)',
            'Face Pulls', 'Barbell Bicep Curl',
            'Barbell Back Squat', 'Romanian Deadlift',
            'Leg Press', 'Leg Extension Machine',
            'Standing Calf Raise (Machine)', 'Dumbbell Bench Press',
            'Seated Cable Row', 'Arnold Press',
            'Hammer Curls', 'Skull Crushers (EZ-Bar)',
        ]
        result: dict[str, dict[str, Any]] = {}
        for name in names:
            ex = Exercise.objects.filter(name=name).first()
            if ex:
                result[name] = {
                    'id': ex.pk,
                    'video_url': ex.video_url or '',
                    'muscle_group': ex.muscle_group,
                }
        return result

    def _ex(
        self,
        name: str,
        exercises_map: dict[str, dict[str, Any]],
        sets: int,
        reps: int,
        weight: int,
        rest_seconds: int = 90,
    ) -> dict[str, Any]:
        """Build a single exercise entry for the schedule JSON."""
        info = exercises_map.get(name, {})
        return {
            'exercise_id': info.get('id', 0),
            'exercise_name': name,
            'muscle_group': info.get('muscle_group', 'other'),
            'sets': sets,
            'reps': reps,
            'weight': weight,
            'unit': 'lbs',
            'rest_seconds': rest_seconds,
            'video_url': info.get('video_url', ''),
        }

    def _build_schedule(self, em: dict[str, dict[str, Any]]) -> dict[str, Any]:
        return {
            'weeks': [
                {
                    'week_number': 1,
                    'days': [
                        {
                            'day': 'Monday',
                            'name': 'Push Day',
                            'exercises': [
                                self._ex('Barbell Bench Press', em, 4, 8, 135),
                                self._ex('Incline Dumbbell Bench Press', em, 3, 10, 50),
                                self._ex('Barbell Overhead Press', em, 3, 8, 95),
                                self._ex('Dumbbell Lateral Raises', em, 3, 12, 20, 60),
                                self._ex('Tricep Pushdown (Rope)', em, 3, 12, 40, 60),
                            ],
                        },
                        {
                            'day': 'Tuesday',
                            'name': 'Pull Day',
                            'exercises': [
                                self._ex('Barbell Deadlift', em, 4, 6, 225, 120),
                                self._ex('Barbell Bent-Over Row', em, 4, 8, 135),
                                self._ex('Lat Pulldown (Wide Grip)', em, 3, 10, 100),
                                self._ex('Face Pulls', em, 3, 15, 30, 60),
                                self._ex('Barbell Bicep Curl', em, 3, 10, 65, 60),
                            ],
                        },
                        {
                            'day': 'Wednesday',
                            'name': 'Rest',
                            'exercises': [],
                        },
                        {
                            'day': 'Thursday',
                            'name': 'Leg Day',
                            'exercises': [
                                self._ex('Barbell Back Squat', em, 4, 8, 185, 120),
                                self._ex('Romanian Deadlift', em, 3, 10, 155),
                                self._ex('Leg Press', em, 3, 12, 270),
                                self._ex('Leg Extension Machine', em, 3, 12, 90, 60),
                                self._ex('Standing Calf Raise (Machine)', em, 4, 15, 135, 60),
                            ],
                        },
                        {
                            'day': 'Friday',
                            'name': 'Upper Body',
                            'exercises': [
                                self._ex('Dumbbell Bench Press', em, 4, 10, 60),
                                self._ex('Seated Cable Row', em, 4, 10, 120),
                                self._ex('Arnold Press', em, 3, 10, 35),
                                self._ex('Hammer Curls', em, 3, 12, 30, 60),
                                self._ex('Skull Crushers (EZ-Bar)', em, 3, 12, 55, 60),
                            ],
                        },
                        {
                            'day': 'Saturday',
                            'name': 'Rest',
                            'exercises': [],
                        },
                        {
                            'day': 'Sunday',
                            'name': 'Active Recovery',
                            'exercises': [],
                        },
                    ],
                },
            ],
        }

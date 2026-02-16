"""
Management command to seed predefined achievements.
Creates 15 achievements across all criteria types.

Usage:
    python manage.py seed_achievements
"""
from __future__ import annotations

from django.core.management.base import BaseCommand

from community.models import Achievement


_ACHIEVEMENTS: list[dict[str, str | int]] = [
    # Workout Count milestones
    {
        'name': 'First Steps',
        'description': 'Complete your first workout',
        'icon_name': 'directions_walk',
        'criteria_type': Achievement.CriteriaType.WORKOUT_COUNT,
        'criteria_value': 1,
    },
    {
        'name': 'Getting Started',
        'description': 'Complete 5 workouts',
        'icon_name': 'fitness_center',
        'criteria_type': Achievement.CriteriaType.WORKOUT_COUNT,
        'criteria_value': 5,
    },
    {
        'name': 'Committed',
        'description': 'Complete 25 workouts',
        'icon_name': 'local_fire_department',
        'criteria_type': Achievement.CriteriaType.WORKOUT_COUNT,
        'criteria_value': 25,
    },
    {
        'name': 'Iron Will',
        'description': 'Complete 100 workouts',
        'icon_name': 'military_tech',
        'criteria_type': Achievement.CriteriaType.WORKOUT_COUNT,
        'criteria_value': 100,
    },

    # Workout Streak milestones
    {
        'name': 'On a Roll',
        'description': 'Work out 3 days in a row',
        'icon_name': 'bolt',
        'criteria_type': Achievement.CriteriaType.WORKOUT_STREAK,
        'criteria_value': 3,
    },
    {
        'name': 'Week Warrior',
        'description': 'Work out 7 days in a row',
        'icon_name': 'whatshot',
        'criteria_type': Achievement.CriteriaType.WORKOUT_STREAK,
        'criteria_value': 7,
    },
    {
        'name': 'Unstoppable',
        'description': 'Work out 14 days in a row',
        'icon_name': 'stars',
        'criteria_type': Achievement.CriteriaType.WORKOUT_STREAK,
        'criteria_value': 14,
    },

    # Weight Check-in Streak milestones
    {
        'name': 'Scale Regular',
        'description': 'Check in 3 days in a row',
        'icon_name': 'monitor_weight',
        'criteria_type': Achievement.CriteriaType.WEIGHT_CHECKIN_STREAK,
        'criteria_value': 3,
    },
    {
        'name': 'Consistent Tracker',
        'description': 'Check in 7 days in a row',
        'icon_name': 'trending_up',
        'criteria_type': Achievement.CriteriaType.WEIGHT_CHECKIN_STREAK,
        'criteria_value': 7,
    },
    {
        'name': 'Data Driven',
        'description': 'Check in 30 days in a row',
        'icon_name': 'insights',
        'criteria_type': Achievement.CriteriaType.WEIGHT_CHECKIN_STREAK,
        'criteria_value': 30,
    },

    # Nutrition Streak milestones
    {
        'name': 'Mindful Eater',
        'description': 'Log nutrition 3 days in a row',
        'icon_name': 'restaurant',
        'criteria_type': Achievement.CriteriaType.NUTRITION_STREAK,
        'criteria_value': 3,
    },
    {
        'name': 'Nutrition Pro',
        'description': 'Log nutrition 7 days in a row',
        'icon_name': 'emoji_food_beverage',
        'criteria_type': Achievement.CriteriaType.NUTRITION_STREAK,
        'criteria_value': 7,
    },
    {
        'name': 'Diet Master',
        'description': 'Log nutrition 30 days in a row',
        'icon_name': 'workspace_premium',
        'criteria_type': Achievement.CriteriaType.NUTRITION_STREAK,
        'criteria_value': 30,
    },

    # Program Completed milestones
    {
        'name': 'Program Graduate',
        'description': 'Complete your first program',
        'icon_name': 'school',
        'criteria_type': Achievement.CriteriaType.PROGRAM_COMPLETED,
        'criteria_value': 1,
    },
    {
        'name': 'Serial Achiever',
        'description': 'Complete 3 programs',
        'icon_name': 'emoji_events',
        'criteria_type': Achievement.CriteriaType.PROGRAM_COMPLETED,
        'criteria_value': 3,
    },
]


class Command(BaseCommand):
    help = 'Seed predefined achievements into the database.'

    def handle(self, *args: object, **options: object) -> None:
        created_count = 0
        skipped_count = 0

        for ach_data in _ACHIEVEMENTS:
            _, created = Achievement.objects.get_or_create(
                criteria_type=ach_data['criteria_type'],
                criteria_value=ach_data['criteria_value'],
                defaults={
                    'name': ach_data['name'],
                    'description': ach_data['description'],
                    'icon_name': ach_data['icon_name'],
                },
            )
            if created:
                created_count += 1
            else:
                skipped_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Achievements seeded: {created_count} created, {skipped_count} already existed.'
            )
        )

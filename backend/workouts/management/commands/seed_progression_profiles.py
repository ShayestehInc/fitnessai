"""
Seed system progression profiles.

Based on v6.5 packet Section 7: Progression Engine.
Five built-in profiles: Staircase Percent, Rep Staircase, Double Progression, Linear, Wave-by-Month.
"""
from django.core.management.base import BaseCommand

from workouts.models import ProgressionProfile


SYSTEM_PROFILES = [
    {
        'name': 'Staircase Percent',
        'slug': 'staircase-percent',
        'description': (
            'Increase intensity by a fixed percentage of TM each week over a work block, '
            'then deload. Failure triggers repeat or load reduction.'
        ),
        'progression_type': 'staircase_percent',
        'rules': {
            'step_pct': 2.5,
            'work_weeks': 4,
            'start_pct': 75,
        },
        'deload_rules': {
            'deload_pct': 65,
            'volume_drop_pct': 40,
            'intensity_drop_pct': 10,
            'trigger_after_weeks': 4,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'load_reduction_pct': 5,
            'action': 'repeat_week',
        },
    },
    {
        'name': 'Rep Staircase',
        'slug': 'rep-staircase',
        'description': (
            'Hold load constant and climb reps (+1/week). At the top rung, '
            'increase load and reset reps to the bottom.'
        ),
        'progression_type': 'rep_staircase',
        'rules': {
            'rep_step': 1,
            'load_increment_upper_lb': 5,
            'load_increment_lower_lb': 10,
        },
        'deload_rules': {
            'deload_pct': 65,
            'volume_drop_pct': 40,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'load_reduction_pct': 5,
            'action': 'reduce_load',
        },
    },
    {
        'name': 'Double Progression',
        'slug': 'double-progression',
        'description': (
            'Earn reps in a rep range. When all sets hit the top of the range '
            'at target RIR, increase load and reset reps to the low end.'
        ),
        'progression_type': 'double_progression',
        'rules': {
            'load_increment_lb': 5,
            'target_rpe': 8,
            'lock_in': 'practical',
        },
        'deload_rules': {
            'deload_pct': 65,
            'volume_drop_pct': 40,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'load_reduction_pct': 5,
            'action': 'reduce_load',
        },
    },
    {
        'name': 'Linear',
        'slug': 'linear',
        'description': (
            'Add a fixed amount of weight each session or week. '
            'If two consecutive failures, deload 5-10% and rebuild.'
        ),
        'progression_type': 'linear',
        'rules': {
            'increment_lb': 5,
            'frequency': 'session',
        },
        'deload_rules': {
            'deload_pct': 10,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'deload_pct': 10,
            'action': 'deload',
        },
    },
    {
        'name': 'Wave-by-Month',
        'slug': 'wave-by-month',
        'description': (
            '4-week wave: Accumulation (65-75%), Build (70-80%), '
            'Intensify (75-85%), Deload (60-70%).'
        ),
        'progression_type': 'wave_by_month',
        'rules': {
            'week_percentages': [75, 80, 85, 65],
            'week_reps': [10, 8, 5, 10],
            'week_sets': [5, 4, 5, 3],
        },
        'deload_rules': {
            'deload_pct': 65,
            'volume_drop_pct': 40,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'action': 'repeat_week',
        },
    },
]


class Command(BaseCommand):
    help = 'Seed system progression profiles (v6.5 Step 7).'

    def handle(self, *args: object, **options: object) -> None:
        created_count = 0
        updated_count = 0

        for data in SYSTEM_PROFILES:
            _, created = ProgressionProfile.objects.update_or_create(
                slug=data['slug'],
                defaults={
                    'name': data['name'],
                    'description': data['description'],
                    'progression_type': data['progression_type'],
                    'rules': data['rules'],
                    'deload_rules': data['deload_rules'],
                    'failure_rules': data['failure_rules'],
                    'is_system': True,
                },
            )
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f"  Created: {data['name']}"))
            else:
                updated_count += 1
                self.stdout.write(f"  Updated: {data['name']}")

        self.stdout.write(self.style.SUCCESS(
            f"\nDone! Progression profiles: {created_count} created, {updated_count} updated."
        ))

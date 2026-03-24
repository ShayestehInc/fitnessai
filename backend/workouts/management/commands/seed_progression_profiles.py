"""
Seed system progression profiles.

Based on v6.5 packet Sections 7-8: Progression Engine + Periodization.
Ten built-in profiles: original 5 + DUP, WUP, Block, Concurrent, Conjugate.
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
    # -----------------------------------------------------------------------
    # v6.5 §8B — Periodization variants
    # -----------------------------------------------------------------------
    {
        'name': 'Daily Undulating (DUP)',
        'slug': 'dup',
        'description': (
            'Same lift appears 2-4x/week with different emphases per day. '
            'Day A: Strength (3-5 reps @80-88%), Day B: Hypertrophy (6-10 reps @65-78%), '
            'Day C: Power/Speed (2-3 reps @50-70%).'
        ),
        'progression_type': 'dup',
        'rules': {
            'day_emphasis_rotation': ['strength', 'hypertrophy', 'power'],
            'rep_ranges': {
                'strength': [3, 5],
                'hypertrophy': [6, 10],
                'power': [2, 3],
            },
            'intensity_pct': {
                'strength': 85,
                'hypertrophy': 72,
                'power': 60,
            },
            'sets': {
                'strength': 5,
                'hypertrophy': 4,
                'power': 6,
            },
        },
        'deload_rules': {
            'deload_frequency_weeks': 6,
            'volume_drop_pct': 40,
            'keep_intensity_exposures': True,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'action': 'progress_each_day_independently',
        },
    },
    {
        'name': 'Weekly Undulating (WUP)',
        'slug': 'wup',
        'description': (
            'Each week has a distinct emphasis. Week 1: Volume (3x8), '
            'Week 2: Moderate (4x6), Week 3: Heavy (5x4), Week 4: Deload.'
        ),
        'progression_type': 'wup',
        'rules': {
            'week_emphasis_rotation': ['volume', 'moderate', 'heavy', 'deload'],
            'week_config': {
                'volume': {'sets': 3, 'reps': 8, 'pct': 70},
                'moderate': {'sets': 4, 'reps': 6, 'pct': 77},
                'heavy': {'sets': 5, 'reps': 4, 'pct': 85},
                'deload': {'sets': 2, 'reps': 5, 'pct': 60},
            },
        },
        'deload_rules': {
            'deload_week_index': 3,
            'volume_drop_pct': 50,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'action': 'repeat_wave',
        },
    },
    {
        'name': 'Block Periodization',
        'slug': 'block',
        'description': (
            'Blocks focus on one adaptation at a time. '
            'Accumulation (4 weeks, high volume @65-75%), '
            'Intensification (3 weeks, moderate volume @75-85%), '
            'Realization/Peak (2 weeks, low volume @85-95%).'
        ),
        'progression_type': 'block',
        'rules': {
            'blocks': [
                {
                    'name': 'accumulation',
                    'weeks': 4,
                    'volume_multiplier': 1.0,
                    'intensity_range_pct': [65, 75],
                    'rep_range': [6, 12],
                },
                {
                    'name': 'intensification',
                    'weeks': 3,
                    'volume_multiplier': 0.8,
                    'intensity_range_pct': [75, 85],
                    'rep_range': [3, 6],
                },
                {
                    'name': 'realization',
                    'weeks': 2,
                    'volume_multiplier': 0.6,
                    'intensity_range_pct': [85, 95],
                    'rep_range': [1, 3],
                },
            ],
        },
        'deload_rules': {
            'auto_deload_between_blocks': True,
            'deload_pct': 60,
            'volume_drop_pct': 50,
        },
        'failure_rules': {
            'consecutive_failures_for_deload': 2,
            'action': 'cap_intensity',
        },
    },
    {
        'name': 'Concurrent',
        'slug': 'concurrent',
        'description': (
            'Train multiple qualities in the same week with planned priority. '
            'One quality is the primary driver; others are maintenance or secondary.'
        ),
        'progression_type': 'concurrent',
        'rules': {
            'qualities': [
                {'name': 'strength', 'priority': 1, 'sessions_per_week': 2},
                {'name': 'hypertrophy', 'priority': 2, 'sessions_per_week': 2},
                {'name': 'conditioning', 'priority': 3, 'sessions_per_week': 1},
            ],
            'fatigue_budget_hard_sets_per_week': 20,
        },
        'deload_rules': {
            'deload_frequency_weeks': 6,
            'volume_drop_pct': 40,
        },
        'failure_rules': {
            'action': 'hold_secondary_progress_primary',
        },
    },
    {
        'name': 'Conjugate (ME/DE/RE)',
        'slug': 'conjugate',
        'description': (
            'Rotate methods: Max Effort (1-5RM variants), Dynamic Effort (fast bar @40-70%), '
            'Repeated Effort (8-15 reps near failure). Rotate ME exercise every 1-3 weeks.'
        ),
        'progression_type': 'conjugate',
        'rules': {
            'rotations': {
                'max_effort': {
                    'sessions_per_week': 1,
                    'exercise_rotation_weeks': 3,
                    'rep_range': [1, 5],
                    'goal': 'beat_recent_best',
                },
                'dynamic_effort': {
                    'sessions_per_week': 1,
                    'intensity_pct': 60,
                    'set_rep': '8x3',
                    'progress_via': 'bar_speed_and_small_pct_changes',
                },
                'repeated_effort': {
                    'sessions_per_week': 1,
                    'rep_range': [8, 15],
                    'progress_via': 'double_progression',
                },
            },
        },
        'deload_rules': {
            'deload_frequency_weeks': 4,
            'volume_drop_pct': 30,
        },
        'failure_rules': {
            'action': 'rotate_exercise_early',
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

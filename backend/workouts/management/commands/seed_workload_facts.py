"""
Seed WorkloadFactTemplate records — deterministic "cool fact" library.

v6.5 §23.2: Facts must feel fun without making things up.
Fact selection order: milestone → progression → distribution → gym-equivalent.
"""
from django.core.management.base import BaseCommand

from workouts.models import WorkloadFactTemplate


FACT_TEMPLATES = [
    # -----------------------------------------------------------------------
    # Exercise-scope facts
    # -----------------------------------------------------------------------
    {
        'scope': 'exercise',
        'template_text': (
            'You moved {{total_workload}} {{unit}} on {{exercise_name}} today — '
            'your highest in the last 30 days!'
        ),
        'condition_rules': {'is_30_day_high': True},
        'priority': 100,
    },
    {
        'scope': 'exercise',
        'template_text': (
            '{{total_workload}} {{unit}} on {{exercise_name}} — '
            'up {{delta_pct}}% from last time.'
        ),
        'condition_rules': {'has_comparison': True, 'delta_positive': True},
        'priority': 90,
    },
    {
        'scope': 'exercise',
        'template_text': (
            '{{total_workload}} {{unit}} on {{exercise_name}} across '
            '{{set_count}} sets and {{rep_total}} reps.'
        ),
        'condition_rules': {'min_workload': 1},
        'priority': 10,
    },
    {
        'scope': 'exercise',
        'template_text': (
            'You completed {{rep_total}} reps on {{exercise_name}} today. '
            "That's {{plates_equivalent}} 45 lb plates worth of work!"
        ),
        'condition_rules': {'min_workload': 2000, 'unit': 'lb_reps'},
        'priority': 50,
    },
    {
        'scope': 'exercise',
        'template_text': (
            '{{exercise_name}}: {{set_count}} sets at an average of '
            '{{avg_load}} {{load_unit}} per set.'
        ),
        'condition_rules': {'min_workload': 1},
        'priority': 5,
    },

    # -----------------------------------------------------------------------
    # Session-scope facts
    # -----------------------------------------------------------------------
    {
        'scope': 'session',
        'template_text': (
            'Total session workload: {{total_workload}} {{unit}}. '
            "That's your best session this month!"
        ),
        'condition_rules': {'is_month_high': True},
        'priority': 100,
    },
    {
        'scope': 'session',
        'template_text': (
            'Session total: {{total_workload}} {{unit}} — '
            'up {{delta_pct}}% vs your last comparable session.'
        ),
        'condition_rules': {'has_comparison': True, 'delta_positive': True},
        'priority': 90,
    },
    {
        'scope': 'session',
        'template_text': (
            'Session total: {{total_workload}} {{unit}} — '
            'down {{delta_pct_abs}}% vs last time. '
            'Intensity or a planned deload may explain the dip.'
        ),
        'condition_rules': {'has_comparison': True, 'delta_positive': False},
        'priority': 80,
    },
    {
        'scope': 'session',
        'template_text': (
            'You hit {{total_workload}} {{unit}} today. '
            "That's like benching a grand piano {{piano_equivalent}} times!"
        ),
        'condition_rules': {'min_workload': 10000, 'unit': 'lb_reps'},
        'priority': 60,
    },
    {
        'scope': 'session',
        'template_text': (
            'Session workload: {{total_workload}} {{unit}} across '
            '{{exercise_count}} exercises.'
        ),
        'condition_rules': {'min_workload': 1},
        'priority': 10,
    },
    {
        'scope': 'session',
        'template_text': (
            'Top contributor: {{top_exercise_name}} at '
            '{{top_exercise_workload}} {{unit}} ({{top_exercise_pct}}% of session).'
        ),
        'condition_rules': {'min_exercises': 2},
        'priority': 40,
    },
    {
        'scope': 'session',
        'template_text': (
            'Week-to-date workload: {{week_to_date}} {{unit}} — '
            '{{week_pct_of_target}}% of your weekly target.'
        ),
        'condition_rules': {'has_week_to_date': True},
        'priority': 70,
    },
    {
        'scope': 'session',
        'template_text': (
            '{{total_workload}} {{unit}} today — '
            "that's the equivalent of carrying {{kettlebell_equivalent}} "
            '53 lb kettlebells up a flight of stairs.'
        ),
        'condition_rules': {'min_workload': 5000, 'unit': 'lb_reps'},
        'priority': 30,
    },
    {
        'scope': 'session',
        'template_text': (
            'Your 3rd consecutive session this week. '
            'Consistency builds strength!'
        ),
        'condition_rules': {'consecutive_sessions_this_week': 3},
        'priority': 45,
    },
    {
        'scope': 'session',
        'template_text': (
            'You trained {{muscle_count}} muscle groups today. '
            'Great coverage!'
        ),
        'condition_rules': {'min_muscle_groups': 3},
        'priority': 35,
    },
]


class Command(BaseCommand):
    help = 'Seed WorkloadFactTemplate records (v6.5 §23.2).'

    def handle(self, *args: object, **options: object) -> None:
        created_count = 0
        updated_count = 0

        for i, data in enumerate(FACT_TEMPLATES):
            _, created = WorkloadFactTemplate.objects.update_or_create(
                template_text=data['template_text'],
                defaults={
                    'scope': data['scope'],
                    'condition_rules': data['condition_rules'],
                    'priority': data['priority'],
                    'is_system': True,
                },
            )
            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(self.style.SUCCESS(
            f"Done! Workload facts: {created_count} created, {updated_count} updated."
        ))

"""
Plan Converter Service — converts a TrainingPlan (relational) to legacy Program (JSON schedule).

Produces the Program.schedule JSON format:
{
  "weeks": [
    {
      "week_number": 1,
      "days": [
        {
          "day": "Monday",
          "is_rest_day": false,
          "exercises": [
            {
              "exercise_id": 1,
              "exercise_name": "Bench Press",
              "sets": 4,
              "reps": 8,
              "weight": null,
              "unit": "lbs",
              "rest_seconds": 120
            }
          ]
        }
      ]
    }
  ]
}
"""
from __future__ import annotations

import datetime
import logging
from dataclasses import dataclass
from typing import Any

from workouts.models import (
    PlanSession,
    PlanSlot,
    PlanWeek,
    Program,
    ProgramTemplate,
    TrainingPlan,
)

logger = logging.getLogger(__name__)

_DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']


@dataclass
class ConvertResult:
    """Output from converting a TrainingPlan to legacy format."""
    template_id: int | None
    program_id: int | None
    schedule_json: dict[str, Any]


def convert_plan_to_schedule(plan: TrainingPlan) -> dict[str, Any]:
    """Convert a TrainingPlan's relational hierarchy into the legacy JSON schedule format."""
    weeks = list(
        PlanWeek.objects.filter(plan=plan)
        .order_by('week_number')
        .prefetch_related(
            'sessions__slots__exercise',
        )
    )

    schedule_weeks: list[dict[str, Any]] = []

    for week in weeks:
        sessions = list(week.sessions.order_by('day_of_week', 'order'))
        days: list[dict[str, Any]] = []

        for session in sessions:
            day_name = _DAY_NAMES[session.day_of_week] if 0 <= session.day_of_week <= 6 else f'Day {session.day_of_week}'
            slots = list(session.slots.order_by('order').select_related('exercise'))

            exercises: list[dict[str, Any]] = []
            for slot in slots:
                exercises.append({
                    'exercise_id': slot.exercise_id,
                    'exercise_name': slot.exercise.name if slot.exercise else 'Unknown',
                    'muscle_group': slot.exercise.primary_muscle_group if slot.exercise else '',
                    'sets': slot.sets,
                    'reps': slot.reps_max,
                    'reps_min': slot.reps_min,
                    'reps_max': slot.reps_max,
                    'weight': None,
                    'unit': 'lbs',
                    'rest_seconds': slot.rest_seconds,
                    'slot_role': slot.slot_role,
                    'notes': slot.notes,
                })

            days.append({
                'day': day_name,
                'label': session.label,
                'is_rest_day': False,
                'exercises': exercises,
            })

        schedule_weeks.append({
            'week_number': week.week_number,
            'is_deload': week.is_deload,
            'phase': week.phase,
            'days': days,
        })

    return {'weeks': schedule_weeks}


def convert_plan_to_template(
    plan: TrainingPlan,
    trainer_id: int,
) -> ProgramTemplate:
    """Convert a TrainingPlan to a ProgramTemplate (reusable, not assigned to anyone)."""
    schedule = convert_plan_to_schedule(plan)

    template, _ = ProgramTemplate.objects.update_or_create(
        name=plan.name,
        created_by_id=trainer_id,
        defaults={
            'description': plan.description or f'Generated from plan {plan.name}',
            'duration_weeks': plan.duration_weeks,
            'schedule_template': schedule,
            'difficulty_level': plan.difficulty or 'intermediate',
            'goal_type': plan.goal,
        },
    )
    return template


def convert_plan_to_program(
    plan: TrainingPlan,
    trainee_id: int,
    trainer_id: int,
) -> Program:
    """Convert a TrainingPlan to a legacy Program assigned to a specific trainee."""
    schedule = convert_plan_to_schedule(plan)

    today = datetime.date.today()
    end_date = today + datetime.timedelta(weeks=plan.duration_weeks)

    program = Program.objects.create(
        trainee_id=trainee_id,
        name=plan.name,
        description=plan.description or '',
        start_date=today,
        end_date=end_date,
        schedule=schedule,
        is_active=True,
        created_by_id=trainer_id,
    )

    # Deactivate other active programs for this trainee
    Program.objects.filter(
        trainee_id=trainee_id,
        is_active=True,
    ).exclude(pk=program.pk).update(is_active=False)

    return program

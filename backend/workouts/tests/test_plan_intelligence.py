"""Tests for the plan intelligence service."""
from decimal import Decimal

from django.test import TestCase

from users.models import User
from workouts.models import PlanSession, PlanSlot, PlanWeek, SplitTemplate, TrainingPlan
from workouts.services.builder_service import BuilderBrief, quick_build
from workouts.services.plan_intelligence_service import (
    assign_pairings,
    assign_phases,
    assign_slot_roles_intelligent,
    assign_tempo_presets,
    auto_trim_session,
    classify_sessions,
    estimate_session_duration,
    filter_exercises_by_tags,
)
from workouts.services.training_generator_service import SlotSpec


class PhaseAssignmentTests(TestCase):
    """Tests for program phase assignment."""

    def _make_weeks(self, count: int) -> list[PlanWeek]:
        return [PlanWeek(week_number=i + 1) for i in range(count)]

    def test_build_muscle_8_weeks_has_deloads(self) -> None:
        weeks = self._make_weeks(8)
        assign_phases(weeks, 'build_muscle')
        phases = [w.phase for w in weeks]
        self.assertIn('deload', phases)
        self.assertEqual(weeks[0].phase, 'on_ramp')

    def test_strength_4_weeks_has_realization(self) -> None:
        weeks = self._make_weeks(4)
        assign_phases(weeks, 'strength')
        phases = [w.phase for w in weeks]
        self.assertIn('realization', phases)
        self.assertIn('deload', phases)

    def test_deload_weeks_have_correct_modifiers(self) -> None:
        weeks = self._make_weeks(4)
        assign_phases(weeks, 'strength')
        for w in weeks:
            if w.phase == 'deload':
                self.assertEqual(w.intensity_modifier, Decimal('0.60'))
                self.assertEqual(w.volume_modifier, Decimal('0.50'))
                self.assertTrue(w.is_deload)

    def test_new_trainee_starts_with_on_ramp(self) -> None:
        weeks = self._make_weeks(6)
        assign_phases(weeks, 'fat_loss', training_age_years=0)
        self.assertEqual(weeks[0].phase, 'on_ramp')

    def test_fallback_for_unknown_duration(self) -> None:
        weeks = self._make_weeks(11)
        assign_phases(weeks, 'build_muscle')
        # Should have at least one deload in an 11-week plan
        deload_count = len([w for w in weeks if w.phase == 'deload'])
        self.assertGreaterEqual(deload_count, 1)
        # All weeks should have a valid phase
        for w in weeks:
            self.assertIn(w.phase, ['on_ramp', 'accumulation', 'intensification', 'realization', 'deload', 'bridge'])


class SessionClassificationTests(TestCase):
    """Tests for session day role / family / stress classification."""

    def test_classifies_based_on_goal(self) -> None:
        session = PlanSession(label='Test', order=0)
        sdef = {'label': 'Push', 'muscle_groups': ['chest', 'shoulders', 'triceps']}
        classify_sessions([session], [sdef], 'build_muscle')
        self.assertTrue(session.session_family)
        self.assertTrue(session.day_stress)

    def test_deload_phase_sets_low_neural(self) -> None:
        session = PlanSession(label='Test', order=0)
        sdef = {'label': 'Heavy', 'muscle_groups': ['chest', 'back', 'quadriceps']}
        classify_sessions([session], [sdef], 'strength', phase='deload')
        self.assertEqual(session.day_stress, 'low_neural')


class PairingTests(TestCase):
    """Tests for exercise pairing logic."""

    def _make_spec(self, order: int, role: str, muscle: str = 'chest') -> SlotSpec:
        from unittest.mock import MagicMock
        ex = MagicMock()
        ex.primary_muscle_group = muscle
        return SlotSpec(
            session=MagicMock(), order=order, slot_role=role,
            sets=3, reps_min=8, reps_max=12, rest_seconds=60,
            exercise=ex,
        )

    def test_primary_compound_stands_alone(self) -> None:
        specs = [
            self._make_spec(1, 'primary_compound', 'chest'),
            self._make_spec(2, 'accessory', 'back'),
            self._make_spec(3, 'accessory', 'chest'),
        ]
        decisions = assign_pairings(specs, 'hypertrophy', 'build_muscle')
        primary = next(d for d in decisions if d.slot_order == 1)
        self.assertIsNone(primary.pairing_group)
        self.assertEqual(primary.pairing_type, 'straight')

    def test_antagonist_muscles_get_superset(self) -> None:
        specs = [
            self._make_spec(1, 'primary_compound', 'quadriceps'),
            self._make_spec(2, 'accessory', 'chest'),
            self._make_spec(3, 'accessory', 'back'),
        ]
        decisions = assign_pairings(specs, 'hypertrophy', 'build_muscle')
        chest_d = next(d for d in decisions if d.slot_order == 2)
        back_d = next(d for d in decisions if d.slot_order == 3)
        self.assertEqual(chest_d.pairing_group, back_d.pairing_group)
        self.assertEqual(chest_d.pairing_type, 'superset_antagonist')


class SessionTimingTests(TestCase):
    """Tests for session timing estimation."""

    def _make_spec(self, order: int, role: str, sets: int = 3, reps: int = 10, rest: int = 60) -> SlotSpec:
        from unittest.mock import MagicMock
        return SlotSpec(
            session=MagicMock(), order=order, slot_role=role,
            sets=sets, reps_min=reps, reps_max=reps, rest_seconds=rest,
        )

    def test_estimate_returns_positive(self) -> None:
        specs = [self._make_spec(i, 'accessory') for i in range(1, 6)]
        duration = estimate_session_duration(specs)
        self.assertGreater(duration, 0)

    def test_more_slots_means_longer_session(self) -> None:
        short = [self._make_spec(i, 'accessory') for i in range(1, 4)]
        long = [self._make_spec(i, 'accessory') for i in range(1, 8)]
        self.assertGreater(estimate_session_duration(long), estimate_session_duration(short))

    def test_auto_trim_removes_optional_first(self) -> None:
        specs = [
            self._make_spec(1, 'primary_compound', sets=5, reps=5, rest=180),
            self._make_spec(2, 'secondary_compound', sets=4, reps=8, rest=120),
            self._make_spec(3, 'accessory', sets=3, reps=10, rest=60),
            self._make_spec(4, 'isolation', sets=3, reps=12, rest=45),
            self._make_spec(5, 'trunk', sets=3, reps=15, rest=30),
        ]
        specs[4].is_optional = True
        removed = auto_trim_session(specs, target_minutes=20)
        if removed:
            self.assertIn(5, removed)


class ExerciseTagFilterTests(TestCase):
    """Tests for exercise tag filtering."""

    def setUp(self) -> None:
        from workouts.models import Exercise
        self.ex1 = Exercise(id=1, name='Barbell Bench Press', primary_muscle_group='chest', equipment_required=['barbell'])
        self.ex2 = Exercise(id=2, name='Dumbbell Press', primary_muscle_group='chest', equipment_required=['dumbbell'])
        self.ex3 = Exercise(id=3, name='Overhead Press', primary_muscle_group='shoulders', equipment_required=['barbell'])
        self.pool = [self.ex1, self.ex2, self.ex3]

    def test_filter_by_equipment(self) -> None:
        filtered = filter_exercises_by_tags(self.pool, '', equipment=['dumbbell'])
        names = [e.name for e in filtered]
        self.assertIn('Dumbbell Press', names)
        self.assertNotIn('Barbell Bench Press', names)

    def test_filter_out_hated_lifts(self) -> None:
        filtered = filter_exercises_by_tags(self.pool, '', hated_lifts=['overhead press'])
        names = [e.name for e in filtered]
        self.assertNotIn('Overhead Press', names)

    def test_avoid_overhead_with_pain_tolerance(self) -> None:
        filtered = filter_exercises_by_tags(
            self.pool, '',
            pain_tolerances={'overhead': 'avoid'},
        )
        names = [e.name for e in filtered]
        self.assertNotIn('Overhead Press', names)


class QuickBuildIntelligenceTests(TestCase):
    """Integration tests for quick_build with intelligence features."""

    def setUp(self) -> None:
        from workouts.models import Exercise
        trainer = User.objects.create_user(
            email='trainer@test.com', password='test123', role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com', password='test123', role='TRAINEE',
            parent_trainer=trainer,
        )
        self.trainer = trainer

        # Seed templates
        for days in range(2, 8):
            session_defs = []
            labels = ['Push', 'Pull', 'Legs', 'Upper', 'Lower', 'Full Body', 'Cardio']
            muscles = [
                ['chest', 'shoulders', 'triceps'], ['back', 'biceps'],
                ['quadriceps', 'hamstrings', 'glutes'], ['chest', 'back', 'shoulders'],
                ['quadriceps', 'hamstrings', 'glutes'],
                ['chest', 'back', 'quadriceps', 'shoulders'], ['quadriceps'],
            ]
            for i in range(days):
                session_defs.append({
                    'label': labels[i % len(labels)],
                    'muscle_groups': muscles[i % len(muscles)],
                })
            SplitTemplate.objects.create(
                name=f'Test Split {days}d', days_per_week=days,
                session_definitions=session_defs, goal_type='build_muscle',
                is_system=True,
            )

        # Seed exercises
        for mg in ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'quadriceps', 'hamstrings', 'glutes']:
            for i in range(5):
                Exercise.objects.create(
                    name=f'{mg.title()} Ex {i + 1}',
                    primary_muscle_group=mg,
                    category='compound' if i < 2 else 'isolation',
                    difficulty_level='intermediate',
                    is_public=True,
                )

    def test_quick_build_assigns_phases(self) -> None:
        brief = BuilderBrief(
            trainee_id=self.trainee.pk, goal='build_muscle',
            days_per_week=4, trainer_id=self.trainer.pk,
        )
        result = quick_build(brief)
        plan = TrainingPlan.objects.get(pk=result.plan_id)
        weeks = list(plan.weeks.all())
        phases = [w.phase for w in weeks]
        self.assertTrue(any(p != 'accumulation' for p in phases))

    def test_quick_build_classifies_sessions(self) -> None:
        brief = BuilderBrief(
            trainee_id=self.trainee.pk, goal='strength',
            days_per_week=3, trainer_id=self.trainer.pk,
        )
        result = quick_build(brief)
        sessions = list(PlanSession.objects.filter(week__plan_id=result.plan_id)[:3])
        for s in sessions:
            self.assertTrue(s.session_family)
            self.assertTrue(s.day_stress)

    def test_quick_build_estimates_duration(self) -> None:
        brief = BuilderBrief(
            trainee_id=self.trainee.pk, goal='build_muscle',
            days_per_week=4, session_length_minutes=60,
            trainer_id=self.trainer.pk,
        )
        result = quick_build(brief)
        sessions = PlanSession.objects.filter(week__plan_id=result.plan_id)[:1]
        for s in sessions:
            self.assertIsNotNone(s.estimated_duration_minutes)
            self.assertGreater(s.estimated_duration_minutes, 0)

    def test_quick_build_with_expanded_brief(self) -> None:
        brief = BuilderBrief(
            trainee_id=self.trainee.pk, goal='build_muscle',
            days_per_week=4, trainer_id=self.trainer.pk,
            secondary_goal='fat_loss',
            body_part_emphasis=['chest', 'shoulders'],
            training_age_years=2,
            recovery_profile={'sleep': 'good', 'stress': 'low'},
            pain_tolerances={'overhead': 'ok', 'axial_loading': 'ok'},
            hated_lifts=['Chest Ex 5'],
            complexity_tolerance='moderate',
        )
        result = quick_build(brief)
        self.assertTrue(result.plan_id)
        self.assertGreater(result.slots_count, 0)

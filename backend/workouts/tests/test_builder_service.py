"""Tests for the dual-mode program builder service."""
from __future__ import annotations

from django.test import TestCase

from users.models import User
from workouts.models import SplitTemplate, TrainingPlan
from workouts.services.builder_service import (
    BuilderBrief,
    BuilderStepResult,
    QuickBuildResult,
    builder_advance,
    builder_start,
    quick_build,
)


class BuilderTestMixin:
    """Shared setup for builder tests."""

    def _create_trainer_and_trainee(self) -> tuple[User, User]:
        trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=trainer,
        )
        return trainer, trainee

    def _seed_split_templates(self) -> None:
        """Create minimal split templates for testing."""
        for days in range(2, 8):
            session_defs = []
            labels = ['Push', 'Pull', 'Legs', 'Upper', 'Lower', 'Full Body', 'Cardio']
            muscles = [
                ['chest', 'shoulders', 'triceps'],
                ['back', 'biceps'],
                ['quadriceps', 'hamstrings', 'glutes'],
                ['chest', 'back', 'shoulders'],
                ['quadriceps', 'hamstrings', 'glutes'],
                ['chest', 'back', 'quadriceps', 'shoulders'],
                ['quadriceps'],
            ]
            for i in range(days):
                session_defs.append({
                    'label': labels[i % len(labels)],
                    'muscle_groups': muscles[i % len(muscles)],
                })
            SplitTemplate.objects.create(
                name=f'Test Split {days}d',
                days_per_week=days,
                session_definitions=session_defs,
                goal_type='build_muscle',
                is_system=True,
            )

    def _seed_exercises(self) -> None:
        """Create minimal exercise pool for testing."""
        from workouts.models import Exercise

        muscle_groups = [
            'chest', 'back', 'shoulders', 'biceps', 'triceps',
            'quadriceps', 'hamstrings', 'glutes',
        ]
        for mg in muscle_groups:
            for i in range(5):
                is_compound = i < 2
                Exercise.objects.create(
                    name=f'{mg.title()} Exercise {i + 1}',
                    primary_muscle_group=mg,
                    category='compound' if is_compound else 'isolation',
                    difficulty_level='intermediate',
                    is_public=True,
                )

    def _make_brief(self, trainee_id: int, trainer_id: int | None = None) -> BuilderBrief:
        return BuilderBrief(
            trainee_id=trainee_id,
            goal='build_muscle',
            days_per_week=4,
            difficulty='intermediate',
            session_length_minutes=60,
            equipment=['barbell', 'dumbbell'],
            trainer_id=trainer_id,
        )


class QuickBuildTests(BuilderTestMixin, TestCase):
    """Tests for the Quick Build endpoint."""

    def setUp(self) -> None:
        self.trainer, self.trainee = self._create_trainer_and_trainee()
        self._seed_split_templates()
        self._seed_exercises()

    def test_quick_build_creates_plan(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = quick_build(brief)

        self.assertIsInstance(result, QuickBuildResult)
        self.assertTrue(result.plan_id)
        self.assertGreater(result.weeks_count, 0)
        self.assertGreater(result.sessions_count, 0)
        self.assertGreater(result.slots_count, 0)
        self.assertTrue(result.summary)

    def test_quick_build_returns_explanations(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = quick_build(brief)

        self.assertGreater(len(result.step_explanations), 0)
        for exp in result.step_explanations:
            self.assertTrue(exp.step_name)
            self.assertTrue(exp.why)

    def test_quick_build_sets_build_mode(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = quick_build(brief)

        plan = TrainingPlan.objects.get(pk=result.plan_id)
        self.assertEqual(plan.build_mode, 'quick')
        self.assertIsNotNone(plan.builder_state)

    def test_quick_build_default_goal_duration(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = quick_build(brief)
        self.assertEqual(result.weeks_count, 8)  # build_muscle default

    def test_quick_build_custom_duration(self) -> None:
        brief = BuilderBrief(
            trainee_id=self.trainee.pk,
            goal='fat_loss',
            days_per_week=3,
            difficulty='intermediate',
            duration_weeks=12,
            trainer_id=self.trainer.pk,
        )
        result = quick_build(brief)
        self.assertEqual(result.weeks_count, 12)

    def test_quick_build_creates_decision_logs(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = quick_build(brief)

        self.assertGreater(len(result.decision_log_ids), 0)


class AdvancedBuilderTests(BuilderTestMixin, TestCase):
    """Tests for the Advanced Builder step-by-step flow."""

    def setUp(self) -> None:
        self.trainer, self.trainee = self._create_trainer_and_trainee()
        self._seed_split_templates()
        self._seed_exercises()

    def test_builder_start_creates_draft_plan(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = builder_start(brief)

        self.assertIsInstance(result, BuilderStepResult)
        self.assertTrue(result.plan_id)
        self.assertEqual(result.current_step, 'length')
        self.assertEqual(result.current_step_number, 1)

        plan = TrainingPlan.objects.get(pk=result.plan_id)
        self.assertEqual(plan.status, 'draft')
        self.assertEqual(plan.build_mode, 'advanced')

    def test_builder_start_returns_length_recommendation(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        result = builder_start(brief)

        self.assertIn('weeks', result.recommendation)
        self.assertTrue(result.why)
        self.assertGreater(len(result.alternatives), 0)

    def test_builder_advance_through_split(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        start_result = builder_start(brief)

        plan = TrainingPlan.objects.get(pk=start_result.plan_id)
        step2 = builder_advance(plan)

        self.assertEqual(step2.current_step, 'split')
        self.assertIn('name', step2.recommendation)
        self.assertTrue(step2.why)

    def test_builder_advance_through_skeleton(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        start_result = builder_start(brief)
        plan = TrainingPlan.objects.get(pk=start_result.plan_id)

        # Advance: length -> split
        builder_advance(plan)
        plan.refresh_from_db()

        # Advance: split -> skeleton
        result = builder_advance(plan)
        plan.refresh_from_db()

        self.assertEqual(result.current_step, 'skeleton')

    def test_builder_full_cycle(self) -> None:
        """Test running through all builder steps to completion."""
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        start_result = builder_start(brief)
        plan = TrainingPlan.objects.get(pk=start_result.plan_id)

        # Walk through all steps
        steps_seen: list[str] = ['length']
        max_iterations = 15  # safety valve

        for _ in range(max_iterations):
            plan.refresh_from_db()
            result = builder_advance(plan)
            steps_seen.append(result.current_step)

            if result.is_complete and result.current_step == 'complete':
                break

        self.assertIn('complete', steps_seen)

        plan.refresh_from_db()
        self.assertEqual(plan.status, 'active')
        self.assertGreater(plan.weeks.count(), 0)

    def test_builder_override_length(self) -> None:
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        start_result = builder_start(brief)
        plan = TrainingPlan.objects.get(pk=start_result.plan_id)

        # Override length to 12 weeks
        step2 = builder_advance(plan, override={'weeks': 12})
        plan.refresh_from_db()

        self.assertEqual(plan.duration_weeks, 12)
        self.assertEqual(step2.current_step, 'split')

    def test_builder_save_as_draft(self) -> None:
        """Test saving as draft instead of publishing."""
        brief = self._make_brief(self.trainee.pk, self.trainer.pk)
        start_result = builder_start(brief)
        plan = TrainingPlan.objects.get(pk=start_result.plan_id)

        # Walk to publish step
        for _ in range(15):
            plan.refresh_from_db()
            state = plan.builder_state or {}
            if state.get('current_step') == 'publish':
                break
            builder_advance(plan)

        # Save as draft
        plan.refresh_from_db()
        result = builder_advance(plan, override={'action': 'save_draft'})

        plan.refresh_from_db()
        self.assertEqual(plan.status, 'draft')
        self.assertEqual(result.current_step, 'complete')

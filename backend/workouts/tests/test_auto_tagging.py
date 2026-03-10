"""
Tests for Exercise Auto-tagging Pipeline — v6.5 Step 13.

Covers:
- Auto-tag request (with mocked AI)
- Draft apply (tags written to exercise, version incremented, DecisionLog created)
- Draft reject
- Draft edit
- Retry (new draft, old rejected)
- Tag history
- API endpoints
- AI response validation
"""
from __future__ import annotations

from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    DecisionLog,
    Exercise,
    ExerciseTagDraft,
    UndoSnapshot,
)
from workouts.services.auto_tagging_service import (
    apply_draft,
    get_current_draft,
    get_tag_history,
    reject_draft,
    request_auto_tag,
    retry_auto_tag,
    update_draft,
    _validate_ai_response,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

MOCK_AI_RESPONSE: dict = {
    'pattern_tags': ['horizontal_push'],
    'primary_muscle_group': 'chest',
    'secondary_muscle_groups': ['triceps', 'front_delts'],
    'muscle_contribution_map': {'chest': 0.6, 'triceps': 0.25, 'front_delts': 0.15},
    'stance': 'supine',
    'plane': 'sagittal',
    'rom_bias': 'mid_range',
    'athletic_skill_tags': [],
    'athletic_attribute_tags': ['power'],
    'equipment_required': ['barbell', 'bench'],
    'equipment_optional': ['wrist_wraps'],
    'confidence': {
        'pattern_tags': 0.95,
        'primary_muscle_group': 0.95,
        'stance': 0.9,
        'plane': 0.95,
        'rom_bias': 0.85,
    },
    'reasoning': {
        'pattern_tags': 'Bench press is a horizontal push.',
        'primary_muscle_group': 'Chest is the primary mover.',
        'stance': 'Performed lying on a bench.',
        'plane': 'Bar moves forward/back in sagittal plane.',
        'rom_bias': 'Moderate tension throughout ROM.',
    },
}


def _create_trainer() -> User:
    return User.objects.create_user(
        email='trainer@test.com',
        password='testpass123',
        role='TRAINER',
    )


def _create_exercise(trainer: User | None = None) -> Exercise:
    return Exercise.objects.create(
        name='Bench Press',
        description='Barbell bench press on flat bench',
        muscle_group='chest',
        category='Press',
        is_public=True,
        created_by=trainer,
    )


def _mock_ai_call(*args: object, **kwargs: object) -> dict:
    """Mock replacement for _call_ai_for_tags."""
    return MOCK_AI_RESPONSE.copy()


# ---------------------------------------------------------------------------
# Service Tests — request_auto_tag
# ---------------------------------------------------------------------------

class RequestAutoTagTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.exercise = _create_exercise()

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_creates_draft(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        self.assertEqual(result.status, 'draft')
        self.assertEqual(result.exercise_id, self.exercise.pk)
        self.assertEqual(result.retry_count, 0)

        draft = ExerciseTagDraft.objects.get(pk=result.draft_id)
        self.assertEqual(draft.pattern_tags, ['horizontal_push'])
        self.assertEqual(draft.primary_muscle_group, 'chest')
        self.assertIn('chest', draft.confidence_scores)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_nonexistent_exercise(self, mock_ai: object) -> None:
        with self.assertRaises(ValueError):
            request_auto_tag(exercise_id=99999, user=self.trainer)


# ---------------------------------------------------------------------------
# Service Tests — apply_draft
# ---------------------------------------------------------------------------

class ApplyDraftTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.exercise = _create_exercise()

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_apply_updates_exercise(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        apply_result = apply_draft(draft_id=result.draft_id, user=self.trainer)

        self.exercise.refresh_from_db()
        self.assertEqual(self.exercise.pattern_tags, ['horizontal_push'])
        self.assertEqual(self.exercise.primary_muscle_group, 'chest')
        self.assertEqual(self.exercise.version, 2)
        self.assertTrue(len(apply_result.fields_updated) > 0)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_apply_creates_decision_log(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        apply_draft(draft_id=result.draft_id, user=self.trainer)

        log = DecisionLog.objects.filter(decision_type='exercise_auto_tag_applied').first()
        self.assertIsNotNone(log)
        self.assertEqual(log.context['exercise_id'], self.exercise.pk)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_apply_creates_undo_snapshot(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        apply_draft(draft_id=result.draft_id, user=self.trainer)

        snapshot = UndoSnapshot.objects.filter(scope='exercise').first()
        self.assertIsNotNone(snapshot)
        self.assertIn('tags', snapshot.after_state)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_apply_marks_draft_applied(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        apply_draft(draft_id=result.draft_id, user=self.trainer)

        draft = ExerciseTagDraft.objects.get(pk=result.draft_id)
        self.assertEqual(draft.status, 'applied')
        self.assertIsNotNone(draft.applied_at)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_cannot_apply_twice(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        apply_draft(draft_id=result.draft_id, user=self.trainer)
        with self.assertRaises(ValueError):
            apply_draft(draft_id=result.draft_id, user=self.trainer)


# ---------------------------------------------------------------------------
# Service Tests — reject, edit, retry
# ---------------------------------------------------------------------------

class DraftManagementTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.exercise = _create_exercise()

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_reject_draft(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        reject_draft(draft_id=result.draft_id, user=self.trainer)
        draft = ExerciseTagDraft.objects.get(pk=result.draft_id)
        self.assertEqual(draft.status, 'rejected')

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_edit_draft(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        updated = update_draft(
            draft_id=result.draft_id,
            user=self.trainer,
            updates={'primary_muscle_group': 'front_delts'},
        )
        self.assertEqual(updated.primary_muscle_group, 'front_delts')

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_retry_creates_new_draft(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        retry_result = retry_auto_tag(draft_id=result.draft_id, user=self.trainer)

        self.assertNotEqual(retry_result.draft_id, result.draft_id)
        self.assertEqual(retry_result.retry_count, 1)

        # Old draft should be rejected
        old = ExerciseTagDraft.objects.get(pk=result.draft_id)
        self.assertEqual(old.status, 'rejected')

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_get_current_draft(self, mock_ai: object) -> None:
        request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        draft = get_current_draft(exercise_id=self.exercise.pk, user=self.trainer)
        self.assertIsNotNone(draft)
        self.assertEqual(draft.status, 'draft')

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_tag_history(self, mock_ai: object) -> None:
        result1 = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        retry_auto_tag(draft_id=result1.draft_id, user=self.trainer)

        history = get_tag_history(exercise_id=self.exercise.pk)
        self.assertEqual(len(history), 2)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_wrong_trainer_cannot_manage(self, mock_ai: object) -> None:
        result = request_auto_tag(exercise_id=self.exercise.pk, user=self.trainer)
        other = User.objects.create_user(email='other@test.com', password='pass', role='TRAINER')
        with self.assertRaises(ValueError):
            reject_draft(draft_id=result.draft_id, user=other)


# ---------------------------------------------------------------------------
# AI Response Validation
# ---------------------------------------------------------------------------

class AIResponseValidationTests(TestCase):

    def test_filters_invalid_tags(self) -> None:
        data = {
            'pattern_tags': ['horizontal_push', 'INVALID_TAG'],
            'primary_muscle_group': 'chest',
            'secondary_muscle_groups': ['triceps', 'not_a_muscle'],
            'muscle_contribution_map': {'chest': 0.7, 'triceps': 0.3},
            'stance': 'supine',
            'plane': 'sagittal',
            'rom_bias': 'mid_range',
            'athletic_skill_tags': ['jump_vertical', 'fake_skill'],
            'athletic_attribute_tags': ['power', 'fake_attr'],
            'confidence': {'pattern_tags': 0.9},
            'reasoning': {'pattern_tags': 'test'},
        }
        result = _validate_ai_response(data)
        self.assertEqual(result['pattern_tags'], ['horizontal_push'])
        self.assertEqual(result['secondary_muscle_groups'], ['triceps'])
        self.assertEqual(result['athletic_skill_tags'], ['jump_vertical'])
        self.assertEqual(result['athletic_attribute_tags'], ['power'])

    def test_normalizes_muscle_contribution_map(self) -> None:
        data = {
            'pattern_tags': [],
            'primary_muscle_group': 'chest',
            'secondary_muscle_groups': [],
            'muscle_contribution_map': {'chest': 0.5, 'triceps': 0.3},
            'stance': '',
            'plane': '',
            'rom_bias': '',
            'athletic_skill_tags': [],
            'athletic_attribute_tags': [],
            'confidence': {},
            'reasoning': {},
        }
        result = _validate_ai_response(data)
        total = sum(result['muscle_contribution_map'].values())
        self.assertAlmostEqual(total, 1.0, places=2)

    def test_rejects_invalid_single_choice(self) -> None:
        data = {
            'pattern_tags': [],
            'primary_muscle_group': 'NOT_REAL',
            'secondary_muscle_groups': [],
            'muscle_contribution_map': {},
            'stance': 'NOT_REAL',
            'plane': 'NOT_REAL',
            'rom_bias': 'NOT_REAL',
            'athletic_skill_tags': [],
            'athletic_attribute_tags': [],
            'confidence': {},
            'reasoning': {},
        }
        result = _validate_ai_response(data)
        self.assertEqual(result['primary_muscle_group'], '')
        self.assertEqual(result['stance'], '')
        self.assertEqual(result['plane'], '')
        self.assertEqual(result['rom_bias'], '')


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------

class AutoTagAPITests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.exercise = _create_exercise()
        self.client = APIClient()
        self.client.force_authenticate(self.trainer)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_request_auto_tag_api(self, mock_ai: object) -> None:
        resp = self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        self.assertEqual(resp.status_code, 201)
        self.assertIn('draft_id', resp.data)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_get_draft_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.get(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['pattern_tags'], ['horizontal_push'])

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_edit_draft_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.patch(
            f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/',
            {'primary_muscle_group': 'front_delts'},
            format='json',
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['primary_muscle_group'], 'front_delts')

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_apply_draft_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/apply/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('new_version', resp.data)
        self.assertEqual(resp.data['new_version'], 2)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_reject_draft_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/reject/')
        self.assertEqual(resp.status_code, 204)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_retry_draft_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/retry/')
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.data['retry_count'], 1)

    @patch('workouts.services.auto_tagging_service._call_ai_for_tags', side_effect=_mock_ai_call)
    def test_tag_history_api(self, mock_ai: object) -> None:
        self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        resp = self.client.get(f'/api/workouts/exercises/{self.exercise.pk}/tag-history/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(len(resp.data), 1)

    def test_get_draft_no_draft(self) -> None:
        resp = self.client.get(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag-draft/')
        self.assertEqual(resp.status_code, 404)

    def test_trainee_cannot_auto_tag(self) -> None:
        trainee = User.objects.create_user(
            email='trainee@test.com', password='pass', role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.client.force_authenticate(trainee)
        resp = self.client.post(f'/api/workouts/exercises/{self.exercise.pk}/auto-tag/')
        self.assertEqual(resp.status_code, 403)

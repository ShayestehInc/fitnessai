"""
Tests for Program Import Pipeline — v6.5 Step 12.

Covers:
- CSV parsing & validation
- Draft creation (valid + error cases)
- Confirm import (atomic plan creation)
- Reject draft
- API endpoints (upload, list, detail, confirm, delete)
"""
from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    Exercise,
    PlanSession,
    PlanSlot,
    PlanWeek,
    ProgramImportDraft,
    TrainingPlan,
)
from workouts.services.program_import_service import (
    confirm_import,
    get_draft,
    list_drafts,
    parse_csv_and_create_draft,
    reject_draft,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

VALID_CSV = (
    "week,day_of_week,session_label,order,exercise_name,slot_role,sets,reps_min,reps_max,rest_seconds,load_pct,notes\n"
    "1,1,Push Day,1,Bench Press,primary_compound,4,6,8,120,80,\n"
    "1,1,Push Day,2,Overhead Press,secondary_compound,3,8,10,90,,\n"
    "1,3,Pull Day,1,Barbell Row,primary_compound,4,6,8,120,75,heavy\n"
    "2,1,Push Day,1,Bench Press,primary_compound,4,5,7,120,85,\n"
)


def _create_trainer() -> User:
    return User.objects.create_user(
        email='trainer@test.com',
        password='testpass123',
        role='TRAINER',
    )


def _create_trainee(trainer: User) -> User:
    return User.objects.create_user(
        email='trainee@test.com',
        password='testpass123',
        role='TRAINEE',
        parent_trainer=trainer,
    )


def _seed_exercises() -> None:
    Exercise.objects.create(name='Bench Press', is_public=True)
    Exercise.objects.create(name='Overhead Press', is_public=True)
    Exercise.objects.create(name='Barbell Row', is_public=True)


# ---------------------------------------------------------------------------
# Service Tests — parse_csv_and_create_draft
# ---------------------------------------------------------------------------

class ParseCSVTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        _seed_exercises()

    def test_valid_csv_creates_draft(self) -> None:
        result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            plan_name='Test Program',
            goal='strength',
        )
        self.assertEqual(result.status, 'pending_review')
        self.assertEqual(result.total_weeks, 2)
        self.assertEqual(result.total_sessions, 3)  # Push Day wk1, Pull Day wk1, Push Day wk2
        self.assertEqual(result.total_slots, 4)
        self.assertEqual(result.errors, [])

    def test_missing_header_columns(self) -> None:
        csv = "week,day_of_week\n1,1\n"
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('Missing required columns' in e for e in result.errors))

    def test_empty_csv(self) -> None:
        csv = "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n"
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('no data rows' in e for e in result.errors))

    def test_no_header_row(self) -> None:
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content='',
        )
        self.assertTrue(any('no header' in e.lower() or 'no data' in e.lower() for e in result.errors))

    def test_unknown_exercise_produces_error(self) -> None:
        csv = (
            "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n"
            "1,1,Leg Day,1,Nonexistent Exercise,3,8,12\n"
        )
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('Nonexistent Exercise' in e for e in result.errors))

    def test_reps_min_gt_reps_max_error(self) -> None:
        csv = (
            "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n"
            "1,1,Day,1,Bench Press,3,12,8\n"
        )
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('reps_min' in e for e in result.errors))

    def test_invalid_week_number(self) -> None:
        csv = (
            "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n"
            "abc,1,Day,1,Bench Press,3,8,12\n"
        )
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('invalid week' in e for e in result.errors))

    def test_trainee_assignment(self) -> None:
        trainee = _create_trainee(self.trainer)
        result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            trainee_id=trainee.pk,
        )
        self.assertEqual(result.errors, [])
        draft = ProgramImportDraft.objects.get(pk=result.draft_id)
        self.assertEqual(draft.trainee_id, trainee.pk)

    def test_invalid_trainee_id(self) -> None:
        result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            trainee_id=99999,
        )
        self.assertTrue(any('not found' in e for e in result.errors))

    def test_unknown_slot_role_defaults_to_isolation(self) -> None:
        csv = (
            "week,day_of_week,session_label,order,exercise_name,slot_role,sets,reps_min,reps_max\n"
            "1,1,Day,1,Bench Press,unknown_role,3,8,12\n"
        )
        result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(any('unknown slot_role' in w for w in result.warnings))
        # Slot should default to 'isolation'
        weeks = result.parsed_preview.get('weeks', {})
        slot = list(list(weeks.values())[0]['sessions'].values())[0]['slots'][0]
        self.assertEqual(slot['slot_role'], 'isolation')


# ---------------------------------------------------------------------------
# Service Tests — confirm_import
# ---------------------------------------------------------------------------

class ConfirmImportTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        _seed_exercises()

    def test_confirm_creates_plan_hierarchy(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            plan_name='My Program',
            goal='hypertrophy',
            trainee_id=self.trainee.pk,
        )
        self.assertEqual(parse_result.errors, [])

        result = confirm_import(
            draft_id=parse_result.draft_id,
            trainer=self.trainer,
        )
        self.assertEqual(result.weeks_created, 2)
        self.assertEqual(result.sessions_created, 3)
        self.assertEqual(result.slots_created, 4)

        # Verify actual DB objects
        plan = TrainingPlan.objects.get(pk=result.training_plan_id)
        self.assertEqual(plan.name, 'My Program')
        self.assertEqual(plan.goal, 'hypertrophy')
        self.assertEqual(plan.trainee_id, self.trainee.pk)
        self.assertEqual(PlanWeek.objects.filter(plan=plan).count(), 2)
        self.assertEqual(
            PlanSession.objects.filter(week__plan=plan).count(), 3,
        )
        self.assertEqual(
            PlanSlot.objects.filter(session__week__plan=plan).count(), 4,
        )

    def test_confirm_updates_draft_status(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            trainee_id=self.trainee.pk,
        )
        confirm_import(draft_id=parse_result.draft_id, trainer=self.trainer)

        draft = ProgramImportDraft.objects.get(pk=parse_result.draft_id)
        self.assertEqual(draft.status, 'confirmed')
        self.assertIsNotNone(draft.confirmed_at)
        self.assertIsNotNone(draft.training_plan)

    def test_confirm_rejects_already_confirmed(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            trainee_id=self.trainee.pk,
        )
        confirm_import(draft_id=parse_result.draft_id, trainer=self.trainer)

        with self.assertRaises(ValueError):
            confirm_import(draft_id=parse_result.draft_id, trainer=self.trainer)

    def test_confirm_rejects_draft_with_errors(self) -> None:
        csv = "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n1,1,Day,1,MISSING_EX,3,8,12\n"
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=csv,
        )
        self.assertTrue(len(parse_result.errors) > 0)

        with self.assertRaises(ValueError):
            confirm_import(draft_id=parse_result.draft_id, trainer=self.trainer)


# ---------------------------------------------------------------------------
# Service Tests — reject, get, list
# ---------------------------------------------------------------------------

class DraftManagementTests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        _seed_exercises()

    def test_reject_draft(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=VALID_CSV,
        )
        reject_draft(draft_id=parse_result.draft_id, trainer=self.trainer)
        draft = ProgramImportDraft.objects.get(pk=parse_result.draft_id)
        self.assertEqual(draft.status, 'rejected')

    def test_reject_already_confirmed_fails(self) -> None:
        trainee = _create_trainee(self.trainer)
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer,
            csv_content=VALID_CSV,
            trainee_id=trainee.pk,
        )
        confirm_import(draft_id=parse_result.draft_id, trainer=self.trainer)

        with self.assertRaises(ValueError):
            reject_draft(draft_id=parse_result.draft_id, trainer=self.trainer)

    def test_get_draft(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=VALID_CSV,
        )
        draft = get_draft(draft_id=parse_result.draft_id, trainer=self.trainer)
        self.assertEqual(str(draft.pk), parse_result.draft_id)

    def test_get_draft_wrong_trainer(self) -> None:
        parse_result = parse_csv_and_create_draft(
            trainer=self.trainer, csv_content=VALID_CSV,
        )
        other_trainer = User.objects.create_user(
            email='other@test.com', password='pass', role='TRAINER',
        )
        with self.assertRaises(ValueError):
            get_draft(draft_id=parse_result.draft_id, trainer=other_trainer)

    def test_list_drafts(self) -> None:
        parse_csv_and_create_draft(trainer=self.trainer, csv_content=VALID_CSV, plan_name='A')
        parse_csv_and_create_draft(trainer=self.trainer, csv_content=VALID_CSV, plan_name='B')
        drafts = list_drafts(trainer=self.trainer)
        self.assertEqual(len(drafts), 2)


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------

class ImportAPITests(TestCase):

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        _seed_exercises()
        self.client = APIClient()
        self.client.force_authenticate(self.trainer)

    def test_upload_csv(self) -> None:
        resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV, 'plan_name': 'API Test'},
            format='json',
        )
        self.assertEqual(resp.status_code, 201)
        self.assertIn('draft_id', resp.data)
        self.assertEqual(resp.data['total_weeks'], 2)

    def test_upload_invalid_csv(self) -> None:
        resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': 'bad,csv\n1,2'},
            format='json',
        )
        self.assertEqual(resp.status_code, 201)  # Draft created with errors
        self.assertTrue(len(resp.data['errors']) > 0)

    def test_list_drafts_api(self) -> None:
        self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV},
            format='json',
        )
        resp = self.client.get('/api/workouts/program-imports/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(len(resp.data), 1)

    def test_get_draft_detail(self) -> None:
        upload_resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV},
            format='json',
        )
        draft_id = upload_resp.data['draft_id']
        resp = self.client.get(f'/api/workouts/program-imports/{draft_id}/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(str(resp.data['id']), draft_id)

    def test_confirm_import_api(self) -> None:
        upload_resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV, 'trainee_id': self.trainee.pk},
            format='json',
        )
        draft_id = upload_resp.data['draft_id']
        resp = self.client.post(f'/api/workouts/program-imports/{draft_id}/confirm/')
        self.assertEqual(resp.status_code, 201)
        self.assertIn('training_plan_id', resp.data)

    def test_reject_draft_api(self) -> None:
        upload_resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV},
            format='json',
        )
        draft_id = upload_resp.data['draft_id']
        resp = self.client.delete(f'/api/workouts/program-imports/{draft_id}/')
        self.assertEqual(resp.status_code, 204)

    def test_trainee_cannot_upload(self) -> None:
        self.client.force_authenticate(self.trainee)
        resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': VALID_CSV},
            format='json',
        )
        self.assertEqual(resp.status_code, 403)

    def test_confirm_draft_with_errors_fails(self) -> None:
        csv = "week,day_of_week,session_label,order,exercise_name,sets,reps_min,reps_max\n1,1,Day,1,MISSING,3,8,12\n"
        upload_resp = self.client.post(
            '/api/workouts/program-imports/upload/',
            {'csv_content': csv},
            format='json',
        )
        draft_id = upload_resp.data['draft_id']
        resp = self.client.post(f'/api/workouts/program-imports/{draft_id}/confirm/')
        self.assertEqual(resp.status_code, 400)

    def test_get_nonexistent_draft(self) -> None:
        resp = self.client.get('/api/workouts/program-imports/00000000-0000-0000-0000-000000000000/')
        self.assertEqual(resp.status_code, 404)

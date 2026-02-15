"""
Tests for workout history and workout detail endpoints.

Covers:
- AC-1: Only DailyLogs with actual exercise data are returned
- AC-2: Computed summary fields (workout_name, exercise_count, total_sets, total_volume_lbs, duration_display)
- AC-3: Pagination via ?page=1&page_size=20
- AC-4: Row-level security (IsTrainee permission, own logs only)
- Workout detail returns restricted fields (id, date, workout_data, notes)
- Workout detail for another user's log returns 404
- Edge cases: empty exercises, null workout_data, sessions format, etc.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
from workouts.models import DailyLog


class WorkoutHistoryTestBase(TestCase):
    """Shared setup for workout history tests."""

    HISTORY_URL = '/api/workouts/daily-logs/workout-history/'

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.other_trainee = User.objects.create_user(
            email='other@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainee)

    def _create_log(
        self,
        trainee: User | None = None,
        log_date: date | None = None,
        workout_data: dict[str, Any] | None = None,
        nutrition_data: dict[str, Any] | None = None,
        notes: str = '',
    ) -> DailyLog:
        """Helper to create a DailyLog with sensible defaults."""
        if trainee is None:
            trainee = self.trainee
        if log_date is None:
            log_date = date.today()
        return DailyLog.objects.create(
            trainee=trainee,
            date=log_date,
            workout_data=workout_data if workout_data is not None else {},
            nutrition_data=nutrition_data if nutrition_data is not None else {},
            notes=notes,
        )

    @staticmethod
    def _make_workout_data(
        workout_name: str = 'Push Day',
        duration: str = '45:00',
        exercises: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        """Build a realistic workout_data dict."""
        if exercises is None:
            exercises = [
                {
                    'exercise_name': 'Bench Press',
                    'exercise_id': 1,
                    'sets': [
                        {'set_number': 1, 'reps': 10, 'weight': 135, 'unit': 'lbs', 'completed': True},
                        {'set_number': 2, 'reps': 8, 'weight': 155, 'unit': 'lbs', 'completed': True},
                        {'set_number': 3, 'reps': 6, 'weight': 175, 'unit': 'lbs', 'completed': True},
                    ],
                },
            ]
        return {
            'workout_name': workout_name,
            'duration': duration,
            'exercises': exercises,
        }


# ---------------------------------------------------------------------------
# AC-1: Filtering — only logs with actual exercise data
# ---------------------------------------------------------------------------

class WorkoutHistoryFilteringTests(WorkoutHistoryTestBase):
    """AC-1: Endpoint returns only DailyLogs with actual workout data."""

    def test_log_with_exercises_is_returned(self) -> None:
        """A log with populated exercises array must appear in results."""
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)

    def test_log_with_default_empty_workout_data_excluded(self) -> None:
        """A log created with default workout_data={} must NOT appear.

        Note: The DailyLog.workout_data field has default=dict and no null=True,
        so the column cannot be NULL at the DB level. The view's exclude(isnull=True)
        is purely defensive. This test verifies the default {} case is excluded.
        """
        self._create_log(log_date=date.today())  # defaults to workout_data={}

        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)

    def test_log_with_empty_dict_workout_data_excluded(self) -> None:
        """A log where workout_data is {} must NOT appear."""
        self._create_log(log_date=date.today(), workout_data={})

        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)

    def test_log_with_empty_exercises_list_excluded(self) -> None:
        """A log where workout_data = {"exercises": []} must NOT appear."""
        self._create_log(
            log_date=date.today(),
            workout_data={'exercises': []},
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)

    def test_log_with_only_nutrition_data_excluded(self) -> None:
        """A log that has nutrition_data but no workout_data exercises must NOT appear."""
        self._create_log(
            log_date=date.today(),
            workout_data={},
            nutrition_data={'meals': [{'name': 'Lunch', 'calories': 600}]},
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)

    def test_log_with_sessions_key_is_returned(self) -> None:
        """A log using the 'sessions' key format must appear."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'sessions': [
                    {
                        'workout_name': 'Push Day',
                        'duration': '45:00',
                        'exercises': [
                            {
                                'exercise_name': 'Bench Press',
                                'sets': [{'reps': 8, 'weight': 135, 'completed': True}],
                            },
                        ],
                    },
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)

    def test_multiple_logs_mixed_validity(self) -> None:
        """Only valid logs appear when there's a mix of valid and invalid."""
        base_date = date(2026, 1, 1)
        # Valid
        self._create_log(
            log_date=base_date,
            workout_data=self._make_workout_data('Push Day'),
        )
        # Valid
        self._create_log(
            log_date=base_date + timedelta(days=1),
            workout_data=self._make_workout_data('Pull Day'),
        )
        # Invalid: empty dict
        self._create_log(
            log_date=base_date + timedelta(days=2),
            workout_data={},
        )
        # Invalid: empty exercises
        self._create_log(
            log_date=base_date + timedelta(days=3),
            workout_data={'exercises': []},
        )

        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 2)


# ---------------------------------------------------------------------------
# AC-2: Computed summary fields
# ---------------------------------------------------------------------------

class WorkoutHistorySummaryFieldTests(WorkoutHistoryTestBase):
    """AC-2: Each log has workout_name, exercise_count, total_sets, total_volume_lbs, duration_display."""

    def test_workout_name_from_top_level(self) -> None:
        """workout_name extracted from workout_data.workout_name."""
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(workout_name='Leg Day'),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['workout_name'], 'Leg Day')

    def test_workout_name_from_first_session(self) -> None:
        """If no top-level workout_name, use first session's name."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'sessions': [
                    {'workout_name': 'Session Push Day', 'exercises': []},
                ],
                'exercises': [
                    {
                        'exercise_name': 'Bench',
                        'sets': [{'reps': 10, 'weight': 100, 'completed': True}],
                    },
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['workout_name'], 'Session Push Day')

    def test_workout_name_fallback_to_default(self) -> None:
        """If no workout_name anywhere, fallback to 'Workout'."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {
                        'exercise_name': 'Bench',
                        'sets': [{'reps': 10, 'weight': 100, 'completed': True}],
                    },
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['workout_name'], 'Workout')

    def test_exercise_count(self) -> None:
        """exercise_count equals the number of exercises in exercises array."""
        exercises = [
            {
                'exercise_name': 'Bench Press',
                'sets': [{'reps': 10, 'weight': 135, 'completed': True}],
            },
            {
                'exercise_name': 'Incline DB Press',
                'sets': [{'reps': 12, 'weight': 50, 'completed': True}],
            },
            {
                'exercise_name': 'Cable Fly',
                'sets': [{'reps': 15, 'weight': 30, 'completed': True}],
            },
        ]
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(exercises=exercises),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['exercise_count'], 3)

    def test_total_sets(self) -> None:
        """total_sets is the sum of all sets across all exercises."""
        exercises = [
            {
                'exercise_name': 'Bench',
                'sets': [
                    {'reps': 10, 'weight': 135, 'completed': True},
                    {'reps': 8, 'weight': 155, 'completed': True},
                ],
            },
            {
                'exercise_name': 'OHP',
                'sets': [
                    {'reps': 10, 'weight': 95, 'completed': True},
                    {'reps': 8, 'weight': 105, 'completed': True},
                    {'reps': 6, 'weight': 115, 'completed': True},
                ],
            },
        ]
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(exercises=exercises),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['total_sets'], 5)  # 2 + 3

    def test_total_volume_lbs_calculation(self) -> None:
        """total_volume_lbs = sum of (weight * reps) for all completed sets."""
        exercises = [
            {
                'exercise_name': 'Bench',
                'sets': [
                    {'reps': 10, 'weight': 100, 'completed': True},   # 1000
                    {'reps': 8, 'weight': 120, 'completed': True},    # 960
                    {'reps': 5, 'weight': 150, 'completed': False},   # skipped (not completed)
                ],
            },
        ]
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(exercises=exercises),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['total_volume_lbs'], 1960.0)

    def test_total_volume_excludes_incomplete_sets(self) -> None:
        """Sets with completed=False should not contribute to volume."""
        exercises = [
            {
                'exercise_name': 'Squat',
                'sets': [
                    {'reps': 5, 'weight': 225, 'completed': False},
                    {'reps': 5, 'weight': 225, 'completed': False},
                ],
            },
        ]
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(exercises=exercises),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['total_volume_lbs'], 0.0)

    def test_total_volume_with_missing_completed_field(self) -> None:
        """If 'completed' key is absent, default to True per serializer logic."""
        exercises = [
            {
                'exercise_name': 'Deadlift',
                'sets': [
                    {'reps': 5, 'weight': 315},  # no 'completed' key
                ],
            },
        ]
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(exercises=exercises),
        )
        response = self.client.get(self.HISTORY_URL)
        # Default completed=True, so volume = 5 * 315 = 1575
        self.assertEqual(response.data['results'][0]['total_volume_lbs'], 1575.0)

    def test_duration_display_from_top_level(self) -> None:
        """duration_display extracted from workout_data.duration."""
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(duration='1:15:30'),
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['duration_display'], '1:15:30')

    def test_duration_display_fallback(self) -> None:
        """When no duration is available, default to '0:00'."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {
                        'exercise_name': 'Bench',
                        'sets': [{'reps': 10, 'weight': 100, 'completed': True}],
                    },
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['duration_display'], '0:00')

    def test_duration_display_from_session(self) -> None:
        """duration_display from first session when no top-level duration."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'sessions': [
                    {'workout_name': 'Arms', 'duration': '30:00'},
                ],
                'exercises': [
                    {
                        'exercise_name': 'Curl',
                        'sets': [{'reps': 12, 'weight': 30, 'completed': True}],
                    },
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['duration_display'], '30:00')

    def test_response_fields_present(self) -> None:
        """Verify all expected fields exist in each result item."""
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
        )
        response = self.client.get(self.HISTORY_URL)
        item = response.data['results'][0]
        expected_fields = {'id', 'date', 'workout_name', 'exercise_count',
                           'total_sets', 'total_volume_lbs', 'duration_display'}
        self.assertTrue(expected_fields.issubset(set(item.keys())))

    def test_no_extra_sensitive_fields_exposed(self) -> None:
        """History summary must NOT include trainee email or nutrition_data."""
        self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
            nutrition_data={'meals': [{'name': 'Lunch', 'calories': 600}]},
        )
        response = self.client.get(self.HISTORY_URL)
        item = response.data['results'][0]
        self.assertNotIn('trainee_email', item)
        self.assertNotIn('nutrition_data', item)
        self.assertNotIn('trainee', item)


# ---------------------------------------------------------------------------
# AC-3: Pagination
# ---------------------------------------------------------------------------

class WorkoutHistoryPaginationTests(WorkoutHistoryTestBase):
    """AC-3: Pagination via ?page=1&page_size=20."""

    def _seed_logs(self, count: int) -> None:
        """Create `count` valid workout logs on consecutive days."""
        base_date = date(2025, 1, 1)
        for i in range(count):
            self._create_log(
                log_date=base_date + timedelta(days=i),
                workout_data=self._make_workout_data(workout_name=f'Workout {i}'),
            )

    def test_default_page_size_is_20(self) -> None:
        """Without page_size param, default returns 20 items."""
        self._seed_logs(25)
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 20)
        self.assertEqual(response.data['count'], 25)

    def test_custom_page_size(self) -> None:
        """page_size=5 returns exactly 5 items per page."""
        self._seed_logs(12)
        response = self.client.get(f'{self.HISTORY_URL}?page_size=5')
        self.assertEqual(len(response.data['results']), 5)
        self.assertEqual(response.data['count'], 12)

    def test_page_2(self) -> None:
        """page=2 with page_size=5 returns the next batch."""
        self._seed_logs(12)
        response = self.client.get(f'{self.HISTORY_URL}?page=2&page_size=5')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 5)

    def test_last_page_partial(self) -> None:
        """Last page returns remaining items even if less than page_size."""
        self._seed_logs(7)
        response = self.client.get(f'{self.HISTORY_URL}?page=2&page_size=5')
        self.assertEqual(len(response.data['results']), 2)

    def test_max_page_size_capped_at_50(self) -> None:
        """page_size over 50 should be capped to 50."""
        self._seed_logs(55)
        response = self.client.get(f'{self.HISTORY_URL}?page_size=100')
        self.assertEqual(len(response.data['results']), 50)

    def test_pagination_metadata_present(self) -> None:
        """Response includes count, next, previous pagination metadata."""
        self._seed_logs(25)
        response = self.client.get(f'{self.HISTORY_URL}?page_size=10')
        self.assertIn('count', response.data)
        self.assertIn('next', response.data)
        self.assertIn('previous', response.data)
        self.assertIn('results', response.data)
        self.assertEqual(response.data['count'], 25)
        self.assertIsNotNone(response.data['next'])
        self.assertIsNone(response.data['previous'])

    def test_results_ordered_newest_first(self) -> None:
        """Results must be ordered by date descending (newest first)."""
        base_date = date(2025, 6, 1)
        for i in range(5):
            self._create_log(
                log_date=base_date + timedelta(days=i),
                workout_data=self._make_workout_data(workout_name=f'Day {i}'),
            )
        response = self.client.get(self.HISTORY_URL)
        dates = [r['date'] for r in response.data['results']]
        self.assertEqual(dates, sorted(dates, reverse=True))

    def test_empty_result_set(self) -> None:
        """No logs at all returns empty result list with count 0."""
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 0)
        self.assertEqual(response.data['results'], [])

    def test_invalid_page_returns_404(self) -> None:
        """Requesting a page beyond available data returns 404."""
        self._seed_logs(3)
        response = self.client.get(f'{self.HISTORY_URL}?page=999')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


# ---------------------------------------------------------------------------
# AC-4: Row-level security
# ---------------------------------------------------------------------------

class WorkoutHistorySecurityTests(WorkoutHistoryTestBase):
    """AC-4: IsTrainee permission with row-level security."""

    def test_trainee_sees_own_logs_only(self) -> None:
        """Trainee must only see their own workout logs."""
        self._create_log(
            trainee=self.trainee,
            log_date=date(2026, 1, 1),
            workout_data=self._make_workout_data('My Workout'),
        )
        self._create_log(
            trainee=self.other_trainee,
            log_date=date(2026, 1, 1),
            workout_data=self._make_workout_data('Other Workout'),
        )

        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['workout_name'], 'My Workout')

    def test_trainer_cannot_access_endpoint(self) -> None:
        """Trainers must NOT be able to access the workout-history endpoint."""
        trainer_client = APIClient()
        trainer_client.force_authenticate(user=self.trainer)

        response = trainer_client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_cannot_access_endpoint(self) -> None:
        """Admins must NOT be able to access the workout-history endpoint (IsTrainee only)."""
        admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            role='ADMIN',
        )
        admin_client = APIClient()
        admin_client.force_authenticate(user=admin_user)

        response = admin_client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_unauthenticated_user_rejected(self) -> None:
        """Unauthenticated requests must return 401."""
        anon_client = APIClient()
        response = anon_client.get(self.HISTORY_URL)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_trainee_cannot_see_other_trainees_logs(self) -> None:
        """Cross-trainee data leakage must be impossible."""
        # Create log for other_trainee
        self._create_log(
            trainee=self.other_trainee,
            log_date=date(2026, 1, 15),
            workout_data=self._make_workout_data('Secret Workout'),
        )

        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['count'], 0)


# ---------------------------------------------------------------------------
# Workout Detail Endpoint
# ---------------------------------------------------------------------------

class WorkoutDetailTests(WorkoutHistoryTestBase):
    """Tests for GET /api/workouts/daily-logs/{id}/workout-detail/."""

    def _detail_url(self, log_id: int) -> str:
        return f'/api/workouts/daily-logs/{log_id}/workout-detail/'

    def test_detail_returns_restricted_fields_only(self) -> None:
        """Detail response must contain only id, date, workout_data, notes."""
        log = self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
            nutrition_data={'meals': [{'name': 'Lunch', 'calories': 600}]},
            notes='Felt strong today',
        )
        response = self.client.get(self._detail_url(log.id))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(set(response.data.keys()), {'id', 'date', 'workout_data', 'notes'})

    def test_detail_does_not_leak_nutrition_data(self) -> None:
        """nutrition_data must NOT be exposed through detail endpoint."""
        log = self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
            nutrition_data={'meals': [{'name': 'Dinner', 'calories': 800}]},
        )
        response = self.client.get(self._detail_url(log.id))
        self.assertNotIn('nutrition_data', response.data)
        self.assertNotIn('trainee_email', response.data)
        self.assertNotIn('trainee', response.data)

    def test_detail_returns_workout_data(self) -> None:
        """Detail must include full workout_data JSON."""
        workout_data = self._make_workout_data(workout_name='Arms Day')
        log = self._create_log(
            log_date=date.today(),
            workout_data=workout_data,
        )
        response = self.client.get(self._detail_url(log.id))
        self.assertEqual(response.data['workout_data']['workout_name'], 'Arms Day')
        self.assertEqual(len(response.data['workout_data']['exercises']), 1)

    def test_detail_returns_notes(self) -> None:
        """Notes field should be returned if present."""
        log = self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
            notes='Extra cardio after lifting',
        )
        response = self.client.get(self._detail_url(log.id))
        self.assertEqual(response.data['notes'], 'Extra cardio after lifting')

    def test_detail_for_other_users_log_returns_404(self) -> None:
        """Accessing another user's log via detail must return 404 (not 403)."""
        other_log = self._create_log(
            trainee=self.other_trainee,
            log_date=date.today(),
            workout_data=self._make_workout_data(),
        )
        response = self.client.get(self._detail_url(other_log.id))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_detail_nonexistent_log_returns_404(self) -> None:
        """Requesting a non-existent log ID must return 404."""
        response = self.client.get(self._detail_url(99999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_detail_trainer_forbidden(self) -> None:
        """Trainer must NOT be able to access workout-detail endpoint."""
        log = self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
        )
        trainer_client = APIClient()
        trainer_client.force_authenticate(user=self.trainer)

        response = trainer_client.get(self._detail_url(log.id))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_detail_unauthenticated_rejected(self) -> None:
        """Unauthenticated requests to detail must return 401."""
        log = self._create_log(
            log_date=date.today(),
            workout_data=self._make_workout_data(),
        )
        anon_client = APIClient()
        response = anon_client.get(self._detail_url(log.id))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Serializer edge cases
# ---------------------------------------------------------------------------

class WorkoutHistorySerializerEdgeCaseTests(WorkoutHistoryTestBase):
    """Edge cases in workout_data JSON parsing."""

    def test_exercise_with_no_sets_key(self) -> None:
        """An exercise dict missing the 'sets' key should contribute 0 sets/volume."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {'exercise_name': 'Plank'},  # no sets
                ],
                'workout_name': 'Core Day',
            },
        )
        response = self.client.get(self.HISTORY_URL)
        result = response.data['results'][0]
        self.assertEqual(result['exercise_count'], 1)
        self.assertEqual(result['total_sets'], 0)
        self.assertEqual(result['total_volume_lbs'], 0.0)

    def test_exercise_with_non_list_sets(self) -> None:
        """If 'sets' is not a list, treat as 0 sets."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {'exercise_name': 'Bench', 'sets': 'invalid'},
                ],
                'workout_name': 'Bad Data',
            },
        )
        response = self.client.get(self.HISTORY_URL)
        result = response.data['results'][0]
        self.assertEqual(result['total_sets'], 0)

    def test_set_with_non_numeric_weight(self) -> None:
        """Non-numeric weight values should be safely ignored in volume calc."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {
                        'exercise_name': 'Bench',
                        'sets': [
                            {'reps': 10, 'weight': 'heavy', 'completed': True},
                            {'reps': 8, 'weight': 135, 'completed': True},
                        ],
                    },
                ],
                'workout_name': 'Mixed Data',
            },
        )
        response = self.client.get(self.HISTORY_URL)
        result = response.data['results'][0]
        # First set ignored (non-numeric weight), second set = 8 * 135 = 1080
        self.assertEqual(result['total_volume_lbs'], 1080.0)
        self.assertEqual(result['total_sets'], 2)

    def test_exercises_array_with_non_dict_items(self) -> None:
        """Non-dict items in exercises array should be silently skipped."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    'not a dict',
                    42,
                    {'exercise_name': 'Squat', 'sets': [{'reps': 5, 'weight': 225, 'completed': True}]},
                ],
                'workout_name': 'Messy Data',
            },
        )
        response = self.client.get(self.HISTORY_URL)
        result = response.data['results'][0]
        self.assertEqual(result['exercise_count'], 1)
        self.assertEqual(result['total_sets'], 1)

    def test_volume_rounded_to_one_decimal(self) -> None:
        """total_volume_lbs should be rounded to one decimal place."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'exercises': [
                    {
                        'exercise_name': 'Bench',
                        'sets': [
                            {'reps': 3, 'weight': 33.33, 'completed': True},
                        ],
                    },
                ],
                'workout_name': 'Precision Test',
            },
        )
        response = self.client.get(self.HISTORY_URL)
        result = response.data['results'][0]
        # 3 * 33.33 = 99.99, rounded to 1 decimal = 100.0
        self.assertEqual(result['total_volume_lbs'], 100.0)

    def test_workout_name_non_string_ignored(self) -> None:
        """If workout_name is not a string, fallback to 'Workout'."""
        self._create_log(
            log_date=date.today(),
            workout_data={
                'workout_name': 123,
                'exercises': [
                    {'exercise_name': 'Bench', 'sets': [{'reps': 10, 'weight': 100}]},
                ],
            },
        )
        response = self.client.get(self.HISTORY_URL)
        self.assertEqual(response.data['results'][0]['workout_name'], 'Workout')

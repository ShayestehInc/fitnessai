# Dev Done: Trainee Workout History + Home Screen Recent Workouts

## Date: 2026-02-14

## Summary
Implemented full workout history feature: backend endpoint with computed summary fields, paginated workout history screen, workout detail screen with exercise/survey data, and home screen "Recent Workouts" section showing last 3 completed workouts.

## Files Created
1. **`mobile/lib/features/workout_log/data/models/workout_history_model.dart`** — `WorkoutHistorySummary` model with fromJson, formattedDate, formattedVolume
2. **`mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart`** — `WorkoutHistoryNotifier` with pagination (loadInitial, loadMore, refresh)
3. **`mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`** — Paginated list with shimmer loading, empty/error states, infinite scroll
4. **`mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`** — Detail view with exercise sets table, readiness/post-workout survey badges

## Files Modified

### Backend
5. **`backend/workouts/serializers.py`** — Added `WorkoutHistorySummarySerializer` with computed fields (workout_name, exercise_count, total_sets, total_volume_lbs, duration_display)
6. **`backend/workouts/views.py`** — Added `WorkoutHistoryPagination` class, `workout_history` action on `DailyLogViewSet` with IsTrainee permission, workout_data filtering, pagination

### Mobile
7. **`mobile/lib/core/constants/api_constants.dart`** — Added `workoutHistory` endpoint
8. **`mobile/lib/features/workout_log/data/repositories/workout_repository.dart`** — Updated `getWorkoutHistory()` with pagination params, added `getRecentWorkouts()` convenience method
9. **`mobile/lib/core/router/app_router.dart`** — Added `/workout-history` and `/workout-detail` routes
10. **`mobile/lib/features/home/presentation/providers/home_provider.dart`** — Added `recentWorkouts` to HomeState, fetches 3 recent workouts in parallel with other data
11. **`mobile/lib/features/home/presentation/screens/home_screen.dart`** — Added "Recent Workouts" section with See All navigation, shimmer loading, empty state, `_RecentWorkoutCard` widget

## Key Decisions
- Used plain Dart classes (not Freezed) for the model to match `home_provider.dart` pattern and avoid code gen
- Backend Python-level filtering as second pass for edge cases Django ORM can't handle
- Full `workout_data` returned in history so detail screen doesn't need second API call
- Survey data extraction handles both top-level and session-level keys

## Deviations from Ticket
- None. All 22 acceptance criteria addressed.

## How to Manually Test
1. **Backend**: `GET /api/workouts/daily-logs/workout-history/?page=1&page_size=3`
2. **Home Screen**: Open trainee home → scroll to "Recent Workouts" section
3. **History Screen**: Tap "See All" → paginated list → scroll to load more → pull to refresh
4. **Detail Screen**: Tap any workout → exercise list, sets table, survey badges
5. **Empty State**: New trainee → see empty messages on both home and history
6. **Error State**: Disconnect network → error with retry button

## Test Results
- Backend: 186 tests, 184 passed, 2 pre-existing MCP module errors (unrelated)
- Flutter analyze: 223 issues, all pre-existing. 0 new errors/warnings from our changes.

# Feature: Trainee Workout History + Home Screen Recent Workouts

## Priority
High — Trainees log workouts daily but have zero way to review past sessions. A fitness app without workout history is fundamentally broken.

## User Stories

### Story 1: Workout History Screen
As a **trainee**, I want to see a list of all my past workouts so that I can track my progress over time.

### Story 2: Workout Detail View
As a **trainee**, I want to tap a past workout and see every exercise, set, rep, and weight I logged so that I can plan today's session based on previous performance.

### Story 3: Recent Workouts on Home Screen
As a **trainee**, I want to see my last 3 completed workouts on the home screen so that I can quickly access recent sessions without navigating away.

## Acceptance Criteria

### Backend (AC-1 through AC-4)
- [ ] AC-1: `GET /api/workouts/daily-logs/workout-history/` custom action returns only DailyLogs where `workout_data` contains actual exercise data (not null, not `{}`, not `{"exercises": []}`)
- [ ] AC-2: Response includes computed summary fields per log: `workout_name`, `exercise_count`, `total_sets`, `total_volume_lbs`, `duration_display`
- [ ] AC-3: Endpoint supports pagination via `?page=1&page_size=20` (default page_size=20)
- [ ] AC-4: Endpoint restricted to `IsTrainee` permission with row-level security (trainee sees only their own logs)

### Workout History Screen (AC-5 through AC-10)
- [ ] AC-5: New `/workout-history` route navigates to `WorkoutHistoryScreen`
- [ ] AC-6: Screen shows paginated list of past workouts sorted by date (newest first)
- [ ] AC-7: Each workout card shows: date (e.g., "Mon, Feb 10"), workout name (e.g., "Push Day"), exercise count, total sets, and duration
- [ ] AC-8: Pull-to-refresh reloads the list from page 1
- [ ] AC-9: Scroll to bottom loads next page (infinite scroll pagination)
- [ ] AC-10: Tapping a workout card navigates to workout detail view

### Workout Detail Screen (AC-11 through AC-15)
- [ ] AC-11: New `/workout-detail` route navigates to `WorkoutDetailScreen` (receives DailyLog data as extra)
- [ ] AC-12: Screen shows workout name, date, and duration at the top
- [ ] AC-13: Lists every exercise with: exercise name, and each set showing set number, reps, weight, and unit
- [ ] AC-14: If readiness survey data exists in the log, shows a "Pre-Workout" section with energy, soreness, sleep quality scores
- [ ] AC-15: If post-workout survey data exists, shows "Post-Workout" section with difficulty, energy level, and notes

### Home Screen Integration (AC-16 through AC-19)
- [ ] AC-16: "Recent Workouts" section appears on trainee home screen after "Next Workout" and before "Latest Videos"
- [ ] AC-17: Shows last 3 completed workouts as compact cards (date, workout name, exercise count)
- [ ] AC-18: Tapping a recent workout card navigates to workout detail view
- [ ] AC-19: "See All" button navigates to full workout history screen

### Empty & Error States (AC-20 through AC-22)
- [ ] AC-20: If trainee has no workout history, home section shows "No workouts yet. Complete your first workout to see it here."
- [ ] AC-21: If workout history fails to load, show error with retry button
- [ ] AC-22: Workout detail screen handles missing/malformed workout_data gracefully (shows "No exercise data recorded" instead of crashing)

## Edge Cases
1. Trainee with zero completed workouts → empty state on both home and history screen
2. DailyLog exists but workout_data is null or `{}` → excluded from history
3. DailyLog with workout_data but empty exercises array → excluded from history
4. Very old workouts (months ago) → pagination handles large datasets
5. Rapid scroll → pagination guard prevents duplicate API calls
6. Network failure during pagination → error state with retry, keeps existing loaded items
7. Workout with no readiness survey → "Pre-Workout" section hidden
8. Workout with no post-workout survey → "Post-Workout" section hidden
9. Very long workout name → text truncation with ellipsis
10. Multiple sessions in one day (workout_data.sessions array) → show each session separately or aggregated
11. Pull-to-refresh during active pagination → resets to page 1
12. Trainee completes a workout then navigates to history → new workout appears at top

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network failure on history list | "Unable to load workout history" + retry button | Keeps existing items if any |
| Network failure on home section | Home section hidden or shows "Couldn't load recent workouts" | Doesn't block other sections |
| Empty history | "No workouts yet" message with encouraging copy | Returns empty list |
| Malformed workout_data | "No exercise data recorded" in detail view | Graceful parsing with fallbacks |
| Pagination exhausted | "You've reached the end" footer | Stops requesting more pages |

## UX Requirements
- **Loading state (history):** Shimmer/skeleton cards while loading first page
- **Loading state (pagination):** Small spinner at bottom of list while loading next page
- **Loading state (home):** Shimmer card in recent workouts section
- **Empty state (history):** Centered icon + text + "Start a Workout" CTA button
- **Empty state (home):** Small text "No workouts yet" — no CTA (home already has next workout section)
- **Error state:** Red-tinted card with error icon, message, and "Retry" button
- **Success (detail):** Clean card-based layout with exercise sections, set tables, and survey badges
- **Mobile behavior:** All screens scrollable, responsive to different screen sizes
- **Transitions:** Standard Material page transitions between screens

## Technical Approach

### Backend

**Modify:** `backend/workouts/views.py` — `DailyLogViewSet`
- Add `workout_history` custom action with `@action(detail=False, methods=['get'])`
- Filter: exclude logs where workout_data is null or empty (use `Exclude` with JSONField checks)
- Compute summary fields in a dedicated serializer
- Permission: `IsTrainee`
- Pagination: `PageNumberPagination` with `page_size=20`

**Modify:** `backend/workouts/serializers.py`
- Add `WorkoutHistorySummarySerializer` as a new serializer class
- Fields: `id`, `date`, `workout_name`, `exercise_count`, `total_sets`, `total_volume_lbs`, `duration_display`, `workout_data`
- `workout_name`: extracted from `workout_data.get('workout_name')` or first session name
- `exercise_count`: count of exercises in workout_data
- `total_sets`: sum of all sets across all exercises
- `total_volume_lbs`: sum of (weight * reps) for all completed sets
- `duration_display`: from `workout_data.get('duration')` or computed from timestamps

### Mobile

**Create:** `mobile/lib/features/workout_log/data/models/workout_history_model.dart`
- Freezed model: `WorkoutHistorySummary` with fields matching serializer

**Create:** `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart`
- `WorkoutHistoryNotifier` extends `StateNotifier<WorkoutHistoryState>`
- State: `workouts: List`, `currentPage: int`, `hasMore: bool`, `isLoadingMore: bool`, `error: String?`
- Methods: `loadInitial()`, `loadMore()`, `refresh()`

**Create:** `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`
- `ListView.builder` with `ScrollController` for infinite scroll
- `RefreshIndicator` for pull-to-refresh
- Shimmer loading state for first load
- Workout card widget per item

**Create:** `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`
- Receives workout data as navigation argument
- Sections: Header, Exercise List (card per exercise with sets table), Survey sections
- Read-only view

**Modify:** `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
- Add `getWorkoutHistory({int page, int pageSize})` method
- Add `getRecentWorkouts({int limit})` method (same endpoint, `page_size=3`)

**Modify:** `mobile/lib/core/constants/api_constants.dart`
- Add `workoutHistory` endpoint

**Modify:** `mobile/lib/core/router/app_router.dart`
- Add `/workout-history` route
- Add `/workout-detail` route

**Modify:** `mobile/lib/features/home/presentation/screens/home_screen.dart`
- Add "Recent Workouts" section after "Next Workout"
- Fetch 3 recent workouts in `_loadDashboardData()`

**Modify:** `mobile/lib/features/home/presentation/providers/home_provider.dart`
- Add `recentWorkouts` to dashboard state
- Fetch from workout history endpoint on init

### Files to Create
- `mobile/lib/features/workout_log/data/models/workout_history_model.dart`
- `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`

### Files to Modify
- `backend/workouts/views.py` — Add `workout_history` action
- `backend/workouts/serializers.py` — Add `WorkoutHistorySummarySerializer`
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` — Add history methods
- `mobile/lib/core/constants/api_constants.dart` — Add endpoint
- `mobile/lib/core/router/app_router.dart` — Add 2 routes
- `mobile/lib/features/home/presentation/screens/home_screen.dart` — Add recent workouts section
- `mobile/lib/features/home/presentation/providers/home_provider.dart` — Add recent workouts to state

## Out of Scope
- Workout comparison (this week vs last week) — separate ticket
- Trainer viewing trainee workout history — separate ticket
- Workout streak tracking / badges — separate ticket
- Editing past workouts — read-only view only
- Enhanced calendar with logged-vs-scheduled indicators — separate ticket
- Export/share workout history — separate ticket
- Workout search / filtering by exercise name — separate ticket

# Code Review Round 2: Workout History + Home Screen Recent Workouts

## Review Date
2026-02-14

## Files Reviewed
1. `backend/workouts/serializers.py` — WorkoutHistorySummarySerializer (lines 296-393)
2. `backend/workouts/views.py` — WorkoutHistoryPagination, workout_history action, workout_detail action (lines 348-456)
3. `mobile/lib/core/constants/api_constants.dart` — workoutHistory, workoutHistoryDetail endpoints
4. `mobile/lib/core/router/app_router.dart` — /workout-history and /workout-detail routes with redirect guard
5. `mobile/lib/features/home/presentation/providers/home_provider.dart` — recentWorkouts in HomeState
6. `mobile/lib/features/home/presentation/screens/home_screen.dart` — Recent Workouts section, _RecentWorkoutCard, _buildSectionHeader "See All" change
7. `mobile/lib/features/workout_log/data/models/workout_history_model.dart` — WorkoutHistorySummary model
8. `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` — getWorkoutHistory, getRecentWorkouts, getWorkoutDetail
9. `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart` — WorkoutHistoryNotifier with pagination
10. `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart` — paginated list with shimmer/empty/error states
11. `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart` — detail screen with exercises, surveys

## Round 1 Fix Verification

| Round 1 Issue | Status | Notes |
|---|---|---|
| C1: Unbounded Python-level full-table scan | FIXED | Now uses DB-level JSON filtering with `exclude()`, `has_key`, paginated queryset |
| C2: Re-fetch without deferred nutrition_data | FIXED | `.defer('nutrition_data')` applied on queryset (views.py:422) |
| C3: Unsafe `state.extra` cast crashes on deep link | FIXED | Redirect guard at router line 585-589 checks `is! WorkoutHistorySummary` |
| M1: Refresh race condition with isLoading guard | FIXED | `refresh()` resets to `const WorkoutHistoryState()` then calls `loadInitial()` (provider line 123-127) |
| M2: Dead ternary `(state.hasMore ? 1 : 1)` | FIXED | Simplified to `state.workouts.length + 1` (history_screen line 75) |
| M5: Full workout_data blob in list response | FIXED | `workout_data` removed from `WorkoutHistorySummarySerializer.Meta.fields`; detail screen fetches via separate `workout-detail` endpoint |
| M8: "See All" uses only an icon | FIXED | Now shows "See All" text + arrow_forward_ios icon (home_screen lines 277-291) |

All Round 1 Critical and Major issues have been properly resolved.

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `views.py:409` | **Unused import left behind from Round 1 refactor.** `from django.db.models.functions import JSONObject  # noqa: F401` is imported but never used. The `# noqa` suppresses the linting warning, masking dead code. While not a runtime bug, dead imports with `noqa` silencing violate the project rule "NO exception silencing!" and set a bad precedent. | Remove `from django.db.models.functions import JSONObject  # noqa: F401` entirely. |
| C2 | `views.py:449-453` | **Redundant IDOR check that returns a Response instead of raising an exception.** `self.get_object()` at line 446 already calls `get_queryset()` which filters by `trainee=user` for trainees. If the log doesn't belong to the user, DRF raises `Http404` automatically. The manual `daily_log.trainee != user` check at line 449 is dead code that can never be reached for trainees. More importantly, returning `Response(status=403)` instead of raising `PermissionDenied` bypasses DRF's exception handling, throttling, and logging pipeline. Since this endpoint is `IsTrainee`-only, the ownership check via `get_queryset()` is sufficient. If you want defense-in-depth, raise `PermissionDenied` instead of returning a Response. | Remove the redundant check (lines 449-453) or replace with `raise PermissionDenied('Not authorized to view this log')`. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `home_screen.dart:602-640` | **Home screen cannot distinguish "no workouts" from "API failure" for Recent Workouts section.** If `getRecentWorkouts()` returns `{'success': false}`, the `recentWorkouts` list stays empty in HomeState, and the home screen shows "No workouts yet. Complete your first workout to see it here." This is misleading when the actual problem is a network error. Ticket error states table requires: "Home section hidden or shows 'Couldn't load recent workouts'". | Add a `recentWorkoutsError` field (or nullable `String`) to HomeState. In `home_provider.dart`, when `recentResult['success'] != true`, set an error string. In `_buildRecentWorkoutsSection`, check the error field and show appropriate error copy instead of the empty state. |
| M2 | `views.py:411-420` | **Filter misses edge case: workouts with empty exercises list but other data.** If `workout_data = {"exercises": [], "sessions": [...], "workout_name": "Push Day"}`, the `.exclude(workout_data={'exercises': []})` does an exact JSON equality match, so it does NOT exclude this record (the dict has more keys). The `.filter(has_key='exercises')` passes. Result: the history shows a workout card with `exercise_count=0, total_sets=0, total_volume_lbs=0.0`. This is a confusing zero-data entry. Per the ticket AC-1: endpoint should return only logs "where workout_data contains actual exercise data (not empty exercises list)". | Add an annotation-based filter or post-filter: `.exclude(workout_data__exercises=[])` using Django's JSON path lookup to check that the `exercises` key specifically contains `[]`, regardless of other keys in the dict. Alternatively, use `.annotate()` with `JSONField` lookups. The simplest approach: add `.exclude(workout_data__exercises=[])` which uses the JSON path containment operator. |
| M3 | `workout_detail_screen.dart` (631 lines), `workout_history_screen.dart` (381 lines) | **Both new screen files exceed the 150-line-per-widget-file convention.** CLAUDE.md mandates "Max 150 lines per widget file -- Extract sub-widgets into separate files." The detail screen is 631 lines with `_ExerciseCard`, `_SurveyBadge`, `_HeaderStat` etc. all in one file. The history screen is 381 lines with `_WorkoutHistoryCard`, `_StatChip`. | Extract `_ExerciseCard` and `_SurveyBadge` (and `_HeaderStat`) into `workout_detail_widgets.dart`. Extract `_WorkoutHistoryCard` and `_StatChip` into `workout_history_widgets.dart`. The main screen files should only contain the screen widget and its state. |
| M4 | `home_screen.dart:64` | **"See All" label now shows on "Current Program" section header.** The `_buildSectionHeader` change (replacing the icon with "See All" text) is a global change. "Current Program" has `showAction: true` and navigates to `/logbook`. Showing "See All" next to "Current Program" is misleading -- the logbook isn't a "see all programs" screen. The change was meant to fix M8 (See All for Recent Workouts) but regressed the existing "Current Program" header. | Either: (1) Add a `actionLabel` parameter to `_buildSectionHeader` so callers can specify the label text (e.g., "See All" vs "View"), or (2) revert the "Current Program" section to use a different label/icon. |
| M5 | `serializers.py:296-393`, `views.py:455` | **`workout_detail` endpoint returns `DailyLogSerializer` which exposes `trainee` (user ID), `trainee_email`, and `nutrition_data` to the mobile client.** The mobile detail screen only needs `workout_data`, `date`, and survey info. Returning the trainee's email address and full nutrition data is unnecessary data exposure. Per security best practice and the CLAUDE.md rules, API responses should not leak fields the client doesn't need. | Create a `WorkoutDetailSerializer` that only includes `id`, `date`, `workout_data`, `notes` -- the fields the detail screen actually uses. Or use `DailyLogSerializer` with a restricted `fields` list for this endpoint. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `workout_history_provider.dart:117` | `loadMore()` silently swallows errors with `catch (_)`. User gets no feedback when pagination fails. (Carried over from Round 1.) | Set an error in state or at minimum log the exception. The UI should show a "tap to retry" footer instead of just stopping the spinner. |
| m2 | `workout_detail_screen.dart:434,435,436,608` | Hardcoded colors (`Color(0xFF22C55E)`, `Color(0xFFF59E0B)`, `Color(0xFFEF4444)`) outside theme. Violates "Centralized theme — Never hardcode colors/fonts" convention. (Carried over from Round 1.) | Define these as theme extension colors or at minimum as constants in the theme file. |
| m3 | `workout_history_model.dart:49-61` | `formattedVolume` getter is defined but never called anywhere in the codebase. Dead code. | Remove it, or use it somewhere (e.g., in the workout history card to show total volume). |
| m4 | `home_screen.dart:607-629` | Home screen shimmer loading placeholder is a single static container. Not animated. Ticket UX requirements say "Shimmer card in recent workouts section." A static colored box is not a shimmer. | Either use the `shimmer` package for animation, or rename the comment to "loading placeholder" for accuracy. |
| m5 | `workout_detail_screen.dart:32-50` | Detail screen creates its own `WorkoutRepository` instance directly with `ref.read(apiClientProvider)` instead of going through a provider. This breaks the Repository pattern (Screen -> Provider -> Repository -> ApiClient). | Create a `workoutDetailProvider` (FutureProvider.family) that accepts a log ID, fetches via repository, and returns the data. The screen watches the provider. |
| m6 | `workout_history_provider.dart:63`, `101` | `result['results'] as List<dynamic>` -- direct cast without null check. If the API response is malformed and `results` key is missing, this throws a `TypeError` instead of gracefully handling it. The `?? []` fallback is only on the home_provider (line 214), not here. | Use `result['results'] as List<dynamic>? ?? []` for safety. |
| m7 | `views.py:408-409` | `from django.db.models import Q` is imported inside the method body. Q is commonly used and should be a top-level import. | Move `from django.db.models import Q` to the top of the file alongside other Django imports. |

## Security Concerns

1. **Data over-exposure in workout_detail (M5):** The `DailyLogSerializer` returns `trainee` (user ID integer), `trainee_email`, and `nutrition_data`. While the endpoint is protected by `IsTrainee` permission and row-level security, exposing the trainee's email in the API response is unnecessary. The mobile client doesn't use these fields. This is a violation of the principle of least privilege for data exposure.

2. **Row-level security is properly enforced:** `workout_history` filters by `trainee=user`. `workout_detail` uses `self.get_object()` which goes through `get_queryset()` (trainee sees own logs only). Auth is enforced via `IsTrainee` permission class. No IDOR vulnerability found.

3. **No secrets or tokens in code.** No injection vectors. Inputs are paginated integers only.

## Performance Concerns

1. **DB-level filtering is now correct.** The Round 1 Python-level full-table scan was replaced with proper queryset filtering. `nutrition_data` is deferred. The `has_key` lookup uses PostgreSQL's `?` operator which is index-friendly.

2. **No N+1 queries.** The summary serializer uses `SerializerMethodField` reading from already-loaded `workout_data` JSON -- no additional queries per item.

3. **Pagination is properly bounded.** `max_page_size=50` prevents abuse.

4. **Minor concern:** The `_get_exercises_list()` helper in the serializer is called multiple times per object (once each for `get_exercise_count`, `get_total_sets`, `get_total_volume_lbs`). For 20 items, this means parsing the JSON exercises array 60 times. Not a real problem at this scale, but could be cached with `@lru_cache` or a single-pass computation.

## Acceptance Criteria Check

| Criterion | Status | Notes |
|---|---|---|
| AC-1: workout-history endpoint filters properly | PARTIAL | Works for most cases, but M2 edge case (empty exercises + other keys) leaks through |
| AC-2: Computed summary fields | PASS | workout_name, exercise_count, total_sets, total_volume_lbs, duration_display all computed |
| AC-3: Pagination support | PASS | PageNumberPagination with page_size=20, page_size_query_param, max=50 |
| AC-4: IsTrainee + row-level security | PASS | Proper permission class, filters by trainee=user |
| AC-5: /workout-history route | PASS | Route defined in app_router.dart |
| AC-6: Paginated list sorted by date | PASS | order_by('-date'), infinite scroll with loadMore() |
| AC-7: Workout card shows date, name, exercises, sets, duration | PASS | All fields displayed in _WorkoutHistoryCard |
| AC-8: Pull-to-refresh | PASS | RefreshIndicator + refresh() method with proper state reset |
| AC-9: Infinite scroll pagination | PASS | ScrollController triggers loadMore() at 200px from bottom |
| AC-10: Tap navigates to detail | PASS | context.push('/workout-detail', extra: workout) |
| AC-11: /workout-detail route | PASS | Route with redirect guard for null/invalid extra |
| AC-12: Detail header with name, date, duration | PASS | _buildHeader widget shows all three |
| AC-13: Exercise list with sets table | PASS | _ExerciseCard with set number, reps, weight, unit |
| AC-14: Pre-workout survey section | PASS | Conditional readiness survey display with score badges |
| AC-15: Post-workout survey section | PASS | Conditional post-survey display with notes |
| AC-16: Recent Workouts section on home | PASS | After Next Workout, before Latest Videos |
| AC-17: Last 3 compact cards | PASS | getRecentWorkouts(limit: 3), _RecentWorkoutCard |
| AC-18: Tap recent workout navigates to detail | PASS | context.push('/workout-detail', extra: workout) |
| AC-19: "See All" navigates to history | PASS | _buildSectionHeader with showAction navigates to /workout-history |
| AC-20: Empty state message | PASS | Both home and history show appropriate empty messages |
| AC-21: Error with retry button | PARTIAL | History screen has error+retry. Home screen cannot distinguish error from empty (M1) |
| AC-22: Graceful malformed data handling | PASS | _buildNoExercisesCard, safe JSON parsing throughout |

## Quality Score: 7/10

Round 1 Criticals and Majors were all fixed correctly. The implementation is substantially improved. The new issues found are less severe: the most impactful ones are the home screen's inability to distinguish API failure from empty state (M1), the filter edge case for empty exercises arrays (M2), and the data over-exposure in workout_detail (M5). The widget file length violations (M3) and the regression in the section header label (M4) are real but lower-risk.

## Recommendation: REQUEST CHANGES

The implementation is close to shippable. The remaining Majors are:
- **M1** (home error vs empty state confusion) — user-facing confusion
- **M2** (filter edge case) — data quality issue
- **M3** (150-line convention violation) — code quality
- **M4** (section header label regression) — UX regression
- **M5** (data over-exposure) — security hygiene

M3 and M4 are quick fixes. M1 and M2 require slightly more thought but are bounded. M5 is a new serializer. One more round of fixes should get this to APPROVE.

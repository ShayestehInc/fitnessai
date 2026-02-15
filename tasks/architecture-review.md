# Architecture Review: Pipeline 8 -- Trainee Workout History + Home Screen Recent Workouts

## Review Date
2026-02-14

## Files Reviewed

### Backend
- `backend/workouts/views.py` (DailyLogViewSet: `workout_history` and `workout_detail` actions)
- `backend/workouts/serializers.py` (`WorkoutHistorySummarySerializer`, `WorkoutDetailSerializer`)
- `backend/workouts/services/daily_log_service.py` (`get_workout_history_queryset`)
- `backend/workouts/models.py` (DailyLog schema review)
- `backend/workouts/tests/test_workout_history.py` (48 tests)

### Mobile
- `mobile/lib/features/workout_log/data/models/workout_history_model.dart` (NEW)
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` (MODIFIED)
- `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart` (NEW)
- `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart` (NEW)
- `mobile/lib/features/workout_log/presentation/screens/workout_history_widgets.dart` (NEW)
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart` (NEW)
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_widgets.dart` (NEW)
- `mobile/lib/features/home/presentation/providers/home_provider.dart` (MODIFIED)
- `mobile/lib/features/home/presentation/screens/home_screen.dart` (MODIFIED)
- `mobile/lib/core/constants/api_constants.dart` (MODIFIED)
- `mobile/lib/core/router/app_router.dart` (MODIFIED)

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (FIXED -- see below)
- [x] Consistent with existing patterns

### Issues Found and Fixed

**Issue 1 (FIXED): Queryset business logic was inline in the view.**

The `workout_history` action in `DailyLogViewSet` contained a complex queryset construction with 5 chained ORM calls including `Q` objects, `exclude`, `filter`, and `defer`. Per project conventions (`CLAUDE.md`: "Business logic in `services/`"), this belongs in the service layer.

**Fix applied:** Extracted `get_workout_history_queryset(trainee_id: int)` into `DailyLogService` in `backend/workouts/services/daily_log_service.py`. The view now calls `DailyLogService.get_workout_history_queryset(user.id)` -- a single line. This matches the pattern already established by `DailyLogService.get_weekly_progress()`.

**Issue 2 (FIXED): JSON extraction logic mixed into UI widget.**

`WorkoutDetailScreen` contained three private methods (`_extractExercises`, `_extractReadinessSurvey`, `_extractPostSurvey`) totaling ~50 lines of JSON-shape-aware parsing. This is data layer logic, not presentation logic.

**Fix applied:** Created `WorkoutDetailData` class in `workout_history_model.dart` with a `fromWorkoutData` factory constructor. The extraction methods are now static methods of this data class. The detail screen simply calls `WorkoutDetailData.fromWorkoutData(data)` and reads `.exercises`, `.readinessSurvey`, `.postSurvey`. This makes the extraction logic reusable and testable outside of Flutter widget tests.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes -- reads existing `DailyLog` table |
| Migrations needed | N/A | No migrations -- pure read endpoint |
| Indexes for new queries | PASS | Existing `['trainee', 'date']` composite index and `['date']` index cover the `filter(trainee_id=...).order_by('-date')` query path |
| No N+1 query patterns | PASS | Single queryset with `.defer('nutrition_data')` |

**Notes on index coverage:**

The `workout_history` query filters on `trainee_id` and orders by `-date`. The existing composite index `['trainee', 'date']` on `daily_logs` table handles this optimally. The JSON field lookups (`workout_data__has_key`, `workout_data__exercises`) operate on the pre-filtered set, which is small per-trainee. No additional GIN index on `workout_data` is needed at current scale.

---

## API Design

| Endpoint | Method | RESTful? | Pagination? | Auth? | Notes |
|----------|--------|----------|-------------|-------|-------|
| `/api/workouts/daily-logs/workout-history/` | GET | YES (custom action on DailyLog) | YES (`PageNumberPagination`, default 20, max 50) | `IsTrainee` | Correct |
| `/api/workouts/daily-logs/{id}/workout-detail/` | GET | YES (detail action) | N/A (single object) | `IsTrainee` | Correct |

**Strengths:**
- Pagination uses standard DRF `PageNumberPagination` with configurable `page_size` and sensible `max_page_size=50`
- Response format follows DRF standard: `{count, next, previous, results}`
- `workout_detail` returns restricted fields only (id, date, workout_data, notes) -- no `nutrition_data` or `trainee` email leakage
- Row-level security: `workout_history` filters by `trainee=user`; `workout_detail` inherits from `DailyLogViewSet.get_queryset()` which filters by role

**Consistency with existing endpoints:**
- Matches `workout-summary/`, `weekly-progress/`, `nutrition-summary/` pattern of custom actions on `DailyLogViewSet`
- Uses same permission class (`IsTrainee`) as survey endpoints

---

## Frontend Patterns

### State Management

| Pattern | Status | Notes |
|---------|--------|-------|
| Riverpod StateNotifier | PASS | `WorkoutHistoryNotifier` and `HomeNotifier` both use `StateNotifier` |
| Provider definition | PASS | `workoutHistoryProvider` follows same pattern as `homeStateProvider` |
| Repository pattern | PASS | Both `getWorkoutHistory()` and `getRecentWorkouts()` go through `WorkoutRepository` |
| API constants centralized | PASS | `ApiConstants.workoutHistory` and `ApiConstants.workoutHistoryDetail()` defined |

### Widget Decomposition

| File | Lines | Compliant? | Notes |
|------|-------|------------|-------|
| `workout_history_screen.dart` | 267 | WARN | Exceeds 150-line limit but all methods are build helpers, not business logic |
| `workout_detail_screen.dart` | 440 | WARN | Exceeds 150-line limit; survey section + shimmer + error state inflate it. Would benefit from further extraction. |
| `workout_history_widgets.dart` | 119 | PASS | `WorkoutHistoryCard` and `StatChip` extracted properly |
| `workout_detail_widgets.dart` | 261 | PASS | `ExerciseCard`, `SurveyBadge`, `HeaderStat`, `SurveyField` extracted |
| `home_screen.dart` (additions) | ~75 new lines | PASS | `_RecentWorkoutCard` is a private widget class at bottom of file |

**Assessment:** The widget extraction pattern is good -- reusable pieces are in `*_widgets.dart` files. The screen files themselves exceed 150 lines due to multiple state-dependent build methods (loading, error, empty, populated), which is acceptable for screen-level files that orchestrate states. The alternative (splitting each state into a separate widget file) would add complexity without improving readability.

### Navigation

The `workout-detail` route uses `state.extra` to pass `WorkoutHistorySummary` data. This is correct for go_router. The route includes a redirect guard that sends users to `/workout-history` if `extra` is not a `WorkoutHistorySummary`, preventing crashes from direct URL access.

---

## Scalability Concerns

| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | N+1 queries | PASS | Single queryset, no related model joins needed |
| 2 | Unbounded fetches | PASS | Paginated with max 50 per page |
| 3 | Large JSON blobs | PASS | `.defer('nutrition_data')` avoids fetching unnecessary large field |
| 4 | Serializer computation | MINOR | Summary fields computed in Python per-row (not DB aggregation). Acceptable for paginated sets of 20-50 items. At extreme scale, these could be precomputed. |
| 5 | Home screen parallel fetch | PASS | `getRecentWorkouts(limit: 3)` runs in parallel with other `Future.wait` calls, not sequentially |
| 6 | Infinite scroll guard | PASS | Provider checks `isLoadingMore`, `hasMore`, and `isLoading` before firing |

**Note on concern #4:** The `WorkoutHistorySummarySerializer` computes `exercise_count`, `total_sets`, `total_volume_lbs`, and `duration_display` by iterating through the `workout_data` JSON in Python. For the typical paginated response of 20 items, each with 5-10 exercises and 15-30 sets, this is negligible. If history grows to thousands of entries per trainee with large workout_data blobs, pre-materializing these summary fields into a `WorkoutSummaryCache` table would be the right optimization. Not needed now.

---

## Technical Debt

### Debt Introduced

| # | Description | Severity | Notes |
|---|-------------|----------|-------|
| 1 | `WorkoutRepository` returns `Map<String, dynamic>` | LOW | Pre-existing pattern. Project rules say "return dataclass or pydantic models, never return dict." The `getWorkoutHistory()` and `getWorkoutDetail()` methods follow the same `Map<String, dynamic>` return pattern as every other method in the repository. Fixing this would require refactoring the entire repository, which is out of scope. |
| 2 | `WorkoutDetailScreen` uses `setState` for fetch state | LOW | The screen uses `setState` for `_isLoading`, `_error`, and `_workoutData`. Per conventions, Riverpod should manage this. However, the data is ephemeral to this screen and loaded once. A provider would add complexity. This is the pragmatic choice. |

### Debt Reduced

| # | Description | Impact |
|---|-------------|--------|
| 1 | JSON extraction logic moved to data layer | Extraction logic is now reusable, testable, and separated from UI |
| 2 | Queryset construction moved to service layer | View is now thin; query logic is centralized and testable |

---

## Serializer Design

The `WorkoutHistorySummarySerializer` is a `ModelSerializer` with `SerializerMethodField` for computed fields. This is the standard DRF approach for derived data.

The `WorkoutDetailSerializer` is a minimal `ModelSerializer` that exposes only `[id, date, workout_data, notes]`. This is a good security practice -- it prevents accidental exposure of `trainee`, `nutrition_data`, or other sensitive fields through the detail endpoint.

Both serializers are properly typed with `serializers.ModelSerializer[DailyLog]`.

---

## Test Coverage

48 tests across 6 test classes covering:
- Filtering (7 tests): null, empty, exercises-only, sessions-only, mixed
- Summary fields (12 tests): workout_name extraction, exercise_count, total_sets, volume calculation, duration
- Pagination (9 tests): page size, max cap, ordering, metadata, empty results
- Security (5 tests): own-logs-only, trainer forbidden, admin forbidden, unauthenticated, cross-trainee
- Detail (8 tests): restricted fields, no leaks, notes, 404 for other user, 403 for trainer
- Edge cases (7 tests): missing sets, non-list sets, non-numeric weight, non-dict items, rounding

**Assessment:** Excellent coverage. Tests verify both positive paths and adversarial inputs. Security tests are thorough.

---

## Architecture Score: 9/10

**Deductions:**
- -0.5: `workout_detail_screen.dart` at 440 lines still exceeds the 150-line widget convention, though it has been improved by extracting business logic to the data layer
- -0.5: Pre-existing `Map<String, dynamic>` return pattern in `WorkoutRepository` not addressed (out of scope but worth noting)

## Recommendation: APPROVE

---

## Summary

Pipeline 8 implements a clean, well-structured feature that follows established patterns. The backend adds two read-only endpoints with proper pagination, security, and computed summary fields. The mobile side adds a paginated history screen, detail screen, and home screen integration following Riverpod/go_router conventions.

Two architectural fixes were applied during this review:
1. Queryset construction extracted from view to `DailyLogService.get_workout_history_queryset()`
2. JSON extraction logic extracted from `WorkoutDetailScreen` widget to `WorkoutDetailData` data class

All 48 backend tests pass after the refactoring. Flutter analyze shows 0 new issues.

## Changes Made by Architect

### Backend
- **`backend/workouts/services/daily_log_service.py`**: Added `get_workout_history_queryset()` static method with the filtered/ordered queryset logic
- **`backend/workouts/views.py`**: Replaced inline queryset construction with service call; added `DailyLogService` import; removed unused `Q` import

### Mobile
- **`mobile/lib/features/workout_log/data/models/workout_history_model.dart`**: Added `WorkoutDetailData` class with `fromWorkoutData()` factory and static extraction methods; added `formattedVolume` getter to `WorkoutHistorySummary`
- **`mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`**: Replaced inline `_extractExercises`, `_extractReadinessSurvey`, `_extractPostSurvey` with `WorkoutDetailData.fromWorkoutData()` call

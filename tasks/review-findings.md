# Code Review: Workout History + Home Screen Recent Workouts

## Review Date
2026-02-14

## Files Reviewed
1. `backend/workouts/serializers.py` — WorkoutHistorySummarySerializer
2. `backend/workouts/views.py` — WorkoutHistoryPagination, workout_history action
3. `mobile/lib/features/workout_log/data/models/workout_history_model.dart`
4. `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart`
5. `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`
6. `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`
7. `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
8. `mobile/lib/core/constants/api_constants.dart`
9. `mobile/lib/core/router/app_router.dart`
10. `mobile/lib/features/home/presentation/providers/home_provider.dart`
11. `mobile/lib/features/home/presentation/screens/home_screen.dart`

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | views.py:416-427 | Unbounded Python-level full-table scan for filtering. Loads ALL DailyLogs into memory for Python check. O(n) in total logs per user. | Replace with DB-level JSON filtering or consolidate to single query with annotate. |
| C2 | views.py:429-431 | Second query re-fetches all fields including large nutrition_data blob. | Add `.defer('nutrition_data')` on the filtered queryset. |
| C3 | app_router.dart:586 | Unsafe `state.extra as WorkoutHistorySummary` cast crashes on deep link or null extra. | Add null check with redirect fallback. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | workout_history_provider.dart:120-126 | Race condition: refresh() sets isLoading=true then calls loadInitial() which early-returns on isLoading. Pull-to-refresh is broken. | Reset state without isLoading, let loadInitial set it. |
| M2 | workout_history_screen.dart:75 | Dead ternary `(state.hasMore ? 1 : 1)` — always evaluates to 1. | Simplify to `state.workouts.length + 1`. |
| M5 | serializers.py:313 | Full workout_data blob in list response. Could be megabytes for 20 items. | Remove workout_data from list serializer, add separate detail fetch. |
| M8 | home_screen.dart:78 | "See All" uses only an icon, no text label. Ticket says "See All button". | Add text label or tooltip. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | workout_history_provider.dart:117 | loadMore silently swallows errors. | Log error or show feedback. |
| m3 | workout_history_screen.dart:113 | "Shimmer" loading isn't animated. | Rename to loading placeholder or add animation. |
| m5 | workout_detail_screen.dart:357 | Hardcoded colors outside theme. | Use theme colors. |

## Quality Score: 6/10
## Recommendation: REQUEST CHANGES

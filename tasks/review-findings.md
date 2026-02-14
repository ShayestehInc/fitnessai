# Code Review: Trainee Home Experience + Password Reset

## Review Date
2026-02-14

## Files Reviewed
1. `backend/config/settings.py` -- Email config, Djoser domain/site
2. `backend/workouts/views.py` -- Weekly progress endpoint, food edit/delete actions
3. `mobile/lib/core/constants/api_constants.dart` -- New endpoints
4. `mobile/lib/core/router/app_router.dart` -- New routes, redirect guard
5. `mobile/lib/features/auth/data/repositories/auth_repository.dart` -- Password reset methods
6. `mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart` -- New file
7. `mobile/lib/features/auth/presentation/screens/reset_password_screen.dart` -- New file
8. `mobile/lib/features/auth/presentation/screens/login_screen.dart` -- Forgot password wiring
9. `mobile/lib/features/home/presentation/providers/home_provider.dart` -- Weekly progress
10. `mobile/lib/features/home/presentation/screens/home_screen.dart` -- Progress bar, notification fix
11. `mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart` -- Edit/delete/weekly methods
12. `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` -- Wire food edit/delete
13. `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart` -- getDailyLogId method
14. `mobile/lib/features/nutrition/presentation/widgets/edit_food_entry_sheet.dart` -- New file

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `backend/workouts/views.py:870-872` | **Arbitrary key injection in edit_meal_entry.** `entry_data` from `request.data.get('data')` is merged directly into the existing meal entry via `existing_entry.update(entry_data)` with no key whitelist. An attacker can inject arbitrary keys into the `nutrition_data` JSON (e.g., `{"__class__": "...", "admin": true, "garbage": "x" * 1000000}`), causing data corruption, storage bloat, or downstream parsing failures on the mobile client. | Add a whitelist: `allowed = {'name', 'protein', 'carbs', 'fat', 'calories', 'timestamp'}` and strip unrecognized keys from `entry_data` before merging: `entry_data = {k: v for k, v in entry_data.items() if k in allowed}`. |
| C2 | `backend/workouts/views.py:883-929` | **DELETE endpoint with request body.** The `delete_meal_entry` action uses `methods=['delete']` and reads `meal_index`/`entry_index` from `request.data` (the request body). RFC 7231 states a DELETE request body has no defined semantics. Many HTTP intermediaries (proxies, CDNs, load balancers) strip bodies from DELETE requests. Dio on Flutter also does not reliably send body data with DELETE on all platforms. This will silently fail in production environments with reverse proxies. | Change to `methods=['post']` with a descriptive url_path like `'delete-meal-entry'`. The mobile already sends data in the body, so just changing the HTTP method is sufficient. Update the mobile ApiConstants and repository to use `dio.post()` instead of `dio.delete()`. |
| C3 | `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart:628-629` + `backend/workouts/views.py:353-377` | **getDailyLogForDate will return the WRONG log.** The mobile client calls `getDailyLogForDate(date)` which issues `GET /api/workouts/daily-logs/?date=<date>`. However, `DailyLogViewSet.get_queryset()` has NO date filtering -- there is no `filterset_fields`, no `filter_backends`, and no manual query param handling for `date`. The `?date=` parameter is silently ignored. The endpoint returns ALL daily logs for the user (page 1 of paginated results). `results.first` grabs the most recent log by default ordering, NOT the log for the requested date. Every food edit and delete operation will modify the wrong DailyLog record, corrupting user data. | Add date filtering to `DailyLogViewSet`. Either: (a) add `filterset_fields = ['date', 'trainee']` and `filter_backends = [DjangoFilterBackend]` (requires `django-filter` in requirements), or (b) add manual filtering in `get_queryset()`: `date = self.request.query_params.get('date'); if date: queryset = queryset.filter(date=date)`. Option (b) is simpler and doesn't require a new dependency. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `backend/workouts/views.py:829-852` | **`meal_index` parameter is required but completely ignored.** Line 833 returns 400 if `meal_index` is None, but line 852 sets `target_index = entry_index`, completely ignoring `meal_index`. This creates a false API contract. Same issue in `delete_meal_entry` (line 914). Consumers will think `meal_index` matters when it doesn't. | Either implement proper meal_index + entry_index addressing, or remove `meal_index` from the required parameters and document that `entry_index` is a flat index into the meals array. The mobile client always sends `meal_index: 0`, so removing the requirement is safe. |
| M2 | `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart:638-651` | **NutritionRepository instantiated manually instead of using provider.** `NutritionRepository(ref.read(apiClientProvider))` creates a new instance on every edit/delete call. This bypasses the existing `nutritionRepositoryProvider` and breaks the repository pattern. | Replace with `ref.read(nutritionRepositoryProvider)` on both lines 639 and 683. |
| M3 | `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart:610-668` | **Race condition: no UI locking during edit/delete operations.** Between `getDailyLogId` and `editMealEntry`/`deleteMealEntry`, another edit or delete could complete and shift all indices, causing the wrong entry to be modified. The user can also tap edit on multiple entries simultaneously. | Add a loading state that disables the edit icons while an operation is in flight. E.g., add `bool _isEditing = false` to `_NutritionScreenState`, set it true before the operation and false after, and pass it to `_MealSection` to disable the edit taps. |
| M4 | `mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart:16-17` + `reset_password_screen.dart:27-28` | **Uses `setState` for `_isLoading`/`_emailSent`/`_resetSuccess` instead of Riverpod.** CLAUDE.md convention: "Riverpod exclusively -- No setState for anything beyond ephemeral animation state." Loading and success states are business logic state, not animation. | Move these states into a Riverpod StateNotifier or AsyncNotifier. Create `ForgotPasswordState` and `ResetPasswordState` classes with corresponding notifiers. |
| M5 | `mobile/lib/features/auth/presentation/screens/reset_password_screen.dart:283-287` | **Missing `const` constructor on Icon widgets.** `Icon(Icons.check_circle_outline, size: 80, color: Colors.green)` is not const. Same issue at line 96-99. CLAUDE.md: "const constructors everywhere -- Performance requirement." | Add `const` keyword: `const Icon(Icons.check_circle_outline, size: 80, color: Colors.green)`. |
| M6 | `mobile/lib/features/home/presentation/providers/home_provider.dart:171` | **Weekly progress fetched from NutritionRepository -- wrong domain.** `_nutritionRepo.getWeeklyProgress()` is called for a workout endpoint. This breaks single-responsibility: nutrition repo should not know about workout progress. The `getWeeklyProgress()` method was added to `NutritionRepository` at line 224 of `nutrition_repository.dart`. | Move `getWeeklyProgress()` to `WorkoutRepository` and call it from there. In `HomeNotifier`, change `_nutritionRepo.getWeeklyProgress()` to `_workoutRepo.getWeeklyProgress()`. |
| M7 | `backend/workouts/views.py:746-754` | **Missing database index on DailyLog (trainee, date).** The weekly_progress query does `DailyLog.objects.filter(trainee=user, date__range=(...))`. Without a composite index, every home screen load by every trainee does a full table scan. This will degrade as the table grows. | Add to DailyLog model: `class Meta: indexes = [models.Index(fields=['trainee', 'date'])]`. Create and run the migration. |
| M8 | `mobile/lib/features/home/presentation/providers/home_provider.dart:273-277` | **TODO comments left in production code.** Lines 273 and 277 contain `// TODO: Track actual workout completion` and `// TODO: Get from actual completion data`. CLAUDE.md: "Allergic to TODOs. Don't leave them. If something needs doing, do it now." These TODOs also mean the local `programProgress` always shows 0%, creating a confusing UX alongside the new API-driven weekly progress that shows real data. | Remove the TODOs. Since the `weeklyProgress` API now provides real completion data, either use it for the program progress too, or remove the separate `programProgress` field entirely. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `forgot_password_screen.dart:149` | **Weak email validation.** `!value.contains('@')` accepts strings like `@`, `@@`, `foo@` as valid emails. | Use `RegExp(r'^[^@]+@[^@]+\.[^@]+$')` or similar. Same issue exists in login_screen.dart:438. |
| m2 | `backend/workouts/views.py:860-867` | **Inconsistent numeric type handling.** Backend accepts both `int` and `float` for macro fields, but mobile `MealEntry` uses `int.tryParse()`. A float like `50.5` would be stored but displayed as `50` on mobile. | Decide on int-only and enforce: `isinstance(value, int) or (isinstance(value, float) and value == int(value))`, or accept floats on both sides. |
| m3 | `nutrition_screen.dart:583` | **Fragile meal matching.** `meals[i].name.toLowerCase().contains('meal $mealNumber')` matches "meal 1" inside "meal 10", "meal 11", etc. An entry named "Meal 10 - Rice" will incorrectly match meal 1. | Use regex with word boundary: `RegExp(r'meal ' + mealNumber.toString() + r'(\s|$|-)', caseSensitive: false)`. |
| m4 | `auth_repository.dart:324-326` | **Dead code in requestPasswordReset catch block.** Dio does not throw for 204 status codes; they're treated as successful responses. The check `if (e.response?.statusCode == 204 ...)` in the DioException catch is unreachable. | Remove the 204 check from the catch block. |
| m5 | `home_screen.dart:54-55` | **Force-unwrap after null check.** `homeState.weeklyProgress != null && homeState.weeklyProgress!.hasProgram` uses `!` which is fragile. | Use pattern matching: `if (homeState.weeklyProgress case final progress? when progress.hasProgram)` or store in a local variable. |
| m6 | `backend/config/settings.py:235` | **Password reset link points to web URL that doesn't exist.** `PASSWORD_RESET_CONFIRM_URL` generates links to `localhost:3000/reset-password/{uid}/{token}`, but this is a mobile-first app with no web frontend. The email link will 404. The ticket notes this is "Out of Scope", but the default domain should at least be documented. | Add a comment in settings explaining this limitation, or create a minimal web page that redirects to the app's deep link. |
| m7 | `nutrition_screen.dart:659` | **Full data reload after edit/delete is wasteful.** After each edit/delete, `loadInitialData()` refetches 5 API endpoints (goals, summary, weight check-in, profile, presets) when only the nutrition summary changed. | Call `refreshDailySummary()` instead of `loadInitialData()` after edit/delete. |
| m8 | `backend/workouts/views.py:709-710` | **Redundant permission class.** `permission_classes=[IsAuthenticated, IsTrainee]` -- `IsTrainee` already checks `is_authenticated` (core/permissions.py:23-27). | Simplify to `permission_classes=[IsTrainee]`. Same at lines 807 and 884. |

## Security Concerns

1. **Arbitrary key injection via edit_meal_entry (C1):** An authenticated trainee can inject any key-value pair into their meal entries. While this primarily affects their own data, it could be used to: (a) bloat the database by injecting large values, (b) confuse downstream consumers that parse nutrition_data, (c) inject XSS payloads into meal names that might be rendered in a web admin dashboard later. Fix: whitelist allowed keys.

2. **No dedicated rate limit on password reset endpoint:** The global `anon: 30/minute` throttle provides some protection, but an attacker can still send 30 password reset emails per minute to flood a user's inbox. Consider adding a `password-reset: 3/hour` throttle class for the Djoser reset endpoint.

3. **TOCTOU race in index-based meal editing:** The meal_index/entry_index addressing scheme is inherently racy. Between reading the current state and sending the edit, another request can shift indices. Low risk for single-device mobile clients, but exploitable via concurrent API calls. Consider using a meal entry ID instead of positional index for a more robust solution.

## Performance Concerns

1. **Missing composite index on DailyLog (trainee, date) (M7):** Every trainee home screen load triggers a query filtered on `trainee` + `date__range`. Without an index, this becomes O(n) as the table grows. With 1000 trainees loading home screens, this is a significant concern.

2. **Full data reload after food edit/delete (m7):** 5 parallel API calls when only 1 is needed. This wastes bandwidth and server resources on every food edit.

3. **Two separate progress calculations:** The home screen now shows both `programProgress` (always 0%, computed locally) and `weeklyProgress` (from API). This is confusing and wasteful.

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | Email backend configured with console for dev, SMTP for prod via env vars |
| AC-2 | PASS | DJOSER DOMAIN and SITE_NAME configured with env var overrides |
| AC-3 | PASS | Uses Djoser's built-in endpoint, 204 regardless of email existence |
| AC-4 | PASS | "Forgot password?" button navigates to ForgotPasswordScreen |
| AC-5 | PASS | Success confirmation screen: "Check your email" with "Back to Login" |
| AC-6 | PASS | Uses Djoser's built-in reset_password_confirm |
| AC-7 | PASS | ResetPasswordScreen accepts uid/token via route params |
| AC-8 | PASS (path differs) | Endpoint at `/daily-logs/weekly-progress/` not `/weekly-progress/` per ticket |
| AC-9 | PASS | Queries non-empty workout_data with proper excludes |
| AC-10 | PARTIAL | Progress bar uses API data correctly, BUT `programProgress` still shows hardcoded 0% in a separate section (confusing dual progress display) |
| AC-11 | PASS | Pull-to-refresh calls loadDashboardData which fetches weekly progress |
| AC-12 | PASS | Edit bottom sheet opens with pre-filled fields |
| AC-13 | **FAIL** | Will modify wrong DailyLog due to C3 (no date filter on list endpoint) |
| AC-14 | **FAIL** | Same as AC-13 -- delete from wrong DailyLog |
| AC-15 | PASS (backend) | Backend recalculates totals; frontend reloads data |
| AC-16 | INTENTIONAL SKIP | Dev deviated -- no optimistic UI, uses loading + refresh instead (documented) |
| AC-17 | PASS | Notification button shows info dialog instead of being dead |

## Quality Score: 5/10

The implementation covers all four user stories structurally and demonstrates good understanding of the codebase patterns. Password reset flow is clean and well-implemented. Home screen weekly progress section is well-designed with proper animation and empty/zero states. The edit food entry bottom sheet is polished.

However, three critical bugs will cause data corruption in production: (1) arbitrary key injection into nutrition data, (2) DELETE with body that will fail behind proxies, and (3) food edit/delete operating on the wrong DailyLog because the date filter query param is silently ignored. These must be fixed before merge.

## Recommendation: REQUEST CHANGES

**Must fix before merge:** C1, C2, C3 (data corruption and silent failures in production).

**Should fix:** M1-M8 (API contract confusion, convention violations, performance issues, domain boundary violations, TODO comments).

**Nice to fix:** m1-m8 (weak validation, dead code, fragile matching, minor optimizations).

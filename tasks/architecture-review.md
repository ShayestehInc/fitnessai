# Architecture Review: Health Data Integration + Performance Audit + Offline UI Polish

## Review Date: 2026-02-15 (Pipeline 16)

## Files Reviewed

### New Files
- `mobile/lib/core/models/health_metrics.dart`
- `mobile/lib/core/providers/health_provider.dart`
- `mobile/lib/shared/widgets/health_card.dart`
- `mobile/lib/shared/widgets/health_permission_sheet.dart`

### Modified Files
- `mobile/lib/core/services/health_service.dart`
- `mobile/lib/features/home/presentation/screens/home_screen.dart`
- `mobile/lib/features/home/presentation/providers/home_provider.dart`
- `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`
- `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart`
- `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart`
- `mobile/lib/core/database/daos/workout_cache_dao.dart`
- `mobile/lib/core/database/daos/nutrition_cache_dao.dart`
- `mobile/lib/core/providers/sync_provider.dart`

---

## Architectural Alignment

- [x] Follows existing layered architecture (Service -> Provider -> Widget)
- [x] Models/schemas in correct locations (`core/models/` for data classes, `core/services/` for platform integration, `core/providers/` for Riverpod state)
- [x] No business logic in views -- health permission flow orchestrated in provider, data fetching in service
- [x] Consistent with existing patterns (Riverpod StateNotifier, sealed class state, DAO accessor pattern)

---

## Overall Assessment

The architecture of this health data integration is well-designed and consistent with the existing codebase patterns. The implementation follows a clean three-layer separation:

1. **HealthService** (platform layer) -- wraps the `health` package, handles raw HealthKit/Health Connect API calls, returns typed `HealthMetrics` dataclass.
2. **HealthDataNotifier** (state management layer) -- manages permission lifecycle, orchestrates data fetching, handles auto-import weight logic, persists permission state.
3. **TodaysHealthCard** / **HomeScreen** (presentation layer) -- reactively renders based on sealed class state, handles user interaction only.

This is the correct layering per the project conventions. The health data never touches the backend -- it flows from HealthKit/Health Connect to the service, through the provider, to the UI. The only server interaction is the weight auto-import, which correctly delegates to the existing `OfflineWeightRepository` (preserving the offline-first architecture from Pipeline 15).

### Key Architecture Decisions Validated

1. **Sealed class state hierarchy**: `HealthDataState` with `HealthDataInitial`, `HealthDataLoading`, `HealthDataLoaded`, `HealthDataPermissionDenied`, `HealthDataUnavailable` enables exhaustive pattern matching in the UI. This is Dart 3 idiomatic and prevents unhandled state bugs.

2. **No new Drift tables**: The pending data merge uses existing `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins` tables. New DAO methods are simple aliases that delegate to existing queries. No schema migration needed.

3. **Injectable HealthService**: The constructor-based `Health` injection (`HealthService({Health? health})`) and `healthServiceProvider` enable unit testing without real HealthKit calls. This was correctly identified and fixed during code review.

4. **Non-blocking health data**: Health data fetch runs in parallel with the main dashboard load via `_initHealthData()` in `initState`. The card appears via Riverpod state change. This prevents the health API (which can be slow on first call) from blocking the entire dashboard.

5. **Permission-once pattern**: Permission state persisted in SharedPreferences with `health_permission_asked` / `health_permission_granted` keys. The permission bottom sheet is shown at most once per app install. This is the correct UX pattern -- respects the user's choice without nagging.

---

## Issues Found & Fixed

### 1. MODERATE -- `dart:io Platform.isIOS` in `HealthService.healthSettingsUri`

**File:** `mobile/lib/core/services/health_service.dart`
**Issue:** The static getter `healthSettingsUri` used `Platform.isIOS` from `dart:io`, which is not web-safe. The code review for this pipeline already fixed the same issue in `health_permission_sheet.dart` (replaced with `Theme.of(context).platform == TargetPlatform.iOS`), but missed the service file. While health functionality is inherently mobile-only, using `dart:io Platform` prevents the service file from even being imported in a web context, which could cause issues when the web dashboard project (Priority #2 in CLAUDE.md) shares code or types.
**Fix:** Replaced `import 'dart:io' show Platform` with `import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform` and changed `Platform.isIOS` to `defaultTargetPlatform == TargetPlatform.iOS`.

### 2. MINOR -- Unnecessary import in `health_card.dart`

**File:** `mobile/lib/shared/widgets/health_card.dart`
**Issue:** `import 'package:flutter/foundation.dart' show debugPrint;` was unnecessary because `package:flutter/material.dart` already re-exports all of `foundation.dart`. This triggered a `unnecessary_import` lint warning.
**Fix:** Auto-resolved by the linter on save. Import was removed.

### 3. MINOR -- Missing `toString()` on `HealthMetrics`

**File:** `mobile/lib/core/models/health_metrics.dart`
**Issue:** While `operator ==` and `hashCode` were properly implemented, `toString()` was missing. For a data class that gets logged in debug `assert()` blocks and stored in provider state, a human-readable `toString()` is important for debuggability. Without it, debug prints show `Instance of 'HealthMetrics'` which is useless.
**Fix:** Added `toString()` that formats all fields clearly.

### 4. MINOR -- `prefer_const_constructors` lint violations

**Files:** `home_screen.dart` (lines 863-864), `nutrition_screen.dart` (line 163)
**Issue:** `SnackBar`, `Row`, and `Tooltip` constructors that could be `const` were not marked as such. These were introduced by this pipeline's changes.
**Fix:** Added `const` modifier to `SnackBar` in home screen and `Tooltip` in nutrition screen.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No new Drift tables or schema changes. `HealthMetrics` is a pure in-memory data class. |
| Migrations reversible | N/A | No database migrations needed for this feature. |
| Indexes added for new queries | OK | New DAO methods (`getPendingWorkoutsForUser`, `getPendingNutritionForUser`, `getPendingWeightForUser`) are aliases that delegate to existing indexed queries. |
| No N+1 query patterns | OK | Each pending data type is loaded with a single query per type per load. Health data is fetched in 4 parallel calls (steps, calories, HR, weight). |
| `HealthMetrics` data class correct | OK | Immutable, `const` constructor, proper `==`/`hashCode`/`toString()`, sensible nullable fields. Follows project's "return dataclass not dict" rule. |
| Sealed state class hierarchy correct | OK | Exhaustive, each state has `const` constructor, `HealthDataLoaded` has proper equality. |

### HealthMetrics Data Flow

```
HealthKit/Health Connect
    |
    v
HealthService.syncTodayHealthData() -> HealthMetrics
    |
    v
HealthDataNotifier.fetchHealthData() -> state = HealthDataLoaded(metrics)
    |                                    |
    |                                    +-> _autoImportWeight(metrics) -> OfflineWeightRepository
    v
TodaysHealthCard watches healthDataProvider -> renders card or SizedBox.shrink()
```

This is clean. No circular dependencies. The weight auto-import reuses the existing offline-first repository chain -- no new data paths introduced.

### Pending Data Merge Flow

```
WorkoutCacheDao.getPendingWorkouts(userId) -> List<PendingWorkoutLog>
    |
    v
HomeNotifier._loadPendingWorkouts() -> List<PendingWorkoutDisplay>
    |
    v
HomeState.pendingWorkouts -> merged into _buildRecentWorkoutsSection()

NutritionCacheDao.getPendingNutritionForUser(userId, date) -> List<PendingNutritionLog>
    |
    v
NutritionNotifier._loadPendingNutrition(date) -> _PendingNutritionResult
    |
    v
NutritionState.pendingNutritionCount / pendingProtein / etc. -> additive merge in _buildMacroCards()

NutritionCacheDao.getPendingWeightForUser(userId) -> List<PendingWeightCheckin>
    |
    v
NutritionNotifier._loadPendingWeights() -> List<PendingWeightDisplay>
    |
    v
NutritionState.pendingWeights -> merged into WeightTrendsScreen + Nutrition header
```

This is additive and correct. Pending entries are displayed alongside server data without replacing it. The `syncCompletionProvider` listener ensures badges disappear reactively when sync completes.

---

## Riverpod Pattern Assessment

**StateNotifier usage**: `HealthDataNotifier` correctly extends `StateNotifier<HealthDataState>` with sealed class states. The `mounted` guards after every `await` prevent state mutations on disposed notifiers. This was a critical fix from the code review.

**Provider dependencies**: `healthDataProvider` watches `authStateProvider`, `offlineWeightRepositoryProvider`, `healthServiceProvider`, and `databaseProvider`. All dependencies are correctly declared. No circular chains.

**`ref.listen(syncCompletionProvider)` in `build()`**: Used in 3 screens (HomeScreen, NutritionScreen, WeightTrendsScreen). This is the correct Riverpod pattern for side effects triggered by provider changes. Riverpod handles listener deduplication internally -- calling `ref.listen` in `build()` does not create multiple listeners.

**`select()` usage**: Applied judiciously for the health card spacer visibility (`healthDataProvider.select((state) => state is HealthDataLoaded || state is HealthDataLoading)`). The dev correctly noted that `select()` on providers where multiple fields are needed would add complexity without reducing rebuilds. This is pragmatically correct.

**Lifecycle**: `HealthDataNotifier` is automatically disposed when `healthDataProvider` is no longer watched. The `mounted` checks prevent post-disposal state mutations. No manual cleanup needed since `HealthService` has no streams or subscriptions to dispose.

---

## Scalability Concerns

| # | Area | Severity | Issue | Recommendation |
|---|------|----------|-------|----------------|
| 1 | Health data types | Low | Adding more health types (sleep, HRV, blood oxygen) requires modifying `_requestedTypes`, adding getter methods in `HealthService`, adding fields to `HealthMetrics`, and adding tiles to `TodaysHealthCard`. The approach is linear but manageable. | Consider a `HealthMetricType` enum and a map-based approach if more than 6-8 types are ever needed. Current 4-type approach is fine. |
| 2 | File sizes | Medium | `home_screen.dart` is 1355 lines (9x the 150-line guideline). `nutrition_screen.dart` is 1150 lines. These are pre-existing issues exacerbated by adding health card and pending workout sections. | Extract `_CalorieRing`, `_MacroCircle`, `_VideoCard`, `_RecentWorkoutCard`, `_PendingWorkoutCard` to separate widget files in `features/home/presentation/widgets/`. This is a refactoring task, not a blocker. |
| 3 | Pending data merge | Low | `_loadPendingWorkouts()` and `_loadPendingNutrition()` are called every time `loadDashboardData()` / `loadInitialData()` is invoked. With many pending entries, the JSON parsing in `_loadPendingWorkouts` could add latency. | Acceptable for V1. The JSON parsing is O(n) per pending entry and n is typically < 10. |
| 4 | `syncCompletionProvider` | Low | This stream-based provider emits on every sync completion, which triggers full dashboard reload in all 3 screens. With frequent sync events, this could cause unnecessary UI rebuilds. | Acceptable for V1. Sync completion is infrequent (once per reconnect cycle). If it becomes a problem, debounce the listener or scope it to specific data types. |
| 5 | `NutritionState.copyWith` cannot null out fields | Low | The `copyWith` method uses `??` for all nullable fields (`latestCheckIn`, `goals`, `dailySummary`, etc.), meaning they can never be explicitly set back to `null`. If a user's last weight check-in is deleted, the state cannot reflect that. | For weight, the server returns the latest check-in, so on next refresh the field updates. Not a blocking issue but worth noting for future. |

---

## Performance Assessment

The performance changes are architecturally sound:

1. **RepaintBoundary placement**: Applied to `_CalorieRing`, `_MacroCircle`, `_MacroCard` (all contain `CircularProgressIndicator`), `_RecentWorkoutCard`, `_PendingWorkoutCard`, and the weight chart `CustomPaint`. These are the right widgets to wrap -- they contain paint-heavy operations that should not trigger parent repaints.

2. **`SliverList.builder` conversion**: Weight trends history correctly converted from `Column` with spread operators to `CustomScrollView` + `SliverList.builder`. This virtualizes the potentially unbounded history list. The `CustomScrollView` approach (vs plain `ListView.builder`) is correct because the screen has non-repeating header content (summary card + chart) that must scroll with the list.

3. **`shouldRepaint` optimization**: `_WeightChartPainter` now uses `listEquals` for data comparison and field-level equality for numeric/color values. This is correct and prevents unnecessary repaints when the widget rebuilds for unrelated reasons.

4. **Static `NumberFormat`**: `_numberFormat` as `static final` in `_LoadedHealthCardState` avoids creating a new formatter on every build. Minor but correct.

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `home_screen.dart` at 1355 lines, well above 150-line guideline | Medium | Extract `_CalorieRing`, `_MacroCircle`, `_VideoCard`, `_RecentWorkoutCard`, `_PendingWorkoutCard` into `features/home/presentation/widgets/`. Pre-existing issue exacerbated by this pipeline. |
| 2 | `nutrition_screen.dart` at 1150 lines | Medium | Extract `_MacroCard`, `_MealSection`, `_FoodEntryRow` into `features/nutrition/presentation/widgets/`. Pre-existing issue. |
| 3 | AC-19 (SyncStatusBadge on individual food entry rows) deferred | Low | Requires refactoring pending nutrition data model from JSON blobs to individual entries. Documented in dev-done.md. Not architecturally blocking. |
| 4 | `PendingWorkoutDisplay` and `PendingWeightDisplay` classes defined in provider files rather than in `models/` | Low | These are small display-only classes closely tied to their providers. Moving to separate model files would improve discoverability but is not critical. |
| 5 | Two pre-existing `use_build_context_synchronously` info warnings in home_screen.dart and nutrition_screen.dart | Low | These are in logout/edit flows with `mounted` guards. The lint is being cautious. Not a real bug. |

## Technical Debt Reduced

| # | Description |
|---|-------------|
| 1 | `HealthService` return type changed from `Map<String, dynamic>` to typed `HealthMetrics` dataclass, adhering to project's "no dict returns" rule. |
| 2 | `HealthService` bug fixed: `data is NumericHealthValue` (wrong -- was checking the `HealthDataPoint` container) changed to `point.value is NumericHealthValue` (correct -- checks the value property). |
| 3 | Sleep data removed from health permissions (was requested but never displayed). Cleaner permission scope. |
| 4 | `Platform.isIOS` replaced with `defaultTargetPlatform == TargetPlatform.iOS` for web safety. |
| 5 | Weight chart `shouldRepaint` changed from `=> true` to data-comparison-based, eliminating unnecessary repaints. |
| 6 | All three deferred AC items from Pipeline 15 (AC-12/16/18 -- merging pending data into list views) are now implemented. |

---

## Architecture Score: 8/10

**Rationale:**

**Strengths (contributing to score):**
- Clean three-layer separation (Service -> Provider -> Widget) for health integration
- Sealed class state hierarchy with exhaustive pattern matching
- No backend changes needed -- health data stays local, respecting privacy
- Weight auto-import correctly reuses existing offline-first repository chain
- Pending data merge is additive and correct
- Performance optimizations are targeted and conservative
- Injectable `HealthService` enables testing
- `mounted` guards prevent post-disposal state mutations

**Deductions:**
- (-1) File sizes significantly exceed the 150-line widget file guideline (pre-existing but exacerbated)
- (-0.5) AC-19 deferred (food entry row sync badges) -- justified but incomplete
- (-0.5) `PendingWorkoutDisplay` / `PendingWeightDisplay` classes co-located with providers rather than in models directory

**Not deducted (pre-existing issues):**
- `home_screen.dart` and `nutrition_screen.dart` were already large before this pipeline
- `use_build_context_synchronously` warnings are pre-existing patterns
- `Map<String, dynamic>` return types in other parts of the codebase

## Recommendation: APPROVE

The architecture is sound, consistent with the existing codebase, and scales appropriately for the current feature set. The health integration is correctly isolated as a local-only, display-only feature that reuses existing infrastructure for weight auto-import. The offline UI polish correctly merges pending data additively without introducing new data paths. Performance optimizations are conservative and targeted. All issues found were minor and have been fixed during this review. The remaining items are low-severity technical debt documented above for follow-up.

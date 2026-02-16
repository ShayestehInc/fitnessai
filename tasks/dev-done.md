# Dev Done: Health Data Integration + Performance Audit + Offline UI Polish

## Date
2026-02-15

## Build & Lint Status
- `flutter analyze`: PASS (0 new errors/warnings in modified files; only pre-existing issues remain)

---

## Summary
Implemented all three parts of the ticket: Health Data Integration (Part A), Offline UI Polish (Part B), and Performance Audit (Part C). This is a frontend-only implementation in the Flutter mobile app.

---

## Files Created

### 1. `mobile/lib/core/models/health_metrics.dart`
- Immutable dataclass for health metrics with `const` constructor and `const empty` factory.
- Fields: `steps`, `activeCalories`, `heartRate` (nullable), `latestWeightKg` (nullable), `weightDate` (nullable).

### 2. `mobile/lib/core/providers/health_provider.dart`
- `HealthDataNotifier` (StateNotifierProvider) with sealed class state hierarchy: `HealthDataInitial`, `HealthDataLoading`, `HealthDataLoaded`, `HealthDataPermissionDenied`, `HealthDataUnavailable`.
- Methods: `checkAndRequestPermission()`, `wasPermissionAsked()`, `requestOsPermission()`, `declinePermission()`, `fetchHealthData()`.
- Auto-import weight feature: when health data is fetched and a weight reading exists for today, it creates a weight check-in via `OfflineWeightRepository` with date-based deduplication.
- Permission state persisted in SharedPreferences (`health_permission_asked`, `health_permission_granted`).

### 3. `mobile/lib/shared/widgets/health_permission_sheet.dart`
- `showHealthPermissionSheet(BuildContext)` returns `Future<bool>`.
- Material bottom sheet with health icon, platform-specific name (Apple Health / Health Connect), "Connect Health" and "Not Now" buttons.

### 4. `mobile/lib/shared/widgets/health_card.dart`
- `TodaysHealthCard` ConsumerWidget using pattern matching on health state.
- `_LoadedHealthCard` with 200ms fade-in animation, 2x2 metric grid (Steps, Active Cal, Heart Rate, Weight).
- Gear icon opens device health settings via `url_launcher`.
- `NumberFormat('#,###')` for thousands separators.
- "--" for missing data.
- `_SkeletonHealthCard` for loading state with matching shimmer layout.
- `_MetricTile` widget with icon, label, value (min height 48dp for accessibility).

---

## Files Modified

### 5. `mobile/lib/core/services/health_service.dart`
- Complete rewrite to include `ACTIVE_ENERGY_BURNED` and `WEIGHT` types.
- Removed `SLEEP_IN_BED` from permission request (not displayed on card).
- Fixed bug: changed `data is NumericHealthValue` (wrong -- data is `HealthDataPoint`) to `point.value is NumericHealthValue`.
- Return type changed from `Map<String, dynamic>` to typed `HealthMetrics` dataclass.
- Added `checkPermissionStatus()`, `getTodayActiveCalories()`, `getLatestWeight()`.
- Each data type fetch is independently try-caught for graceful partial data.
- Added `healthSettingsUri` static getter for platform-specific health app URI.

### 6. `mobile/ios/Runner/Runner.entitlements`
- Added `com.apple.developer.healthkit` = true and `com.apple.developer.healthkit.access` = empty array (read-only).

### 7. `mobile/ios/Runner/Info.plist`
- Updated `NSHealthShareUsageDescription` to mention steps, active calories, heart rate, weight.
- Removed `NSHealthUpdateUsageDescription` (we are read-only).

### 8. `mobile/android/app/src/main/AndroidManifest.xml`
- Added `READ_ACTIVE_CALORIES_BURNED` and `READ_WEIGHT` permissions.
- Removed all WRITE permissions and `READ_SLEEP` permission (no longer needed).

### 9. `mobile/lib/features/home/presentation/screens/home_screen.dart`
- Added `TodaysHealthCard` between Nutrition and Weekly Progress sections with conditional spacer.
- `_initHealthData()` in initState: first-time permission prompt flow (check persisted state -> show bottom sheet if first time -> request OS permission).
- Pull-to-refresh also refreshes health data in parallel (non-blocking).
- Wrapped `_CalorieRing` and each `_MacroCircle` in `RepaintBoundary` (AC-25).
- Wrapped `_RecentWorkoutCard` in `RepaintBoundary` (AC-22).
- Updated `_buildRecentWorkoutsSection` to show pending workouts first with `_PendingWorkoutCard`.
- Added `_PendingWorkoutCard` widget with Stack + Positioned SyncStatusBadge at bottom-right (AC-15, AC-18).
- Used `select()` for health card spacer visibility to avoid unnecessary rebuilds (AC-24).

### 10. `mobile/lib/features/home/presentation/providers/home_provider.dart`
- Added `PendingWorkoutDisplay` class with clientId, workoutName, exerciseCount, createdAt, formattedDate getter.
- Added `pendingWorkouts` field to `HomeState` and its `copyWith`.
- `HomeNotifier` now takes `AppDatabase` and `int? _userId` as constructor params.
- Provider wires in `databaseProvider` and `authStateProvider.user.id`.
- Added `_loadPendingWorkouts()` method that queries `workoutCacheDao.getPendingWorkouts()`, parses JSON for workout name and exercise count, handles corrupted JSON gracefully (falls back to "Unknown Workout").

### 11. `mobile/lib/core/database/daos/workout_cache_dao.dart`
- Added `getPendingWorkoutsForUser(int userId)` alias method (AC-21).

### 12. `mobile/lib/core/database/daos/nutrition_cache_dao.dart`
- Added `getPendingNutritionForUser(int userId, String date)` alias method (AC-21).
- Added `getPendingWeightForUser(int userId)` alias method (AC-21).

### 13. `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart`
- Added `PendingWeightDisplay` class with clientId, date, weightKg, notes.
- Added `_PendingNutritionResult` class for macro totals (internal).
- Added pending fields to `NutritionState`: `pendingNutritionCount`, `pendingCalories`, `pendingProtein`, `pendingCarbs`, `pendingFat`, `pendingWeights`.
- `NutritionNotifier` now takes `AppDatabase` and `int? _userId`.
- `loadInitialData()` now loads pending nutrition and pending weights, merges latest weight (pending vs server).
- `refreshDailySummary()` now also reloads pending nutrition data in parallel.
- Added `_loadPendingNutrition(String date)` and `_loadPendingWeights()` methods.

### 14. `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`
- `_buildMacroCards` adds pending macros to displayed totals (AC-16).
- Each `_MacroCard` wrapped in `RepaintBoundary` (AC-25).
- Added "(includes X pending)" label below macro cards when `pendingNutritionCount > 0` (AC-16).
- Updated `_buildGoalHeader` Latest Weight section to show cloud_off icon when latest weight is from pending entry (AC-17).
- Fixed pre-existing `prefer_const_constructors` lint on star icon (AC-23).

### 15. `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart`
- Converted body from `SingleChildScrollView` + `Column` with spread operators to `CustomScrollView` + `SliverList.builder` for virtualised rendering of history items (AC-26).
- Pending weight entries shown first with `_buildPendingWeightRow` and SyncStatusBadge (AC-17, AC-20).
- Server entries use `_buildHistoryRow` with optional `isPending` flag for SyncStatusBadge.
- Added `RepaintBoundary` around the CustomPaint weight chart (AC-22).
- Improved `shouldRepaint` in `_WeightChartPainter` to compare data instead of always returning true (performance).

### 16. `mobile/lib/core/providers/sync_provider.dart`
- Added `syncCompletionProvider` StreamProvider that emits true when sync completes (for reactive UI updates after sync).

---

## Key Decisions

1. **Sealed class for health state**: Used Dart 3 sealed class pattern (`HealthDataInitial`, `HealthDataLoading`, `HealthDataLoaded`, `HealthDataPermissionDenied`, `HealthDataUnavailable`) to enable exhaustive pattern matching in the UI. This ensures every state is handled.

2. **Weight auto-import deduplication**: Relies on `OfflineWeightRepository.createWeightCheckIn()` returning a failure when a check-in already exists for today, rather than pre-checking. This avoids race conditions.

3. **Non-blocking health data**: Health data fetches run in parallel with the main dashboard load. The card appears via state change when data arrives. The rest of the dashboard is never delayed.

4. **Read-only health permissions**: Removed all write permissions (we only read from health platforms). Removed sleep data entirely since it's not displayed.

5. **CustomScrollView + SliverList.builder**: Used for weight trends history instead of `ListView.builder` because we need the non-repeating header content (summary card + chart) to scroll with the list. `SliverList.builder` provides virtualisation for the potentially large history list.

6. **Riverpod select()**: Applied selectively where it provides the most benefit (health card spacer visibility check) rather than applying it everywhere. Widgets that need multiple fields from a provider don't benefit from select() and would add complexity without performance gain.

7. **shouldRepaint optimization**: Changed the weight chart painter from `shouldRepaint => true` to comparing data/range/color. This prevents unnecessary repaints when the parent widget rebuilds for unrelated reasons.

---

## Review Fixes Applied (Round 1)

### Critical Fixes
1. **C1 (Steps double-counting)**: Replaced `getHealthDataFromTypes()` + manual sum in `getTodaySteps()` with `getTotalStepsInInterval()` which uses platform-level aggregate queries (HKStatisticsQuery on iOS, AggregateRequest on Android) for proper deduplication of overlapping sources.

2. **C2 (Fire-and-forget async)**: Changed `_autoImportWeight(metrics)` from fire-and-forget to `await _autoImportWeight(metrics)` inside the existing try-catch. Added `if (!mounted) return;` guards after every `await` in `fetchHealthData()` and `_autoImportWeight()` to prevent state mutations on disposed notifiers.

3. **C3 (Refresh UX)**: Added `isRefresh` parameter to `fetchHealthData()`. When refreshing with existing data, skips the `HealthDataLoading` state (no skeleton flash) and on failure preserves the existing `HealthDataLoaded` state instead of transitioning to `HealthDataUnavailable`. Home screen passes `isRefresh: true` on pull-to-refresh.

### Major Fixes
4. **M1 (syncCompletionProvider unused)**: Wired `ref.listen(syncCompletionProvider, ...)` into `HomeScreen.build()`, `NutritionScreen.build()`, and `WeightTrendsScreen.build()` to reload pending data when sync completes, so badges disappear reactively.

5. **M2 (Active calories overlapping sources)**: Replaced `getHealthDataFromTypes()` + manual sum in `getTodayActiveCalories()` with `getHealthAggregateDataFromTypes()` which uses platform-level aggregate queries.

6. **M3 (Offline weight dedup)**: Before auto-importing weight, now queries `nutritionCacheDao.getPendingWeightCheckins()` and checks if any pending entry already has today's date. If so, skips the import to prevent duplicate offline entries.

7. **M6/M7 (HealthService not injectable)**: Changed `HealthService` from static `_health` singleton to instance field via constructor (`HealthService({Health? health})`). Created `healthServiceProvider` for Riverpod injection. `healthDataProvider` now uses `ref.watch(healthServiceProvider)`.

### Minor Fixes
8. **m1 (Gear icon accessibility)**: Replaced `GestureDetector` with `IconButton` for proper ripple feedback, 32dp minimum touch target, and tooltip.

9. **m2 (Platform.isIOS not web-safe)**: Replaced `Platform.isIOS` with `Theme.of(context).platform == TargetPlatform.iOS` in `health_permission_sheet.dart`.

10. **m3 (Android health settings URI)**: Changed Android URI from Play Store URL to Health Connect content URI (`content://com.google.android.apps.healthdata`).

11. **m4 (shouldRepaint reference equality)**: Added `import 'package:flutter/foundation.dart' show listEquals;` and changed `data != oldDelegate.data` to `!listEquals(data, oldDelegate.data)` for proper deep list comparison.

12. **m5 (HealthMetrics equality)**: Added `operator ==` and `hashCode` to `HealthMetrics` using `Object.hash(steps, activeCalories, heartRate, latestWeightKg, weightDate)`.

13. **m6 (Error silencing)**: Added `assert(() { debugPrint('...error: $e'); return true; }());` debug logging to all `catch` blocks in `HealthService` and `HealthDataNotifier`.

14. **m7 (Hardcoded date arrays)**: Replaced manual weekday/month arrays in `PendingWorkoutDisplay.formattedDate` with `DateFormat('EEE, MMM d').format(createdAt)` from the `intl` package.

15. **m11 (HealthDataLoaded equality)**: Added `operator ==` and `hashCode` to `HealthDataLoaded` that delegates to `HealthMetrics` equality.

16. **m12 (NumberFormat allocation)**: Made `NumberFormat('#,###')` a static final field in `_LoadedHealthCardState` instead of recreating it on every build.

---

## Deviations from Ticket

1. **AC-19 (SyncStatusBadge on food entry rows)**: Partially deferred. Pending nutrition entries are stored as raw JSON blobs in Drift, not as individual `MealEntry` objects. The architecture stores an entire AI-parsed meal payload, not individual food items. Mapping them back to specific meal section rows would require significant refactoring of the pending data model. Instead, the macro totals merge and "(includes X pending)" label address the intent of showing that offline data is reflected in the display.

2. **AC-23 (const constructor audit)**: Focused on the priority files specified in the ticket (home_screen.dart, nutrition_screen.dart, weight_trends_screen.dart, shared widgets). All new code already uses `const` constructors where possible. One pre-existing lint issue fixed (Icon widget in nutrition_screen.dart). The broader codebase has pre-existing `prefer_const_constructors` lints in files outside the scope of this ticket.

3. **AC-24 (Riverpod select())**: Applied `select()` for the health card spacer visibility check. The home screen and nutrition screen already have relatively clean provider watching patterns. The main `build()` methods need multiple fields from the state, so `select()` would not reduce rebuilds meaningfully (you'd need to select multiple fields, defeating the purpose).

---

## How to Manually Test

### Part A: Health Data Integration

1. **Permission flow**: Install on a physical iOS device (or Android with Health Connect). On first launch, the home screen should show a bottom sheet asking to connect health data. Tap "Connect Health" to see the OS permission prompt. After granting, the health card should appear.

2. **Health card display**: After granting permission, pull down on the home screen. The card should show steps, active calories, heart rate, and weight from HealthKit/Health Connect. Missing metrics show "--".

3. **Settings gear**: Tap the gear icon on the health card. On iOS, it should open the Health app. On Android, it should open Health Connect.

4. **Permission denied**: Decline the permission prompt. The health card should be hidden. Close and reopen the app -- the prompt should NOT appear again.

5. **Weight auto-import**: Ensure a weight reading exists in HealthKit for today. Open the app. Navigate to Weight Trends -- an auto-imported check-in with notes "Auto-imported from Health" should appear (unless a manual entry already exists for today).

### Part B: Offline UI Polish

6. **Pending workouts on home screen**: Put the device in airplane mode. Log a workout through the AI command center. Return to the home screen. The workout should appear at the top of "Recent Workouts" with a cloud_off icon (SyncStatusBadge pending) at the bottom-right. Tapping it shows a "This workout is waiting to sync" snackbar.

7. **Pending nutrition on nutrition screen**: In airplane mode, log nutrition via the AI command center. Open the Nutrition tab. The macro cards should include the pending entry's macros, and a "(includes 1 pending)" label should appear below the cards.

8. **Pending weights on weight trends**: In airplane mode, do a weight check-in. Open Weight Trends. The pending weight should appear at the top of the history list with a SyncStatusBadge.

9. **Latest weight merge**: If the most recent weight is a pending entry, the Nutrition screen header should show it with a small cloud_off icon.

10. **Sync resolution**: Turn off airplane mode. Let sync complete. Pending badges should disappear. Data should remain consistent.

### Part C: Performance

11. **Scroll performance**: On the home screen, scroll up and down. The CalorieRing and MacroCircle widgets have RepaintBoundary -- they should not cause jank.

12. **Weight trends virtualisation**: Add 50+ weight check-ins (via API/seed data). Open Weight Trends. The history list uses SliverList.builder -- only visible items are rendered. Scrolling should be smooth.

13. **Chart repaint**: The weight chart's `shouldRepaint` now compares data. Scrolling the weight trends screen should not cause unnecessary chart repaints.

---

## Acceptance Criteria Status

| AC | Description | Status |
|----|-------------|--------|
| AC-1 | Health permission request on first home screen visit | DONE |
| AC-2 | Permission bottom sheet with explanation | DONE |
| AC-3 | Card hidden when permission denied / unavailable | DONE |
| AC-4 | Health card with steps, active cal, HR, weight | DONE |
| AC-5 | Health data non-blocking, pull-to-refresh | DONE |
| AC-6 | HealthDataProvider with sealed states | DONE |
| AC-7 | WEIGHT added to HealthService | DONE |
| AC-8 | ACTIVE_ENERGY_BURNED added to HealthService | DONE |
| AC-9 | Weight auto-import with date dedup | DONE |
| AC-10 | Auto-import notes "Auto-imported from Health" | DONE |
| AC-11 | Permission persisted in SharedPreferences | DONE |
| AC-12 | HealthService rewritten, typed return | DONE |
| AC-13 | iOS entitlements + Android permissions | DONE |
| AC-14 | Gear icon opens health settings | DONE |
| AC-15 | Pending workouts in home Recent Workouts | DONE |
| AC-16 | Pending nutrition merged into macro totals | DONE |
| AC-17 | Pending weights in Weight Trends + Latest Weight | DONE |
| AC-18 | SyncStatusBadge on pending workout cards | DONE |
| AC-19 | SyncStatusBadge on food entry rows | DEFERRED (see deviations) |
| AC-20 | SyncStatusBadge on pending weight entries | DONE |
| AC-21 | DAO alias methods for pending queries | DONE |
| AC-22 | RepaintBoundary on list items with paint ops | DONE |
| AC-23 | Const constructor audit on priority files | DONE |
| AC-24 | Riverpod select() where beneficial | DONE |
| AC-25 | RepaintBoundary on CalorieRing, MacroCircle, MacroCard | DONE |
| AC-26 | ListView.builder / SliverList.builder for large lists | DONE |

# Feature: Health Data Integration + Performance Audit + Offline UI Polish

## Priority
High

## User Story
As a **trainee**, I want to see my daily health metrics (steps, active calories, heart rate, weight) pulled from Apple Health / Health Connect directly on my home screen, so that I have a holistic view of my fitness without manually entering data that my phone already tracks.

As a **trainee**, I want my offline-logged workouts, nutrition entries, and weight check-ins to appear in the correct list views (with sync status indicators), so that I can trust the app shows complete data even when I log things offline.

As a **developer**, I want the app to hit 60fps on common scrolling/navigation flows, so that the user experience feels polished and responsive.

---

## Acceptance Criteria

### Part A: Health Data Integration

- [ ] **AC-1**: On first launch after update (or first visit to home screen with no prior permission), the app requests HealthKit (iOS) and Health Connect (Android) read permissions for: steps, active energy burned (active calories), heart rate, and weight.
- [ ] **AC-2**: The permission request uses a clear, non-technical explanation bottom sheet that tells the user *why* the app needs health data before triggering the OS-level prompt. The sheet has "Connect Health" and "Not Now" buttons.
- [ ] **AC-3**: If the user denies permission or the platform does not support health data (e.g., simulator, unsupported Android device), the "Today's Health" card is hidden entirely from the home screen. No error. No empty card.
- [ ] **AC-4**: If permission is granted, a "Today's Health" card appears on the home screen between the "Nutrition" section and the "Weekly Progress" section. The card shows:
  - Steps (integer, e.g., "8,234") with a walking icon
  - Active Calories (integer, e.g., "342 cal") with a flame icon
  - Heart Rate (integer, e.g., "68 bpm") with a heart icon -- shows latest reading from the past 24 hours, or "--" if no data
  - Weight (one decimal, e.g., "75.2 kg") from the most recent HealthKit/Health Connect weight sample, or "--" if none
- [ ] **AC-5**: Health data is fetched when the home screen loads (`initState`) and when the user pulls to refresh. Health data fetch does NOT block the rest of the dashboard from loading -- it runs in parallel and the card appears/updates when data arrives.
- [ ] **AC-6**: A `HealthDataProvider` (Riverpod `StateNotifierProvider`) manages the state: `loading`, `loaded(HealthMetrics)`, `unavailable`, `permissionDenied`. The home screen reactively shows/hides the card based on this state.
- [ ] **AC-7**: The `health` package `HealthDataType.WEIGHT` is added to the types list in `HealthService`. When a weight reading is found from the past 7 days, the service returns it.
- [ ] **AC-8**: `HealthDataType.ACTIVE_ENERGY_BURNED` is added to the types list. The service returns today's total active calories (summed, same pattern as steps).
- [ ] **AC-9**: Auto-import weight from HealthKit/Health Connect: When health data is fetched and a weight reading exists for today that is NOT already in the WeightCheckIn model (check by date), the app automatically creates a weight check-in via the existing `OfflineWeightRepository.createWeightCheckIn()`. Deduplication is by date -- if a check-in already exists for today (from manual entry or prior auto-import), skip the import.
- [ ] **AC-10**: The auto-imported weight check-in has `notes` set to `"Auto-imported from Health"` so the user can distinguish it from manual entries.
- [ ] **AC-11**: Health permission status is persisted in `SharedPreferences` (`health_permission_granted: bool`, `health_permission_asked: bool`). The permission prompt is shown at most once per app install. After the first ask, the app respects whatever the OS returns silently.
- [ ] **AC-12**: `HealthService` is rewritten to include `ACTIVE_ENERGY_BURNED` and `WEIGHT` in addition to existing `STEPS`, `HEART_RATE`. Sleep is removed from the permission request (not displayed on the card). The return type of `syncTodayHealthData()` is changed from `Map<String, dynamic>` to a typed `HealthMetrics` dataclass.
- [ ] **AC-13**: iOS `Runner.entitlements` has `com.apple.developer.healthkit` entitlement added. Android `AndroidManifest.xml` has `READ_ACTIVE_CALORIES_BURNED` and `READ_WEIGHT` permissions added.
- [ ] **AC-14**: The "Today's Health" card has a gear icon in the top-right corner that opens the device's Health app settings (iOS: opens Health app, Android: opens Health Connect). Uses `url_launcher` with the platform-specific URI.

### Part B: Offline UI Polish (Deferred from Pipeline 15)

- [ ] **AC-15**: Local pending workouts from `PendingWorkoutLogs` are merged into the Home screen "Recent Workouts" list. They appear at the top of the list (most recent first), with a `SyncStatusBadge` overlay showing `pending` or `failed` status. Tapping a pending workout shows a "Pending sync" snackbar instead of navigating to detail.
- [ ] **AC-16**: Local pending nutrition entries from `PendingNutritionLogs` are merged into the Nutrition screen's macro totals for the selected date. When viewing a date that has pending entries, those entries' macros (protein, carbs, fat, calories) are added to the server-provided totals. A small "(includes X pending)" label appears below the macro cards.
- [ ] **AC-17**: Local pending weight check-ins from `PendingWeightCheckins` are merged into the Weight Trends screen history list and the "Latest Weight" display on the Nutrition screen. Pending check-ins show with a `SyncStatusBadge`. The "Latest Weight" on the nutrition screen header uses the most recent weight across both server and local data.
- [ ] **AC-18**: `SyncStatusBadge` is placed on each `_RecentWorkoutCard` in the home screen's recent workouts section. The badge is positioned at the bottom-right of the card via a `Stack` + `Positioned` wrapper. Only shown for items that came from local storage (not server data).
- [ ] **AC-19**: `SyncStatusBadge` is placed on each food entry row in the nutrition screen's meals section for entries that are pending sync. The badge appears after the edit icon.
- [ ] **AC-20**: `SyncStatusBadge` is placed on each weight check-in entry in the Weight Trends screen's history list for entries that are pending sync.
- [ ] **AC-21**: The `WorkoutCacheDao` exposes a method `getPendingWorkoutsForUser(int userId)` that returns all pending workout rows, and the `NutritionCacheDao` exposes `getPendingNutritionForUser(int userId, String date)` that returns pending nutrition entries for a given date, and `getPendingWeightForUser(int userId)` that returns all pending weight entries.

### Part C: Performance Audit

- [ ] **AC-22**: All scrollable lists (home screen, nutrition screen meals, workout history, weight trends, trainer trainee list, exercise bank) are audited for `RepaintBoundary` usage. `RepaintBoundary` is added around list item widgets where the item contains animations, progress indicators, or complex paint operations.
- [ ] **AC-23**: All widget classes across the codebase are audited for `const` constructors. Every widget that CAN have a `const` constructor (no mutable fields, all fields are final with const-compatible types) is converted to use `const`. Priority files: home_screen.dart, nutrition_screen.dart, workout_log_screen.dart, weight_trends_screen.dart, and all shared widgets.
- [ ] **AC-24**: Riverpod `Consumer` / `ConsumerWidget` usage is audited. Where a widget watches a provider but only uses one field from the state, it is refactored to use `ref.watch(provider.select((s) => s.field))` to avoid unnecessary rebuilds. Priority: home screen (watches `homeStateProvider` in multiple sub-widgets), nutrition screen.
- [ ] **AC-25**: The `_CalorieRing`, `_MacroCircle`, and `_MacroCard` widgets on the home/nutrition screens are wrapped in `RepaintBoundary` since they contain `CircularProgressIndicator` paint operations that cause expensive repaints.
- [ ] **AC-26**: `ListView.builder` is used (instead of `Column` with `.map().toList()`) for any list that can exceed 10 items. The home screen's recent workouts section (capped at 3-5) is fine as `Column`, but the workout history screen, weight trends history list, and nutrition meals list (if > 10 entries) should use `ListView.builder` for virtualization.

---

## Edge Cases

1. **Health data returns zero for everything**: Steps = 0, calories = 0, heart rate = null, weight = null. The card should still show: "0" for steps, "0 cal" for calories, "--" for heart rate, "--" for weight. The card should NOT be hidden just because values are zero -- zero is valid data (user hasn't moved yet today).

2. **Health permission denied after previously being granted (revoked in Settings)**: The `health` package's `requestAuthorization` returns `true` even if the user subsequently revokes individual data types in iOS Health settings (Apple's privacy design). The service should handle empty/null data gracefully by showing "--" for that metric, not crashing or showing stale data from `SharedPreferences`.

3. **Multiple weight readings on the same day from HealthKit**: Sum/average is NOT what we want. Use the MOST RECENT weight reading by `dateFrom` timestamp. If the user steps on a smart scale 3 times, we want the last reading.

4. **Auto-import weight races with manual entry**: User opens weight check-in screen and manually enters 75.0 kg. Meanwhile, the home screen loads and tries to auto-import 75.1 kg from HealthKit (smart scale reading from an hour ago). The deduplication check (by date) prevents the auto-import from overwriting the manual entry. Manual entry takes priority because it was already saved by the time the health data fetch completes.

5. **Offline pending data + server data have overlapping dates**: A pending nutrition entry from yesterday (saved offline) and the server's data for yesterday (synced before the offline entry was created) should be ADDED together, not replaced. The pending entry represents NEW food logged offline that hasn't been synced yet -- it's additive.

6. **Platform has no health data support at all**: Android devices without Health Connect installed, iOS simulators, or very old Android versions. `health.requestAuthorization()` throws or returns false. The `HealthDataProvider` state should be `unavailable` and the card should be hidden. No crash. No error dialog.

7. **Large step counts or calorie values**: A marathon runner might have 40,000+ steps or 3,000+ active calories. The card layout must not overflow. Use `NumberFormat` with locale-aware thousands separators (e.g., "40,234" not "40234").

8. **App launched while device is in airplane mode**: Health data should still be accessible (it's local on-device). The `HealthService` reads from the local HealthKit/Health Connect store, not from a network. This should work even when `ConnectivityService.isOnline` is false.

9. **SyncStatusBadge on a card that gets synced while visible**: When the sync engine processes a pending item and it succeeds, the badge should transition from `pending` to `synced` (which renders as `SizedBox.shrink()` per the existing implementation). The list should reactively update. This requires watching the sync status stream or re-querying pending items after sync events complete.

10. **Pending nutrition entries contain invalid or zero macros**: A nutrition entry saved offline might have `protein: 0, carbs: 0, fat: 0, calories: 0` (e.g., water or a zero-calorie drink). This is valid and should still be counted/merged without filtering.

11. **Weight auto-import when user has never manually checked in**: The `NutritionState.latestCheckIn` may be null. The auto-imported weight creates the first-ever check-in. The nutrition screen's "Latest Weight" should then display this auto-imported value.

12. **User has health permission but HealthKit returns an error for a specific data type**: For example, steps work fine but `ACTIVE_ENERGY_BURNED` throws. Each data type fetch is independent and wrapped in its own try-catch. Partial data is valid.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Health permission denied | No health card on home screen | Sets `HealthDataState.permissionDenied`, persists to SharedPreferences. Card hidden. |
| Health data fetch throws exception | No health card (graceful degradation) | Catches exception, sets state to `unavailable`. Rest of dashboard loads normally. |
| Health data partially available (e.g., steps yes, heart rate no) | Card shows available data, "--" for missing | Each metric is independently nullable. Card renders what it has. |
| Platform doesn't support health APIs | No health card | Try-catch around `requestAuthorization`. State = `unavailable`. |
| HealthKit returns stale data (no readings today) | Steps: 0, Calories: 0, HR: shows last 24h reading or "--", Weight: shows last 7d reading or "--" | Date ranges: steps/calories = today midnight to now, HR = last 24h, weight = last 7 days. |
| Auto-import weight fails (e.g., storage full) | No visible error (background operation) | Catches `OfflineSaveResult.failure`, does NOT show snackbar. Silent failure -- logged in debug only. |
| Pending workout has corrupted JSON | Card shows "Unknown Workout" with sync badge | JSON decode wrapped in try-catch. Falls back to placeholder data. |
| Offline DB query for pending items fails | Server-only data shown (no merge) | Try-catch around DB reads. If DB fails, show server data only. No crash. |
| SyncStatusBadge shown on already-synced item | Badge disappears (SizedBox.shrink for synced) | Query is re-run after sync completes. Synced items are removed from pending tables. |

---

## UX Requirements

### Health Card
- **Loading state**: Skeleton shimmer placeholder matching the card layout (4 metric placeholders as gray rounded rectangles). Shown while health data is being fetched. Rest of dashboard renders immediately above and below.
- **Empty state (no permission)**: Card is hidden entirely. No "Connect Health" banner cluttering the home screen uninvited. The user can connect later via Settings.
- **Error state**: Card hidden. No error toast/banner for health data failures -- it's supplementary data, not core functionality. The dashboard functions perfectly without it.
- **Success state**: Card fades in with a 200ms opacity animation when data arrives. Metrics update in place on pull-to-refresh.
- **Permission prompt**: Material bottom sheet with health icon, title "Connect Your Health Data", body text: "FitnessAI can read your steps, calories burned, heart rate, and weight from [Apple Health / Health Connect] to give you a complete picture of your daily activity.", two buttons: "Connect Health" (primary filled button) and "Not Now" (text button). Shown once per app install, on first home screen visit.
- **Mobile behavior**: The health card is a single horizontal row on wider screens (tablet), 2x2 grid on phones. Each metric tile is 48dp minimum height.

### Offline Merge UI
- **Pending workout cards**: Identical layout to server workout cards but wrapped in a `Stack` with a `Positioned` `SyncStatusBadge` at bottom-right. Tapping shows a snackbar: "This workout is waiting to sync." Not navigable to detail screen.
- **Pending nutrition merge**: The "(includes X pending)" text is 11px, uses `theme.textTheme.bodySmall?.color`, appears directly below the macro cards row with 4px top padding. Disappears when items sync.
- **Pending weight in Latest Weight**: If the most recent weight is a pending local entry, the "Latest Weight" number on the nutrition screen shows it with a small 12px `cloud_off` icon (amber) next to the date text.
- **Sync badge placement**: All badges are 16x16 per the existing `SyncStatusBadge` spec. Positioned via `Positioned(right: 4, bottom: 4)` inside a `Stack`.

### Performance
- No visible UI changes for the user. Performance improvements are invisible.
- If `RepaintBoundary` wrapping causes any visual regressions (clipping, shadow cutoff, z-index issues), remove it from that specific widget.
- `const` constructor additions should not change any runtime behavior.
- `select()` optimizations should not change any rendered output.

---

## Technical Approach

### Files to Create

| File | Purpose |
|------|---------|
| `mobile/lib/core/models/health_metrics.dart` | Immutable dataclass: `int steps`, `int activeCalories`, `int? heartRate`, `double? latestWeightKg`, `DateTime? weightDate`. Has `const` constructor. |
| `mobile/lib/core/providers/health_provider.dart` | `HealthDataProvider` (Riverpod `StateNotifierProvider`). States: `initial`, `loading`, `loaded(HealthMetrics)`, `permissionDenied`, `unavailable`. Methods: `checkAndRequestPermission()`, `fetchHealthData()`, `autoImportWeight()`. Depends on `HealthService`, `SharedPreferences`, `OfflineWeightRepository`. |
| `mobile/lib/shared/widgets/health_card.dart` | `TodaysHealthCard` widget: ConsumerWidget that watches `healthDataProvider`. Shows skeleton, data card, or nothing based on state. 4-metric layout with icons. Gear settings icon. `const` where possible. |
| `mobile/lib/shared/widgets/health_permission_sheet.dart` | `showHealthPermissionSheet(BuildContext)` function. Returns `Future<bool>` (true = user tapped Connect). Material bottom sheet with icon, title, body, two buttons. |

### Files to Modify

| File | Changes |
|------|---------|
| `mobile/lib/core/services/health_service.dart` | Rewrite: Add `ACTIVE_ENERGY_BURNED`, `WEIGHT` to types. Remove `SLEEP_IN_BED`. Add `getTodayActiveCalories()`, `getLatestWeight()`. Change `syncTodayHealthData()` to return `HealthMetrics`. Add `checkPermissionStatus()`. Fix API usage: `getHealthDataFromTypes` returns `List<HealthDataPoint>`, extract `.value` properly (the current code checks `data is NumericHealthValue` on a `HealthDataPoint` which is wrong -- should be `data.value is NumericHealthValue`). |
| `mobile/lib/features/home/presentation/screens/home_screen.dart` | Insert `TodaysHealthCard` between Nutrition and Weekly Progress. Wrap `_CalorieRing` and `_MacroCircle` in `RepaintBoundary`. Modify `_buildRecentWorkoutsSection` to merge pending workouts. Add `SyncStatusBadge` to `_RecentWorkoutCard` via optional `syncStatus` parameter. |
| `mobile/lib/features/home/presentation/providers/home_provider.dart` | Add `List<PendingWorkoutDisplay> pendingWorkouts` to `HomeState`. In `loadDashboardData()`, query `WorkoutCacheDao.getPendingWorkoutsForUser()` and merge results into recent workouts. |
| `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` | Below macro cards, add "(includes X pending)" label when pending count > 0. Add `SyncStatusBadge` to `_FoodEntryRow` for pending items. Wrap `_MacroCard` in `RepaintBoundary`. |
| `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart` | In macro total computation, add pending nutrition macros. Query `NutritionCacheDao.getPendingNutritionForUser()` for the selected date. Add `int pendingNutritionCount` to `NutritionState`. |
| `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart` | Merge pending weight check-ins from `NutritionCacheDao.getPendingWeightForUser()` into the history list. Show `SyncStatusBadge` on pending entries. |
| `mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart` | No functional changes. Already uses `OfflineWeightRepository`. |
| `mobile/lib/core/database/daos/workout_cache_dao.dart` | Add `Future<List<PendingWorkoutLog>> getPendingWorkoutsForUser(int userId)`. |
| `mobile/lib/core/database/daos/nutrition_cache_dao.dart` | Add `Future<List<PendingNutritionLog>> getPendingNutritionForUser(int userId, String date)`. Add `Future<List<PendingWeightCheckin>> getPendingWeightForUser(int userId)`. |
| `mobile/ios/Runner/Runner.entitlements` | Add `com.apple.developer.healthkit` key with value `true`, and `com.apple.developer.healthkit.access` array with empty array (read-only). |
| `mobile/ios/Runner/Info.plist` | Update `NSHealthShareUsageDescription` to: "FitnessAI reads your steps, active calories, heart rate, and weight to display your daily health summary and auto-import weight check-ins." |
| `mobile/android/app/src/main/AndroidManifest.xml` | Add `android.permission.health.READ_ACTIVE_CALORIES_BURNED` and `android.permission.health.READ_WEIGHT` permissions. Remove WRITE permissions (we are read-only). |
| `mobile/lib/core/providers/sync_provider.dart` | Expose a provider or stream that notifies when sync completes, so UI can refresh pending item lists. |

### Key Dependencies
- `health: ^13.2.1` -- already in `pubspec.yaml`
- `shared_preferences: ^2.2.2` -- already in `pubspec.yaml`
- `url_launcher: ^6.2.4` -- already in `pubspec.yaml`
- `intl: ^0.20.2` -- already in `pubspec.yaml` (for `NumberFormat`)
- No new packages needed.

### Key Design Decisions

1. **Health data is display-only, local-only**: No backend changes. Health metrics are never sent to the server. This respects user privacy and avoids HIPAA/GDPR complexity. The only exception is auto-importing weight to WeightCheckIn, which uses the existing save flow (goes through `OfflineWeightRepository` which handles online/offline).

2. **HealthMetrics as a typed dataclass, not Map<String, dynamic>**: Per project rules (`.claude/rules/datatypes.md`), services and utils return dataclasses or Pydantic models, never dicts.

3. **Permission prompt shown once, via bottom sheet, not blocking**: The bottom sheet is shown on first home screen visit if `health_permission_asked` is false in SharedPreferences. After the user taps "Connect" or "Not Now", the preference is set and the sheet never appears again. This is non-intrusive -- the home screen loads fully behind the sheet.

4. **Pending data merge is additive for nutrition, positional for workouts/weight**: Pending nutrition entries add to server totals (they represent new food not yet synced). Pending workouts prepend to the recent list (newest first). Pending weight entries insert chronologically into the trends list.

5. **Performance changes are conservative**: Only add `RepaintBoundary` where there's a clear paint-heavy widget (CircularProgressIndicator, LinearProgressIndicator, animations). Don't wrap every widget -- that increases memory usage with diminishing returns. Focus on the hot paths: home screen scroll, nutrition screen scroll, workout log scroll.

6. **Auto-import weight runs silently**: No snackbar, no dialog. The weight just appears in the check-in history. The `notes` field ("Auto-imported from Health") distinguishes it from manual entries. If auto-import fails (storage full, DB error), it fails silently -- the user can always manually check in. Errors logged in debug mode only.

7. **Existing HealthService bugs fixed**: The current `health_service.dart` has a bug where it checks `if (data is NumericHealthValue)` on `HealthDataPoint` objects. The `health` package returns `List<HealthDataPoint>` from `getHealthDataFromTypes`, and the numeric value is at `data.value` (a `HealthValue`), not on the `HealthDataPoint` itself. This must be fixed as part of the rewrite.

8. **No new Drift tables**: Pending data already exists in `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`. We just need new DAO query methods to read them. No schema migration needed.

---

## Out of Scope

- Background health data sync (when app is closed) -- requires BGTaskScheduler (iOS) / WorkManager (Android), too complex for this pipeline
- Writing health data back to HealthKit/Health Connect (read-only integration)
- Full health dashboard screen -- just a summary card on the home screen
- Sending health data to the backend -- this is local/display only
- Sleep tracking display -- was in the original placeholder but not in the focus
- Heart rate variability (HRV) or resting heart rate (separate HealthKit types) -- just use generic `HEART_RATE`
- Historical health data charting (past 7/30 days of steps) -- just today's snapshot
- Health data notifications ("You hit 10,000 steps!")
- Backend API for health data storage or analytics
- Workout history screen refactor to `ListView.builder` (already uses pagination/infinite scroll)
- New Drift schema version / migration -- not needed for this ticket

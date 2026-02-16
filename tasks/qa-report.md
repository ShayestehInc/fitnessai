# QA Report: Offline Workout & Nutrition Logging with Sync Queue (Phase 6)

## QA Date
2026-02-15 (Pipeline 15)

## Test Approach
Full code review of all 30+ implementation files against all 42 acceptance criteria. No runtime tests executed (no device/simulator available), but every acceptance criterion was verified by reading actual code paths, tracing data flow, and reasoning about edge cases.

---

## Test Results
- **Total AC Verified:** 42
- **AC Passed:** 33 (including 2 with documented deviations)
- **AC Partial:** 4 (AC-11, AC-36, AC-37, AC-38)
- **AC Failed:** 3 (AC-12, AC-16, AC-18 -- deferred UI merge tasks)
- **AC Not Applicable:** 2 (AC-28 and AC-40 overlap -- both refer to synced item cleanup timing)
- **Bugs Found:** 5 (1 critical, 1 minor, 3 info)
- **Bugs Fixed by QA:** 1

---

## Bugs Found and Fixed

### BUG-1: Infinite Retry Loop -- retryItem resets retryCount for sync engine (CRITICAL, FIXED)

**Files:** `mobile/lib/core/database/daos/sync_queue_dao.dart` + `mobile/lib/core/services/sync_service.dart`

**Description:** The `retryItem()` DAO method resets `retryCount` to 0 (correctly, for user-initiated manual retries from the FailedSyncSheet). However, the `SyncService._handleSyncError()` at line 288 also called `retryItem()` for automatic retries within the backoff loop. Since `retryItem()` resets `retryCount` to 0, the automatic retry logic would never reach the `retryCount + 1 < _maxRetries` threshold -- items would retry infinitely instead of failing permanently after 3 attempts.

**Root cause:** Single method serving two different retry semantics (manual vs automatic).

**Fix applied:**
- Created new `requeueForRetry(int id)` method in `SyncQueueDao` that resets status to `pending` and clears `lastError` but does NOT reset `retryCount`.
- Updated `SyncService._handleSyncError()` to call `requeueForRetry()` instead of `retryItem()`.
- `retryItem()` continues to reset `retryCount` to 0, used only for user-initiated retries from the FailedSyncSheet.

**Verification after fix:** Retry trace is now correct:
- Attempt 1: retryCount=0, fails -> markFailed sets retryCount=1, requeueForRetry preserves retryCount=1, delay 5s
- Attempt 2: retryCount=1, fails -> markFailed sets retryCount=2, requeueForRetry preserves retryCount=2, delay 15s
- Attempt 3: retryCount=2, fails -> `2+1 < 3` is false -> markFailed sets retryCount=3, permanently failed. Correct: 3 total attempts with 5s, 15s, 45s backoffs.

---

## Acceptance Criteria Verification

### Drift Local Database Setup

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | **PASS** | `app_database.dart` declares `@DriftDatabase` with 5 tables: `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`, `CachedPrograms`, `SyncQueueItems`. Database initialized in `main.dart:25` before `runApp`. |
| AC-2 | **PASS** | `_openConnection()` in `app_database.dart:69-74` uses `getApplicationDocumentsDirectory()` from `path_provider` and stores file at `fitnessai_offline.sqlite`. `LazyDatabase` ensures persistence across restarts. |
| AC-3 | **PASS** | `pubspec.yaml` uses `drift: ^2.14.1`, `sqlite3_flutter_libs: ^0.5.18`, `drift_dev: ^2.14.1` (dev). `sqlite3: ^2.9.0` added as direct dependency for `SqliteException` import -- acceptable and necessary. |
| AC-4 | **PASS** | `database_provider.dart` exposes `databaseProvider` (Riverpod `Provider<AppDatabase>`). Overridden in `ProviderScope` in `main.dart:35`. Default body throws `UnimplementedError`. |

### Network Connectivity Detection

| AC | Status | Evidence |
|----|--------|----------|
| AC-5 | **PASS** | `connectivity_plus: ^6.0.0` in `pubspec.yaml:38`. `ConnectivityService` in `connectivity_service.dart` wraps `connectivity_plus`, monitors via stream subscription at line 44, debounces with 2-second timer at lines 52-58. |
| AC-6 | **PASS** | `connectivityStatusProvider` (StreamProvider) in `connectivity_provider.dart:13-17`. `isOnlineProvider` provides synchronous check at lines 21-28. Both exposed to entire widget tree. |
| AC-7 | **PASS** | `SyncService._onConnectivityChanged()` at `sync_service.dart:62-70` triggers `_processQueue()` when status transitions to online. `_pendingRestart` flag handles re-invocation if sync is already in progress. |
| AC-8 | **PASS** | All three offline repos check `DioExceptionType.connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, and `unknown` narrowed to `SocketException`. On match, data is saved locally instead of showing an error. Verified at `offline_workout_repository.dart:293-298`, `offline_nutrition_repository.dart:105-110`, `offline_weight_repository.dart:110-115`. |

### Offline Workout Logging

| AC | Status | Evidence |
|----|--------|----------|
| AC-9 | **PASS** | `OfflineWorkoutRepository._saveWorkoutLocally()` inserts into `pendingWorkoutLogs` table with `clientId`, `userId`, JSON payloads, and auto-generated `createdAt` via Drift default. Status `pending` in sync queue. |
| AC-10 | **PASS** | Payload structure at `offline_workout_repository.dart:94-98` includes `workout_summary` (with workout_name, duration, exercises with sets), `survey_data`, and `readiness_survey` -- matches the structure expected by `POST /api/workouts/surveys/post-workout/`. |
| AC-11 | **PARTIAL** | Offline success shows a SnackBar with cloud_off icon and "Workout saved locally..." text (`active_workout_screen.dart:450-466`). The ticket specifies "success screen identical to the online flow, plus a banner." The current implementation shows only a snackbar before `context.pop()`, not the full success screen. |
| AC-12 | **FAIL** | Deferred. Home screen's `_buildRecentWorkoutsSection` does NOT merge local pending workouts with server data. Infrastructure exists (`WorkoutCacheDao.getPendingWorkouts`) but HomeProvider was not modified to consume it. |
| AC-13 | **PASS** | `OfflineWorkoutRepository.submitReadinessSurvey()` at lines 129-189 saves to sync queue with `SyncOperationType.readinessSurvey`. Called from `active_workout_screen.dart:414-421`. |

### Offline Nutrition Logging

| AC | Status | Evidence |
|----|--------|----------|
| AC-14 | **PASS** | `OfflineNutritionRepository.confirmAndSave()` saves `parsedDataJson` and `targetDate` to `pendingNutritionLogs` and `syncQueueItems` when offline. Used by `LoggingNotifier.confirmAndSave()` at `logging_provider.dart:148-153`. |
| AC-15 | **PASS** | `ai_command_center_screen.dart:58-73` shows snackbar with cloud_off icon: "Log saved locally. It will sync when you're back online." |
| AC-16 | **FAIL** | Deferred. Nutrition screen does NOT merge locally-saved entries into macro totals. The offline banner is present, but pending entries are not optimistically added to consumed values. |

### Offline Weight Check-In

| AC | Status | Evidence |
|----|--------|----------|
| AC-17 | **PASS** | `OfflineWeightRepository.createWeightCheckIn()` saves to `pendingWeightCheckins` and `syncQueueItems`. Called from `weight_checkin_screen.dart:246-250`. Correct date, weightKg, and notes saved. |
| AC-18 | **FAIL** | Deferred. Weight trends screen does NOT merge local pending check-ins with server data. The offline banner provides visibility but no data merge. |

### Program Caching

| AC | Status | Evidence |
|----|--------|----------|
| AC-19 | **PASS** | `OfflineWorkoutRepository.getPrograms()` at lines 197-204 caches programs via `ProgramCacheDao.cachePrograms()` after successful fetch. Stores JSON-encoded programs keyed by userId. |
| AC-20 | **PASS** | On API failure, `_getProgramsFromCache()` reads from Drift cache. `WorkoutNotifier.loadInitialData()` sets `programsFromCache: fromCache` flag. `WorkoutLogScreen` at lines 34-58 shows "Showing cached program. Some data may be outdated." banner when `state.programsFromCache` is true. |
| AC-21 | **PASS** | `ProgramCacheDao.cachePrograms()` wraps delete-then-insert in `transaction()` for atomicity. Old entries are overwritten, not appended. |
| AC-22 | **PASS** | `ActiveWorkoutScreen` operates entirely on local state (`_exerciseLogs`). Program data is loaded into `WorkoutState.programWeeks` from cache. Workout can be started, exercises logged, sets completed, and post-workout survey submitted -- all using the offline repository for final save. |

### Sync Queue

| AC | Status | Evidence |
|----|--------|----------|
| AC-23 | **PASS** | `SyncQueueItems` table in `tables.dart:44-55` has: `id` (auto-increment), `clientId` (unique text), `userId` (int), `operationType` (text), `payloadJson` (text), `status` (text, default 'pending'), `createdAt` (datetime with default), `syncedAt` (nullable datetime), `retryCount` (int, default 0), `lastError` (nullable text). All required columns present. |
| AC-24 | **PASS** | `SyncService._processQueue()` uses `getNextPending()` which queries `status.equals('pending')` ordered by `createdAt ASC` with `limit(1)` -- FIFO. Items processed sequentially in a while loop, not in parallel. |
| AC-25 | **PASS** | `_processItem()` calls `markSyncing()`, then on success calls `markSynced()` (sets `syncedAt`), on failure routes to `_handleSyncError()` which calls `markFailed()` (increments `retryCount`, sets `lastError`). All status transitions verified. |
| AC-26 | **PASS** | After BUG-1 fix: `_handleSyncError` checks `item.retryCount + 1 < _maxRetries` (3). If retryable, `markFailed` increments count, `requeueForRetry` resets to pending (preserving count), exponential backoff delay applied [5s, 15s, 45s]. If max reached, permanently failed. Exactly 3 retry attempts. |
| AC-27 | **PASS** | `FailedSyncSheet` in `failed_sync_sheet.dart` shows each failed item with: operation type icon (fitness_center/restaurant/monitor_weight/assignment), description extracted from payload, error message in red, created date, per-item "Retry" (outlined blue) and "Delete" (text red) buttons. "Retry All" button in header. Auto-closes when all items handled via `Navigator.of(context).pop()`. |
| AC-28 | **PASS (deviation)** | `runStartupCleanup()` calls `deleteOldSynced(Duration(hours: 24))`. Ticket AC-28 says "24 hours" but AC-40 says "7 days." Implementation uses 24 hours -- documented as intentional since synced items are already on server. |
| AC-29 | **PASS** | `SyncService` is created via `syncServiceProvider` which starts on `syncService.start()`. It listens to connectivity stream independently of navigation state. Runs as long as the ProviderScope (app) is alive. |

### Conflict Resolution

| AC | Status | Evidence |
|----|--------|----------|
| AC-30 | **PASS** | `_handleSyncError` at lines 254-258: HTTP 409 detected, `_getConflictMessage` returns "Program was updated by your trainer. Please review." for workout_log. `markFailed` called with `_maxRetries` to prevent automatic retry. |
| AC-31 | **PASS** | Same mechanism for nutrition_log: returns "Nutrition data was updated. Please review." |
| AC-32 | **PASS** | For 5xx errors and network errors: `isRetryable` check returns true. Exponential backoff [5s, 15s, 45s] applied. After BUG-1 fix, exactly 3 retries occur before permanent failure. |

### Visual Indicators

| AC | Status | Evidence |
|----|--------|----------|
| AC-33 | **PASS** | `OfflineBanner` offline state: amber banner (`Color(0xFFF59E0B)` at 15% opacity), cloud_off icon, "You are offline" text, 28px height. Present on HomeScreen, WorkoutLogScreen, NutritionScreen. Semantics liveRegion included. |
| AC-34 | **PASS** | Syncing state: blue banner (`Color(0xFF3B82F6)` at 15% opacity), cloud_upload icon, progress text ("Syncing X of Y..."), 2px LinearProgressIndicator, 28px height. |
| AC-35 | **PASS** | All-synced state: green banner (`Color(0xFF22C55E)` at 15% opacity), cloud_done icon, "All changes synced" text. Auto-dismiss after 3 seconds via Timer at line 153. |
| AC-36 | **PARTIAL** | `SyncStatusBadge` widget exists in `sync_status_badge.dart` with correct 16x16 container, 12px icon, amber cloud_off for pending. Widget is functional but NOT placed on any cards in list views. |
| AC-37 | **PARTIAL** | `_RotatingIcon` provides 1-second rotation animation for syncing badge. Widget exists and works but is not placed on any cards. |
| AC-38 | **PARTIAL** | Failed badge uses error_outline icon, red color. Widget exists but is not placed on any cards in list views. |

### Performance & Cleanup

| AC | Status | Evidence |
|----|--------|----------|
| AC-39 | **PASS** | `_openConnection()` uses `LazyDatabase` (opened on first access, not eagerly). `syncServiceProvider` has `ref.onDispose(() => syncService.dispose())` for cleanup. Database persists for app lifetime. |
| AC-40 | **PASS (deviation)** | Cleanup uses 24 hours for synced items instead of 7 days. Documented as intentional (synced items already on server, 24h is sufficient buffer). |
| AC-41 | **PASS** | `runStartupCleanup()` calls `programCacheDao.deleteStaleCache(Duration(days: 30))`. |
| AC-42 | **PASS** | `NativeDatabase.createInBackground(file)` at `app_database.dart:73` runs database operations on a background isolate via Drift's built-in isolate support, preventing UI jank. |

---

## Acceptance Criteria Summary

| Status | Count | ACs |
|--------|-------|-----|
| PASS | 31 | AC-1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15, 17, 19, 20, 21, 22, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 39, 41, 42 |
| PASS (deviation) | 2 | AC-28 (24h vs 7d), AC-40 (24h vs 7d) |
| PARTIAL | 4 | AC-11 (snackbar not full success screen), AC-36, 37, 38 (badge widgets exist but unused on cards) |
| FAIL | 3 | AC-12 (no local workout merge on home), AC-16 (no local nutrition merge), AC-18 (no local weight merge) |

---

## Bugs Found Outside Tests

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| BUG-1 | **Critical** | `retryItem()` resets `retryCount` to 0, but sync engine also calls `retryItem()` -- causes infinite retry loop. Items never reach max retries and retry forever. | **FIXED** -- Added `requeueForRetry()` method for sync engine use. |
| BUG-2 | Minor | Non-atomic writes in `_saveWorkoutLocally`, `_saveNutritionLocally`, `_saveWeightLocally`: insert to pending table and sync queue are two separate operations without a transaction. A crash between them could leave orphaned data in the pending table with no corresponding sync queue entry. | Not fixed -- architecture constraint (repositories don't have direct access to `transaction()`). Low probability. |
| BUG-3 | Info | `OfflineBanner.build()` shows `SizedBox.shrink` on first build frame due to `addPostFrameCallback` deferring state update. One-frame flash where the banner should be visible but renders as hidden. | Not fixed -- cosmetic, barely perceptible. |
| BUG-4 | Info | `OfflineBanner.build()` both watches providers (lines 65-85) AND uses `ref.listen` for the same providers (lines 45-62). Redundant dual-path state tracking with potential for subtle inconsistency. | Not fixed -- code smell, functionally correct. |
| BUG-5 | Info | `SyncQueueDao` uses raw string literals ('pending', 'syncing', 'synced', 'failed') instead of `SyncItemStatus.pending.value` enum values. A typo would silently break queries at runtime. | Not fixed -- low risk, DAO is the database boundary layer. |

---

## Key Code Quality Observations

### Strengths
1. **Decorator pattern** for offline repos is clean -- existing repos remain unchanged, new behavior added non-invasively.
2. **Idempotency** via `clientId` + `existsByClientId()` prevents duplicate submissions during connectivity flicker.
3. **2-second debounce** in `ConnectivityService` correctly prevents sync thrashing during connectivity flapping.
4. **Exponential backoff** timing [5s, 15s, 45s] is reasonable for mobile network conditions.
5. **409 conflict handling** correctly marks as permanently failed with operation-specific descriptive messages.
6. **SQLite error handling** catches storage-full condition with user-friendly message across all 3 offline repos.
7. **Typed `OfflineSaveResult`** replaces untyped `Map<String, dynamic>` returns with clear success/failure/offline semantics.
8. **Background isolate** via `NativeDatabase.createInBackground` prevents UI jank from database operations.
9. **Startup cleanup** is wrapped in try/catch -- failures are non-fatal, app launches normally.
10. **clearUserData** is wrapped in a transaction for atomic cleanup on logout.

### Concerns
1. **totalPending count captured once** at start of sync processing. If new items are added during sync, the progress display ("Syncing X of Y") shows a potentially misleading total.
2. **401 handling marks single item as failed** but does not pause the queue -- subsequent items will also hit 401 until the Dio interceptor refreshes the token. Could cause rapid cascading failures of multiple items.
3. **No database migration strategy** -- `schemaVersion` is 1. Future schema changes will need migration logic in `onUpgrade`.
4. **`_processQueue` recursion via `_pendingRestart`** -- after the fix to use `Future.microtask`, this is safe from stack overflow but could theoretically loop indefinitely if `_pendingRestart` keeps getting set.

---

## Confidence Level: **MEDIUM-HIGH**

### Rationale
- The core offline infrastructure (database, sync queue, connectivity monitoring, offline repositories) is solid and well-implemented.
- BUG-1 (critical: infinite retry loop) was found and fixed during this QA pass. Without this fix, the sync queue would have retried failed items infinitely.
- 33 of 42 ACs pass (79%). 3 ACs remain failed -- these are UI merge tasks (showing offline data alongside server data in list views) that were documented as deferred in dev-done. They don't affect core offline functionality.
- 4 ACs are partial -- badge widgets exist but are not placed on UI cards, and the offline workout success is shown via snackbar rather than full success screen.
- Without runtime testing on a real device, I cannot verify connectivity transitions, timer behavior, debounce timing, or visual rendering. The code reads correctly but real-world timing and state management may reveal additional issues.

---

**QA completed by:** QA Engineer Agent
**Date:** 2026-02-15
**Pipeline:** 15 -- Offline-First Workout & Nutrition Logging with Sync Queue (Phase 6)
**Verdict:** Confidence MEDIUM-HIGH, Failed: 3 (deferred), Critical Bugs Fixed: 1

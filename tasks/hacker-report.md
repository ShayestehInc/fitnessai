# Hacker Report: Offline-First Workout & Nutrition Logging with Sync Queue (Pipeline 15)

## Date: 2026-02-15

## Focus Areas
Offline-first workout, nutrition, and weight check-in logging with Drift (SQLite) local database, sync queue, and connectivity monitoring. Backend-agnostic sync engine with FIFO queue processing, exponential backoff, and 409 conflict detection. Mobile: core database layer (tables, DAOs, app_database), offline-aware repositories (workout, nutrition, weight), services (connectivity, sync, sync_status), providers, UI widgets (offline_banner, sync_status_badge, failed_sync_sheet), modified screens (home, workout_log, nutrition, weight_checkin, ai_command_center, settings, active_workout).

---

## Dead Buttons & Non-Functional UI

| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | `SyncStatusBadge` (synced state) | Badge icon for synced items | AC-38: synced items show no badge | Was showing green `cloud_done` icon inside a 16x16 SizedBox, taking up layout space for nothing. **FIXED**: changed to `SizedBox.shrink()`. |
| 2 | Low | `FailedSyncSheet` | "Retry All" button | Should trigger sync and provide feedback | Button triggers sync and closes sheet, but there is no visual feedback while the retry-all loop runs (it iterates items sequentially). For large lists, the user could tap multiple times. Not a blocker -- the `_failedItems.clear()` prevents duplicates. |
| 3 | Low | `SyncStatusBadge` widget | The badge widget itself | Should be used on workout/nutrition/weight cards | The widget exists and is well-implemented, but it is not actually placed on any card in the UI. It was created for AC-38 but no screen references it on individual items. Not wired up anywhere. Cannot fix without design decisions about which cards to badge. |

---

## Visual Misalignments & Layout Bugs

| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | `OfflineBanner` | Banner height is fixed at 28px with `height: 28`. On very small font sizes the text fits, but at larger accessibility font sizes the text could clip vertically. | Not fixed -- would need a `ConstrainedBox` with `minHeight` instead of fixed `height`. Requires testing on device with accessibility settings. |
| 2 | Low | `_BannerContent` | The indeterminate `LinearProgressIndicator` (syncing state) is only 60px wide and 2px tall. It may be hard to notice on larger screens. | Not fixed -- a design decision. The icon + text already convey syncing state. |
| 3 | Low | `FailedSyncSheet` | The `DraggableScrollableSheet` starts at 50% height. If there is only 1 failed item, the sheet is half-filled with empty space below the card. `initialChildSize` could be dynamic based on item count. | Not fixed -- minor polish item. The sheet is still functional. |

---

## Broken Flows & Logic Bugs

| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Manual retry of failed items | 1. Save items offline. 2. Go online. 3. Items fail 3 times (retryCount=3, marked `failed`). 4. Open FailedSyncSheet. 5. Tap "Retry" on a failed item. | Item should reset to pending with retryCount=0, giving it a fresh set of 3 retry attempts. | **WAS BROKEN**: `retryItem()` did NOT reset `retryCount`. After manual retry, the item would be picked up with retryCount=3, and `retryCount + 1 < _maxRetries` (4 < 3) = false, so it would immediately be marked permanently failed again. **FIXED**: Added `retryCount: Value(0)` to `retryItem()` in sync_queue_dao.dart. Also added separate `requeueForRetry()` method (preserves retryCount) for automatic retries by the sync engine. |
| 2 | High | Connectivity false-negative on Android | 1. Device connected to WiFi. 2. `connectivity_plus` reports `[ConnectivityResult.wifi, ConnectivityResult.none]` (documented Android behavior). | App reports online status. | **WAS BROKEN**: `_mapResults` checked `results.contains(ConnectivityResult.none)`, which would return offline even with a real WiFi connection present. **FIXED**: Changed logic to only report offline when `none` is the sole result (no real connections present). |
| 3 | High | Weight check-in double-submit | 1. Open weight check-in screen. 2. Enter weight. 3. Tap "Save Check-In". 4. Quickly tap again before the async operation completes. | Button should be disabled during save. | **WAS BROKEN**: The save button checked `state.isLoading` from `nutritionStateProvider`, but the actual save bypasses that provider and calls `offlineWeightRepo.createWeightCheckIn()` directly. The button stayed enabled during the entire async save, allowing double-taps. **FIXED**: Added local `_isSaving` flag with proper setState management. |
| 4 | Medium | Weight check-in missing online success feedback | 1. Be online. 2. Save a weight check-in successfully. | User should see a success snackbar. | **WAS BROKEN**: When `result.success && !result.offline`, the code block was empty -- no snackbar shown. Screen just popped with zero feedback. **FIXED**: Added success snackbar "Weight check-in saved successfully!" |
| 5 | Medium | SyncProgress totalPending is stale during sync | 1. Queue 3 items offline. 2. Go online (sync starts). 3. While syncing, save another item offline. | Progress should reflect the total including newly queued items. | `totalPending` is captured once at the start of `_processQueue()` (line 81-82 of sync_service.dart) and used throughout the entire sync loop. New items queued during sync will be processed (because the while loop fetches `getNextPending()` each iteration), but the progress display will show "Syncing 4 of 3..." (exceeding totalPending). The `_pendingRestart` flag will catch this for a re-run, but the in-progress UI is misleading. Not fixed -- would require re-querying count during the loop, which adds DB overhead. Low severity since it resolves after the sync cycle. |
| 6 | Low | FailedSyncSheet does not update if sync completes while sheet is open | 1. Open FailedSyncSheet showing 2 failed items. 2. Background process retries and succeeds for one item. | Sheet should reactively update to show 1 item. | Sheet loads failed items once in `initState()` and stores them in local `_failedItems` state. It does not watch a provider stream. If background sync changes items, the sheet shows stale data until closed and reopened. Not fixed -- would require converting to a StreamProvider-backed widget. |
| 7 | Low | Post-workout survey submission has no error handling | 1. Submit a post-workout survey via `_submitPostWorkoutSurvey`. 2. The offline repo returns a failure result. | User should be informed of the failure. | The `_submitPostWorkoutSurvey` method checks `result.offline` for the snackbar but does not check `result.success`. If the save fails entirely (e.g., disk full), the user gets no error feedback -- the screen just pops silently via `context.pop()` which is called unconditionally by the `onComplete` callback in PostWorkoutSurveyScreen. Not fixed -- requires restructuring the callback flow. |

---

## Edge Case Analysis (Verified Clean)

| # | Scenario | Current Behavior | Risk |
|---|----------|-----------------|------|
| 1 | Idempotency on duplicate offline save | `existsByClientId()` in OfflineWorkoutRepository checks sync queue before inserting. If clientId exists, returns `offlineSuccess` without inserting a duplicate. | Low -- Clean |
| 2 | Full disk SQLite write | All three offline repositories catch `SqliteException` and check `e.toString().contains('full')` for user-friendly "Device storage is full" error. | Low -- Clean |
| 3 | Corrupt JSON payload in sync queue | `_processItem()` catches `FormatException` from `jsonDecode()` and marks item permanently failed with descriptive message. No retry. | Low -- Clean |
| 4 | Unknown operation type in sync queue | `_processItem()` catches `ArgumentError` from `SyncOperationType.fromString()` and marks item permanently failed. No retry. | Low -- Clean |
| 5 | 409 Conflict response | `_handleSyncError()` detects HTTP 409 and marks item permanently failed with conflict-specific message. No retry. | Low -- Clean |
| 6 | 401 Unauthorized during sync | Detected, item marked failed with "Authentication expired. Please log in again." No further retry of that item. | Low -- Clean |
| 7 | Logout with unsynced items | Both `home_screen.dart` and `settings_screen.dart` check `unsyncedCountProvider` and show warning dialog with item count. User must confirm "Logout Anyway". `clearUserData()` runs in a transaction. | Low -- Clean |
| 8 | App startup with corrupted program cache | `_getProgramsFromCache()` catches `FormatException` from corrupt JSON, deletes the cache, and returns descriptive error. | Low -- Clean |
| 9 | Connectivity flapping (rapid on/off) | 2-second debounce in `ConnectivityService._onChanged()` prevents sync queue thrashing. | Low -- Clean |
| 10 | Sync while already syncing | `_isSyncing` flag prevents concurrent `_processQueue()` calls. `_pendingRestart` flag ensures new items are picked up after current sync completes. Uses `Future.microtask` to avoid recursive stack growth. | Low -- Clean |
| 11 | Offline save wraps insert pair in transaction | All three offline repositories wrap the pending-data insert + sync-queue insert in a Drift `transaction()`, preventing orphaned data without queue entry. | Low -- Clean |
| 12 | Startup cleanup failure | `runStartupCleanup()` wraps cleanup in try/catch. Failure is non-fatal; app launches even if cleanup fails. Debug-mode logging via assert. | Low -- Clean |
| 13 | WAL mode enabled | `beforeOpen` runs `PRAGMA journal_mode=WAL` for better concurrent read/write performance on the background isolate. | Low -- Clean |

---

## Product Improvement Suggestions

| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Home Screen pull-to-refresh | `RefreshIndicator.onRefresh` on home screen should also trigger `syncServiceProvider?.triggerSync()` in addition to `loadDashboardData()`. Users pulling to refresh expect pending items to sync. | Natural user expectation. Pull-to-refresh is the universal "sync now" gesture. Currently only refreshes dashboard data, not the sync queue. |
| 2 | High | Offline indicator in bottom nav | Add a subtle offline indicator (amber dot) on the bottom navigation bar, not just inside individual screens. Users navigating between tabs should always know they are offline. | The OfflineBanner is only visible on screens that include it (Home, Logbook, Nutrition). If the user is on Settings or any other screen, they have no offline awareness. |
| 3 | Medium | Retry with countdown | When the sync engine is waiting for exponential backoff (5s, 15s, 45s), show a countdown in the banner: "Retrying in 12s..." | The current "syncing" banner shows during the actual HTTP request but goes idle during backoff delays, making it look like sync stopped. A countdown would set expectations. |
| 4 | Medium | Conflict resolution UI | 409 conflict errors are marked as permanently failed with "Data conflict detected. Please review." but there is no UI to actually review or resolve the conflict. The user can only retry (which will fail again) or delete the local data. | A conflict resolution screen showing server vs. local data side-by-side would be ideal. Even a more helpful error message ("Your trainer updated your program while you were offline.") would improve the experience. |
| 5 | Medium | Pending items count in settings | Show the count of pending/failed sync items in the Settings screen (e.g., "Sync Status: 3 pending, 1 failed"). | Settings is where users go when something feels wrong. Having sync status there gives a second pathway to diagnose issues. |
| 6 | Low | Haptic feedback on offline save | Add light haptic feedback (`HapticFeedback.lightImpact()`) when data is saved offline. | Offline saves feel less certain to users. Haptic feedback provides tactile confirmation. |
| 7 | Low | Swipe-to-delete on FailedSyncSheet items | Failed sync item cards should support swipe-to-delete (Dismissible widget). | Faster interaction for power users. Standard iOS/Android pattern. |
| 8 | Low | Cached program staleness indicator | The workout log screen shows "Showing cached program. Some data may be outdated." but does not say HOW old the cached data is. Adding "Last updated: 2 hours ago" would help. | The current banner is helpful but vague. A timestamp would let users make informed decisions. |

---

## Summary

- Dead UI elements found: 3 (1 fixed, 2 noted)
- Visual bugs found: 3 (0 fixed -- minor polish items)
- Logic bugs found: 7 (4 fixed, 3 documented for future work)
- Edge cases verified clean: 13
- Improvements suggested: 8
- Items fixed by hacker: 5

## Fixes Applied

### Fix 1: `mobile/lib/core/database/daos/sync_queue_dao.dart`
- **Bug**: `retryItem()` did not reset `retryCount` to 0, causing manually retried items to immediately fail again.
- **Fix**: Added `retryCount: Value(0)` to the `retryItem()` method. Added separate `requeueForRetry()` method for automatic retries by the sync engine that preserves retryCount for correct exponential backoff.

### Fix 2: `mobile/lib/shared/widgets/sync_status_badge.dart`
- **Bug**: Synced items showed a green `cloud_done` icon, violating AC-38 which states synced items should show no badge.
- **Fix**: Changed synced case to `return const SizedBox.shrink()`.

### Fix 3: `mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart`
- **Bug 1**: No success snackbar when saving weight check-in online (screen popped with zero feedback).
- **Fix 1**: Added success snackbar "Weight check-in saved successfully!" in the `else` branch.
- **Bug 2**: Save button did not disable during async save, allowing double-taps.
- **Fix 2**: Added local `_isSaving` flag with proper `setState` management. Button and spinner now correctly reflect save-in-progress state.

### Fix 4: `mobile/lib/core/services/connectivity_service.dart`
- **Bug**: `_mapResults` reported offline when `results` contained `ConnectivityResult.none` alongside real connections (e.g., WiFi). This is documented Android behavior where `connectivity_plus` can return `[wifi, none]` simultaneously.
- **Fix**: Changed logic to check if any real connection exists (`results.any((r) => r != ConnectivityResult.none)`). Only reports offline when `none` is the sole result.

---

## Chaos Score: 7/10

### Rationale
The offline-first implementation is solid in its core architecture. The decorator pattern, transaction-wrapped saves, idempotency keys, and exponential backoff show careful engineering. However, several edge cases slipped through: the retryItem retryCount bug was critical (manual retries would silently fail forever), the connectivity false-negative on Android could cause the entire offline system to trigger incorrectly on WiFi, and the weight check-in had both missing feedback and a double-submit vulnerability. The FailedSyncSheet's static data loading means it can show stale state if background processes change items. The SyncStatusBadge exists but is not wired into any actual cards. The progress counter can exceed its total. These are the kinds of bugs that surface in real-world usage with real devices and real users, and several of them would have been frustrating to debug without understanding the full system.

**Good:**
- `transaction()` wrapping all offline save operations (pending data + sync queue insert)
- UUID-based idempotency keys with `existsByClientId()` check
- `requeueForRetry()` vs `retryItem()` separation for automatic vs manual retry semantics
- `_pendingRestart` flag with `Future.microtask` prevents recursive stack growth
- `FormatException` and `ArgumentError` catches in `_processItem()` for corrupt/unknown data
- `SqliteException` catch with user-friendly "device storage is full" messaging
- `clearUserData()` in a transaction for atomic logout cleanup
- WAL mode for concurrent read/write performance
- 2-second connectivity debounce preventing sync thrashing
- `runStartupCleanup()` is non-fatal -- app launches even if cleanup fails

---

**Audit completed by:** Hacker Agent
**Date:** 2026-02-15
**Pipeline:** 15 -- Offline-First Workout & Nutrition Logging with Sync Queue

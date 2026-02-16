# Feature: Offline Workout & Nutrition Logging with Sync Queue (Phase 6)

## Priority
Critical

## User Story
As a trainee at the gym with poor or no internet connection, I want to log my workouts and nutrition without interruption so that I never lose data and can focus on training instead of worrying about connectivity.

---

## Acceptance Criteria

### Drift Local Database Setup
- [ ] AC-1: A Drift (SQLite) database is initialized on app startup at `mobile/lib/core/database/app_database.dart` with tables for `pending_workout_logs`, `pending_nutrition_logs`, `pending_weight_checkins`, `cached_programs`, and `sync_queue`.
- [ ] AC-2: The database file is stored in the app's documents directory via `path_provider` and persists across app restarts.
- [ ] AC-3: The `drift` and `sqlite3_flutter_libs` packages (already in pubspec.yaml) are used. `drift_dev` (already in dev_dependencies) generates `.g.dart` files. No additional SQLite packages are added.
- [ ] AC-4: A `DatabaseProvider` (Riverpod provider) exposes the database singleton to the entire app.

### Network Connectivity Detection
- [ ] AC-5: The `connectivity_plus` package (~6.0.0) is added to `pubspec.yaml` and a `ConnectivityService` monitors network status in real time via stream subscription.
- [ ] AC-6: A `connectivityProvider` (Riverpod `StreamProvider`) exposes the current connectivity status (`online` / `offline`) to the entire widget tree.
- [ ] AC-7: When connectivity transitions from offline to online, the sync queue automatically begins processing pending items.
- [ ] AC-8: When connectivity transitions from online to offline, in-flight API calls that fail with `DioException` of type `connectionTimeout`, `sendTimeout`, `receiveTimeout`, or `connectionError` are automatically saved to the local database instead of showing an error.

### Offline Workout Logging
- [ ] AC-9: When the trainee completes a workout (post-workout survey submit) while offline, the workout data is saved to the `pending_workout_logs` Drift table with status `pending` and a `created_at` timestamp.
- [ ] AC-10: The saved offline workout contains the full `workout_summary` JSON (workout_name, duration, exercises with sets), `survey_data` JSON, and optional `readiness_survey` JSON -- the same payload structure that `POST /api/workouts/surveys/post-workout/` expects.
- [ ] AC-11: After saving offline, the trainee sees a success screen identical to the online flow, plus a banner: "Workout saved locally. It will sync when you're back online."
- [ ] AC-12: The home screen's "Recent Workouts" section includes locally-saved workouts (with a cloud-off icon badge) merged with server-fetched workouts, sorted by date descending.
- [ ] AC-13: The readiness survey submission (`POST /api/workouts/surveys/readiness/`) also falls back to local save when offline, queued for later sync.

### Offline Nutrition Logging (Confirm & Save)
- [ ] AC-14: When the trainee confirms an AI-parsed food entry (`POST /api/workouts/daily-logs/confirm-and-save/`) while offline, the parsed data is saved to the `pending_nutrition_logs` Drift table with the `parsed_data` JSON and target `date`.
- [ ] AC-15: After saving offline nutrition, the trainee sees a success snackbar: "Food entry saved locally. It will sync when you're back online."
- [ ] AC-16: The nutrition screen shows locally-saved entries (with a cloud-off icon badge) alongside server-fetched entries, so the trainee's macro totals reflect pending entries optimistically.

### Offline Weight Check-In
- [ ] AC-17: When the trainee submits a weight check-in (`POST /api/workouts/weight-checkins/`) while offline, the data is saved to `pending_weight_checkins` with `date`, `weight_kg`, and `notes`.
- [ ] AC-18: The weight trends screen shows locally-saved check-ins (with a cloud-off icon badge) merged with server data.

### Program Caching
- [ ] AC-19: When programs are fetched successfully online (`GET /api/workouts/programs/`), the full program list (including schedules) is cached in the `cached_programs` Drift table, keyed by trainee user ID.
- [ ] AC-20: When the programs API call fails due to no network, the app falls back to the cached programs from Drift. The UI shows a subtle banner: "Showing cached program. Some data may be outdated."
- [ ] AC-21: Cached program data is refreshed every time the programs endpoint returns successfully. Old cache entries are overwritten (not appended).
- [ ] AC-22: The active workout screen works fully offline when the program schedule is cached -- the trainee can view exercises, log sets, complete the workout, and save locally.

### Sync Queue
- [ ] AC-23: The `sync_queue` Drift table stores each pending operation with: `id` (auto-increment), `operation_type` (enum: `workout_log`, `nutrition_log`, `weight_checkin`, `readiness_survey`), `payload` (JSON text), `status` (enum: `pending`, `syncing`, `synced`, `failed`), `created_at`, `synced_at` (nullable), `retry_count` (default 0), `last_error` (nullable text).
- [ ] AC-24: A `SyncQueueService` processes the queue in FIFO order (oldest first) when connectivity is restored. Each item is processed sequentially (not in parallel) to avoid race conditions on `DailyLog` records.
- [ ] AC-25: Each sync attempt: set status to `syncing`, call the appropriate API endpoint, on success set status to `synced` and `synced_at`, on failure increment `retry_count` and set `last_error`.
- [ ] AC-26: Items that fail 3 times are set to status `failed` and skipped. The user is notified via a persistent banner on the home screen: "1 item failed to sync. Tap to retry."
- [ ] AC-27: Tapping the failed-sync banner opens a bottom sheet listing failed items with: operation type, date, error message, and "Retry" / "Delete" buttons per item.
- [ ] AC-28: Successfully synced items (`status = synced`) are deleted from the local database after 24 hours (cleanup runs on app startup).
- [ ] AC-29: The sync queue processes items even when the app is in the foreground but the user is on a different screen (the service runs independently of navigation state).

### Conflict Resolution
- [ ] AC-30: If a workout sync fails with HTTP 409 (conflict -- e.g., trainer changed the program), the sync queue marks the item as `failed` with error "Program was updated by your trainer. Please review." and does NOT retry automatically.
- [ ] AC-31: If a nutrition sync fails with HTTP 409, same behavior as AC-30 with message "Nutrition data was updated. Please review."
- [ ] AC-32: For non-conflict server errors (500, 502, 503), the sync queue retries up to 3 times with exponential backoff (5s, 15s, 45s delay between retries).

### Visual Indicators
- [ ] AC-33: When the device is offline, a thin persistent banner appears at the top of every trainee screen (below the app bar): amber background, "You are offline" text, cloud-off icon. Height: 28px. Does not push content down aggressively.
- [ ] AC-34: When sync is actively processing, the banner changes to: blue background, "Syncing..." text with a small linear progress indicator, cloud-upload icon.
- [ ] AC-35: When all items are synced, the banner briefly shows green "All changes synced" for 3 seconds, then disappears.
- [ ] AC-36: Items that were saved offline but not yet synced show a small `Icons.cloud_off` badge (12px, amber) overlaid on their card/tile in lists.
- [ ] AC-37: Items that are currently syncing show a small `Icons.cloud_upload` badge (12px, blue) with a rotating animation.
- [ ] AC-38: Items that failed to sync show a small `Icons.cloud_off` badge (12px, red) with a warning indicator.

### Performance & Cleanup
- [ ] AC-39: The Drift database connection is opened lazily (on first access) and closed on app termination.
- [ ] AC-40: Sync queue items older than 7 days with status `synced` are auto-deleted on app startup.
- [ ] AC-41: Cached programs older than 30 days are auto-deleted on app startup.
- [ ] AC-42: Database operations (reads and writes) run on isolates via Drift's built-in isolate support to avoid janking the UI thread.

---

## Edge Cases

1. **Double-submit prevention:** Trainee completes a workout offline, the app saves it locally, then connectivity returns before the trainee navigates away. The sync queue picks it up and syncs. But what if the workout screen's `_submitPostWorkoutSurvey` also fires when connectivity flickers? The sync queue must use idempotency: each pending item gets a UUID `client_id`. Before adding to the queue, check if an item with the same `client_id` already exists. The backend should also be tolerant of duplicate `DailyLog` session entries (the existing `get_or_create` + `sessions` append pattern handles this, but duplicate session names + timestamps should be detected and deduplicated).

2. **App killed while workout in progress offline:** If the user force-kills the app mid-workout (before hitting "Finish"), the in-progress exercise data is lost (same as online behavior -- we do not auto-save mid-workout in this phase). The readiness survey, if already submitted, is queued. This is acceptable; mid-workout auto-save is a future enhancement.

3. **Trainee opens app after 3 days offline:** The cached program may be stale. When connectivity returns, the sync queue processes old items, then the app fetches fresh programs. If a program was changed by the trainer during the offline period, the trainee sees the new program after sync. Old workouts logged against the previous program schedule are still valid (they reference exercise IDs and names, not the schedule structure).

4. **Multiple workouts logged offline for the same day:** The backend's `_save_workout_to_daily_log` already handles multiple sessions per day via the `sessions` list append pattern. The sync queue processes them in order, so each session is appended correctly. The `client_id` UUID prevents duplicates.

5. **Nutrition logged offline then the same meal logged online (duplicate):** Each nutrition confirm-and-save is an independent operation on the backend (it creates or appends to the day's `nutrition_data`). The sync queue sends the offline entry, which appends to whatever is already on the server. This may result in apparent duplicates if the user logged the same food twice. This is acceptable -- the user can delete duplicates via the existing edit/delete food entry UI.

6. **Connectivity flapping (rapid on/off/on):** The `ConnectivityService` should debounce connectivity changes with a 2-second delay before triggering sync. This prevents the sync queue from starting and immediately failing when connectivity is unstable.

7. **Sync queue has 50+ items after extended offline period:** The queue processes items sequentially with no artificial limit. Each item takes roughly 1-3 seconds to sync. A 50-item queue takes 1-2 minutes. The sync banner shows progress ("Syncing 5 of 50..."). The user can continue using the app normally during sync.

8. **User logs out while items are pending sync:** On logout, warn the user: "You have X unsaved changes that haven't synced yet. Logging out will lose this data. Continue?" If they confirm, clear the local database for that user. If they cancel, stay logged in.

9. **Different user logs in on same device:** The Drift database tables include a `user_id` column. When a new user logs in, they only see their own pending items. Old user's synced items are cleaned up, but pending items for other users are preserved (they'll sync when that user logs back in). Actually, for simplicity in V1: on logout, warn about pending items and delete all local data for that user if they confirm.

10. **Server returns 401 during sync (token expired):** The existing Dio interceptor handles token refresh. If refresh also fails (e.g., refresh token expired), the sync queue pauses and the app redirects to login. Pending items remain in the database and will resume syncing after the user logs back in.

11. **Device storage full (SQLite write fails):** Drift operations that throw `SqliteException` with "database or disk is full" should be caught. Show a snackbar: "Device storage is full. Free up space to save workout data." The workout data is lost in this case (same as if the API call failed with no fallback).

12. **Timezone edge case:** A workout started at 11:55 PM and finished at 12:05 AM (date boundary). The `created_at` uses the timestamp when the workout was completed (12:05 AM), so it goes to the next day's DailyLog. This matches the existing online behavior since `timezone.now().date()` is evaluated at save time on the backend. The local save should use the same date the backend would use -- the date at the time of completion.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Workout complete while offline | Success screen + amber banner "Workout saved locally. It will sync when you're back online." | Save to `pending_workout_logs` + add to `sync_queue` |
| Nutrition confirm while offline | Green snackbar "Food entry saved locally. It will sync when you're back online." | Save to `pending_nutrition_logs` + add to `sync_queue` |
| Weight check-in while offline | Green snackbar "Weight saved locally. It will sync when you're back online." | Save to `pending_weight_checkins` + add to `sync_queue` |
| Programs API fails (no network) | Program screen loads from cache + subtle banner "Showing cached program. Some data may be outdated." | Read from `cached_programs` Drift table |
| Programs API fails (no cache) | Empty state: "No program data available. Connect to the internet to load your program." with retry button | Show error state, no fallback |
| Sync fails after 3 retries | Persistent banner on home: "1 item failed to sync. Tap to retry." | Set sync_queue status to `failed`, stop retrying |
| Sync fails with 409 conflict | Failed item banner with message: "Program was updated by your trainer. Please review." | Set to `failed`, do not auto-retry |
| Device storage full on save | Snackbar: "Device storage is full. Free up space to save your data." | Catch SqliteException, do not save |
| User logs out with pending items | Dialog: "You have X unsaved changes. Logging out will lose this data." with Cancel/Continue buttons | If continue: clear user's local data. If cancel: stay logged in |
| Sync in progress when app backgrounded | Sync continues if within ~30 seconds (iOS) | Platform-dependent background execution limits apply |

---

## UX Requirements

### Offline Banner
- **Position:** Fixed at top of Scaffold body, below AppBar, above all other content.
- **Offline state:** Amber/orange background (#F59E0B at 15% opacity), cloud_off icon (amber), "You are offline" text in bodySmall, 28px height.
- **Syncing state:** Blue background (#3B82F6 at 15% opacity), cloud_upload icon (blue), "Syncing..." text + 2px LinearProgressIndicator, 28px height.
- **Synced state:** Green background (#22C55E at 15% opacity), cloud_done icon (green), "All changes synced" text, auto-dismiss after 3 seconds with fade animation.
- **Animation:** SlideTransition from top (200ms) on appear, FadeTransition (300ms) on dismiss.
- **Accessibility:** Semantics liveRegion so screen readers announce state changes.

### Sync Status Badges
- **Badge position:** Bottom-right corner of the card/tile, 4px offset inward.
- **Badge size:** 16x16px container with 12px icon.
- **Pending (not yet synced):** `Icons.cloud_off`, amber (#F59E0B).
- **Syncing:** `Icons.cloud_upload`, blue (#3B82F6), rotating animation (1s loop).
- **Failed:** `Icons.error_outline`, red (#EF4444).
- **Synced:** No badge (the item is now server-authoritative).

### Failed Sync Bottom Sheet
- **Trigger:** Tapping the persistent "X items failed to sync" banner.
- **Content:** DraggableScrollableSheet with list of failed items. Each item shows: icon for type (fitness_center for workouts, restaurant for nutrition, monitor_weight for weight), description ("Push Day workout from Feb 15"), error message in bodySmall red text, "Retry" outlined button (blue), "Delete" text button (red).
- **Empty state:** If all items are retried/deleted, sheet auto-closes.
- **Retry behavior:** Individual retry immediately attempts sync. If successful, item disappears from list with slide animation.

### Logout Warning
- **Trigger:** User taps logout while `sync_queue` has items with status `pending` or `failed`.
- **Dialog:** AlertDialog, title "Unsaved Changes", body "You have X workout(s) and Y nutrition entry/entries that haven't synced to the server yet. Logging out will permanently delete this data.", actions: "Cancel" (TextButton), "Logout Anyway" (TextButton, red text).
- **No pending items:** Normal logout flow (no dialog).

### Active Workout Screen (Offline)
- **No behavioral change.** The workout screen works identically offline (all state is local during the workout). The only difference is at submission: the data goes to Drift instead of the API.
- **Post-workout survey screen:** After survey submit, if offline, show the offline success banner before popping back.

### Home Screen
- **Recent Workouts:** Merge server workouts + local pending workouts. Local pending workouts appear at the top (most recent). Each local workout card has the cloud-off badge.
- **Nutrition section:** Macro circle values include locally-saved nutrition entries (optimistic addition to consumed values).

### Loading State
- **Drift DB init:** Happens during app startup (splash screen). No additional loading indicator needed (Drift opens fast, <100ms).
- **Sync processing:** Only the sync banner indicates activity. No blocking modal or full-screen loader.

### Empty State
- **No cached program + offline:** Card with cloud_off icon, "No program data available. Connect to the internet to load your program." + "Retry" button (which re-checks connectivity and attempts fetch).

### Success State
- **Workout saved offline:** Full-screen success with checkmark animation (same as online), plus the amber offline banner text.
- **Nutrition saved offline:** Snackbar with cloud_off icon prefix.
- **Weight saved offline:** Snackbar with cloud_off icon prefix.
- **Sync complete:** Green banner "All changes synced" for 3 seconds.

### Mobile/Responsive Behavior
- **Offline banner** is full-width, respects safe area insets.
- **Sync badges** scale with card size (stay proportional).
- **Failed sync bottom sheet** is 50% initial height, 90% max, handles keyboard if any input were added.

---

## Technical Approach

### New Files to Create

#### Core Database Layer
1. **`mobile/lib/core/database/app_database.dart`** -- Drift database class with all table definitions. Tables: `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`, `CachedPrograms`, `SyncQueueItems`. Uses `@DriftDatabase(tables: [...])` annotation. Includes typed DAOs for each table.
2. **`mobile/lib/core/database/tables.dart`** -- Drift table definitions as separate classes. Each table has proper column types, defaults, and constraints.
3. **`mobile/lib/core/database/daos/sync_queue_dao.dart`** -- DAO for sync queue operations: `insertItem()`, `getNextPending()`, `markSyncing()`, `markSynced()`, `markFailed()`, `getPendingCount()`, `getFailedItems()`, `deleteOldSynced()`, `retryFailed()`, `deleteItem()`.
4. **`mobile/lib/core/database/daos/workout_cache_dao.dart`** -- DAO for workout cache and pending workout operations.
5. **`mobile/lib/core/database/daos/nutrition_cache_dao.dart`** -- DAO for pending nutrition operations.
6. **`mobile/lib/core/database/daos/program_cache_dao.dart`** -- DAO for cached program operations.

#### Connectivity Service
7. **`mobile/lib/core/services/connectivity_service.dart`** -- `ConnectivityService` class that wraps `connectivity_plus`. Exposes a `Stream<ConnectivityStatus>` (enum: `online`, `offline`). Debounces transitions by 2 seconds to handle flapping. Provides a synchronous `isOnline` getter for point-in-time checks.

#### Sync Engine
8. **`mobile/lib/core/services/sync_service.dart`** -- `SyncService` that orchestrates the queue. Listens to connectivity changes. When online: pulls next pending item from `SyncQueueDao`, sets to `syncing`, dispatches to the correct API endpoint based on `operation_type`, handles success/failure. Implements exponential backoff for retries (5s, 15s, 45s). Exposes a `syncStatusStream` for the UI banner.
9. **`mobile/lib/core/services/sync_status.dart`** -- Data classes: `SyncStatus` enum (`idle`, `syncing`, `allSynced`, `hasFailed`), `SyncProgress` (current item, total items), `FailedSyncItem` model.

#### Offline-Aware Repositories
10. **`mobile/lib/core/database/offline_workout_repository.dart`** -- Wraps `WorkoutRepository` with offline fallback. `submitPostWorkoutSurvey()`: tries API first; on network error, saves to Drift + sync queue. `submitReadinessSurvey()`: same pattern. `getPrograms()`: tries API first; on success, caches in Drift; on failure, reads from Drift cache.
11. **`mobile/lib/core/database/offline_nutrition_repository.dart`** -- Wraps nutrition operations with offline fallback. `confirmAndSave()`: tries API first; on network error, saves to Drift + sync queue.
12. **`mobile/lib/core/database/offline_weight_repository.dart`** -- Wraps weight check-in with offline fallback.

#### UI Components
13. **`mobile/lib/shared/widgets/offline_banner.dart`** -- `OfflineBanner` widget. Consumes `connectivityProvider` and `syncStatusProvider`. Renders the appropriate banner state (offline, syncing, synced, hidden). Uses `AnimatedSwitcher` for transitions.
14. **`mobile/lib/shared/widgets/sync_status_badge.dart`** -- `SyncStatusBadge` widget. Takes a `SyncItemStatus` enum and renders the appropriate icon badge at the designated position.
15. **`mobile/lib/shared/widgets/failed_sync_sheet.dart`** -- `FailedSyncSheet` bottom sheet widget. Lists failed items from `SyncQueueDao`, provides retry/delete per item.

#### Providers
16. **`mobile/lib/core/providers/database_provider.dart`** -- Riverpod provider for the Drift database singleton.
17. **`mobile/lib/core/providers/connectivity_provider.dart`** -- Riverpod `StreamProvider<ConnectivityStatus>` wrapping `ConnectivityService`.
18. **`mobile/lib/core/providers/sync_provider.dart`** -- Riverpod providers for `SyncService`, `syncStatusProvider` (stream of SyncStatus), `pendingSyncCountProvider`, `failedSyncItemsProvider`.

### Existing Files to Modify

#### pubspec.yaml
19. **`mobile/pubspec.yaml`** -- Add `connectivity_plus: ~6.0.0` to dependencies. `drift`, `sqlite3_flutter_libs`, `path_provider`, and `path` are already listed. Add `uuid: ~4.0.0` for client-side idempotency keys.

#### Repositories (Wrap with Offline Layer)
20. **`mobile/lib/features/workout_log/data/repositories/workout_repository.dart`** -- No changes to this file. The offline layer wraps it externally.
21. **`mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`** -- Change `workoutRepositoryProvider` to use `OfflineWorkoutRepository` instead of `WorkoutRepository`. Add `programsProvider` that uses the offline-aware programs fetcher.
22. **`mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart`** -- No changes to this file. The offline layer wraps it externally.
23. **`mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart`** -- Change to use `OfflineNutritionRepository`.

#### Screens (Add Offline Banner + Badges)
24. **`mobile/lib/features/home/presentation/screens/home_screen.dart`** -- Add `OfflineBanner` widget at top of body. Modify `_buildRecentWorkoutsSection` to merge local pending workouts with server data. Add sync badge to local workout cards. Add failed-sync banner if any items have `failed` status.
25. **`mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart`** -- Modify `_submitPostWorkoutSurvey()` to use `OfflineWorkoutRepository`. On offline save, show success with offline banner text. Modify `_submitReadinessSurvey()` similarly.
26. **`mobile/lib/features/workout_log/presentation/screens/post_workout_survey_screen.dart`** -- Add offline success messaging after survey submission.
27. **`mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`** -- Add `OfflineBanner` widget. Show sync badges on locally-saved entries. Merge local pending nutrition data into macro totals.
28. **`mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart`** -- Use `OfflineWeightRepository` for submissions.
29. **`mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart`** -- Merge local pending weight check-ins into the trend chart.
30. **`mobile/lib/features/logging/presentation/screens/ai_command_center_screen.dart`** -- Note: AI parsing requires network by design (it calls OpenAI). The confirm-and-save step uses `OfflineNutritionRepository`. If AI parsing fails due to no network, show: "AI food parsing requires an internet connection. Connect to parse your input."
31. **`mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart`** -- Add `OfflineBanner` to the workout log screen. Show cached program data when offline.

#### App Initialization
32. **`mobile/lib/main.dart`** (or equivalent app entry point) -- Initialize `AppDatabase`, `ConnectivityService`, and `SyncService` during app startup. Register providers. Run cleanup (delete old synced items, delete stale caches).

#### Auth (Logout Warning)
33. **`mobile/lib/features/auth/presentation/providers/auth_provider.dart`** -- Modify logout to check pending sync count first. If > 0, show warning dialog. On confirmed logout, call `AppDatabase.clearUserData(userId)`.

### Code Generation
After creating Drift tables and DAOs, run:
```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

### Dependencies Summary
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `drift` | ~2.14.1 | SQLite ORM for local DB | Already in pubspec |
| `sqlite3_flutter_libs` | ~0.5.18 | Native SQLite binaries | Already in pubspec |
| `drift_dev` | ~2.14.1 | Code generation for Drift | Already in dev_dependencies |
| `path_provider` | ~2.1.1 | App documents directory | Already in pubspec |
| `path` | ~1.8.3 | Path joining | Already in pubspec |
| `connectivity_plus` | ~6.0.0 | Network status monitoring | **New -- add to pubspec** |
| `uuid` | ~4.0.0 | Idempotency keys for sync queue | **New -- add to pubspec** |

---

## Out of Scope
- Offline AI natural language parsing (requires OpenAI API -- network required by nature)
- Offline support for trainer/admin features (trainer dashboard, admin dashboard)
- Offline support for the web dashboard (Next.js)
- Background sync when the app is fully closed (requires platform-specific background execution -- iOS BGTaskScheduler / Android WorkManager)
- HealthKit / Health Connect integration (Phase 6 item but separate ticket)
- App performance audit / RepaintBoundary optimization (Phase 6 item but separate ticket)
- Full offline-first architecture for every feature (only workout, nutrition, and weight logging)
- Mid-workout auto-save (saving exercise progress before hitting "Finish")
- Offline exercise video/image caching
- Conflict resolution UI for merging diverged data (V1 uses simple last-write-wins for most cases, with explicit failure for true conflicts)

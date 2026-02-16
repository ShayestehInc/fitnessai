# Architecture Review: Offline-First Workout & Nutrition Logging with Sync Queue (Pipeline 15)

## Review Date: 2026-02-15

## Files Reviewed

### New Files
- `mobile/lib/core/database/tables.dart`
- `mobile/lib/core/database/app_database.dart`
- `mobile/lib/core/database/daos/sync_queue_dao.dart`
- `mobile/lib/core/database/daos/workout_cache_dao.dart`
- `mobile/lib/core/database/daos/nutrition_cache_dao.dart`
- `mobile/lib/core/database/daos/program_cache_dao.dart`
- `mobile/lib/core/database/offline_workout_repository.dart`
- `mobile/lib/core/database/offline_nutrition_repository.dart`
- `mobile/lib/core/database/offline_weight_repository.dart`
- `mobile/lib/core/database/offline_save_result.dart`
- `mobile/lib/core/services/connectivity_service.dart`
- `mobile/lib/core/services/sync_service.dart`
- `mobile/lib/core/services/sync_status.dart`
- `mobile/lib/core/services/network_error_utils.dart` (created during review)
- `mobile/lib/core/providers/database_provider.dart`
- `mobile/lib/core/providers/connectivity_provider.dart`
- `mobile/lib/core/providers/sync_provider.dart`
- `mobile/lib/shared/widgets/offline_banner.dart`
- `mobile/lib/shared/widgets/sync_status_badge.dart`
- `mobile/lib/shared/widgets/failed_sync_sheet.dart`

### Modified Files
- `mobile/lib/main.dart`
- `mobile/lib/features/home/presentation/screens/home_screen.dart`
- `mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart`
- `mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`
- `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`
- `mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart`
- `mobile/lib/features/logging/presentation/providers/logging_provider.dart`
- `mobile/lib/features/logging/presentation/screens/ai_command_center_screen.dart`
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `mobile/pubspec.yaml`

---

## Architectural Alignment

- [x] Follows existing layered architecture (Repository -> Provider -> Screen)
- [x] Models/schemas in correct locations (`core/database` for Drift, `core/services` for business logic)
- [x] No business logic in views -- offline decision-making is in repositories/services
- [x] Consistent with existing patterns (Riverpod providers, Dio-based networking)
- [x] Decorator/wrapper pattern for offline repositories is architecturally sound

---

## Overall Assessment

The offline-first implementation is well-designed at the architectural level. The decorator pattern for offline repositories (OfflineWorkoutRepository wrapping WorkoutRepository, etc.) is the correct approach -- it preserves the existing API contracts, avoids modifying online-only code paths, and makes the offline behavior removable or replaceable without cascading changes. The separation of concerns across database layer (Drift tables + DAOs), services (ConnectivityService, SyncService), and providers (Riverpod) is clean and follows the project's established patterns.

### Layering Evaluation

**Strengths:**
1. The offline repositories sit cleanly between the providers and the online repositories, acting as a transparent interception layer. The online repositories are completely unmodified.
2. ConnectivityService encapsulates `connectivity_plus` details and exposes a simplified `ConnectivityStatus` enum. The rest of the app never touches `connectivity_plus` directly.
3. SyncService is self-contained -- it manages its own lifecycle, listens to connectivity changes, and processes the queue independently of navigation state (AC-29).
4. The DAO-per-table pattern (SyncQueueDao, WorkoutCacheDao, etc.) keeps database access organized and testable.
5. `OfflineSaveResult` typed result class demonstrates proper "no dict returns" adherence for save operations.

---

## Issues Found & Fixed

### 1. MAJOR -- Non-atomic local save operations
**Files:** `offline_workout_repository.dart`, `offline_nutrition_repository.dart`, `offline_weight_repository.dart`
**Issue:** All three `_saveLocally` methods performed two sequential inserts -- one to the pending data table and one to the sync queue table -- without transaction wrapping. If the sync queue insert failed (e.g., UNIQUE constraint violation on clientId race, disk full between operations), the pending data would be orphaned with no corresponding sync queue entry to trigger its eventual upload.
**Fix:** Wrapped both inserts in `_db.transaction()` in all three repositories. Now either both succeed or both roll back.

### 2. MAJOR -- Non-atomic user data cleanup
**File:** `app_database.dart` (`clearUserData`)
**Issue:** `clearUserData` performed five sequential DELETE operations across five tables without transaction wrapping. A failure mid-way through (unlikely but possible with a corrupted DB or concurrent access) would leave the user's data partially cleared -- some tables cleaned, others still containing stale data.
**Fix:** Wrapped all five deletes in `_db.transaction()`.

### 3. MAJOR -- Triple-duplicated `_isNetworkError` method
**Files:** All three offline repositories
**Issue:** The identical `_isNetworkError(DioException e)` method was copy-pasted into three files. This violates DRY and means any future change to the network error detection logic (e.g., adding a new DioExceptionType) must be replicated in three places.
**Fix:** Extracted to `core/services/network_error_utils.dart` as a shared top-level function `isNetworkError()`. All three repositories now import and call the shared function.

### 4. MODERATE -- Recursive `_processQueue` from `finally` block
**File:** `sync_service.dart`
**Issue:** When `_pendingRestart` was true, `_processQueue()` was called directly from its own `finally` block. While the `_isSyncing` guard prevents true infinite recursion, a tight loop of "sync starts, connectivity changes, pending restart set, sync ends, restart" could accumulate call stack frames.
**Fix:** Replaced `_processQueue()` with `Future.microtask(_processQueue)` in the `finally` block, which schedules the restart on the next microtask rather than as a direct recursive call. This eliminates stack depth concerns.

### 5. MODERATE -- Missing `MigrationStrategy`
**File:** `app_database.dart`
**Issue:** No `MigrationStrategy` was defined. While schemaVersion is 1 (so no migrations are needed yet), the absence means: (a) no `onCreate` hook for initial setup, (b) no `beforeOpen` hook for pragmas like WAL mode, and (c) no skeleton for future schema changes. Drift's default behavior creates tables but doesn't set pragmas.
**Fix:** Added explicit `MigrationStrategy` with `onCreate` (calls `m.createAll()`), a skeleton `onUpgrade` with comments for future migrations, and `beforeOpen` that enables WAL (Write-Ahead Logging) mode for better concurrent read/write performance on the background isolate.

### 6. MODERATE -- Missing error handling in `_getProgramsFromCache`
**File:** `offline_workout_repository.dart`
**Issue:** `_getProgramsFromCache()` called `jsonDecode(cached.programsJson)` and `ProgramModel.fromJson(json)` without catching deserialization errors. Corrupted JSON in the cache (e.g., from a schema change between app versions) would throw an unhandled `FormatException`, crashing the app.
**Fix:** (Applied by linter automatically) Added `on FormatException` catch that deletes the corrupted cache and returns a clean error, and a generic catch for other deserialization failures.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | OK | First version (v1), no backward compatibility concerns |
| Migrations reversible | N/A | v1 -- MigrationStrategy skeleton added for future use |
| Indexes added for new queries | RECOMMEND | See index recommendations below |
| No N+1 query patterns | OK | DAO methods fetch exactly what's needed with WHERE clauses |
| Column types appropriate | OK | TEXT for JSON, REAL for weight, INTEGER for IDs/counts, DATETIME for timestamps |
| Nullable vs required correct | OK | `readinessSurveyJson`, `syncedAt`, `lastError` properly nullable |
| UNIQUE constraints present | OK | `clientId` UNIQUE on all relevant tables for idempotency |

### Table Design (5 tables)

**PendingWorkoutLogs:** Well-designed. `clientId` UNIQUE for idempotency, `userId` for multi-user scoping, three JSON TEXT columns for the payload parts. No unnecessary columns.

**PendingNutritionLogs:** Clean. `targetDate` as TEXT matches the API's date string format, avoiding timezone conversion issues.

**PendingWeightCheckins:** Appropriate. `weightKg` as REAL is correct for decimal precision. `notes` defaults to empty string rather than nullable, simplifying downstream handling.

**CachedPrograms:** Simple one-row-per-user design. `programsJson` stores the full serialized program list. `cachedAt` enables TTL-based cleanup.

**SyncQueueItems:** Well-structured central queue. `operationType` and `status` as TEXT strings (matching enum `.value`), `retryCount` for backoff tracking, `clientId` UNIQUE for deduplication.

### Missing Indexes (Recommendation -- not a blocker for V1)

For operational queries as data grows beyond trivial size:
- `SyncQueueItems(userId, status)` -- used by `getNextPending`, `getPendingCount`, `getUnsyncedCount`, `getFailedItems`, and both watch queries
- `SyncQueueItems(status, syncedAt)` -- used by `deleteOldSynced`
- `CachedPrograms(userId)` -- used by `getCachedPrograms` and `deleteAllForUser`
- `PendingNutritionLogs(userId, targetDate)` -- used by `getPendingNutritionForDate`

At current scale (handful of items per user), SQLite's default indexes are sufficient. Add these when the feature stabilizes.

---

## Scalability Concerns

| # | Area | Severity | Issue | Recommendation |
|---|------|----------|-------|----------------|
| 1 | Progress display | Low | `getPendingCount` runs once at sync start. New items queued during sync won't update the total in the progress banner ("Syncing 5 of 50"). | Accept for V1. The progress is informational. |
| 2 | Program cache | Low | Entire program list stored as one JSON blob. With 10+ complex programs, this could be several KB. | Acceptable. SQLite handles multi-KB TEXT columns efficiently. |
| 3 | Watch queries | Low | `watchPendingCount` and `watchFailedCount` re-fire on any `syncQueueItems` table change (Drift's table-level notification). | COUNT on indexed columns is negligible. Acceptable. |
| 4 | Startup cleanup | Low | Sequential cleanup before widget tree builds. Thousands of stale items could add to startup time. | Best-effort, non-blocking. Move to post-startup if profiling shows concern. |
| 5 | Backoff delays | Low | 45-second max delay blocks the entire queue processing loop. Other pending items that would succeed wait behind a failing item. | By-design for DailyLog race condition prevention. Acceptable tradeoff. |

---

## Riverpod Pattern Assessment

**Provider Scoping:** Correct. `databaseProvider` and `connectivityServiceProvider` use the `throw UnimplementedError` pattern, requiring override in `ProviderScope`. This is idiomatic for externally-initialized singletons.

**Lifecycle Management:** `syncServiceProvider` correctly watches `authStateProvider` and auto-creates/disposes `SyncService` on login/logout. `ref.onDispose` ensures cleanup.

**Nullable Repository Providers:** `offlineWorkoutRepositoryProvider` and `offlineWeightRepositoryProvider` return `null` when unauthenticated, correctly handled at call sites.

**Memory Leak Risk:** Low. All stream subscriptions and controllers are properly cancelled/closed in `dispose()` methods, which are triggered by `ref.onDispose`. Minor concern: `ConnectivityService` created in `main()` is not explicitly disposed on hot restart -- not a production issue.

**Watch vs Read:** Correct throughout. Reactive dependencies use `ref.watch`, one-time reads in callbacks use `ref.read`.

---

## Drift Pattern Assessment

**Code Generation:** Properly configured with `part` directives and `@DriftDatabase`/`@DriftAccessor` annotations. Tables and DAOs correctly linked.

**DAO Conventions:** Standard `DatabaseAccessor<AppDatabase>` extension with generated mixins. All queries use Drift's type-safe query builder (no raw SQL).

**Isolate Usage:** `NativeDatabase.createInBackground(file)` correctly offloads all DB I/O to a background isolate. `LazyDatabase` wrapper handles the async path_provider call.

**WAL Mode:** Added during this review in `MigrationStrategy.beforeOpen`. Enables concurrent reads during writes, important for the sync service writing while UI watches.

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `getPrograms()` and `getActiveProgram()` in `OfflineWorkoutRepository` return `Map<String, dynamic>` | Medium | Create a `ProgramFetchResult` typed class. Violates the project's "never return dict" rule from `.claude/rules/datatypes.md`. |
| 2 | String-based status/type matching in DAO queries (e.g., `t.status.equals('pending')`) | Low | Use `SyncItemStatus.pending.value` instead of `'pending'` literals. The enums exist but DAOs use raw strings. |
| 3 | `_handleLogout` logic duplicated between `home_screen.dart` and `settings_screen.dart` | Low | Extract to a shared utility or Riverpod notifier method. |
| 4 | `build_runner` and `json_serializable` in both `dependencies` and `dev_dependencies` | Low | Pre-existing. Move to `dev_dependencies` only. |
| 5 | AC-12, AC-16, AC-18 deferred (merging local data into list views and macro totals) | Medium | The infrastructure exists (DAO methods for fetching pending items) but the UI integration was deferred. Should be completed in a follow-up. |

## Technical Debt Reduced

| # | Description |
|---|-------------|
| 1 | `OfflineSaveResult` typed result class replaces `Map<String, dynamic>` for save operation returns. |
| 2 | `SyncOperationType` and `SyncItemStatus` enums centralize magic strings with `fromString()` parsers. |
| 3 | Decorator pattern leaves online repositories completely untouched -- clean separation. |
| 4 | Connectivity debouncing prevents thrashing of sync queue during unstable network. |
| 5 | `network_error_utils.dart` centralizes network error detection logic (previously triplicated). |

---

## Architecture Score: 8/10

**Rationale:** The overall architecture is sound and well-layered. The decorator pattern for offline repos is the right call. The data model is appropriate for the problem. The sync queue design (FIFO, sequential processing, exponential backoff, conflict detection) is production-quality. Points deducted for: (1) missing transactional guarantees (now fixed), (2) `Map<String, dynamic>` return types violating the project's "no dict returns" rule, and (3) deferred UI integration for AC-12/16/18.

## Recommendation: APPROVE

The architecture is solid and appropriate for V1 of offline-first capabilities. The issues found were implementation-level (missing transactions, code duplication, missing error handling) rather than fundamental architectural flaws. All critical and major issues were fixed during this review. The remaining items are low-severity technical debt documented above for follow-up.

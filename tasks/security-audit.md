# Security Audit: Health Data Integration + Performance Audit + Offline UI Polish (Pipeline 16)

**Date:** 2026-02-15
**Auditor:** Security Engineer (Senior Application Security)
**Scope:** Mobile Flutter app only -- HealthKit/Health Connect integration, offline UI merge, performance optimizations. No backend changes.

**Files Audited (New):**

- `mobile/lib/core/models/health_metrics.dart` -- Immutable health data model
- `mobile/lib/core/providers/health_provider.dart` -- Health state management and permission handling
- `mobile/lib/shared/widgets/health_card.dart` -- Health metrics display card
- `mobile/lib/shared/widgets/health_permission_sheet.dart` -- Permission request bottom sheet

**Files Audited (Modified):**

- `mobile/lib/core/services/health_service.dart` -- Health data fetching service (rewritten)
- `mobile/lib/core/providers/sync_provider.dart` -- Added syncCompletionProvider
- `mobile/lib/features/home/presentation/screens/home_screen.dart` -- Health card, pending workouts, RepaintBoundary
- `mobile/lib/features/home/presentation/providers/home_provider.dart` -- Pending workout loading
- `mobile/lib/core/database/daos/workout_cache_dao.dart` -- New alias method
- `mobile/lib/core/database/daos/nutrition_cache_dao.dart` -- New alias methods
- `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart` -- Pending nutrition/weight merge
- `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` -- Pending UI indicators
- `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart` -- Pending weight, virtualised list
- `mobile/ios/Runner/Runner.entitlements` -- HealthKit entitlement (read-only)
- `mobile/ios/Runner/Info.plist` -- Updated health usage description, removed write description
- `mobile/android/app/src/main/AndroidManifest.xml` -- Read-only health permissions, removed write permissions

---

## Executive Summary

This audit covers the Health Data Integration feature, which adds HealthKit (iOS) and Health Connect (Android) read access for steps, active calories, heart rate, and weight; the Offline UI Polish feature, which merges pending local data into visible UI lists; and a Performance Audit with RepaintBoundary and select() optimizations.

**Critical findings:**
- **No hardcoded secrets, API keys, passwords, or tokens found** across all new and modified files.
- **No health data sent to the backend** -- all health metrics (steps, calories, heart rate) remain local. The only data that reaches the server is the weight value via the existing WeightCheckIn flow, which is identical to manual entry.
- **No health data logged** -- all debug prints are wrapped in `assert()` blocks (stripped in release builds) and log only method names and error types, never raw health metric values.
- **SharedPreferences stores only boolean flags** (`health_permission_asked`, `health_permission_granted`), never health data values.
- **Health permissions are strictly read-only** -- no write access requested on either platform.
- **0 Critical issues found.**
- **0 High issues found.**
- **0 Medium issues found.**
- **2 Low / Informational issues found (documented).**

---

## Security Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No health data leaked to backend or logs
- [x] All user input sanitized (Drift parameterized queries for all DAO methods)
- [x] Health permissions are read-only (HealthDataAccess.READ for all types)
- [x] DAO queries use parameterized builder (no raw SQL anywhere)
- [x] Error messages don't leak internals (all errors are user-friendly or debug-only)
- [x] SharedPreferences stores only flags, not data

---

## Secrets Scan

### Scan Methodology

Grepped the full git diff (`HEAD~3`) and all new/modified files for:
- API keys, secret keys, passwords, tokens: `(api[_-]?key|secret|password|token|auth|bearer|credential|private[_-]?key)`
- Hardcoded URLs containing credentials: `(sk_live|pk_live|sk_test|pk_test|AKIA|AIza|ghp_|gho_|xox[bpsa])`
- Stripe, OpenAI, and other service keys: `(OPENAI|STRIPE|SK_|PK_)`

### Results: PASS

**No secrets found in any new or modified file.**

Specific observations:

1. **GIDClientID in Info.plist** (`678085268098-oiujkrm9mavo40jtpgjq9vbu0ki25nl0.apps.googleusercontent.com`) -- This is a **pre-existing** Google Sign-In OAuth client ID, not introduced by this change. iOS OAuth client IDs are public identifiers (they are embedded in the app binary and URL schemes by design). This is not a secret.

2. **No hardcoded health data values** appear anywhere in the codebase as constants, test fixtures, or default values. The `HealthMetrics.empty` factory uses `steps: 0, activeCalories: 0` which are valid zero values, not sensitive data.

---

## Health Data Privacy Audit

This is the primary security concern for this feature. Health data from HealthKit and Health Connect is subject to Apple and Google privacy policies respectively.

### Data Flow Analysis

| Data Type | Source | Stored Locally? | Sent to Backend? | Logged? |
|-----------|--------|----------------|-----------------|---------|
| Steps (int) | HealthKit / Health Connect | No -- in-memory only via Riverpod state | No | No (debug-only assert prints log method name, not value) |
| Active Calories (int) | HealthKit / Health Connect | No -- in-memory only via Riverpod state | No | No |
| Heart Rate (int?) | HealthKit / Health Connect | No -- in-memory only via Riverpod state | No | No |
| Weight (double?) | HealthKit / Health Connect | Yes -- via existing WeightCheckIn flow (same as manual entry) | Yes -- via OfflineWeightRepository (same as manual entry) | No (debug prints log date, not weight value) |
| Permission Status (bool) | User action | Yes -- SharedPreferences (two boolean flags) | No | No |

### Weight Auto-Import Analysis

The weight auto-import is the only path where health platform data reaches the backend. Analysis:

1. **What is sent:** A weight value in kg (e.g., `75.2`) and a date string (e.g., `2026-02-15`), and the notes string `"Auto-imported from Health"`.
2. **How it's sent:** Via `OfflineWeightRepository.createWeightCheckIn()`, which is the exact same code path used for manual weight entry. The backend endpoint and serializer are unchanged.
3. **What the notes field contains:** The string `"Auto-imported from Health"` -- a static label, not raw health data. The notes field does not contain the source device name, HealthKit record ID, or any other metadata from the health platform.
4. **Privacy assessment:** This is consistent with the ticket requirement ("Health data is display-only, local-only. The only exception is auto-importing weight to WeightCheckIn"). The weight value is the same type of data the user would enter manually. This does not constitute a health data privacy violation.

### SharedPreferences Audit

| Key | Type | Value Range | Contains Health Data? |
|-----|------|------------|----------------------|
| `health_permission_asked` | bool | true / false | No -- permission lifecycle flag only |
| `health_permission_granted` | bool | true / false | No -- permission status flag only |

**Assessment: PASS.** SharedPreferences stores only boolean permission flags. No health metric values (steps, calories, heart rate, weight, timestamps) are persisted in SharedPreferences.

### Debug Logging Audit

All `debugPrint` calls in `health_service.dart` and `health_provider.dart` are wrapped in `assert(() { ... return true; }())` blocks. This pattern ensures:
1. The `debugPrint` is **completely removed in release/profile builds** by the Dart compiler.
2. The logged messages contain only method names and error types, never raw health values.

Specific verification of each debug print:

| File | Line | Message Content | Leaks Health Data? |
|------|------|----------------|-------------------|
| health_service.dart | 45 | `'HealthService.requestPermissions error: $e'` | No -- error only |
| health_service.dart | 63 | `'HealthService.checkPermissionStatus error: $e'` | No -- error only |
| health_service.dart | 104 | `'HealthService.getTodaySteps error: $e'` | No -- error only |
| health_service.dart | 139 | `'HealthService.getTodayActiveCalories error: $e'` | No -- error only |
| health_service.dart | 177 | `'HealthService.getLatestHeartRate error: $e'` | No -- error only |
| health_service.dart | 218 | `'HealthService.getLatestWeight error: $e'` | No -- error only |
| health_provider.dart | 109 | `'HealthDataNotifier.checkAndRequestPermission error: $e'` | No -- error only |
| health_provider.dart | 124 | `'HealthDataNotifier.wasPermissionAsked error: $e'` | No -- error only |
| health_provider.dart | 151 | `'HealthDataNotifier.requestOsPermission error: $e'` | No -- error only |
| health_provider.dart | 168 | `'HealthDataNotifier.declinePermission error: $e'` | No -- error only |
| health_provider.dart | 197 | `'HealthDataNotifier.fetchHealthData error: $e'` | No -- error only |
| health_provider.dart | 241 | `'Health weight auto-import: skipped, pending entry exists for $todayStr'` | No -- date only, no weight value |
| health_provider.dart | 248 | `'Health weight auto-import: pending check failed: $e'` | No -- error only |
| health_provider.dart | 269 | `'Health weight auto-import skipped: ${result.error}'` | No -- error message only |
| health_provider.dart | 276 | `'Health weight auto-import error: $e'` | No -- error only |

**Assessment: PASS.** No health data values are logged, even in debug mode.

---

## Platform Permissions Audit

### iOS

**Runner.entitlements:**
```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

- `com.apple.developer.healthkit` = `true` enables HealthKit capability.
- `com.apple.developer.healthkit.access` = empty array means **read-only access**. No clinical or write capabilities are declared.
- `NSHealthShareUsageDescription` (read) is present with a clear description.
- `NSHealthUpdateUsageDescription` (write) has been **removed**. This is correct for read-only access.

**Assessment: PASS.** iOS permissions are minimal and read-only.

### Android

**AndroidManifest.xml health permissions:**
```xml
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_WEIGHT"/>
```

- All four permissions are **READ-only**.
- No `WRITE_*` permissions are declared.
- Previously present `WRITE_STEPS`, `WRITE_HEART_RATE`, and `READ_SLEEP` permissions have been **removed**.

**Assessment: PASS.** Android permissions are minimal and read-only. Only the four data types displayed on the health card are requested.

### Dart Code Permission Request

In `health_service.dart:34-41`:
```dart
final permissions = List<HealthDataAccess>.filled(
  _requestedTypes.length,
  HealthDataAccess.READ,
);
return await _health.requestAuthorization(
  _requestedTypes,
  permissions: permissions,
);
```

All permission types are `HealthDataAccess.READ`. The `_requestedTypes` list contains exactly four types: `STEPS`, `ACTIVE_ENERGY_BURNED`, `HEART_RATE`, `WEIGHT`. No write access is requested at the Dart level either.

**Assessment: PASS.** Permission requests are consistent across all three layers (platform config, Dart code).

---

## Injection & Data Handling

### SQL Injection: PASS

All new DAO methods use Drift's parameterized query builder:
- `workout_cache_dao.dart:54` -- `getPendingWorkoutsForUser(int userId)` delegates to `getPendingWorkouts(userId)` which uses `t.userId.equals(userId)` (parameterized).
- `nutrition_cache_dao.dart:52-56` -- `getPendingNutritionForUser(int userId, String date)` delegates to `getPendingNutritionForDate` which uses `t.userId.equals(userId) & t.targetDate.equals(date)` (parameterized).
- `nutrition_cache_dao.dart:103-104` -- `getPendingWeightForUser(int userId)` delegates to `getPendingWeightCheckins` which uses `t.userId.equals(userId)` (parameterized).

No raw SQL (`rawQuery`, `rawInsert`, `rawUpdate`, `rawDelete`, `customStatement`, `customSelect`) exists in any DAO file.

### JSON Parsing: PASS

All JSON parsing in new code is wrapped in try-catch:
- `home_provider.dart:316-324` -- `jsonDecode(row.workoutSummaryJson)` wrapped in try-catch, falls back to "Unknown Workout" on failure.
- `nutrition_provider.dart:396-418` -- `jsonDecode(row.parsedDataJson)` wrapped in try-catch per row, skips corrupted entries.
- No `jsonDecode` in health provider or health service (health data is returned as typed objects from the `health` package, not raw JSON).

### URL Launcher: PASS

The `_openHealthSettings()` method in `health_card.dart` calls `launchUrl()` with a URI from `HealthService.healthSettingsUri`. This is a static getter that returns one of two hardcoded URIs:
- iOS: `x-apple-health://`
- Android: `content://com.google.android.apps.healthdata`

There is no user-controlled input in the URI construction. No path traversal or URI injection is possible.

---

## Auth & Authorization

### Health Permission Flow

| Step | Security Check | Status |
|------|---------------|--------|
| Permission asked once | `health_permission_asked` flag in SharedPreferences | Correct -- prevents re-prompting |
| Permission denied respected | State set to `HealthDataPermissionDenied`, card hidden | Correct |
| OS permission result persisted | `health_permission_granted` flag stored | Correct |
| Permission revocation handled | `HealthService` returns null/zero for revoked types, card shows "--" | Correct |

### Data Access Authorization

Health data is accessed from the local HealthKit/Health Connect store, which is protected by the OS permission system. The app does not access health data from any backend API.

For the offline merge features (pending workouts, nutrition, weight), all DAO queries filter by `userId` from the authenticated session, maintaining the existing data isolation pattern established in Pipeline 15.

---

## Data Exposure

### Error Messages

| Context | Error Message | Leaks Internals? |
|---------|--------------|------------------|
| Health permission denied | No visible error (card hidden) | No |
| Health data fetch throws | No visible error (card hidden, graceful degradation) | No |
| Partial health data | Card shows "--" for missing metrics | No |
| Platform doesn't support health | No visible error (card hidden) | No |
| Auto-import weight fails | No visible error (silent failure) | No |
| Pending workout corrupted JSON | Shows "Unknown Workout" placeholder | No |
| Pending nutrition DB query fails | Server-only data shown, no error | No |
| URL launch failure (gear icon) | Silent catch, no user feedback | No |

**Assessment: PASS.** No error messages expose health data, internal state, stack traces, or implementation details.

---

## Issues Found

### Critical Issues: 0

None.

### High Issues: 0

None.

### Medium Issues: 0

None.

### Low / Informational Issues: 2

| # | Severity | File:Line | Issue | Fix | Status |
|---|----------|-----------|-------|-----|--------|
| L-1 | Low | `health_service.dart:2,230` | **`dart:io Platform.isIOS` used in static getter.** The `healthSettingsUri` getter imports `dart:io` and uses `Platform.isIOS` which would throw on Flutter web. However, this entire feature (HealthKit/Health Connect) is inherently mobile-only and will never run on web. The `health` package itself depends on `dart:io`. The permission sheet was correctly fixed to use `Theme.of(context).platform`, but the service layer cannot access `BuildContext`. | No fix needed -- the health service is mobile-only by nature. If Flutter web support is added in the future, the health service should be conditionally imported. | Documented |
| L-2 | Low | `health_provider.dart:89,120,138,162` | **SharedPreferences instance obtained multiple times.** Each method call to `checkAndRequestPermission()`, `wasPermissionAsked()`, `requestOsPermission()`, and `declinePermission()` calls `SharedPreferences.getInstance()` independently. While `SharedPreferences.getInstance()` returns a cached singleton after the first call (so there is no performance or correctness issue), a cleaner pattern would be to inject the SharedPreferences instance via the constructor. This is a code quality observation, not a security issue. | No fix needed -- functionally correct. Consider constructor injection in a future refactor. | Documented |

---

## Concurrency & Race Condition Analysis

### Weight Auto-Import Race Condition

The ticket identifies a potential race condition (Edge Case 4): "User manually enters weight while auto-import runs concurrently."

**Analysis of protection:**

1. **Local dedup (health_provider.dart:233-245):** Before auto-importing, the code queries `nutritionCacheDao.getPendingWeightCheckins()` and checks if any pending entry has today's date. If so, it skips the import.

2. **Server dedup:** If online, `OfflineWeightRepository.createWeightCheckIn()` calls the backend API, which returns an error if a check-in already exists for today (409 or validation error). The auto-import silently handles this failure.

3. **mounted guards (health_provider.dart:190,200,236,255):** Multiple `if (!mounted) return;` guards prevent state mutations on disposed notifiers after async gaps.

4. **Awaited auto-import (health_provider.dart:194):** `_autoImportWeight(metrics)` is `await`ed inside the existing try-catch, not fire-and-forget. This was a critical fix applied in Round 1.

**Assessment: PASS.** The race condition is properly protected by both local dedup and server dedup.

### Sync Completion Reactivity

The `syncCompletionProvider` stream is listened to by all three screens (home, nutrition, weight trends) to reload pending data when sync completes. This ensures badges disappear reactively without a manual refresh.

**Assessment: PASS.** No race conditions in the sync completion notification flow.

---

## Dependency Analysis

No new dependencies were added by this feature. All used packages (`health`, `shared_preferences`, `url_launcher`, `intl`) are pre-existing in `pubspec.yaml`.

| Package | Usage in Feature | Known CVEs | Status |
|---------|-----------------|-----------|--------|
| `health` (^13.2.1) | HealthKit/Health Connect read access | None known as of audit date | Acceptable |
| `shared_preferences` (^2.2.2) | Permission state persistence (boolean flags only) | None known as of audit date | Acceptable |
| `url_launcher` (^6.2.4) | Open health app settings | None known as of audit date | Acceptable |
| `intl` (^0.20.2) | Number formatting (thousands separators) | None known as of audit date | Acceptable |

---

## Security Strengths of This Implementation

1. **Health data stays local.** Steps, active calories, and heart rate never leave the device. They exist only in Riverpod in-memory state and are garbage collected when the widget is disposed.

2. **Read-only permissions enforced at three layers.** Platform config files (entitlements, manifest), Dart permission request code, and the absence of any health write API calls all enforce read-only access.

3. **No health data in SharedPreferences.** Only boolean flags for permission state are persisted. No metric values, timestamps, or health record IDs are stored.

4. **No health data in debug logs.** All `debugPrint` calls are wrapped in `assert()` (release-stripped) and log only method names and error types, never health metric values.

5. **Weight auto-import uses existing save path.** The auto-imported weight goes through the same `OfflineWeightRepository.createWeightCheckIn()` as manual entry, inheriting all existing validation, auth, and dedup logic.

6. **Notes field is a static string.** The auto-import notes ("Auto-imported from Health") is a hardcoded label, not derived from health platform metadata. No HealthKit record IDs, source device names, or sample UUIDs leak into the notes.

7. **Mounted guards prevent use-after-dispose.** Every async gap in `HealthDataNotifier` is followed by an `if (!mounted) return;` guard, preventing state mutations on disposed notifiers.

8. **HealthService is injectable for testing.** The constructor accepts an optional `Health` instance, enabling unit tests to mock the health platform without touching real HealthKit/Health Connect data.

9. **Sealed class state ensures exhaustive handling.** The `HealthDataState` sealed class hierarchy guarantees that every state (initial, loading, loaded, denied, unavailable) is handled by the UI via pattern matching.

10. **DAO queries maintain userId isolation.** All new alias methods delegate to existing userId-filtered queries, maintaining the data isolation established in Pipeline 15.

---

## Security Score: 9.5/10

**Breakdown:**
- **Health Data Privacy:** 10/10 (no health data sent to backend, logged, or persisted in SharedPreferences)
- **Platform Permissions:** 10/10 (read-only on iOS and Android, write permissions removed)
- **Secrets Management:** 10/10 (no secrets in code or config changes)
- **Input Validation:** 10/10 (Drift parameterized queries, JSON parsing with try-catch)
- **Error Handling:** 10/10 (no information leakage, graceful degradation)
- **Injection Prevention:** 10/10 (no raw SQL, no user-controlled URIs)
- **Data Isolation:** 10/10 (userId filtering on all DAO queries)
- **Concurrency:** 9/10 (race conditions properly handled with dedup and mounted guards)
- **Debug Logging:** 10/10 (all debug prints assert-wrapped, no health values logged)
- **Dependencies:** 9/10 (no new deps, all existing deps are mainstream with no known CVEs)

**Deductions:**
- -0.5: Minor code quality items (L-1, L-2) documented but not security-impacting

---

## Recommendation: PASS

**Verdict:** The Health Data Integration, Offline UI Polish, and Performance Audit features are **secure for production**. No Critical, High, or Medium issues exist. The implementation correctly enforces read-only health permissions, keeps health metrics local (except weight which follows the existing manual entry path), avoids logging health data, and stores only boolean permission flags in SharedPreferences.

**Ship Blockers:** None.

**Follow-up Items:**
1. If Flutter web support is ever added, conditionally import the `health_service.dart` to avoid `dart:io` crashes on web (L-1).
2. Consider constructor-injecting SharedPreferences into HealthDataNotifier for cleaner testability (L-2).

---

**Audit Completed:** 2026-02-15
**Fixes Applied:** 0 (no issues requiring code changes)
**Pipeline:** 16 -- Health Data Integration + Performance Audit + Offline UI Polish

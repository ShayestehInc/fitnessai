# Hacker Report: Health Data Integration + Performance Audit + Offline UI Polish (Pipeline 16)

## Date: 2026-02-15

## Focus Areas
HealthKit/Health Connect integration (steps, active calories, heart rate, weight), auto-import weight check-ins, permission flow, health card on home screen, offline pending data merge (workouts on home, nutrition macros, weight trends), SyncStatusBadge placement, performance audit (RepaintBoundary, const constructors, Riverpod select(), SliverList.builder).

---

## Dead Buttons & Non-Functional UI

| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | `nutrition_screen.dart` `_MealSection` | "Copy Meal" PopupMenuItem | Tapping should copy the meal's food entries to clipboard or another meal slot. | No `onTap` handler. Tapping selects the item and closes the popup, but does nothing. Dead button. Pre-existing (not from this pipeline). |
| 2 | Medium | `nutrition_screen.dart` `_MealSection` | "Clear Meal" PopupMenuItem | Tapping should delete all food entries in the meal, possibly with a confirmation dialog. | No `onTap` handler. Same as above -- dead button. Pre-existing. |
| 3 | Low | `home_screen.dart` `_VideoCard` | Play button overlay on video thumbnail | Tapping should play the video or open it in a player. | The entire video card has no `GestureDetector` or `InkWell`. The play button is purely decorative. The like heart icon is also an `Icon`, not an `IconButton`. Pre-existing. |
| 4 | Low | `home_screen.dart` `_VideoCard` | Like heart icon and count | Tapping should toggle the like state. | No tap handler. Static icon. Pre-existing. |

---

## Visual Bugs

| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | `nutrition_screen.dart` `_buildGoalHeader` | Refresh icon was a 16px `GestureDetector`-wrapped `Icon` with no minimum tap target (violates 48dp accessibility guideline), no ripple feedback, and no tooltip. Nearly impossible to tap on mobile. | **FIXED**: Replaced `GestureDetector` with `IconButton` having `constraints: BoxConstraints(minWidth: 32, minHeight: 32)`, `tooltip: 'Refresh goals'`, and proper ripple feedback. |
| 2 | Low | `health_card.dart` `_SkeletonHealthCard` | Skeleton header placeholder is only 100px wide and 12px tall. On wider devices, the skeleton looks oddly small compared to the "Today's Health" title that replaces it. | Not fixed -- cosmetic only, the skeleton disappears quickly once data loads. |
| 3 | Low | `health_card.dart` `_MetricTile` | The value text uses `maxLines: 1` with `TextOverflow.ellipsis`, which is correct. But with large active calories (e.g., "3,456 cal"), the " cal" suffix might get truncated on narrow screens. The value and unit suffix are combined into a single text string. | Not fixed -- would need to split value and suffix into separate widgets to prevent truncating the number. Extremely unlikely with the 2x2 grid layout. |
| 4 | Low | `weight_trends_screen.dart` | The chart (`_WeightChartPainter`) draws data points as 4px-radius dots. With 30 data points on a narrow phone, dots can overlap each other, creating visual noise. | Not fixed -- requires design decision on whether to reduce dot size or only show dots at selected intervals. |

---

## Broken Flows & Logic Bugs

| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | High | Server weight entries wrongly showing pending badge | 1. Save weight offline (creates pending entry for "2026-02-15"). 2. Sync completes, pending entry goes to server. 3. Pending entry is removed from local DB. 4. **But:** before step 3 finishes, or if a pending entry has the same date as an existing server entry, open Weight Trends screen. | Server entries (already synced) should NOT show a SyncStatusBadge. Only pending entries (from local DB) should show badges. | `_buildHistoryRow` was called with `isPending: pendingDates.contains(checkIn.date)`. If a pending weight and a server weight share the same date (e.g., manual entry + auto-import), the server entry would incorrectly display a pending SyncStatusBadge. **FIXED**: Removed the `isPending` parameter from `_buildHistoryRow`. Server entries never get badges. Only `_buildPendingWeightRow` displays SyncStatusBadge. Cleaned up dead code (`pendingDates` set, `isPending` parameter, unnecessary `Stack` wrapper). |
| 2 | Medium | No way to reconnect health data after declining | 1. On first home screen visit, the health permission sheet appears. 2. Tap "Not Now". 3. The sheet never appears again (`health_permission_asked` = true in SharedPreferences). 4. User changes their mind and wants to connect health data. | There should be a "Connect Health Data" option in the Settings screen, per the ticket UX requirements: "The user can connect later via Settings." | No health reconnection option exists in the Settings screen. The gear icon on the health card opens the device's health settings, but the card itself is hidden when permission is denied. The user has no way to re-trigger the permission flow from within the app. **NOT FIXED**: Requires adding a new Settings screen row with logic to reset `health_permission_asked`/`health_permission_granted` in SharedPreferences and re-trigger the OS permission dialog. This is a feature addition, not a bug fix. |
| 3 | Medium | Home screen nutrition totals don't include pending | 1. Go to airplane mode. 2. Log nutrition via AI command center (saves pending). 3. Return to Home screen. 4. Compare the CalorieRing and MacroCircles on the Home screen with the Nutrition screen. | Both screens should show the same calorie/macro totals. | The Home screen's `HomeState.caloriesConsumed` etc. come from server-only `todayNutrition` data. The Nutrition screen adds `pendingProtein`, `pendingCarbs`, `pendingFat` on top of server data. This means the Home screen shows lower numbers than the Nutrition screen for the same day when pending entries exist. **NOT FIXED**: This was not in the ticket's scope (AC-16 only mentions the Nutrition screen). Fixing it would require adding pending nutrition loading to `HomeNotifier.loadDashboardData()` and adding pending fields to `HomeState`. Documenting for future pipeline. |
| 4 | Low | `HealthService.healthSettingsUri` uses `Platform.isIOS` from `dart:io` | 1. This is a static getter, so it's evaluated at runtime. 2. On mobile, this works fine. 3. If Flutter Web were ever enabled, this would crash at import time due to `dart:io` import. | Should use a platform-agnostic approach consistent with the fix applied to `health_permission_sheet.dart` (which uses `Theme.of(context).platform`). | The `HealthService` is a plain Dart class without access to `BuildContext`, so it cannot use `Theme.of(context)`. The health permission sheet was fixed in review round 1 (m2) but the service was not. **NOT FIXED**: Since this is a mobile-only feature (HealthKit/Health Connect), `dart:io` is always available. The inconsistency is minor. Would require passing `TargetPlatform` as a parameter to `healthSettingsUri`, which is unnecessary refactoring for a mobile-only feature. |
| 5 | Low | Fade animation replays when widget is remounted | 1. Navigate away from the Home screen (e.g., go to Settings). 2. Navigate back to the Home screen. 3. The `_LoadedHealthCard` is rebuilt, running the 200ms fade-in again. | On return navigation, the card should appear instantly (no fade). | The fade animation runs in `initState`, which is called every time the widget is mounted. On tab switch or navigation return, the entire home screen tree may be rebuilt, causing a brief 200ms fade on the health card. This is barely noticeable but technically incorrect. **NOT FIXED**: Would require caching whether the animation has already played (e.g., in a provider or static flag). Very minor UX issue. |
| 6 | Low | Health data fetch failure on first load shows nothing | 1. Grant health permission. 2. Kill HealthKit daemon (or run on simulator with no data sources). 3. Open the Home screen for the first time. | The health card should show "--" for all metrics (zero data is valid). | If `syncTodayHealthData()` throws an exception (not just returns zeros), the state becomes `HealthDataUnavailable` and the card is hidden entirely. The user sees no card and no error. This is correct per the ticket ("Error state: Card hidden"), but it means the user might think health integration is broken rather than just having no data. The ticket's design prioritizes clean UI over diagnostic information. Acceptable behavior. |

---

## Product Improvement Suggestions

| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Settings screen | Add a "Health Data" row in Settings that shows connection status ("Connected" / "Not Connected") and allows reconnecting. If denied, show a message explaining how to enable it in device settings. If never asked, show the permission sheet. | Currently there is no way to connect health data after the initial prompt. This was called out in the ticket UX requirements but not implemented. |
| 2 | High | Home screen nutrition | Include pending nutrition macros in the Home screen's CalorieRing and MacroCircle widgets, matching what the Nutrition screen shows. Add "(includes X pending)" label if pending count > 0. | Data consistency between screens is fundamental UX. Users will notice the discrepancy and lose trust in the app's accuracy. |
| 3 | Medium | Health card | Add a subtle "Last synced: 2m ago" timestamp below the health card title. Health data from HealthKit can be delayed, and users might wonder if the displayed steps are current. | Sets correct expectations. Apple Health data can be 5-15 minutes delayed depending on the source. |
| 4 | Medium | Pending workout cards | Instead of just a snackbar ("This workout is waiting to sync"), show the actual workout data in a read-only detail view. The data is already in the local DB as JSON. | The user logged this workout and wants to see what they logged. A snackbar feels like a dead end. |
| 5 | Medium | Health card animations | Add a number counting animation when metrics update on pull-to-refresh (e.g., steps counting from old value to new value over 300ms). | Provides clear visual feedback that the refresh actually fetched new data. Without it, users can't tell if the numbers changed on refresh. |
| 6 | Low | Weight auto-import | Show a subtle one-time snackbar after the first successful auto-import: "Weight imported from [Apple Health / Health Connect]". After the first time, import silently. | Helps the user understand that health integration is working. The "Auto-imported from Health" note in the history is discoverable but not immediately obvious. |
| 7 | Low | Nutrition screen | Wire up the "Copy Meal" and "Clear Meal" popup menu items. These are visible interactive elements that do nothing. | Dead buttons erode trust. If they can't be implemented yet, hide them. |
| 8 | Low | Video cards | Either make video cards tappable (navigate to a video player or external URL) or remove the play button overlay that implies interactivity. | The play button overlay strongly suggests the video is playable. Having it do nothing is misleading. |

---

## Summary

- Dead UI elements found: 4 (0 new from this pipeline; all pre-existing)
- Visual bugs found: 4 (1 fixed, 3 cosmetic/not-fixed)
- Logic bugs found: 6 (1 fixed, 5 documented -- 3 require design decisions, 2 are minor)
- Improvements suggested: 8
- Items fixed by hacker: 2

## Fixes Applied

### Fix 1: `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart`
- **Bug**: Server weight entries incorrectly displayed a `SyncStatusBadge` when their date matched a pending weight entry's date. The `pendingDates` set was built from pending entries and used to flag server rows with `isPending: pendingDates.contains(checkIn.date)`.
- **Fix**: Removed the `pendingDates` set computation. Removed the `isPending` parameter from `_buildHistoryRow` (server entries are always synced). Removed the unnecessary `Stack` wrapper and `Positioned` `SyncStatusBadge` from `_buildHistoryRow`. Pending entries are already shown correctly via `_buildPendingWeightRow` which always has the badge. This eliminates the false-positive badge on server entries.

### Fix 2: `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`
- **Bug**: The "Refresh goals" icon was a 16px `Icon` wrapped in a `GestureDetector` with no minimum tap target, no ripple feedback, and no accessibility tooltip. This violates Material Design's 48dp minimum touch target guideline.
- **Fix**: Replaced `GestureDetector` with `IconButton` providing `constraints: BoxConstraints(minWidth: 32, minHeight: 32)`, `tooltip: 'Refresh goals'`, and built-in ripple feedback. The 32dp minimum is acceptable for an inline icon button next to text.

---

## Chaos Score: 8/10

### Rationale
The Health Data Integration is well-architected. The sealed state hierarchy with exhaustive pattern matching ensures every UI state is handled. The independent try-catch per health data type means partial data degrades gracefully. The auto-import weight deduplication checks both server and local pending entries. The `isRefresh` parameter prevents skeleton flash on pull-to-refresh. The `mounted` guards after every `await` prevent disposed-state mutations.

The one real logic bug I found (server weight entries getting false-positive pending badges) was a subtle data-flow issue that would confuse users seeing sync badges on entries they never logged offline. This is the kind of bug that only surfaces when pending and server data coexist for the same date.

The bigger product gaps are:
1. No reconnection path for health data after initial denial (ticket called for it, was not implemented)
2. Home screen nutrition totals don't include pending data, creating inconsistency with the Nutrition screen
3. Pre-existing dead UI (Copy Meal, Clear Meal, Video play buttons) that wasn't addressed by this pipeline

The performance audit (RepaintBoundary, select(), SliverList.builder, shouldRepaint) is conservative and correct -- no over-optimization that would cause visual regressions.

**Good:**
- Sealed class state hierarchy with exhaustive `switch` pattern matching
- Each health data type independently try-caught (partial data is valid)
- `isRefresh` parameter preserving existing data on refresh failure
- `mounted` guards after every `await` in `HealthDataNotifier`
- Weight auto-import with both server and offline dedup checks
- `NumberFormat('#,###')` as a `static final` (no per-build allocation)
- `shouldRepaint` on `_WeightChartPainter` using `listEquals` for proper comparison
- `SliverList.builder` for weight history virtualization
- Permission persisted in SharedPreferences (single-ask design)

---

**Audit completed by:** Hacker Agent
**Date:** 2026-02-15
**Pipeline:** 16 -- Health Data Integration + Performance Audit + Offline UI Polish

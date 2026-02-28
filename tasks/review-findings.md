# Code Review: Calendar Integration Completion (Pipeline 41)

## Review Date
2026-02-27

## Files Reviewed
1. `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart` (256 lines)
2. `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart` (268 lines)
3. `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart` (290 lines)
4. `mobile/lib/features/calendar/presentation/widgets/calendar_card.dart` (174 lines)
5. `mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart` (97 lines)
6. `mobile/lib/features/calendar/presentation/widgets/availability_slot_editor.dart` (230 lines)
7. `mobile/lib/features/calendar/presentation/providers/calendar_provider.dart` (343 lines)
8. `mobile/lib/features/calendar/data/models/calendar_connection_model.dart` (130 lines)
9. `mobile/lib/core/router/app_router.dart` (lines 329-344)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `calendar_events_screen.dart:57` | **Race condition: hasAnyConnection check uses stale state.** `initState` calls `loadEvents()` but the screen also checks `state.hasAnyConnection` to decide between the "no connection" view and the events view. On first navigation, `connections` list is empty (default state) because `loadConnections()` was called on the *connection screen*, not here. If the provider is shared across screens this works, but if state was reset or the user deep-links to `/trainer/calendar/events` directly, `hasAnyConnection` will be `false` and the "Connect a calendar first" view renders even if the user HAS a connection. The screen does not call `loadConnections()` itself. | Either (a) call `loadConnections()` in `initState` before `loadEvents()`, or (b) change the empty-check to only show "no connection" after loading is complete AND connections is empty. The safest fix: add `ref.read(calendarProvider.notifier).loadConnections()` at the top of `initState`'s postFrameCallback, before `loadEvents()`. |
| C2 | `calendar_events_screen.dart:104-106` + `167-184` | **Empty state not wrapped in scrollable widget, so pull-to-refresh is unreachable.** When `events.isEmpty` and `!isLoading`, the `_buildEmpty` widget renders inside the `Expanded` but outside the `RefreshIndicator`. The user sees "Pull down to sync your calendar" but literally cannot pull-to-refresh because there is no `RefreshIndicator` wrapping the empty state. This is a broken UX promise and violates AC2 for the empty-events case. | Wrap the empty state in a `RefreshIndicator` + `SingleChildScrollView` with `physics: AlwaysScrollableScrollPhysics()` so the user can actually pull to refresh even when the list is empty. |
| C3 | `calendar_connection_model.dart:80` | **CalendarEventModel.fromJson reads `external_event_id` but backend serializer sends `external_id`.** The backend `CalendarEventSerializer` (serializers.py:32) serializes `external_id` as the field name. The mobile model reads `json['external_event_id']`, which will never match. `externalEventId` will always be `null` on the client even when the backend sends valid data. | Change `json['external_event_id']` to `json['external_id']` on line 80. |
| C4 | `calendar_events_screen.dart:61-62` + `124-127` | **Provider filter has a state mismatch failure mode.** When user changes filter (line 124-127), it calls `loadEvents(provider: provider)` which replaces `state.events` with filtered results from the API. But `_providerFilter` is local state. If the API call for the new filter fails (network error), the old *unfiltered* events remain displayed while the filter chip shows the new selection. The user sees "Google" filter active but is looking at both Google and Microsoft events. | Store the active filter in `CalendarState` so it is always consistent with the data. Alternatively, on error, revert `_providerFilter` back to its previous value. |
| C5 | `calendar_event_tile.dart` (entire file) | **AC1 requires "provider badge" on each event tile, but provider info is completely absent.** The ticket AC1 states: "with title, time, location, and provider badge." The `CalendarEventModel` does not contain a `provider` field (the backend `CalendarEventSerializer` does not expose `connection.provider`). The tile renders title, time, and location but the provider badge (Google blue / Microsoft orange) is completely missing. This is a hard acceptance criteria failure. | Either (a) add a `provider` field to the backend's `CalendarEventSerializer` (e.g., `source='connection.provider'`), then add it to `CalendarEventModel.fromJson`, and render a badge in the tile. Or (b) if backend changes are out of scope for this pipeline, document it explicitly as a known gap in `dev-done.md` and adjust the AC. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `calendar_events_screen.dart` (256 lines), `trainer_availability_screen.dart` (268 lines), `calendar_connection_screen.dart` (290 lines), `availability_slot_editor.dart` (230 lines) | **Four files exceed the 150-line limit.** Project convention (CLAUDE.md): "Max 150 lines per widget file." CalendarEventsScreen is 256, TrainerAvailabilityScreen is 268, CalendarConnectionScreen is 290, AvailabilitySlotEditor is 230. | Extract sub-widgets: CalendarEventsScreen: extract `_buildDateSection`, `_buildEmpty`, `_buildNoConnection` into separate widget files. TrainerAvailabilityScreen: extract `_buildSlotTile` into `availability_slot_tile.dart`. CalendarConnectionScreen: extract `_buildHeader` and `_buildActionsSection`. AvailabilitySlotEditor: move `_TimeTile` to its own file. |
| M2 | `calendar_provider.dart:188` | **`syncCalendar` returns and accesses a raw `Map<String, dynamic>` — violates project rule.** `result['synced_count'] ?? 0` operates on an untyped map. The project rule (.claude/rules/datatypes.md) states: "for services and utils, return dataclass or pydandict models, never ever return dict." The repository `syncCalendar` returns `response.data as Map<String, dynamic>` which also throws a runtime cast error if the response is not a Map. | Create a typed `SyncResult` model class (or at minimum a simple data class with `syncedCount` field) and use it in both the repository return type and the notifier. |
| M3 | `trainer_availability_screen.dart:183-196` | **Delete via Dismissible does not await the API result — failure mode leaves ghost item.** `confirmDismiss` returns `true` after calling `deleteAvailability(id)` without awaiting the API result. If the delete API call fails, the widget is already dismissed from the UI (Dismissible removes it from the tree). But the item remains in `state.availability` because `deleteAvailability` only removes it on success. On next rebuild, the item reappears — causing a confusing UX glitch. | Either (a) `await ref.read(calendarProvider.notifier).deleteAvailability(id)` and check for errors before returning `true`, or (b) implement optimistic delete in the provider (remove from list immediately, revert on failure) and always return `true`. Currently it is a broken hybrid of both approaches. |
| M4 | `trainer_availability_screen.dart:202-205`, `259-263` | **Time string parsing is fragile — `int.parse` on unvalidated split result.** `slot.startTime.split(':')` then `int.parse(parts[0])` will throw `FormatException` if the backend returns an unexpected time format (e.g., empty string, or time without colons). Same issue in `_formatTimeString` at lines 259-263. | Use `int.tryParse` with fallback defaults, or wrap in try-catch with a sensible fallback display. |
| M5 | `availability_slot_editor.dart:177-179` | **Validation error uses SnackBar instead of adaptive toast.** Every other screen in this feature uses `showAdaptiveToast` for messages, but the "End time must be after start time" validation on line 177 uses `ScaffoldMessenger.showSnackBar`. This breaks the iOS-native look and is inconsistent with the rest of the codebase. | Replace `ScaffoldMessenger.of(context).showSnackBar(...)` with `showAdaptiveToast(context, message: 'End time must be after start time', type: ToastType.error)`. Add the import for `adaptive_toast.dart`. |
| M6 | `calendar_provider.dart:287-311` | **`toggleAvailability` optimistic update reconstructs `TrainerAvailabilityModel` manually.** If `TrainerAvailabilityModel` gains new fields in the future, this manual construction will silently drop them. The model has no `copyWith` method. | Add a `copyWith` method to `TrainerAvailabilityModel` in `calendar_connection_model.dart` and use `a.copyWith(isActive: isActive)` instead of manually constructing a new instance. |
| M7 | All calendar files (22 calls total) | **`Color.withOpacity()` is deprecated in Flutter 3.27+.** There are 22 calls to `withOpacity()` across the calendar feature files. Flutter recommends using `Color.withValues(alpha: X)` instead. Breakdown: events_screen (4), availability_screen (6), calendar_card (6), event_tile (4), slot_editor (2). | Replace all `.withOpacity(X)` calls with `.withValues(alpha: X)`. |
| M8 | `calendar_events_screen.dart:22-25` | **`loadEvents()` called without `loadConnections()` — pull-to-refresh sync will be a no-op.** Related to C1. The `_syncAndReload` method (line 28-37) checks `state.hasGoogleConnected` / `state.hasMicrosoftConnected` to decide what to sync. With empty connection state, both checks are `false`, so pull-to-refresh only calls `loadEvents()` — no sync happens. The user thinks they are syncing but nothing is synced. | Load connections before or alongside events in `initState`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `calendar_events_screen.dart:112` | **`grouped.keys.elementAt(index)` is O(n) on each call.** For a `LinkedHashMap`/`Map`, `elementAt` on `keys` iterates from the beginning. With many date groups, this creates O(n^2) behavior in the ListView builder. | Convert keys to a list once: `final dateKeys = grouped.keys.toList();` then use `dateKeys[index]`. |
| m2 | `trainer_availability_screen.dart:72` | Same `elementAt` performance issue as m1. | Same fix: pre-compute `grouped.keys.toList()`. |
| m3 | `calendar_events_screen.dart:102-103` | **Loading state uses `CircularProgressIndicator` instead of shimmer placeholders.** Ticket UX Requirements specify: "Shimmer placeholders for both screens (consistent with existing loading_shimmer.dart pattern)." Both events and availability screens use a plain spinner. | Replace with shimmer loading widget matching the existing `loading_shimmer.dart` pattern. |
| m4 | `trainer_availability_screen.dart:61-62` | Same shimmer loading issue as m3 — availability screen also uses `CircularProgressIndicator`. | Same fix: use shimmer placeholder. |
| m5 | `calendar_card.dart:174` | **File is 174 lines — slightly over the 150-line limit.** | Consider extracting `_formatDate` into a shared utility or extracting the connected/disconnected card bodies into sub-widgets. |
| m6 | `calendar_connection_screen.dart:50-51` | **`TextEditingController` instances created in dialog builder are never disposed.** `codeController` and `stateController` are created in `_showCallbackDialog` but never disposed. They leak when the dialog closes. | Dispose controllers when the dialog closes (e.g., via `StatefulBuilder` or explicit disposal in the `Navigator.pop` callbacks), or store them as class fields with proper disposal in `dispose()`. |
| m7 | `calendar_events_screen.dart:133` | **Events are grouped by start date but not sorted within each group.** If the backend returns events out of order, events within a single date group will appear unsorted. | After grouping, sort each list by `event.startTime`. |
| m8 | `trainer_availability_screen.dart:95-97` | **Day name array is duplicated in 3 places.** `_dayNames` constant array appears in `_buildDaySection` (line 95), `AvailabilitySlotEditor._dayNames` (slot_editor line 28), and `TrainerAvailabilityModel.dayName` getter (model line 123). | Extract to a single shared constant (e.g., in `calendar_connection_model.dart` or a shared constants file). |
| m9 | `calendar_events_screen.dart:28-37` | **`_syncAndReload` syncs sequentially (Google then Microsoft).** If both providers are connected, the user waits for Google sync to finish before Microsoft sync starts. | Use `Future.wait([...])` to sync both providers in parallel, reducing total wait time. |
| m10 | `calendar_events_screen.dart:75` | **Filter chips only show when BOTH providers are connected.** If user only has Google connected, filter chips are hidden entirely. This is reasonable but means the user has no visual indicator of which provider's events they are viewing. | Consider showing filter chips even with a single provider (just "All" + the connected one), or add a subtle provider indicator somewhere else. Low priority. |

---

## Security Concerns

1. **OAuth code/state values sent without length validation** (`calendar_connection_screen.dart:92-94`). The `code` and `state` values from user text input are sent directly to the backend. While the backend validates these, defense-in-depth suggests adding basic length limits (OAuth codes are typically < 256 chars). Low risk.

2. **No explicit route guards on new calendar routes** (`app_router.dart:335-344`). The `/trainer/calendar/events` and `/trainer/calendar/availability` routes should be verified to have role-based guards (trainer-only). If a trainee deep-links to these URLs, the screens render (though API calls return 403). Verify the route guard middleware covers these paths.

## Performance Concerns

1. **No pagination on events.** Noted as out-of-scope in the ticket, but unbounded data fetches are a risk for trainers with hundreds of synced events.

2. **`_groupByDate` and `_groupByDay` re-compute on every rebuild** triggered by any `CalendarState` change (e.g., `isLoading` toggling). Use `ref.watch(calendarProvider.select((s) => s.events))` to only rebuild when the events list actually changes.

3. **Sequential calendar sync** (see m9).

---

## Acceptance Criteria Verification

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC1 | Events screen with title, time, location, provider badge | **FAIL** | Provider badge is missing entirely (C5). Title, time, location are correct. |
| AC2 | Pull-to-refresh on events | **PARTIAL** | Works when events exist; broken on empty state (C2) — user sees "pull to sync" text but cannot actually pull. |
| AC3 | Provider filter (All/Google/Microsoft) | **PASS** | Filter chips work, API call made on change. |
| AC4 | Empty state when no events | **PASS** | Renders correctly with icon + text. |
| AC5 | Error state with retry | **PARTIAL** | Error toast shows, but there is no explicit error card with retry button as specified in the ticket's error states table. Error falls through to empty state. |
| AC6 | Availability grouped by day | **PASS** | Correctly grouped and sorted by day of week. |
| AC7 | Add availability slot | **PASS** | FAB opens bottom sheet, save works with validation. |
| AC8 | Toggle slot active/inactive | **PASS** | Optimistic update with revert on failure. |
| AC9 | Delete slot with confirmation | **PARTIAL** | Confirmation dialog works but delete has a failure-mode issue (M3). |
| AC10 | Edit existing slot | **PASS** | Pre-fills bottom sheet, calls updateAvailability. |
| AC11 | Routes registered + navigation | **PASS** | Both routes in app_router.dart, navigation from connection screen works. |
| AC12 | CalendarEventModel field fix (`all_day`) | **PASS** | Changed to `all_day` correctly on line 79. |
| AC13 | updateAvailability + toggleAvailability exposed | **PASS** | Both methods implemented in CalendarNotifier. |
| AC14 | CalendarConnectionScreen refactored, card extracted | **PASS** | CalendarCard extracted, screen reduced from 524 to 290 lines. (Still over 150 limit per M1.) |

**Summary: 8/14 PASS, 3/14 PARTIAL, 1/14 FAIL, 2/14 not applicable to code review**

---

## Quality Score: 5/10

### What is good:
- Core CRUD functionality for availability is solid with proper error handling and optimistic updates
- Code is generally readable with clear naming conventions
- CalendarCard extraction was done cleanly with proper parameterization
- Adaptive dialogs and toasts are used consistently (one exception: M5)
- The `CalendarEventModel.fromJson` field fix for `all_day` is correct
- Provider state management pattern is consistent and well-structured
- Dismiss-to-delete with confirmation is a good UX pattern

### What prevents a higher score:
- 5 critical issues: broken pull-to-refresh on empty state (C2), missing provider badge (C5/AC1 FAIL), stale connection state race condition (C1/C4), wrong JSON field name (C3)
- 8 major issues including 4 files over the 150-line limit, raw Map return violating project rules, Dismissible delete failure mode, fragile time parsing, inconsistent error feedback
- Shimmer loading states specified in ticket but not implemented (m3/m4)
- Error state with retry button specified in ticket but not implemented (AC5 partial)

## Recommendation: REQUEST CHANGES

The 5 critical issues — particularly C2 (broken pull-to-refresh UX promise), C5 (missing provider badge / AC1 failure), and C1+M8 (stale connection state making sync a no-op) — make this unsuitable for shipping. After addressing critical and major issues, a re-review should bring this to shippable quality.

# Hacker Report: Calendar Integration (Pipeline 41)

## Date: 2026-02-27

## Files Audited
### Screens:
- `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart`
- `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart`
- `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart`

### Widgets:
- `mobile/lib/features/calendar/presentation/widgets/availability_slot_editor.dart`
- `mobile/lib/features/calendar/presentation/widgets/availability_slot_tile.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_actions_section.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_card.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_connection_header.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_no_connection_view.dart`
- `mobile/lib/features/calendar/presentation/widgets/calendar_provider_filter.dart`
- `mobile/lib/features/calendar/presentation/widgets/time_tile.dart`

### Provider:
- `mobile/lib/features/calendar/presentation/providers/calendar_provider.dart`

### Data:
- `mobile/lib/features/calendar/data/models/calendar_connection_model.dart`
- `mobile/lib/features/calendar/data/repositories/calendar_repository.dart`

---

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | CalendarConnectionScreen | "Connect Google Calendar" / "Connect Microsoft Outlook" button when auth URL fetch returns null without an error | User sees feedback that the connection attempt failed | Nothing happened. User tapped Connect and the app went silent. **FIXED**: Added fallback toast when authUrl is null but no error was set on state. |

---

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | CalendarEventTile / _ProviderBadge | Google provider badge used `Colors.blue`, but CalendarCard uses `Colors.red` for Google. Microsoft badge used `Colors.orange`, but CalendarCard uses `Colors.blue` for Microsoft. Colors were inconsistent across the same feature for the same providers. | **FIXED**: Changed `_ProviderBadge` to use `Colors.red` for Google and `Colors.blue` for Microsoft, matching `CalendarCard` icon colors. |

---

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Major | CalendarEventsScreen._setFilter race condition | 1. Have both Google and Microsoft connected with events. 2. Tap a provider filter chip. 3. `loadEvents` API call fails (network error). | Filter reverts to previous value so user sees the original events. | The `ref.listen` listener clears `state.error` via `clearMessages()` before `_setFilter` reaches the `if (state.error != null)` check. Filter stays on the new value while showing stale data from the previous filter. **FIXED**: Changed to compare event list identity instead of checking error state. |
| 2 | Major | CalendarEventsScreen._syncAndReload concurrent state mutations | 1. Have both Google and Microsoft connected. 2. Pull to refresh. | Smooth sync with consistent loading state. | `syncCalendar('google')` and `syncCalendar('microsoft')` ran concurrently via `Future.wait`. Both set `isLoading = true` then `isLoading = false` on shared state. The internal `loadConnections()` call inside `syncCalendar` also toggles `isLoading`. This creates flickering loading states and potential state corruption from interleaved state updates. **FIXED**: Changed to sequential sync execution. |
| 3 | Major | TrainerAvailabilityScreen._confirmDelete race condition | 1. Swipe to delete an availability slot. 2. Confirm deletion. 3. `deleteAvailability` API call fails (network error). | Dismissible stays in place (confirmDismiss returns false). | `state.error` is checked after `deleteAvailability()`, but the listener already cleared it via `clearMessages()`. `_confirmDelete` returns `true`, causing Dismissible to animate the slot away despite failed deletion. On next build, the slot reappears (jarring UX). **FIXED**: Check if the slot was removed from the availability list instead of checking error state. |
| 4 | Medium | CalendarEventsScreen.initState wasteful API call | 1. Navigate to events screen with no calendar connections. | Only `loadConnections` is called; screen shows "no connection" view. | `loadEvents()` is always called after `loadConnections()`, even when `hasAnyConnection` is false. Fires an unnecessary API request that returns empty results. **FIXED**: Added guard `if (state.hasAnyConnection)` before calling `loadEvents`. |
| 5 | Medium | CalendarConnectionScreen._showCallbackDialog controller lifecycle | 1. Tap Connect. 2. Complete OAuth flow. 3. Paste code/state. 4. Tap Connect button in dialog. | TextEditingControllers disposed after async operation completes. | Controllers were disposed immediately after `Navigator.pop()` (line 107-108) but BEFORE the `await notifier.completeGoogleCallback()` call. While the values were already extracted into local variables so no crash occurred, the dispose ordering was incorrect -- disposal should happen after the async work. **FIXED**: Moved `dispose()` calls after the async callback completes. Also added `autofocus: true` to the code field for better UX. |
| 6 | Medium | AvailabilitySlotTile._formatTimeString malformed input | 1. Backend returns an availability slot with empty string for `startTime`. 2. Or returns non-numeric time like "abc:xyz". | Graceful display showing something meaningful. | Empty string produced "12:00 AM" silently (hour=0, minute=0 defaults). Non-numeric parts also defaulted to 0, showing "12:00 AM". Misleading to the user. **FIXED**: Added empty string check returning "--:--" and validation check returning the raw string for completely malformed input. |
| 7 | Medium | TrainerAvailabilityScreen._showEditor time parsing | 1. Edit an availability slot whose time string has out-of-range values (e.g., "25:99:00"). | Safe parsing with clamped values. | `int.tryParse` with null-coalesce to 0 was used, but no clamping was applied. An hour of 25 or minute of 99 could create an invalid `TimeOfDay`, potentially causing assertion errors in debug mode. **FIXED**: Extracted `_parseTimeString` helper method with `.clamp(0, 23)` for hours and `.clamp(0, 59)` for minutes. |

---

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | CalendarConnectionScreen | Replace the manual code/state paste dialog with a deep link callback flow. Having users manually copy OAuth authorization codes from a browser into the app is extremely friction-heavy and error-prone. | Modern OAuth flows use redirect URIs back to the app via deep links or universal links. The current UX is a developer-facing workaround, not a production-ready flow. This is the single biggest UX improvement needed. |
| 2 | Medium | CalendarEventsScreen | Add date range controls or a mini calendar/date picker to navigate to past or future events. Currently only shows whatever the API returns (presumably upcoming). | Users may want to review past appointments or look further ahead than the default range. |
| 3 | Medium | TrainerAvailabilityScreen | Add a bulk-copy feature: "Copy Monday's schedule to Tuesday-Friday." Setting up availability for 7 days one slot at a time is tedious. | Trainers typically have similar hours across weekdays. One-tap copy would save significant time. |
| 4 | Medium | CalendarEventsScreen | Show an inline sync-in-progress indicator (e.g., linear progress bar below the app bar) instead of relying solely on the RefreshIndicator spinner. | When sync is triggered programmatically rather than via pull-to-refresh, there is no visual feedback that syncing is in progress. |
| 5 | Low | AvailabilitySlotEditor | Add a "Repeat for weekdays" or "Apply to multiple days" checkbox when creating a new slot. | Reduces repetitive slot creation from 5 separate operations to 1. |
| 6 | Low | CalendarCard | Display `connection.calendarName` alongside the email when connected, if available. The field exists on the model but is never shown. | Gives the user more context about which calendar is connected, especially if they have multiple Google calendars. |
| 7 | Low | CalendarProviderFilter | Replace custom `GestureDetector`-based `_Chip` with Flutter's built-in `ChoiceChip` or `FilterChip`. | The custom chip lacks keyboard navigation, focus indicators, and proper semantics. Material chip widgets provide these for free. |

---

## Items Not Fixed (Need Design Decisions / Backend Changes)
| # | Issue | Why Not Fixed | Suggested Approach |
|---|-------|---------------|-------------------|
| 1 | OAuth callback requires manual code pasting | Requires backend deep link / redirect URI configuration and Flutter deep link setup. Cannot be fixed in UI alone. | Implement app deep link handling for OAuth redirect URI. Configure redirect_uri in Google/Microsoft OAuth settings to use a custom scheme (e.g., `fitnessai://calendar/callback`) or universal links. Handle the redirect in `go_router` to extract code/state automatically. |
| 2 | All three screens duplicate the same `ref.listen` toast pattern | Code duplication across CalendarConnectionScreen, CalendarEventsScreen, and TrainerAvailabilityScreen. Each has identical 10-line blocks for error/success toast handling. | Extract a shared mixin (e.g., `CalendarToastListenerMixin`) or a utility method that handles the standard error/success toast listener pattern. |
| 3 | CalendarProviderFilter uses GestureDetector instead of Material chips | Low priority but affects accessibility. No focus ring, no keyboard interaction, no ripple feedback. | Replace `_Chip` with Flutter's built-in `ChoiceChip` widget for proper semantics, focus handling, and keyboard support. |
| 4 | No createEvent UI exists despite repository having `createEvent` method | The repository has a `createEvent` method but no screen or widget calls it. Users can only view synced events, not create new ones from the app. | Add a "Create Event" FAB or button on the CalendarEventsScreen. Build a form for title, time, description, location. Wire it to the existing repository method. |

---

## Summary
- Dead UI elements found: 1
- Visual bugs found: 1
- Logic bugs found: 7
- Improvements suggested: 7
- Items fixed by hacker: 8
- Items needing design decisions: 4

### Files Changed by Hacker
1. **`mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart`** -- Added fallback toast for null authUrl without error; fixed controller disposal ordering; added autofocus to code field
2. **`mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart`** -- Fixed `_setFilter` race condition (compare event lists instead of error state); fixed `_syncAndReload` concurrent mutation (sequential execution); added `hasAnyConnection` guard before loading events
3. **`mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart`** -- Fixed `_confirmDelete` race condition (check slot removal instead of error state); extracted `_parseTimeString` helper with value clamping
4. **`mobile/lib/features/calendar/presentation/widgets/availability_slot_tile.dart`** -- Fixed `_formatTimeString` to handle empty and malformed time strings gracefully
5. **`mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart`** -- Fixed `_ProviderBadge` color inconsistency (Google: red, Microsoft: blue)

## Chaos Score: 6/10

The calendar feature works correctly on the happy path but has several lurking race conditions in the state management layer. The root cause is a design pattern where `ref.listen` clears error/success messages immediately upon receiving them, which means any code that checks `state.error` after an async operation races against the listener. This pattern caused three separate bugs (filter revert, delete dismiss, and confirm-delete). All three have been fixed with approaches that don't depend on `state.error` being present.

The malformed-time-string handling was silently producing misleading "12:00 AM" values for empty or garbage input -- now it shows fallback values. The provider color inconsistency (blue vs red for Google across two widgets in the same feature) has been corrected.

The biggest product concern is the OAuth code-paste dialog, which requires users to manually copy authorization codes from a browser. This is a significant friction point that needs a backend/deep-link solution.

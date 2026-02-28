# Feature: Calendar Integration Completion (Mobile)

## Priority
High

## User Story
As a **trainer**, I want to view my synced calendar events and manage my availability slots from the mobile app, so that I can coordinate scheduling with trainees without switching to a browser.

## Acceptance Criteria
- [ ] AC1: CalendarEventsScreen displays all synced events from connected calendars, grouped by date, with title, time, location, and provider badge
- [ ] AC2: CalendarEventsScreen supports pull-to-refresh (triggers sync + reload)
- [ ] AC3: CalendarEventsScreen has a provider filter (All / Google / Microsoft)
- [ ] AC4: CalendarEventsScreen shows proper empty state when no events exist
- [ ] AC5: CalendarEventsScreen shows proper error state with retry
- [ ] AC6: TrainerAvailabilityScreen displays all availability slots grouped by day of week
- [ ] AC7: TrainerAvailabilityScreen allows adding a new availability slot (day picker + start/end time pickers)
- [ ] AC8: TrainerAvailabilityScreen allows toggling a slot active/inactive
- [ ] AC9: TrainerAvailabilityScreen allows deleting a slot with confirmation
- [ ] AC10: TrainerAvailabilityScreen allows editing an existing slot (update time/day)
- [ ] AC11: Both routes registered in app_router.dart and navigation from CalendarConnectionScreen works
- [ ] AC12: CalendarEventModel field name bug fixed (`all_day` not `is_all_day`)
- [ ] AC13: `updateAvailability` exposed in CalendarNotifier (currently only in repository)
- [ ] AC14: CalendarConnectionScreen refactored: extract card widget to stay under 150 lines

## Edge Cases
1. No calendar connected yet — events screen shows "Connect a calendar first" with button to navigate back to connection screen
2. Calendar connected but zero events synced — shows empty state "No upcoming events. Pull to sync."
3. Sync fails (expired token, network error) — error toast, events screen still shows last cached data
4. Availability slot with end_time before start_time — validation prevents saving
5. Duplicate availability slot (same day + overlapping times) — show warning but allow (backend allows it)
6. All availability slots deleted — empty state "No availability set. Add your first slot."
7. Rapidly toggling active/inactive — debounce or optimistic update to prevent UI flicker
8. Very long event title — text overflow handled with ellipsis + max lines
9. All-day events — display "All Day" instead of time range
10. Events spanning midnight — show correct date grouping based on start_time

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network error loading events | Error card with "Failed to load events" + Retry button | Preserves last cached state |
| Network error loading availability | Error card with "Failed to load availability" + Retry button | Preserves last cached state |
| Sync fails (token expired) | Adaptive toast: "Calendar sync failed. Please reconnect." (error) | Marks connection as expired |
| Save availability fails | Adaptive toast: "Failed to save availability" (error) | Reverts optimistic update |
| Delete availability fails | Adaptive toast: "Failed to delete slot" (error) | Reverts deletion |

## UX Requirements
- **Loading state:** Shimmer placeholders for both screens (consistent with existing loading_shimmer.dart pattern)
- **Empty state (events):** Calendar icon + "No upcoming events" + "Pull down to sync your calendar" subtitle
- **Empty state (availability):** Clock icon + "No availability set" + "Tap + to add your first time slot"
- **Error state:** Error icon + message + Retry button (consistent with existing error states)
- **Success feedback:** Adaptive toast for create/update/delete operations
- **Pull-to-refresh:** Events screen syncs + reloads; Availability screen just reloads
- **Navigation:** Back arrow returns to CalendarConnectionScreen

## Technical Approach

### Files to Create
1. `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart` (~120 lines)
   - ConsumerStatefulWidget
   - Loads events via `calendarProvider`
   - Groups events by date using `LinkedHashMap`
   - Provider filter chips (All / Google / Microsoft)
   - Pull-to-refresh triggers `syncCalendar()` then `loadEvents()`
   - Each event tile: title, time range or "All Day", location if present, provider icon

2. `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart` (~130 lines)
   - ConsumerStatefulWidget
   - Loads availability via `calendarProvider`
   - Grouped by day of week (Monday-Sunday)
   - Each slot: time range, active toggle, edit/delete actions
   - FAB to add new slot → shows bottom sheet with day picker + time pickers
   - Swipe-to-delete with confirmation

3. `mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart` (~60 lines)
   - Extracted widget for a single event row
   - Provider badge (Google blue / Microsoft orange)
   - Time formatting, all-day handling

4. `mobile/lib/features/calendar/presentation/widgets/calendar_card.dart` (~80 lines)
   - Extracted from CalendarConnectionScreen._buildCalendarCard()
   - Keeps connection screen under 150 lines

5. `mobile/lib/features/calendar/presentation/widgets/availability_slot_editor.dart` (~80 lines)
   - Bottom sheet for creating/editing availability slots
   - Day of week dropdown, adaptive time pickers, save/cancel buttons

### Files to Modify
1. `mobile/lib/core/router/app_router.dart` — Add 2 routes:
   - `/trainer/calendar/events` → CalendarEventsScreen
   - `/trainer/calendar/availability` → TrainerAvailabilityScreen

2. `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart`:
   - Extract `_buildCalendarCard` to `calendar_card.dart`
   - Fix navigation path: `/trainer/availability` → `/trainer/calendar/availability`
   - Reduce to <150 lines

3. `mobile/lib/features/calendar/data/models/calendar_connection_model.dart`:
   - Fix `CalendarEventModel.fromJson`: change `is_all_day` → `all_day` to match backend

4. `mobile/lib/features/calendar/presentation/providers/calendar_provider.dart`:
   - Add `updateAvailability(id, {...})` method to CalendarNotifier
   - Add `toggleAvailability(id, isActive)` convenience method

### Dependencies
- No new packages needed — all existing (flutter_riverpod, go_router, intl)

### Key Design Decisions
- Events screen uses the locally-cached CalendarEvent data (GET /events/), not direct API calls to Google/Microsoft
- Pull-to-refresh on events triggers a sync first, then reloads from cache
- Availability editor uses adaptive time picker for iOS-native feel
- OAuth flow remains as-is (manual code paste) — deep link fix is a separate future pipeline
- No pagination on events (backend doesn't support it) — acceptable for typical trainer usage

## Out of Scope
- OAuth deep-link redirect (requires native URL scheme setup — separate pipeline)
- Web calendar fixes (disconnect endpoint mismatch, missing Microsoft flow)
- Creating events from mobile (endpoint exists but UI deferred)
- Trainee-facing calendar view
- Recurring event expansion
- Event detail screen (tapping opens external link via url_launcher)

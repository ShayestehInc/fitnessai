# Code Review: Community Events

## Review Date: 2026-03-05

## Files Reviewed
1. `mobile/lib/features/community/data/models/event_model.dart`
2. `mobile/lib/features/community/data/repositories/event_repository.dart`
3. `mobile/lib/features/community/presentation/providers/event_provider.dart`
4. `mobile/lib/features/community/presentation/widgets/event_type_badge.dart`
5. `mobile/lib/features/community/presentation/widgets/rsvp_button.dart`
6. `mobile/lib/features/community/presentation/widgets/event_card.dart`
7. `mobile/lib/features/community/presentation/screens/event_list_screen.dart`
8. `mobile/lib/features/community/presentation/screens/event_detail_screen.dart`
9. `mobile/lib/features/community/presentation/screens/trainer_event_list_screen.dart`
10. `mobile/lib/features/community/presentation/screens/trainer_event_form_screen.dart`
11. `mobile/lib/core/router/app_router.dart` (event routes)
12. `mobile/lib/features/community/presentation/screens/school_home_screen.dart` (event icon)
13. `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` (events section)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `event_model.dart:55` | **No null-safety on DateTime.parse** — If backend returns `null` for `starts_at` or `ends_at`, `DateTime.parse` throws an unhandled `FormatException`/`TypeError`. This can crash the entire event list if a single event has corrupt data. | Wrap in try/catch or add null checks: `json['starts_at'] as String? ?? ''` with a fallback, or guard with `if (json['starts_at'] == null) throw FormatException(...)` for explicit handling. |
| C2 | `event_provider.dart:70,104,134` | **Swallowing all exceptions** — `catch (_)` discards the actual error type and message. DioExceptions carry HTTP status codes and server error messages (e.g., 409 conflict for concurrent RSVP). The user always sees generic "Failed to load events" even for auth failures (401) that should trigger logout. | Catch `DioException` specifically, extract `response?.statusCode` and `response?.data` for meaningful error messages. Re-throw non-network errors. At minimum, log the error. |
| C3 | `event_repository.dart:105` | **Uses PUT for partial update** — `updateEvent()` sends only changed fields via `PUT`, but PUT semantics require a complete resource representation. If the backend enforces PUT semantics (requires all fields), this will fail. If it treats PUT as PATCH, it works but is semantically wrong. | Change to `_apiClient.dio.patch(...)` for partial updates, matching REST semantics and the `clearMaxAttendees` partial-update pattern. |
| C4 | `event_detail_screen.dart:219-224` | **`_launchUrl` silently fails** — If URL parsing fails or `canLaunchUrl` returns false, the user gets zero feedback. The "Join Meeting" button does nothing. This is a dead button scenario. | Show a snackbar on failure: `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open meeting link')))`. Also, `_launchUrl` is not called with context, so it needs refactoring to surface errors to the UI. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `event_list_screen.dart:35-37` | **No shimmer skeleton loading** — Ticket UX spec requires "Shimmer skeleton cards (3 placeholder event cards) matching event card layout." Implementation uses `CircularProgressIndicator` instead. | Build a shimmer skeleton matching the EventCard layout (similar to `SchoolHomeScreen._buildLoadingSkeleton`). |
| M2 | `event_model.dart` | **Missing `location` field** — Ticket AC-10 says trainer should be able to set `location`. The backend model has `meeting_url` but no `location` field for in-person events. The model only derives `isVirtual` from `meetingUrl.isNotEmpty`, meaning in-person events have no location display — the card shows "In Person" with no address. | If backend supports a `location` field, add it to the model. If not, this is a ticket/backend gap that should be documented. Currently, the detail screen shows "In Person" with no actual address, which is unhelpful for the user. |
| M3 | `event_card.dart:104` | **`DateTime.now()` called multiple times per build across model getters** — `isPast`, `isHappeningNow`, `canJoinVirtual`, and `_formatDateRange` each call `DateTime.now()` independently. Each call returns a slightly different time, potentially causing inconsistent state within a single frame (e.g., an event could theoretically be both "happening now" and "past" if the clock ticks between getter calls). | Pass `DateTime.now()` once from the parent widget and thread it through, or compute it once in `build()` and pass to all helpers. |
| M4 | `trainer_event_form_screen.dart:128` | **Title field has `counterText: ''`** — This hides the character counter, but the ticket UX spec explicitly requires "character counters on title (200) and description (2000)." Description field shows the counter (default behavior with `maxLength: 2000`), but title does not. | Remove `counterText: ''` from the title field decoration to show the counter. |
| M5 | `event_detail_screen.dart:10-33` | **Detail screen does not fetch from API** — It only reads from the provider's in-memory list (`state.events.where(...).firstOrNull`). If the user deep-links to an event detail or the provider state was disposed (autoDispose), they see "Event not found." There's no API fallback. Also violates error state from ticket: "Event deleted while viewing detail" — a 404 from the server should show a snackbar and pop back, but there's no server call to detect this. | Add a `getEventDetail(eventId)` call as fallback when the event isn't in the provider state. Handle 404 responses to pop back with a snackbar. |
| M6 | `event_provider.dart:37-50` | **Computed properties `upcoming`, `past`, `cancelled` re-sort on every access** — These getters create new lists, filter, and sort on every call. In `EventListScreen.build()`, `state.upcoming`, `state.cancelled`, and `state.past` are each called at least once per build. With large event lists, this is wasteful. | Cache the computed lists in the state object (invalidate on `copyWith`) or compute them once in `build()` and store in local variables. |
| M7 | `trainer_event_form_screen.dart:345-411` | **`_submit` catches only `Exception`, does not parse DRF validation errors** — `on Exception` won't catch `Error` subclasses. More importantly, it doesn't parse DRF validation errors from the response body. The ticket error states table says "Parse DRF error response, map to fields" for validation errors, but the implementation just shows a generic snackbar. | Catch `DioException`, parse `response?.data` for field-level errors (e.g., `{'starts_at': ['End time must be after start time']}`), and map them to the form fields. |
| M8 | `event_list_screen.dart:86-87` | **Date grouping missing "Next Week" group** — The ticket UX spec lists groups: "Today", "Tomorrow", "This Week", "Next Week", "Later". Implementation only has "Today", "Tomorrow", "This Week", "Later" — "Next Week" is missing. Additionally, the week boundary calculation `today.add(Duration(days: 7 - today.weekday))` yields `endOfWeek == today` on Sundays (weekday=7), meaning nothing falls into "This Week" on Sundays. | Add "Next Week" group. Fix Sunday edge case by using `today.add(Duration(days: 8 - today.weekday))` or similar. |
| M9 | `event_provider.dart:37-50` | **Cancelled past events vanish from list** — `upcoming` excludes cancelled (`!e.isCancelled`). `cancelled` only includes non-past cancelled events (`!e.isPast`). `past` includes by end-time past OR completed status, but not cancelled-and-past. A cancelled event whose `endsAt` is in the past falls into `past` via `e.isPast`, so it does appear. However, a cancelled event whose `endsAt` is still future but is `isCompleted` false would appear in `cancelled` — correct. **On closer inspection:** the `past` getter checks `e.isPast || e.isCompleted` — a cancelled event that is also past would appear in BOTH `past` and `cancelled`. Need to deduplicate. | Ensure each event appears in exactly one section. `cancelled` should only show non-past cancelled events (current behavior). `past` should exclude cancelled events: `e.isPast && !e.isCancelled`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `rsvp_button.dart` | **No Semantics on individual segments** — The outer `Semantics` label says "RSVP status: Going" but individual segments don't have labels for screen readers. | Verify `SegmentedButton`'s built-in accessibility; add individual Semantics if needed. |
| m2 | `event_card.dart:21-22` | **Dimming conflicts with "Happening Now"** — A cancelled event that is still within its time window shows both the "Happening Now" badge and is dimmed. Confusing. | If cancelled, always dim and skip the "Happening Now" badge. The event_card header already handles this: `event.isHappeningNow || event.isCancelled` shows status badge — but the badge selection picks cancelled over live (line 65). This is actually correct but the `isHappeningNow` check is still evaluated. Minor confusion, not a bug. |
| m3 | `trainer_event_form_screen.dart:291-297` | **`_pickDate` allows picking yesterday** — `firstDate: DateTime.now().subtract(const Duration(days: 1))` lets users create events starting yesterday. | For creation mode, set `firstDate: DateTime.now()`. For edit mode, allow past dates (event might have already started). |
| m4 | `trainer_event_list_screen.dart:33-34` | **FAB pushes with type `<bool>` but edit pops `String`** — `context.push<bool>('/trainer/events/create')` expects bool, but edit flow pops with `context.pop('updated')`. The FAB only handles create (returns `true`), so it works, but the type parameter is misleading. | Change to `<Object?>` or use a consistent return type across all navigation results. |
| m5 | `event_list_screen.dart:19-21` | **Uses `Future.microtask` instead of `addPostFrameCallback`** — Inconsistent with the rest of the codebase (see `school_home_screen.dart:33` which uses `addPostFrameCallback`). | Use `WidgetsBinding.instance.addPostFrameCallback` for consistency. |
| m6 | `trainer_event_form_screen.dart:398` | **Mixed return types** — `context.pop(_isEditing ? 'updated' : true)` returns String for edit, bool for create. Type-unsafe. | Use consistent String returns: `'created'`, `'updated'`, `'deleted'`. |
| m7 | `event_detail_screen.dart:147-163` | **Cancelled events hide RSVP entirely** — Edge case #7 says "user's RSVP preserved but greyed out" for cancelled events. Current implementation hides the RSVP section completely. | Show the RSVP button disabled/greyed out for cancelled events, reflecting the user's previous selection. |
| m8 | `event_detail_screen.dart` | **No Semantics on "Join Meeting" button, cancelled card, or past event card** — These interactive/informational elements lack accessibility labels. | Add `Semantics` with appropriate labels to these elements. |

---

## Acceptance Criteria Check

- [x] AC-1: Trainee can see "Events" entry point from Community tab — Events icon in SchoolHomeScreen app bar (line 69-72).
- [x] AC-2: Event list shows upcoming events sorted by start_time with date-grouped sections — Implemented. **Missing "Next Week" group per UX spec (M8).**
- [x] AC-3: Event card shows title, date/time, event type badge, location, attendee count, RSVP status — All present in EventCard.
- [x] AC-4: Detail screen shows description, time range, location/meeting link, max attendees, attendee count — Present. **No actual address for in-person events (M2).**
- [x] AC-5: RSVP with three options, optimistic UI + rollback — Implemented in TraineeEventNotifier.rsvp().
- [x] AC-6: Can change RSVP, button reflects current status — SegmentedButton with selected set from current RSVP.
- [x] AC-7: Past events shown in separate section or dimmed — Both: separate "Past Events" section + opacity dimming.
- [x] AC-8: Cancelled events show badge and disable RSVP — EventStatusBadge shows "Cancelled", RSVP hidden (should be greyed per edge case #7 — m7).
- [x] AC-9: Full events show "Full" badge, disable Going but allow Interested — RsvpButton disables Going segment when at capacity. Correct.
- [x] AC-10: Trainer can create event with required fields — TrainerEventFormScreen has all fields. **Missing location field (M2).**
- [x] AC-11: Trainer can edit event — Edit mode loads existing data, submits via updateEvent.
- [x] AC-12: Trainer can cancel event — _confirmCancel dialog calls cancelEvent.
- [x] AC-13: Trainer can delete event with confirmation — _confirmDelete dialog calls deleteEvent.
- [x] AC-14: Trainer event list shows going/interested counts — EventCard shows going and interested counts.
- [ ] AC-15: Virtual "Join" button within 15 min or ongoing — **PARTIAL.** canJoinVirtual logic correct, button shows in detail screen. No Join button on list card for quick access. Silent failure when URL can't launch (C4).
- [ ] AC-17: All screens have loading, empty, and error states — **PARTIAL.** Loading uses CircularProgressIndicator not shimmer (M1). Detail screen has no loading/error state for API calls (M5).
- [ ] AC-18: All interactive elements have Semantics labels — **PARTIAL.** EventCard and RsvpButton have Semantics. Missing on Join button, empty states, detail screen elements (m8).
- [x] AC-16: Pull-to-refresh on both lists.

**Score: 15/18 AC fully met, 3 partially met.**

---

## Security Concerns

- No IDOR risk — all authorization enforced server-side. Mobile passes JWT; backend filters by trainer.
- Meeting URL launched via `Uri.tryParse` + `canLaunchUrl` — correct approach, no XSS risk in native Flutter.
- No data exposure — model contains only user-visible fields.

## Performance Concerns

- DateTime.now() called multiple times per frame (M3).
- Computed list properties re-sort on every access (M6).
- No pagination on event list — entire list fetched at once. Acceptable for v1.

---

## Quality Score: 6/10

The implementation covers the core happy path well. Event listing, RSVP with optimistic updates, create/edit/delete/cancel all work. The code structure follows existing patterns (repository -> provider -> screen), widgets are properly extracted, and the overall architecture is sound. Good use of const constructors, proper disposal of controllers, and mounted checks.

However, there are meaningful gaps that prevent shipping: error handling swallows all exceptions with no logging or differentiation (C2), PUT vs PATCH semantic mismatch (C3), the "Join Meeting" button can silently fail (C4), missing shimmer loading states (M1), the detail screen has no API fallback for deep links or stale state (M5), DRF validation errors are not parsed (M7), and date grouping is missing "Next Week" with a Sunday edge case bug (M8).

## Recommendation: REQUEST CHANGES

**Must fix before re-review:**
- All 4 Critical issues (C1-C4)
- Major issues M1, M4, M5, M7, M8, M9

**Should fix:**
- M2 (location field gap — may need backend check), M3, M6
- Minor issues m5 (consistency), m6 (type safety), m7 (cancelled RSVP greyed out)

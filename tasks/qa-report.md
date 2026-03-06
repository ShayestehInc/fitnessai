# QA Report: Community Events

## Date: 2026-03-05

## Test Results
- Backend tests: COULD NOT RUN (no PostgreSQL database available in this environment)
- Flutter tests: No new test files created for this feature
- Static analysis: Manual code review performed on all 13 implementation files

- Total acceptance criteria: 18
- Passed: 15
- Failed: 3

## Acceptance Criteria Verification

- [x] AC-1: Trainee can see an "Events" entry point from the Community/School tab -- **PASS**
  - `school_home_screen.dart` line 69-72: calendar icon (`Icons.event_outlined`) in app bar actions navigates to `/community/events`.

- [x] AC-2: Trainee event list shows upcoming events sorted by start_time, with date-grouped sections -- **PASS**
  - `event_provider.dart` line 38-41: `upcoming` getter sorts by `startsAt`.
  - `event_list_screen.dart` lines 79-125: `_buildGroupedEvents` groups into Today, Tomorrow, This Week, Next Week, Later.

- [x] AC-3: Trainee event list shows: title, date/time, event type badge, location/"Virtual", attendee count, RSVP status -- **PASS**
  - `event_card.dart` displays all required elements: title (line 93-100), date/time (line 109), type badge (line 62), Virtual/In Person (line 111-115), attendee count (line 117-123), RSVP indicator (line 86-87).

- [x] AC-4: Trainee can tap event to see full detail screen -- **PASS**
  - `event_detail_screen.dart` shows description, time range, location/meeting link, max attendees, attendee count. Route wired at `/community/events/:id`.

- [x] AC-5: Trainee can RSVP with three options with optimistic UI update and error rollback -- **PASS**
  - `event_provider.dart` lines 84-121: saves `previousEvents`, adjusts counts locally, calls API, replaces with server response on success, rolls back on error.

- [x] AC-6: Trainee can change RSVP, button reflects current status -- **PASS**
  - `rsvp_button.dart` uses `SegmentedButton` with `selected: current != null ? {current} : {}` and `emptySelectionAllowed: true`.

- [x] AC-7: Past events shown in separate "Past" section or visually dimmed -- **PASS**
  - Past events in separate section with "Past Events" header (event_list_screen.dart line 71-73).
  - Dimmed at 0.55 opacity (event_card.dart line 21-27).

- [x] AC-8: Cancelled events show "Cancelled" badge and disable RSVP button -- **PASS**
  - EventStatusBadge with 'cancelled' status shown (event_card.dart line 63-66).
  - RSVP disabled in detail screen (line 185: `disabled: event.isCancelled`).
  - Cancelled events in their own section in list view.

- [x] AC-9: Events at capacity show "Full" and disable RSVP to "Going" but allow "Interested" -- **PASS**
  - "Full" badge shown when `isAtCapacity && !isCancelled` (event_card.dart line 67-84).
  - Going segment disabled but Interested/Not Going remain enabled (rsvp_button.dart line 31).

- [x] AC-10: Trainer can create a new event with all required fields -- **PASS**
  - Form has: title, description, event_type, start_time, end_time, is_virtual toggle, meeting_link, max_attendees.
  - Note: Ticket mentions `location` field but backend model has no `location` field. Implementation correctly matches the backend.

- [x] AC-11: Trainer can edit an existing event -- **PASS**
  - Edit mode via `eventId` parameter. `_loadExistingEvent()` populates form. Route at `/trainer/events/:id/edit`.

- [x] AC-12: Trainer can cancel an event -- **PASS**
  - `_confirmCancel()` shows confirmation dialog, calls `cancelEvent()` which uses `updateEventStatus(eventId, 'cancelled')`.

- [x] AC-13: Trainer can delete an event with confirmation dialog -- **PASS**
  - `_confirmDelete()` shows AlertDialog with "Delete" and "Keep" options, calls `deleteEvent()`.

- [x] AC-14: Trainer event list shows attendee counts -- **PASS**
  - Same `EventCard` widget displays `goingCount` and `maybeCount`.

- [x] AC-15: Virtual events show "Join" button within 15 min of start or ongoing -- **PASS**
  - `canJoinVirtual` checks `isVirtual`, `!isCancelled`, and 15-min window (event_model.dart lines 83-88).
  - "Join Meeting" button shown conditionally (event_detail_screen.dart lines 129-142).

- [x] AC-16: Pull-to-refresh on both event lists -- **PASS**
  - Both trainee and trainer lists wrapped in `RefreshIndicator`. Empty states also support pull-to-refresh.

- [ ] AC-17: All screens have loading, empty, and error states -- **FAIL**
  - Loading: Uses `CircularProgressIndicator` instead of shimmer skeleton cards. Ticket explicitly requires "Shimmer skeleton cards (3 placeholder event cards) matching event card layout."
  - Empty and error states: Present on all screens. PASS for those.

- [ ] AC-18: All interactive elements have Semantics/accessibility labels -- **FAIL (Partial)**
  - Core elements have Semantics: EventCard (line 23-25), RsvpButton (line 23-24), Join button (line 133-134).
  - Missing: Section headers, empty/error views, trainer FAB (only has tooltip), form fields (relies on label text).

## Edge Case Verification

1. **No events exist** -- **PASS**
   - Trainee: `_EmptyView` with icon and "No upcoming events" message.
   - Trainer: `_TrainerEmptyView` with "Create Event" CTA button.

2. **Event started but not ended ("Happening Now")** -- **PASS**
   - `isHappeningNow` correctly checks time window. Green "Happening Now" badge displayed. RSVP still allowed.

3. **Event fully in the past** -- **PASS**
   - Filtered into "Past" section. Dimmed. RSVP hidden (`if (!event.isPast)`). "This event has ended" card shown.

4. **max_attendees is null (unlimited)** -- **PASS**
   - `isAtCapacity` returns false. Attendee display omits "/max" portion.

5. **max_attendees reached** -- **PASS**
   - "Full" badge displayed. Going disabled, Interested/Not Going remain available. Counts adjust correctly in optimistic update.

6. **Virtual event with no meeting_link** -- **PASS**
   - `isVirtual` returns false when `meetingUrl.isEmpty`, so Join button is hidden. Shows "In Person" label instead.

7. **Event cancelled after user RSVPed** -- **PASS**
   - Cancelled badge shown. RSVP greyed out with `Opacity(0.5)` and disabled. Cancellation message card displayed.

8. **Extremely long title/description** -- **PASS**
   - Card: title truncated at 2 lines with `TextOverflow.ellipsis`. Form: `maxLength: 200` / `maxLength: 2000` enforced.

9. **Timezone handling** -- **PASS**
   - Display: `.toLocal()` used consistently. Submission: `.toUtc().toIso8601String()` used.

10. **Concurrent RSVP changes** -- **PASS**
    - Optimistic update replaced by server response. 409 handled with specific message. Full rollback on error.

11. **Trainee removed from trainer** -- **PASS (by design)**
    - Backend row-level security returns 403/404. Mobile shows error state.

12. **Network error during RSVP** -- **FAIL (Minor)**
    - Provider correctly catches error and rolls back state (lines 110-120).
    - **BUG**: Error is set in provider `state.error` but the detail screen (`_EventDetailBody`) does NOT display it. The error only appears as an inline banner if user navigates back to the list. Ticket specifies a snackbar: "Could not update RSVP. Try again."

## Bugs Found

| # | Severity | Description |
|---|----------|-------------|
| 1 | Minor | Loading state uses `CircularProgressIndicator` instead of shimmer skeleton cards as specified in UX requirements. Both trainee and trainer event list screens affected. |
| 2 | Minor | RSVP error on detail screen is not surfaced to the user. Provider sets `state.error` but `_EventDetailBody` does not listen to or display error messages. The error only appears if user goes back to list. Ticket requires snackbar "Could not update RSVP. Try again." |
| 3 | Minor | Some secondary UI elements lack Semantics labels: section headers, empty/error views. Core interactive elements (cards, RSVP button, Join button) are properly labeled. |
| 4 | Low | Trainer form catches `on Exception` (trainer_event_form_screen.dart line 398) which won't catch `Error` subclasses. Acceptable for Dio errors but worth noting. |
| 5 | Low | `is_virtual` toggle is local-only UI state. Backend infers virtual from `meetingUrl.isNotEmpty`. If trainer toggles virtual ON but leaves link blank, event appears as "In Person" to trainees. |

## Confidence Level: MEDIUM

**Rationale**: 15 of 18 acceptance criteria pass. All 12 edge cases handled (11 PASS, 1 minor gap on error display). No critical or major bugs found. Three minor issues exist: (1) loading skeleton not shimmer, (2) RSVP error not shown on detail screen, (3) partial Semantics coverage. Backend tests could not be executed due to missing database. No Flutter tests were written for the new feature.

# Feature: Community Events — Trainer Create & Trainee RSVP (Mobile)

## Priority
High

## User Story
As a **trainer**, I want to create events (group workouts, live Q&As, check-ins, seminars) so that my trainees can see what's coming up and RSVP.

As a **trainee**, I want to browse upcoming events from my trainer, view event details, and RSVP so that I can plan my schedule and show my trainer I'm engaged.

## Context
The backend is **100% complete**. The following already exist:
- **Models**: `CommunityEvent` (title, description, event_type, start_time, end_time, location, max_attendees, is_virtual, meeting_link, cover_image, is_cancelled, trainer FK) and `EventRSVP` (event FK, user FK, status choices: GOING/INTERESTED/NOT_GOING, responded_at)
- **Trainer views**: `TrainerEventListCreateView`, `TrainerEventDetailView` (full CRUD, scoped to trainer)
- **Trainee views**: `TraineeEventListView`, `TraineeEventDetailView`, `TraineeEventRSVPView`
- **URLs**: All wired in `community/urls.py` and `trainer/urls.py`
- **API constants**: Already defined in `mobile/lib/core/constants/api_constants.dart` (`communityEvents`, `communityEventDetail(id)`, `communityEventRsvp(id)`)
- **Serializers**: `CommunityEventSerializer`, `CommunityEventCreateSerializer` exist in `community/serializers/`

What's missing: **All mobile screens, providers, repositories, and models.**

## Acceptance Criteria
- [ ] AC-1: Trainee can see an "Events" entry point from the Community/School tab (e.g., calendar icon in app bar or a tab/section)
- [ ] AC-2: Trainee event list screen shows upcoming events sorted by start_time, with date-grouped sections (Today, Tomorrow, This Week, Later)
- [ ] AC-3: Trainee event list shows: title, date/time, event type badge, location (or "Virtual"), attendee count, and the user's RSVP status
- [ ] AC-4: Trainee can tap an event to see the full detail screen with description, time range, location/meeting link, max attendees, and list of attendees (count)
- [ ] AC-5: Trainee can RSVP with three options: Going, Interested, Not Going — with optimistic UI update and error rollback
- [ ] AC-6: Trainee can change their RSVP (e.g., switch from Interested to Going) — the button reflects current status
- [ ] AC-7: Past events are shown in a separate "Past" section or are visually dimmed
- [ ] AC-8: Cancelled events show a clear "Cancelled" badge and disable the RSVP button
- [ ] AC-9: Events at capacity (attendee count >= max_attendees) show "Full" and disable RSVP to "Going" (but allow "Interested")
- [ ] AC-10: Trainer can create a new event from their community management area with: title, description, event_type, start_time, end_time, location, is_virtual, meeting_link, max_attendees
- [ ] AC-11: Trainer can edit an existing event (title, description, time, location, etc.)
- [ ] AC-12: Trainer can cancel an event (sets is_cancelled=true), which shows cancelled badge to trainees
- [ ] AC-13: Trainer can delete an event entirely (with confirmation dialog)
- [ ] AC-14: Trainer event list shows attendee counts (going/interested) for each event
- [ ] AC-15: Virtual events show a "Join" button linking to meeting_link when event is within 15 min of start or ongoing
- [ ] AC-16: Pull-to-refresh on both trainer and trainee event lists
- [ ] AC-17: All screens have loading, empty, and error states
- [ ] AC-18: All interactive elements have Semantics/accessibility labels

## Edge Cases
1. **No events exist yet** — empty state with illustration and "No upcoming events" message. For trainer, show "Create your first event" CTA.
2. **Event starts in the past but hasn't ended** — show as "Happening Now" with green indicator. RSVP still allowed.
3. **Event fully in the past** — show in "Past" section, disable RSVP, show final attendee count.
4. **max_attendees is null** — unlimited capacity, never show "Full" badge.
5. **max_attendees reached** — show "Full" badge, disable "Going" RSVP, allow "Interested" and "Not Going". If someone changes from Going to another status, spot opens up.
6. **Virtual event with no meeting_link** — hide "Join" button, show location as "Virtual" without link.
7. **Event cancelled after user RSVPed** — show cancelled badge, user's RSVP preserved but greyed out.
8. **Extremely long event title/description** — truncate in list with ellipsis, full display in detail screen.
9. **Timezone handling** — display times in device local timezone. Backend stores UTC.
10. **Concurrent RSVP changes** — optimistic update with rollback on 409/error. Server is source of truth.
11. **Trainee removed from trainer** — events become inaccessible (row-level security enforced by backend).
12. **Network error during RSVP** — show error snackbar, revert optimistic state.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network error loading events | Error card with "Could not load events" and Retry button | Catches DioException, displays error message |
| Network error during RSVP | Snackbar "Could not update RSVP. Try again." | Reverts optimistic state change |
| Event deleted while viewing detail | Snackbar "This event no longer exists" and pop back to list | 404 response handled gracefully |
| Network error creating event (trainer) | Error snackbar with message | Form stays populated, button re-enabled |
| Validation error creating event (trainer) | Inline field errors (e.g., "End time must be after start time") | Parse DRF error response, map to fields |

## UX Requirements
- **Loading state:** Shimmer skeleton cards (3 placeholder event cards) matching event card layout
- **Empty state:** Centered illustration with "No upcoming events" text. Trainer version includes "Create Event" button.
- **Error state:** Error icon + message + "Retry" button
- **Success feedback:** Snackbar on RSVP change ("You're going!"), event creation ("Event created"), deletion ("Event deleted")
- **RSVP buttons:** Three-way segmented control or chip group: Going (green), Interested (amber), Not Going (grey). Current selection is filled, others are outlined.
- **Event card layout:** Title (bold), date/time row (calendar icon), location row (pin icon or video icon for virtual), attendee count row (people icon), event type badge (chip), RSVP status indicator
- **Date grouping:** Sticky headers for "Today", "Tomorrow", "This Week", "Next Week", "Later"
- **Trainer create form:** Material date/time pickers, switch for is_virtual (shows/hides meeting_link field), character counters on title (200) and description (2000)
- **Pull-to-refresh:** Standard platform pull-to-refresh on list screens
- **Mobile behavior:** All content scrollable, no overflow. Bottom sheet for quick RSVP on list cards.

## Technical Approach

### Files to create:
- `mobile/lib/features/community/data/models/event_model.dart` — Manual model for CommunityEvent with fromJson, matching backend serializer fields
- `mobile/lib/features/community/data/models/event_rsvp_model.dart` — RSVP status enum and model
- `mobile/lib/features/community/data/repositories/event_repository.dart` — API calls: list events, get event detail, RSVP, trainer CRUD
- `mobile/lib/features/community/presentation/providers/event_provider.dart` — Riverpod StateNotifier for event list, detail, and RSVP state
- `mobile/lib/features/community/presentation/screens/event_list_screen.dart` — Trainee event list with date grouping
- `mobile/lib/features/community/presentation/screens/event_detail_screen.dart` — Trainee event detail with RSVP
- `mobile/lib/features/community/presentation/screens/trainer_event_list_screen.dart` — Trainer event management list
- `mobile/lib/features/community/presentation/screens/trainer_event_form_screen.dart` — Trainer create/edit event form
- `mobile/lib/features/community/presentation/widgets/event_card.dart` — Reusable event list card widget
- `mobile/lib/features/community/presentation/widgets/rsvp_button.dart` — Three-way RSVP toggle widget
- `mobile/lib/features/community/presentation/widgets/event_type_badge.dart` — Event type chip widget

### Files to modify:
- `mobile/lib/core/router/app_router.dart` — Add routes for event screens (trainee + trainer)
- `mobile/lib/features/community/presentation/screens/school_home_screen.dart` — Add Events entry point (calendar icon in app bar)
- Trainer navigation/community section — Add Events management entry point

### Dependencies:
- No new packages needed. Uses existing Dio, Riverpod, go_router patterns.
- API constants already defined in `api_constants.dart`
- Backend fully ready — no backend changes needed

### Key design decisions:
- Follow existing community screen patterns (SpaceListScreen, SavedItemsScreen) for consistency
- Use repository pattern: Screen -> Provider -> Repository -> ApiClient
- Optimistic RSVP updates with error rollback (same pattern as reaction toggles in CommunityFeedNotifier)
- Date grouping logic extracted to a utility function for testability
- Event model uses manual fromJson (consistent with CommunityPostModel pattern)
- Trainer event form reuses adaptive time/date pickers from calendar feature
- EventProvider uses StateNotifier with typed state class (loading, events, error, selectedEvent)

## Out of Scope
- Event notifications/reminders (push notification when event is starting soon)
- Recurring events
- Event cover image upload from mobile (model supports it, skip for v1)
- Event search/filter
- Web dashboard event management (separate ticket)
- Event chat/discussion thread
- Calendar integration (syncing events to Google/Apple calendar)
- Event attendance tracking (checking in at the event)

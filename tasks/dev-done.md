# Dev Done: Community Events — Trainer Create & Trainee RSVP (Mobile)

## Date: 2026-03-05

## Files Created
- `features/community/data/models/event_model.dart` — CommunityEventModel with fromJson, copyWith, computed getters (isPast, isHappeningNow, isAtCapacity, canJoinVirtual, eventTypeLabel). RsvpStatus enum with apiValue/fromApi/label.
- `features/community/data/repositories/event_repository.dart` — Full CRUD: getEvents, getEventDetail, rsvp (trainee); getTrainerEvents, createEvent, updateEvent, deleteEvent, updateEventStatus (trainer).
- `features/community/presentation/providers/event_provider.dart` — TraineeEventNotifier (loadEvents, optimistic rsvp with rollback), TrainerEventNotifier (loadEvents, createEvent, updateEvent, deleteEvent, cancelEvent). Both autoDispose.
- `features/community/presentation/widgets/event_type_badge.dart` — EventTypeBadge and EventStatusBadge (live/cancelled/completed/scheduled).
- `features/community/presentation/widgets/rsvp_button.dart` — Three-way SegmentedButton (Going/Interested/Can't Go) with capacity-aware disabling and Semantics.
- `features/community/presentation/widgets/event_card.dart` — Reusable card with title, date/time, location, attendee counts, badges, RSVP indicator. Dimmed for past/cancelled.
- `features/community/presentation/screens/event_list_screen.dart` — Trainee event list with date-grouped sections (Today/Tomorrow/This Week/Later), Past/Cancelled sections, pull-to-refresh, empty/error/loading states.
- `features/community/presentation/screens/event_detail_screen.dart` — Detail view with full info, RSVP button, "Join Meeting" for virtual events within 15min window, cancelled/past banners.
- `features/community/presentation/screens/trainer_event_list_screen.dart` — Trainer event management list with FAB to create, upcoming/cancelled/past grouping, edit on tap.
- `features/community/presentation/screens/trainer_event_form_screen.dart` — Create/edit form with title, description, event type dropdown, date/time pickers, virtual toggle, meeting URL, max attendees. Cancel/delete with confirmation dialogs. PopScope during submission.

## Files Modified
- `core/router/app_router.dart` — Added 5 routes: community-events, community-event-detail, trainer-events, trainer-event-create, trainer-event-edit.
- `features/community/presentation/screens/school_home_screen.dart` — Added Events icon button in app bar actions.
- `features/trainer/presentation/screens/trainer_dashboard_screen.dart` — Added "Manage Events" card in dashboard between Announcements and Check-In Forms.

## Key Decisions
1. Optimistic RSVP with rollback — matches existing reaction toggle pattern in CommunityFeedNotifier
2. Date grouping uses local timezone — backend stores UTC, we convert with .toLocal()
3. EventCard dimmed (opacity 0.55) for past/cancelled events
4. "Join Meeting" button only shows within 15-min pre-start window and during event
5. TrainerEventFormScreen doubles as create and edit — `eventId` param determines mode
6. Cancel and Delete are separate actions — cancel sets status, delete removes entirely
7. Both event providers use autoDispose to release memory when screens are popped
8. Used SegmentedButton for RSVP instead of custom chip group — follows Material 3 guidelines

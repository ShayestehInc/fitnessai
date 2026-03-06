# UX Audit: Community Events Feature

## Audit Date: 2026-03-05

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | **Critical** | RSVP flow (backend) | Backend `TraineeEventRSVPView.post()` returned only `{'status': 'going'}` but mobile `EventRepository.rsvp()` calls `CommunityEventModel.fromJson()` expecting a full event object. This caused a runtime crash on every RSVP. | **FIXED.** Backend now returns the full event serializer response after RSVP, matching mobile expectations. |
| 2 | **High** | Event update flow (backend) | Backend `TrainerEventDetailView` only defined `put` and `delete` methods, but mobile `EventRepository.updateEvent()` sends `PATCH`. All event updates from mobile would get 405 Method Not Allowed. | **FIXED.** Added `patch` method to `TrainerEventDetailView` with shared `_update()` helper that supports both PUT (full) and PATCH (partial). |
| 3 | **Medium** | Event list (trainee, backend) | Backend `TraineeEventListView.get_queryset()` filtered to only `SCHEDULED`/`LIVE` events, but the mobile `EventListState` has `past` and `cancelled` computed lists. These sections would always be empty. | **FIXED.** Removed status filter from backend queryset so all event statuses are returned. |
| 4 | **Medium** | RSVP on cancelled events | Mobile correctly dims the RSVP button and disables it for cancelled events, but the backend had no server-side guard. A crafted API call could RSVP to cancelled/completed events. | **FIXED.** `EventService.rsvp()` now raises `ValueError` for cancelled/completed events; view returns 409. |
| 5 | **Minor** | TrainerEventListScreen | FAB missing Semantics wrapper -- screen readers may not announce its purpose clearly. | **FIXED.** Added `Semantics(label: 'Create a new event', button: true)` wrapper. |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A | EventCard has Semantics -- good (label includes title, type, date; button: true) | No fix needed |
| 2 | A | RsvpButton has Semantics -- good (label includes current status) | No fix needed |
| 3 | A | EventListScreen loading skeleton has Semantics -- good | No fix needed |
| 4 | A | FAB in TrainerEventListScreen was missing Semantics | FIXED |

## Missing States
- [x] Loading / skeleton -- present in EventListScreen (skeleton cards), TrainerEventListScreen (CircularProgressIndicator), EventDetailScreen (CircularProgressIndicator)
- [x] Empty / zero data -- present in EventListScreen (_EmptyView with icon, text, pull-to-refresh), TrainerEventListScreen (_TrainerEmptyView with "Create Event" CTA)
- [x] Error / failure -- present with retry buttons in both list screens; inline error banner for non-critical errors; SnackBars for RSVP failures with rollback
- [x] Success / confirmation -- SnackBar feedback on create/update/delete/cancel/RSVP
- [x] Disabled / submitting -- Submit button disabled and shows spinner during submission; PopScope blocks back nav during submit
- [x] Cancelled event state -- Cancellation banner shown in detail screen, dimmed card in list, RSVP disabled
- [x] Past event state -- "This event has ended" card shown, dimmed in list, RSVP section hidden
- [x] At capacity state -- "Full" badge in card and detail, "Going" segment disabled when at capacity
- [ ] Offline / degraded -- not handled (acceptable; errors fall through to error state)

## Positive UX Findings

1. **Optimistic RSVP updates** in `TraineeEventNotifier.rsvp()` with rollback on failure -- excellent UX pattern.
2. **Smart date grouping** (Today/Tomorrow/This Week/Next Week/Later) in trainee event list.
3. **Confirmation dialogs** for destructive actions (cancel event, delete event).
4. **Virtual event join window** -- "Join Meeting" button only appears 15 minutes before and until end time.
5. **Deep link support** -- `EventDetailScreen` falls back to API fetch when event not in cache.
6. **Form validation** -- end-before-start check, URL format validation, max attendees min value.
7. **Pull-to-refresh** on both list screens.

## Overall UX Score: 8/10

The feature has comprehensive state handling, good accessibility, optimistic updates, and proper error rollback. The critical issue (RSVP response format mismatch) and high issue (PATCH method missing) would have caused runtime failures but are now fixed. Remaining gap is offline/degraded handling.

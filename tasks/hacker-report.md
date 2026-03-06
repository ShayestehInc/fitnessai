# Hacker Report: Community Events Feature

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| - | - | - | - | - | No dead buttons found. All buttons, FABs, and interactive elements are wired to functional handlers. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | TrainerEventFormScreen | Delete operation shows no visual feedback -- screen appears frozen while API call runs. `_isDeleting` flag only blocks back navigation via `PopScope` but no spinner or overlay is shown. | FIXED -- Added a `Stack` with a translucent overlay + `CircularProgressIndicator` when `_isDeleting` is true. |
| 2 | Low | EventCard._detailRow | Attendee counts string can get very long ("12 going, 8 interested / 20 max") and overflow on narrow screens. | Already handled via `Expanded` + `TextOverflow.ellipsis` on the Text widget. No fix needed. |
| 3 | Low | EventListScreen skeleton | Skeleton containers use flat `color: theme.dividerColor` without `borderRadius`, causing visual inconsistency with the rounded badge placeholder above them. | Cosmetic only, not fixed. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Event model parsing | API returns event with `starts_at: null` or missing field | Should handle gracefully with fallback | `DateTime.parse('')` throws `FormatException`, crashing the entire event list. FIXED -- changed to `DateTime.tryParse` with `DateTime.now()` fallback. |
| 2 | Major | RSVP optimistic update | 1. Event has 0 going count. 2. User has existing RSVP of "going". 3. User switches to "maybe". | Going count should stay at 0 (already 0 on server) | `(newCounts['going'] ?? 1) - 1` evaluates to `(0 ?? 1) - 1 = -1`, displaying "-1 going" in the UI until server response arrives. FIXED -- clamped decrement at 0. |
| 3 | Major | Cancelled events vanish | 1. Trainer cancels an event that has already passed its start time. 2. Trainee views event list. | Event should appear in Cancelled section | `cancelled` getter filters `!e.isPast`, `past` getter filters `!e.isCancelled` -- the event matches neither list and disappears entirely. FIXED -- removed `!e.isPast` from `cancelled` getter. |
| 4 | Medium | End time before start time | 1. Open event form. 2. Pick a start date of March 10. 3. Pick an end date of March 8. 4. Submit. | End time should auto-correct or show immediate feedback | End date picker allowed selecting a date before start. Validation only fires on submit. FIXED -- added auto-correction in `_pickDate` and `_pickTime` for the end field (same pattern already existed for start field). |
| 5 | Low | Trainer form edit fallback | 1. Provider gets disposed (e.g., memory pressure). 2. User navigates to edit event `/trainer/events/5/edit`. | Should fetch from API and populate form | `_loadExistingEvent()` reads from in-memory provider only. If event is not found, form opens blank with no error -- trainer thinks they're creating a new event. Not fixed (requires API fetch integration in `initState`). |
| 6 | Low | RSVP on deep-linked event | 1. Open event via deep link `/community/events/42`. 2. Event loads via `eventDetailProvider`. 3. Tap RSVP button. | RSVP should work | RSVP calls `ref.read(traineeEventProvider.notifier).rsvp(event.id, status)` but the event was loaded via `eventDetailProvider`, not `traineeEventProvider`. The event won't be found in `traineeEventProvider.state.events`, so the optimistic update produces no visible change. The server call still works, but the UI doesn't update until a full reload. Not fixed (requires provider architecture change). |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | EventDetailScreen | Add "Add to Calendar" button for upcoming events (export .ics or use platform calendar API) | Users want to remember events; this is table-stakes for any event feature |
| 2 | High | TrainerEventListScreen | Add event attendee list view (who RSVPed going/maybe/not going) | Trainers need to know who's coming to plan accordingly |
| 3 | Medium | EventListScreen | Add filter tabs (All / Going / Interested) so trainees can quickly find events they've RSVPed to | With many events, finding "my events" requires scanning every card |
| 4 | Medium | TrainerEventFormScreen | Add "Duplicate Event" action for recurring event creation (copy all fields, clear dates) | Trainers often create weekly recurring events with same title/description/type |
| 5 | Low | RsvpButton | Add haptic feedback on RSVP selection change | Makes the interaction feel more responsive and tactile |
| 6 | Low | EventCard | Add countdown timer for events starting within 1 hour ("Starts in 23 min") | Creates urgency and is more useful than showing the absolute time |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 1 (fixed)
- Logic bugs found: 6 (4 fixed, 2 documented)
- Improvements suggested: 6
- Items fixed by hacker: 5

## Chaos Score: 6/10

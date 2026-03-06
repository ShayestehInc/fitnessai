# Architecture Review: Community Events Feature

## Review Date: 2026-03-05

## Architectural Alignment
- [x] Follows existing layered architecture (Screen -> Provider -> Repository -> ApiClient)
- [x] Models properly typed with named constructors, no raw Maps
- [x] State management correct (StateNotifier + State class)
- [x] Consistent with existing codebase patterns
- [x] No business logic in views/screens

### Layer Breakdown

- **Model** (`event_model.dart`): `CommunityEventModel` with `fromJson` factory, `copyWith`, and computed getters. `RsvpStatus` enum with API serialization. Uses `Map<String, int>` for attendee counts (typed, not raw dynamic). Follows same pattern as `CommunityPostModel`, `AnnouncementModel`, etc.
- **Repository** (`event_repository.dart`): Clean separation of trainee vs trainer endpoints. Returns typed models, not raw maps. Follows the `datatypes.md` rule. All API calls go through `ApiClient.dio`.
- **Providers** (`event_provider.dart`): `StateNotifier` + `EventListState` for both trainee and trainer. Optimistic updates for RSVP. `FutureProvider.autoDispose.family` for single event detail (deep link fallback). `autoDispose` on all providers -- correct.
- **Widgets** (`event_card.dart`, `event_type_badge.dart`, `rsvp_button.dart`): Stateless, reusable, accept data + callbacks. Widget sizes are well within the 150-line limit.
- **Screens** (`event_list_screen.dart`, `event_detail_screen.dart`, `trainer_event_list_screen.dart`, `trainer_event_form_screen.dart`): Use `ConsumerStatefulWidget` for stateful forms, `ConsumerWidget` for display. All screens under 300 lines except trainer form (now ~510 lines with Stack overlay fix).
- **Routes** (`app_router.dart`): Registered at `/community/events`, `/community/events/:id`, `/trainer/events`, `/trainer/events/create`, `/trainer/events/:id/edit`. Uses `context.push` with pop results for create/edit/delete flows.
- **API Constants** (`api_constants.dart`): All endpoints centralized. Consistent naming.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | No schema changes; model is a client-side DTO |
| Types correct | PASS | All fields properly typed; `Map<String, int>` for counts, enums for RSVP |
| No raw Maps or `dynamic` leaking into UI | PASS | `fromJson` converts everything to typed fields |
| `copyWith` handles all mutation cases | PASS | Supports `clearRsvp` flag for nullable field |
| Computed getters correct | PASS | `isPast`, `isHappeningNow`, `canJoinVirtual`, `isAtCapacity` all well-defined |
| Provider keying correct | PASS | `eventDetailProvider` keyed by `int eventId` |

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Event list fetch | `getEvents()` fetches all events without pagination | Acceptable for now -- event count per trainer is bounded (tens to low hundreds). Add cursor-based pagination if event count grows significantly |
| 2 | Computed getters on state | `upcoming`, `past`, `cancelled` re-sort on every access | Minor -- list sizes are small. Could memoize if this becomes a hot path |
| 3 | Optimistic RSVP | Previous events snapshot kept in closure for rollback | Correct pattern; no memory concern since it's a single list copy |
| 4 | `eventDetailProvider` | `autoDispose.family` keyed by event ID -- entries cleaned up when unwatched | Correct |

## Technical Debt
| # | Description | Severity |
|---|-------------|----------|
| 1 | `TrainerEventFormScreen` is ~510 lines. Should extract date/time picker section and event type selector into separate widget files. | Minor |
| 2 | `_loadExistingEvent()` reads from provider in `initState` -- if provider is stale (disposed + recreated), the event won't be found and no error is shown. Should fallback to API fetch like `EventDetailScreen` does. | Medium |
| 3 | The `EventListState` is shared between trainee and trainer providers but the computed getters (`upcoming`, `past`, `cancelled`) are coupled to the state class. If trainee and trainer need different grouping logic in the future, the state class would need to be split. | Low |
| 4 | `_formatDateRange` and `_formatFullDateRange` are duplicated date-formatting logic. Could be extracted to a shared utility. | Low |

## Fixes Applied
1. **Fixed `DateTime.parse` crash on null/empty dates** in `event_model.dart` lines 55-56: Changed `DateTime.parse(json['starts_at'] as String? ?? '')` to `DateTime.tryParse(...)` with `DateTime.now()` fallback, matching the safe pattern already used for `createdAt`/`updatedAt` on lines 63-64.
2. **Fixed negative RSVP count in optimistic update** in `event_provider.dart` line 95: Changed `(newCounts[oldStatus.apiValue] ?? 1) - 1` to clamp at 0, preventing display of negative attendee counts.
3. **Fixed cancelled events disappearing** in `event_provider.dart`: The `cancelled` getter filtered by `!e.isPast`, causing past cancelled events to vanish from both the `cancelled` and `past` lists (since `past` also excludes cancelled). Removed the `!e.isPast` filter from `cancelled`.

## Architecture Score: 8/10
## Recommendation: APPROVE

The feature follows all established architectural patterns correctly. The layering is clean, types are sound, state management uses Riverpod StateNotifier properly with optimistic updates and rollback. The three bugs fixed were implementation-level issues, not architectural problems. The remaining debt items are minor and consistent with existing codebase conventions.

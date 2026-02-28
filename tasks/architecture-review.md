# Architecture Review: Calendar Integration Completion (Pipeline 41)

## Review Date
2026-02-27

## Files Reviewed
### Backend
- `backend/calendars/models.py`
- `backend/calendars/serializers.py`
- `backend/calendars/services.py`
- `backend/calendars/views.py`
- `backend/calendars/urls.py`

### Mobile
- `mobile/lib/features/calendar/data/models/calendar_connection_model.dart`
- `mobile/lib/features/calendar/data/repositories/calendar_repository.dart`
- `mobile/lib/features/calendar/presentation/providers/calendar_provider.dart`
- `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart`
- `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart`
- `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart`
- `mobile/lib/features/calendar/presentation/widgets/*.dart` (9 files)
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/core/constants/api_constants.dart`

---

## Architectural Alignment
- [x] Follows existing layered architecture (Provider -> Repository -> ApiClient)
- [x] Models/schemas in correct locations (`data/models/`, `data/repositories/`)
- [x] Consistent with existing feature-first folder structure
- [x] Row-level security enforced (every view filters by authenticated user)
- [x] Routes registered in `app_router.dart`
- [x] API constants centralized in `api_constants.dart`
- [x] FIXED: Business logic was in `CreateCalendarEventView` (dispatching to Google vs Microsoft). Moved to `CalendarSyncService.create_external_event()`.
- [x] FIXED: `DisconnectCalendarView` and `SyncCalendarView` accepted arbitrary `provider` URL parameters without validation. Added `_validate_provider()` guard.
- [x] FIXED: `CalendarEventsView.get_queryset()` now validates the `provider` query param before filtering.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | No breaking changes. `CalendarConnection`, `CalendarEvent`, `TrainerAvailability` models are clean and well-structured. |
| Encryption at rest for tokens | PASS | `_access_token` / `_refresh_token` use Fernet encryption with property getters/setters. |
| Indexes for new queries | NOTE | `CalendarEvent` queries filter by `connection` + `start_time`. The `connection` FK already has an index. `start_time` is used in ordering. Consider adding `index_together = [['connection', 'start_time']]` if event counts per connection grow large. Not blocking. |
| No N+1 query patterns | PASS | `CalendarEventsView` uses `select_related('connection')`. `TrainerAvailability` views are single-table queries. |
| Mobile models match backend serializer output | PASS | All field names and types align. `provider_display` fallback in `CalendarConnectionModel.fromJson` is defensive. |
| Unique constraints | PASS | `CalendarConnection` has `unique_together = [['user', 'provider']]`. `CalendarEvent` has `unique_together = [['connection', 'external_id']]`. |

## Scalability Concerns

| # | Area | Issue | Status | Recommendation |
|---|------|-------|--------|----------------|
| 1 | Mobile events fetch | `getEvents()` fetched only first page of paginated results (backend default PAGE_SIZE=20), silently truncating event lists for active calendars. | FIXED | Added auto-pagination in `CalendarRepository.getEvents()` with a `maxPages=10` safety bound (~200 events max). |
| 2 | Backend HTTP timeouts | All `requests.get/post` calls in `GoogleCalendarService` and `MicrosoftCalendarService` had no timeout, risking indefinite hangs if Google/Microsoft APIs are slow. | FIXED | Added `_REQUEST_TIMEOUT = (10, 30)` (connect=10s, read=30s) to all external HTTP calls. |
| 3 | Sync batch size | `CalendarSyncService.sync_events()` calls `update_or_create` in a loop for each event (N queries for N events). | NOT FIXED | For typical trainer calendars (< 200 events in 30 days), this is acceptable. If event volumes grow, consider `bulk_create` with `update_conflicts=True` (Django 4.1+). Not blocking. |
| 4 | Single isLoading flag | `CalendarNotifier` uses one `isLoading` boolean for all operations. Concurrent `loadConnections()` + `loadEvents()` creates ambiguous UI state. | NOTE | Not blocking but worth refactoring to per-operation loading flags (e.g., `isLoadingConnections`, `isLoadingEvents`, `isSyncing`) in a future iteration. Current usage patterns are sequential so the impact is minimal. |

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `CalendarConnectionScreen._showCallbackDialog` requires manual copy-paste of OAuth code and state from browser. This is a temporary UX workaround until deep linking is implemented. | Low | Implement deep link / custom URL scheme callback handler. The current approach works but is clunky. |
| 2 | `apiClientProvider` is defined in both `auth_provider.dart` and `payment_provider.dart`. The calendar feature imports from `auth_provider.dart`, which is correct. The duplicate in payments is pre-existing tech debt, not introduced by this PR. | Low | Consolidate to a single `apiClientProvider` in a shared location. |
| 3 | Backend `CalendarSyncService` raises a generic `Exception` with string message when token refresh fails. | Low | Consider a custom `CalendarTokenExpiredError` exception class for cleaner error handling upstream. |

## Validation Gaps (Fixed)

| # | Area | Issue | Status |
|---|------|-------|--------|
| 1 | `CreateEventSerializer` | No cross-field validation: `end_time` could be before `start_time`. | FIXED - Added `validate()` method. |
| 2 | `OAuthCallbackSerializer` | `code` and `state` fields had no max_length, allowing arbitrarily large payloads. | FIXED - Added `max_length` and `min_length` constraints. |
| 3 | `DisconnectCalendarView` | `provider` URL parameter not validated against `Provider.choices`. | FIXED - Added `_validate_provider()`. |
| 4 | `SyncCalendarView` | Same `provider` URL parameter issue. | FIXED - Added `_validate_provider()`. |

## Positive Architectural Observations

1. **Token encryption**: The `CalendarConnection` model properly encrypts OAuth tokens at rest using Fernet, with clean property-based access. This is a security-conscious design.

2. **Service layer separation**: `GoogleCalendarService`, `MicrosoftCalendarService`, and `CalendarSyncService` properly separate OAuth mechanics, API calls, and sync logic. After the fix, event creation also routes through the service layer.

3. **CSRF protection on OAuth**: State tokens are generated server-side, stored in cache with TTL, and verified on callback. This prevents CSRF attacks on the OAuth flow.

4. **Optimistic updates**: The `toggleAvailability` method in `CalendarNotifier` uses optimistic update with rollback on failure. This is the right UX pattern for toggle operations.

5. **Widget extraction**: All screens stay under 230 lines. Reusable widgets (`CalendarCard`, `CalendarEventTile`, `AvailabilitySlotTile`, `TimeTile`, etc.) are properly extracted. Consistent with codebase conventions.

6. **Defensive JSON parsing**: Mobile models use null-safe parsing with fallback defaults (`as int? ?? 0`, `as String? ?? json['provider']`), protecting against backend API changes.

7. **Row-level security**: Every backend view filters by authenticated user. No IDOR vulnerabilities. `limit_choices_to={'role': 'TRAINER'}` on model FKs adds defense-in-depth.

## Architecture Score: 8/10

The calendar feature follows the established architecture well. The Provider -> Repository -> ApiClient pattern on mobile is correct. The backend properly separates concerns between services, serializers, and views. The primary issues were: (a) business logic leaked into `CreateCalendarEventView` (now fixed), (b) missing input validation on provider URL params and serializer cross-field checks (now fixed), and (c) missing HTTP timeouts on external API calls (now fixed). The remaining items (single isLoading flag, manual OAuth callback UX) are minor and do not warrant blocking.

## Recommendation: APPROVE

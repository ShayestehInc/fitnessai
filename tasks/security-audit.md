# Security Audit: Calendar Integration Completion (Pipeline 41)

## Audit Date
2026-02-27

## Scope
Pipeline 41 -- Calendar Integration feature. Full OAuth flow (Google + Microsoft), calendar event sync/create, trainer availability CRUD. Backend: `backend/calendars/` (views.py, serializers.py, models.py, services.py, admin.py, urls.py). Mobile: `mobile/lib/features/calendar/` (all data/models, data/repositories, presentation layers). Router: calendar routes in `mobile/lib/core/router/app_router.dart`.

## Files Audited

### Backend
1. `backend/calendars/views.py` -- 12 view classes/functions, OAuth callbacks, event CRUD, availability CRUD
2. `backend/calendars/serializers.py` -- 5 serializer classes including OAuth callback and event creation
3. `backend/calendars/models.py` -- CalendarConnection (encrypted tokens), CalendarEvent, TrainerAvailability
4. `backend/calendars/services.py` -- GoogleCalendarService, MicrosoftCalendarService, CalendarSyncService
5. `backend/calendars/urls.py` -- 10 URL patterns
6. `backend/calendars/admin.py` -- Admin panel registration

### Mobile
7. `mobile/lib/features/calendar/data/models/calendar_connection_model.dart` -- Data models
8. `mobile/lib/features/calendar/data/repositories/calendar_repository.dart` -- API repository
9. `mobile/lib/features/calendar/presentation/providers/calendar_provider.dart` -- Riverpod state management
10. `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart` -- OAuth connection UI
11. `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart` -- Event list screen
12. `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart` -- Availability CRUD screen
13. `mobile/lib/features/calendar/presentation/widgets/calendar_card.dart` -- Connection card widget
14. `mobile/lib/features/calendar/presentation/widgets/calendar_actions_section.dart` -- Actions section
15. `mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart` -- Event tile
16. `mobile/lib/features/calendar/presentation/widgets/availability_slot_tile.dart` -- Availability slot tile
17. `mobile/lib/features/calendar/presentation/widgets/availability_slot_editor.dart` -- Availability editor
18. `mobile/lib/features/calendar/presentation/widgets/calendar_connection_header.dart` -- Header banner
19. `mobile/lib/features/calendar/presentation/widgets/calendar_no_connection_view.dart` -- No connection state
20. `mobile/lib/features/calendar/presentation/widgets/calendar_provider_filter.dart` -- Provider filter chips
21. `mobile/lib/features/calendar/presentation/widgets/time_tile.dart` -- Time display widget

### Configuration
22. `mobile/lib/core/constants/api_constants.dart` -- Calendar API endpoint constants
23. `mobile/lib/core/router/app_router.dart` -- Calendar route definitions

---

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history
- [x] All user input sanitized
- [x] Authentication checked on all new endpoints (IsAuthenticated + IsTrainer on all views)
- [x] Authorization -- correct role/permission guards (trainer-only via IsTrainer permission)
- [x] No IDOR vulnerabilities (all querysets filter by authenticated user)
- [N/A] File uploads validated (no file uploads in this feature)
- [x] Rate limiting on sensitive endpoints (global user throttle: 120/minute applies)
- [x] Error messages don't leak internals (FIXED -- see below)
- [x] CORS policy appropriate (production restricts to env-configured origins)

---

## Secrets Scan

Performed grep across ALL changed files (backend + mobile + task artifacts) for:
- API keys, passwords, secrets, tokens, credentials, bearer tokens
- Provider-specific prefixes (`sk_live`, `pk_live`, `sk_test`, `OPENAI_`, `STRIPE_`, `AWS_`)
- Private keys, environment variable literals

**Result: CLEAN.** All OAuth client secrets are loaded from Django settings via `getattr(settings, ...)` which reads from environment variables. No hardcoded credentials found. The `CALENDAR_ENCRYPTION_KEY` is configured via `os.getenv()` in settings.py. No secrets in any `.dart`, `.py`, or `.md` file.

---

## Injection Vulnerabilities
| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

**Details:**
- **SQL Injection:** All database queries use Django ORM (`objects.filter()`, `objects.get()`, `objects.update_or_create()`). No raw SQL. The `provider` URL parameter is validated against `CalendarConnection.Provider.choices` before ORM use.
- **XSS:** No HTML rendering of user input. All API responses are JSON. Mobile Flutter UI uses `Text()` widgets which auto-escape.
- **Command Injection:** No shell execution anywhere in the calendar module.
- **Path Traversal:** No file path operations.
- **OData Injection (Microsoft Graph):** The `$filter` parameter in `MicrosoftCalendarService.get_events()` uses only datetime values derived from `datetime.isoformat()` -- not user-controlled strings. Safe.

---

## Auth & Authz Issues
| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found (all verified) | -- |

**Verification of every endpoint:**

| Endpoint | Method | Permission Classes | QuerySet Scoping |
|----------|--------|-------------------|------------------|
| `GET /api/calendar/connections/` | GET | IsAuthenticated, IsTrainer | `filter(user=user)` |
| `GET /api/calendar/google/auth/` | GET | IsAuthenticated, IsTrainer | N/A (generates URL) |
| `POST /api/calendar/google/callback/` | POST | IsAuthenticated, IsTrainer | `update_or_create(user=user, ...)` |
| `GET /api/calendar/microsoft/auth/` | GET | IsAuthenticated, IsTrainer | N/A (generates URL) |
| `POST /api/calendar/microsoft/callback/` | POST | IsAuthenticated, IsTrainer | `update_or_create(user=user, ...)` |
| `POST /api/calendar/<provider>/disconnect/` | POST | IsAuthenticated, IsTrainer | `get(user=user, provider=...)` |
| `POST /api/calendar/<provider>/sync/` | POST | IsAuthenticated, IsTrainer | `get(user=user, provider=..., status=...)` |
| `GET /api/calendar/events/` | GET | IsAuthenticated, IsTrainer | `filter(connection__in=user_connections)` |
| `POST /api/calendar/events/create/` | POST | IsAuthenticated, IsTrainer | `filter(user=user, status=...)` |
| `GET/POST /api/calendar/availability/` | GET/POST | IsAuthenticated, IsTrainer | `filter(trainer=user)` / `save(trainer=user)` |
| `GET/PUT/PATCH/DELETE /api/calendar/availability/<pk>/` | CRUD | IsAuthenticated, IsTrainer | `filter(trainer=user)` |

All endpoints require both `IsAuthenticated` AND `IsTrainer`. No endpoint is accessible to trainees or unauthenticated users. Every queryset filters by the authenticated user, preventing cross-trainer data access.

---

## IDOR Analysis

**Scenario: Trainer A tries to access Trainer B's calendar data.**

1. **Connections:** `CalendarConnectionListView.get_queryset()` filters `user=request.user`. Trainer A only sees their own connections. SAFE.
2. **Events:** `CalendarEventsView.get_queryset()` filters by `connection__in=connections` where connections are pre-filtered by `user=request.user`. SAFE.
3. **Availability:** Both list and detail views filter `trainer=request.user`. The detail view uses `get_queryset()` for lookup, so `GET /availability/123/` by Trainer A will return 404 if slot 123 belongs to Trainer B. SAFE.
4. **OAuth State:** Cache keys include user ID (`google_oauth_state_{user.id}`). No cross-user state confusion possible. SAFE.
5. **Calendar Sync:** `SyncCalendarView` looks up `CalendarConnection.objects.get(user=user, ...)`. Trainer A cannot trigger sync on Trainer B's connection. SAFE.

**Verdict: No IDOR vulnerabilities found.**

---

## Data Exposure Assessment

**CalendarConnectionSerializer fields exposed:**
`id`, `provider`, `provider_display`, `status`, `status_display`, `is_connected`, `calendar_email`, `calendar_name`, `sync_enabled`, `last_synced_at`, `created_at`

**NOT exposed:** `_access_token`, `_refresh_token`, `token_expires_at`, `scopes`, `sync_error`, `calendar_id`. These are correctly excluded from the serializer `fields` list.

**CalendarEventSerializer fields exposed:**
Standard event details (title, description, location, times, type). No sensitive internal fields leaked.

**Admin Panel:** Encrypted token fields (`_access_token`, `_refresh_token`) are now excluded from admin detail view via `exclude` attribute. (FIXED)

---

## Critical Issues (Fixed)

| # | Severity | File:Line | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| 1 | Critical | `views.py:128-132` (Google callback) | Exception details leaked to client via `f'Failed to connect Google Calendar: {str(e)}'`. Could expose internal paths, Google API error details, token exchange failures, or stack trace fragments. | Replaced with generic message: `'Failed to connect Google Calendar. Please try again.'` Added `logger.exception()` for server-side visibility. |
| 2 | Critical | `views.py:222-226` (Microsoft callback) | Same issue for Microsoft callback. `str(e)` could expose Microsoft Graph error details. | Replaced with generic message. Added `logger.exception()`. |
| 3 | Critical | `views.py:291-295` (Sync) | Sync failure exposed internal error via `f'Sync failed: {str(e)}'`. Could reveal token refresh failures, API rate limit details. | Replaced with generic message. Added `logger.exception()`. |
| 4 | Critical | `views.py:389-393` (Create event) | Event creation failure exposed error via `f'Failed to create event: {str(e)}'`. | Replaced with generic message. Added `logger.exception()`. |

---

## High Issues (Fixed)

| # | Severity | File:Line | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| 5 | High | `serializers.py:57-58` (OAuthCallbackSerializer) | `code` and `state` fields had no `max_length` constraint. OAuth authorization codes are typically short (<512 chars). Without limits, attackers could send multi-MB payloads to stress the backend and cache layer. The `state` is compared against a cached value that is always 43 chars (`secrets.token_urlsafe(32)`). | Added `max_length=2048, min_length=1` to `code`. Added `max_length=256, min_length=1` to `state`. |
| 6 | High | `views.py` (Disconnect + Sync views) | `provider` URL path parameter was not validated against known choices before use. While Django ORM prevents SQL injection, an arbitrary string could be passed and would result in an unnecessary DB query. Defense-in-depth requires explicit validation. | Added `_validate_provider()` helper that checks against `CalendarConnection.Provider.choices`. Applied to `DisconnectCalendarView`, `SyncCalendarView`, and `CalendarEventsView` query parameter. |

---

## Medium Issues (Fixed)

| # | Severity | File:Line | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| 7 | Medium | `admin.py:9-13` (CalendarConnectionAdmin) | Admin detail view did not exclude `_access_token` and `_refresh_token` fields. While encrypted, these blobs are visible to admin users and could be accidentally copied. | Added `exclude = ['_access_token', '_refresh_token']` to `CalendarConnectionAdmin`. |
| 8 | Medium | `serializers.py:65-66` (CreateEventSerializer) | `description` and `location` fields lacked `max_length` constraints, allowing unbounded text to be forwarded to Google/Microsoft APIs. | Added `max_length=8192` to `description`, `max_length=500` to `location` (matching the model field). Added `max_length=50` to `attendee_emails` list to prevent abuse. |

---

## Low Issues (Not Fixed -- Informational)

| # | Severity | File:Line | Issue | Recommendation |
|---|----------|-----------|-------|----------------|
| 9 | Low | `models.py:13-20` (get_encryption_key) | Fallback encryption key derived from `SECRET_KEY[:32]` when `CALENDAR_ENCRYPTION_KEY` is not set. This is weaker than a dedicated Fernet key and ties token encryption to the Django secret key. | Set `CALENDAR_ENCRYPTION_KEY` in production environment. Consider adding a startup warning if the env var is empty. |
| 10 | Low | `services.py:182-191` (revoke_token) | Google token revocation silently swallows all exceptions and returns `False`. If revocation fails, the token remains valid on Google's side. | Add logging when revocation fails so ops can investigate. |
| 11 | Low | `views.py:265-268` (DisconnectCalendarView) | On disconnect, only Google token is revoked. Microsoft does not have a simple revocation endpoint, but the disconnect flow should at least log that Microsoft tokens cannot be programmatically revoked. | Add a comment or log noting Microsoft limitation. |

---

## Positive Security Findings

1. **Token encryption at rest:** OAuth tokens are encrypted with Fernet before database storage. Access/refresh tokens are never exposed via API serializers.
2. **CSRF state parameter:** OAuth flows use `secrets.token_urlsafe(32)` for state tokens, stored in cache with 10-minute TTL. State is validated before code exchange, preventing CSRF attacks on the OAuth callback.
3. **State is single-use:** After validation, the state token is immediately deleted from cache (`cache.delete(cache_key)`). Replay attacks are prevented.
4. **Row-level security:** Every queryset filters by the authenticated user. The `CalendarConnection.user` FK has `limit_choices_to={'role': 'TRAINER'}` at the model level.
5. **Global rate limiting:** DRF throttling at 120 requests/minute for authenticated users applies to all calendar endpoints.
6. **Serializer validation:** `CreateEventSerializer` validates `end_time > start_time`, uses `EmailField` for attendee emails, and `ChoiceField` for provider selection.
7. **No debug prints:** Zero `print()` statements in any changed file.
8. **CORS properly configured:** Production restricts origins to `CORS_ALLOWED_ORIGINS` env var. Only development allows all origins.

---

## Mobile Security Assessment

1. **No secrets in mobile code:** All API calls go through `ApiClient` which handles JWT auth via interceptors. No API keys or tokens hardcoded in Dart files.
2. **OAuth flow:** The mobile app launches an external browser for OAuth consent, then captures the code/state. This is the recommended pattern (no embedded WebView credential capture).
3. **Input validation:** The `AvailabilitySlotEditor` validates that end time is after start time client-side. The `_showCallbackDialog` validates non-empty code/state before submission. Server-side validation provides the real security boundary.
4. **No sensitive data stored locally:** Calendar tokens are server-side only. Mobile only stores JWT access/refresh tokens (standard auth pattern).

---

## Fixes Applied Summary

| # | Severity | File | Change |
|---|----------|------|--------|
| 1-4 | Critical | `backend/calendars/views.py` | Replaced 4 `str(e)` error message leaks with generic messages + server-side logging |
| 5 | High | `backend/calendars/serializers.py` | Added `max_length`/`min_length` to OAuth `code` and `state` fields |
| 6 | High | `backend/calendars/views.py` | Added `_validate_provider()` helper + validation in 3 view methods |
| 7 | Medium | `backend/calendars/admin.py` | Added `exclude = ['_access_token', '_refresh_token']` |
| 8 | Medium | `backend/calendars/serializers.py` | Added `max_length` to `description`, `location`, and `attendee_emails` |
| -- | -- | `backend/calendars/views.py` | Added `import logging` + `logger = logging.getLogger(__name__)` for structured error logging |

---

## Security Score: 9/10
## Recommendation: PASS

**Rationale:** The Calendar Integration feature follows strong security practices out of the box: encrypted token storage, CSRF-protected OAuth flow, row-level security on all querysets, trainer-only permission guards, and no secrets in code. Four critical information leakage issues in error responses have been fixed. Two high-severity input validation gaps have been closed. Two medium issues (admin panel token exposure and unbounded input fields) have been addressed. The remaining low-severity items (encryption key fallback, silent revocation failure) are non-blocking and documented for future improvement. No IDOR vulnerabilities. No injection surfaces. No data exposure via API responses.

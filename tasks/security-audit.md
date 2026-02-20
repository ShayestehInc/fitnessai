# Security Audit: Message Search (Pipeline 24)

## Audit Date
2026-02-20

## Files Audited
- `backend/messaging/services/search_service.py` (new)
- `backend/messaging/views.py` (modified — added `SearchMessagesView`)
- `backend/messaging/serializers.py` (modified — added `SearchMessageResultSerializer`)
- `backend/messaging/urls.py` (modified — added `search/` route)
- `backend/messaging/tests/test_search.py` (new)
- `web/src/components/messaging/message-search.tsx` (new)
- `web/src/components/messaging/search-result-item.tsx` (new)
- `web/src/lib/highlight-text.tsx` (new)
- `web/src/hooks/use-messaging.ts` (modified — added `useSearchMessages`)
- `web/src/lib/constants.ts` (modified — added `MESSAGING_SEARCH`)
- `web/src/app/(dashboard)/messages/page.tsx` (modified — added search UI integration)
- `web/src/types/messaging.ts` (modified — added `SearchMessageResult`, `SearchMessagesResponse`)
- `backend/config/settings.py` (reference — middleware, throttle config)
- `backend/messaging/models.py` (reference — data model)

---

## Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history
- [x] All user input sanitized (query stripped/validated in service, `max_length=2000` on message model)
- [x] Authentication checked on all new endpoints (`IsAuthenticated` on `SearchMessagesView`)
- [x] Authorization — correct role/permission guards (trainer/trainee filter in service, admin rejected with ValueError)
- [x] No IDOR vulnerabilities (row-level security enforced via `conversation__trainer=user` / `conversation__trainee=user` filter — users cannot access other users' messages by manipulating parameters)
- [x] No file upload concerns (search endpoint is read-only GET, no file handling)
- [x] Rate limiting on sensitive endpoints (`ScopedRateThrottle` with `'messaging'` scope = 30/minute)
- [x] Error messages don't leak internals (generic ValueError messages: "Search query is required.", "at least 2 characters", "Only trainers and trainees can search messages.")
- [x] CORS policy appropriate (restricted in production, permissive only in DEBUG mode — unchanged)
- [x] No SQL injection (Django ORM exclusively — `content__icontains`, no raw queries, no `.extra()`, no `RawSQL`)
- [x] No XSS (React JSX auto-escapes; `highlightText()` uses `<mark>` JSX elements, NOT `dangerouslySetInnerHTML`; no `innerHTML` anywhere in changed files)
- [x] No command injection (no `subprocess`, `os.system`, `exec`, `eval` in any messaging code)
- [x] No path traversal (search is read-only, no file path operations)
- [x] CSRF not applicable (JWT bearer token auth, not cookie-based)
- [x] WebSocket auth unchanged (not affected by this pipeline)

---

## Secrets Scan

Scanned all new/modified files in the diff (HEAD~4..HEAD) for:
- API keys (`sk-`, `pk_`, `AKIA`, `ghp_`, `glpat-`)
- Hardcoded credentials / password strings
- Token literals (>20 chars random-looking strings)
- `.env` file contents committed to version control

**Findings:**
- Test fixtures use `password='testpass123'` — standard test password, acceptable for test code.
- `web/src/lib/constants.ts` contains only URL path strings, no tokens or API keys.
- `NEXT_PUBLIC_API_URL` is read from environment variable with safe fallback to `http://localhost:8000`.
- `TOKEN_KEYS` constants are localStorage key names (`fitnessai_access_token`, `fitnessai_refresh_token`) — not actual tokens.

**Verdict: PASS — No secrets in any tracked source files.**

---

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Status |
|---|------|-----------|-------|--------|
| 1 | SQL Injection | `search_service.py:88` | `content__icontains=stripped_query` — Django ORM parameterized query. User input is never interpolated into SQL. The `icontains` lookup generates a proper `LIKE %query%` with parameterized binding. | CLEAR |
| 2 | SQL Injection | `search_service.py:76-78` | Conversation filter uses `Q(conversation__trainer=user)` / `Q(conversation__trainee=user)` with the authenticated User object, not user-supplied IDs. | CLEAR |
| 3 | XSS | `highlight-text.tsx:11` | Query string used in regex construction. Special regex characters are properly escaped via `query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")`. The escaped query is used in `new RegExp()` — safe against ReDoS because the pattern is a simple literal match with no quantifiers. | CLEAR |
| 4 | XSS | `highlight-text.tsx:21-29` | Text highlighting uses React JSX `<mark>` elements with `{part}` text content — React auto-escapes. No `dangerouslySetInnerHTML` or `innerHTML`. If message content contains `<script>` tags, React renders them as literal text, not executable HTML. | CLEAR |
| 5 | XSS | `search-result-item.tsx:57` | `{highlightText(snippet, query)}` renders the return value from `highlightText()` as ReactNode children — React-safe. | CLEAR |
| 6 | Command Injection | All backend files | No `subprocess`, `os.system`, `os.popen`, `exec`, or `eval` calls in any messaging code. | CLEAR |
| 7 | Path Traversal | N/A | Search endpoint is read-only. No file path operations. | CLEAR |

---

## Auth & Authz Issues

| # | Severity | File:Line | Issue | Status |
|---|----------|-----------|-------|--------|
| - | - | - | No auth/authz issues found. | - |

**Detailed Analysis:**

1. **Authentication:** `SearchMessagesView` (line 122) has `permission_classes = [IsAuthenticated]`. Unauthenticated requests return 401. Verified by test `test_search_unauthenticated_returns_401`.

2. **Row-level security:** The service function `search_messages()` (line 75-80) enforces data isolation at the query level:
   - Trainers: `Q(conversation__trainer=user)` — only conversations where this user is the trainer.
   - Trainees: `Q(conversation__trainee=user)` — only conversations where this user is the trainee.
   - Admin role: raises `ValueError` — admins must use impersonation.
   - This is defense-in-depth: the filter is applied at the database query level, making it impossible to return messages from conversations the user does not participate in, regardless of any parameter manipulation.

3. **No IDOR:** The search endpoint does not accept a `conversation_id` parameter. It searches across ALL conversations the user participates in, determined entirely by the authenticated `request.user`. There is no user-controllable FK/ID that could be manipulated to access other users' data.

4. **Impersonation:** The search endpoint is read-only (GET), so there is no impersonation guard needed (per AC-10). When an admin impersonates a trainer, `request.user` is set to the trainer, so the trainer's conversation filter applies correctly. This is consistent with other read-only endpoints like `ConversationListView` and `ConversationDetailView`.

5. **Data scoping consistency:** Verified that `test_search_row_level_security_trainer`, `test_search_other_trainer_cannot_see_my_messages`, `test_search_row_level_security_trainee`, and `test_search_other_trainer_isolated` all confirm cross-user isolation.

---

## Data Exposure

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | None | `SearchMessageResultSerializer` exposes: `message_id, conversation_id, sender_id, sender_first_name, sender_last_name, content, image_url, created_at, other_participant_id, other_participant_first_name, other_participant_last_name`. No email addresses, no password hashes, no internal model details. | CLEAR |
| 2 | None | Error messages are generic strings from ValueError: "Search query is required.", "Search query must be at least 2 characters.", "Only trainers and trainees can search messages." No stack traces, no DB internals, no file paths. | CLEAR |
| 3 | None | Soft-deleted messages (`is_deleted=True`) are excluded from search results via the ORM filter. Deleted content cannot be surfaced through search. | CLEAR |
| 4 | None | Archived conversations (`is_archived=True`) are excluded from search results. Messages from removed trainees cannot be surfaced through search. | CLEAR |
| 5 | Info | The `ConversationParticipantSerializer` (used in conversation list, not search) exposes participant `email`. This is pre-existing behavior, not introduced by this pipeline. The search serializer intentionally does NOT expose email — only first/last name. | EXISTING |

---

## Rate Limiting

| Endpoint | Throttle | Rate |
|----------|----------|------|
| GET `/api/messaging/search/` | `ScopedRateThrottle` `'messaging'` | 30/minute per user |
| Global (all auth users) | `UserRateThrottle` | 120/minute per user |

The 30/minute messaging scope is shared with send, edit, and delete operations. This is deliberately conservative and prevents abuse of the search endpoint (e.g., enumerating message content through repeated searches). The global 120/minute rate provides an additional backstop.

**Verdict: PASS.**

---

## CORS / CSRF

- **CORS:** `CORS_ALLOW_ALL_ORIGINS = True` only when `DEBUG=True`. In production, `CORS_ALLOWED_ORIGINS` is loaded from environment. No change in this pipeline. Acceptable.
- **CSRF:** DRF with JWT authentication via `Authorization: Bearer` header (not cookies). CSRF is not applicable. Django's `CsrfViewMiddleware` is in the middleware stack but DRF's `APIView` exempts JWT-authenticated endpoints.
- **CSRF_TRUSTED_ORIGINS:** Includes `*.ngrok-free.app` and `*.ngrok.io` — this is for development tunneling and acceptable as long as production deploys restrict this list via environment variable.

---

## Frontend Security Analysis

### Text Highlighting (XSS Vector Assessment)

The `highlightText()` function in `web/src/lib/highlight-text.tsx` was the primary XSS concern for this feature, because search result highlighting is a common XSS vector in web applications (e.g., using `innerHTML` to inject `<mark>` tags around matched text).

**Assessment: SAFE.** The implementation is secure because:

1. **No `dangerouslySetInnerHTML`:** Confirmed via grep — zero instances in the entire `web/src` directory.
2. **React JSX auto-escaping:** The `highlightText()` function returns a `ReactNode` array of string fragments and `<mark>` JSX elements. React renders string content as text nodes, automatically escaping any HTML entities. A message containing `<script>alert('xss')</script>` would be rendered as literal visible text.
3. **Regex injection prevention:** The query string is escaped via `query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")` before being used in `new RegExp()`. This prevents ReDoS (Regular Expression Denial of Service) and regex injection.
4. **No prototype pollution:** The `truncateAroundMatch()` function uses only `String.prototype` methods (`toLowerCase`, `indexOf`, `slice`) — no object manipulation.

### Search Input

- Input value is controlled via React state (`useState`), not directly manipulated via DOM.
- 300ms debounce prevents excessive API calls.
- 2-character minimum enforced client-side (query disabled when `query.length < 2`) and server-side (service raises `ValueError`).
- `URLSearchParams` is used to construct query strings — properly handles encoding.

---

## Performance / DoS Considerations

| # | Concern | Severity | Analysis |
|---|---------|----------|----------|
| 1 | `icontains` search performs sequential scan | Low | Acknowledged in code comment (line 83-85). At current scale (<100k messages), this is acceptable. The rate limiter (30/min) prevents abuse. For future scaling, a GIN trigram index is recommended. |
| 2 | Unbounded result count | None | Pagination via `Paginator` limits results to 20 per page. The total `count` is computed by the database but not materialized in Python. |
| 3 | `select_related` + `.only()` on search queryset | None | Properly optimized — fetches only needed columns, joins related tables in a single query. No N+1 queries. |

---

## Critical Issues Fixed

**None.** No Critical or High severity issues were found in the Message Search implementation.

---

## Minor Observations (No Fix Required)

1. **Page clamping logic** (`search_service.py:113`): `page_number = max(1, min(page, paginator.num_pages or 1))` — the `or 1` handles the edge case where `num_pages` is 0 (no results). This prevents an `EmptyPage` exception from `get_page()`. Correct behavior.

2. **ValueError propagation** (`views.py:138-143`): The view catches `ValueError` from the service and returns HTTP 400. This is the correct pattern — service raises domain exceptions, view translates to HTTP responses. The `str(exc)` message is safe because all ValueError messages in `search_messages()` are hardcoded strings, not user input.

3. **React Query cache key** (`use-messaging.ts:230`): The query key `["messaging", "search", query, page]` includes both the query string and page number. This ensures that changing the search term or page number correctly invalidates the cache and fetches fresh data. The `enabled: query.length >= 2` guard prevents unnecessary API calls.

4. **Keyboard shortcut** (`messages/page.tsx:94-103`): The `Cmd/Ctrl+K` handler uses `e.preventDefault()` to prevent the browser's default action (e.g., Chrome's address bar focus). The event listener is properly cleaned up on component unmount via the `useEffect` return function.

5. **Test passwords**: All test files use `password='testpass123'` — standard for Django test fixtures. These are ephemeral in-memory database passwords, not production credentials.

---

## Security Score: 9/10

The implementation is fundamentally sound with no Critical, High, or Medium severity issues. All security concerns have been properly addressed:

- Row-level security enforced at the database query level (not just view-level checks)
- No injection vectors (ORM for SQL, React JSX for XSS, regex escaping for ReDoS)
- Proper authentication and rate limiting on the new endpoint
- No secrets or sensitive data exposure
- Text highlighting implemented safely without `dangerouslySetInnerHTML`
- Comprehensive test coverage including security-relevant edge cases (cross-user isolation, admin rejection, unauthenticated access)

The -1 point is for the inherent performance characteristic of `icontains` (sequential scan) which, while not a security vulnerability per se, could be leveraged as a minor DoS vector at scale. The rate limiter mitigates this adequately at current scale.

## Recommendation: PASS

# Security Audit: In-App Direct Messaging (Trainer-to-Trainee)

## Audit Date: 2026-02-19

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (checked all new files in messaging/ and web/src/components/messaging/)
- [x] All user input sanitized (message content validated and stripped server-side)
- [x] Authentication checked on all new endpoints (IsAuthenticated on all 6 REST views)
- [x] Authorization -- correct role/permission guards (row-level security on every endpoint)
- [x] No IDOR vulnerabilities (user A cannot access user B's conversations -- verified)
- [x] Rate limiting on sensitive endpoints (30/minute on send + start via ScopedRateThrottle)
- [x] Error messages don't leak internals (generic error strings, no stack traces)
- [x] CORS policy appropriate (AllowAll in DEBUG only, restricted in production)
- [x] WebSocket authentication secure (JWT validated via simplejwt AccessToken)
- [x] No SQL injection (all ORM usage, no raw queries)
- [x] No XSS (React auto-escapes content, no dangerouslySetInnerHTML, Flutter text widgets)
- [x] Impersonation guard correct (SendMessageView + StartConversationView check JWT claim)

## Files Audited

### Backend
- `backend/messaging/models.py` -- Data model, FK constraints, indexes
- `backend/messaging/views.py` -- All 6 REST API endpoints
- `backend/messaging/services/messaging_service.py` -- Business logic, validation
- `backend/messaging/consumers.py` -- WebSocket consumer, JWT auth, access control
- `backend/messaging/serializers.py` -- Input/output serialization, validation
- `backend/messaging/urls.py` -- URL patterns (all use `<int:conversation_id>` -- no string injection)
- `backend/messaging/routing.py` -- WebSocket URL pattern
- `backend/messaging/admin.py` -- Django admin registration
- `backend/config/settings.py` -- INSTALLED_APPS, throttle config
- `backend/config/asgi.py` -- WebSocket routing with AllowedHostsOriginValidator
- `backend/trainer/views.py` -- RemoveTraineeView integration with archive

### Web Dashboard
- `web/src/components/messaging/chat-view.tsx` -- Message rendering
- `web/src/components/messaging/message-bubble.tsx` -- Content display
- `web/src/components/messaging/chat-input.tsx` -- Input validation, character limit
- `web/src/components/messaging/conversation-list.tsx` -- Conversation display
- `web/src/hooks/use-messaging.ts` -- API hooks
- `web/src/types/messaging.ts` -- TypeScript types
- `web/src/lib/constants.ts` -- API URLs (no secrets)
- `web/src/app/(dashboard)/messages/page.tsx` -- Messages page
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` -- Trainee detail "Message" button

### Mobile
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart` -- WebSocket service
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` -- API calls

---

## Critical Issues Found: 0

No critical issues (leaked secrets, authentication bypass, SQL injection) were found.

---

## High Severity Issues Found: 3 (ALL FIXED)

| # | Severity | File:Line | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| H1 | High | `backend/messaging/consumers.py:168-171` | WebSocket `_check_conversation_access()` did not filter out archived conversations. A removed trainee who still had a valid JWT could connect to an archived conversation's WebSocket channel and receive real-time messages broadcast to that group. | Added `is_archived=False` filter to the Conversation query in `_check_conversation_access()`. |
| H2 | High | `backend/messaging/consumers.py:141-151` | WebSocket `_authenticate()` used bare `except Exception` which silently swallowed all errors including programming bugs (ImportError, AttributeError, etc.). This could mask serious issues in production and make debugging impossible. | Narrowed to `except (TokenError, User.DoesNotExist, ValueError, KeyError)` with `logger.debug()` logging. Moved imports outside the try block so import errors propagate. |
| H3 | High | `backend/messaging/views.py:82-128` | `ConversationDetailView` did not check `is_archived` flag. Per ticket spec: "Messages are preserved for audit but no longer accessible to trainee." A removed trainee could still read all message history by hitting `/api/messaging/conversations/<id>/messages/` with a known conversation ID. | Added archived check: trainees get 403 on archived conversations (trainers can still view for audit purposes). |

---

## Medium Severity Issues Found: 2 (ALL FIXED)

| # | Severity | File:Line | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| M1 | Medium | `backend/messaging/views.py:289-340` | `MarkReadView` did not check `is_archived` flag. An impersonating admin or stale client could mark messages as read in an archived conversation, mutating data that should be immutable. | Added `is_archived` check returning 403 before calling `mark_conversation_read()`. |
| M2 | Medium | `backend/messaging/views.py:440-479` | `_send_message_push_notification()` typed `recipient_id` as `int` but `conversation.trainee_id` can be `None` (SET_NULL FK). In a theoretical race condition (trainee deleted between conversation lookup and push send), passing `None` to `send_push_notification(user_id=None)` could cause unexpected behavior. | Changed type annotation to `int | None` and added early return with warning log when `recipient_id is None`. |

---

## Low Severity Issues Found: 2 (noted, not blocking)

| # | Severity | File:Line | Issue | Recommendation |
|---|----------|-----------|-------|----------------|
| L1 | Low | `backend/messaging/views.py:361-375` | `_is_impersonating()` fallback returns `False` when `request.auth` is not a token object (e.g., SessionAuthentication). If session-based impersonation were ever added, the guard would not catch it. | Currently safe because all messaging endpoints use JWT auth exclusively. Document this assumption. If SessionAuth is ever added, this function must be updated. |
| L2 | Low | `backend/messaging/consumers.py:81-94` | WebSocket `receive_json` silently drops unknown message types. While not a vulnerability (the consumer only joins its own group), logging unknown types would help detect client bugs or probing attempts. | Consider adding `logger.debug("Unknown WS message type: %s", msg_type)` for unrecognized types. |

---

## Input Validation Assessment

| Input Point | Validation | Status |
|-------------|-----------|--------|
| Message `content` (REST) | CharField(max_length=2000), strip() + empty check in serializer AND service | PASS |
| Message `content` (WebSocket) | Messages are NOT sent via WebSocket (only via REST POST). WS is read-only for message delivery. | PASS (by design) |
| `trainee_id` (StartConversation) | IntegerField in serializer, ownership validated in service | PASS |
| `conversation_id` (URL path) | `<int:conversation_id>` in URL pattern -- Django enforces integer type | PASS |
| WebSocket `token` query param | Validated via simplejwt AccessToken with specific exception handling | PASS |
| WebSocket `is_typing` | Coerced to strict `bool()` to prevent arbitrary data injection | PASS (fixed) |
| Textarea (web) | `maxLength={2000}` on HTML element + disabled send when over limit | PASS |
| Textarea (mobile) | Character counter in ChatInput widget | PASS |

## Authentication & Authorization Matrix

| Endpoint | Auth Required | Role Check | Row-Level Security | Impersonation Guard | Archived Guard |
|----------|:---:|:---:|:---:|:---:|:---:|
| GET /conversations/ | Yes | Via service (trainer/trainee) | Via service queryset filter | N/A (read-only) | Excluded by service |
| GET /conversations/:id/messages/ | Yes | N/A | user.id in (trainer_id, trainee_id) | N/A (read-only) | Trainee blocked, trainer allowed |
| POST /conversations/:id/send/ | Yes | N/A | user.id in (trainer_id, trainee_id) | Yes -- 403 | Via service (ValueError) |
| POST /conversations/start/ | Yes | is_trainer() | Via service (parent_trainer check) | Yes -- 403 | N/A (creates/un-archives) |
| POST /conversations/:id/read/ | Yes | N/A | user.id in (trainer_id, trainee_id) | N/A | Yes -- 403 |
| GET /unread-count/ | Yes | Via service (trainer/trainee) | Via service queryset filter | N/A (read-only) | Excluded by service |
| WS /ws/messaging/:id/ | Yes (JWT) | N/A | _check_conversation_access() | N/A (receive-only) | Yes -- connection rejected |

## XSS Prevention Assessment

| Component | Rendering Method | XSS Risk |
|-----------|-----------------|----------|
| `message-bubble.tsx` | `{message.content}` in JSX (React auto-escapes) | None |
| `conversation-list.tsx` | `{conversation.last_message_preview}` in JSX | None |
| `chat-view.tsx` | `{displayName}`, `{otherParty.email}` in JSX | None |
| Flutter `MessageBubble` | `Text(message.content)` widget (auto-escapes) | None |
| Flutter `ConversationTile` | `Text(conversation.lastMessagePreview)` | None |

No `dangerouslySetInnerHTML`, `innerHTML`, or `v-html` usage found anywhere in the messaging code.

## CORS & WebSocket Origin

- REST API: CORS configured via `corsheaders` middleware. `CORS_ALLOW_ALL_ORIGINS = True` only in DEBUG mode. Production restricts to `CORS_ALLOWED_ORIGINS` from environment variable.
- WebSocket: `AllowedHostsOriginValidator` wraps the URL router in `asgi.py`, which validates the Origin header against `ALLOWED_HOSTS`. This is correct.

## Rate Limiting

- `SendMessageView`: `ScopedRateThrottle` with scope `messaging` at 30/minute
- `StartConversationView`: Same
- `ConversationListView`, `ConversationDetailView`, `MarkReadView`, `UnreadCountView`: No rate limiting beyond DRF global defaults (read endpoints)
- WebSocket: No built-in rate limiting on typing events. A malicious client could spam typing indicators. Low risk (ephemeral, no DB writes). Consider adding in v2.

## Data Model Security

- `Conversation.trainee` FK uses `on_delete=SET_NULL` -- prevents cascade deletion of conversations when user is deleted
- `Conversation.trainer` FK uses `on_delete=CASCADE` -- acceptable since trainer deletion should clean up their conversations
- `UniqueConstraint(fields=['trainer', 'trainee'])` prevents duplicate conversations
- `Message.content` has `max_length=2000` at the database level
- Indexes cover all query patterns (no full table scans for common operations)

---

## Security Score: 9/10

Strong security posture. All endpoints have proper authentication, authorization, and row-level security. Input validation is thorough (serializer + service layer). No secrets leaked. No XSS vectors. No SQL injection. WebSocket authentication uses proper JWT validation with specific exception handling. The three High issues found (archived conversation access via WebSocket, bare exception swallowing, missing archived check on message detail) have all been fixed. The remaining Low items are informational and do not pose a risk in the current architecture.

## Recommendation: PASS

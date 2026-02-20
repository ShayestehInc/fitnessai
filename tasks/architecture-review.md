# Architecture Review: Message Editing and Deletion (Pipeline 23)

## Review Date
2026-02-19

## Files Reviewed
- `backend/messaging/models.py`
- `backend/messaging/migrations/0004_add_edited_at_is_deleted_to_message.py`
- `backend/messaging/services/messaging_service.py`
- `backend/messaging/serializers.py`
- `backend/messaging/views.py`
- `backend/messaging/urls.py`
- `backend/messaging/consumers.py`
- `mobile/lib/features/messaging/data/models/message_model.dart`
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart`
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart`
- `web/src/types/messaging.ts`
- `web/src/hooks/use-messaging.ts`
- `web/src/hooks/use-messaging-ws.ts`
- `web/src/components/messaging/message-bubble.tsx`
- `web/src/components/messaging/chat-view.tsx`
- `web/src/lib/constants.ts`
- `mobile/lib/core/constants/api_constants.dart`

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views
- [x] Consistent with existing patterns (after fixes below)

---

## Layering Assessment

**GOOD — Backend**

The service layer is clean. `edit_message()` and `delete_message()` carry all business logic: sender validation, time-window enforcement, empty-content guard, `select_for_update` for concurrency safety, and image file deletion outside the transaction. Views only handle request/response. Serializers only handle input validation (`EditMessageSerializer`) and output projection (`MessageSerializer`). This is textbook correct.

The broadcast helpers live in the service module but are called from views after the transaction commits — correct positioning since WS broadcast should happen only after the DB write is committed.

**GOOD — Mobile**

Repository (`MessagingRepository`) calls API. Notifier (`ChatNotifier`) calls repository and owns state. Widget (`MessageBubble`) fires callbacks. Clean Riverpod chain throughout with proper optimistic update and rollback in the provider layer.

**FIXED — Web**

The original implementation called `apiClient.patch()` and `apiClient.delete()` directly inside `handleEditMessage` and `handleDeleteMessage` in `chat-view.tsx`. This violated the hooks abstraction layer — API calls belong in hooks, not components. AC-32 explicitly required `useEditMessage()` and `useDeleteMessage()` mutation hooks, which were absent from `use-messaging.ts`.

Fix applied: Added `useEditMessage(conversationId)` and `useDeleteMessage(conversationId)` to `web/src/hooks/use-messaging.ts`. These hooks own cache invalidation via React Query. `chat-view.tsx` now uses these hooks instead of raw `apiClient` calls. The `useQueryClient` import was removed from the component since cache management is now entirely in the hooks.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | `edited_at` is nullable, `is_deleted` defaults `False` — additive, non-breaking |
| Migrations reversible | PASS | Migration 0004 is pure `AddField` — trivially reversible |
| Indexes added for new queries | PASS | Existing `(conversation, created_at)` index covers all new queries. `is_deleted` is not queried in isolation |
| No N+1 query patterns | PASS | `get_conversations_for_user()` uses correlated subqueries via `Subquery()` + `annotate()`. All `Message` fetches use `select_related('sender')` |

Minor observation: After `edit_message()` completes in the view, a second `Message.objects.select_related('sender').get(id=result.message_id)` is issued to build the response payload. This is one extra query per edit. Acceptable and consistent with the existing `SendMessageView` pattern.

---

## API Design Assessment

**FIXED — Non-RESTful delete URL**

The original implementation registered DELETE at `/messages/<id>/delete/` — a verb-in-URL antipattern. The correct REST design is to use the HTTP method to distinguish the operation: `PATCH /messages/<id>/` to edit, `DELETE /messages/<id>/` to delete. Both methods can be served from the same URL pattern because Django dispatches by HTTP verb. The dev-done note acknowledged the `/delete/` suffix as workaround for "conflict" — that is a misunderstanding of HTTP routing.

Fix applied: Merged `EditMessageView` and `DeleteMessageView` into a single `MessageDetailView` that handles both `patch()` and `delete()`. The helper `_resolve_conversation()` extracts shared conversation lookup and row-level security to avoid duplication. URL pattern is a single `conversations/<id>/messages/<msg_id>/` entry.

The delete endpoint URL change required updating both client-side constant files to remove the `/delete/` suffix:
- `mobile/lib/core/constants/api_constants.dart`: added `messagingMessageDetail()` as canonical; `messagingEditMessage()` and `messagingDeleteMessage()` are aliases pointing to it.
- `web/src/lib/constants.ts`: same — `messagingMessageDetail` added, aliases retained for call-site clarity.

**GOOD — Error codes**

`PermissionError` to 403, `ValueError` to 400, `DoesNotExist` to 404. Consistent with all other messaging views. No internal details leaked in error messages.

**GOOD — Rate limiting**

Edit and delete both use `ScopedRateThrottle` with `throttle_scope = 'messaging'` — same as send, satisfying AC-15.

---

## Frontend Patterns Assessment

**Mobile**

Repository pattern correctly followed. `editMessage()` and `deleteMessage()` in the repository make typed HTTP calls. `ChatNotifier.editMessage()` and `ChatNotifier.deleteMessage()` implement optimistic-then-confirm with rollback. `MessageBubble` fires callbacks; `ChatScreen` wires them to the notifier. `onMessageEdited()` and `onMessageDeleted()` handle WS events in the notifier. Full Riverpod chain intact.

`isEditWindowExpired` is computed client-side on `MessageModel` for UI gating, while the backend enforces it authoritatively. Correct pattern — never trust client-side time checks for security.

**Web (after fix)**

`chat-view.tsx` now properly delegates to `useEditMessage` and `useDeleteMessage` hooks. The component retains optimistic local state updates via `setAllMessages`, while the hooks handle the React Query cache and server-side invalidation. Component manages ephemeral local UI state; hooks manage persistent cache — clean separation.

WS cache updates in `use-messaging-ws.ts` use `setQueriesData` to update all cached pages — correct, since the user might be on any page when an edit/delete WS event arrives.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | `select_for_update()` in edit/delete | Correct usage — prevents race on simultaneous edits to the same message | GOOD |
| 2 | Image file deletion outside transaction | Correct — file I/O inside a DB transaction is an antipattern. If file delete fails, soft-delete still persists and a warning is logged | GOOD |
| 3 | Correlated subqueries in conversation list | Three subqueries per conversation row. Acceptable at current scale. At thousands of conversations, consider a `last_message` FK + post-save signal | MONITOR |
| 4 | Silent WS broadcast failure | Broadcast failure is caught and logged but not retried. Acceptable — clients recover on reconnect or polling | ACCEPTABLE |

---

## Technical Debt Assessment

| # | Description | Severity | Resolution |
|---|-------------|----------|------------|
| 1 | Non-RESTful `/delete/` URL suffix | Medium | RESOLVED — merged into `MessageDetailView` with unified URL |
| 2 | Missing `useEditMessage`/`useDeleteMessage` hooks (AC-32) | Medium | RESOLVED — hooks added to `use-messaging.ts` |
| 3 | Raw `apiClient` calls inside a React component | Medium | RESOLVED — `chat-view.tsx` now uses hooks |
| 4 | `EDIT_WINDOW_MS` duplicated in `message-bubble.tsx` and backend | Low | EXISTING — client-side check is UX gating only; server enforces authoritatively. Acceptable |
| 5 | Post-edit extra DB fetch in views | Low | EXISTING — matches `SendMessageView` pattern. Low priority |

Net result: no new technical debt introduced. Three medium-severity items resolved.

---

## Fixes Applied by Architect

1. **`web/src/hooks/use-messaging.ts`** — Added `useEditMessage(conversationId)` and `useDeleteMessage(conversationId)` mutation hooks with proper React Query cache updates (`setQueriesData` across all pages) and conversation list invalidation.

2. **`web/src/components/messaging/chat-view.tsx`** — Replaced inline `apiClient.patch()`/`apiClient.delete()` calls with `editMessageMutation` and `deleteMessageMutation` from the new hooks. Removed `useQueryClient` import.

3. **`backend/messaging/views.py`** — Merged `EditMessageView` and `DeleteMessageView` into `MessageDetailView`. Added `_resolve_conversation()` helper to deduplicate conversation lookup and row-level security check shared by both HTTP methods.

4. **`backend/messaging/urls.py`** — Removed the `/delete/` suffix URL entry. Now a single `conversations/<id>/messages/<msg_id>/` pattern routes to `MessageDetailView` for both PATCH and DELETE.

5. **`mobile/lib/core/constants/api_constants.dart`** — Added `messagingMessageDetail()` as canonical URL. `messagingEditMessage()` and `messagingDeleteMessage()` are now aliases pointing to the same URL.

6. **`web/src/lib/constants.ts`** — Added `messagingMessageDetail`. Edit and delete aliases updated to match the unified URL (removed `/delete/` suffix).

---

## Architecture Score: 9/10
## Recommendation: APPROVE

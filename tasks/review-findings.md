# Code Review: Message Editing and Deletion

## Review Date
2026-02-19

## Files Reviewed
- `backend/messaging/models.py`
- `backend/messaging/migrations/0004_add_edited_at_is_deleted_to_message.py`
- `backend/messaging/services/messaging_service.py`
- `backend/messaging/views.py`
- `backend/messaging/urls.py`
- `backend/messaging/consumers.py`
- `backend/messaging/serializers.py`
- `mobile/lib/features/messaging/data/models/message_model.dart`
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart`
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart`
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart`
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_context_menu.dart`
- `mobile/lib/features/messaging/presentation/widgets/edit_message_sheet.dart`
- `mobile/lib/core/constants/api_constants.dart`
- `web/src/types/messaging.ts`
- `web/src/lib/constants.ts`
- `web/src/hooks/use-messaging.ts`
- `web/src/hooks/use-messaging-ws.ts`
- `web/src/components/messaging/message-bubble.tsx`
- `web/src/components/messaging/chat-view.tsx`

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `backend/messaging/services/messaging_service.py:394-422` | **Race condition on edit: no atomic guard.** `edit_message()` reads the message, validates it, then writes back. Between the read and write, another request could delete the same message: read says `is_deleted=False`, then delete runs and clears content, then edit writes content back to a now-deleted message, leaving it in an inconsistent state (`is_deleted=True` with non-empty content). | Wrap the read + validate + save in `transaction.atomic()` and use `Message.objects.select_for_update().get(...)` to acquire a row lock, same pattern as `send_message()` already uses `transaction.atomic()`. |
| C2 | `backend/messaging/services/messaging_service.py:455-472` | **Race condition on delete: same issue as C1.** No transaction or row lock. Two concurrent delete requests could both pass the `is_deleted` check and produce double WS broadcasts. A concurrent edit could write content back to a message that's mid-delete. | Wrap in `transaction.atomic()` with `select_for_update()`. |
| C3 | `backend/messaging/services/messaging_service.py:469-472` | **Deleted message image file is orphaned on disk/S3.** Setting `message.image = None` removes the DB reference but does NOT delete the actual file from storage. The old image file persists forever, leaking storage and potentially leaking sensitive image content that the user explicitly deleted. This is a data privacy concern. | Before setting `message.image = None`, save a reference to the old file and call `old_image.delete(save=False)` to remove it from storage. E.g.: `old_image = message.image; message.image = None; ... message.save(...); if old_image: old_image.delete(save=False)`. |
| C4 | `backend/messaging/views.py:357-364` | **Rate limiting depends on `'messaging'` throttle scope being defined in settings.** The view declares `throttle_scope = 'messaging'` but if `REST_FRAMEWORK['DEFAULT_THROTTLE_RATES']['messaging']` is not defined in `settings.py`, DRF silently skips throttling entirely. Must verify the setting exists; if not, AC-15 is unmet. | Verify `REST_FRAMEWORK['DEFAULT_THROTTLE_RATES']['messaging']` exists in `settings.py`. If not, add `'messaging': '30/minute'`. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `backend/messaging/views.py:421-470` | **DeleteMessageView has no rate limiting.** AC-15 specifies rate limiting for the edit endpoint, but the delete endpoint has zero throttling. A malicious user could spam DELETE requests at high velocity, causing excessive DB writes and WS broadcasts. | Add `throttle_classes = [ScopedRateThrottle]` and `throttle_scope = 'messaging'` to `DeleteMessageView`. |
| M2 | `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart:457-460` | **`editMessage()` fallback `orElse` returns `state.messages.first` which crashes on empty list.** If `state.messages` is empty, `state.messages.first` throws `StateError: No element`. | Replace with a null-safe approach: use `firstWhereOrNull` from collection package, or check `state.messages.isEmpty` first. Same issue at line 497-500 for `deleteMessage()`. |
| M3 | `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart:496-500` | **`deleteMessage()` has same `orElse` crash risk as M2.** Identical pattern with `state.messages.first` as fallback. | Same fix as M2. |
| M4 | `mobile/lib/features/messaging/data/services/messaging_ws_service.dart:145-147` | **Silent exception swallowing in `_onMessage`.** The catch block swallows ALL exceptions including programming errors (null dereference, type errors) with no logging. This violates the project rule "All functions...should raise errors if there is an error, NO exception silencing!" | At minimum log the error: `debugPrint('MessagingWsService._onMessage error: $e')`. Better: catch only `FormatException` and `TypeError` for malformed WS frames, rethrow others. |
| M5 | `web/src/hooks/use-messaging.ts:118-155` | **`useEditMessage` and `useDeleteMessage` hooks are dead code.** They take `messageId` as a hook parameter (requiring a new hook instance per message), but `chat-view.tsx` bypasses them entirely and calls `apiClient.patch`/`apiClient.delete` directly (lines 206-254). AC-32 is technically met (hooks exist) but they're never used. | Either (a) remove the dead hooks and document that `chat-view.tsx` handles mutations inline, or (b) refactor the hooks to accept `messageId` as a mutation variable (not a hook parameter) and actually use them in `chat-view.tsx`. Option (b) is cleaner and more consistent. |
| M6 | `web/src/hooks/use-messaging-ws.ts:219-239` and `241-263` | **WS cache updates only target page 1.** `updateMessageEdited` and `updateMessageDeleted` hardcode the query key to `["messaging", "messages", conversationId, 1]`. If the user has scrolled up and loaded page 2+, edits/deletes on those older messages won't be reflected until refetch. | Use `queryClient.invalidateQueries({ queryKey: ["messaging", "messages", conversationId] })` to invalidate all pages, or iterate over cached page keys. |
| M7 | `web/src/components/messaging/chat-view.tsx:223-226` and `248-250` | **No error feedback to user on edit/delete failure.** The catch blocks silently revert via `refetch()` but show no toast or error message. The ticket error states table says "Toast: 'Failed to edit message'" and "Toast: 'Failed to delete message'" should appear. | Add toast notifications in the catch blocks. |
| M8 | `mobile/lib/features/messaging/presentation/widgets/edit_message_sheet.dart:41` | **Edit sheet prevents saving empty content even for image messages.** `_canSave` requires `text.isNotEmpty`, but per edge case #8, "User tries to edit with empty content on an image message -> allowed." The backend allows this, but the mobile UI blocks it. | Pass `hasImage` boolean to `EditMessageSheet` and adjust `_canSave`: `return (text.isNotEmpty || hasImage) && text != widget.initialContent && text.length <= _maxLength;`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart:199` | **Deleted message text says "This message was deleted"** but AC-21 says "[This message was deleted]" with square brackets. | Change to `'[This message was deleted]'`. |
| m2 | `web/src/components/messaging/message-bubble.tsx:97` | **Same bracket mismatch on web.** Says "This message was deleted" but AC-29 says "[This message was deleted]". | Change to `[This message was deleted]`. |
| m3 | `mobile/lib/features/messaging/data/models/message_model.dart:42-43` | **`isEditWindowExpired` uses client-local `DateTime.now()`.** If the device clock is wrong, the edit window check will be inaccurate. The backend enforces the real check, so this is cosmetic only. | Accept as known limitation or add a comment. |
| m4 | `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart:60,282` | **`debugPrint` used for error logging.** The project rule says "No debug prints -- Remove all `print()` before committing." While `debugPrint` is a no-op in release builds, it still violates the stated convention. | Replace with a proper logging mechanism or remove. |
| m5 | `web/src/components/messaging/message-bubble.tsx:37-40` | **`canEdit` recalculated on every render using `Date.now()`.** At the 15-minute boundary, the edit button could flicker between renders. | Not critical. Could use a timer but likely negligible UX issue. |
| m6 | `backend/messaging/views.py:407` | **Extra DB query on edit response.** After `edit_message()` already fetched and saved the message, the view re-fetches it for serialization. Unnecessary round-trip. | Return the message object from the service or serialize from the result dataclass. |
| m7 | `web/src/components/messaging/chat-view.tsx:337-346` | **`onEdit`/`onDelete` callbacks passed to all own messages including deleted ones.** Harmless since `MessageBubble` checks `canEdit`/`canDelete`, but inconsistent with mobile code which filters them out. | Add `&& !message.is_deleted` condition when passing callbacks. |
| m8 | `backend/messaging/models.py:117-123` | **`Message.__str__` does not account for `is_deleted` state.** A deleted message shows `Message(user@email: )` in admin/logs. | Add early return: `if self.is_deleted: preview = '[deleted]'`. |

## Security Concerns

1. **Row-level security: PASS.** Both `edit_message()` and `delete_message()` verify the user is a conversation participant AND is the sender. The views additionally check conversation existence separately. Defense in depth is solid.

2. **IDOR protection: PASS.** Messages are fetched by both `id` AND `conversation`, preventing cross-conversation message manipulation.

3. **Impersonation guard: PASS.** `EditMessageView` and `DeleteMessageView` both check `is_impersonating(request.auth)` and return 403. Matches AC-13.

4. **Input validation: PASS.** Content is stripped and length-checked (2000 chars) in both serializer and service layer. Double validation is good.

5. **Data exposure: PASS.** `MessageSerializer` returns the same field structure for deleted messages (empty content, null image). No internal data leakage.

6. **WebSocket security: PASS.** WS edit/delete events only contain message_id, content, and edited_at -- no sensitive data. Events only broadcast to the conversation group which requires authenticated access.

7. **Image file leak on delete: CONCERN (C3).** Soft-deleting a message nulls the DB reference but the actual file remains on disk/S3. Anyone with the old URL can still access the image, which the user intended to delete.

## Performance Concerns

1. **No row locking (C1/C2).** Under concurrent requests, this could cause inconsistent state. The fix (select_for_update) adds minimal overhead.

2. **Extra query on edit response (m6).** Minor: one additional SELECT per edit operation. Not a concern at expected volume.

3. **Conversation list subquery: OK.** The new `last_message_is_deleted_subquery` mirrors existing subqueries and uses the same `(conversation, created_at)` index. No N+1 issue.

4. **WS cache update only targets page 1 (M6).** If users have loaded many history pages, old messages won't reflect edits/deletes until refetch. Functional but imperfect.

## Acceptance Criteria Check

### Backend
- [x] **AC-1:** `edited_at` and `is_deleted` fields added with migration 0004.
- [x] **AC-2:** PATCH endpoint exists and works.
- [x] **AC-3:** DELETE endpoint exists and works.
- [x] **AC-4:** Correct HTTP error codes for edit: 403 for non-sender, 400 for expired/deleted.
- [x] **AC-5:** Correct HTTP error codes for delete: 403 for non-sender, 400 for already deleted.
- [x] **AC-6:** Soft-delete clears content and image.
- [x] **AC-7:** Edit updates content and sets edited_at.
- [x] **AC-8:** Deleted messages returned with is_deleted=true, content="", image=null.
- [x] **AC-9:** WS broadcasts `chat.message_edited` with correct payload.
- [x] **AC-10:** WS broadcasts `chat.message_deleted` with message_id.
- [x] **AC-11:** Conversation list preview shows "This message was deleted" for deleted last message.
- [x] **AC-12:** Row-level security enforced (participant check + sender check).
- [x] **AC-13:** Impersonation guard present on both endpoints.
- [x] **AC-14:** `EditMessageResult` and `DeleteMessageResult` are frozen dataclasses.
- [?] **AC-15:** Edit has throttle class declared. Depends on `'messaging'` scope existing in settings (C4).

### Mobile (Flutter)
- [x] **AC-16:** Long-press shows context menu with Edit, Delete, Copy.
- [x] **AC-17:** Other's messages show Copy only.
- [x] **AC-18:** Edit opens bottom sheet with pre-filled content, Save, Cancel.
- [x] **AC-19:** Edit grayed out when window expired.
- [x] **AC-20:** Delete shows confirmation dialog with correct text.
- [FAIL] **AC-21:** Text says "This message was deleted" -- missing brackets per spec "[This message was deleted]". (m1)
- [x] **AC-22:** "(edited)" indicator shown next to timestamp.
- [x] **AC-23:** WS events update chat state in real-time.
- [x] **AC-24:** Optimistic update on delete with rollback.

### Web (Next.js)
- [x] **AC-25:** Hover shows pencil and trash icons.
- [x] **AC-26:** Inline edit with textarea, Save/Cancel, Esc/Ctrl+Enter.
- [x] **AC-27:** Edit icon hidden when window expired.
- [x] **AC-28:** Delete confirmation with destructive Delete button.
- [FAIL] **AC-29:** Text says "This message was deleted" -- missing brackets. (m2)
- [x] **AC-30:** "(edited)" shown next to timestamp.
- [x] **AC-31:** WS events update cache and local state.
- [x] **AC-32:** `useEditMessage()` and `useDeleteMessage()` hooks exist. (Note: dead code, see M5.)

### Edge Cases
1. Edit already-deleted -> 400 "Message has been deleted" -- **PASS**
2. Edit > 15 minutes -> 400 "Edit window has expired" -- **PASS**
3. Edit/delete other's message -> 403 -- **PASS**
4. Concurrent edits -> last-write-wins -- **PARTIAL** (works by accident but needs row locks, see C1)
5. Edit image message -> only text changes -- **PASS**
6. Delete image message -> content + image cleared -- **PASS** (DB reference, not file -- see C3)
7. Empty content on text-only -> 400 -- **PASS**
8. Empty content on image message -> allowed -- **PASS** backend, **FAIL** mobile edit sheet (M8)
9. WS disconnected -> polling fallback -- **PASS**
10. Last message deleted -> preview updates -- **PASS**
11. Impersonating admin -> 403 -- **PASS**

## Quality Score: 7/10

The implementation is thorough, well-structured, and follows existing patterns. The service layer cleanly separates PermissionError (403) from ValueError (400). Frozen dataclasses for results. Mobile has proper optimistic updates with rollback. Web has inline editing with keyboard shortcuts. WS integration is solid on both platforms. However, the race conditions on edit/delete (C1/C2) are real risks under concurrent load, the orphaned image files (C3) are a data privacy issue, two acceptance criteria fail on text format (AC-21/AC-29), and the mobile edit sheet blocks a valid edge case (M8).

## Recommendation: REQUEST CHANGES

**Must fix (blocking):**
1. C1/C2: Add `transaction.atomic()` + `select_for_update()` to `edit_message()` and `delete_message()`
2. C3: Delete actual image file from storage on soft-delete
3. C4: Verify `messaging` throttle rate exists in `settings.py`
4. m1/m2: Fix bracket text for deleted messages to match AC-21/AC-29

**Should fix:**
1. M1: Add rate limiting to `DeleteMessageView`
2. M2/M3: Fix `orElse` crash risk in mobile provider on empty message list
3. M4: Fix silent exception swallowing in mobile WS service
4. M5: Wire up or remove dead `useEditMessage`/`useDeleteMessage` hooks
5. M7: Add error toasts to web edit/delete handlers
6. M8: Fix edit sheet to allow empty content for image messages

# Dev Done: Message Editing and Deletion

## Date
2026-02-19

## Files Changed

### Backend
- `backend/messaging/models.py` — Added `edited_at` (DateTimeField, nullable) and `is_deleted` (BooleanField, default False) fields to Message model
- `backend/messaging/migrations/0004_add_edited_at_is_deleted_to_message.py` — Migration for new fields (already applied)
- `backend/messaging/services/messaging_service.py` — Added:
  - `EDIT_WINDOW = timedelta(minutes=15)` configurable constant
  - `EditMessageResult` and `DeleteMessageResult` frozen dataclasses
  - `edit_message()` — validates sender, edit window, deleted state, empty content
  - `delete_message()` — validates sender, already-deleted state, clears content + image
  - `broadcast_message_edited()` and `broadcast_message_deleted()` WS broadcast helpers
  - Updated `get_conversations_for_user()` with `annotated_last_message_is_deleted` subquery annotation
- `backend/messaging/serializers.py` — Added `EditMessageSerializer`, updated `MessageSerializer` with `edited_at` and `is_deleted` fields, updated `ConversationListSerializer.get_last_message_preview()` to show "This message was deleted"
- `backend/messaging/views.py` — Added `EditMessageView` (PATCH), `DeleteMessageView` (DELETE) with impersonation guards and row-level security
- `backend/messaging/urls.py` — Added URL patterns for edit (PATCH) and delete (DELETE) endpoints
- `backend/messaging/consumers.py` — Added `chat_message_edited` and `chat_message_deleted` WS event handlers

### Mobile (Flutter)
- `mobile/lib/features/messaging/data/models/message_model.dart` — Added `editedAt`, `isDeleted`, `isEdited`, `isEditWindowExpired` fields; updated `copyWith()` and `fromJson()`
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` — Added `editMessage()` and `deleteMessage()` API methods
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart` — Added `message_edited` and `message_deleted` WS event handlers
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — Added `onMessageEdited()`, `onMessageDeleted()`, `editMessage()`, `deleteMessage()` to ChatNotifier with optimistic updates and rollback
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Added deleted message placeholder, "(edited)" indicator, long-press to show context menu, `onEdit`/`onDelete` callbacks
- `mobile/lib/features/messaging/presentation/widgets/message_context_menu.dart` — **New file**: Bottom sheet context menu with Copy, Edit (grayed when expired), Delete (with confirmation dialog)
- `mobile/lib/features/messaging/presentation/widgets/edit_message_sheet.dart` — **New file**: Bottom sheet edit UI with pre-filled content, character counter, Save/Cancel
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart` — Passes `onEdit`/`onDelete` callbacks to MessageBubble
- `mobile/lib/core/constants/api_constants.dart` — Added `messagingEditMessage()` and `messagingDeleteMessage()` URLs

### Web (Next.js)
- `web/src/types/messaging.ts` — Added `edited_at` and `is_deleted` to `Message` interface
- `web/src/lib/constants.ts` — Added `messagingEditMessage()` and `messagingDeleteMessage()` URL functions
- `web/src/hooks/use-messaging.ts` — Added `useEditMessage()` and `useDeleteMessage()` mutation hooks
- `web/src/hooks/use-messaging-ws.ts` — Added `WsMessageEditedEvent`, `WsMessageDeletedEvent` types, `updateMessageEdited()`, `updateMessageDeleted()` cache helpers, and WS event handlers
- `web/src/components/messaging/message-bubble.tsx` — Added deleted placeholder, "(edited)" indicator, hover action icons (pencil/trash), inline edit mode with textarea + Save/Cancel, delete confirmation inline dialog
- `web/src/components/messaging/chat-view.tsx` — Added `handleEditMessage()` and `handleDeleteMessage()` with optimistic updates, passes callbacks to MessageBubble

## Key Decisions
1. **Edit uses PATCH, delete uses DELETE** — Standard REST semantics. Edit endpoint path includes message ID. Delete has a separate `/delete/` suffix to avoid conflict with the PATCH route.
2. **PermissionError vs ValueError** — Used `PermissionError` for "not your message" (→ 403) and `ValueError` for validation failures (→ 400). Clean separation in views.
3. **Soft-delete clears content AND image** — As per AC-6. `is_deleted=True`, `content=''`, `image=None`.
4. **Edit window is configurable** — `EDIT_WINDOW = timedelta(minutes=15)` constant in services.
5. **Optimistic updates with rollback** — Both mobile and web update UI immediately, revert on API failure.
6. **Web uses inline edit** — Textarea replaces content, Esc cancels, Ctrl/Cmd+Enter saves.
7. **Mobile uses bottom sheet** — Long-press → context menu → edit sheet or delete confirmation dialog.
8. **WS broadcasts from views, not services** — Keeps services pure and testable.

## Deviations from Ticket
- None. All 32 acceptance criteria addressed.

## How to Manually Test

### Backend
1. Send a message via POST `/api/messaging/conversations/<id>/send/`
2. Edit it via PATCH `/api/messaging/conversations/<id>/messages/<msg_id>/` with `{"content": "new text"}`
3. Verify edited_at is set in response
4. Wait 15+ minutes, try edit again → should get 400
5. Delete via DELETE `/api/messaging/conversations/<id>/messages/<msg_id>/delete/`
6. Verify is_deleted=true, content="", image=null
7. Try editing deleted message → 400
8. Try deleting already-deleted message → 400
9. Try editing/deleting another user's message → 403
10. Check conversation list → last message preview shows "This message was deleted"

### Mobile
1. Open a conversation, send a message
2. Long-press your message → context menu appears with Edit, Delete, Copy
3. Tap Edit → bottom sheet with pre-filled content, edit and save
4. Verify "(edited)" appears next to timestamp
5. Long-press again → tap Delete → confirmation dialog → confirm
6. Verify message shows "This message was deleted" in italic gray
7. Long-press other party's message → only "Copy" option shown
8. Send message, wait 15 minutes → Edit option should be grayed out

### Web
1. Open a conversation, send a message
2. Hover over your message → pencil and trash icons appear
3. Click pencil → inline edit mode with textarea
4. Edit text, press Ctrl+Enter to save (or click Save)
5. Verify "(edited)" appears next to timestamp
6. Click trash → "Delete this message?" confirmation appears
7. Confirm → message shows "This message was deleted"
8. Hover over other party's message → no action icons

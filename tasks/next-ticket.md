# Feature: Message Editing and Deletion

## Priority
High

## User Story
As a trainer or trainee, I want to edit or delete messages I've sent so that I can correct typos and remove messages sent by mistake.

## Acceptance Criteria

### Backend
- [ ] AC-1: Message model has `edited_at` (DateTimeField, nullable) and `is_deleted` (BooleanField, default False) fields with migration
- [ ] AC-2: PATCH `/api/messaging/conversations/<id>/messages/<message_id>/` edits message content (sender only, within 15-minute window)
- [ ] AC-3: DELETE `/api/messaging/conversations/<id>/messages/<message_id>/` soft-deletes message (sender only, no time limit)
- [ ] AC-4: Edit endpoint returns 403 if not the sender, 400 if message older than 15 minutes, 400 if message already deleted
- [ ] AC-5: Delete endpoint returns 403 if not the sender, 400 if message already deleted
- [ ] AC-6: Soft-deleted messages have `is_deleted=True` and content cleared to empty string. Image field set to None.
- [ ] AC-7: Edit updates `content` and sets `edited_at` to current timestamp
- [ ] AC-8: ConversationDetailView returns deleted messages as `{is_deleted: true, content: "", image: null}` (preserves message position in timeline)
- [ ] AC-9: WebSocket broadcasts `chat.message_edited` event with message_id, new content, and edited_at to conversation group
- [ ] AC-10: WebSocket broadcasts `chat.message_deleted` event with message_id to conversation group
- [ ] AC-11: Conversation list "last message" preview shows "This message was deleted" if the last message is deleted
- [ ] AC-12: Edit/delete endpoints have row-level security (user must be participant in conversation)
- [ ] AC-13: Impersonating users cannot edit or delete messages (same guard as send)
- [ ] AC-14: Service layer functions `edit_message()` and `delete_message()` with frozen dataclass results
- [ ] AC-15: Rate limiting on edit endpoint (30/minute, same as send)

### Mobile (Flutter)
- [ ] AC-16: Long-press on own message shows context menu with "Edit" and "Delete" options
- [ ] AC-17: Long-press on other's message shows "Copy" option only
- [ ] AC-18: "Edit" opens a bottom sheet with the message content pre-filled, "Save" button, and "Cancel"
- [ ] AC-19: Edit is disabled (grayed out in menu) if message is older than 15 minutes
- [ ] AC-20: "Delete" shows confirmation dialog: "Delete this message? This can't be undone."
- [ ] AC-21: Deleted messages display as "[This message was deleted]" in italic gray text, no sender info, timestamp preserved
- [ ] AC-22: Edited messages show "(edited)" text next to the timestamp
- [ ] AC-23: WebSocket events for edit/delete update the chat state in real-time
- [ ] AC-24: Optimistic update on delete (remove immediately, revert on error)

### Web (Next.js)
- [ ] AC-25: Hover on own message shows action icons (pencil for edit, trash for delete)
- [ ] AC-26: Edit opens inline edit mode: message content becomes a textarea with Save/Cancel buttons
- [ ] AC-27: Edit is disabled if message is older than 15 minutes (icon not shown or grayed out)
- [ ] AC-28: Delete shows confirmation dialog with "Delete" (destructive) and "Cancel" buttons
- [ ] AC-29: Deleted messages display as "[This message was deleted]" in muted italic text
- [ ] AC-30: Edited messages show "(edited)" text next to the timestamp
- [ ] AC-31: WebSocket events `message_edited` and `message_deleted` update React Query cache and local state in real-time
- [ ] AC-32: `useEditMessage()` and `useDeleteMessage()` mutation hooks

## Edge Cases
1. User tries to edit a message that was already deleted → 400 "Message has been deleted"
2. User tries to edit a message older than 15 minutes → 400 "Edit window has expired"
3. User tries to edit/delete someone else's message → 403 Forbidden
4. Two users try to edit the same message simultaneously → last-write-wins
5. User edits a message with an image → only text content changes, image preserved
6. User deletes a message with an image → both content cleared and image set to None
7. User tries to edit with empty content on a text-only message → 400 "Content cannot be empty"
8. User tries to edit with empty content on an image message → allowed (image-only message)
9. WebSocket disconnected when edit/delete happens → HTTP polling picks up changes on next fetch
10. Message is the last in conversation and gets deleted → conversation list preview updates
11. Impersonating admin tries to edit/delete → 403 Forbidden

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Edit fails (network) | Toast: "Failed to edit message" | Revert optimistic update |
| Delete fails (network) | Toast: "Failed to delete message" | Revert optimistic update |
| Edit window expired | Grayed-out edit option / toast | 400 from backend |
| Already deleted | "Message has been deleted" toast | 400 from backend |
| Not sender | Edit/delete actions not shown | 403 from backend |

## UX Requirements
- **Edit indicator:** Small "(edited)" text in muted color next to timestamp
- **Deleted state:** "[This message was deleted]" in italic muted text. Timestamp preserved.
- **Mobile context menu:** Bottom sheet with Edit (pencil), Delete (trash, red), Copy (clipboard). Long-press trigger.
- **Web action menu:** Icon buttons on hover over own messages. Pencil and trash.
- **Edit bottom sheet (mobile):** TextFormField pre-filled, character counter, Save/Cancel
- **Inline edit (web):** Textarea replaces content, Save/Cancel below. Esc cancels. Ctrl/Cmd+Enter saves.
- **Delete confirmation:** Dialog with destructive "Delete" button
- **Dark mode:** All states correct in dark mode

## Technical Approach

### Backend
- `backend/messaging/models.py` — Add `edited_at`, `is_deleted` fields
- `backend/messaging/views.py` — Add `EditMessageView`, `DeleteMessageView`
- `backend/messaging/services/messaging_service.py` — Add `edit_message()`, `delete_message()`, broadcast helpers
- `backend/messaging/serializers.py` — Update `MessageSerializer`, add `EditMessageSerializer`
- `backend/messaging/urls.py` — Add edit/delete URL patterns
- `backend/messaging/consumers.py` — Add `chat_message_edited`, `chat_message_deleted` handlers

### Mobile
- `mobile/lib/features/messaging/data/models/message_model.dart` — Add fields
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` — Add methods
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Edit/delete UI
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — Mutations + WS events
- `mobile/lib/core/constants/api_constants.dart` — New endpoints
- New: `message_context_menu.dart`, `edit_message_sheet.dart`

### Web
- `web/src/components/messaging/message-bubble.tsx` — Hover actions, inline edit, deleted state
- `web/src/components/messaging/chat-view.tsx` — WS event handlers
- `web/src/hooks/use-messaging.ts` — `useEditMessage()`, `useDeleteMessage()`
- `web/src/hooks/use-messaging-ws.ts` — New WS event types
- `web/src/lib/constants.ts` — New API URLs
- `web/src/types/messaging.ts` — Updated Message type

## Out of Scope
- Edit history UI
- Admin force-delete
- Bulk delete
- "Unsend" (retroactive removal)

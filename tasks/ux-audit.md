# UX Audit: Message Editing and Deletion (Pipeline 23)

## Audit Date
2026-02-19

## Files Audited
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_context_menu.dart`
- `mobile/lib/features/messaging/presentation/widgets/edit_message_sheet.dart`
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart`
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart`
- `mobile/lib/features/messaging/data/models/message_model.dart`
- `mobile/lib/features/messaging/data/models/conversation_model.dart`
- `mobile/lib/features/messaging/presentation/widgets/conversation_tile.dart`
- `web/src/components/messaging/message-bubble.tsx`
- `web/src/components/messaging/chat-view.tsx`
- `web/src/hooks/use-messaging.ts`
- `web/src/hooks/use-messaging-ws.ts`
- `web/src/types/messaging.ts`
- `backend/messaging/serializers.py`
- `backend/messaging/services/messaging_service.py`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | Web message-bubble.tsx | Delete confirmation disappears when mouse leaves the message hover area. User clicks trash icon, then moves mouse to the confirmation bar that appears below, which is outside the onMouseLeave container. The confirmation vanishes before they can click "Delete". | Remove setShowDeleteConfirm(false) from onMouseLeave. Add Escape key handler to dismiss instead. | FIXED |
| 2 | Major | Mobile chat_screen.dart | Edit/delete failures set error in ChatState but no snackbar is shown to the user. The error is silently stored in state. User sees message revert but has no idea why. | Add ref.listen for error state changes, show SnackBar on new errors, clear error after display. | FIXED |
| 3 | Medium | Web message-bubble.tsx | Keyboard shortcut hint says "Ctrl+Enter" on macOS. Should show the platform-appropriate modifier key. | Detect macOS via navigator.userAgent and show command symbol instead. | FIXED |
| 4 | Medium | Web message-bubble.tsx | Inline edit Save button disabled for image messages with empty text. AC-8 specifies that editing to empty content on an image message should be allowed (image-only message). | Check hasImage in the disabled condition: allow empty trim when image is present. | FIXED |
| 5 | Minor | Mobile messaging_provider.dart | ChatNotifier has no clearError() method. Errors set during editMessage/deleteMessage persist in state indefinitely and could cause stale error display on future state transitions. | Add clearError() method. Call it from the UI after displaying the snackbar. | FIXED |
| 6 | Minor | Web message-bubble.tsx | handleSaveEdit also blocks saving empty content for image messages. Same root cause as #4 but in the handler logic. | Update canSave logic in handleSaveEdit to allow empty for hasImage. | FIXED |

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A | Mobile _buildDeletedBubble has no Semantics widget. Screen readers cannot read deleted message text or timestamp. Normal messages wrap in Semantics but deleted messages skip it. | Added Semantics(label: ...) wrapping the deleted bubble with sender name, deleted status, and timestamp. | FIXED |
| 2 | A | Web delete confirmation inline dialog has no ARIA role. Screen readers do not announce it as a dialog. | Added role="alertdialog" and aria-label="Confirm message deletion" to the confirmation container. | FIXED |
| 3 | A | Web deleted message container has no aria-label. Screen readers cannot distinguish deleted messages from normal ones. | Added aria-label with sender context and timestamp to the deleted message wrapper div. | FIXED |
| 4 | AA | Web delete confirmation has no keyboard dismissal. Keyboard-only users cannot escape the confirmation without using a mouse. | Added useEffect with Escape keydown listener that dismisses the confirmation. | FIXED |

## Missing States

- [x] Loading / skeleton -- Both mobile and web have loading states with skeleton messages and spinners respectively.
- [x] Empty / zero data -- Both platforms show "No messages yet" empty states.
- [x] Error / failure -- Error state with retry button on both platforms. Edit/delete failure now shows snackbar (mobile) and toast (web).
- [x] Success / confirmation -- Optimistic updates provide instant visual feedback on edit (shows "(edited)") and delete (shows placeholder). Copy shows snackbar confirmation.
- [x] Offline / degraded -- Web shows connection banner. Mobile has WS reconnect. HTTP polling fallback on web.
- [x] Permission denied -- Edit/delete actions hidden for other users' messages. Backend returns 403. Context menu only shows "Copy" for others' messages.
- [x] Edited state -- "(edited)" label shows in muted italic next to timestamp on both platforms.
- [x] Deleted state -- "[This message was deleted]" in italic muted text. Timestamp preserved. Both platforms match.
- [x] Edit window expired -- Mobile: grayed out Edit option with "Edit window expired" subtitle. Web: edit pencil icon not shown when expired.
- [x] Dark mode -- Uses theme tokens throughout (mobile: Theme.of(context), web: Tailwind CSS variables). All states should render correctly in dark mode.

## Consistency Across Platforms

| Aspect | Mobile | Web | Consistent? |
|--------|--------|-----|-------------|
| Deleted text | "[This message was deleted]" italic muted | "[This message was deleted]" italic muted | Yes |
| Edited indicator | "(edited)" next to timestamp, italic | "(edited)" next to timestamp, italic | Yes |
| Edit trigger | Long-press context menu | Hover action icon | Platform-appropriate |
| Delete confirmation | AlertDialog with Cancel/Delete | Inline bar with Delete/X button | Platform-appropriate |
| Delete copy | "Delete this message? This can't be undone." | "Delete this message? This can't be undone." | Yes (after fix) |
| Optimistic updates | Edit and delete both optimistic with revert | Edit and delete both optimistic with revert | Yes |
| Error feedback | SnackBar (after fix) | Toast via sonner | Platform-appropriate |
| Edit window expired | Grayed option + subtitle text | Icon not shown | Both clear |
| Character counter | Visible in edit sheet (X/2000) | maxLength on textarea | Both enforce limit |
| Save shortcut | N/A (mobile) | Ctrl/Cmd+Enter + Esc | Web-appropriate |

## What Was Already Done Well

1. Optimistic updates with proper revert -- Both mobile and web implement optimistic UI for edit and delete with full state reversion on network failure.
2. WebSocket real-time sync -- Both platforms handle message_edited and message_deleted WS events, updating the UI in real-time for the other participant.
3. Edit window enforcement -- Client-side 15-minute check mirrors the backend. Mobile shows disabled state with explanation text.
4. Context menu design -- Mobile bottom sheet with clear iconography (pencil for edit, red trash for delete). Web hover icons are unobtrusive.
5. Conversation list preview -- Backend correctly returns "This message was deleted" for the last message preview when it is soft-deleted.
6. Image handling -- Image-only messages handled correctly in delete (clears image). Edit preserves images.
7. Semantics on normal messages -- Good accessibility labels with sender, content type, timestamp, edit status, and read status.

## Recommendations Not Implemented (Future Consideration)

1. Haptic feedback on long-press -- Mobile context menu trigger should include light haptic feedback for better tactile confirmation.
2. Edit countdown timer -- Consider showing remaining edit time (e.g., "12 min left to edit") in the edit sheet or context menu for better transparency.
3. Undo delete toast -- Instead of a confirmation dialog before delete, consider a post-delete "Undo" toast pattern (like Gmail). Less friction, same safety. Out of scope per ticket though.
4. Batch message operations -- Long-press to select multiple messages for deletion is a common pattern in chat apps. Listed as out of scope.

## Overall UX Score: 9/10

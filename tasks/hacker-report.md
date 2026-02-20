# Hacker Report: Message Editing and Deletion (Pipeline 23)

## Date: 2026-02-19

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | -- |

No dead buttons or non-functional UI elements found. All edit/delete buttons correctly wire to their respective handlers across mobile, web, and backend.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| -- | -- | -- | -- | -- |

No visual misalignments found. Both mobile and web deleted message placeholders, edit indicators, and context menus are visually consistent with the existing message design language.

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Backend delete tests | Run `python manage.py test messaging` | All delete view tests pass against the actual endpoint | Tests used `/messages/<id>/delete/` URL which doesn't exist in urls.py -- the actual endpoint is `/messages/<id>/` with DELETE method. Tests would hit a 404 or wrong view and silently pass/fail for wrong reasons. **FIXED**: Updated 3 test URLs to use the correct RESTful endpoint. |
| 2 | High | Edit message with empty content (image message, backend) | PATCH a message that has an image with `{"content": ""}` | 200 OK -- image-only message allowed per edge case 8 | 400 Bad Request -- `EditMessageSerializer` had `allow_blank=False` (default), rejecting empty strings before the service layer could check for image presence. **FIXED**: Added `allow_blank=True` to `EditMessageSerializer.content` field. |
| 3 | High | Web: Other party edits/deletes a message | User A sends a message, User B views it, User A edits or deletes via another client | User B's chat view updates in real-time via WebSocket | The WS `message_edited` and `message_deleted` events updated the React Query cache but did NOT update `ChatView`'s local `allMessages` state. User B would see stale content until next HTTP poll or page refresh. **FIXED**: Added `onMessageEdited` and `onMessageDeleted` callbacks to `useMessagingWebSocket` hook, wired them in `ChatView` to directly update `allMessages` state. |
| 4 | Low | Mobile: Convention violation -- debugPrint in production code | Trigger any error in conversation loading or message loading | Error state shown to user | `debugPrint()` calls logged to console, violating project convention "No debug prints". **FIXED**: Removed 3 `debugPrint()` calls and the `flutter/foundation.dart` import from `messaging_provider.dart`. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Mobile conversation list | Update conversation list preview in real-time when the last message is edited or deleted via WebSocket | Currently the mobile conversation list preview goes stale if the last message in a conversation is edited/deleted by the other party. The web side already invalidates the conversations cache on edit/delete WS events. The mobile side should do the same -- e.g., call `conversationListProvider.loadConversations()` or update the specific conversation's preview optimistically from the WS event. |
| 2 | Low | Backend: Audit trail | Store `original_content` field on Message model for edit audit trail | The focus.md mentions "store original_content for future audit, but no UI to view edit history." The current implementation does not store the original content before edits. Future admin tooling would benefit from having the pre-edit content stored. Not in AC scope so not implemented. |
| 3 | Low | Mobile: Edit window countdown | Show remaining time to edit in the context menu | Currently the edit option is simply grayed out with "Edit window expired" text. Showing remaining time (e.g., "Edit (12 min left)") would reduce user confusion about why the edit option disappears. |
| 4 | Low | Web: Keyboard shortcut hint | Show Cmd vs Ctrl based on platform in edit mode | The inline edit hint already detects Mac/Windows and shows the appropriate modifier key symbol (already implemented in the file). Confirming this works correctly. |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 0
- Logic bugs found: 4
- Improvements suggested: 4
- Items fixed by hacker: 4

### Files Modified
1. `backend/messaging/tests/test_edit_delete.py` -- Fixed 3 URLs in delete view tests (Critical)
2. `backend/messaging/serializers.py` -- Added `allow_blank=True` to `EditMessageSerializer` (High)
3. `web/src/hooks/use-messaging-ws.ts` -- Added `onMessageEdited`/`onMessageDeleted` callbacks (High)
4. `web/src/components/messaging/chat-view.tsx` -- Wired WS edit/delete callbacks to update local state (High)
5. `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` -- Removed debugPrint calls (Low)

### Test Results
All 107 messaging tests pass after fixes.

## Chaos Score: 8/10
The implementation is solid overall. The three bugs I found were:
1. A critical test URL mismatch that meant delete view tests were testing the wrong endpoint entirely
2. A serializer-level validation that blocked a legitimate edge case (image message caption clearing)
3. A real-time sync gap on web where the other party's edits/deletes didn't update local state

All three were real issues that would affect production users. The codebase conventions are well-followed, the security model is sound (row-level checks at every layer), and the optimistic updates with rollback are correctly implemented. The WS integration is robust with heartbeats, reconnection, and fallback polling.

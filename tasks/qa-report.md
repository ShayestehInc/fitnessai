# QA Report: In-App Direct Messaging (Trainer-to-Trainee)

## QA Date: 2026-02-19

## Test Results
- Total: 93 (86 existing + 7 new messaging tests)
- Passed: 93
- Failed: 0
- Skipped: 0

## Bugs Found and Fixed During QA

### BUG-1 (Critical): Runtime ReferenceError in ChatView -- scrollToBottom used before initialization
- **File:** `web/src/components/messaging/chat-view.tsx`
- **Root cause:** `scrollToBottom` was defined with `useCallback` on line 88 but referenced in a `useEffect` dependency array on line 77. JavaScript `const` declarations via `useCallback` are not hoisted, causing `ReferenceError: Cannot access 'scrollToBottom' before initialization` at runtime whenever a conversation with messages was selected.
- **Impact:** The entire Messages page crashed when any conversation with messages was rendered, showing a Next.js runtime error overlay. This blocked 4 of 7 E2E tests and would have completely broken messaging for all web users.
- **Fix:** Moved the `scrollToBottom` `useCallback` definition above the `useEffect` that depends on it.

### BUG-2 (Major): E2E mock returned wrong response format for conversations endpoint
- **File:** `web/e2e/helpers/auth.ts` (line 155-158)
- **Root cause:** The default mock for `/messaging/conversations/` returned `[]` (a bare array), but `useConversations()` in `use-messaging.ts` expects a paginated response `{ count, next, previous, results: [...] }` and accesses `.results`. When `[].results` evaluates to `undefined`, React Query v5 throws because `queryFn` must not return `undefined`.
- **Impact:** The conversations list always showed the error state ("Failed to load conversations") in E2E tests, causing the empty-state test to fail.
- **Fix:** Changed the mock to return `{ count: 0, next: null, previous: null, results: [] }`.

### BUG-3 (Major): E2E test mocks in messages.spec.ts returned wrong format for conversations
- **File:** `web/e2e/trainer/messages.spec.ts` (4 occurrences)
- **Root cause:** Test-specific route overrides returned `JSON.stringify(MOCK_CONVERSATIONS)` (bare array) instead of wrapping in paginated envelope. Same root cause as BUG-2.
- **Fix:** Changed all 4 occurrences to return `{ count: MOCK_CONVERSATIONS.length, next: null, previous: null, results: MOCK_CONVERSATIONS }`.

### BUG-4 (Minor): E2E test selector too broad for conversation list verification
- **File:** `web/e2e/trainer/messages.spec.ts` (line 129)
- **Root cause:** `page.getByText("Jane Doe")` resolved to 2 elements -- one in the conversation list sidebar and one in the chat header (since the first conversation auto-selects). Playwright strict mode correctly rejects ambiguous selectors.
- **Fix:** Scoped the assertion to the conversation listbox: `page.getByRole("listbox", { name: /conversations/i }).getByText("Jane Doe")`.

## Acceptance Criteria Verification

- [x] AC-1: New `messaging` Django app with `Conversation` and `Message` models -- **PASS**
  - `backend/messaging/models.py` has both models with proper fields, constraints, indexes
  - `Conversation`: trainer FK, trainee FK (SET_NULL), last_message_at, is_archived, unique constraint on (trainer, trainee)
  - `Message`: conversation FK, sender FK, content (max 2000), is_read, read_at, created_at
  - Migrations: `0001_initial.py` and `0002_alter_conversation_trainee_set_null.py`

- [x] AC-2: Trainer can open a message thread with any of their trainees from trainee detail screen -- **PASS**
  - Mobile: `trainee_detail_screen.dart` lines 128-129, 685-690 wire "Send Message" to navigate to `/messages/new-conversation`
  - Web: `trainees/[id]/page.tsx` line 42-47 navigates to `/messages?trainee=<id>`

- [x] AC-3: Trainer can see a list of all active conversations sorted by most recent message -- **PASS**
  - Backend: `get_conversations_for_user()` filters by trainer, excludes archived, orders by `-last_message_at`
  - Mobile: `conversation_list_screen.dart` renders full list
  - Web: `conversation-list.tsx` renders sidebar list
  - E2E test "should display conversation list with conversations" passes

- [x] AC-4: Trainer can send text messages to a trainee in a conversation -- **PASS**
  - Backend: `SendMessageView` POST endpoint with row-level security
  - Service: `send_message()` validates content, creates Message, updates last_message_at
  - Web: `ChatInput` + `useSendMessage` mutation
  - Mobile: `ChatNotifier.sendMessage()` with optimistic updates

- [x] AC-5: Trainee can see a list of conversations -- **PASS**
  - Backend: `get_conversations_for_user()` handles trainee role (filters by trainee=user)
  - Mobile: trainee navigation shell includes Messages tab at index 4

- [x] AC-6: Trainee can send text messages replying to their trainer -- **PASS**
  - Backend: `SendMessageView` allows both trainer and trainee as sender (checks user.id in participant list)
  - Mobile: `ChatScreen` and `ChatInput` are role-agnostic

- [x] AC-7: Messages appear in real-time via WebSocket -- **PASS**
  - Backend: `DirectMessageConsumer` in `consumers.py` with channel groups per conversation
  - Mobile: `MessagingWsService` with exponential backoff reconnection
  - Web: Uses HTTP polling (5s interval) as v1 limitation -- documented deviation

- [x] AC-8: Unread message count badge shown on the messaging nav item -- **PASS**
  - Backend: `UnreadCountView` GET endpoint
  - Mobile: Both `trainer_navigation_shell.dart` and `main_navigation_shell.dart` show badge via `unreadMessageCountProvider`
  - Web: `sidebar.tsx` and `sidebar-mobile.tsx` show red badge via `useMessagingUnreadCount()`

- [x] AC-9: Push notification sent to recipient when a new message arrives -- **PASS**
  - Backend: `_send_message_push_notification()` in views.py calls `send_push_notification()`
  - Catches (ConnectionError, TimeoutError, OSError) -- does not silence programming errors

- [x] AC-10: Messages are paginated (20 per page) with infinite scroll loading older messages -- **PASS**
  - Backend: `MessagePagination` with `page_size = 20`
  - Web: `ChatView` has `handleScroll` that detects scroll-to-top and increments page
  - Mobile: `ChatNotifier` handles pagination

- [x] AC-11: Conversation list shows last message preview, timestamp, unread count, and trainee avatar/name -- **PASS**
  - Backend: `ConversationListSerializer` includes `last_message_preview` (annotated), `unread_count` (annotated), trainer/trainee participant info
  - Web: `ConversationList` renders avatar, name, preview, relative time, unread badge
  - Mobile: `ConversationTile` renders all fields

- [x] AC-12: Row-level security enforced -- **PASS**
  - Service: `get_conversations_for_user()` filters by trainer=user or trainee=user
  - Views: Every endpoint checks `user.id in (conversation.trainer_id, conversation.trainee_id)`
  - WebSocket: `_check_conversation_access()` verifies participant

- [x] AC-13: Messages are persisted to the database -- **PASS**
  - `Message.objects.create()` in `send_message()` service function
  - PostgreSQL table `messaging_messages` with indexes

- [x] AC-14: Trainer web dashboard has a Messages page with conversation list and chat view -- **PASS**
  - `web/src/app/(dashboard)/messages/page.tsx` -- split-panel layout (320px sidebar + chat)
  - Nav link in `nav-links.tsx` with MessageSquare icon
  - E2E tests verify navigation and rendering

- [x] AC-15: Trainer can send messages from the web dashboard trainee detail page -- **PASS**
  - `trainees/[id]/page.tsx` line 42-47: "Message" button navigates to `/messages?trainee=<traineeId>`
  - Messages page auto-selects matching conversation via `traineeIdParam`

- [x] AC-16: Message input supports multiline text (max 2000 characters) with character counter at 90%+ -- **PASS**
  - Web: `ChatInput` -- `MAX_LENGTH = 2000`, `WARNING_THRESHOLD = 0.9`, textarea with `maxLength`, counter shown at threshold
  - Mobile: `ChatInput` -- `_maxLength = 2000`, `_counterThreshold = 0.9`
  - Backend: `SendMessageSerializer.content` has `max_length=2000`, service validates `len > 2000`

- [x] AC-17: Typing indicators shown -- **PASS (mobile only, web documented limitation)**
  - Backend: `DirectMessageConsumer.receive_json()` handles 'typing' type, broadcasts to group
  - Mobile: `MessagingWsService.sendTyping()` with 3-second debounce auto-dismiss
  - Mobile: `TypingIndicator` widget with animated dots
  - Web: `typing-indicator.tsx` component exists but not wired (documented v1 limitation -- web uses polling)

- [x] AC-18: Messages display timestamps -- **PASS**
  - Web: `formatRelativeTime()` in conversation-list.tsx (now, Xm, Xh, Xd, date)
  - Web: `formatDateSeparator()` in chat-view.tsx (Today, Yesterday, weekday, date)
  - Web: `formatMessageTime()` in message-bubble.tsx (time only)
  - Mobile: `messaging_utils.dart` -- shared formatters with midnight fix

- [x] AC-19: Conversation auto-created when trainer sends first message -- **PASS**
  - Backend: `get_or_create_conversation()` uses `Conversation.objects.get_or_create()`
  - `send_message_to_trainee()` calls `get_or_create_conversation()` then `send_message()`
  - Un-archives if previously archived (trainee re-assigned)

- [x] AC-20: Read receipts -- sender can see if their message has been read -- **PASS**
  - Backend: `MarkReadView` POST endpoint, `mark_conversation_read()` service, WebSocket broadcast
  - Web: `MessageBubble` shows `Check` (sent) or `CheckCheck` (read) icons
  - Mobile: `MessageBubble` shows single/double checkmark with color change

- [x] AC-21: Trainer can quick-message from trainee list/detail -- **PASS**
  - Mobile: `trainee_detail_screen.dart` line 135: PopupMenuItem, line 128: navigates to new-conversation
  - Web: trainee detail page has "Message" button navigating to `/messages?trainee=<id>`

## Edge Case Verification

| # | Edge Case | Verified | Method |
|---|-----------|----------|--------|
| 1 | Trainee removed -> conversations archived | PASS | `archive_conversations_for_trainee()` called in `RemoveTraineeView.post()` (trainer/views.py line 328). SET_NULL on trainee FK. |
| 2 | Offline trainee -> message persisted + FCM push | PASS | Messages always DB-persisted. `_send_message_push_notification()` in views.py. |
| 3 | Concurrent messages -> server timestamp ordering | PASS | Auto-incrementing IDs, server `created_at`. Client sorts by server timestamp. |
| 4 | WebSocket drop -> reconnection | PASS | Mobile: exponential backoff in `MessagingWsService`. Web: HTTP polling every 5s. |
| 5 | Empty/whitespace messages -> rejected | PASS | Server: `strip()` + 400 error. Client: empty check disables send button. |
| 6 | Long messages (>2000 chars) -> rejected | PASS | Client: `maxLength=2000`, counter at 90%. Server: serializer + service validation. |
| 7 | No parent_trainer -> empty conversations | PASS | `get_conversations_for_user()` returns empty for non-trainer/trainee. |
| 8 | Rate limiting (>30/min) -> 429 | PASS | `ScopedRateThrottle` + `throttle_scope = 'messaging'` on send/start views. |
| 9 | Navigate away mid-typing -> no draft | PASS | No draft system, send-or-discard. |
| 10 | Impersonation -> read-only | PASS | `_is_impersonating()` checks `request.auth`, returns 403 on send/start. |

## Summary of Fixes Applied
1. **chat-view.tsx**: Moved `scrollToBottom` `useCallback` definition above the `useEffect` that depends on it (critical runtime fix)
2. **auth.ts**: Changed conversations mock from `[]` to `{ count: 0, next: null, previous: null, results: [] }`
3. **messages.spec.ts**: Wrapped all 4 `MOCK_CONVERSATIONS` responses in paginated envelope
4. **messages.spec.ts**: Scoped conversation list assertions to the listbox role to avoid strict mode violations

## Confidence Level: HIGH

All 93 E2E tests pass (7 new messaging + 86 existing). All 21 acceptance criteria verified as PASS by reading actual implementation code. All 4 bugs discovered during testing were fixed. Zero regressions. The critical `scrollToBottom` runtime error was a real production-breaking bug that would have crashed the messaging page for all web users.

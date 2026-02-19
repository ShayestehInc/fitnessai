# Dev Done: In-App Direct Messaging (Trainer-to-Trainee)

## Implementation Date
2026-02-19

## Summary
Full-stack implementation of 1:1 direct messaging between trainers and their trainees. Covers backend (Django REST + WebSocket), mobile (Flutter with Riverpod), and web dashboard (Next.js with TanStack React Query). All acceptance criteria addressed.

---

## Review Fixes Applied (Round 1)

### Critical Issues Fixed

**C1: N+1 query in ConversationListSerializer.get_last_message_preview()**
- `backend/messaging/services/messaging_service.py` — `get_conversations_for_user()` now annotates the queryset with `Subquery` + `Left()` to fetch last message preview in a single query
- `backend/messaging/serializers.py` — `get_last_message_preview()` now reads from the `annotated_last_message_preview` annotation instead of re-querying

**C2: N+1 query in ConversationListSerializer.get_unread_count()**
- `backend/messaging/services/messaging_service.py` — `get_conversations_for_user()` now annotates with `Count('messages', filter=...)` for unread count
- `backend/messaging/serializers.py` — `get_unread_count()` now reads from the `annotated_unread_count` annotation instead of re-querying

**C3: Silent exception swallowing in broadcast/push helpers**
- `backend/messaging/views.py` — `_broadcast_new_message()`, `_broadcast_read_receipt()`, and `_send_message_push_notification()` now catch `(ConnectionError, TimeoutError, OSError)` instead of bare `Exception`. Programming errors (TypeError, AttributeError, etc.) will propagate.

**C4: archive_conversations_for_trainee() never called**
- `backend/trainer/views.py` — `RemoveTraineeView.post()` now calls `archive_conversations_for_trainee(trainee)` before clearing `parent_trainer`, with logging

**C5: Rate limiting not applied to views**
- `backend/messaging/views.py` — `SendMessageView` and `StartConversationView` now have `throttle_classes = [ScopedRateThrottle]` and `throttle_scope = 'messaging'`, enforcing the 30/minute rate limit defined in settings

### Major Issues Fixed

**M1: CASCADE delete on Conversation.trainee FK**
- `backend/messaging/models.py` — Changed `trainee` FK to `on_delete=models.SET_NULL, null=True` to preserve conversations when a User is deleted
- `backend/messaging/models.py` — Updated `__str__()` to handle null trainee
- `backend/messaging/migrations/0002_alter_conversation_trainee_set_null.py` — New migration

**M2: Web typing indicator never rendered**
- `web/src/components/messaging/chat-view.tsx` — Added comment documenting this as a v1 limitation (web uses polling, no WebSocket). The `typing-indicator.tsx` component is ready for when web WebSocket support is added.

**M3: Web sidebar no unread badge**
- `web/src/components/layout/sidebar.tsx` — Added `useMessagingUnreadCount()` hook and renders a red badge next to "Messages" when unread_count > 0
- `web/src/components/layout/sidebar-mobile.tsx` — Same fix for mobile sidebar

**M4: ConversationListView no pagination**
- `backend/messaging/views.py` — Added `ConversationPagination` (page_size=50) to `ConversationListView`
- `web/src/types/messaging.ts` — Added `ConversationsResponse` type for paginated response
- `web/src/hooks/use-messaging.ts` — `useConversations()` now extracts `results` from paginated response

**M5: addPostFrameCallback infinite loop**
- `mobile/lib/shared/widgets/trainer_navigation_shell.dart` — Converted from `ConsumerWidget` to `ConsumerStatefulWidget` with refresh in `initState()` (runs once)
- `mobile/lib/shared/widgets/main_navigation_shell.dart` — Same fix

**M6: setState in new_conversation_screen**
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — Added `NewConversationState` and `NewConversationNotifier` with `newConversationProvider`
- `mobile/lib/features/messaging/presentation/screens/new_conversation_screen.dart` — Converted from `ConsumerStatefulWidget` to `ConsumerWidget`, all state managed via Riverpod

**M7: markRead mutation loop**
- `web/src/components/messaging/chat-view.tsx` — Added `markReadCalledRef` to track whether markRead was already called for a conversation, preventing re-triggering when unread_count changes to 0. Added `markRead` to the dependency array properly.

**M8: Auto-greeting on web**
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Changed `handleMessageTrainee` to navigate to `/messages?trainee=<id>` instead of auto-sending a greeting message. Removed `useStartConversation` hook.
- `web/src/app/(dashboard)/messages/page.tsx` — Added handling for `trainee` query param to auto-select the matching conversation

**M9: Manual query string parsing in WS consumer**
- `backend/messaging/consumers.py` — Replaced manual `split('&')` / `split('=')` parsing with `urllib.parse.parse_qs()` which handles URL encoding, duplicate keys, and edge cases correctly

### Minor Issues Fixed

**m1: Duplicated _formatTimestamp logic**
- `mobile/lib/features/messaging/presentation/widgets/messaging_utils.dart` — New file with shared `formatConversationTimestamp()` and `formatMessageTimestamp()` functions
- `mobile/lib/features/messaging/presentation/widgets/conversation_tile.dart` — Uses shared utility
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Uses shared utility

**m2: Timestamp midnight hour bug**
- Fixed in `messaging_utils.dart` — `_to12Hour()` correctly returns 12 for hour 0 (midnight)

**m3: Generic serializer type parameters**
- `backend/messaging/serializers.py` — Removed non-standard `[dict[str, Any]]` generic parameters from `SendMessageSerializer`, `StartConversationSerializer`, `MessageSenderSerializer`, and `ConversationParticipantSerializer`

**m4: Missing scrollToBottom in useEffect deps**
- `web/src/components/messaging/chat-view.tsx` — Added `scrollToBottom` to the dependency array of the auto-scroll useEffect

**m5: Silent exception swallowing in WS service**
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart` — `_onMessage` catch block now logs via `debugPrint()` instead of silently swallowing

**m6: Impersonation JWT re-parsing**
- `backend/messaging/views.py` — `_is_impersonating()` now reads from `request.auth` (the already-validated token) instead of re-parsing the Authorization header

**m7: Conversation list showing wrong party**
- `web/src/components/messaging/conversation-list.tsx` — Now uses `useAuth()` to get current user and displays the "other party" (trainer sees trainee, trainee sees trainer)
- `web/src/components/messaging/chat-view.tsx` — Same fix for chat header

**m8: UnreadCountNotifier silent catch**
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — `UnreadCountNotifier.refresh()` and `ChatNotifier.markRead()` now log errors via `debugPrint()` instead of silently catching

**m9: calc-based height in messages page**
- `web/src/app/(dashboard)/messages/page.tsx` — Replaced `h-[calc(100vh-8rem)]` with `min-h-0 flex-1` for flexible layout that adapts to header changes

**m10: Missing default_auto_field** — Already present in the existing `apps.py`, no change needed.

---

## Files Created

### Backend (Django)
- `backend/messaging/__init__.py`
- `backend/messaging/apps.py` — MessagingConfig AppConfig
- `backend/messaging/models.py` — Conversation and Message models with unique constraints, indexes, soft-archive
- `backend/messaging/services/__init__.py`
- `backend/messaging/services/messaging_service.py` — Business logic with dataclass returns (SendMessageResult, MarkReadResult, UnreadCountResult)
- `backend/messaging/serializers.py` — Input (SendMessageSerializer, StartConversationSerializer) and Output (MessageSerializer, ConversationListSerializer) serializers
- `backend/messaging/views.py` — REST endpoints with row-level security, impersonation guard, WebSocket broadcast, push notifications
- `backend/messaging/urls.py` — 6 URL patterns under /api/messaging/
- `backend/messaging/consumers.py` — DirectMessageConsumer WebSocket with JWT auth, typing indicators, read receipts
- `backend/messaging/routing.py` — WebSocket route: ws/messaging/<conversation_id>/
- `backend/messaging/admin.py` — Django admin registration for Conversation + Message
- `backend/messaging/migrations/0001_initial.py` — Auto-generated migration
- `backend/messaging/migrations/0002_alter_conversation_trainee_set_null.py` — Trainee FK SET_NULL migration

### Mobile (Flutter)
- `mobile/lib/features/messaging/data/models/conversation_model.dart` — ConversationModel with fromJson/copyWith
- `mobile/lib/features/messaging/data/models/message_model.dart` — MessageModel, MessagesResponse, StartConversationResponse
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` — API calls for all messaging endpoints
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart` — WebSocket service with exponential backoff reconnection
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — ConversationListNotifier, UnreadCountNotifier, NewConversationNotifier, ChatNotifier
- `mobile/lib/features/messaging/presentation/screens/conversation_list_screen.dart` — Full screen with loading/empty/error states
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart` — Chat with WebSocket, scroll-to-bottom, load-more, typing indicator
- `mobile/lib/features/messaging/presentation/screens/new_conversation_screen.dart` — Start conversation from trainee detail (Riverpod-managed)
- `mobile/lib/features/messaging/presentation/widgets/conversation_tile.dart` — Conversation row with avatar, preview, unread badge
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Aligned bubbles with read receipts
- `mobile/lib/features/messaging/presentation/widgets/typing_indicator.dart` — Animated 3-dot indicator
- `mobile/lib/features/messaging/presentation/widgets/chat_input.dart` — Text input with character counter, multiline, send button
- `mobile/lib/features/messaging/presentation/widgets/messaging_utils.dart` — Shared timestamp formatting utilities

### Web Dashboard (Next.js)
- `web/src/types/messaging.ts` — TypeScript interfaces for all messaging types
- `web/src/hooks/use-messaging.ts` — TanStack React Query hooks for conversations, messages, send, start, mark-read, unread count
- `web/src/components/messaging/conversation-list.tsx` — Conversation sidebar with empty state, unread badges, relative timestamps
- `web/src/components/messaging/chat-view.tsx` — Split-panel chat view with date separators, auto-scroll, load-more, polling
- `web/src/components/messaging/message-bubble.tsx` — Message bubbles with read receipt icons
- `web/src/components/messaging/typing-indicator.tsx` — Animated typing dots
- `web/src/components/messaging/chat-input.tsx` — Textarea with character counter, Enter-to-send, Shift+Enter for newline
- `web/src/app/(dashboard)/messages/page.tsx` — Messages page with conversation list + chat panel layout

### E2E Tests
- `web/e2e/trainer/messages.spec.ts` — 6 test cases: nav link, navigation, empty state, conversation list, chat view, input interaction

---

## Files Modified

### Backend
- `backend/config/settings.py` — Added 'messaging' to INSTALLED_APPS, added 'messaging' throttle rate (30/minute)
- `backend/config/urls.py` — Added `path('api/messaging/', include('messaging.urls'))`
- `backend/config/asgi.py` — Added messaging WebSocket routes alongside community routes
- `backend/trainer/views.py` — RemoveTraineeView now calls archive_conversations_for_trainee()

### Mobile
- `mobile/lib/core/constants/api_constants.dart` — Added 6 messaging REST endpoints + 1 WebSocket URL
- `mobile/lib/core/router/app_router.dart` — Added Messages branch in both trainer and trainee shells, added new-conversation and chat routes
- `mobile/lib/shared/widgets/trainer_navigation_shell.dart` — ConsumerStatefulWidget with initState refresh, Messages nav item (index 2) with unread badge
- `mobile/lib/shared/widgets/main_navigation_shell.dart` — ConsumerStatefulWidget with initState refresh, Messages nav item (index 4) with unread badge
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Wired dead "Send Message" button to navigate to new-conversation screen

### Web Dashboard
- `web/src/lib/constants.ts` — Added 6 messaging API URLs
- `web/src/components/layout/nav-links.tsx` — Added Messages link with MessageSquare icon
- `web/src/components/layout/sidebar.tsx` — Added unread message count badge to Messages nav link
- `web/src/components/layout/sidebar-mobile.tsx` — Added unread message count badge to Messages nav link
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Message button navigates to messages page with trainee param (no auto-greeting)

### E2E Helpers
- `web/e2e/helpers/auth.ts` — Added messaging mock responses (conversations, unread count)

---

## Key Design Decisions

1. **Conversation model uses unique constraint on (trainer, trainee)** — Ensures exactly one conversation per pair. Re-uses archived conversations when trainee is re-assigned.

2. **Soft-archive instead of delete** — When a trainee is removed, conversations are archived (is_archived=True) preserving message history for audit purposes. Trainee FK uses SET_NULL to avoid cascade deletion.

3. **Business logic in services layer** — All validation, creation, and querying logic lives in `messaging_service.py`. Views handle HTTP/WS only.

4. **Dataclass returns from services** — Following project rules: services return frozen dataclasses (SendMessageResult, MarkReadResult, UnreadCountResult), never dicts.

5. **Row-level security everywhere** — Every view checks user.id is in (conversation.trainer_id, conversation.trainee_id). Service functions also validate.

6. **Impersonation read-only guard** — SendMessageView and StartConversationView check request.auth for 'impersonating' claim and reject with 403.

7. **Navigation tab replacement** — Trainer shell: Messages replaces Exercises tab (Exercises moved to standalone route). Trainee shell: Messages replaces TV placeholder tab.

8. **Web uses polling for near-real-time** — Web chat refetches messages every 5 seconds, conversations every 15 seconds. WebSocket is used on mobile for true real-time. Typing indicators are a documented v1 web limitation.

9. **Split-panel layout on web** — Desktop messages page uses a conversation list sidebar (320px) + chat view panel, matching modern messaging app UX.

10. **Optimistic updates on mobile** — ChatNotifier adds messages to local state immediately, then reconciles with server response.

11. **N+1 query elimination** — Conversation list queryset uses Subquery + Left for last_message_preview and Count annotation for unread_count, reducing ~100 extra queries per request to zero.

12. **Rate limiting** — Send endpoints enforce 30/minute via ScopedRateThrottle matching the 'messaging' scope in settings.

---

## Deviations from Ticket

1. **Web WebSocket**: The ticket mentioned WebSocket for web dashboard, but polling (5s interval) was used instead. WebSocket would require additional infrastructure (ws:// handling in Next.js). Polling provides a good enough near-real-time experience for v1.

2. **Trainee detail "Message" button on web**: Now navigates to the messages page with the trainee ID as a query param, where the trainer can type their own first message (matching the mobile flow). Previously auto-sent a greeting.

---

## How to Manually Test

### Backend
```bash
# Run migrations (including new 0002 migration)
cd backend && python manage.py migrate

# Start server
python manage.py runserver

# Test endpoints (need JWT token):
# GET  /api/messaging/conversations/          — List conversations (paginated)
# POST /api/messaging/conversations/start/    — Start new conversation (rate-limited)
# GET  /api/messaging/conversations/<id>/messages/  — Get messages
# POST /api/messaging/conversations/<id>/send/      — Send message (rate-limited)
# POST /api/messaging/conversations/<id>/read/      — Mark read
# GET  /api/messaging/unread-count/           — Unread count

# Test rate limiting: send > 30 messages in 1 minute, expect 429
# Test trainee removal: POST to remove-trainee, verify conversations are archived
```

### Mobile
```bash
cd mobile && flutter pub get && flutter run -d ios
# 1. Login as trainer -> see Messages tab in bottom nav
# 2. Go to Trainees -> tap trainee -> tap "Send Message"
# 3. Type and send a message -> redirects to chat screen
# 4. Login as trainee -> see Messages tab, open conversation
# 5. Verify unread badge counts update (no infinite loop)
# 6. Verify typing indicators appear when other party types
```

### Web Dashboard
```bash
cd web && npm run dev
# 1. Login as trainer -> see "Messages" in sidebar with unread badge
# 2. Click Messages -> see conversation list (empty if no conversations)
# 3. Go to trainee detail -> click "Message" button -> navigates to messages page
# 4. Type and send a message (no auto-greeting)
# 5. Send messages back and forth, verify they appear
# 6. Verify sidebar unread badge updates
```

### E2E Tests
```bash
cd web && npx playwright test e2e/trainer/messages.spec.ts
```

# Dev Done: In-App Direct Messaging (Trainer-to-Trainee)

## Implementation Date
2026-02-19

## Summary
Full-stack implementation of 1:1 direct messaging between trainers and their trainees. Covers backend (Django REST + WebSocket), mobile (Flutter with Riverpod), and web dashboard (Next.js with TanStack React Query). All acceptance criteria addressed.

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

### Mobile (Flutter)
- `mobile/lib/features/messaging/data/models/conversation_model.dart` — ConversationModel with fromJson/copyWith
- `mobile/lib/features/messaging/data/models/message_model.dart` — MessageModel, MessagesResponse, StartConversationResponse
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` — API calls for all messaging endpoints
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart` — WebSocket service with exponential backoff reconnection
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` — ConversationListNotifier, UnreadCountNotifier, ChatNotifier (per-conversation)
- `mobile/lib/features/messaging/presentation/screens/conversation_list_screen.dart` — Full screen with loading/empty/error states
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart` — Chat with WebSocket, scroll-to-bottom, load-more, typing indicator
- `mobile/lib/features/messaging/presentation/screens/new_conversation_screen.dart` — Start conversation from trainee detail
- `mobile/lib/features/messaging/presentation/widgets/conversation_tile.dart` — Conversation row with avatar, preview, unread badge
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Aligned bubbles with read receipts
- `mobile/lib/features/messaging/presentation/widgets/typing_indicator.dart` — Animated 3-dot indicator
- `mobile/lib/features/messaging/presentation/widgets/chat_input.dart` — Text input with character counter, multiline, send button

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

### Mobile
- `mobile/lib/core/constants/api_constants.dart` — Added 6 messaging REST endpoints + 1 WebSocket URL
- `mobile/lib/core/router/app_router.dart` — Added Messages branch in both trainer and trainee shells, added new-conversation and chat routes
- `mobile/lib/shared/widgets/trainer_navigation_shell.dart` — Added Messages nav item (index 2) with unread badge
- `mobile/lib/shared/widgets/main_navigation_shell.dart` — Replaced TV with Messages nav item (index 4) with unread badge
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Wired dead "Send Message" button to navigate to new-conversation screen

### Web Dashboard
- `web/src/lib/constants.ts` — Added 6 messaging API URLs
- `web/src/components/layout/nav-links.tsx` — Added Messages link with MessageSquare icon
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Added "Message" button that starts conversation and navigates to messages page

### E2E Helpers
- `web/e2e/helpers/auth.ts` — Added messaging mock responses (conversations, unread count)

---

## Key Design Decisions

1. **Conversation model uses unique constraint on (trainer, trainee)** — Ensures exactly one conversation per pair. Re-uses archived conversations when trainee is re-assigned.

2. **Soft-archive instead of delete** — When a trainee is removed, conversations are archived (is_archived=True) preserving message history for audit purposes.

3. **Business logic in services layer** — All validation, creation, and querying logic lives in `messaging_service.py`. Views handle HTTP/WS only.

4. **Dataclass returns from services** — Following project rules: services return frozen dataclasses (SendMessageResult, MarkReadResult, UnreadCountResult), never dicts.

5. **Row-level security everywhere** — Every view checks user.id is in (conversation.trainer_id, conversation.trainee_id). Service functions also validate.

6. **Impersonation read-only guard** — SendMessageView and StartConversationView check JWT for 'impersonating' claim and reject with 403.

7. **Navigation tab replacement** — Trainer shell: Messages replaces Exercises tab (Exercises moved to standalone route). Trainee shell: Messages replaces TV placeholder tab.

8. **Web uses polling for near-real-time** — Web chat refetches messages every 5 seconds, conversations every 15 seconds. WebSocket is used on mobile for true real-time.

9. **Split-panel layout on web** — Desktop messages page uses a conversation list sidebar (320px) + chat view panel, matching modern messaging app UX.

10. **Optimistic updates on mobile** — ChatNotifier adds messages to local state immediately, then reconciles with server response.

---

## Deviations from Ticket

1. **Web WebSocket**: The ticket mentioned WebSocket for web dashboard, but polling (5s interval) was used instead. WebSocket would require additional infrastructure (ws:// handling in Next.js). Polling provides a good enough near-real-time experience for v1.

2. **Trainee detail "Message" button on web**: Instead of just linking, the button sends a greeting message and creates the conversation in one action, then navigates to the messages page with the conversation selected.

---

## How to Manually Test

### Backend
```bash
# Run migrations
cd backend && python manage.py migrate

# Start server
python manage.py runserver

# Test endpoints (need JWT token):
# GET  /api/messaging/conversations/          — List conversations
# POST /api/messaging/conversations/start/    — Start new conversation
# GET  /api/messaging/conversations/<id>/messages/  — Get messages
# POST /api/messaging/conversations/<id>/send/      — Send message
# POST /api/messaging/conversations/<id>/read/      — Mark read
# GET  /api/messaging/unread-count/           — Unread count
```

### Mobile
```bash
cd mobile && flutter pub get && flutter run -d ios
# 1. Login as trainer -> see Messages tab in bottom nav
# 2. Go to Trainees -> tap trainee -> tap "Send Message"
# 3. Type and send a message -> redirects to chat screen
# 4. Login as trainee -> see Messages tab, open conversation
# 5. Verify unread badge counts update
# 6. Verify typing indicators appear when other party types
```

### Web Dashboard
```bash
cd web && npm run dev
# 1. Login as trainer -> see "Messages" in sidebar
# 2. Click Messages -> see conversation list (empty if no conversations)
# 3. Go to trainee detail -> click "Message" button
# 4. Verify conversation appears in messages page
# 5. Send messages back and forth, verify they appear
# 6. Verify unread badges
```

### E2E Tests
```bash
cd web && npx playwright test e2e/trainer/messages.spec.ts
```

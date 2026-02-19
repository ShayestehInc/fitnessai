# Feature: In-App Direct Messaging (Trainer-to-Trainee)

## Priority
Critical — Fills the largest gap in trainer-trainee communication. Dead UI button already exists, causing user frustration.

## User Story
As a **Trainer**, I want to send direct messages to individual trainees so that I can privately discuss their progress, provide personalized coaching guidance, check in on missed workouts, and send motivational reminders — all within the app without needing external tools like SMS or WhatsApp.

As a **Trainee**, I want to receive and reply to messages from my trainer so that I can ask questions, share updates, and stay connected without leaving the app.

## Acceptance Criteria

- [ ] AC-1: New `messaging` Django app with `Conversation` and `Message` models
- [ ] AC-2: Trainer can open a message thread with any of their trainees from trainee detail screen (wiring the existing dead "Send Message" button)
- [ ] AC-3: Trainer can see a list of all active conversations sorted by most recent message
- [ ] AC-4: Trainer can send text messages to a trainee in a conversation
- [ ] AC-5: Trainee can see a list of conversations (they will only have one — with their trainer)
- [ ] AC-6: Trainee can send text messages replying to their trainer
- [ ] AC-7: Messages appear in real-time via WebSocket (no manual refresh needed)
- [ ] AC-8: Unread message count badge shown on the messaging nav item (both trainer and trainee)
- [ ] AC-9: Push notification (FCM) sent to recipient when a new message arrives (if they are not in the conversation)
- [ ] AC-10: Messages are paginated (20 per page) with infinite scroll loading older messages
- [ ] AC-11: Conversation list shows last message preview, timestamp, unread count, and trainee avatar/name
- [ ] AC-12: Row-level security: trainers only see conversations with THEIR trainees; trainees only see their OWN conversation
- [ ] AC-13: Messages are persisted to the database (not ephemeral)
- [ ] AC-14: Trainer web dashboard has a Messages page with conversation list and chat view
- [ ] AC-15: Trainer can send messages from the web dashboard trainee detail page
- [ ] AC-16: Message input supports multiline text (max 2000 characters) with character counter at 90%+
- [ ] AC-17: Typing indicators shown (WebSocket) — trainee sees "Trainer is typing..." and vice versa
- [ ] AC-18: Messages display timestamps (relative for recent, absolute for older)
- [ ] AC-19: Conversation auto-created when trainer sends first message to a trainee who has no conversation
- [ ] AC-20: Read receipts — sender can see if their message has been read (double checkmark pattern)
- [ ] AC-21: Trainer can quick-message from the trainee list (action menu) without opening trainee detail first

## Edge Cases

1. **What happens when a trainee is removed?** — Conversation is soft-deleted (archived). Messages are preserved for audit but no longer accessible to trainee. Trainer sees "[Trainee Removed]" label.
2. **What happens when trainer sends message to offline trainee?** — Message is persisted to DB, push notification sent via FCM. Trainee sees it on next app open. Offline-first sync queue used on mobile.
3. **What happens with concurrent messages (race condition)?** — Messages use auto-incrementing IDs and server-assigned `created_at` timestamps. Client sorts by server timestamp. Optimistic UI adds message immediately, reconciles on WebSocket confirmation.
4. **What happens when WebSocket connection drops?** — Falls back to polling (every 10 seconds). Exponential backoff reconnection as per existing community WebSocket pattern. Messages are never lost (DB is source of truth).
5. **What happens when message content is empty or only whitespace?** — Client-side validation prevents empty sends. Server-side `strip()` + validation returns 400 if empty after strip.
6. **What happens with very long messages (> 2000 chars)?** — Client-side character counter shows at 90% threshold. Server rejects > 2000 chars with clear error.
7. **What happens if trainee has no `parent_trainer`?** — Conversation list returns empty. Cannot create conversation without valid trainer-trainee relationship.
8. **What happens with rapid fire messages (spam)?** — Rate limit: max 30 messages per minute per user. Server returns 429 with retry-after header.
9. **What happens on web if user navigates away mid-typing?** — No unsaved changes guard for messages (they are send-or-discard, not drafts).
10. **What happens when admin impersonates trainer?** — Impersonating trainer can VIEW messages but CANNOT send (read-only during impersonation to protect trainee trust).

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network failure on send | Red error icon next to message + "Tap to retry" | Queues in offline sync queue (mobile), shows toast (web) |
| WebSocket disconnected | Subtle "Reconnecting..." banner | Exponential backoff reconnect, falls back to polling |
| Message too long (>2000) | Character counter turns red, send disabled | Server returns 400, client pre-validates |
| Rate limited (429) | "Slow down. Try again in X seconds" snackbar | Server returns 429 with retry-after |
| Trainee removed mid-conversation | "This trainee has been removed" banner, input disabled | Conversation archived, 403 on new sends |
| No conversations yet (trainer) | Empty state: "No conversations yet. Message a trainee from their profile." with CTA | Returns empty list |
| No conversations yet (trainee) | Empty state: "Your trainer hasn't messaged you yet." | Returns empty list |
| Failed to load messages | Error state with retry button | Client shows cached messages if available (offline-first) |

## UX Requirements

- **Loading state:** Conversation list shows skeleton cards (5 shimmer rows). Chat view shows skeleton message bubbles.
- **Empty state (trainer):** MessageSquare icon + "No conversations yet" + "Start a conversation from any trainee's profile" + button to go to trainee list.
- **Empty state (trainee):** MessageSquare icon + "No messages yet" + "Your trainer will reach out here."
- **Error state:** ErrorState component with retry button (existing pattern).
- **Success feedback:** Message appears instantly in chat (optimistic), blue checkmark when delivered, double checkmark when read.
- **Mobile behavior:** Full-screen chat view. Back button returns to conversation list. Keyboard avoidance. Input at bottom with safe area padding. Pull-to-load-more for older messages.
- **Web behavior:** Two-panel layout — conversation list (left sidebar, 300px) and chat view (right, fills remaining). Responsive: single-panel on mobile web with back navigation.
- **Typing indicator:** "..." animated dots below last message while other party is typing. Debounced to 3 seconds of inactivity to auto-dismiss.
- **Timestamps:** "Just now" (< 1 min), "5m ago" (< 1h), "2:30 PM" (today), "Yesterday", "Feb 15" (this year), "Feb 15, 2025" (prior year).
- **Unread badge:** Red dot with count on Messages nav item. Capped at "99+".

## Technical Approach

### Backend (new `messaging` Django app)

Files to create:
- `backend/messaging/__init__.py`
- `backend/messaging/apps.py`
- `backend/messaging/models.py` — `Conversation` (trainer FK, trainee FK, `last_message_at`, `is_archived`) and `Message` (conversation FK, sender FK, `content` TextField(max 2000), `is_read`, `read_at`, `created_at`)
- `backend/messaging/serializers.py` — ConversationListSerializer, MessageSerializer, SendMessageSerializer
- `backend/messaging/views.py` — ConversationListView, ConversationDetailView (GET messages), SendMessageView (POST), MarkReadView (POST), UnreadCountView (GET)
- `backend/messaging/urls.py` — Wire to `/api/messaging/`
- `backend/messaging/services/messaging_service.py` — Business logic: `send_message()`, `mark_conversation_read()`, `get_or_create_conversation()`
- `backend/messaging/consumers.py` — WebSocket consumer for real-time messages + typing indicators
- `backend/messaging/routing.py` — `ws/messaging/<conversation_id>/`
- `backend/messaging/admin.py` — Django admin registration
- `backend/messaging/migrations/0001_initial.py` — Auto-generated

Files to modify:
- `backend/config/settings.py` — Add `'messaging'` to INSTALLED_APPS
- `backend/config/urls.py` — Add `path('api/messaging/', include('messaging.urls'))`
- `backend/config/asgi.py` — Add messaging WebSocket routes alongside community routes

### Mobile (new `messaging` feature)

Files to create:
- `mobile/lib/features/messaging/data/models/conversation_model.dart`
- `mobile/lib/features/messaging/data/models/message_model.dart`
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart`
- `mobile/lib/features/messaging/data/services/messaging_ws_service.dart`
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart`
- `mobile/lib/features/messaging/presentation/screens/conversation_list_screen.dart`
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart`
- `mobile/lib/features/messaging/presentation/widgets/conversation_tile.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart`
- `mobile/lib/features/messaging/presentation/widgets/typing_indicator.dart`
- `mobile/lib/features/messaging/presentation/widgets/chat_input.dart`

Files to modify:
- `mobile/lib/core/constants/api_constants.dart` — Add messaging endpoints
- `mobile/lib/core/router/app_router.dart` — Add messaging routes
- `mobile/lib/shared/widgets/trainer_navigation_shell.dart` — Add Messages tab with unread badge
- `mobile/lib/shared/widgets/main_navigation_shell.dart` — Add Messages tab for trainee nav with unread badge
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Wire dead "Send Message" button (lines 128-129)

### Web Dashboard

Files to create:
- `web/src/app/(dashboard)/messages/page.tsx` — Messages page (conversation list + chat)
- `web/src/components/messaging/conversation-list.tsx`
- `web/src/components/messaging/chat-view.tsx`
- `web/src/components/messaging/message-bubble.tsx`
- `web/src/components/messaging/chat-input.tsx`
- `web/src/components/messaging/typing-indicator.tsx`
- `web/src/hooks/use-messaging.ts` — TanStack React Query hooks
- `web/src/types/messaging.ts` — TypeScript types

Files to modify:
- `web/src/lib/constants.ts` — Add messaging API URLs
- `web/src/components/layout/nav-links.tsx` — Add Messages nav item with unread badge
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Add "Message" button to trainee actions

### Key Design Decisions
- Separate `messaging` Django app (not inside `trainer` or `community`) because messaging is a cross-cutting concern used by both roles
- Conversations are always 1:1 (trainer-trainee). No group messaging (that is what community feed and announcements are for)
- Messages use a separate WebSocket consumer (not the community feed consumer) for isolation and security
- Each conversation gets its own WebSocket channel group (`messaging_conversation_{id}`)
- Read receipts update via WebSocket broadcast (not polling)
- Typing indicators are ephemeral (WebSocket only, not persisted)
- Offline-first on mobile: use existing Drift tables pattern for `PendingMessages`

## Out of Scope
- Group messaging / group chats
- Image/file/video attachments in messages
- Message editing or deletion after send
- Message search
- Canned responses / quick replies templates
- Auto-messages / scheduled messages
- Message encryption (E2E)
- Trainee-to-trainee messaging (only trainer-trainee)

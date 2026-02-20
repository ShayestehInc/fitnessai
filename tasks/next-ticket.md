# Feature: WebSocket Real-Time Messaging for Web Dashboard

## Priority
High

## User Story
As a **trainer using the web dashboard**, I want my **messages to arrive instantly** instead of with a 5-second polling delay, so that conversations feel natural and responsive — just like they do on mobile.

As a **trainer**, I want to **see when the other person is typing** so I know they're about to respond, reducing the urge to send follow-up messages.

## Acceptance Criteria

### WebSocket Connection Lifecycle
- [ ] AC-1: A new `useMessagingWebSocket` hook manages WebSocket connection per conversation. Connects on mount, disconnects on unmount or conversation change.
- [ ] AC-2: WebSocket URL follows existing pattern: `ws(s)://<host>/ws/messaging/<conversationId>/?token=<JWT>`. Protocol auto-detects from page location (ws:// for http, wss:// for https).
- [ ] AC-3: Connection authenticates using the current JWT access token from `getAccessToken()`.
- [ ] AC-4: If the access token is expired, refresh it before connecting (use existing `refreshAccessToken()`).
- [ ] AC-5: Exponential backoff reconnection on disconnect: 1s, 2s, 4s, 8s, 16s cap. Max 5 attempts before giving up and falling back to polling.
- [ ] AC-6: Reconnects immediately when browser tab regains focus (via `visibilitychange` event), resetting the backoff counter.
- [ ] AC-7: Sends `ping` heartbeat every 30 seconds. If no `pong` received within 5 seconds, close and reconnect.
- [ ] AC-8: Hook exposes connection state: `connecting`, `connected`, `disconnected`, `failed` (exhausted retries).
- [ ] AC-9: On `failed` state, falls back to existing HTTP polling (5s messages, 15s conversations, 30s unread count).
- [ ] AC-10: Properly cleans up WebSocket on component unmount — no leaked connections or event listeners.

### Real-Time Message Delivery
- [ ] AC-11: When a `new_message` event arrives via WebSocket, the message is appended to the chat view immediately without a full page refetch.
- [ ] AC-12: New messages from WebSocket are deduplicated against existing messages (by message ID) to prevent duplicates when both WS and send response return the same message.
- [ ] AC-13: When WebSocket is connected, the 5-second message polling interval is disabled. Polling resumes only on fallback.
- [ ] AC-14: Auto-scroll to bottom when a new message arrives via WebSocket (if user was already near the bottom). Don't force-scroll if user has scrolled up to read history.
- [ ] AC-15: New messages from WebSocket update the conversation list's `last_message_preview` and `last_message_at` without requiring a full conversation list refetch.

### Typing Indicators
- [ ] AC-16: When the user types in the chat input, send a `{ type: "typing", is_typing: true }` message via WebSocket.
- [ ] AC-17: Typing signals are debounced: send `is_typing: true` at most once every 3 seconds while actively typing.
- [ ] AC-18: Send `is_typing: false` when the user stops typing for 3 seconds (idle timeout).
- [ ] AC-19: Send `is_typing: false` immediately when a message is sent.
- [ ] AC-20: When a `typing_indicator` event arrives (from the other party), display the existing `TypingIndicator` component showing "{name} is typing..." with the animated dots.
- [ ] AC-21: Typing indicator auto-hides after 4 seconds of no typing updates from the other party (safety timeout).
- [ ] AC-22: Typing indicator appears between the last message and the chat input area.
- [ ] AC-23: When typing indicator appears/disappears, auto-scroll if user is near the bottom (same logic as new messages).

### Read Receipts
- [ ] AC-24: When a `read_receipt` event arrives via WebSocket, update the relevant messages' `is_read` status to `true` immediately — existing double-checkmark UI updates in real-time.
- [ ] AC-25: Read receipts via WebSocket replace the need to refetch message data for read status changes.

### Conversation List Real-Time Updates
- [ ] AC-26: When WebSocket is connected, conversation list polling interval increases from 15s to 60s (light refresh for conversation metadata not covered by WS events).
- [ ] AC-27: Unread count polling increases from 30s to 60s when WebSocket is connected.
- [ ] AC-28: When the user receives a new message via WebSocket for the currently selected conversation AND the chat is visible, automatically mark it as read (send markRead API call).

### Connection State UI
- [ ] AC-29: No visible connection indicator when WebSocket is connected (default state — should be invisible).
- [ ] AC-30: When WebSocket is disconnected and reconnecting, show a small subtle banner at the top of the chat area: "Reconnecting..." with a subtle loading spinner. Auto-hides when reconnected.
- [ ] AC-31: When WebSocket has failed (exhausted retries), show a small banner: "Real-time updates unavailable. Messages may be delayed." with no action button (polling is automatic fallback).

## Edge Cases
1. **Token expires during WebSocket session** — WebSocket closes with 4001 code. Hook detects this, refreshes the token, and reconnects. If refresh fails, fall back to polling.
2. **User switches conversation rapidly** — Previous WebSocket must be cleanly closed before opening new one. Use cleanup function in useEffect. No race conditions.
3. **Browser goes to sleep/background** — WebSocket likely closes. On `visibilitychange` when tab becomes visible, immediately attempt reconnect.
4. **Server restarts (Redis channel layer reset)** — WebSocket closes unexpectedly. Backoff reconnection handles this automatically.
5. **Multiple browser tabs open on same conversation** — Each tab gets its own WebSocket connection. No cross-tab coordination needed (each connection is independent).
6. **Concurrent send + WebSocket receive** — User sends a message (HTTP POST) and WebSocket delivers the same message. Dedup by message ID prevents duplicate display.
7. **Network flap (brief disconnection)** — Reconnect with backoff. On reconnect, do a single message refetch to catch any messages missed during the gap.
8. **User scrolled up reading history, new message arrives** — Don't force-scroll. Show "New messages" indicator or scroll-down FAB (existing button).
9. **Image message arrives via WebSocket** — Image URL is included in message payload. MessageBubble renders it normally (already supports images from Pipeline 21).
10. **Typing indicator from archived conversation** — Backend consumer already rejects connections to archived conversations (code 4003), so this can't happen.
11. **WebSocket message arrives with unknown type** — Silently ignore. Log a debug warning.
12. **Connection drops right after sending typing: true** — Other party's typing indicator will timeout after 4 seconds (AC-21 safety timeout).

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| WebSocket connection refused (server down) | "Reconnecting..." banner, then polling fallback | Exponential backoff x5, then fall back to HTTP polling |
| JWT token expired during WS session | Nothing visible (transparent reconnect) | Refreshes token, reconnects. If refresh fails, falls back to polling |
| WebSocket auth rejected (4001) | Nothing visible | Attempts token refresh + reconnect. If still fails, falls back to polling |
| Access denied to conversation (4003) | Nothing visible | Falls back to polling for this conversation |
| Malformed WebSocket message | Nothing visible | Silently ignores, logs warning to console in dev |
| Browser doesn't support WebSocket | Nothing visible | Falls back to HTTP polling (WebSocket is supported in all modern browsers, but guard anyway) |
| Network offline | "Reconnecting..." banner | Reconnect attempts when network returns |

## UX Requirements
- **Connection state:** Invisible when connected. Subtle "Reconnecting..." banner when disconnected. "Updates may be delayed" when failed.
- **Typing indicator:** Displayed between the message list and chat input. Uses existing `TypingIndicator` component with animated bouncing dots and "{Name} is typing..." text. `aria-live="polite"` for accessibility.
- **Message arrival:** Smooth append animation (no flash/jump). Auto-scroll if near bottom.
- **Loading state:** No change to initial page load (still fetches via HTTP on mount).
- **Empty state:** No change.
- **Error state:** Graceful degradation to polling — user should barely notice.
- **Success feedback:** Messages appear instantly instead of with 5-second delay.
- **Mobile behavior:** Same responsive layout as before — WebSocket works on all screen sizes.

## Technical Approach

### New Files
- `web/src/hooks/use-messaging-ws.ts` — Core WebSocket hook
  - Manages connection lifecycle (connect, disconnect, reconnect with backoff)
  - Parses incoming events (new_message, typing_indicator, read_receipt, pong)
  - Exposes: `connectionState`, `sendTyping()`, `lastMessage` (for consumers)
  - Uses `useRef` for WebSocket instance (avoids re-render on internal state changes)
  - Uses `useEffect` for lifecycle + cleanup
  - Integrates with token-manager for JWT

### Files to Modify
- `web/src/lib/constants.ts` — Add `WS_BASE` URL and `wsMessaging(conversationId: number)` builder function
- `web/src/hooks/use-messaging.ts` — Add parameter to control polling interval (disable when WS is connected), add helpers to update React Query cache from WS events
- `web/src/components/messaging/chat-view.tsx` — Integrate `useMessagingWebSocket`, remove hardcoded 5s polling, add typing indicator display, add connection state banner, handle new_message events
- `web/src/components/messaging/chat-input.tsx` — Accept `onTyping` callback prop, fire it on input change (debounced), fire stop-typing on send
- `web/src/components/messaging/conversation-list.tsx` — No direct changes needed (conversation data flows from React Query)
- `web/src/app/(dashboard)/messages/page.tsx` — Pass through any needed context

### WebSocket Protocol (Backend Already Supports)
```
Client → Server:
  { "type": "ping" }
  { "type": "typing", "is_typing": true/false }

Server → Client:
  { "type": "pong" }
  { "type": "new_message", "message": { id, conversation_id, sender, content, image, is_read, read_at, created_at } }
  { "type": "typing_indicator", "user_id": number, "is_typing": boolean }
  { "type": "read_receipt", "reader_id": number, "read_at": "ISO timestamp" }
```

### Key Design Decisions
1. **One WebSocket per conversation** — Matches the backend consumer model (one group per conversation). Connect/disconnect as user switches conversations.
2. **React Query cache as single source of truth** — WebSocket events mutate the React Query cache directly (via `queryClient.setQueryData`). No separate message store.
3. **Graceful degradation** — WebSocket is an enhancement. If it fails, polling kicks in. User experience degrades gracefully, never breaks.
4. **No reconnection on purposeful close** — When user navigates away or switches conversation, close cleanly (code 1000). Only reconnect on unexpected closes.
5. **Debounced typing** — 3-second debounce matches backend consumer's expectation. Prevents spamming WS with every keystroke.

### Dependencies
- No new packages needed. Native `WebSocket` API is available in all modern browsers. Token management uses existing `token-manager.ts`.

## Out of Scope
- Backend changes (consumer is complete and tested)
- Mobile changes (already uses WebSocket)
- WebSocket for community feed on web
- Cross-tab message synchronization
- Push notifications for web (separate feature)
- Online/offline status indicators for users
- Message delivery confirmation ("delivered" vs "sent")

# Dev Done: WebSocket Real-Time Messaging for Web Dashboard (Pipeline 22)

## Implementation Date
2026-02-19

## Summary
Replaced HTTP polling with WebSocket real-time delivery on the web dashboard messaging page. Enabled typing indicators and instant read receipts, completing feature parity with mobile. Graceful fallback to HTTP polling when WebSocket connection fails.

## Files Changed

### Web (Next.js)
| File | Change |
|------|--------|
| `web/src/lib/constants.ts` | Added `WS_BASE` URL derivation (ws/wss from API base) and `wsMessaging(conversationId)` URL builder |
| `web/src/hooks/use-messaging-ws.ts` | **NEW** Core WebSocket hook — connection lifecycle, exponential backoff reconnection (1s-16s, 5 attempts), heartbeat (30s ping, 5s pong timeout), event parsing (new_message, typing_indicator, read_receipt), React Query cache mutation, typing debounce (3s), tab visibility reconnect |
| `web/src/hooks/use-messaging.ts` | Added configurable `refetchIntervalMs` parameter to `useConversations()` and `useMessagingUnreadCount()` for dynamic polling control |
| `web/src/components/messaging/chat-view.tsx` | Integrated `useMessagingWebSocket` — disables 5s polling when WS connected, displays typing indicator, shows connection state banner (reconnecting/failed), handles new messages via WS with dedup and auto-scroll, auto-marks-read on incoming messages, refetches on reconnect to catch missed messages |
| `web/src/components/messaging/chat-input.tsx` | Added `onTyping` callback prop, fires on input change (debounced in WS hook) and stop-typing on send. Fixed pre-existing bug: replaced broken `@/hooks/use-toast` import with `sonner` toast |
| `web/src/components/messaging/typing-indicator.tsx` | No changes — already built and ready. Now wired into chat-view.tsx |

### No Backend Changes
The Django `DirectMessageConsumer` already supports all needed WebSocket events (new_message, typing, read_receipt, ping/pong, JWT auth). No backend modifications required.

### No Mobile Changes
Flutter mobile already uses WebSocket for real-time messaging.

## Key Decisions
1. **One WebSocket per conversation** — Matches backend consumer model. Connect/disconnect as user switches conversations.
2. **React Query cache as single source of truth** — WebSocket events mutate the React Query cache directly via `queryClient.setQueryData`. No separate message store.
3. **Graceful degradation** — If WebSocket fails after 5 reconnect attempts, falls back to existing 5s HTTP polling. User sees subtle "Updates may be delayed" banner.
4. **Debounced typing** — 3s debounce matches backend consumer expectation. Auto-sends `is_typing: false` after 3s idle. Stops typing on send.
5. **Reconnect on tab focus** — Uses `visibilitychange` event to immediately reconnect when browser tab regains focus, resetting backoff counter.
6. **Dedup strategy** — New messages from WS are deduped against existing messages by ID (handles concurrent WS delivery + HTTP send response).
7. **Refetch on reconnect** — When WS reconnects after a gap, does a single HTTP refetch to catch messages missed during disconnection.

## Bug Fix
- **Pre-existing**: `chat-input.tsx` imported `useToast` from `@/hooks/use-toast` which doesn't exist. The project uses `sonner` for toasts. Fixed by replacing with `import { toast } from "sonner"` and `toast.error(...)` calls.

## Test Results
- Django: 35 messaging tests pass
- TypeScript: 0 new errors (all errors in `tsc --noEmit` are pre-existing in ambassador/trainee files)
- No regressions

## How to Test
1. **WebSocket connection**: Open messages page → open browser DevTools Network tab → filter WS → verify WebSocket connection to `ws://localhost:8000/ws/messaging/{id}/?token=...`
2. **Real-time messages**: Open two browser windows (trainer + trainee, or two different users on same conversation) → send message from one → appears instantly in other
3. **Typing indicators**: Start typing in one window → other window shows "{Name} is typing..." with animated dots → stop typing for 3s → indicator disappears
4. **Read receipts**: Send message → other party views the conversation → sender's message shows double checkmark (read) in real-time
5. **Reconnection**: In DevTools, close the WS connection manually → "Reconnecting..." banner appears → WS reconnects → banner disappears
6. **Fallback**: Block WebSocket connections (e.g., browser extension) → "Updates may be delayed" banner → messages still arrive via HTTP polling (5s)
7. **Tab visibility**: Switch to another tab → wait → switch back → WS reconnects immediately
8. **Heartbeat**: Keep connection open for >30 seconds → verify ping/pong in WS frames in DevTools

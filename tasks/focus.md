# Pipeline 22 Focus: WebSocket Real-Time Messaging for Web Dashboard

## Priority
Replace HTTP polling with WebSocket real-time delivery on the web dashboard messaging page. Enable typing indicators and instant read receipts — completing feature parity with mobile.

## Why This Feature
1. **Backend is fully built** — DirectMessageConsumer in `messaging/consumers.py` supports JWT auth, new_message, typing, read receipts, and heartbeat. Mobile already uses it.
2. **Web typing indicator component already exists** — `typing-indicator.tsx` is built and waiting, commented out in `chat-view.tsx` with a clear note saying "for use when web WebSocket support is added."
3. **Polling is inefficient and laggy** — 5s message polling + 15s conversation polling + 30s unread count polling creates noticeable delay and wastes bandwidth.
4. **Natural progression from Pipelines 20-21** — Messaging was shipped in P20, image attachments in P21. Real-time delivery completes the messaging experience.
5. **Highest value-to-effort ratio** — Zero backend changes needed. Pure web frontend work with clear reference implementation (mobile WebSocket service).

## Scope
- Web only — backend (DirectMessageConsumer) and mobile (messaging_ws_service.dart) are already complete
- New: `use-messaging-ws.ts` hook for WebSocket connection lifecycle
- Modify: `chat-view.tsx` (replace polling with WS), `chat-input.tsx` (send typing), `use-messaging.ts` (WS-driven cache updates), `constants.ts` (WS URL), `conversation-list.tsx` (real-time unread updates)
- Wire up: existing `typing-indicator.tsx`
- Graceful fallback: if WebSocket fails, fall back to existing HTTP polling

## What NOT to build
- Backend changes (consumer is complete)
- Mobile changes (already uses WebSocket)
- New Django Channels consumer or routing
- WebSocket for community feed on web (separate feature)
- Message editing/deletion (future pipeline)

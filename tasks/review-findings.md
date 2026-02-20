# Code Review: WebSocket Real-Time Messaging for Web Dashboard (Pipeline 22)

## Review Date: 2026-02-19
## Round: 1

## Files Reviewed
- `web/src/lib/constants.ts` (WS_BASE + wsMessaging URL builder)
- `web/src/hooks/use-messaging-ws.ts` (NEW — core WebSocket hook)
- `web/src/hooks/use-messaging.ts` (configurable polling interval)
- `web/src/components/messaging/chat-view.tsx` (WS integration, typing, connection banner)
- `web/src/components/messaging/chat-input.tsx` (onTyping prop, sonner fix)

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `use-messaging-ws.ts:206-372` | **Race condition: component unmount during async `connect()`**. If the component unmounts while `connect()` is awaiting `refreshAccessToken()`, the cleanup runs (sets intentionalClose=true, closes WS) but `connect()` resumes and creates a NEW WebSocket — leaked connection. | Add a `cancelledRef` checked after each async gap. Set `cancelledRef.current = true` in the cleanup function. After `refreshAccessToken()`, check `if (cancelledRef.current) return`. |
| C2 | `chat-view.tsx:288-289` | **Typing indicator inside scroll area**. Placed inside `overflow-y-auto` div — invisible when user scrolls up to read history. | Move typing indicator OUTSIDE the scroll area, between the message list div and `<ChatInput>`. |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `chat-view.tsx:42-63,78` | **`markRead` referenced before declaration** in `onNewMessage` closure. `useMessagingWebSocket` is on line 42, but `markRead` is declared on line 78. Works at runtime (closure + async execution) but confusing. | Move `useMarkConversationRead` above `useMessagingWebSocket`. |
| M2 | `chat-view.tsx:24-25` | **`POLLING_DISABLED = false as const` is confusing**. Variable named "DISABLED" has value `false`. Used in `if (!pollInterval)` where falsy works, but confusing to read. | Rename to `const POLLING_OFF = 0` or just use `0` inline. |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `use-messaging-ws.ts:192-193` | Read receipts mark ALL unread messages as read, not just current user's sent messages. Harmless (UI guards via `isOwnMessage`) but semantically wrong. | Accept — harmless with current UI. |
| m2 | `chat-input.tsx:113` | `onTyping?.(true)` fires on every keystroke. Debounce in WS hook handles rate limiting but minor overhead per keystroke. | Accept — overhead negligible. |

## Security Concerns
None — JWT in URL param is standard for WS. Token encoded. Auth failure handled.

## Performance Concerns
None — polling correctly disabled when WS connected. Cache mutations avoid extra refetches.

## Quality Score: 7/10
## Recommendation: REQUEST CHANGES

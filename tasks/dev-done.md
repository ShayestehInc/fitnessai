# Dev Done: Message Search (Pipeline 24)

## Date
2026-02-20

## Files Changed

### Backend (New)
- `backend/messaging/services/search_service.py` — New service with `search_messages()` function, `SearchMessageItem` and `SearchMessagesResult` frozen dataclasses, pagination via Django Paginator, row-level security via conversation ownership filter

### Backend (Modified)
- `backend/messaging/serializers.py` — Added `SearchMessageResultSerializer`
- `backend/messaging/views.py` — Added `SearchMessagesView` (GET /api/messaging/search/) with query validation, pagination, rate limiting
- `backend/messaging/urls.py` — Added `search/` URL pattern

### Web (New)
- `web/src/components/messaging/message-search.tsx` — Main search UI component with debounced input, search results list, pagination, empty/error/loading states, Esc key handling
- `web/src/components/messaging/search-result-item.tsx` — Individual search result card with avatar, highlighted snippet, sender name, timestamp
- `web/src/lib/highlight-text.tsx` — `highlightText()` and `truncateAroundMatch()` utilities for text highlighting and context-aware truncation

### Web (Modified)
- `web/src/app/(dashboard)/messages/page.tsx` — Added search button with Cmd/Ctrl+K shortcut hint, search open state, sidebar toggle between search and conversation list, search result click-to-navigate
- `web/src/hooks/use-messaging.ts` — Added `useSearchMessages()` React Query hook
- `web/src/lib/constants.ts` — Added `MESSAGING_SEARCH` API URL constant
- `web/src/types/messaging.ts` — Added `SearchMessageResult` and `SearchMessagesResponse` types

## Key Decisions
1. Used `icontains` for search (not PostgreSQL full-text search) — matches existing codebase patterns, sufficient for current scale
2. Global search across ALL conversations (not per-conversation) — higher user value
3. Search replaces conversation list in sidebar when active — clean UX, easy to dismiss
4. Cmd/Ctrl+K keyboard shortcut — standard search pattern (Slack, Linear, etc.)
5. 300ms debounce with 2-char minimum — matches trainee search pattern
6. Used Django's Paginator (not DRF PageNumberPagination) in service layer for cleaner separation
7. Excluded archived conversations and deleted messages from search results
8. No new database indexes needed — icontains uses sequential scan anyway

## Deviations from Ticket
- AC-15 (scroll to specific message) — Simplified to navigate to the conversation. Full scroll-to-message would require passing message ID through to ChatView and implementing scroll logic, which adds significant complexity. The user can find the message in the conversation context after navigation.

## How to Test
1. Login as demo.trainer@fitnessai.com (TestPass123)
2. Navigate to Messages page
3. Click the "Search" button in the header (or press Cmd/Ctrl+K)
4. Type a search query (at least 2 characters)
5. Results appear with highlighted matching text
6. Click a result to navigate to that conversation
7. Press Esc to close search
8. Test edge cases: empty query, single char, no results, special characters
9. Test API directly: `GET /api/messaging/search/?q=testing` with auth header

# Feature: Message Search

## Priority
High

## User Story
As a **trainer**, I want to **search across all my conversations** for specific messages so that I can **quickly find past instructions, nutrition notes, or scheduling discussions** without manually scrolling through individual conversation histories.

## Acceptance Criteria

### Backend
- [ ] AC-1: New endpoint `GET /api/messaging/search/?q=<query>` returns paginated messages matching the search query across ALL conversations the authenticated user participates in
- [ ] AC-2: Search is case-insensitive substring match on `message.content` field (using ORM `icontains`)
- [ ] AC-3: Soft-deleted messages (`is_deleted=True`) are excluded from search results
- [ ] AC-4: Results are paginated (20 per page) and ordered by most recent first (`-created_at`)
- [ ] AC-5: Each result includes full message data PLUS conversation context: the other participant's name and ID, and the conversation ID
- [ ] AC-6: Row-level security: only messages in conversations where the authenticated user is a participant (trainer or trainee) are searchable
- [ ] AC-7: Empty query string `q=` or missing `q` returns 400 Bad Request with error message
- [ ] AC-8: Query must be at least 2 characters, otherwise returns 400 with "Search query must be at least 2 characters"
- [ ] AC-9: Rate limiting applied (same `messaging` throttle scope, 30/min)
- [ ] AC-10: Impersonation guard — impersonating users can search (read-only operation, no data modification)
- [ ] AC-11: Service layer function `search_messages()` returns typed dataclass results (not raw dicts)

### Web Dashboard
- [ ] AC-12: Search icon/button in the messages page header area that opens a search interface
- [ ] AC-13: Search input with 300ms debounce (matches trainee search pattern), minimum 2 characters before firing
- [ ] AC-14: Search results displayed as a list showing: message content snippet (with matched text highlighted in bold), sender name, conversation participant name, relative timestamp, conversation context
- [ ] AC-15: Each search result is clickable — navigates to that conversation and scrolls to / highlights the matched message
- [ ] AC-16: Empty state when no results: "No messages match your search" with search icon
- [ ] AC-17: Loading state: skeleton placeholders while search is in progress
- [ ] AC-18: Error state: "Search failed. Please try again." with retry button
- [ ] AC-19: Search results pagination — "Load more" button or infinite scroll for additional pages
- [ ] AC-20: When search is active, the search results replace the conversation list in the left sidebar
- [ ] AC-21: Clear/close search button that dismisses results and returns to conversation list view
- [ ] AC-22: Keyboard shortcut: Cmd/Ctrl+K opens search (standard search shortcut)
- [ ] AC-23: Search input auto-focuses when opened
- [ ] AC-24: Esc key closes search and returns to conversation list
- [ ] AC-25: React Query hook `useSearchMessages(query)` with proper cache key including search term

## Edge Cases
1. **Empty conversations** — User with no conversations searches: should return empty results, not error
2. **Archived conversations** — Messages in archived conversations (trainee removed) should NOT appear in search results (conversation.is_archived = True filter)
3. **Very long messages** — Search result snippet should truncate to ~150 chars around the matched portion, with "..." ellipsis
4. **Special characters in query** — Quotes, ampersands, unicode emoji, HTML entities should not break the search
5. **Concurrent message edit/delete** — If a message is edited or deleted after search results load, the result may show stale data. This is acceptable — clicking through shows the current state.
6. **Image-only messages** — Messages with empty content but an image should not appear in text search results (they have no text to match)
7. **Multiple matches in same conversation** — Each matching message should appear as its own result, even if many matches are in the same conversation
8. **Query with only whitespace** — Should be treated as empty query -> 400 error
9. **Rapid typing** — Debounce prevents excessive API calls. Results for stale queries should be discarded (React Query handles this via cache key changes)
10. **Trainee also uses search** — Both trainers and trainees can search their own conversations. Row-level security ensures they only see their messages.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network error during search | "Search failed. Please try again." + retry button | Toast error, ErrorState component |
| Query too short (<2 chars) | Input hint: "Type at least 2 characters to search" | No API call fired |
| No results | "No messages match your search" + search icon | EmptyState component |
| Rate limited (429) | "Too many searches. Please wait a moment." | Toast error |

## UX Requirements
- **Default state:** Messages page shows normal conversation list. Search button/icon in header.
- **Search open state:** Search input appears at top of sidebar, replaces conversation list with search results
- **Loading state:** Skeleton cards in sidebar (3-4 skeleton items)
- **Results state:** List of message cards with sender avatar, message snippet (highlighted match), conversation name, relative time
- **Empty state:** EmptyState component with Search icon, "No messages match your search", muted description
- **Error state:** ErrorState component with retry
- **Mobile behavior:** On small screens, search results take full width (same responsive pattern as conversation list)
- **Keyboard:** Cmd/Ctrl+K opens search, Esc closes, Enter (or just debounce) triggers search
- **Dark mode:** All new components support dark mode via existing CSS variables

## Technical Approach

### Backend

**New file: `backend/messaging/services/search_service.py`**
- `search_messages(user: User, query: str, page: int = 1) -> SearchMessagesResult`
- Returns frozen dataclass with `results: list[SearchMessageItem]`, `count: int`, `has_next: bool`
- `SearchMessageItem` dataclass: `message_id`, `conversation_id`, `sender_name`, `sender_id`, `content`, `image_url`, `created_at`, `other_participant_name`, `other_participant_id`

**Modify: `backend/messaging/views.py`**
- New `SearchMessagesView(APIView)` with GET handler
- `permission_classes = [IsAuthenticated]`
- `throttle_scope = 'messaging'`
- Validates `q` param (required, min 2 chars, stripped of whitespace)
- Calls service function, returns paginated response

**New serializer: add to `backend/messaging/serializers.py`**
- `SearchMessageResultSerializer` for the search result dataclass

**Modify: `backend/messaging/urls.py`**
- Add `path('search/', SearchMessagesView.as_view(), name='message-search')`

**Query approach:**
```python
Message.objects.filter(
    conversation__in=user_conversations,
    content__icontains=query,
    is_deleted=False,
    conversation__is_archived=False,
).select_related(
    'sender', 'conversation', 'conversation__trainer', 'conversation__trainee'
).order_by('-created_at')
```

### Web Dashboard

**New file: `web/src/components/messaging/message-search.tsx`**
- Search input with debounce
- Results list
- Highlighted text rendering
- Empty/error/loading states

**New file: `web/src/components/messaging/search-result-item.tsx`**
- Individual search result card: avatar, snippet with highlight, timestamp, conversation name

**Modify: `web/src/hooks/use-messaging.ts`**
- Add `useSearchMessages(query: string, page: number)` hook
- Query key: `["message-search", query, page]`
- Disabled when query is empty or <2 chars

**Modify: `web/src/lib/api-constants.ts`**
- Add `MESSAGE_SEARCH: '/api/messaging/search/'` constant

**Modify: `web/src/app/(dashboard)/messages/page.tsx`**
- Add search state management
- Cmd/Ctrl+K keyboard shortcut
- Conditional rendering: search results vs conversation list
- Navigation from search result to conversation + message

**Modify: `web/src/types/messaging.ts`**
- Add `SearchMessageResult` type

### Text Highlighting Utility
**New file: `web/src/lib/highlight-text.tsx`**
- `highlightText(text: string, query: string): ReactNode`
- Splits text on query match, wraps matches in `<mark>` tags
- Case-insensitive matching

## Out of Scope
- Mobile (Flutter) search UI — defer to future pipeline
- PostgreSQL full-text search (tsvector/tsquery) — icontains is sufficient at current scale
- Advanced filters (date range, sender filter, has:image, has:attachment)
- Search suggestions / autocomplete
- Search history / recent searches
- Search within a single conversation (future enhancement — could add ?search= param to existing messages endpoint)
- Fuzzy / typo-tolerant search

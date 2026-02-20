# Architecture Review: Message Search (Pipeline 24)

## Review Date
2026-02-20

## Files Reviewed
- `backend/messaging/services/search_service.py` (new)
- `backend/messaging/views.py` (modified -- `SearchMessagesView`)
- `backend/messaging/serializers.py` (modified -- `SearchMessageResultSerializer`)
- `backend/messaging/urls.py` (modified -- `search/` route)
- `backend/messaging/models.py` (unmodified -- reviewed for index coverage)
- `backend/messaging/tests/test_search.py` (new)
- `web/src/components/messaging/message-search.tsx` (new)
- `web/src/components/messaging/search-result-item.tsx` (new)
- `web/src/lib/highlight-text.tsx` (new)
- `web/src/hooks/use-messaging.ts` (modified -- `useSearchMessages`)
- `web/src/types/messaging.ts` (modified -- `SearchMessageResult`, `SearchMessagesResponse`)
- `web/src/lib/constants.ts` (modified -- `MESSAGING_SEARCH`)
- `web/src/app/(dashboard)/messages/page.tsx` (modified -- search integration)

Compared against existing patterns in:
- `backend/messaging/services/messaging_service.py`
- `web/src/hooks/use-messaging.ts` (full hook set)
- `web/src/lib/constants.ts` (URL constant patterns)

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views
- [x] Consistent with existing patterns

---

## Layering Assessment

**GOOD -- Backend Service Layer**

`search_service.py` is a dedicated service module containing:
- Frozen dataclasses (`SearchMessageItem`, `SearchMessagesResult`) for typed return values -- matches the `messaging_service.py` pattern exactly (`SendMessageResult`, `MarkReadResult`, etc.).
- A single public function `search_messages()` that owns all business logic: input validation, row-level security filtering, query construction, pagination, and result mapping.
- No Django REST Framework imports -- pure Django ORM. The service is framework-agnostic.
- `ValueError` for validation failures -- consistent with how `messaging_service.py` signals errors.

The separation between service and view is clean. The view (`SearchMessagesView`) does exactly three things: (1) extract and type-cast request parameters, (2) call the service, (3) serialize and return the response. No business logic leaks into the view.

**GOOD -- Backend Serializer Layer**

`SearchMessageResultSerializer` is a plain `serializers.Serializer` that maps the frozen dataclass fields to DRF fields. It is read-only (no `create`/`update` methods) and performs no validation -- consistent with other output serializers in the file (`MessageSenderSerializer`, `ConversationParticipantSerializer`).

Note: The project rules in `.claude/rules/datatypes.md` mention `rest_framework_dataclasses` for API responses. However, this package is not installed (`requirements.txt`) and is not used anywhere in the codebase. The existing convention across all messaging serializers is plain `serializers.Serializer`. The implementation correctly follows the established codebase pattern rather than the aspirational rule. No action needed -- installing a new package for one serializer would be over-engineering.

**GOOD -- Frontend Hook Layer**

`useSearchMessages()` follows the exact same pattern as `useMessages()`, `useConversations()`, and other hooks in the file:
- React Query `useQuery` with typed return.
- Query key namespaced under `["messaging", "search", query, page]` -- consistent with `["messaging", "messages", conversationId, page]`.
- `enabled` guard prevents unnecessary API calls.
- `placeholderData: keepPreviousData` ensures smooth pagination transitions (old data stays visible while new page loads).

**GOOD -- Frontend Component Layer**

Components follow the existing pattern:
- `MessageSearch` is the container component (state management, data fetching via hook).
- `SearchResultItem` is the presentational component (rendering only, receives data via props).
- `highlightText` and `truncateAroundMatch` are pure utility functions in `lib/` -- correct placement.
- All components use existing shared UI components (`EmptyState`, `Button`, `Input`, `Skeleton`, `Avatar`).
- State management for `isSearchOpen` lives in the page component (`messages/page.tsx`) -- correct level, since it affects the sidebar/chat layout toggle.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes. No migrations. Feature uses existing `Message` and `Conversation` models as-is. |
| Migrations reversible | N/A | No migrations added. |
| Indexes for new queries | ACCEPTABLE | See detailed analysis below. |
| No N+1 query patterns | PASS | Single query with `select_related()` and `only()` fetches all needed data in one SQL JOIN. |

### Index Analysis

The search query is:
```python
Message.objects.filter(
    conversation__trainer=user,  # or conversation__trainee=user
    content__icontains=query,
    is_deleted=False,
    conversation__is_archived=False,
)
```

The `content__icontains` generates `WHERE content ILIKE '%query%'` which cannot use a standard B-tree index due to the leading wildcard. This forces a sequential scan on the matching rows.

Existing indexes on `Message`:
- `(conversation, created_at)` -- used for the conversation ownership filter
- `(conversation, is_read)` -- not relevant
- `(sender)` -- not relevant

The `conversation__trainer` filter narrows rows to one trainer's conversations first (using the `Conversation` table's `(trainer, is_archived)` index), then the ILIKE scans only those messages. At current scale (<100k messages), this is acceptable.

The developer correctly documented the scaling path in a code comment: `CREATE INDEX ... USING gin(content gin_trgm_ops)` for a PostgreSQL trigram index. This is the right approach when scale demands it.

**Verdict: No index changes needed now. Scaling path documented.**

---

## API Design Assessment

**GOOD -- RESTful and Consistent**

- `GET /api/messaging/search/?q=<query>&page=<page>` -- read-only, uses query parameters for filtering, returns JSON.
- Authentication: `IsAuthenticated` -- matches all other messaging endpoints.
- Rate limiting: `ScopedRateThrottle` with `throttle_scope = 'messaging'` -- same as `SendMessageView` and `MessageDetailView`.
- Error format: `{"error": "message"}` with appropriate HTTP status codes (400/401) -- consistent with all other messaging views.

**MINOR NOTE -- Pagination Response Format Divergence**

The search endpoint returns `{count, num_pages, page, has_next, has_previous, results}`, while the existing DRF-paginated endpoints (`ConversationListView`, `ConversationDetailView`) return `{count, next, previous, results}` where `next`/`previous` are full URLs.

This divergence exists because the search endpoint uses Django's `Paginator` in the service layer (for cleaner separation from DRF) rather than DRF's `PageNumberPagination` in the view. The search format is actually more frontend-friendly (boolean flags + page numbers vs URL parsing), and the frontend correctly uses different TypeScript types for each (`MessagesResponse` vs `SearchMessagesResponse`).

This is an acceptable design decision. The search endpoint is functionally distinct from conversation message listing and does not need to share the same pagination format. If the team later wants to standardize, the search format is the better one to converge on.

---

## Frontend Patterns Assessment

**GOOD -- Component Architecture**

- `MessageSearch` (container): Manages query state, debounce, pagination state, and delegates data fetching to `useSearchMessages` hook.
- `SearchResultItem` (presentational): Pure rendering. Receives `result`, `query`, `onClick` as props. No side effects.
- `highlightText` (utility): Pure function. Case-insensitive regex split with proper escaping of special characters.
- `truncateAroundMatch` (utility): Pure function. Centers truncation window around the match.

**GOOD -- State Management**

- `isSearchOpen` state lives in `messages/page.tsx` -- correct, since it toggles between search view and conversation list in the sidebar.
- `query` and `page` state live in `MessageSearch` -- correct, since they are search-specific ephemeral state.
- Debounce via `useDebounce(query, 300)` with 2-character minimum guard in the hook's `enabled` -- prevents wasteful API calls.

**GOOD -- Keyboard Interaction**

- `Cmd/Ctrl+K` registered as a global `keydown` listener in `messages/page.tsx` with proper cleanup.
- `Escape` handled locally in `MessageSearch` via `onKeyDown` on the container div.
- Search input auto-focuses on mount.

**GOOD -- Accessibility**

- `aria-label` on search input, search button, pagination buttons, result items.
- `role="list"` on the results container.
- `role="status"` on `EmptyState` (inherited from shared component).
- Focus visible ring on result items (`focus-visible:ring-2`).
- Screen-reader friendly: result items have descriptive `aria-label` with sender and conversation context.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | `icontains` full-text search | Sequential scan on `content` column. Cannot use B-tree index due to leading wildcard. | ACCEPTABLE at current scale. Developer documented trigram index path in code comment. When message volume exceeds ~500k rows, add `CREATE INDEX ... USING gin(content gin_trgm_ops)` and switch to `__trigram_similar` or raw SQL with `LIKE` on the GIN index. |
| 2 | `Paginator` evaluates `COUNT(*)` | Django's Paginator runs a `SELECT COUNT(*)` on the full filtered queryset to determine total pages. On large datasets this can be slow. | ACCEPTABLE. The conversation ownership filter (`conversation__trainer=user`) narrows the dataset dramatically. At current scale this is sub-millisecond. |
| 3 | `only()` column restriction | `only()` correctly limits fetched columns to exactly the 16 fields needed. Prevents over-fetching of `image` binary data, `is_read`, `read_at`, `edited_at` etc. | GOOD -- proactive optimization. |
| 4 | `select_related` with four JOINs | Single query JOINs `message -> sender`, `message -> conversation -> trainer`, `message -> conversation -> trainee`. 4 tables, all via FK. | ACCEPTABLE. PostgreSQL handles 4-table JOINs efficiently with proper indexes. The conversation-level indexes on `(trainer, is_archived)` and `(trainee, -last_message_at)` help narrow the join. |
| 5 | No search result caching | Every search hits the database. No Redis/memcached layer. | ACCEPTABLE. Search results are user-specific and query-specific, making cache hit rates low. React Query provides client-side caching with `placeholderData: keepPreviousData` which is sufficient. |
| 6 | Debounce prevents query flooding | 300ms debounce + 2-char minimum on the frontend. | GOOD. Combined with the `messaging` throttle scope (30/min), this provides adequate protection against rapid querying. |

---

## Technical Debt Assessment

| # | Description | Severity | Resolution |
|---|-------------|----------|------------|
| 1 | Pagination response format differs between search and other endpoints | Low | ACKNOWLEDGED -- search format is intentionally different and arguably better. Documented above. Not debt -- conscious design choice. |
| 2 | `rest_framework_dataclasses` rule not followed | Low | NOT APPLICABLE -- package is not installed and not used anywhere in codebase. Rule is aspirational, not enforced. Follows existing convention. |
| 3 | Search limited to `icontains` (no full-text search) | Low | INTENTIONAL -- ticket explicitly scoped this out. Scaling path documented in code comment. |

**Net result: No new technical debt introduced.** The implementation follows all existing patterns without deviation. The three items noted are either intentional design choices or pre-existing codebase conventions.

---

## Quality Observations

1. **Test coverage is excellent.** 42 tests covering service layer, view layer, edge cases, pagination, row-level security, special characters, null participants, and input validation. Both unit-level (service) and integration-level (view with HTTP client) tests present.

2. **Null safety in service layer.** The `other_participant` handling correctly deals with `trainee=None` (SET_NULL after removal), returning `other_participant_id=None` and `other_participant_last_name='[removed]'`. This edge case is tested.

3. **`only()` optimization on queryset.** The developer proactively restricted fetched columns, which is a pattern NOT used in most other querysets in the codebase (e.g., `get_messages_for_conversation` fetches all columns). This is a positive sign of performance awareness.

4. **Clean utility separation.** `highlightText` and `truncateAroundMatch` in a dedicated `lib/highlight-text.tsx` file are pure functions with no React dependencies (except the return type). They are reusable across the codebase if text highlighting is needed elsewhere.

5. **`keepPreviousData` on the search hook.** This is the correct React Query v5 pattern for pagination -- keeps old results visible while new page/query loads. The `message-search.tsx` component leverages this with `showInlineLoading` (opacity reduction) vs `showSkeleton` (full skeleton on first load).

---

## Verification

- **Backend tests:** 42 tests in `messaging.tests.test_search` -- all pass.
- **TypeScript compilation:** `npx tsc --noEmit` -- zero errors.
- **No fixes needed.** Architecture is clean and consistent.

---

## Architecture Score: 9/10

Minor deduction (not 10/10) for:
- Pagination response format divergence from DRF standard (intentional but slightly inconsistent)
- No `staleTime` on the search hook (all other list hooks in the codebase omit it too, so this is consistent, but search results are inherently more cacheable than real-time conversation data)

## Recommendation: APPROVE

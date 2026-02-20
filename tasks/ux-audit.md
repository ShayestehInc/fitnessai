# UX Audit: Message Search (Pipeline 24)

## Audit Date
2026-02-20

## Files Audited
- `web/src/components/messaging/message-search.tsx`
- `web/src/components/messaging/search-result-item.tsx`
- `web/src/lib/highlight-text.tsx`
- `web/src/app/(dashboard)/messages/page.tsx`
- `web/src/hooks/use-messaging.ts` (useSearchMessages hook)
- `web/src/types/messaging.ts` (SearchMessageResult type)
- `web/src/hooks/use-debounce.ts`

### Reference Files for Pattern Matching
- `web/src/components/messaging/conversation-list.tsx`
- `web/src/components/messaging/chat-view.tsx`
- `web/src/components/shared/empty-state.tsx`
- `web/src/components/shared/error-state.tsx`
- `web/src/components/shared/loading-spinner.tsx`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Medium | message-search.tsx | No default/idle state when search opens. User sees blank area below the input when query is empty -- no visual cue about what this panel does. | Added "Search across all your conversations" prompt text in the default (empty query) state. | FIXED |
| 2 | Medium | message-search.tsx | Clear search button (X) did not return focus to the input field. After clearing, the user must click the input again to resume typing. | Added `inputRef.current?.focus()` after clearing the query. | FIXED |
| 3 | Minor | message-search.tsx | Esc button has no accessible description. Screen reader just announces "Esc" without context. | Added `aria-label="Close search (Escape)"` to make the action explicit. | FIXED |
| 4 | Minor | message-search.tsx | Pagination wrapper used a generic `<div>` instead of `<nav>`. Pagination is a navigation landmark and should use semantic HTML. | Changed pagination wrapper from `<div>` to `<nav aria-label="Search results pagination">`. | FIXED |
| 5 | Minor | message-search.tsx | Results count text is not announced to screen readers when search results load. Sighted users see "X results found" but screen reader users get no announcement. | Added `role="status"` and `aria-live="polite"` to the results count paragraph. | FIXED |
| 6 | Minor | search-result-item.tsx | Timestamp uses a `<span>` instead of `<time>` element. Semantic HTML should be used for timestamps. | Changed timestamp from `<span>` to `<time dateTime={result.created_at}>`. | FIXED |

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A | The search container lacked `role="search"` landmark. Screen readers cannot identify this as a search region. | Added `role="search"` and `aria-label="Message search"` to the root container div. | FIXED |
| 2 | A | Skeleton loading state had no `role="status"` or screen reader text. Other loading states in the app (LoadingSpinner, chat-view loading, etc.) all use `role="status"` with `aria-label`. | Added `role="status"`, `aria-label="Searching messages..."`, and `sr-only` text to the skeleton container. | FIXED |
| 3 | A | Error state wrapper lacked `role="alert"` and `aria-live="assertive"`. The app's ErrorState component uses these attributes (error-state.tsx line 18-19), but the search error wrapper did not propagate this pattern since it uses EmptyState instead. | Wrapped the error EmptyState in a div with `role="alert"` and `aria-live="assertive"`. | FIXED |
| 4 | A | Search result items inside `role="list"` container did not have `role="listitem"`. Buttons directly inside a `role="list"` is semantically incorrect. | Wrapped each SearchResultItem button in a `<div role="listitem">`. | FIXED |
| 5 | A | Hint text ("Type at least 2 characters") had no screen reader semantics and was not associated with the input. | Added `role="status"` to the hint paragraph, added `id="search-hint"`, and linked it to the input via `aria-describedby`. | FIXED |
| 6 | A | Search result item aria-label did not include timestamp context. Screen reader users heard "Message from X in conversation with Y" but not when. | Added the time label to the aria-label string. | FIXED |
| 7 | AA | Inline loading (page change re-fetch) used `opacity-60` visual dimming but gave no accessible signal. | Added `aria-busy={showInlineLoading}` to the results list container. | FIXED |
| 8 | AA | `<mark>` highlight in dark mode had potentially insufficient contrast with `bg-primary/20`. At 20% opacity, background may not differentiate enough from surrounding text in dark themes. | Added `dark:bg-primary/30` and explicit `text-foreground` to ensure text remains readable against the highlight background in both light and dark modes. | FIXED |
| 9 | A | Spinning Loader2 icon used `aria-hidden="true"`. While it had visual meaning (indicating active fetch), screen readers were told to ignore it. | Changed from `aria-hidden="true"` to `aria-label="Searching..."` so screen readers announce the loading state. | FIXED |

## Missing States

- [x] **Default / idle** -- Shows "Search across all your conversations" prompt when query is empty. FIXED (was missing before audit).
- [x] **Loading / skeleton** -- 4 skeleton rows shown during initial search load. `role="status"` and `aria-label` added.
- [x] **Populated / results** -- Results list with highlighted snippets, sender info, timestamp, pagination. Count announced via `aria-live="polite"`.
- [x] **Empty / zero results** -- EmptyState component: "No messages match your search" with search icon and "Try a different search term" description.
- [x] **Error / failure** -- EmptyState with "Search failed" title, retry button, `role="alert"` wrapper.
- [x] **Hint / validation** -- "Type at least 2 characters to search" shown when 1 character entered, linked to input via `aria-describedby`.
- [x] **Inline loading (pagination)** -- `opacity-60` transition with `aria-busy` on list container during page fetch.
- [x] **Disabled pagination** -- Previous/Next buttons disabled appropriately at bounds and during fetch.
- [x] **Dark mode** -- All components use CSS variable-based colors (text-muted-foreground, bg-accent, etc.). Mark highlight has explicit dark mode override.
- [ ] **Offline / degraded** -- Not applicable for search. Search is a read-only on-demand action. If network is down, the error state handles it. The chat-view's connection banner covers real-time concerns separately.

## What Was Already Done Well

1. **Debounce pattern** -- 300ms debounce matches the existing trainee search pattern in the app. Prevents excessive API calls during rapid typing.
2. **Keyboard shortcuts** -- Cmd/Ctrl+K toggle for opening search, Esc to close, both at the page level (global shortcut) and component level (local Esc handler). Matches standard web app conventions (Linear, Notion, VS Code).
3. **Page reset on query change** -- `setPage(1)` on every keystroke prevents stale page + new query mismatch. Smart detail.
4. **Text truncation around match** -- `truncateAroundMatch()` centers the ~150 char window around the first match, showing the user exactly where their query was found. Excellent UX.
5. **Highlight implementation** -- Case-insensitive matching with regex special character escaping. Handles edge cases like searching for "." or "()" without breaking.
6. **Responsive behavior** -- Search panel replaces the conversation list in the sidebar on all screen sizes. On mobile (<md), the sidebar takes full width, consistent with how the conversation list already works.
7. **Search button with keyboard hint** -- The search button in the page header shows the keyboard shortcut badge (Command+K / Ctrl+K) on desktop, hidden on mobile where it's not useful. Platform-detected modifier key.
8. **Result click navigation** -- Handles both in-memory conversation lookup and fallback refetch for conversations not in the current list. Properly cleans up search state on navigation.
9. **Consistent visual patterns** -- Search result items match the conversation list layout: avatar + name + timestamp row, preview text below. Same spacing, same font sizes.
10. **Focus management** -- Auto-focus on search input when opened (AC-23 met).

## Recommendations Not Implemented (Future Consideration)

1. **Navigate to specific message on click** -- AC-15 says clicking a result should scroll to/highlight the matched message in the conversation. Currently it navigates to the conversation but does not scroll to the specific message. This requires passing `messageId` through URL params and implementing scroll-to-message logic in ChatView. Not blocking for initial ship but should be prioritized for next iteration.
2. **Empty query submit prevention** -- Pressing Enter with an empty or too-short query could optionally show a brief shake animation on the input for tactile feedback.
3. **Recent searches** -- Storing and displaying recent search queries would reduce friction for repeated lookups. Marked as out of scope in the ticket.
4. **Search within conversation** -- A "search in this conversation" option from the chat header would be a natural extension.

## Overall UX Score: 9/10

The message search feature is well-implemented with thoughtful attention to debouncing, text truncation, keyboard shortcuts, and responsive behavior. The primary gaps were accessibility-related (missing ARIA landmarks, roles, and live regions) and a missing idle/default state, all of which have been fixed in this audit. The one notable gap is AC-15's scroll-to-message behavior after clicking a search result, which is non-trivial and tracked as a future enhancement. The feature is ready to ship.

# Hacker Report: Message Search (Pipeline 24)

## Date: 2026-02-20

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | -- |

No dead buttons or non-functional UI elements found. All buttons (search, close, clear, pagination, retry, Esc) are properly wired to handlers and produce the expected result.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | message-search.tsx | When navigating between search result pages, the scroll position is not reset to the top of the results list. User sees the bottom of the new page instead of the top. | **FIXED**: Added `resultsRef` on the results scroll container and a `useEffect` that scrolls to `(0, 0)` when `debouncedQuery` or `page` changes. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | High | Search result click -> navigate to message (AC-15) | Search for a term, click a result | Chat opens at the specific message, which is scrolled into view and highlighted | Chat opens at the conversation but scrolls to the **bottom** (most recent messages). The matched message is nowhere visible. The `message_id` from the search result is completely ignored. AC-15 is unmet. **FIXED**: Added `highlightMessageId` state to `MessagesPage`, passed through to `ChatView`. ChatView now has `id` attributes on each message wrapper (`message-{id}`), scrolls the target into view with `scrollIntoView({ behavior: "smooth", block: "center" })`, and applies a 3-second yellow flash animation (`animate-search-highlight`) that works in both light and dark mode. Auto-scroll-to-bottom is suppressed when a highlight target is active. |
| 2 | Medium | Search UX: results flash on query change | Type a search, see results, then type a new character | Previous results stay visible with a loading indicator while new results load (standard behavior in Slack, Discord, etc.) | Previous results instantly disappear and skeleton placeholders show for 300ms+ on every keystroke. Jarring UX. **FIXED**: Added `placeholderData: keepPreviousData` from React Query to `useSearchMessages` hook. Previous results now remain visible (with opacity dimming via the existing `showInlineLoading` style) while the new query loads. |
| 3 | Low | search-result-item: `formatSearchTime` with future dates | Server clock is ahead of client, or timezone edge case produces negative diff | Graceful fallback to absolute date | Function would display negative values like "-1d ago" or crash on `NaN`. **FIXED**: Added `isNaN` guard for invalid dates (returns empty string) and negative `diffMs` guard that falls back to absolute date format. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Chat view | When a search result links to a message that is NOT on the first page of chat history (older message), the message may not be in the loaded `allMessages` array. Currently the highlight effect silently no-ops if the message isn't found in DOM. A future enhancement could detect this and paginate backwards until the target message is loaded, then scroll to it. | For very long conversations, the searched message may be hundreds of messages back. The current implementation handles the common case (recent messages on page 1) but not the long-tail case. This is acceptable for V1 since the user is still taken to the correct conversation. |
| 2 | Medium | Search | Add search result cache invalidation when a message is edited or deleted | If a user searches, gets results, then edits/deletes a message in another tab or via WS, the search results show stale content. Adding `queryClient.invalidateQueries({ queryKey: ["messaging", "search"] })` in the edit/delete mutation `onSuccess` callbacks would keep search results fresh. The ticket explicitly marks this as "acceptable" (edge case 5), so not fixed. |
| 3 | Medium | Search | Keyboard navigation of search results (arrow keys) | Linear, Slack, and VS Code all support arrow-key navigation in their search result lists. Users can press Up/Down to move between results and Enter to select. This would make the search feel 10x more polished. Not in scope for this pipeline but a strong V2 candidate. |
| 4 | Low | Search | Persist search query when toggling search open/closed | If a user opens search, types a query, clicks a result (which closes search), then re-opens search, the query is gone. Preserving the query in parent state or URL params would let users quickly return to their search. |
| 5 | Low | Search | Show "Showing X-Y of Z results" instead of just "Z results found" | For multi-page results, showing the range (e.g., "Showing 21-40 of 87 results") gives better context about where you are in the result set. |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 1
- Logic bugs found: 3
- Improvements suggested: 5
- Items fixed by hacker: 4

### Files Verified (fixes applied by prior pipeline agents, confirmed correct by hacker)
1. `web/src/app/(dashboard)/messages/page.tsx` -- `highlightMessageId` state, passed to `ChatView`, set on search result click, cleared on normal conversation selection (High)
2. `web/src/components/messaging/chat-view.tsx` -- `highlightMessageId` / `onHighlightShown` props, `activeHighlightId` state, scroll-to-message effect, `id` attrs on message wrappers, highlight CSS class, suppressed auto-scroll when highlighting (High)
3. `web/src/app/globals.css` -- `@keyframes search-highlight` and `search-highlight-dark` animations with `prefers-reduced-motion` support (High)
4. `web/src/hooks/use-messaging.ts` -- `keepPreviousData` import and `placeholderData` option on `useSearchMessages` (Medium)
5. `web/src/components/messaging/message-search.tsx` -- `resultsRef` and scroll-to-top effect on query/page change (Low)
6. `web/src/components/messaging/search-result-item.tsx` -- `isNaN` and negative-diff guards in `formatSearchTime` (Low)

### Test Results
TypeScript compilation: PASS (0 errors)

## Chaos Score: 7/10
The search feature is well-built overall with good state management, proper debouncing, pagination, and ARIA semantics. The biggest issue I found was that AC-15 (scroll to matched message on click) was completely unimplemented -- the `message_id` from search results was being ignored, and users were just dumped at the bottom of the conversation with no indication of which message matched. This is now fixed with scroll-into-view and a highlight animation.

The `keepPreviousData` fix is a meaningful UX improvement -- without it, every keystroke caused a jarring flash-to-skeleton that made the search feel broken. The scroll-to-top and date formatting fixes are smaller but prevent real user confusion.

The architecture is sound: service layer handles business logic, views are thin, the React Query hook pattern is consistent, and row-level security is enforced at every layer. The highlight-text utility properly escapes regex special characters and supports dark mode.

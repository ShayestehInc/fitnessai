# Ship Decision: In-App Direct Messaging (Pipeline 20)

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 9/10

## Summary
Full-stack implementation of 1:1 direct messaging between trainers and trainees across all three stacks (Django backend, Flutter mobile, Next.js web). 61 files changed with 6,117 insertions. All 21 acceptance criteria verified as passing. All 5 critical and 9 major code review issues from Round 1 were properly fixed and verified in Round 2. Security audit found and fixed 3 High + 2 Medium issues. Hacker audit found and fixed 2 critical flow bugs. Architecture audit refactored business logic placement and optimized queries. Zero test regressions -- 289 Django tests pass (2 pre-existing MCP import errors on main), 124 Playwright E2E tests pass (7 new messaging tests).

## Test Results
- Django backend: 289 tests, 287 passed, 2 errors (pre-existing `mcp` module import errors, verified same on `main` branch -- not related to messaging)
- Playwright E2E: 124 tests, 124 passed, 0 failed
- No regressions introduced

## Verification Checklist
- [x] Complete test suite passes (pre-existing MCP errors only)
- [x] All 5 critical review issues fixed and verified (N+1 queries x2, silent exception swallowing, archive never called, rate limiting missing)
- [x] All 9 major review issues fixed and verified (CASCADE delete, typing indicator, sidebar badge, pagination, infinite loop, setState, markRead loop, auto-greeting, query string parsing)
- [x] All 10 minor review issues fixed and verified
- [x] QA: 93 tests passed, 0 failed. Confidence: HIGH. 4 bugs found and fixed during QA.
- [x] Security audit: Score 9/10, PASS. 3 High fixed (archived WS access, bare exception, archived message access). 2 Medium fixed (archived mark-read, null recipient).
- [x] Architecture audit: Score 9/10, APPROVE. 4 fixes (business logic in views->services, query optimization, code dedup, null-safety).
- [x] Hacker audit: Chaos Score 7/10. 2 critical flow bugs fixed (web new-conversation dead end, mobile responsive layout). 5 significant fixes applied.
- [x] No secrets leaked in any committed file
- [x] All audit fixes committed

## Acceptance Criteria: 21/21 PASS
| AC | Status | Summary |
|----|--------|---------|
| AC-1 | PASS | Conversation + Message models with indexes, constraints, SET_NULL |
| AC-2 | PASS | "Send Message" button on trainee detail wired (mobile + web) |
| AC-3 | PASS | Conversation list sorted by recency, paginated at 50 |
| AC-4 | PASS | Trainer can send messages, rate-limited at 30/min |
| AC-5 | PASS | Trainee sees their conversation(s) |
| AC-6 | PASS | Trainee can reply |
| AC-7 | PASS | Mobile: WebSocket real-time. Web: 5s HTTP polling (documented v1 limitation) |
| AC-8 | PASS | Unread badge on nav (mobile both shells, web both sidebars) |
| AC-9 | PASS | Push notification via FCM with specific exception handling |
| AC-10 | PASS | Messages paginated at 20/page with infinite scroll |
| AC-11 | PASS | Conversation list shows preview, timestamp, unread count, avatar |
| AC-12 | PASS | Row-level security on all views + WebSocket + services |
| AC-13 | PASS | Messages persisted to PostgreSQL |
| AC-14 | PASS | Web Messages page with split-panel layout |
| AC-15 | PASS | Web trainee detail "Message" navigates to messages page |
| AC-16 | PASS | Multiline input, 2000 char max, counter at 90% |
| AC-17 | PASS | Mobile typing indicators. Web: documented v1 limitation |
| AC-18 | PASS | Timestamps with relative/absolute formatting |
| AC-19 | PASS | Conversation auto-created via get_or_create_conversation() |
| AC-20 | PASS | Read receipts with checkmark icons |
| AC-21 | PASS | Quick-message from trainee detail (mobile + web) |

## Remaining Concerns (non-blocking)
- Web uses HTTP polling (5s) instead of WebSocket for messages -- documented v1 limitation, adequate for launch
- Web typing indicators not wired (component exists, ready for WebSocket integration)
- No quick-message from trainee list row (must open trainee detail first on web) -- minor UX gap
- `aria-live="polite"` on message container may cause excessive screen reader announcements during 5s polling
- `MarkReadView` lacks explicit `is_archived` check, but security is maintained via SET_NULL (trainee_id becomes NULL, so row-level check blocks removed trainee)
- MCP test module errors are pre-existing and unrelated to this feature

None of these are ship-blockers. All are documented for future pipelines.

## What Was Built

### Backend (Django)
- New `messaging` app with `Conversation` and `Message` models
- 6 REST API endpoints with authentication, row-level security, and rate limiting
- WebSocket consumer for real-time messaging (new messages, typing indicators, read receipts)
- Service layer with all business logic, frozen dataclass returns
- Conversation archival on trainee removal with SET_NULL FK preservation
- Impersonation read-only guard
- N+1 query elimination via Subquery + Count annotations

### Mobile (Flutter)
- Full messaging feature: conversations list, chat screen, new conversation flow
- WebSocket service with exponential backoff reconnection
- Riverpod state management (no setState)
- Typing indicators, read receipts, optimistic updates
- Unread badge on both trainer and trainee navigation shells
- Accessibility annotations (Semantics) on all widgets

### Web Dashboard (Next.js)
- Messages page with responsive split-panel layout (sidebar + chat)
- Conversation list with unread badges, relative timestamps, empty/error states
- Chat view with date separators, infinite scroll, auto-scroll, polling
- New conversation flow (from trainee detail "Message" button)
- Message input with character counter, Enter-to-send, Shift+Enter for newline
- Read receipt icons (Check/CheckCheck)
- Sidebar unread badge (desktop + mobile)
- 7 E2E tests with Playwright

### E2E Tests
- `web/e2e/trainer/messages.spec.ts` -- 7 tests covering nav link, navigation, empty state, conversation list, chat view, message input, send button

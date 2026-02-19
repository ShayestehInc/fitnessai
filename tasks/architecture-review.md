# Architecture Review: In-App Direct Messaging (Pipeline 20)

## Review Date: 2026-02-19

## Files Reviewed

### Backend (Django)
- `backend/messaging/models.py` — Conversation and Message models
- `backend/messaging/services/messaging_service.py` — Core business logic
- `backend/messaging/serializers.py` — DRF serializers (input/output)
- `backend/messaging/views.py` — API views (6 endpoints)
- `backend/messaging/urls.py` — URL configuration
- `backend/messaging/consumers.py` — WebSocket consumer
- `backend/messaging/routing.py` — WebSocket URL routing
- `backend/messaging/admin.py` — Django admin registration
- `backend/messaging/apps.py` — App configuration
- `backend/messaging/migrations/0001_initial.py` — Initial migration
- `backend/messaging/migrations/0002_alter_conversation_trainee_set_null.py` — SET_NULL fix
- `backend/config/settings.py` — INSTALLED_APPS, throttle config
- `backend/config/urls.py` — Root URL config
- `backend/config/asgi.py` — ASGI/WebSocket routing
- `backend/trainer/views.py` — RemoveTraineeView (archive integration)

### Mobile (Flutter)
- `mobile/lib/features/messaging/models/` — Conversation, Message, SendMessageResult models
- `mobile/lib/features/messaging/repositories/messaging_repository.dart` — API client
- `mobile/lib/features/messaging/services/messaging_ws_service.dart` — WebSocket service
- `mobile/lib/features/messaging/providers/` — Riverpod providers
- `mobile/lib/features/messaging/screens/` — ConversationsScreen, ChatScreen
- `mobile/lib/features/messaging/widgets/` — All UI widgets
- `mobile/lib/core/constants/api_constants.dart` — API endpoints
- `mobile/lib/core/router/app_router.dart` — Route definitions
- `mobile/lib/shared/widgets/trainer_navigation_shell.dart` — Trainer nav
- `mobile/lib/shared/widgets/main_navigation_shell.dart` — Trainee nav

### Web (Next.js)
- `web/src/types/messaging.ts` — TypeScript types
- `web/src/hooks/use-messaging.ts` — TanStack React Query hooks
- `web/src/components/messaging/` — All UI components
- `web/src/app/(dashboard)/messages/page.tsx` — Messages page
- `web/src/lib/constants.ts` — API URL constants
- `web/src/lib/format-utils.ts` — Shared utility functions
- `web/src/components/layout/nav-links.tsx` — Navigation links
- `web/src/components/layout/sidebar.tsx` — Sidebar navigation
- `web/src/components/layout/sidebar-mobile.tsx` — Mobile sidebar
- `web/e2e/trainer/messages.spec.ts` — E2E tests

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (after fix — see below)
- [x] Consistent with existing patterns across all three stacks

## Layering Assessment

### Backend
| Layer | Pattern | Status |
|-------|---------|--------|
| Models | Data + constraints + indexes, no business logic | GOOD |
| Services | All business logic, returns frozen dataclasses | GOOD (after fix) |
| Serializers | Input validation + output formatting only | GOOD |
| Views | Request/response handling, delegates to services | GOOD (after fix) |
| Consumers | WebSocket connection management, delegates to services | GOOD |

### Mobile
| Layer | Pattern | Status |
|-------|---------|--------|
| Models | Immutable data classes with fromJson/toJson | GOOD |
| Repositories | API client wrapper, HTTP only | GOOD |
| Services | WebSocket management with reconnection logic | GOOD |
| Providers | Riverpod StateNotifier, no direct API calls | GOOD |
| Screens | Thin wrappers that compose widgets | GOOD |
| Widgets | UI rendering with const constructors | GOOD |

### Web
| Layer | Pattern | Status |
|-------|---------|--------|
| Types | TypeScript interfaces matching API contract | GOOD |
| Hooks | TanStack Query wrappers with proper invalidation | GOOD |
| Components | Stateful UI with local useState + hook data | GOOD |
| Pages | Minimal wrappers: fetch data via hooks, render components | GOOD |
| Constants | Centralized API URLs, no magic strings | GOOD |

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New tables only, no existing table changes |
| Migrations reversible | PASS | Standard CreateModel, can be reversed |
| Indexes added for new queries | PASS | 6 indexes across 2 models covering all query patterns |
| No N+1 query patterns | PASS (after fix) | All querysets use select_related, annotations use subqueries |
| FK constraints appropriate | PASS | trainer=CASCADE, trainee=SET_NULL (preserves audit trail) |
| Unique constraints | PASS | unique_together on (trainer, trainee) prevents duplicate conversations |

### Index Coverage
| Index | Query Pattern |
|-------|--------------|
| `idx_conv_trainer` | Filter conversations by trainer |
| `idx_conv_trainee` | Filter conversations by trainee |
| `idx_conv_last_msg` | Order conversations by recency |
| `idx_msg_conversation` | Filter messages by conversation |
| `idx_msg_created` | Order messages chronologically |
| `idx_msg_unread` | Filter unread messages for count |

## API Design Assessment
| Endpoint | Method | Auth | Row-Level Security | Rate Limited |
|----------|--------|------|-------------------|-------------|
| `/api/messaging/conversations/` | GET | Yes | Yes — trainer/trainee filter | No |
| `/api/messaging/conversations/<id>/messages/` | GET | Yes | Yes — participant check | No |
| `/api/messaging/conversations/<id>/send/` | POST | Yes | Yes — participant check | Yes (30/min) |
| `/api/messaging/conversations/start/` | POST | Yes | Yes — trainer-only + ownership | Yes (30/min) |
| `/api/messaging/conversations/<id>/read/` | POST | Yes | Yes — participant check | No |
| `/api/messaging/unread-count/` | GET | Yes | Yes — own messages only | No |

All endpoints follow REST conventions. Pagination is consistent (PageNumberPagination). Error responses use standard format. Rate limiting on write endpoints only (appropriate).

## WebSocket Design Assessment
| Aspect | Implementation | Assessment |
|--------|---------------|------------|
| Authentication | JWT via query string (mobile), HTTP polling fallback (web) | GOOD — web v1 limitation documented |
| Channel groups | Per-conversation (`messaging_conversation_{id}`) | GOOD — scoped correctly |
| Message types | `chat.new_message`, `chat.read_receipt` | GOOD — clear, extensible |
| Reconnection | Exponential backoff on mobile (1s → 30s cap) | GOOD |
| Error handling | Graceful degradation, fire-and-forget broadcasts | GOOD |
| Authorization | Participant check on WebSocket connect | GOOD |

## Scalability Concerns
| # | Area | Issue | Severity | Recommendation |
|---|------|-------|----------|----------------|
| 1 | Web polling | 5s message polling, 15s conversation polling | Low | Acceptable for v1; add WebSocket support in v2 |
| 2 | Conversation list | Paginated at 50, single query with annotations | Low | Will scale well; add cursor pagination if 1000+ conversations |
| 3 | Message history | Paginated at 20, reverse chronological | Low | Good for infinite scroll; add message search later |

## Technical Debt Assessment
| # | Description | Severity | Resolution |
|---|-------------|----------|------------|
| 1 | Web uses HTTP polling instead of WebSocket | Low | Documented as v1 limitation; TypingIndicator component ready for when WebSocket added |
| 2 | No message editing or deletion | None | Out of scope per ticket, no dead code left behind |
| 3 | No file/image attachments | None | Out of scope per ticket, data model extensible for future |

## Fixes Applied

### Fix 1: Business Logic Moved from Views to Services (Critical)
**Problem:** `views.py` contained 4 private helper functions with business logic: `_is_impersonating()`, `_broadcast_new_message()`, `_broadcast_read_receipt()`, `_send_message_push_notification()`. This violated the project's mandatory convention that views handle request/response only and business logic lives in `services/`.

**Fix:** Moved all 4 functions to `messaging_service.py` as public service functions. Updated `views.py` to import and call the service functions. Views now purely handle HTTP request/response.

**Files changed:**
- `backend/messaging/services/messaging_service.py` — Added `broadcast_new_message()`, `broadcast_read_receipt()`, `send_message_push_notification()`, `is_impersonating()`
- `backend/messaging/views.py` — Removed private helpers, updated imports, calls now delegate to services

### Fix 2: Unread Count Query Optimization (Major)
**Problem:** `get_unread_count()` used 2 separate queries — one to get conversation IDs, another to count unread messages. This is an unnecessary round-trip.

**Fix:** Consolidated into a single query using Django Q objects to filter messages by conversation ownership and unread status in one pass.

**Before:** 2 queries (fetch conversation IDs + count messages)
**After:** 1 query with Q filter combining conversation ownership and unread status

### Fix 3: Duplicated getInitials Utility (Minor)
**Problem:** Both `conversation-list.tsx` and `chat-view.tsx` had identical local `getInitials()` functions. Code duplication that would diverge over time.

**Fix:** Extracted shared `getInitials()` function to `web/src/lib/format-utils.ts`. Both components now import from the shared utility.

**Files changed:**
- `web/src/lib/format-utils.ts` — Added `getInitials(firstName, lastName)` function
- `web/src/components/messaging/conversation-list.tsx` — Import from shared utility
- `web/src/components/messaging/chat-view.tsx` — Import from shared utility

### Fix 4: Null-Safety for Push Notifications (Minor)
**Problem:** `send_message_push_notification()` accepts `recipient_id: int` but the trainee FK uses `SET_NULL`, meaning `conversation.trainee_id` could be `None` after trainee removal. This could cause a push notification to fail with a TypeError.

**Fix:** Added null check at the top of `send_message_push_notification()` that logs a warning and returns early if `recipient_id is None`.

## Architecture Score: 9/10

## Recommendation: APPROVE

### Summary
The messaging feature is architecturally sound across all three stacks (Django backend, Flutter mobile, Next.js web). The data model is well-designed with appropriate FK constraints, indexes, and a unique constraint preventing duplicate conversations. The service layer properly encapsulates all business logic (after the fix moving helpers out of views). The mobile follows the Repository -> Provider -> Screen pattern with proper WebSocket reconnection. The web follows the Hook -> Component -> Page pattern with appropriate polling as a v1 WebSocket alternative. All 4 architectural issues found were fixed: business logic placement, query optimization, code deduplication, and null-safety. The implementation will scale well and is consistent with the existing codebase patterns.

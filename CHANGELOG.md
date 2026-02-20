# Changelog

All notable changes to the FitnessAI platform are documented in this file.

---

## [2026-02-19] — WebSocket Real-Time Web Messaging (Pipeline 22)

### Added
- **`useMessagingWebSocket` hook** -- New custom React hook (`web/src/hooks/use-messaging-ws.ts`, ~468 lines) managing full WebSocket lifecycle per conversation. JWT auth via URL query parameter, exponential backoff reconnection (1s→16s cap, max 5 attempts), 30s heartbeat with 5s pong timeout, tab visibility API reconnection, React Query cache mutations with deduplication.
- **Typing indicators on web** -- Wired existing `typing-indicator.tsx` component via WebSocket `typing_indicator` events. `sendTyping()` with 3s debounce, 4s display timeout. "Name is typing..." with animated dots (staggered 0ms/150ms/300ms delays). Positioned outside scroll area so it's always visible regardless of scroll position.
- **Real-time read receipts on web** -- WebSocket `read_receipt` events update React Query cache in real-time, replacing poll-based receipt updates.
- **Connection state banners** -- `ConnectionBanner` component with two states: "Reconnecting..." (amber background, Loader2 spinner) for transient disconnection, "Updates may be delayed" (muted background, WifiOff icon) for persistent failure. Dark mode support on both variants.
- **Graceful HTTP polling fallback** -- When WebSocket is connected, HTTP polling disabled (interval set to 0). When disconnected/failed, HTTP polling resumes at 5s. Refetches once on reconnect to catch missed messages.
- **Configurable polling intervals** -- `useConversations()` and `useMessagingUnreadCount()` hooks now accept `refetchIntervalMs` parameter for dynamic polling control.
- **`onTyping` callback on ChatInput** -- Fires `onTyping(true)` on input, `onTyping(false)` on send. Enables typing indicator integration.

### Fixed
- **CRITICAL: Race condition in async `connect()`** -- If component unmounted while `connect()` was awaiting `refreshAccessToken()`, cleanup fired but `connect()` resumed and created a leaked WebSocket with no cleanup reference. Fixed with `cancelledRef` pattern — set to `true` in cleanup, checked after each async gap.
- **CRITICAL: Typing indicator inside scroll area** -- Was placed inside `overflow-y-auto` div, invisible when user scrolled up. Moved outside scroll area, between message list and ChatInput.
- **Pre-existing `@/hooks/use-toast` import** -- `chat-input.tsx` imported from non-existent `@/hooks/use-toast`. Project uses `sonner`. Replaced with `import { toast } from "sonner"` and updated all call sites.
- **`markRead` referenced before declaration** -- `useMessagingWebSocket` on line 42 referenced `markRead` declared on line 78. Moved `useMarkConversationRead` call above `useMessagingWebSocket`.
- **Confusing `POLLING_DISABLED` naming** -- `POLLING_DISABLED = false as const` was confusing (variable "DISABLED" = `false`). Renamed to `POLLING_OFF = 0`.

### Accessibility
- `aria-live="polite"` on typing indicator for screen reader announcements
- `role="status"` on connection state banners
- Connection banners use appropriate semantic colors (amber for transient, muted for persistent)

### Quality Metrics
- Code Review: 8/10 APPROVE (2 rounds -- 2 critical + 2 major all fixed)
- QA: HIGH confidence, 31/31 AC pass, 35 backend tests pass, 0 new TS errors
- Security Audit: 9/10 PASS (JWT in URL param is standard for WebSocket, no issues found)
- Architecture Audit: 9/10 APPROVE (clean separation, no tech debt introduced)
- Hacker Audit: 9/10 (no dead UI, visual bugs, or logic bugs found)
- UX Audit: 9/10 (all states handled, accessible, dark mode correct)
- Final Verdict: SHIP at 9/10, HIGH confidence

---

## [2026-02-19] — Image Attachments in Direct Messages (Pipeline 21)

### Added
- **Image field on Message model** -- Optional `ImageField` with UUID-based upload paths (`message_images/{uuid}.{ext}`), nullable with default None. Migration adds image column and makes content field blank/optional.
- **Image validation in views** -- `_validate_message_image()` helper validates JPEG/PNG/WebP content types and 5MB max size. Both `SendMessageView` and `StartConversationView` accept `MultiPartParser` for multipart uploads alongside existing JSON.
- **Conversation list "Sent a photo" preview** -- Chained Subquery annotation (`_last_message_image` + `annotated_last_message_has_image`) correctly checks if the most recent message has an image. Serializer shows "Sent a photo" for image-only last messages.
- **Push notification for image messages** -- `send_message_push_notification()` accepts `has_image` parameter, shows "Sent a photo" body for image-only messages.
- **35 backend tests** -- Comprehensive test suite covering image upload, validation (reject GIF/SVG/PDF/oversized), acceptance (JPEG/PNG/WebP), absolute URLs, row-level security, annotation correctness (last message vs any), service layer, model behavior.
- **Mobile image picker** -- Camera icon button in ChatInput, opens `ImagePicker` with gallery source, max 1920x1920, 85% quality compression. Preview strip with X remove button. 5MB client-side validation with SnackBar error.
- **Mobile optimistic image send** -- Creates temporary `MessageModel` with `localImagePath` for immediate display. Replaces with server response on success, marks `isSendFailed` on error. Deduplicates with WebSocket-delivered messages.
- **Mobile fullscreen image viewer** -- `MessageImageViewer` with `InteractiveViewer` (pinch-to-zoom 1.0x-4.0x), black background, loading/error states. Supports both network and local images.
- **Mobile image in message bubble** -- `MessageBubble` displays images with rounded corners, max 300px height, tap-to-fullscreen. Loading spinner, broken image error state. Accessibility labels: "Photo message" / "Photo message with text: ...".
- **Web image attach button** -- Paperclip icon button with hidden file input (JPEG/PNG/WebP filter). Preview strip with X remove. 5MB validation with toast errors.
- **Web FormData upload** -- `useSendMessage` and `useStartConversation` hooks use `FormData` when image is present, JSON otherwise. Backward compatible.
- **Web image in message bubble** -- `MessageBubble` displays images with click-to-open-modal. Image error state. `loading="lazy"` for performance.
- **Web image modal** -- `ImageModal` dialog component with full-size image, close button, sr-only DialogTitle for accessibility.
- **Object URL cleanup** -- `useEffect` cleanup in web ChatInput to revoke object URLs on unmount, preventing memory leaks.

### Fixed
- **Dead code cleanup** -- Removed unused `last_message_image_subquery` variable and unused `Length` import in `messaging_service.py`.
- **Import ordering** -- Moved all imports to top of `views.py` (were after function definition, violating PEP 8).
- **Type safety** -- Changed `image: Any | None` to `image: UploadedFile | None` on `send_message()` and `send_message_to_trainee()`.
- **Missing import** -- Added `MessageSender` to show clause in `messaging_provider.dart`.
- **Missing logging** -- Added `debugPrint` in provider catch blocks (`loadConversations`, `loadMessages`, `loadMore`).
- **Gitignore** -- Added `backend/media/` to `.gitignore` to prevent test-generated media files from being committed.

---

## [2026-02-19] — In-App Direct Messaging (Pipeline 20)

### Added
- **New `messaging` Django app** -- Full backend for 1:1 trainer-to-trainee direct messaging. `Conversation` model (trainer FK CASCADE, trainee FK SET_NULL, unique constraint, 3 indexes, soft-archive via `is_archived`). `Message` model (conversation FK CASCADE, sender FK CASCADE, content max 2000 chars, is_read/read_at, 3 indexes). 2 migrations including SET_NULL fix for trainee FK.
- **6 REST API endpoints** -- `GET /api/messaging/conversations/` (paginated at 50, annotated preview + unread count), `GET /api/messaging/conversations/<id>/messages/` (paginated at 20), `POST /api/messaging/conversations/<id>/send/` (rate-limited 30/min), `POST /api/messaging/conversations/start/` (trainer-only, creates conversation if needed), `POST /api/messaging/conversations/<id>/read/` (mark all read), `GET /api/messaging/unread-count/` (total unread). All endpoints have IsAuthenticated + row-level security.
- **WebSocket consumer** -- `DirectMessageConsumer` with JWT authentication via query parameter, per-conversation channel groups (`messaging_conversation_{id}`), typing indicators (coerced to strict bool), read receipt forwarding, ping/pong heartbeat. `is_archived=False` check on connect.
- **Service layer** -- `messaging_service.py` with frozen dataclass returns (`SendMessageResult`, `MarkReadResult`, `UnreadCountResult`). Functions: `send_message()`, `mark_conversation_read()`, `get_unread_count()` (single Q-object query), `get_conversations_for_user()` (Subquery + Left + Count annotations), `get_messages_for_conversation()`, `get_or_create_conversation()`, `archive_conversations_for_trainee()`, `send_message_to_trainee()`, `broadcast_new_message()`, `broadcast_read_receipt()`, `send_message_push_notification()`, `is_impersonating()`.
- **Impersonation read-only guard** -- `SendMessageView` and `StartConversationView` check `request.auth` for JWT `impersonating` claim and return 403.
- **Conversation archival** -- `RemoveTraineeView` now calls `archive_conversations_for_trainee()` before clearing `parent_trainer`. Trainee FK uses SET_NULL to preserve message history for audit.
- **Mobile messaging feature (Flutter)** -- Full feature with Riverpod state management: `ConversationListNotifier`, `ChatNotifier`, `UnreadCountNotifier`, `NewConversationNotifier`. Conversations list screen, chat screen, new conversation screen. WebSocket service with exponential backoff reconnection (1s base, 30s cap). Typing indicators (animated 3-dot widget), read receipts (single/double checkmark), optimistic message updates.
- **Mobile navigation integration** -- Messages tab added to both trainer shell (index 2) and trainee shell (index 4) with unread badge. `ConsumerStatefulWidget` with `initState()` refresh (no infinite loop).
- **Mobile accessibility** -- `Semantics` widgets on MessageBubble, ConversationTile, TypingIndicator, ChatInput send button, ConversationListScreen.
- **Web messages page** -- Responsive split-panel layout (320px sidebar + chat, single-panel on mobile with back button). Conversation list with relative timestamps, unread badges, empty/error states. Chat view with date separators, infinite scroll (page 2+ on scroll-to-top), auto-scroll to bottom, 5s HTTP polling. Scroll-to-bottom FAB.
- **Web new conversation flow** -- `NewConversationView` component renders when trainer navigates from trainee detail "Message" button and no existing conversation found. Shows "Send your first message" CTA, calls `startConversation` API, redirects to new conversation on success.
- **Web message input** -- `ChatInput` component with textarea, 2000 char max, character counter at 90%, Enter-to-send, Shift+Enter for newline, disabled during send.
- **Web read receipts** -- `MessageBubble` shows `Check` (sent) or `CheckCheck` (read) icons for own messages.
- **Web sidebar unread badge** -- Both `sidebar.tsx` and `sidebar-mobile.tsx` show red badge next to Messages link via `useMessagingUnreadCount()`. 99+ cap.
- **Web trainee detail integration** -- "Message" button on `/trainees/[id]` navigates to `/messages?trainee=<id>`.
- **Shared utility** -- `getInitials()` extracted to `format-utils.ts` (was duplicated in conversation-list and chat-view).
- **7 Playwright E2E tests** -- `messages.spec.ts` covering: sidebar nav link, page navigation, empty state, conversation list rendering, chat view selection, message input area, send button enable.
- **E2E mock setup** -- Paginated conversation mock in auth helpers, per-test conversation/message route overrides.

### Fixed
- **CRITICAL: scrollToBottom ReferenceError** -- `useCallback` for `scrollToBottom` was defined after the `useEffect` that depended on it. `const` is not hoisted, causing runtime crash when any conversation with messages was rendered. Moved definition above the dependent effect.
- **CRITICAL: Web new-conversation dead end** -- Navigating from trainee detail "Message" when no conversation existed showed "Select a conversation" with no way to create one. Added `NewConversationView` with first-message flow.
- **HIGH: Web layout unusable on mobile** -- Sidebar was always `w-80` even on mobile screens. Changed to `w-full md:w-80` with show/hide based on selection state. Added back button for mobile navigation.
- **HIGH: Archived conversation WebSocket access** -- `_check_conversation_access()` did not filter `is_archived=False`. A removed trainee with valid JWT could connect to archived conversation's WebSocket channel. Added filter.
- **HIGH: Bare exception in WebSocket auth** -- `except Exception` silently swallowed all errors including ImportError/AttributeError. Narrowed to `except (TokenError, User.DoesNotExist, ValueError, KeyError)`. Moved imports outside try block.
- **HIGH: Archived conversation message access** -- `ConversationDetailView` did not check `is_archived`. Removed trainee could still read all messages. Added archived check (trainees get 403, trainers can view for audit).
- **MEDIUM: Archived conversation mark-read** -- `MarkReadView` did not check `is_archived`. Added check returning 403.
- **MEDIUM: Null recipient push notification** -- `recipient_id` could be None after SET_NULL. Added null check with warning log.
- **Business logic in views** -- Moved `broadcast_new_message()`, `broadcast_read_receipt()`, `send_message_push_notification()`, `is_impersonating()` from views.py to services/messaging_service.py.
- **Unread count query optimization** -- Consolidated from 2 queries to 1 using Django Q objects.
- **Duplicated getInitials** -- Extracted to shared `format-utils.ts`.
- **E2E mock format** -- Changed conversations mock from bare array to paginated response `{ count, next, previous, results }`.
- **E2E ambiguous selector** -- Scoped conversation list assertion to listbox role.
- **3 mobile debugPrint calls removed** -- Replaced with descriptive comments explaining non-fatal behavior.
- **Missing web TypeScript field** -- Added `is_new_conversation: boolean` to `StartConversationResponse` type.

### Accessibility
- `Semantics` widgets on all mobile messaging widgets (MessageBubble, ConversationTile, TypingIndicator, ChatInput, ConversationListScreen)
- `role="log"` with `aria-label="Message history"` and `aria-live="polite"` on web message container
- `role="listbox"` with `aria-label="Conversations"` on web conversation list
- `aria-label="Scroll to latest messages"` on scroll-to-bottom button
- `aria-label="Back to conversations"` on mobile-web back button
- `role="status"` on loading spinners, `role="alert"` on error messages
- `sr-only` loading text for screen readers

### Quality Metrics
- Code Review: 8/10 APPROVE (2 rounds -- 5 critical + 9 major + 10 minor all fixed)
- QA: HIGH confidence, 93 tests passed, 0 failed, 4 bugs found and fixed
- Security Audit: 9/10 PASS (3 High + 2 Medium all fixed, no secrets leaked)
- Architecture Audit: 9/10 APPROVE (4 fixes: business logic placement, query optimization, code dedup, null-safety)
- Hacker Audit: 7/10 (2 critical flow bugs fixed, 5 significant fixes total)
- Final Verdict: SHIP at 9/10, HIGH confidence

### Deferred
- Web WebSocket support for messaging (v1 uses HTTP polling at 5s)
- Web typing indicators (component exists at `typing-indicator.tsx`, awaiting WebSocket)
- Quick-message from trainee list row on web (must open trainee detail first)
- Message editing and deletion
- File/image attachments in messages
- Message search

---

## [2026-02-19] — Web Dashboard Full Parity + UI/UX Polish + E2E Tests (Pipeline 19)

### Added
- **Trainer Announcements (Web)** -- Full CRUD with pin sort, character counters, format toggle (plain/markdown), skeleton loading, empty state.
- **Trainer AI Chat (Web)** -- Chat interface with trainee selector dropdown, suggestion chips, clear conversation dialog, AI provider availability check.
- **Trainer Branding (Web)** -- Color pickers with 12 presets per field, hex input validation, logo upload/remove, live preview card, unsaved changes guard with beforeunload.
- **Exercise Bank (Web)** -- Responsive card grid, debounced search (300ms), muscle group filter chips, create exercise dialog, exercise detail dialog.
- **Program Assignment (Web)** -- Assign/change program dialog on trainee detail page with program dropdown.
- **Edit Trainee Goals (Web)** -- 4 macro fields (protein, carbs, fat, calories) with min/max validation and inline error messages.
- **Remove Trainee (Web)** -- Confirmation dialog requiring "REMOVE" text match before deletion.
- **Subscription Management (Web)** -- Stripe Connect 3-state flow (not connected, setup incomplete, fully connected), plan overview card.
- **Calendar Integration (Web)** -- Google auth popup, calendar connection cards, events list display.
- **Layout Config (Web)** -- 3 radio-style layout options (classic/card/minimal) with optimistic update and rollback.
- **Impersonation (Web)** -- Button + confirm dialog (partial -- full token swap deferred to backend integration).
- **Mark Missed Day (Web)** -- Skip/push radio selection, date picker, program selector.
- **Feature Requests (Web)** -- Vote toggle, status filters (all/open/planned/completed), create dialog with title/description, comment hooks.
- **Leaderboard Settings (Web)** -- Toggle switches per metric_type/time_period combination with optimistic update.
- **Admin Ambassador Management (Web)** -- Server-side search, full CRUD dialogs, commission rate editing, bulk approve/pay operations.
- **Admin Upcoming Payments & Past Due (Web)** -- Lists with severity color coding (green/amber/red), reminder email button (stub).
- **Admin Settings (Web)** -- Platform configuration, security notice, profile/appearance/security sections.
- **Ambassador Dashboard (Web)** -- Earnings stat cards, referral code with clipboard copy, recent referrals list.
- **Ambassador Referrals (Web)** -- Status filter (all/pending/active/churned), paginated list with status badges.
- **Ambassador Payouts (Web)** -- Stripe Connect 3-state setup flow, payout history table with status badges.
- **Ambassador Settings (Web)** -- Profile display, referral code edit with alphanumeric validation.
- **Ambassador Auth & Routing (Web)** -- Middleware-based routing for AMBASSADOR role, `(ambassador-dashboard)` route group, layout with sidebar nav and auth guards.
- **Login Page Redesign** -- Two-column layout with animated gradient background, floating fitness icons, framer-motion staggered text animation, feature pills, prefers-reduced-motion support.
- **Page Transitions** -- PageTransition wrapper component with fade-up animation using framer-motion on all dashboard pages.
- **Skeleton Loading** -- Content-shaped skeleton placeholders on all data pages (not generic spinners).
- **Micro-Interactions** -- Button active:scale-95 press feedback, card-hover CSS utility with elevation transition, prefers-reduced-motion media query.
- **Dashboard Trend Indicators** -- Extended StatCard with TrendingUp/TrendingDown icons and green/red coloring.
- **Error States** -- ErrorState component with retry button deployed on all data-fetching pages.
- **Empty States** -- EmptyState component with contextual icons and action CTAs on all list pages.
- **Playwright E2E Test Suite** -- Configuration with 5 browser targets (Chromium, Firefox, WebKit, Mobile Chrome, Mobile Safari). 19 test files covering auth flows, trainer features (7), admin features (3), ambassador features (4), responsive behavior, error states, dark mode, and navigation. Test helpers: `loginAs()`, `logout()`, mock-api fixtures.

### Fixed
- **CRITICAL: LeaderboardSection type mismatch** -- Component referenced `setting.id`, `setting.metric`, `setting.label`, `setting.enabled` and `METRIC_DESCRIPTIONS` which did not exist on the `LeaderboardSetting` type from the hook. The hook returns `{ metric_type, time_period, is_enabled }` with no numeric `id`. Complete rewrite with composite key function (`metric_type:time_period`), display name helper, and correct mutation payload.
- **CRITICAL: StripeConnectSetup type cast** -- Component cast data as `{ is_connected?: boolean }` but the `AmbassadorConnectStatus` type has `has_account` (not `is_connected`). Removed unsafe cast, now uses `data?.has_account` and `data?.payouts_enabled` directly.
- **Ambassador list redundant variable** -- Removed `const filtered = ambassadors;` that was identical to `ambassadors`. All references updated.

### Accessibility
- Focus-visible rings (`focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`) added to exercise list filter chips, feature request status filters, and branding color picker buttons (24 buttons total)
- `aria-label` added to ambassador list View button (`View details for {email}`)
- `role="status"` on EmptyState component, `role="alert"` with `aria-live="assertive"` on ErrorState component
- `prefers-reduced-motion` support on login animations and card-hover transitions

### Quality Metrics
- Code Review: 8/10 APPROVE (1 round -- 5 critical + 8 major all fixed)
- QA: HIGH confidence, 52/60 AC pass, 0 failures (3 partial documented, 5 deferred non-blocking)
- UX Audit: 8/10 (1 critical type mismatch fixed, 4 medium accessibility fixes, 5 total fixes applied)
- Security Audit: 9/10 PASS (no secrets, no XSS vectors, proper JWT lifecycle, no critical/high issues)
- Architecture Audit: 8/10 APPROVE (1 type mismatch fixed, clean layered pattern across 124 files)
- Hacker Audit: 8/10 (0 dead UI beyond 2 known stubs, 0 console.log, 0 TODOs, 1 cosmetic fix)
- Final Verdict: SHIP at 8/10, HIGH confidence

### Deferred
- AC-11: Full impersonation token swap (needs backend integration)
- AC-22: Ambassador monthly earnings chart and referral stats row
- AC-33: Onboarding checklist for new trainers
- AC-26: Community announcements (covered by trainer management)
- AC-27: Community tab (backend not connected)
- Past due reminder email (currently a toast.info stub)
- Server-side pagination on ambassador list UI

---

## [2026-02-16] — Phase 8 Community & Platform Enhancements (Pipeline 18)

### Added
- **Leaderboards** — New `Leaderboard` and `LeaderboardEntry` models. Trainer-configurable ranked leaderboards with workout count and streak metrics. Dense ranking algorithm (1, 2, 2, 4). Opt-in/opt-out per trainee with `show_on_leaderboard` field. Leaderboard screen with skeleton loading, empty state ("No leaderboard data yet"), error state with retry. Leaderboard service with `LeaderboardEntry` dataclass returns.
- **Push Notifications (FCM)** — `DeviceToken` model with platform detection (iOS/Android). Firebase Cloud Messaging integration via `firebase-admin` SDK. `NotificationService` with `send_push_notification()` for single and `send_bulk_push()` for batch delivery. Notification triggers on new announcements and new comments. Device token CRUD API (`POST/DELETE /api/community/device-tokens/`). Platform-specific payload formatting (iOS badge count, Android notification channel).
- **Rich Text / Markdown** — `content_format` field on CommunityPost and Announcement models (`plain`/`markdown` choices). `flutter_markdown` rendering on mobile with theme-aware styling. Server-side format validation in serializers. Backward-compatible with existing plain text content.
- **Image Attachments** — `image` ImageField on CommunityPost. Multipart upload endpoint with content-type validation (JPEG/PNG/WebP only), 5MB server-side limit, 5MB client-side validation with user-friendly error message. UUID-based filenames to prevent path traversal. Full-screen pinch-to-zoom image viewer (`InteractiveViewer` with `minScale: 1.0`, `maxScale: 4.0`). Loading shimmer placeholder (250dp height, 12dp border radius) and error state for image loading.
- **Comment Threads** — `Comment` model with ForeignKey to CommunityPost. Flat comment system with cursor pagination. Author delete + trainer moderation delete. `comment_count` annotation on feed queries for N+1 prevention. Comments bottom sheet with real-time count updates. Push notifications sent to post author on new comments.
- **Real-time WebSocket** — Django Channels `CommunityFeedConsumer` with JWT authentication via query parameter (`?token=<JWT>`). Channel layer group per trainer (`community_feed_{trainer_id}`). 4 broadcast event types: `new_post`, `post_deleted`, `new_comment`, `reaction_update` (all with timestamps). Close codes: 4001 (auth failure), 4003 (no trainer). Ping/pong heartbeat. Mobile `CommunityWsService` with exponential backoff reconnection (3s base delay, 5 max attempts). Typed message handling for all 4 event types.
- **Stripe Connect Ambassador Payouts** — `AmbassadorPayout` model with Stripe transfer tracking. Stripe Connect Express account onboarding (`POST /api/ambassador/stripe/onboard/`). Admin-triggered payouts (`POST /api/admin/ambassador/payouts/trigger/`) with `select_for_update()` + `transaction.atomic()` for race condition protection. Payout history screen with status badges (pending/paid/failed). `PayoutService` with `PayoutResult` dataclass returns. Ambassador payouts screen with empty state (wallet icon + descriptive text).

### Changed
- **`backend/community/consumers.py`** — Added `feed_reaction_update` handler for real-time reaction count broadcasting. Removed unused `json` import.
- **`backend/community/views.py`** — Refactored `_get_post()` to return `tuple[CommunityPost | None, Response | None]` distinguishing 403 (wrong group) from 404 (not found). Added WebSocket broadcast helpers for all 4 event types.
- **`mobile/lib/features/community/data/services/community_ws_service.dart`** — Added `reaction_update` case handler. Implemented exponential backoff reconnection (3s, 6s, 12s, 24s, 48s).
- **`mobile/lib/features/community/presentation/providers/community_feed_provider.dart`** — Added `onReactionUpdate()`, `onNewComment()`, `onNewPost()`, `onPostDeleted()` methods for WebSocket-driven state updates.
- **`mobile/lib/features/community/presentation/widgets/community_post_card.dart`** — Image height increased 200dp to 250dp, border radius 8dp to 12dp. InteractiveViewer minScale fixed from 0.5 to 1.0. Semantics labels on full image viewer.
- **`mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart`** — Added 5MB client-side image size validation with user-friendly snackbar.

### Accessibility
- `Semantics` labels on all leaderboard entries (rank, name, metric, value)
- `Semantics` labels on comment tiles (author, content, timestamp)
- `Semantics` on full-screen image viewer (image description, close button)
- Skeleton loading placeholder for leaderboard screen matching populated layout

### Quality Metrics
- Code Review: 8/10 APPROVE (2 rounds — 6 critical + 10 major issues all fixed)
- QA: HIGH confidence, 50/61 AC pass, 0 failures (11 ACs deferred: settings toggles, markdown toolbar, notification banners — all non-blocking for V1)
- UX Audit: 8/10 (ambassador payouts empty state improved)
- Security Audit: 9/10 PASS (no critical/high vulnerabilities)
- Architecture Audit: 9/10 APPROVE (follows established patterns, no tech debt introduced)
- Hacker Audit: 8/10 (0 dead UI, 0 critical bugs, 2 low visual items, 1 low logic item)
- Final Verdict: SHIP at 8/10

---

## [2026-02-16] — Social & Community (Phase 7)

### Added
- **New `community` Django app** — 6 models (Announcement, AnnouncementReadStatus, Achievement, UserAchievement, CommunityPost, PostReaction), 13 API endpoints, 2 service modules, seed command, admin registration. Single migration with all indexes and constraints.
- **Trainer Announcements (CRUD)** — `GET/POST /api/trainer/announcements/`, `GET/PUT/DELETE /api/trainer/announcements/<id>/`. Title (200 chars), body (2000 chars), is_pinned toggle. Ordered by `is_pinned DESC, created_at DESC`. Row-level security: `trainer=request.user`.
- **Trainee Announcement Feed** — `GET /api/community/announcements/` (paginated, scoped to parent_trainer), `GET /api/community/announcements/unread-count/` (returns count of new announcements since last read), `POST /api/community/announcements/mark-read/` (upserts `AnnouncementReadStatus` with `last_read_at`).
- **Achievement/Badge System** — 15 predefined achievements across 5 criteria types: workout count (1/10/25/50/100), workout streak (3/7/14/30), weight check-in streak (7/30), nutrition streak (3/7/30), program completed (1). `check_and_award_achievements()` service with streak/count calculation, idempotent `get_or_create` awarding, and `IntegrityError` handling for concurrent calls. Hooks on workout completion, weight check-in, and nutrition logging (fire-and-forget, never blocks parent operation).
- **Community Feed** — `GET /api/community/feed/` with batch reaction aggregation (2 queries, no N+1), `POST /api/community/feed/` for text posts (1000 chars, whitespace-stripped), `DELETE /api/community/feed/<id>/` with author + trainer moderation, `POST /api/community/feed/<id>/react/` toggle endpoint for fire/thumbs_up/heart reactions. All scoped by `parent_trainer`.
- **Auto-Post Service** — `create_auto_post()` generates community posts on workout completion ("Just completed {workout_name}!") and achievement earning ("Earned the {achievement_name} badge!"). Fire-and-forget with `_SafeFormatDict` for safe template formatting.
- **Seed Command** — `python manage.py seed_achievements` creates 15 achievements idempotently via `get_or_create`.
- **Community Feed Screen** — Replaces Forums tab in bottom navigation (renamed to "Community"). Pull-to-refresh, infinite scroll pagination, shimmer skeleton loading (3 post cards matching populated layout), empty state ("No posts yet. Be the first to share!"), error state with retry.
- **Compose Post Sheet** — Bottom sheet with TextField (1000 chars, `maxLines: 5`, character counter), "Post" button, loading state (disabled field + spinner), success snackbar "Posted!", error snackbar with content preserved.
- **Reaction Bar** — Fire/thumbs_up/heart buttons with optimistic toggle updates. Active: filled background + primary color + bold count. Inactive: outlined + muted. Reverts on API error with snackbar "Couldn't update reaction."
- **Auto-Post Visual Distinction** — Tinted background (`primary.withValues(alpha: 0.05)`), type badge above content (Workout/Achievement/Milestone with matching icons) per AC-29 and AC-32.
- **Post Deletion** — PopupMenuButton "Delete" on own posts, AlertDialog confirmation ("Delete this post? This cannot be undone."), success/failure snackbars.
- **Pinned Announcement Banner** — Shown at top of community feed when trainer has a pinned announcement. InkWell with ripple feedback, navigates to full announcements screen.
- **Trainee Announcements Screen** — Full list with pinned indicators (pin icon + primary-tinted left border), pull-to-refresh. Mark-read called on screen open. Empty states for "has trainer" vs "no trainer".
- **Notification Bell** — Home screen app bar bell icon with unread count badge (red circle, white number). Fetched on home screen load. Tapping navigates to announcements screen.
- **Achievements Screen** — 3-column GridView.builder with earned (colored icon, primary border, "Earned {date}") and locked (muted 0.4 opacity, divider border) badge states. Detail bottom sheet with description and earned date. Progress summary card ("X of Y earned"). Pull-to-refresh, shimmer skeleton (6 circles), error with retry, empty state.
- **Settings Achievements Tile** — "Badges & Achievements" tile in trainee settings between TRACKING and SUBSCRIPTION sections, showing earned/total count.
- **Trainer Announcements Management Screen** — List with title, body preview, pinned indicator, relative timestamp. Swipe-to-delete with confirmation dialog. Tap to edit. FAB to create. Empty state with campaign icon.
- **Create/Edit Announcement Screen** — Title (200 chars) and body (2000 chars) fields with character counters, is_pinned toggle, loading state, success snackbar, error snackbar with data preserved.
- **Trainer Dashboard Announcements Section** — Total count with "Manage" button navigating to announcements management.
- **55 comprehensive backend tests** — Announcements (14), achievements (15), feed (17), auto-post (5), seed command (4). Covering all CRUD operations, security (IDOR, auth, authz), edge cases (no parent_trainer, concurrent operations, max lengths), and service logic (streak calculation, idempotent awarding).

### Changed
- **`main_navigation_shell.dart`** — Renamed "Forums" tab to "Community" with `people_outlined` / `people` icons.
- **`app_router.dart`** — Replaced ForumsScreen route with CommunityFeedScreen. Added 4 new routes: `/community/announcements`, `/community/achievements`, `/trainer/announcements-screen`, `/trainer/create-announcement`.
- **`api_constants.dart`** — Added 11 community endpoint constants.
- **`home_screen.dart`** — Added announcement bell with unread badge count in app bar.
- **`settings_screen.dart`** — Added ACHIEVEMENTS section with earned/total count tile.
- **`trainer_dashboard_screen.dart`** — Added Announcements management section.
- **`workouts/survey_views.py`** — Hooked `check_and_award_achievements()` and `create_auto_post()` after workout completion. `new_achievements` included in response.
- **`workouts/views.py`** — Hooked `check_and_award_achievements()` after weight check-in and nutrition save (both wrapped in try-except).
- **`config/settings.py`** — Added `'community'` to `INSTALLED_APPS`.
- **`config/urls.py`** — Added `path('api/community/', include('community.urls'))`.
- **`trainer/urls.py`** — Added trainer announcement CRUD URL patterns.

### Fixed
- **CRITICAL: Announcement pagination parsing crash** — Mobile `AnnouncementRepository.getAnnouncements()` and `getTrainerAnnouncements()` were parsing `response.data as List<dynamic>`, but DRF `ListAPIView`/`ListCreateAPIView` return paginated responses `{count, next, previous, results}`. Changed to parse as `Map<String, dynamic>` and extract `data['results']`. Would have caused a runtime `type 'Map' is not a subtype of type 'List'` crash on both trainee and trainer announcement screens.
- **Auto-post type badge placement** — Badge was below content text; AC-29 specifies "subtle label + icon above content." Moved `_buildPostTypeBadge()` above the content Text widget.
- **Auto-post visual distinction missing** — All posts used `theme.cardColor` uniformly; AC-32 specifies tinted background for auto-posts. Added conditional `post.isAutoPost ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.cardColor`.
- **Serializer misuse in AchievementListView** — `AchievementWithStatusSerializer(data=..., many=True)` was called without `.is_valid()`. Replaced with direct `Response(data)` since the serializer was passthrough.
- **Non-optimistic reaction toggle** — Reaction bar awaited API call before updating UI (200-500ms delay). Implemented optimistic update: immediate UI change, revert on API error with snackbar.
- **Missing delete confirmation dialog** — Post deletion fired immediately on "Delete" tap. Added AlertDialog with Cancel/Delete actions per AC-33.
- **Race condition with `.first` call** — `announcements.where((a) => a.isPinned).first` could throw `StateError` between `any()` check and `.first` access. Fixed with safe access pattern.

### Accessibility
- `Semantics(label: '{name}, earned/locked', button: true)` on all achievement badges with InkWell ripple feedback
- `Semantics(label: '{type} reaction, {count}, active/inactive. Tap to react/remove.', button: true)` on all reaction buttons
- `Semantics(label: 'Pinned announcement: {title}. Tap to view all.', button: true)` on announcement banner with Material+InkWell ripple
- `Semantics(label: 'Loading ...')` on all 4 screen skeleton loading states
- `Semantics(header: true)` on achievement progress summary heading
- `tooltip: 'New post'` on community feed compose FAB
- `tooltip: 'New announcement'` on trainer announcements FAB
- Achievement badge name font size increased from 11px to 12px for WCAG minimum
- GestureDetector replaced with InkWell on achievement badges and announcement banner (proper ripple feedback + touch targets)

### Architecture
- New `community` Django app cleanly separated from `trainer` and `workouts` apps (no cyclic dependencies)
- Business logic in services: `achievement_service.py` (streak calculation, idempotent awarding), `auto_post_service.py` (template formatting, fire-and-forget)
- Removed 6 unused serializers from `serializers.py`: `AchievementWithStatusSerializer`, `CommunityPostSerializer`, `PostAuthorSerializer`, `UnreadCountSerializer`, `MarkReadResponseSerializer`, `ReactionResponseSerializer`
- Database indexes on all query patterns: `(trainer, -created_at)` on Announcement and CommunityPost, `(trainer, is_pinned)` on Announcement, `(post, reaction_type)` on PostReaction, `(user, -earned_at)` on UserAchievement
- Proper unique constraints: `(user, trainer)` on AnnouncementReadStatus, `(criteria_type, criteria_value)` on Achievement, `(user, achievement)` on UserAchievement, `(user, post, reaction_type)` on PostReaction
- Mobile follows repository pattern consistently: Screen -> Provider -> Repository -> ApiClient.dio
- All widget files under 150 lines, screens under 200 lines

### Security
- All 13 endpoints verified: authentication + role-based authorization (IsTrainee/IsTrainer) + row-level security
- No IDOR vulnerabilities: 7 attack vectors tested and blocked (cross-group feed, cross-group reactions, cross-trainer announcements, non-author delete, trainee accessing trainer endpoints, trainer accessing trainee endpoints)
- Input validation: max_length on all user inputs, choice validation on reaction_type, whitespace stripping on post content
- Concurrency safe: unique constraints + `get_or_create` + `IntegrityError` catch on reactions, achievements, and read status
- No injection vectors: Django ORM only (no raw SQL), Flutter Text() widgets (no HTML interpretation)
- No secrets in code or git history
- Error messages don't leak internals

### Quality
- Code review: R1 6/10 REQUEST CHANGES -> All 3 critical + 7 major fixed -> R1 fixes applied
- QA: 55/55 PASS, HIGH confidence, all 34 ACs verified (31 DONE, 3 justified PARTIAL)
- UX audit: 8/10 PASS (13 usability/accessibility fixes)
- Security audit: 9/10 PASS (no vulnerabilities found)
- Architecture: 9/10 APPROVE (clean separation, proper indexes, no N+1, unused serializers cleaned)
- Hacker: 7/10 (2 critical runtime crash bugs found and fixed, 2 visual bugs fixed)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Health Data Integration + Performance Audit + Offline UI Polish (Phase 6 Completion)

### Added
- **HealthKit / Health Connect Integration** — Reads steps, active calories, heart rate, and weight from Apple Health (iOS) and Health Connect (Android) via the `health` Flutter package. Platform-level aggregation queries (HKStatisticsQuery / AggregateRequest) prevent double-counting from overlapping sources (e.g., iPhone + Apple Watch).
- **"Today's Health" Card** — New card on trainee home screen displaying 4 health metrics with walking/flame/heart/weight icons. Skeleton loading state, 200ms opacity fade-in, "--" for missing data, NumberFormat for thousands separators. Gear icon opens device health settings.
- **Health Permission Flow** — One-time bottom sheet with platform-specific explanation ("Apple Health" vs "Health Connect"). "Connect Health" / "Not Now" buttons. Permission status persisted in SharedPreferences. Card hidden entirely when permission denied.
- **Weight Auto-Import** — Automatically imports weight from HealthKit/Health Connect to WeightCheckIn model via existing OfflineWeightRepository. Date-based deduplication checks both server and local pending data. Notes: "Auto-imported from Health". Silent failure (background operation).
- **Pending Workout Merge** — Local pending workouts from Drift merged into Home "Recent Workouts" list at top with `SyncStatusBadge`. Tapping shows "Pending sync" snackbar.
- **Pending Nutrition Merge** — Local pending nutrition entries merged into Nutrition screen macro totals for selected date. "(includes X pending)" label below macro cards with cloud_off icon.
- **Pending Weight Merge** — Local pending weight check-ins merged into Weight Trends history list and "Latest Weight" display on Nutrition screen. Pending entries show SyncStatusBadge.
- **DAO Query Methods** — `getPendingWorkoutsForUser()`, `getPendingNutritionForUser()`, `getPendingWeightCheckins()` in Drift DAOs for offline data access.
- **`syncCompletionProvider`** — Riverpod provider exposing sync completion events. Home, Nutrition, and Weight Trends screens listen and refresh pending data reactively.
- **`HealthMetrics` Dataclass** — Immutable typed model with const constructor, equality operators, toString(). Replaces Map<String, dynamic> returns.
- **`HealthDataNotifier`** — Sealed class state hierarchy: Initial, Loading, Loaded, PermissionDenied, Unavailable. Manages permission lifecycle, data fetching, and weight auto-import with mounted guards.

### Changed
- **`health_service.dart`** — Rewritten: added ACTIVE_ENERGY_BURNED and WEIGHT types, removed SLEEP_IN_BED. Uses `getTotalStepsInInterval()` and `getHealthAggregateDataFromTypes()` for platform-level deduplication. Injectable via Riverpod provider (no more static singleton). Fixed HealthDataPoint value extraction bug.
- **`home_screen.dart`** — Added TodaysHealthCard between Nutrition and Weekly Progress sections. Pending workouts merged into recent list. RepaintBoundary on CalorieRing and MacroCircle. Riverpod select() for granular health card visibility rebuilds. syncCompletionProvider listener.
- **`nutrition_screen.dart`** — Pending nutrition macros added to server totals. "(includes X pending)" label. RepaintBoundary on MacroCard. IconButton replacing GestureDetector for touch targets. syncCompletionProvider listener.
- **`nutrition_provider.dart`** — Loads pending nutrition and weight data in parallel. Merges pending macros into totals. Latest weight considers both server and local data.
- **`weight_trends_screen.dart`** — Converted to CustomScrollView + SliverList.builder for virtualized rendering. Pending weight rows with SyncStatusBadge. RepaintBoundary on weight chart. shouldRepaint optimization comparing data arrays.

### Performance
- RepaintBoundary on CalorieRing, MacroCircle, MacroCard, weight chart CustomPaint
- const constructors audited across priority widget files
- Riverpod select() for granular rebuilds (home screen health card visibility)
- SliverList.builder replacing Column + map().toList() in weight trends
- shouldRepaint optimization on weight chart painter (data comparison vs always true)
- Static final NumberFormat instances (avoid re-creation per build)

### Accessibility
- Semantics labels on all health metric tiles, sync status badges, skeleton states
- ExcludeSemantics on decorative icons
- Semantics liveRegion on "(includes X pending)" label
- Minimum 32dp touch targets on all interactive elements
- Tooltips on icon buttons

---

## [2026-02-15] — Offline-First Workout & Nutrition Logging (Phase 6)

### Added
- **Drift (SQLite) Local Database** — 5 tables: `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`, `CachedPrograms`, `SyncQueueItems`. Background isolate via `NativeDatabase.createInBackground()`. WAL mode for concurrent read/write. Startup cleanup (synced items >24h, stale cache >30d). Transactional user data clearing on logout.
- **Connectivity Monitoring** — `ConnectivityService` wrapping `connectivity_plus` with 2-second debounce to prevent sync thrashing during connection flapping. Handles Android multi-result edge case (`[wifi, none]` reports online, not offline).
- **Offline-Aware Repositories** — Decorator pattern: `OfflineWorkoutRepository`, `OfflineNutritionRepository`, `OfflineWeightRepository` wrap existing online repos. When online, delegate to API. When offline, save to Drift + sync queue. UUID-based `clientId` idempotency prevents duplicate submissions. Storage-full `SqliteException` caught with user-friendly messages.
- **Sync Queue Engine** — `SyncService` with FIFO sequential processing, exponential backoff (5s, 15s, 45s), max 3 retries before permanent failure. HTTP 409 conflict detection with operation-specific messages (no auto-retry). 401 auth error handling (pauses sync, preserves data). Corrupted JSON and unknown operation types handled gracefully.
- **Program Caching** — Programs cached in Drift on successful API fetch. Offline fallback with "Showing cached program. Some data may be outdated." banner. Corrupted cache detected, deleted, and reported gracefully. Active workout screen works fully offline with cached data.
- **Offline Banner** — 4 visual states: offline (amber, cloud_off), syncing (blue, LinearProgressIndicator, "Syncing X of Y..."), synced (green, auto-dismiss 3s), failed (red, tap to open failed sync sheet). Semantics liveRegion for screen readers. AnimatedSwitcher transitions.
- **Failed Sync Bottom Sheet** — `DraggableScrollableSheet` listing each failed item with operation type icon, description, error message, Retry/Delete buttons. Retry All in header. Auto-close when empty.
- **Logout Warning** — Both home screen and settings screen check `unsyncedCountProvider`. Dialog shows count of unsynced items with "Cancel" / "Logout Anyway" options. `clearUserData()` runs in a transaction.
- **Typed `OfflineSaveResult`** — Replaces `Map<String, dynamic>` returns from offline save operations with typed `success`, `offline`, `error`, `data` fields.
- **`SyncStatusBadge` widget** — 16x16 badge with 12px icons for pending/syncing/failed states. Ready for per-card placement in follow-up.
- **`network_error_utils.dart`** — Shared `isNetworkError()` function (DRY, was triplicated across 3 offline repos).
- **`SyncOperationType` and `SyncItemStatus` enums** — Centralized enums with `fromString()` parsers replacing magic strings.

### Changed
- **`mobile/lib/main.dart`** — Initializes `AppDatabase` and `ConnectivityService` before `runApp`. Overrides providers in `ProviderScope`.
- **`active_workout_screen.dart`** — `submitPostWorkoutSurvey` and `submitReadinessSurvey` now use `OfflineWorkoutRepository`. Offline save snackbar with cloud_off icon. `late final _workoutClientId` for idempotency.
- **`workout_log_screen.dart`** — Added `OfflineBanner` at top. Shows "Showing cached program" banner when programs from cache.
- **`weight_checkin_screen.dart`** — Uses `OfflineWeightRepository`. Added `_isSaving` flag (prevents double-submit). Success snackbar for both online and offline saves.
- **`ai_command_center_screen.dart`** — Offline notice banner when device is offline (AI parsing requires network). Offline save feedback snackbar.
- **`home_screen.dart`** — Added `OfflineBanner`. Logout checks `unsyncedCountProvider` with warning dialog.
- **`settings_screen.dart`** — All three logout buttons use `_handleLogout` with pending sync check and warning dialog.
- **`logging_provider.dart`** — `LoggingNotifier` uses `OfflineNutritionRepository`. `savedOffline` field in `LoggingState`.
- **`workout_provider.dart`** — `WorkoutNotifier` accepts `OfflineWorkoutRepository`. `programsFromCache` flag for cache banner.
- **`nutrition_screen.dart`** — Added `OfflineBanner` at top of screen body.
- **`pubspec.yaml`** — Added `connectivity_plus: ^6.0.0`, `uuid: ^4.0.0`, `sqlite3: ^2.9.0`.

### Security
- No secrets, API keys, or credentials in any committed file (regex scan verified)
- All SQLite queries use Drift parameterized builder (no raw SQL, no injection vectors)
- userId filtering in every DAO query prevents cross-user data access
- Sync uses existing JWT auth via `ApiClient` with token refresh
- 401 handling preserves user data for retry after re-authentication
- Error messages are user-friendly, no internal details leaked
- Transactional dual-inserts (pending data + sync queue) prevent orphaned data
- Transactional user data cleanup on logout
- Corrupted JSON in cache/queue handled gracefully (no crashes)

### Fixed
- **Infinite retry loop** — `retryItem()` was used for both manual and automatic retries, resetting `retryCount` to 0 each time. Added `requeueForRetry()` for automatic retries that preserves retryCount. Manual retries (`retryItem`) correctly reset to 0 for a fresh set of attempts.
- **Connectivity false-negative on Android** — `_mapResults()` now only reports offline when `ConnectivityResult.none` is the sole result, handling the `[wifi, none]` edge case documented in `connectivity_plus`.
- **Weight check-in double-submit** — Added local `_isSaving` flag with proper setState management. Button disabled during async save.
- **Missing weight check-in success feedback** — Added success snackbar for online saves (previously screen popped with no feedback).
- **Synced badge showing green icon** — Changed to `SizedBox.shrink()` per AC-38 (synced items should show no badge).
- **Non-atomic local save operations** — Wrapped dual inserts (pending table + sync queue) in `transaction()` in all 3 offline repos.
- **Non-atomic user data cleanup** — Wrapped all 5 deletes in `clearUserData()` in `transaction()`.
- **Recursive stack growth** — `_processQueue()` recursion via `_pendingRestart` now uses `Future.microtask()`.
- **Corrupted JSON crashes app** — `_getProgramsFromCache()` catches `FormatException`, deletes corrupt cache, returns graceful error.

### Quality
- Code review: 7.5/10 APPROVE (2 rounds — 4 critical + 9 major all fixed)
- QA: 33/42 AC pass, MEDIUM-HIGH confidence, 1 critical bug found and fixed
- Security audit: 9/10 PASS (1 medium fixed, 0 critical/high)
- Architecture review: 8/10 APPROVE (6 issues fixed)
- Hacker report: 7/10 (5 fixes applied, 13 edge cases verified clean)
- Final verdict: 8/10 SHIP, HIGH confidence

### Deferred
- AC-12: Merge local pending workouts into Home "Recent Workouts" list
- AC-16: Merge local pending nutrition into macro totals
- AC-18: Merge local pending weight check-ins into weight trends
- AC-36/37/38: Place SyncStatusBadge on individual cards in list views
- Background health data sync (HealthKit / Health Connect) -- separate ticket
- App performance audit (60fps, RepaintBoundary) -- separate ticket

---

## [2026-02-15] — Ambassador Enhancements (Phase 5)

### Added
- **Monthly Earnings Chart** — fl_chart BarChart on ambassador dashboard showing last 6 months of commission earnings. Skeleton loading state, empty state for zero data, accessibility semantics on chart elements.
- **Native Share Sheet** — share_plus package integration for native iOS/Android share dialog. Automatic fallback to clipboard on unsupported platforms (emulators, web). Broad exception catch handles MissingPluginException.
- **Commission Approval/Payment Workflow** — Full admin workflow for commission lifecycle (PENDING → APPROVED → PAID). Individual and bulk operations (up to 200 per request). `CommissionService` with atomic transactions, `select_for_update` concurrency control, frozen-dataclass results following `ReferralService` pattern. Admin mobile UI with confirmation dialogs, per-commission loading indicators (`Set<int>`), and "Pay All" bulk button.
- **Custom Referral Codes** — Ambassadors can set custom 4-20 character alphanumeric codes (e.g., "JOHN20"). Triple-layer validation: serializer uniqueness check (fast-path UX), DB unique constraint (ultimate guard), `IntegrityError` catch (TOCTOU race condition). Edit dialog in ambassador settings with auto-uppercase and server error display.
- **Ambassador Password Validation** — Django `validate_password()` applied to admin-created ambassador accounts via `AdminCreateAmbassadorSerializer`.
- **`BulkCommissionActionResult`** — Typed Dart model replacing raw `Map<String, dynamic>` returns from bulk commission repository methods.
- **3 extracted sub-widgets** — `AmbassadorProfileCard` (167 lines), `AmbassadorReferralsList` (117 lines), `AmbassadorCommissionsList` (261 lines) decomposed from 900-line monolithic screen.

### Changed
- `referral_code` max_length widened from 8 to 20 characters (migration 0003, `AlterField` only, fully reversible)
- Commission service logic extracted from views into dedicated `CommissionService` following `ReferralService` pattern
- `AdminAmbassadorDetailView.get()` reuses paginator's cached count instead of issuing redundant SQL COUNT queries
- Individual approve/pay buttons disabled during bulk processing to prevent conflicting actions
- Share exception catch broadened from `PlatformException` to `catch (_)` for `MissingPluginException` compatibility
- All-zero earnings chart now shows empty state instead of invisible zero-height bars
- Currency display uses comma-grouped formatting ($10,500.00 instead of 10500.00)
- Long referral codes wrapped in `FittedBox(fit: BoxFit.scaleDown)` to prevent overflow

### Security
- State transition guards on `AmbassadorCommission.approve()` and `mark_paid()` — `ValueError` for invalid state transitions
- Bulk operations capped at 200 IDs with automatic deduplication via `validate_commission_ids`
- Django password validation on admin-created ambassador accounts
- `select_for_update()` prevents concurrent double-processing of commissions
- No secrets, API keys, or credentials in any committed file

### Quality
- Code review: 8/10 APPROVE (2 rounds — all issues fixed)
- QA: 34/34 AC pass, HIGH confidence, 0 bugs
- Security audit: 9/10 PASS (3 fixes applied)
- Architecture review: 8/10 APPROVE (4 fixes applied)
- Hacker report: 7/10 (8 fixes applied)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Admin Dashboard (Completes Web Dashboard Phase 4)

### Added
- **Admin Dashboard Overview** — `/admin/dashboard` with stat cards (MRR, trainers, trainees), revenue cards (past due, upcoming payments), tier breakdown, and past due alerts with "View All" link.
- **Trainer Management** — `/admin/trainers` with searchable/filterable list, detail dialog with subscription info, activate/suspend toggle, and impersonation flow (stores admin tokens in sessionStorage).
- **Subscription Management** — `/admin/subscriptions` with multi-filter list (status, tier, past due, upcoming). Detail dialog with 4 action forms: change tier, change status, record payment, admin notes. Payment History and Change History tabs.
- **Tier Management** — `/admin/tiers` with CRUD dialogs, toggle active (optimistic update), seed defaults for empty state, delete protection for tiers with active subscriptions.
- **Coupon Management** — `/admin/coupons` with CRUD dialogs, applicable tiers multi-select, revoke/reactivate lifecycle, detail dialog with usage history. Status/type/applies_to filters. Auto-uppercase codes.
- **User Management** — `/admin/users` with role-filtered list, create admin/trainer accounts, edit users, self-deletion/self-deactivation protection.
- **Admin Layout** — Separate `(admin-dashboard)` route group with admin sidebar, admin nav links, impersonation banner.
- **`admin-constants.ts`** — Centralized TIER_COLORS, SUBSCRIPTION_STATUS_VARIANT, COUPON_STATUS_VARIANT, SELECT_CLASSES constants.
- **`format-utils.ts`** — Shared `formatCurrency()` with cached `Intl.NumberFormat`, `formatDiscount()` for coupon display.

### Changed
- **`auth-provider.tsx`** — Extended to accept ADMIN role. Sets role cookie after login for middleware routing.
- **`middleware.ts`** — Added admin route protection: checks role cookie, blocks non-admin from `/admin/*` routes.
- **`token-manager.ts`** — Added `setRoleCookie()`, optional `role` parameter on `setTokens()`, cleanup in `clearTokens()`.
- **`constants.ts`** — Added 20+ admin API URL constants.
- **`impersonation-banner.tsx`** — Restores ADMIN role cookie on end-impersonation, sets TRAINER role on start.

### Security
- Three-layer admin auth: Edge middleware (role cookie) → Layout component (server user check) → Backend API (`IsAdminUser`)
- Role cookie is client-writable (documented limitation) — backend authorization is the true security boundary
- Impersonation tokens scoped to sessionStorage (tab isolation), hard page reload on end clears React Query cache
- No secrets, XSS vectors, or IDOR vulnerabilities found

### Quality
- Code review: 8/10 APPROVE (2 rounds — 3 critical + 8 major all fixed)
- QA: 46/49 AC pass, MEDIUM confidence (3 design deviations: dialogs vs dedicated pages)
- UX audit: 16 usability + 6 accessibility fixes
- Security audit: 8.5/10 PASS (1 High fixed: middleware route protection)
- Architecture: 8/10 APPROVE (5 deduplication fixes, centralized constants)
- Hacker audit: 7/10 (13 fixes across 10 files — overflow protection, error states, same-value guards)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 4 (Trainer Program Builder)

### Added
- **Program List Page** — `/programs` route with DataTable showing program templates (name, difficulty badge, goal, duration, times used, created date). Search with `useDeferredValue`, pagination, empty state with "Create Program" CTA. Three-dot action menu with Edit (owner only), Assign to Trainee, Delete (owner only).
- **Program Builder** — Two-card layout (metadata + schedule). Name (100 chars) and description (500 chars) with live character counters and amber warning at 90%. Duration (1-52 weeks), difficulty, and goal selects with lowercase enum values matching Django TextChoices. Week tabs with horizontal scroll. 7 days per week (Mon-Sun), rest day toggle with exercise loss confirmation. Exercise picker dialog with multi-add, search, muscle group filter, truncation warning ("Showing X of Y"). Exercise rows with sets (1-20), reps (1-100 or string ranges), weight (0-9999), unit (lbs/kg), rest (0-600s). Up/down reorder. Max 50 exercises per day. Copy Week to All feature. Ctrl/Cmd+S keyboard shortcut.
- **Assignment Flow** — Dialog with trainee dropdown (up to 200 via `useAllTrainees`), date picker with local timezone default. Empty trainee state with "Send Invitation" CTA.
- **Delete Flow** — Confirmation dialog with times_used warning. Prevents close during API call. "Cannot be undone" copy.
- **`error-utils.ts`** — Shared `getErrorMessage()` for extracting DRF field-level validation error messages. Used across program-builder, assign-program-dialog, and delete-program-dialog.
- **Backend: JSON field validation** — `validate_schedule_template()` (512KB max, 52 weeks, 7 days/week structure validation) and `validate_nutrition_template()` (64KB max, dict validation) on `ProgramTemplateSerializer`.
- **Backend: SearchFilter** — Added `filter_backends = [SearchFilter]` with `search_fields = ['name', 'description']` to `ProgramTemplateListCreateView`.
- **`reconcileSchedule()`** — Syncs schedule weeks with duration when trainer changes week count. Pads new weeks with default 7-day structure, trims excess weeks with confirmation.

### Changed
- **`nav-links.tsx`** — Added Programs nav item with `Dumbbell` icon between Trainees and Invitations.
- **`constants.ts`** — Added `PROGRAM_TEMPLATES`, `programTemplateDetail(id)`, `programTemplateAssign(id)`, `EXERCISES` API URL constants.
- **`use-trainees.ts`** — `useAllTrainees()` hook moved here from `use-programs.ts` (architecture fix).
- **`program-list.tsx`** — Columns memoized with `useMemo`. Program name is clickable link to edit page for owners.
- **Backend: `ProgramTemplateSerializer`** — `is_public` and `image_url` added to `read_only_fields` (security fix).

### Accessibility
- All form inputs have visible labels, `aria-label`, and proper `htmlFor`/`id` associations
- `role="group"` with descriptive `aria-label` on exercise rows for screen reader grouping
- `aria-invalid` on whitespace-only program names with `role="alert"` error message
- Move/delete buttons include exercise name in `aria-label` (e.g., "Move Bench Press up")
- `DialogDescription` on all dialogs for screen reader context
- Focus-visible rings on all interactive elements including `<select>` elements
- Week tabs have `aria-label="Week N of M"`

### UX
- Dirty state tracking: `hasMountedRef` skips initial mount (no false "unsaved changes" warning), `beforeunload` event only when dirty, cancel button confirms when dirty
- Double-click prevention: `savingRef` guard + `<fieldset disabled={isSaving}>` disables entire form during save
- Data loss prevention: Confirmation when reducing duration (removes populated weeks), confirmation when toggling rest day with exercises
- Character counters with amber warning at 90% capacity on name and description fields
- "Back to Programs" navigation link on create and edit pages
- Truncation warning on exercise picker when results exceed page_size
- Green checkmark on already-added exercises in multi-select picker
- "Done (N added)" button text in exercise picker footer

### Quality
- Code review: 8/10 APPROVE (2 rounds — 4 critical + 8 major issues all fixed in round 1)
- QA: 27/27 AC pass, HIGH confidence (3 minor input clamping bugs fixed)
- UX audit: 9/10 (19 usability + 10 accessibility fixes)
- Security audit: 8/10 CONDITIONAL PASS (2 High fixed: JSON validation, read-only fields)
- Architecture: 9/10 APPROVE (3 fixes: hook placement, missing type field, column memoization)
- Hacker audit: 16 items fixed (multi-add dialog, Cmd+S, copy week, exercise cap, data loss confirmations)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 3 (Trainer Analytics Page)

### Added
- **Trainer Analytics Page** — New `/analytics` route with two independent sections: Adherence and Progress. Nav link added between Invitations and Notifications.
- **Adherence Section** — Three `StatCard` components (Food Logged, Workouts Logged, Protein Goal Hit) with color-coded values: green (≥80%), amber (50-79%), red (<50%). Text descriptions ("Above target", "Below target", "Needs attention") for WCAG 1.4.1 color-only compliance.
- **Adherence Bar Chart** — Horizontal recharts `BarChart` with per-trainee adherence rates sorted descending. Theme-aware colors via CSS custom properties (`--chart-2`, `--chart-4`, `--destructive`). Click-through navigation to trainee detail page. Custom YAxis tick with SVG `<title>` for truncated name tooltips.
- **Period Selector** — 7d/14d/30d tab-style radio group with WAI-ARIA radiogroup pattern: roving tabindex, arrow key navigation (Left/Right/Up/Down), `aria-checked`, `aria-label` with expanded text. `disabled` prop during initial load. Focus-visible rings and active press states.
- **Progress Section** — `DataTable` with 4 columns: trainee name (truncated with title tooltip), current weight, weight change (with TrendingUp/TrendingDown icons and goal-aligned coloring), and goal. Click-through to trainee detail.
- **`AdherencePeriod` type** — Union type `7 | 14 | 30` for compile-time safety on period selector and React Query hook.
- **`chart-utils.ts`** — Shared module with `tooltipContentStyle` and `CHART_COLORS` constants, eliminating duplication between progress-charts.tsx and adherence-chart.tsx.
- **`StatCard` `valueClassName` prop** — Extended shared component with optional `valueClassName` for colored analytics values. Backward-compatible.

### Changed
- **`nav-links.tsx`** — Added Analytics nav item with `BarChart3` icon at index 3 (between Invitations and Notifications).
- **`constants.ts`** — Added `ANALYTICS_ADHERENCE` and `ANALYTICS_PROGRESS` API URL constants.
- **`progress-charts.tsx`** — Refactored to import `tooltipContentStyle` and `CHART_COLORS` from shared `@/lib/chart-utils` instead of local definitions.

### Accessibility
- Screen-reader accessible chart: `role="img"` with descriptive `aria-label` + sr-only `<ul>` listing all trainee adherence data
- `aria-busy` attribute on sections during background refetch with sr-only live region announcements
- Skeleton loading states with `role="status"` and `aria-label`
- `aria-label="No data"` on em-dash placeholder spans in progress table
- `getIndicatorDescription()` text labels complement color-only stat card indicators (WCAG 1.4.1)

### Quality
- Code review: 9/10 APPROVE (2 rounds — 2 critical + 7 major issues all fixed in round 1)
- QA: 21/22 AC pass, HIGH confidence (1 deliberate copy improvement)
- UX audit: 9/10 (shared StatCard, WCAG fixes, responsive header, disabled period selector, sr-only live regions)
- Security audit: 9/10 PASS (0 Critical/High/Medium issues)
- Architecture: 9/10 APPROVE (extracted shared chart-utils, extended StatCard, eliminated 3 duplication instances)
- Hacker audit: 7/10 (theme-aware amber, scroll trap fix, isFetching on progress, trainee counts)
- Final verdict: 9/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 2 (Settings, Charts, Notifications, Invitations)

### Added
- **Settings Page** — Three sections: Profile (name, business name, image upload/remove), Appearance (Light/Dark/System theme toggle), Security (password change with inline Djoser error parsing). Loading skeleton, error state with retry.
- **Progress Charts** — Trainee detail Progress tab now renders three recharts visualizations: weight trend (LineChart), workout volume (BarChart), adherence (stacked BarChart). Theme-aware colors via CSS custom properties. Per-chart empty states with contextual icons. Safe date parsing via `parseISO`/`isValid`.
- **Notification Click-Through** — Notifications with `trainee_id` in data now navigate to `/trainees/{id}`. ChevronRight visual affordance for navigable notifications. Popover auto-closes on navigation. Non-navigable notifications show "Marked as read" toast.
- **Invitation Row Actions** — Three-dot dropdown menu per invitation row: Copy Code (clipboard), Resend (POST, resets expiry), Cancel (with confirmation dialog). Status-aware action visibility: PENDING shows all, EXPIRED hides Cancel, ACCEPTED/CANCELLED shows Copy only.
- **Auth `refreshUser()`** — `AuthProvider` now exposes `refreshUser()` method. Profile/image mutations call it so the header nav updates immediately without full page reload.

### Changed
- **`api-client.ts`** — Added `postFormData()` method; `buildHeaders()` skips `Content-Type: application/json` for FormData bodies (lets browser set `multipart/form-data` boundary).
- **`notification-bell.tsx`** — Controlled Popover state for programmatic close. Conditionally renders `NotificationPopover` only when open (prevents unnecessary API calls).

### Accessibility
- Theme selector implements proper ARIA radiogroup keyboard navigation (arrow keys, roving tabIndex, focus management)
- Password fields have `aria-describedby` and `aria-invalid` attributes linking to error messages
- Email field has `aria-describedby="email-hint"` for the read-only explanation
- Notification popover loading state has `role="status"` and `aria-label`
- Image upload spinner has `aria-hidden="true"`

### Quality
- Code review: 8/10 APPROVE (2 rounds — all critical/major issues fixed)
- QA: 27/28 AC pass, HIGH confidence (1 partial is pre-existing backend gap)
- UX audit: 9/10 (10 usability + 6 accessibility fixes implemented)
- Security audit: 9/10 PASS (0 Critical/High/Medium issues)
- Architecture: 9/10 APPROVE (extracted shared tooltip styles, theme-aware chart colors)
- Hacker audit: 7/10 (isDirty tracking, dropdown close-on-action, toast feedback, layout consistency fixes)

---

## [2026-02-15] — Web Trainer Dashboard (Next.js Foundation)

### Added
- **Web Trainer Dashboard** — Complete Next.js 15 + React 19 web application for trainers at `http://localhost:3000`. ~100 frontend files using shadcn/ui component library, TanStack React Query for data fetching, and Zod v4 for form validation.
- **JWT Auth System** — Login with email/password, automatic token refresh with mutex (prevents thundering herd), session cookie for Next.js middleware route protection, TRAINER role gating (non-trainer users rejected immediately), 10-second auth timeout via `Promise.race`.
- **Dashboard Page** — 4 stats cards (Total Trainees, Active Today, On Track, Pending Onboarding) in responsive grid, recent trainees table (last 10), inactive trainees alert list. Skeleton loading, error with retry, empty state with "Send Invitation" CTA.
- **Trainee Management** — Searchable paginated list with 300ms debounce, full-row click navigation, DataTable with integrated pagination ("Page X of Y (N total)"). Detail page with 3 tabs: Overview (profile, nutrition goals, programs), Activity (7/14/30 day filter with goal badges), Progress (placeholder).
- **Notification System** — Bell icon with unread badge (30s polling, "99+" cap), popover showing last 5 with "View all" link, full page with server-side "All"/"Unread" filtering via `?is_read=false`, mark individual as read, mark all as read with success/error toasts, pagination.
- **Invitation Management** — Table with color-coded status badges (Pending=amber, Accepted=green, Expired=muted, Cancelled=red), smart expired-pending detection. Create dialog with Zod validation: email, optional message (500 char limit with counter), expires days (1-30, integer step).
- **Responsive Layout** — Fixed 256px sidebar on desktop (`lg+`), Sheet drawer on mobile, header with hamburger/bell/avatar dropdown. Skip-to-content link for keyboard users.
- **Dark Mode** — Full support via CSS variables and next-themes with system preference default. All components use theme-aware color tokens.
- **Docker Integration** — Multi-stage `node:20-alpine` Dockerfile with non-root `nextjs` user (uid 1001), standalone output. Added `web` service to `docker-compose.yml` on port 3000.
- **Security Headers** — `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(), microphone=(), geolocation=()`. Removed `X-Powered-By` header.
- **Shared Components** — `DataTable<T>` (generic paginated table with row click + keyboard nav), `EmptyState` (icon + title + CTA), `ErrorState` (alert with retry), `LoadingSpinner` (configurable aria-label), `PageHeader` (title + description + actions).
- **Accessibility** — 16 WCAG fixes: `role="status"` on loading/empty states, `role="alert"` on error states, `aria-hidden="true"` on all decorative icons (10+ files), `aria-current="page"` on active nav links, `aria-label` on pagination/notification/user-menu buttons, skip-to-content link, keyboard-accessible table rows (tabIndex, Enter/Space, focus ring), `aria-label="Main navigation"` on sidebars.
- **Input Protection** — `maxLength` on all inputs (email 254, password 128, message 500), `step={1}` on integer fields, `required` attributes, double-submit prevention (`isSubmitting` / `isPending` guards).
- **`SearchFilter`** added to `TraineeListView` backend — enables `?search=` query parameter for trainee search by email, first_name, last_name.

### Changed (Backend Performance)
- **6 N+1 query patterns eliminated:**
  - `TraineeListView.get_queryset()` — Added `.select_related('profile').prefetch_related('daily_logs', 'programs')`
  - `TraineeDetailView.get_queryset()` — Added `.select_related('profile', 'nutrition_goal').prefetch_related('programs', 'activity_summaries')`
  - `TrainerDashboardView.get()` — Replaced Python loop for inactive trainees with `Max` annotation query, added prefetching
  - `TrainerStatsView.get()` — Replaced Python loop for pending_onboarding with single `.filter().count()` query
  - `AdherenceAnalyticsView.get()` — Replaced per-trainee N+1 loop with `.values().annotate(Case/When)` aggregation
  - `ProgressAnalyticsView.get()` — Added `.select_related('profile').prefetch_related('weight_checkins')`
- **4 bare `except:` clauses** replaced with specific `RelatedObjectDoesNotExist` exceptions in serializers
- **Serializer prefetch optimization** — `get_last_activity()` and `get_current_program()` iterate prefetched data in Python instead of issuing new queries
- **Query param bounds** — `days` parameter clamped to 1-365 with try/except fallback
- **TypeScript/API alignment** — `DashboardOverview.today` field added to match backend response

### Security
- No secrets in source code (full grep scan, `.env.local` gitignored)
- Three-layer auth: Next.js middleware + dashboard layout guard + AuthProvider role validation
- No XSS vectors (zero `dangerouslySetInnerHTML`, `eval`, `innerHTML` usage — React auto-escaping)
- No IDOR (backend row-level security via `parent_trainer` queryset filter on all endpoints)
- JWT in localStorage with refresh mutex (accepted SPA tradeoff, no XSS vectors to exploit)
- Cookie `Secure` flag applied consistently on both set and delete operations
- Generic error messages — no stack traces, SQL errors, or internal paths exposed
- Backend rate limiting: 30/min anonymous, 120/min authenticated
- Docker non-root user (nextjs, uid 1001)
- CORS: development allows all origins; production restricts to env-configured whitelist

### Quality
- Code review: 8/10 — APPROVE (Round 2, all 17 Round 1 issues verified fixed, 2 new major fixed post-QA)
- QA: 34/35 ACs pass initially (AC-12 fixed by UX audit), 7/7 edge cases pass — HIGH confidence
- UX audit: 8/10 — 8 usability + 16 accessibility issues fixed across 15+ files
- Security audit: 9/10 — PASS (0 Critical, 0 High, 2 Medium both fixed)
- Architecture review: 8/10 — APPROVE (10 issues including 6 N+1 patterns, all fixed)
- Hacker report: 6/10 — 3 dead UI, 9 visual bugs, 12 logic bugs found; 20 items fixed
- Overall quality: 8/10 — SHIP

---

## [2026-02-14] — Trainee Workout History + Home Screen Recent Workouts

### Added
- **Workout History API** — `GET /api/workouts/daily-logs/workout-history/` paginated endpoint returning computed summary fields (workout_name, exercise_count, total_sets, total_volume_lbs, duration_display) from workout_data JSON. `GET /api/workouts/daily-logs/{id}/workout-detail/` for full workout data with restricted serializer.
- **`WorkoutHistorySummarySerializer`** — Computes workout summaries from DailyLog.workout_data JSON blob. Handles both `exercises` and `sessions` key formats.
- **`WorkoutDetailSerializer`** — Restricted serializer exposing only id, date, workout_data, notes (excludes trainee email, nutrition_data).
- **`DailyLogService.get_workout_history_queryset()`** — Service-layer queryset builder with DB-level JSON filtering (excludes null, empty dict, empty exercises). Uses `Q` objects for `has_key` lookups and `.defer('nutrition_data')` for performance.
- **WorkoutHistoryScreen** — Paginated list with shimmer skeleton loading, pull-to-refresh, infinite scroll (200px trigger), empty state with "Start a Workout" CTA, styled error with retry.
- **WorkoutDetailScreen** — Full workout detail with real-header shimmer (uses available summary data during loading), exercise cards with sets table (set#, reps, weight, unit, completed icon), pre/post-workout survey badges with color-coded scores, error retry.
- **Home Screen Recent Workouts** — "Recent Workouts" section showing last 3 completed workouts as compact cards. 3-card shimmer loading, styled error with retry, empty state text. "See All" button navigates to full history.
- **`WorkoutDetailData` class** — Data-layer class for centralized JSON extraction logic (exercises, readiness survey, post-workout survey) with factory constructor.
- **`WorkoutHistoryCard` + `StatChip`** — Extracted widgets with responsive `Wrap` layout (prevents overflow on narrow screens).
- **`ExerciseCard`, `SurveyBadge`, `HeaderStat`, `SurveyField`** — Extracted detail widgets with theme-aware colors.
- **Route guards** — `/workout-detail` redirects to `/workout-history` if extra data is invalid.
- **Accessibility** — `Semantics` labels on all new interactive widgets (WorkoutHistoryCard, RecentWorkoutCard, ExerciseCard, SurveyBadge, HeaderStat), `liveRegion` on error/empty states, `ExcludeSemantics` to prevent duplicate announcements.
- **48 new backend tests** — Filtering (7), serialization (15), pagination (9), security (5), detail (8), edge cases (6). Tests verify auth, IDOR prevention, data leakage, and malformed JSON handling.

### Changed
- **`DailyLogService`** — Extracted `get_workout_history_queryset()` from view to service layer per project architecture conventions.
- **`WorkoutHistoryPagination`** — Custom pagination class with `page_size=20`, `max_page_size=50`.
- **Home screen** — Added `recentWorkoutsError` field to `HomeState` for distinguishing API failure from empty data. Section header "See All" uses `InkWell` with Material ripple feedback instead of `GestureDetector`.
- **`workout_history_provider.dart`** — `loadMore()` clears stale errors with `clearError: true` before retrying.
- **Test infrastructure** — Converted `workouts/tests.py` into package with `__init__.py`, `test_surveys.py`, `test_workout_history.py`.

### Security
- Both endpoints require `IsTrainee` (authenticated + trainee role)
- Row-level security via queryset filter `trainee=user` (IDOR returns 404, not 403)
- `WorkoutHistorySummarySerializer` excludes trainee, email, nutrition_data
- `WorkoutDetailSerializer` exposes only id, date, workout_data, notes
- `.defer('nutrition_data')` defense-in-depth (not loaded from DB)
- `max_page_size=50` prevents resource exhaustion
- Generic error messages — no internal details leaked
- 30 security-relevant tests verify auth, authz, IDOR, data leakage

### Quality
- Code review: 8/10 — APPROVE (Round 3, all 2 Critical + 5 Major from Round 2 fixed)
- QA: 48/48 tests pass, 1 bug found and fixed (PostgreSQL NULL semantics) — HIGH confidence
- UX audit: 8/10 — 9 usability + 7 accessibility issues fixed
- Security audit: 9.5/10 — PASS (0 Critical/High issues)
- Architecture review: 9/10 — APPROVE (2 issues fixed: service extraction, data class)
- Hacker report: 7/10 — 4 items fixed (overflow, accessibility, volume display, pagination retry)
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — AI Food Parsing + Password Change + Invitation Emails

### Added
- **AI Food Parsing Activation** — Removed "AI parsing coming soon" banner from AI Entry tab. Added meal selector (1-4) with InkWell touch feedback and Semantics labels. Added `_confirmAiEntry()` with empty meals validation, nutrition refresh after save, icon-enhanced success/error snackbars with retry action. Changed button label from "Log Food" to "Parse with AI" for clarity. Added helper text and concrete input examples.
- **Password Change Screen** — New `ChangePasswordScreen` in Settings → Security. Calls Djoser's `POST /api/auth/users/set_password/` via new `AuthRepository.changePassword()` method. Inline error under "Current Password" field for wrong password. Green success snackbar with icon + auto-pop. Network/server error handling with descriptive messages.
- **Password Strength Indicator** — Color-coded progress bar (Weak/Fair/Good/Strong) on new password field with helper text.
- **Invitation Email Service** — New `backend/trainer/services/invitation_service.py` with `send_invitation_email()`. HTML + plain text email templates with trainer name, invite code, registration URL, expiry date. XSS prevention via `django.utils.html.escape()` on all user-supplied values. URL scheme auto-detection (HTTP for localhost, HTTPS for production). URL-encoded invite codes.
- **`ApiConstants.setPassword`** — New endpoint constant for Djoser password change.
- **Expired Invitation Resend** — Resend endpoint now accepts EXPIRED invitations, resets status to PENDING, extends expiry by 7 days.
- **Accessibility Improvements** — Semantics live regions on error/clarification/preview containers. Autofill hints on password fields (`'password'`, `'newPassword'`). TextInputAction flow (next → next → done). Tooltips on show/hide password buttons. 48dp minimum touch targets on meal selector. Theme-aware colors for light/dark mode.

### Changed
- **Meal prefix on AI-parsed food** — `LoggingNotifier.confirmAndSave()` accepts optional `mealPrefix` parameter. AI-parsed foods saved with "Meal N - " prefix matching manual entry flow.
- **Password fields** — Added focus borders, error borders, `enableSuggestions: false`, `autocorrect: false` for secure input. Outlined visibility icons.
- **Login history section** — Added "PREVIEW ONLY" badge to clarify mock data.
- **Invitation resend query** — Added `select_related('trainer')` to prevent N+1 query.

### Security
- All user input HTML-escaped in invitation email templates (XSS prevention)
- URL scheme auto-detected based on domain (prevents broken links on localhost)
- Invite code URL-encoded for defense-in-depth
- TYPE_CHECKING imports with proper `User` type hints (no `type: ignore`)
- All invitation endpoints require `IsAuthenticated + IsTrainer`
- Row-level security: `trainer=request.user` on all queries
- Password change uses Djoser's built-in endpoint with Django validators

### Quality
- Code review: 9/10 — APPROVE (Round 2, 2 critical + 3 major from Round 1 all fixed)
- QA: 17/17 ACs PASS, 12/12 edge cases, 0 bugs — HIGH confidence
- UX audit: 8.5/10 — 23 usability + 8 accessibility issues fixed
- Security audit: 8.5/10 — PASS (1 CRITICAL URL scheme fixed)
- Architecture review: 10/10 — APPROVE (exemplary architecture, zero issues)
- Hacker report: 7/10 — 2 items fixed, 1 CRITICAL verified as false alarm
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — Trainee Home Experience + Password Reset

### Added
- **Password Reset Flow** — Full forgot/reset password screens using Djoser's built-in email endpoints. ForgotPasswordScreen with email input, loading state, success view with spam folder hint. ResetPasswordScreen with uid/token route params, password strength indicator, validation. Email backend configured (console for dev, SMTP for prod via env vars).
- **Weekly Workout Progress** — New `GET /api/workouts/daily-logs/weekly-progress/` endpoint returning `{total_days, completed_days, percentage, has_program}`. Home screen shows animated progress bar (hidden when no program). Data fetched in parallel with other dashboard data.
- **Food Entry Edit/Delete** — New `PUT /api/workouts/daily-logs/<id>/edit-meal-entry/` and `POST /api/workouts/daily-logs/<id>/delete-meal-entry/` endpoints with input key whitelisting, numeric validation, and automatic total recalculation. Mobile EditFoodEntrySheet bottom sheet with pre-filled form, save/delete buttons, confirmation dialog.
- **EditMealEntrySerializer / DeleteMealEntrySerializer** — Proper DRF serializers for food edit/delete input validation (architecture audit improvement).
- **Date filtering on DailyLog list** — `GET /api/workouts/daily-logs/?date=YYYY-MM-DD` now filters by date (critical fix: was silently ignoring date param).

### Changed
- **Login screen** — "Forgot password?" button now navigates to ForgotPasswordScreen (was showing "Coming soon!" snackbar).
- **Home screen notification button** — Shows info dialog ("Notifications coming soon") instead of being a dead button.
- **ProgramViewSet logging** — Removed verbose email logging, changed to debug level (architecture audit improvement).
- **Nutrition edit/delete** — Uses `refreshDailySummary()` instead of `loadInitialData()` after changes (1 API call instead of 5).
- **Weekly progress domain** — Moved `getWeeklyProgress()` from NutritionRepository to WorkoutRepository (correct domain boundary).

### Security
- Input key whitelisting on meal entry edits (prevents arbitrary JSON injection)
- DELETE-with-body changed to POST for proxy compatibility
- No email enumeration in password reset (204 regardless of email existence)
- Race condition guard (`_isEditingEntry`) prevents concurrent food edits
- Row-level security on all new endpoints (trainee can only edit own logs)

---

## [2026-02-14] — Trainer Notifications Dashboard + Ambassador Commission Webhook

### Added
- **Trainer Notification API** — 5 endpoints: `GET /api/trainer/notifications/` (paginated, `?is_read` filter), `GET /api/trainer/notifications/unread-count/`, `POST /api/trainer/notifications/<id>/read/`, `POST /api/trainer/notifications/mark-all-read/`, `DELETE /api/trainer/notifications/<id>/`. All protected by `[IsAuthenticated, IsTrainer]` with row-level security.
- **Ambassador Commission Webhook** — `_handle_invoice_paid()` creates commissions from actual Stripe invoice `amount_paid` (not cached subscription price). `_handle_checkout_completed()` handles first platform subscription payment. `_handle_subscription_deleted()` triggers `ReferralService.handle_trainer_churn()`. `_create_ambassador_commission()` helper looks up referral, validates active ambassador, extracts billing period.
- **Notification Bell Badge** — `NotificationBadge` widget on trainer dashboard with unread count (shows "99+" for >99), theme-colored, screen reader accessible.
- **Notifications Screen** — Full paginated feed with date grouping ("Today", "Yesterday", "Feb 12"), `NotificationCard` with type-based icons (7 types), unread dot, relative timestamps, swipe-to-dismiss with undo snackbar, mark-all-read with confirmation dialog.
- **Optimistic UI** — All mutations (mark-read, mark-all-read, delete) update state immediately and revert on API failure.
- **Pagination** — `AsyncNotifierProvider` with `loadMore()` guard against concurrent requests, loading indicator at bottom of list.
- **Accessibility** — `Semantics` wrappers on notification cards (read status + type + title + time), badge (count-aware label), mark-all-read button.
- **90 new tests** — 59 notification view tests (auth, permissions, row-level security, pagination, filtering, idempotency) + 31 ambassador webhook tests (commission creation, churn handling, lifecycle, edge cases).
- Database migration: `trainer/migrations/0005_*` (index optimization).

### Changed
- **Index optimization** (`trainer/models.py`) — Removed standalone `notification_type` index (never queried alone). Changed `(trainer, created_at)` to `(trainer, -created_at)` descending to match query pattern.
- **Webhook symmetry** (`payment_views.py`) — Extended `_handle_invoice_payment_failed()` and `_handle_subscription_updated()` to handle both `TraineeSubscription` and `Subscription` models, matching dual-model pattern.
- **Skeleton loader** — Replaced static containers with shared animated `LoadingShimmer` widget.
- **Empty/error states** — Both wrapped in `RefreshIndicator` + `LayoutBuilder` + `SingleChildScrollView` for pull-to-refresh.
- **Safe JSON parsing** (`trainer_notification_model.dart`) — Uses `is Map<String, dynamic>` type check instead of unsafe `as` cast for `data` field.

### Security
- No secrets in committed code (grepped all new/changed files)
- All notification endpoints authenticated + authorized (IsTrainer)
- Row-level security: every query filters `trainer=request.user`
- No IDOR: trainer A cannot read/modify trainer B's notifications
- Webhook signature verification in place (pre-existing `stripe.Webhook.construct_event`)
- Commission creation uses `select_for_update` + `UniqueConstraint` for race condition protection

### Quality
- Code review: 8/10 — APPROVE (Round 2, all Round 1 issues fixed)
- QA: 90/90 tests pass, 0 bugs — HIGH confidence
- UX audit: 8/10 — 15 improvements (shimmer, undo, accessibility, conditional buttons)
- Security audit: 9/10 — PASS (no critical/high issues)
- Architecture review: 9/10 — APPROVE (index optimization, webhook symmetry)
- Hacker report: 8/10 — 5 edge-case fixes (safe JSON cast, exception logging, clock skew guard)
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — Ambassador User Type & Referral Revenue Sharing

### Added
- **AMBASSADOR user role** — New `User.Role.AMBASSADOR` with `is_ambassador()` helper method, `IsAmbassador` and `IsAmbassadorOrAdmin` permission classes.
- **AmbassadorProfile model** — OneToOne to User with `referral_code` (unique 8-char alphanumeric, auto-generated with collision retry), `commission_rate` (DecimalField, default 0.20), `is_active`, cached `total_referrals` and `total_earnings`.
- **AmbassadorReferral model** — Tracks ambassador-to-trainer referrals with 3-state lifecycle: PENDING (registered) -> ACTIVE (first payment) -> CHURNED (cancelled), with reactivation support.
- **AmbassadorCommission model** — Monthly commission records with rate snapshot at creation time, `UniqueConstraint` on (referral, period_start, period_end) to prevent duplicates.
- **Ambassador API endpoints** — `GET /api/ambassador/dashboard/` (aggregated stats, monthly earnings, recent referrals), `GET /api/ambassador/referrals/` (paginated, status-filterable), `GET /api/ambassador/referral-code/` (code + share message).
- **Admin ambassador management API** — `GET /api/admin/ambassadors/` (search, active filter), `POST /api/admin/ambassadors/create/` (with password), `GET/PUT /api/admin/ambassadors/<id>/` (detail with paginated referrals/commissions, update rate/status).
- **ReferralService** — `process_referral_code()` (registration integration), `create_commission()` (with `select_for_update` locking and duplicate period guard), `handle_trainer_churn()` (bulk update).
- **Registration integration** — Optional `referral_code` field on `UserCreateSerializer`, restricted role choices to TRAINEE/TRAINER only (prevents ADMIN/AMBASSADOR self-registration).
- **Ambassador mobile shell** — `StatefulShellRoute` with 3 tabs: Dashboard, Referrals, Settings. Router redirect for ambassador users.
- **Ambassador dashboard screen** — Gradient earnings card, referral code card with copy/share, stats row (total/active/pending/churned), recent referrals list with status badges.
- **Ambassador referrals screen** — Filterable list (All/Active/Pending/Churned), pull-to-refresh, status badges, subscription tier, commission earned per referral.
- **Ambassador settings screen** — Profile info, commission rate (read-only), referral code, total earnings, logout with confirmation dialog.
- **Admin ambassador screens** — Searchable list with active/inactive filter, create form with password + commission rate slider, detail screen with commission history and rate editing dialog.
- **Referral code on registration** — Optional field shown when TRAINER role selected, `maxLength: 8`, `textCapitalization: characters`.
- **Accessibility** — Semantics widgets on all interactive elements, 48dp minimum touch targets (InkWell), screen reader labels for stat tiles, nav items, and referral cards.
- **Rate limiting** — Global `DEFAULT_THROTTLE_CLASSES` (anon: 30/min, user: 120/min), `RegistrationThrottle` (5/hour).
- **CORS hardening** — `CORS_ALLOW_ALL_ORIGINS` now conditional on `DEBUG`; production reads `CORS_ALLOWED_ORIGINS` from environment variable.
- Database migrations: `ambassador/migrations/0001_initial.py`, `ambassador/migrations/0002_alter_ambassadorreferral_unique_together_and_more.py`, `users/migrations/0005_alter_user_role.py`.
- New file: `backend/core/throttles.py` with `RegistrationThrottle` class.

### Changed
- `users/serializers.py` — Role choices restricted to `[(TRAINEE, 'Trainee'), (TRAINER, 'Trainer')]`, single `create_user()` call instead of two DB writes, referral code processing integrated.
- `config/urls.py` — Ambassador admin URLs mounted at `/api/admin/ambassadors/` (split from ambassador app URLs).
- `config/settings.py` — Added `ambassador` to `INSTALLED_APPS`, throttle classes, conditional CORS.
- `core/permissions.py` — Added `IsAmbassador` and `IsAmbassadorOrAdmin` permission classes.

### Security
- Registration role escalation prevention (ADMIN/AMBASSADOR roles blocked from self-registration)
- Race condition protection: `select_for_update()` on commission creation, `IntegrityError` retry on code generation
- DB-level `UniqueConstraint` on (referral, period_start, period_end) prevents duplicate commissions
- Cryptographic referral code generation (`secrets.choice`, 36^8 = 2.8 trillion code space)
- No IDOR: all ambassador queries filter by `request.user`

### Quality
- Code review: 3 rounds. Round 1: BLOCK (5/10) -> 12 fixes. Round 2: REQUEST CHANGES (7.5/10) -> 3 fixes. Round 3: APPROVE.
- QA: 25/25 acceptance criteria PASS (4 URL routing issues fixed in QA round)
- UX audit: 8/10 — 12 usability + 10 accessibility issues fixed
- Security audit: 9/10 — PASS (5 critical/high issues fixed)
- Architecture review: 8/10 — APPROVE (6 issues fixed: atomicity, DRY, pagination, typed models, bulk updates)
- Hacker report: 6/10 chaos — 10 items fixed (unusable password, crash bug, missing commission display, filter persistence)
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-14] — White-Label Branding Infrastructure

### Added
- **TrainerBranding model** — OneToOne to User with `app_name`, `primary_color`, `secondary_color`, `logo` (ImageField). Auto-creates with defaults via `get_or_create_for_trainer()` classmethod.
- **branding_service.py** — Service layer for image validation and logo operations. `validate_logo_image()` performs 5-layer defense-in-depth validation (content-type, file size, Pillow format, dimensions, filename). `upload_trainer_logo()` and `remove_trainer_logo()` handle business logic.
- **Trainer API endpoints** — `GET/PUT /api/trainer/branding/` for config management, `POST/DELETE /api/trainer/branding/logo/` for logo upload/removal. IsTrainer permission, row-level security via OneToOne.
- **Trainee API endpoint** — `GET /api/users/my-branding/` returns parent trainer's branding or defaults. IsTrainee permission.
- **BrandingScreen** — Trainer-facing branding editor with app name field, 12-preset color picker (primary + secondary), logo upload/preview, and live preview card. Extracted into 3 sub-widgets: `BrandingPreviewCard`, `BrandingLogoSection`, `BrandingColorSection`.
- **Theme branding override** — `ThemeNotifier.applyTrainerBranding()` / `clearTrainerBranding()` with SharedPreferences caching (hex-string format). Trainer's primary/secondary colors override default theme throughout the app.
- **Dynamic splash screen** — Shows trainer's logo (with loading spinner) and app name instead of hardcoded "FitnessAI" when branding is configured.
- **Shared branding sync** — `BrandingRepository.syncTraineeBranding()` static method shared between splash and login screens. Fetches, applies, and caches branding.
- **Unsaved changes guard** — `PopScope` wrapper shows confirmation dialog when navigating away with unsaved changes.
- **Reset to defaults** — AppBar overflow menu option to reset all branding to FitnessAI defaults.
- **Accessibility labels** — Semantics wrappers on all interactive branding elements (buttons, color swatches, logo image, preview card).
- **Luminance-based contrast** — Color picker indicators and preview button text adapt based on color brightness for WCAG compliance.
- **84 comprehensive backend tests** — Model, views, serializer, permissions, row-level security, edge cases (unicode, rapid updates, multi-trainer isolation).
- Database migration: `trainer/migrations/0004_add_trainer_branding.py`.
- **Dead settings buttons fixed** — 5 empty `onTap` handlers in settings_screen.dart now show "Coming soon!" SnackBars.

### Changed
- `splash_screen.dart` — Uses `ref.watch(themeProvider)` for reactive branding updates during animation. Added `loadingBuilder` for logo network images.
- `login_screen.dart` — Fetches branding after trainee login via shared `syncTraineeBranding()`.
- `theme_provider.dart` — Extended `AppThemeState` with `trainerBranding`, `effectivePrimary`, `effectivePrimaryLight`. `TrainerBrandingTheme` uses hex-string format for consistent caching.
- `branding_repository.dart` — All methods return typed `BrandingResult` class instead of `Map<String, dynamic>`. Specific exception catches (`DioException`, `FormatException`).

### Security
- UUID-based filenames for logo uploads (prevents path traversal)
- HTML tag stripping in `validate_app_name()` (prevents stored XSS)
- File size bypass fix (`is None or` instead of `is not None and`)
- Generic error messages (no internal details leaked)
- 5-layer image validation (content-type + Pillow format + size + dimensions + filename)

### Quality
- Code review: 8/10 — APPROVE (Round 2, all 17 Round 1 issues fixed)
- QA: 84/84 tests pass, 0 bugs — HIGH confidence
- UX audit: 8/10 — 9 issues fixed
- Security audit: 9/10 — PASS (5 issues fixed)
- Architecture review: 8.5/10 — APPROVE (service layer extracted)
- Hacker report: 7/10 — 12 items fixed
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-14] — Trainer-Selectable Workout Layouts

### Added
- **WorkoutLayoutConfig model** — OneToOne per trainee with layout_type (classic/card/minimal), config_options JSONField, and configured_by FK for audit trail.
- **Trainer API endpoints** — `GET/PUT /api/trainer/trainees/<id>/layout-config/` with auto-create default and row-level security (parent_trainer check).
- **Trainee API endpoint** — `GET /api/workouts/my-layout/` with IsTrainee permission and graceful fallback to 'classic' when no config exists.
- **ClassicWorkoutLayout widget** — All exercises in scrollable ListView with full sets tables, previous weight/reps, add set, and complete buttons.
- **MinimalWorkoutLayout widget** — Compact collapsible tiles with circular progress indicators, expand/collapse, and quick-complete.
- **Workout Display section** in trainer's trainee detail Overview tab — segmented control with Classic/Card/Minimal options, optimistic update with rollback on failure.
- Error state with retry button on layout picker when API fetch fails.
- `validate_config_options()` on serializer — rejects non-dict and oversized (>2048 char) payloads.
- Database migration: `trainer/migrations/0003_add_workout_layout_config.py`.

### Changed
- `active_workout_screen.dart` — Added `_layoutType` state variable and `_buildExerciseContent` switch statement to render Classic/Card/Minimal based on API config.
- Card layout uses existing `_ExerciseCard` PageView (no new widget needed).

### Quality
- Code review: 9/10 backend, 8.5/10 mobile — APPROVE (Round 2)
- QA: 13/13 acceptance criteria PASS, Confidence HIGH
- Security audit: 9/10 — PASS
- Architecture review: 8.6/10 — APPROVE
- UX audit: 7.5/10 — Fixes applied
- Hacker report: 7.5/10 — 4 issues fixed
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-13] — Fix All 5 Trainee-Side Workout Bugs

### Fixed
- **CRITICAL — Workout data now persists to database.** `PostWorkoutSurveyView` writes to `DailyLog.workout_data` via `_save_workout_to_daily_log()` with `transaction.atomic()` and `get_or_create`. Multiple workouts per day merge into a `sessions` list while preserving a flat `exercises` list for backward compatibility.
- **HIGH — Trainer notifications now fire correctly.** Changed `getattr(user, 'trainer', None)` to `user.parent_trainer` in both `ReadinessSurveyView` and `PostWorkoutSurveyView`. Created missing `TrainerNotification` database migration.
- **HIGH — Real program schedules shown instead of sample data.** Removed `_generateSampleWeeks()` and `_getSampleExercises()` fallbacks from workout provider. Proper empty states for: no programs assigned, empty schedule, no workouts this week.
- **MEDIUM — Debug print statements removed.** All 15+ `print('[WorkoutRepository]...')` statements removed from `workout_repository.dart`.
- **MEDIUM — Program switcher implemented.** Bottom sheet with full program list, active program indicator, snackbar confirmation, and `WorkoutNotifier.switchProgram()` for state update.

### Added
- Comprehensive Django test suite: 10 tests covering workout persistence, merge logic, trainer notifications, edge cases, and auth.
- Error state UI with retry button on workout log screen.
- Accessibility tooltips on icon buttons in workout log header.
- `TrainerNotification` database migration (`trainer/migrations/0002_add_trainer_notification.py`).

### Removed
- ~130 lines of hardcoded sample workout data (`_generateSampleWeeks`, `_getSampleExercises`).
- 2 stale TODO comments in `active_workout_screen.dart` that falsely suggested code was unimplemented.

### Changed
- `DailyLog.workout_data` JSON schema extended with `sessions` array to support multiple workouts per day (backward compatible).

### Quality
- Security audit: 9/10 — PASS
- Architecture review: 8/10 — APPROVE
- UX audit: 7/10 — Acceptable
- Overall quality: 8/10 — SHIP

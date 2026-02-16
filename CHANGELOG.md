# Changelog

All notable changes to the FitnessAI platform are documented in this file.

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

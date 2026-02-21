# PRODUCT_SPEC.md — FitnessAI Product Specification

> Living document. Describes what the product does, what's built, what's broken, and what's next.
> Last updated: 2026-02-20 (Pipeline 24: In-App Message Search)

---

## 1. Product Vision

FitnessAI is a **white-label fitness platform** that personal trainers purchase to manage their client base. Trainers assign programs, track nutrition, monitor progress, and communicate with trainees — all powered by AI that understands natural language logging.

**Who pays:** Trainers subscribe via Stripe Connect. Each trainer is a mini-business on the platform.
**Who uses:** Trainees (the trainer's clients) use the mobile app daily. Trainers use it for management. Admins oversee everything.

---

## 2. User Roles

### 2.1 Admin (Super Admin)
- Platform owner / Shayesteh Inc staff
- Manages all trainers, subscription tiers, coupons, and platform settings
- Can impersonate any trainer to debug issues
- Sees platform-wide analytics and revenue

### 2.2 Trainer
- Paying customer of the platform
- Creates workout programs (weekly schedules with exercises, sets, reps, weights)
- Assigns programs to trainees
- Sets nutrition goals (macros, calories) per trainee — can override AI suggestions
- Receives notifications when trainees start/finish workouts
- Has AI assistant for program design and trainee communication
- Can impersonate trainees to see their experience
- Manages pricing and Stripe Connect for accepting payments from trainees

### 2.3 Trainee
- End user / trainer's client
- Logs workouts (via structured UI or natural language AI input)
- Tracks nutrition (food logging, macro tracking, weight check-ins)
- Completes readiness surveys before workouts and feedback surveys after
- Views assigned program schedule
- Subscribes to trainer via Stripe

### 2.4 Ambassador
- Recruited by admin to sell the platform to trainers
- Earns monthly commission (configurable rate, default 20%) on each referred trainer's subscription
- Has dedicated dashboard showing referral stats, earnings, and recent referrals
- Referral code system: auto-generated or custom codes (4-20 chars, alphanumeric), shared via native share sheet or clipboard
- Three referral states: PENDING (registered) → ACTIVE (first payment) → CHURNED (cancelled)
- Commission rate snapshot at time of charge — admin rate changes don't affect historical commissions

---

## 3. Feature Inventory

### 3.1 Authentication & Onboarding
| Feature | Status | Notes |
|---------|--------|-------|
| Email-only registration (no username) | ✅ Done | Djoser + JWT |
| JWT auth with refresh tokens | ✅ Done | |
| Password reset via email | ✅ Done | Shipped 2026-02-14: Forgot/Reset screens, Djoser email integration, password strength indicator |
| Password change (in-app) | ✅ Done | Shipped 2026-02-14: Settings → Security → Change Password, calls Djoser set_password, autofill hints, strength indicator |
| 4-step onboarding wizard | ✅ Done | About You → Activity → Goal → Diet |
| Apple/Google social auth | 🟡 Partial | Backend configured, mobile not wired |
| Server URL configuration | ✅ Done | For multi-deployment support |

### 3.2 Workout System
| Feature | Status | Notes |
|---------|--------|-------|
| Exercise bank (system + trainer-custom) | ✅ Done | Images, video URL, muscle groups, tags |
| Program builder (trainer) | ✅ Done | Week editor, exercise selection, sets/reps/weight |
| Program templates | ✅ Done | Save and reuse programs across trainees |
| Program assignment | ✅ Done | Trainer assigns program to trainee |
| Program schedule display (trainee) | ✅ Done | Fixed 2026-02-13: Real programs shown, empty states for missing schedules |
| Active workout screen | ✅ Done | Fixed 2026-02-13: Workout data persists to DailyLog.workout_data |
| Readiness survey (pre-workout) | ✅ Done | Fixed 2026-02-13: Trainer notification fires correctly via parent_trainer |
| Post-workout survey | ✅ Done | Fixed 2026-02-13: Data saves + notification fires |
| Workout calendar / history | ✅ Done | Shipped 2026-02-14: Paginated workout history API, history screen with infinite scroll, detail screen with exercises/sets/surveys, home screen recent workouts section |
| Program switcher | ✅ Done | Fixed 2026-02-13: Bottom sheet with active indicator + snackbar |
| Trainer-selectable workout layouts | ✅ Done | Shipped 2026-02-14: Classic / Card / Minimal per trainee |
| Missed day handling | ✅ Done | Skip or push (shifts program dates) |

### 3.3 Nutrition System
| Feature | Status | Notes |
|---------|--------|-------|
| Daily macro tracking | ✅ Done | Protein, carbs, fat, calories |
| Food search & logging | ✅ Done | |
| AI natural language food parsing | ✅ Done | "Had 2 eggs and toast" → structured macro data. Shipped 2026-02-14: Activated UI (removed "coming soon" banner), meal selector, confirm flow |
| Nutrition goals per trainee | ✅ Done | Trainer can set/override |
| Macro presets (Training Day, Rest Day) | ✅ Done | |
| Weekly nutrition plans | ✅ Done | Carb cycling support |
| Weight check-ins | ✅ Done | |
| Weight trend charts | ✅ Done | |
| Food entry edit/delete | ✅ Done | Shipped 2026-02-14: Edit bottom sheet, backend endpoints with input whitelisting |
| Weekly workout progress | ✅ Done | Shipped 2026-02-14: Animated progress bar on home screen, API-driven |

### 3.4 Trainer Dashboard
| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard overview (stats, activity) | ✅ Done | |
| Trainee list | ✅ Done | |
| Trainee detail (progress, adherence) | ✅ Done | |
| Trainee invitation system | ✅ Done | Email-based invite codes. Shipped 2026-02-14: Invitation emails with HTML/text, XSS protection, resend for expired |
| Trainee goal editing | ✅ Done | |
| Trainee removal | ✅ Done | |
| Impersonation (log in as trainee) | ✅ Done | With audit trail |
| AI chat assistant | ✅ Done | Uses trainee context for personalized advice |
| Adherence analytics | ✅ Done | |
| Progress analytics | ✅ Done | |
| Revenue analytics | ✅ Done | Shipped 2026-02-20 (Pipeline 28): MRR, period revenue, subscriber/payment tables, monthly chart |
| CSV data export | ✅ Done | Shipped 2026-02-21 (Pipeline 29): Export payments, subscribers, trainees as CSV with CSV injection protection |
| Trainer notifications | ✅ Done | Fixed 2026-02-13: Uses parent_trainer, migration created |
| Trainer notifications dashboard | ✅ Done | Shipped 2026-02-14: In-app notification feed with pagination, mark-read, swipe-to-dismiss, badge count |

### 3.5 Admin Dashboard
| Feature | Status | Notes |
|---------|--------|-------|
| Platform dashboard | ✅ Done | |
| Trainer management | ✅ Done | |
| User management | ✅ Done | Create, edit, view all users |
| Subscription tier management | ✅ Done | |
| Coupon management | ✅ Done | |
| Past due subscriptions | ✅ Done | |
| Upcoming payments | ✅ Done | |

### 3.6 Payments
| Feature | Status | Notes |
|---------|--------|-------|
| Stripe Connect onboarding (trainer) | ✅ Done | Trainer gets own Stripe account |
| Trainer pricing management | ✅ Done | |
| Trainee subscription checkout | ✅ Done | |
| Trainer payment history | ✅ Done | |
| Trainer coupons | ✅ Done | |

### 3.7 White-Label Branding
| Feature | Status | Notes |
|---------|--------|-------|
| TrainerBranding model | ✅ Done | OneToOne to User, app_name, primary/secondary colors, logo |
| Trainer branding screen | ✅ Done | App name, 12-preset color picker, logo upload/preview |
| Trainee branding application | ✅ Done | Fetched on login/splash, cached in SharedPreferences |
| Dynamic splash screen | ✅ Done | Shows trainer's logo and app name |
| Theme color override | ✅ Done | Trainer's primary/secondary override default indigo |
| Logo upload with validation | ✅ Done | 5-layer: content-type, size, Pillow format, dimensions, UUID filename |
| Branding API (trainer) | ✅ Done | GET/PUT /api/trainer/branding/, POST/DELETE branding/logo/ |
| Branding API (trainee) | ✅ Done | GET /api/users/my-branding/ |
| Unsaved changes guard | ✅ Done | PopScope warning dialog on back navigation |
| Reset to defaults | ✅ Done | AppBar overflow menu option |

### 3.8 Ambassador System
| Feature | Status | Notes |
|---------|--------|-------|
| AMBASSADOR user role | ✅ Done | Added to User.Role enum with is_ambassador() helper |
| AmbassadorProfile model | ✅ Done | OneToOne to User, referral_code, commission_rate, cached stats |
| AmbassadorReferral model | ✅ Done | Tracks ambassador→trainer referrals with 3-state lifecycle |
| AmbassadorCommission model | ✅ Done | Monthly commission records with rate snapshot |
| Ambassador dashboard API | ✅ Done | GET /api/ambassador/dashboard/ with aggregated stats |
| Ambassador referrals API | ✅ Done | GET /api/ambassador/referrals/ with pagination + status filter |
| Ambassador referral code API | ✅ Done | GET /api/ambassador/referral-code/ with share message |
| Admin ambassador management | ✅ Done | List, create, detail, update (commission rate, active status) |
| Referral code on registration | ✅ Done | Optional field, silently ignored if invalid |
| Commission creation service | ✅ Done | ReferralService with select_for_update, duplicate guards |
| Ambassador commission webhook | ✅ Done | Shipped 2026-02-14: Stripe webhook creates commissions from invoice.paid, handles churn on subscription.deleted |
| Ambassador mobile shell | ✅ Done | 3-tab navigation: Dashboard, Referrals, Settings |
| Ambassador dashboard screen | ✅ Done | Earnings card, referral code + share, stats, recent referrals |
| Ambassador referrals screen | ✅ Done | Filterable list with status badges, tier, commission |
| Ambassador settings screen | ✅ Done | Profile info, commission rate, earnings, logout |
| Admin ambassador screens | ✅ Done | List with search/filter, create with password, detail with commissions |
| Monthly earnings chart | ✅ Done | Shipped 2026-02-15: fl_chart BarChart with last 6 months, skeleton loading, empty state, accessibility semantics |
| Native share sheet | ✅ Done | Shipped 2026-02-15: share_plus for native iOS/Android share, clipboard fallback on unsupported platforms |
| Commission approval workflow | ✅ Done | Shipped 2026-02-15: Individual + bulk (200 cap) approve/pay, CommissionService with select_for_update, state transition guards, admin mobile UI with confirmation dialogs |
| Custom referral codes | ✅ Done | Shipped 2026-02-15: Ambassador-chosen 4-20 char codes, triple-layer validation (serializer + DB unique + IntegrityError catch), settings edit dialog |
| Ambassador password reset | ✅ Done | Shipped 2026-02-15: Django password validation on admin-created ambassador accounts |

### 3.9 Web Trainer Dashboard
| Feature | Status | Notes |
|---------|--------|-------|
| Next.js 15 + React 19 foundation | ✅ Done | Shipped 2026-02-15: shadcn/ui, TanStack React Query, Zod v4 |
| JWT auth with auto-refresh | ✅ Done | Shipped 2026-02-15: Login, refresh mutex, session cookie for middleware, TRAINER role gating |
| Dashboard (stats + trainees) | ✅ Done | Shipped 2026-02-15: 4 stats cards, recent trainees table, inactive trainees alert list |
| Trainee list with search + pagination | ✅ Done | Shipped 2026-02-15: Debounced search (300ms), full-row click, DataTable with pagination |
| Trainee detail with tabs | ✅ Done | Shipped 2026-02-15: Overview (profile, nutrition goals, programs), Activity (7/14/30 day filter), Progress (placeholder) |
| Notification system | ✅ Done | Shipped 2026-02-15: Bell badge with 30s polling, popover with last 5, full page with server-side unread filter, mark as read/all |
| Invitation management | ✅ Done | Shipped 2026-02-15: Table with status badges, create dialog with Zod validation, email + expiry + message fields |
| Responsive layout + dark mode | ✅ Done | Shipped 2026-02-15: Fixed sidebar (desktop), sheet drawer (mobile), dark mode via CSS variables + next-themes |
| Docker integration | ✅ Done | Shipped 2026-02-15: Multi-stage node:20-alpine build, non-root user, port 3000 |
| Security headers | ✅ Done | Shipped 2026-02-15: X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy |
| Settings page (profile, appearance, security) | ✅ Done | Shipped 2026-02-15: Profile edit (name, business name, image upload/remove), theme toggle (Light/Dark/System), password change with Djoser error parsing |
| Progress charts tab | ✅ Done | Shipped 2026-02-15: Weight trend (line), volume (bar), adherence (stacked bar) via recharts. Theme-aware colors, per-chart empty states |
| Notification click-through navigation | ✅ Done | Shipped 2026-02-15: Notifications with trainee_id navigate to trainee detail. ChevronRight affordance, popover auto-close, "Marked as read" toast for non-navigable |
| Invitation row actions | ✅ Done | Shipped 2026-02-15: Copy code, resend, cancel with confirmation dialog. Status-aware visibility (PENDING/EXPIRED/ACCEPTED/CANCELLED) |
| Trainer analytics page | ✅ Done | Shipped 2026-02-15: Adherence section (3 stat cards, horizontal bar chart, 7/14/30d period selector) + Progress section (trainee table with weight change, goal alignment). Theme-aware chart colors, WCAG accessible |
| Trainer announcements (web) | ✅ Done | Shipped 2026-02-19: Full CRUD with pin sort, character counters, format toggle, skeleton loading |
| Trainer AI chat (web) | ✅ Done | Shipped 2026-02-19: Chat interface with trainee selector, suggestion chips, clear dialog, provider check |
| Trainer branding (web) | ✅ Done | Shipped 2026-02-19: Color pickers (12 presets), hex validation, logo upload/remove, live preview, unsaved changes guard |
| Exercise bank (web) | ✅ Done | Shipped 2026-02-19: Responsive grid, debounced search, muscle group filters, create/detail dialogs |
| Program assignment (web) | ✅ Done | Shipped 2026-02-19: Assign/change dialog on trainee detail |
| Edit trainee goals (web) | ✅ Done | Shipped 2026-02-19: 4 macro fields with min/max validation and inline errors |
| Remove trainee (web) | ✅ Done | Shipped 2026-02-19: Confirmation dialog with "REMOVE" text match |
| Subscription management (web) | ✅ Done | Shipped 2026-02-19: Stripe Connect 3-state flow, plan overview |
| Calendar integration (web) | ✅ Done | Shipped 2026-02-19: Google auth popup, connection cards, events list |
| Layout config (web) | ✅ Done | Shipped 2026-02-19: 3 radio-style options with optimistic update |
| Impersonation (web) | 🟡 Partial | Shipped 2026-02-19: Button + confirm dialog exist, token swap deferred to backend integration |
| Mark missed day (web) | ✅ Done | Shipped 2026-02-19: Skip/push radio, date picker, program selector |
| Feature requests (web) | ✅ Done | Shipped 2026-02-19: Vote toggle, status filters, create dialog, comment hooks |
| Leaderboard settings (web) | ✅ Done | Shipped 2026-02-19: Toggle switches with optimistic update |
| Admin ambassador management (web) | ✅ Done | Shipped 2026-02-19: Server-side search, CRUD, commission actions, bulk operations |
| Admin upcoming/past due (web) | ✅ Done | Shipped 2026-02-19: Lists with severity color coding |
| Admin settings (web) | ✅ Done | Shipped 2026-02-19: Platform config, security, profile/appearance/security sections |
| Ambassador dashboard (web) | ✅ Done | Shipped 2026-02-19: Earnings cards, referral code, recent referrals |
| Ambassador referrals (web) | ✅ Done | Shipped 2026-02-19: Status filter, pagination |
| Ambassador payouts (web) | ✅ Done | Shipped 2026-02-19: Stripe Connect 3-state setup, history table |
| Ambassador settings (web) | ✅ Done | Shipped 2026-02-19: Profile, referral code edit with validation |
| Ambassador auth & routing (web) | ✅ Done | Shipped 2026-02-19: Middleware routing, layout with auth guards |
| Login page redesign | ✅ Done | Shipped 2026-02-19: Two-column layout, animated gradient, floating icons, framer-motion stagger, prefers-reduced-motion |
| Page transitions | ✅ Done | Shipped 2026-02-19: PageTransition wrapper with fade-up animation |
| Skeleton loading | ✅ Done | Shipped 2026-02-19: Content-shaped skeletons on all pages |
| Micro-interactions | ✅ Done | Shipped 2026-02-19: Button active:scale, card-hover utility with reduced-motion query |
| Dashboard trend indicators | ✅ Done | Shipped 2026-02-19: StatCard with TrendingUp/TrendingDown icons |
| Error/empty states (web) | ✅ Done | Shipped 2026-02-19: ErrorState with retry, EmptyState with contextual icons and action CTAs |
| E2E test suite (Playwright) | ✅ Done | Shipped 2026-02-19: 19 test files, 5 browser targets, auth/trainer/admin/ambassador/responsive/dark mode coverage |
| Macro preset management (web) | ✅ Done | Shipped 2026-02-21 (Pipeline 30): CRUD presets per trainee, copy-to-trainee, default toggle, calorie mismatch warning, full a11y |

### 3.10 Social & Community
| Feature | Status | Notes |
|---------|--------|-------|
| Trainer announcements (CRUD) | ✅ Done | Shipped 2026-02-16: Trainer create/edit/delete announcements, pinned support, swipe-to-delete with confirmation |
| Trainee announcement feed | ✅ Done | Shipped 2026-02-16: List with pinned indicators, unread count badge on home screen bell, mark-read on open |
| Achievement/badge system | ✅ Done | Shipped 2026-02-16: 15 predefined badges across 5 criteria types (workout count, workout streak, weight check-in streak, nutrition streak, program completed) |
| Achievement hooks | ✅ Done | Shipped 2026-02-16: Auto-check after workout completion, weight check-in, nutrition logging. Fire-and-forget pattern. |
| Achievement screen | ✅ Done | Shipped 2026-02-16: 3-column badge grid with earned/locked states, detail bottom sheet, progress summary |
| Community feed | ✅ Done | Shipped 2026-02-16: Trainer-scoped community posts with pull-to-refresh, infinite scroll, compose bottom sheet |
| Reaction system | ✅ Done | Shipped 2026-02-16: Fire/thumbs_up/heart toggle with optimistic updates and error rollback |
| Auto-posts | ✅ Done | Shipped 2026-02-16: Automated community posts on workout completion and achievement earning |
| Community feed moderation | ✅ Done | Shipped 2026-02-16: Author delete + trainer moderation via impersonation |
| Achievement toast on new badge | 🟡 Partial | Backend returns new_achievements data; mobile toast wiring deferred to workout flow update |
| Leaderboards | ✅ Done | Shipped 2026-02-16: Trainer-configurable ranked leaderboards with workout count and streak metrics, dense ranking, opt-in/opt-out, skeleton loading, empty/error states |
| Push notifications (FCM) | ✅ Done | Shipped 2026-02-16: Firebase Cloud Messaging with device token management, announcement/comment notifications, platform-specific detection |
| Rich text / markdown | ✅ Done | Shipped 2026-02-16: Content format support on posts and announcements with flutter_markdown rendering |
| Image attachments | ✅ Done | Shipped 2026-02-16: Multipart image upload (JPEG/PNG/WebP, 5MB), UUID filenames, full-screen pinch-to-zoom viewer, client/server validation |
| Comment threads | ✅ Done | Shipped 2026-02-16: Flat comment system with pagination, author/trainer delete, real-time count updates, push notifications |
| Real-time WebSocket | ✅ Done | Shipped 2026-02-16: Django Channels consumer with JWT auth, 4 broadcast event types, exponential backoff reconnection |
| Stripe Connect ambassador payouts | ✅ Done | Shipped 2026-02-16: Express account onboarding, admin-triggered payouts with race condition protection, payout history with status badges |

### 3.12 Direct Messaging
| Feature | Status | Notes |
|---------|--------|-------|
| Messaging Django app (models, services, views) | ✅ Done | Shipped 2026-02-19: Conversation + Message models, 6 REST endpoints, row-level security |
| Trainer-to-trainee 1:1 messaging | ✅ Done | Shipped 2026-02-19: Send/receive messages, auto-create conversations, soft-archive on removal |
| WebSocket real-time (mobile) | ✅ Done | Shipped 2026-02-19: DirectMessageConsumer with JWT auth, typing indicators, read receipts |
| HTTP polling real-time (web) | ✅ Done | Shipped 2026-02-19: 5s message polling, 15s conversation polling (fallback when WS disconnected) |
| Conversation list | ✅ Done | Shipped 2026-02-19: Sorted by recency, last message preview (annotated), unread count, avatar |
| Message pagination | ✅ Done | Shipped 2026-02-19: 20 per page with infinite scroll |
| Push notifications | ✅ Done | Shipped 2026-02-19: FCM push on new message to offline recipient |
| Unread badge | ✅ Done | Shipped 2026-02-19: Mobile nav shells + web sidebar (desktop + mobile), 99+ cap |
| Read receipts | ✅ Done | Shipped 2026-02-19: Double checkmark pattern on mobile + web |
| Typing indicators | ✅ Done | Shipped 2026-02-19: Mobile (WebSocket) + Web (WebSocket, Pipeline 22). "Name is typing..." with animated dots |
| Character counter | ✅ Done | Shipped 2026-02-19: 2000 char max, counter at 90%, server validation |
| Impersonation read-only guard | ✅ Done | Shipped 2026-02-19: Admin impersonating trainer cannot send messages |
| Rate limiting | ✅ Done | Shipped 2026-02-19: 30 messages/minute via ScopedRateThrottle |
| Conversation archival on trainee removal | ✅ Done | Shipped 2026-02-19: Soft-archive, SET_NULL FK, messages preserved for audit |
| Web messages page | ✅ Done | Shipped 2026-02-19: Split-panel layout, responsive (single-panel on mobile), new conversation flow |
| Web trainee detail "Message" button | ✅ Done | Shipped 2026-02-19: Navigates to messages page with trainee param |
| Mobile trainee detail "Send Message" | ✅ Done | Shipped 2026-02-19: Wired existing dead button to new-conversation screen |
| WebSocket real-time (web) | ✅ Done | Shipped 2026-02-19 (Pipeline 22): Replaces HTTP polling with WebSocket — instant message delivery, typing indicators, read receipts, graceful HTTP polling fallback, connection state banners, exponential backoff reconnection, tab visibility reconnect |
| E2E tests | ✅ Done | Shipped 2026-02-19: 7 Playwright tests for messaging |
| Message editing (15-min window) | ✅ Done | Shipped 2026-02-19 (Pipeline 23): PATCH endpoint, sender-only, edit window, optimistic updates, "(edited)" indicator |
| Message soft-deletion | ✅ Done | Shipped 2026-02-19 (Pipeline 23): DELETE endpoint, sender-only, no time limit, image file cleanup, "[This message was deleted]" placeholder |
| Edit/delete WebSocket broadcast | ✅ Done | Shipped 2026-02-19 (Pipeline 23): chat.message_edited and chat.message_deleted events, real-time sync across mobile and web |
| Mobile edit/delete UI | ✅ Done | Shipped 2026-02-19 (Pipeline 23): Long-press context menu, edit bottom sheet, grayed-out expired edit, delete confirmation dialog |
| Web edit/delete UI | ✅ Done | Shipped 2026-02-19 (Pipeline 23): Hover action icons, inline edit mode (Esc/Cmd+Enter), delete confirmation, ARIA accessibility |
| Message search | ✅ Done | Shipped 2026-02-20 (Pipeline 24): GET /api/messaging/search/?q=&page=, case-insensitive icontains, row-level security, web search UI with Cmd/Ctrl+K, debounced input, highlighted results, scroll-to-message, 42 tests |

### 3.11 Other
| Feature | Status | Notes |
|---------|--------|-------|
| Calendar integration (Google/Microsoft) | 🟡 Partial | Backend API done, mobile basic |
| Feature request board | ✅ Done | In-app submission + voting |
| MCP server (Claude Desktop) | ✅ Done | Trainer can query data via Claude Desktop |
| TV mode | ❌ Placeholder | Screen exists but empty |
| Community feed (replaces Forums) | ✅ Done | Shipped 2026-02-16: Trainer-scoped feed with text posts, reactions (fire/thumbs_up/heart), auto-posts for workouts and achievements, optimistic updates, infinite scroll, image attachments, markdown, comments, real-time WebSocket updates |
| Offline-first with local DB | ✅ Done | Shipped 2026-02-15: Drift (SQLite) local database, sync queue with FIFO/exponential backoff, connectivity monitoring with 2s debounce, offline-aware repositories for workouts/nutrition/weight, program caching, 409 conflict detection, UI banners (offline/syncing/synced/failed), failed sync bottom sheet, logout warning |

---

## 4. Current Sprint: Foundation Fix + Layout + Branding + Ambassador

### 4.1 Bug Fixes — COMPLETED (2026-02-13)

All 5 trainee-side bugs have been fixed and shipped.

**BUG-1 [CRITICAL]: Workout data never persists** — ✅ FIXED
- Added `_save_workout_to_daily_log()` method with `transaction.atomic()` + `get_or_create`
- Multiple workouts per day merge via `sessions` list
- 5 backend tests covering save, merge, empty exercises, and error cases

**BUG-2 [HIGH]: Trainer notifications never fire** — ✅ FIXED
- Changed `getattr(user, 'trainer', None)` to `user.parent_trainer` in both views
- Created missing `TrainerNotification` migration (table never existed in DB)
- 4 backend tests covering readiness/post-workout notifications

**BUG-3 [HIGH]: Sample data shown instead of real programs** — ✅ FIXED
- Removed `_generateSampleWeeks()` and `_getSampleExercises()` entirely
- Returns `[]` for null/empty schedules; UI shows appropriate empty state
- Three distinct empty states: no programs, empty schedule, no workouts this week

**BUG-4 [MEDIUM]: Debug prints in production** — ✅ FIXED
- All 15+ `print()` statements removed from `workout_repository.dart`

**BUG-5 [MEDIUM]: Program switcher not implemented** — ✅ FIXED
- Bottom sheet with full program list, active indicator (check_circle), snackbar confirmation
- `WorkoutNotifier.switchProgram()` re-parses weeks and resets selection

### 4.2 Trainer-Selectable Workout Layouts — COMPLETED (2026-02-14)

Trainers choose which workout logging UI their trainees see. Three variants:

| Layout | Description | Best For |
|--------|------------|----------|
| `classic` | Scrollable list — all exercises visible with full sets tables | Experienced lifters who want overview |
| `card` | One exercise at a time — swipe between exercises (existing PageView) | Beginners, simpler UX |
| `minimal` | Compact collapsible list — circular progress, quick-complete | Speed loggers, high-volume training |

**What was built:**
- New `WorkoutLayoutConfig` model (OneToOne per trainee, 3 layout choices, JSONField for future config)
- Trainer API: `GET/PUT /api/trainer/trainees/<id>/layout-config/` with auto-create default
- Trainee API: `GET /api/workouts/my-layout/` with graceful fallback to classic
- Trainer UI: "Workout Display" section in trainee detail Overview tab with segmented control
- Active workout screen: layout switching via `_buildExerciseContent` switch statement
- Two new layout widgets: `ClassicWorkoutLayout` (scrollable table), `MinimalWorkoutLayout` (collapsible list)
- Card layout uses existing PageView (no new widget needed)
- Full row-level security, error states with retry, optimistic updates with rollback

### 4.3 White-Label Branding Infrastructure — COMPLETED (2026-02-14)

Per-trainer customizable branding so trainees see their trainer's brand instead of "FitnessAI."

**What was built:**
- `TrainerBranding` model (OneToOne to User): `app_name`, `primary_color`, `secondary_color`, `logo` (ImageField)
- Service layer: `branding_service.py` with `validate_logo_image()`, `upload_trainer_logo()`, `remove_trainer_logo()`
- Trainer API: `GET/PUT /api/trainer/branding/` (auto-creates with defaults), `POST/DELETE /api/trainer/branding/logo/`
- Trainee API: `GET /api/users/my-branding/` (returns trainer's branding or defaults)
- Mobile: `BrandingScreen` with app name field, 12-preset color picker, logo upload/preview, live preview card
- Mobile: `ThemeNotifier.applyTrainerBranding()` overrides theme colors from trainer's config
- Mobile: Splash screen + login screen fetch branding via shared `BrandingRepository.syncTraineeBranding()`
- Mobile: SharedPreferences caching for offline persistence (hex-string format)
- UX: Save button change detection, unsaved changes guard, reset to defaults, accessibility labels
- Security: 5-layer image validation, UUID filenames, HTML tag stripping, generic error messages
- 84 comprehensive backend tests (model, views, serializer, permissions, row-level security, edge cases)

### 4.4 Ambassador User Type & Referral Revenue Sharing — COMPLETED (2026-02-14)

New AMBASSADOR role with referral tracking, commission management, and full mobile UI.

**What was built:**
- **Backend**: New `ambassador` Django app with 3 models (AmbassadorProfile, AmbassadorReferral, AmbassadorCommission)
- 6 API endpoints: ambassador dashboard, referrals, referral-code; admin list, create, detail/update
- `ReferralService` with `process_referral_code()`, `create_commission()`, `handle_trainer_churn()`
- Registration integration: optional `referral_code` field, silently ignored if invalid
- Security: `select_for_update()` for commission creation, `UniqueConstraint` for duplicate prevention, `IntegrityError` retry for code generation race conditions
- Global rate limiting (anon: 30/min, user: 120/min) and production CORS restriction
- **Mobile**: Ambassador navigation shell with 3 tabs (Dashboard, Referrals, Settings)
- Dashboard: earnings card, referral code with copy/share, stats row, recent referrals list
- Referrals screen: filterable by status, shows subscription tier and commission earned
- Settings screen: profile info, commission rate (read-only), earnings, logout with confirmation
- Admin ambassador management: searchable list with active/inactive filter, create with password, detail with commission history and rate editing
- Referral code field on trainer registration screen
- Accessibility: Semantics widgets throughout, confirmation dialogs, 48dp touch targets
- 25 acceptance criteria, all verified PASS

### 4.5 Trainer Notifications Dashboard + Ambassador Commission Webhook — COMPLETED (2026-02-14)

In-app notification feed for trainers and Stripe webhook integration for automatic ambassador commissions.

**What was built:**
- **Backend Notification API**: 5 views (list with pagination, unread count, mark-read, mark-all-read, delete) with `[IsAuthenticated, IsTrainer]` permissions and row-level security
- **Ambassador Commission Webhook**: `_handle_invoice_paid()` creates ambassador commissions from actual Stripe invoice amounts, `_handle_subscription_deleted()` triggers trainer churn, `_handle_checkout_completed()` handles first platform subscription payment
- **Mobile Notification UI**: Bell icon badge with "99+" cap, paginated list with date grouping ("Today", "Yesterday", "Feb 12"), swipe-to-dismiss with undo snackbar, mark-all-read with confirmation dialog, optimistic updates with revert-on-failure
- **Accessibility**: Screen reader semantics on all notification cards, badge, and action buttons
- **Database Optimization**: Index optimization — removed unused notification_type index, changed (trainer, created_at) to descending (trainer, -created_at)
- **Webhook Symmetry**: Extended `_handle_invoice_payment_failed()` and `_handle_subscription_updated()` to handle both TraineeSubscription and Subscription models
- **90 new tests**: 59 notification view tests + 31 ambassador webhook tests

### 4.7 AI Food Parsing + Password Change + Invitation Emails — COMPLETED (2026-02-14)

Three features shipped — activated existing AI food parsing UI, wired password change to Djoser, and created invitation email service.

**What was built:**
- **AI Food Parsing Activation**: Removed "AI parsing coming soon" banner, added meal selector (1-4), `_confirmAiEntry()` with empty meals check, nutrition refresh, success/error snackbars. UX: InkWell ripple, Semantics live regions, "Parse with AI" button label, keyboard handling, accessible touch targets.
- **Password Change**: `ApiConstants.setPassword` endpoint, `AuthRepository.changePassword()` with Djoser error parsing, `ChangePasswordScreen` with inline errors, loading states, success snackbar. UX: autofill hints, textInputAction flow, password strength indicator, focus borders, tooltips.
- **Invitation Emails**: `invitation_service.py` with `send_invitation_email()` — HTML + plain text, XSS prevention via `escape()`, URL scheme auto-detection, proper logging. Views call service in try/except for non-blocking email. Resend allows EXPIRED invitations, resets status to PENDING, extends expiry 7 days.
- **Security**: All user input HTML-escaped, URL-encoded invite codes, `select_related('trainer')` for N+1 prevention, proper TYPE_CHECKING imports.
- **Accessibility**: WCAG 2.1 Level AA — Semantics labels, live regions, 48dp touch targets, autofill hints, theme-aware colors.

### 4.9 Web Trainer Dashboard (Next.js Foundation) — COMPLETED (2026-02-15)

Complete Next.js 15 web dashboard for trainers with JWT auth, dashboard, trainee management, notifications, invitations, responsive layout, dark mode, and Docker integration.

**What was built:**
- **Frontend**: ~100 files — auth system (JWT login, refresh mutex, session cookie, role gating, 10s timeout), dashboard (4 stats cards, recent/inactive trainees), trainee management (searchable paginated list with full-row click, detail with Overview/Activity/Progress tabs), notification system (bell badge with 30s polling, popover, full page with server-side filtering, mark as read/all), invitation management (table with status badges, create dialog with Zod validation), responsive layout (256px sidebar desktop, sheet drawer mobile), dark mode via CSS variables, Docker multi-stage build
- **Backend performance fixes**: 6 N+1 query patterns eliminated across TraineeListView, TraineeDetailView, TrainerDashboardView, TrainerStatsView, AdherenceAnalyticsView, ProgressAnalyticsView. 4 bare `except:` clauses replaced with specific exception catches. Unbounded `days` parameter clamped to 1-365.
- **Accessibility**: 16 WCAG fixes — ARIA roles/labels, skip-to-content link, keyboard navigation on table rows, screen reader text, decorative icon hiding
- **Security**: Security response headers, consistent cookie Secure flag, input bounds (maxLength), double-submit protection, Zod validation
- **Quality**: Code review 8/10 APPROVE, QA 34/35 AC pass (1 fixed post-QA), UX 8/10, Security 9/10, Architecture 8/10, Hacker 6/10 (20 items fixed)

### 4.10 Web Dashboard Phase 2 (Settings, Charts, Notifications, Invitations) — COMPLETED (2026-02-15)

Four dead UI surfaces in the web trainer dashboard replaced with fully functional production-ready features.

**What was built:**
- **Settings Page**: Profile editing (name, business name, image upload/remove with 5MB/MIME validation), appearance section (Light/Dark/System theme toggle with `useSyncExternalStore` for hydration safety), security section (password change with Djoser error parsing, aria-describedby/aria-invalid accessibility)
- **Progress Charts**: Three recharts components — weight trend (LineChart), workout volume (BarChart), adherence (stacked BarChart with stackId). Theme-aware `CHART_COLORS` via CSS custom properties for dark mode and white-label readiness. Safe date parsing via `parseISO`/`isValid`. 5-minute `staleTime` on progress query.
- **Notification Click-Through**: `getNotificationTraineeId()` shared helper handles number/string coercion. ChevronRight visual affordance. Popover closes on navigation. "Marked as read" toast for non-navigable notifications.
- **Invitation Row Actions**: Context-sensitive dropdown (PENDING: Copy/Resend/Cancel, EXPIRED: Copy/Resend, ACCEPTED/CANCELLED: Copy only). Cancel with confirmation dialog and Loader2 spinner. Controlled dropdown closes immediately on action.
- **Auth Enhancement**: `refreshUser()` exposed from AuthProvider — profile/image mutations trigger context refresh so header updates immediately.
- **Quality**: Code review 8/10 APPROVE, QA 27/28 AC pass (1 partial pre-existing), UX 9/10, Security 9/10 PASS, Architecture 9/10, Hacker 7/10

### 4.11 Web Dashboard Phase 3 (Trainer Analytics Page) — COMPLETED (2026-02-15)

Dedicated analytics page for trainers with adherence tracking and trainee progress monitoring.

**What was built:**
- **Adherence Section**: Three stat cards (Food Logged, Workouts Logged, Protein Goal Hit) with color-coded indicators (green ≥80%, amber 50-79%, red <50%). Horizontal bar chart (recharts) showing per-trainee adherence rates with click-through to trainee detail. Period selector (7/14/30 days) with WAI-ARIA radiogroup keyboard navigation.
- **Progress Section**: DataTable showing all trainees with current weight, weight change (with TrendingUp/TrendingDown icons), and goal. Weight change color-coded by goal alignment (green = progress toward goal, red = regression).
- **Shared Infrastructure**: `chart-utils.ts` with shared `tooltipContentStyle` and `CHART_COLORS`. Extended `StatCard` with `valueClassName` prop. `AdherencePeriod` union type (`7 | 14 | 30`) for compile-time safety.
- **Accessibility**: WCAG 1.4.1 compliance (text descriptions complement color indicators), screen-reader accessible chart (`role="img"` + sr-only data list), `aria-busy` + sr-only live regions during refetch, keyboard-navigable period selector with roving tabindex.
- **UX**: Independent React Query hooks for each section (5-min staleTime), `isFetching` opacity transition during period switch, skeleton loading, error with retry, empty states with "Invite Trainee" CTA, responsive header layout.
- **Quality**: Code review 9/10 APPROVE, QA 21/22 AC pass (HIGH confidence), UX 9/10, Security 9/10 PASS, Architecture 9/10 APPROVE, Hacker 7/10, Final 9/10 SHIP.

### 4.12 Web Dashboard Phase 4 (Trainer Program Builder) — COMPLETED (2026-02-15)

Full CRUD program template builder for the trainer web dashboard with exercise bank integration and trainee assignment.

**What was built:**
- **Program List Page**: DataTable with name, difficulty badge, goal, duration, times used, created date. Search with `useDeferredValue`. Pagination. Empty state with "Create Program" CTA. Three-dot action menu with Edit (owner only), Assign to Trainee, Delete (owner only).
- **Program Builder**: Two-card layout (metadata + schedule). Name (100 chars), description (500 chars) with character counters and whitespace validation. Duration (1-52 weeks), difficulty, and goal selects with lowercase enum values matching Django backend. Week tabs with horizontal scroll. 7 days per week (Mon-Sun), rest day toggle with exercise loss confirmation. Exercise picker dialog with multi-add, search, muscle group filter, truncation warning. Exercise rows with sets (1-20), reps (1-100 or string ranges like "8-12"), weight (0-9999), unit (lbs/kg), rest seconds (0-600). Move up/down reorder. `reconcileSchedule()` syncs schedule with duration changes. Copy Week to All feature. Ctrl/Cmd+S keyboard shortcut.
- **Assignment Flow**: Assign dialog with trainee dropdown (up to 200), date picker with local timezone default. Empty trainee state with "Send Invitation" CTA.
- **Delete Flow**: Confirmation dialog with times_used warning. Prevents close during deletion. "Cannot be undone" copy.
- **Backend Enhancements**: SearchFilter on ProgramTemplateListCreateView. JSON field validation (schedule_template max 512KB, 52 weeks, 7 days; nutrition_template max 64KB). `is_public` and `image_url` made read-only.
- **Shared Infrastructure**: `error-utils.ts` with `getErrorMessage()` for DRF field-level error extraction. `useAllTrainees()` hook moved to `use-trainees.ts`. Column memoization with `useMemo`.
- **UX**: Dirty state tracking with mount guard (no false positives), double-click prevention via `savingRef`, fieldset disabled during save, character counters with amber warning at 90%, data loss confirmation on duration reduction, cancel confirmation when dirty, exercise count per day (max 50), "Back to Programs" navigation on create/edit pages, program name clickable link to edit in list.
- **Accessibility**: ARIA labels on all inputs and buttons, `role="group"` on exercise rows, `aria-invalid` on whitespace names, focus-visible rings, screen reader exercise names in move/delete labels, `DialogDescription` on all dialogs.
- **Quality**: Code review 8/10 APPROVE (2 rounds — 4 critical + 8 major all fixed), QA 27/27 AC pass (HIGH confidence), UX 9/10, Security 8/10 CONDITIONAL PASS, Architecture 9/10 APPROVE, Hacker report (16 items fixed), Final 8/10 SHIP.

### 4.13 Web Dashboard Phase 5 (Admin Dashboard) — COMPLETED (2026-02-15)

Full admin dashboard for the platform super admin with 7 management sections.

**What was built:**
- **Auth & Routing**: Extended AuthProvider to accept ADMIN role. Role cookie for middleware-level routing (admin → /admin/dashboard, trainer → /dashboard). Middleware blocks non-admin users from /admin/* routes. Separate `(admin-dashboard)` route group with admin sidebar and nav.
- **Admin Dashboard Overview**: Stat cards (MRR, total trainers, active trainers, total trainees). Revenue cards (past due amount, payments due today/week/month). Tier breakdown with color-coded badges. Past due alerts with "View All" link.
- **Trainer Management**: Searchable/filterable trainer list (active/all toggle). Detail dialog with subscription info, trainee count. Activate/suspend toggle. Impersonation flow (stores admin tokens in sessionStorage, restores on end with role cookie).
- **Subscription Management**: Filterable list (status, tier, past due, upcoming payments). Detail dialog with 4 action forms (change tier, change status, record payment, admin notes). Payment History and Change History tabs. Action forms reset between switches.
- **Tier Management**: CRUD with dialog-based forms. Toggle active with optimistic update. Seed defaults for empty state. Delete protection for tiers with active subscriptions. Features as comma-separated input.
- **Coupon Management**: CRUD with dialog-based forms. Applicable tiers multi-select checkbox UI. Revoke/reactivate lifecycle. Detail dialog with usage history table. Auto-uppercase codes. Status/type/applies_to filters.
- **User Management**: Role-filtered list (Admin/Trainer). Create admin/trainer accounts. Edit existing users. Self-deletion and self-deactivation protection. Password field with minimum length validation.
- **Shared Infrastructure**: `admin-constants.ts` with TIER_COLORS, status variant maps, SELECT_CLASSES. `format-utils.ts` with `formatCurrency()` (cached Intl.NumberFormat) and `formatDiscount()`. Impersonation banner component.
- **Quality**: Code review 8/10 APPROVE (2 rounds — 3 critical + 8 major all fixed), QA 46/49 AC pass (MEDIUM confidence — 3 design deviations), UX audit (16 usability + 6 accessibility fixes), Security 8.5/10 PASS (1 High fixed: middleware route protection), Architecture 8/10 APPROVE (5 deduplication fixes), Hacker 7/10 (13 fixes across 10 files), Final 8/10 SHIP.

### 4.14 Offline-First Workout & Nutrition Logging (Phase 6) -- COMPLETED (2026-02-15)

Complete offline-first infrastructure for the mobile app, enabling trainees to log workouts, nutrition, and weight check-ins without an internet connection.

**What was built:**
- **Local Database (Drift/SQLite)**: 5 tables (`PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`, `CachedPrograms`, `SyncQueueItems`). Background isolate via `NativeDatabase.createInBackground()`. WAL mode for concurrent read/write. Startup cleanup (24h synced items, 30d stale cache). Transactional user data clearing on logout.
- **Connectivity Monitoring**: `ConnectivityService` wrapping `connectivity_plus` with 2-second debounce to prevent sync thrashing during connection flapping. Handles Android's multi-result connectivity reporting (`[wifi, none]` edge case).
- **Offline-Aware Repositories**: Decorator pattern wrapping existing WorkoutRepository, LoggingRepository, and NutritionRepository. When online, delegates to API. When offline, saves to Drift + sync queue. UUID-based idempotency prevents duplicate submissions. Storage-full SQLite errors caught with user-friendly messages. Typed `OfflineSaveResult` return class.
- **Sync Queue Engine**: FIFO sequential processing. Exponential backoff (5s, 15s, 45s). Max 3 retries before permanent failure. HTTP 409 conflict detection with operation-specific messages (no auto-retry). 401 auth error handling (pauses sync, preserves data for re-authentication). Corrupted JSON and unknown operation types handled gracefully with permanent failure marking.
- **Program Caching**: Programs cached locally on successful fetch. Offline fallback reads from cache with "Some data may be outdated" banner. Corrupted cache detected, deleted, and reported gracefully. Active workout screen works fully offline with cached program data.
- **UI Indicators**: Offline banner (amber, cloud_off, "You are offline"), syncing banner (blue, LinearProgressIndicator, "Syncing X of Y..."), synced banner (green, auto-dismiss 3s), failed banner (red, tap to open failed sync sheet). `FailedSyncSheet` bottom sheet with per-item retry/delete, retry all, operation type icons, error messages, auto-close when empty. Logout warning dialog with unsynced item count and cancel/continue options.
- **Shared Utilities**: `network_error_utils.dart` (DRY network error detection), `SyncOperationType` and `SyncItemStatus` enums, `SyncStatusBadge` widget (ready for per-card placement in follow-up).
- **Quality**: 4 code review rounds, 13 critical/high issues found and fixed across all audit stages. Security 9/10, Architecture 8/10, Final 8/10 SHIP.

**Deferred items (completed in Pipeline 16):**
- ~~AC-12: Merge local pending workouts into Home "Recent Workouts" list~~ ✅
- ~~AC-16: Merge local pending nutrition into macro totals~~ ✅
- ~~AC-18: Merge local pending weight check-ins into weight trends~~ ✅
- ~~AC-36/37/38: Place SyncStatusBadge on individual cards in list views~~ ✅ (workout + weight cards; food entry badges deferred — nutrition entries stored as JSON blobs)

### 4.16 Health Data Integration + Performance Audit + Offline UI Polish (Phase 6 Completion) -- COMPLETED (2026-02-15)

Completes Phase 6 by adding HealthKit/Health Connect integration, app performance optimizations, and the deferred offline UI polish from Pipeline 15.

**What was built:**
- **Health Data Integration**: Reads steps, active calories, heart rate, and weight from HealthKit (iOS) / Health Connect (Android) via the `health` Flutter package. "Today's Health" card on home screen with 4 metrics, skeleton loading, 200ms fade-in animation. Platform-level aggregation (HKStatisticsQuery/AggregateRequest) for accurate step/calorie deduplication across overlapping sources (iPhone + Apple Watch). One-time permission bottom sheet with platform-specific explanation. Gear icon opens device health settings.
- **Weight Auto-Import**: Automatically imports weight from HealthKit/Health Connect to WeightCheckIn model. Date-based deduplication prevents duplicate entries. Checks both server and local pending data. Notes field set to "Auto-imported from Health". Silent failure (no snackbar) — background operation.
- **Offline UI Polish**: Pending workouts merged into Home "Recent Workouts" with SyncStatusBadge. Pending nutrition macros added to server totals with "(includes X pending)" label. Pending weight check-ins merged into Weight Trends history. SyncStatusBadge on workout cards and weight entries. Reactive updates via `syncCompletionProvider` — badges disappear when sync completes.
- **Performance Audit**: RepaintBoundary on CalorieRing, MacroCircle, MacroCard, weight chart CustomPaint. const constructors audited across priority widget files. Riverpod `select()` for granular rebuilds on home screen health card visibility. SliverList.builder for weight trends history (virtualized rendering). shouldRepaint optimization on weight chart painter.
- **Architecture**: Sealed class state hierarchy for HealthDataState (exhaustive pattern matching). Injectable HealthService via Riverpod provider. `mounted` guards after every async gap. Independent try-catch per health data type. `HealthMetrics` typed dataclass (no Map returns).
- **Quality**: Code review R1 6/10 → R2 8/10 APPROVE (3 critical + 4 major fixed). QA 24/26 AC pass HIGH confidence. UX 8/10 (15 usability + 8 accessibility fixes). Security 9.5/10 PASS. Architecture 8/10 APPROVE. Hacker 8/10 (2 fixes). Final 8/10 SHIP.

### 4.17 Social & Community (Phase 7) -- COMPLETED (2026-02-16)

Full implementation of the Social & Community feature set: Trainer Announcements, Achievement/Badge System, and Community Feed.

**What was built:**
- **Backend**: New `community` Django app with 6 models (Announcement, AnnouncementReadStatus, Achievement, UserAchievement, CommunityPost, PostReaction). 13 API endpoints. Achievement service with streak/count calculation and concurrent-safe awarding. Auto-post service for automated community posts. Seed command for 15 predefined achievements. 55 comprehensive backend tests.
- **Mobile (Trainer)**: Announcements management screen with swipe-to-delete and edit. Create/edit announcement form with character counters and pinned toggle.
- **Mobile (Trainee)**: Community feed screen (replaces Forums tab) with pull-to-refresh, infinite scroll, shimmer skeletons. Compose post bottom sheet. Reaction bar with optimistic toggle updates and error rollback. Auto-post visual distinction (tinted background, type badge). Post deletion with confirmation dialog. Announcements screen with mark-read on open. Notification bell with unread count badge. Achievements screen with 3-column badge grid (earned/locked states). Settings tile showing earned/total count.
- **Cross-Cutting**: Full Semantics/accessibility annotations. Shimmer skeleton loading states. Row-level security (all data scoped by parent_trainer). Batch reaction aggregation (no N+1). Proper CASCADE behavior. Database indexes on all query patterns.
- **Quality**: Code review R1 6/10 → fixes applied. QA 55/55 pass HIGH confidence. UX 8/10 (13 fixes). Security 9/10 PASS. Architecture 9/10 APPROVE. Hacker 7/10 (2 critical pagination bugs found and fixed). Final 8/10 SHIP.

### 4.18 Phase 8 Community & Platform Enhancements -- COMPLETED (2026-02-16)

Seven features extending the community platform with real-time capabilities, rich media, and ambassador monetization.

**What was built:**
- **Leaderboards**: New `Leaderboard` and `LeaderboardEntry` models. Trainer-configurable ranked leaderboards with workout count and streak metrics. Dense ranking algorithm (1, 2, 2, 4). Opt-in/opt-out per trainee. Skeleton loading, empty/error states. Leaderboard service with dataclass returns.
- **Push Notifications (FCM)**: `DeviceToken` model with platform detection. Firebase Cloud Messaging integration. Notification triggers on announcements and comments. Device token CRUD API. Platform-specific payload formatting (iOS badge, Android channel).
- **Rich Text / Markdown**: `content_format` field on posts and announcements (plain/markdown). `flutter_markdown` rendering on mobile. Server-side format validation.
- **Image Attachments**: `image` ImageField on CommunityPost. Multipart upload with content-type validation (JPEG/PNG/WebP only), 5MB server-side limit, 5MB client-side validation, UUID-based filenames. Full-screen pinch-to-zoom viewer (`InteractiveViewer` with `minScale: 1.0`). Loading/error states for images.
- **Comment Threads**: `Comment` model with ForeignKey to CommunityPost. Flat comment system with pagination. Author delete + trainer moderation. `comment_count` annotation for N+1 prevention. Push notifications on new comments.
- **Real-time WebSocket**: Django Channels `CommunityFeedConsumer` with JWT auth via query parameter. Channel layer group per trainer. 4 broadcast event types: `new_post`, `post_deleted`, `new_comment`, `reaction_update`. Exponential backoff reconnection (3s base, 5 max attempts). Mobile WebSocket service with typed message handling.
- **Stripe Connect Ambassador Payouts**: `AmbassadorPayout` model. Stripe Connect Express account onboarding. Admin-triggered payouts with `select_for_update()` + `transaction.atomic()` for race condition protection. Payout history screen with status badges (pending/paid/failed). Payout service with dataclass returns.
- **Quality**: Code review 8/10 APPROVE (2 rounds, 6 critical + 10 major all fixed). QA 50/61 AC pass HIGH confidence (11 deferred non-blocking). UX 8/10. Security 9/10 PASS. Architecture 9/10 APPROVE. Hacker 8/10. Final 8/10 SHIP.

### 4.19 Web Dashboard Full Parity + UI/UX Polish + E2E Tests (Pipeline 19) -- COMPLETED (2026-02-19)

Three workstreams: full feature parity for Trainer/Admin/Ambassador web dashboards, UI/UX polish with animations and micro-interactions, and a complete E2E test suite with Playwright. 130 files changed, 10,170 insertions.

**What was built:**

**Workstream 1: Feature Parity (28 ACs)**
- **Trainer Features**: Announcements (CRUD, pin sort, character counters), AI Chat (trainee selector, suggestion chips, clear dialog), Branding (12-preset color pickers, hex validation, logo upload/remove, live preview, unsaved changes guard), Exercise Bank (responsive grid, debounced search, muscle group filters, create/detail dialogs), Program Assignment (assign/change dialog), Edit Trainee Goals (4 macro fields with validation), Remove Trainee (REMOVE text match confirmation), Subscription Management (Stripe Connect 3-state flow), Calendar Integration (Google auth popup, events list), Layout Config (3 radio options, optimistic update), Impersonation (button + confirm dialog, token swap deferred), Mark Missed Day (skip/push radio, date picker), Feature Requests (vote toggle, status filters, create dialog), Leaderboard Settings (toggle switches, optimistic update)
- **Admin Features**: Ambassador Management (server-side search, CRUD, commission actions, bulk operations), Upcoming Payments & Past Due (severity color coding), Settings (platform config, security, profile/appearance/security sections)
- **Ambassador Features**: Dashboard (earnings cards, referral code, recent referrals), Referrals (status filter, pagination), Payouts (Stripe Connect 3-state setup, history table), Settings (profile, referral code edit), Auth & Routing (middleware routing, layout with auth guards)

**Workstream 2: UI/UX Polish (7 ACs)**
- Login Page Redesign (two-column layout, animated gradient, floating icons, framer-motion stagger, feature pills, prefers-reduced-motion)
- Page Transitions (PageTransition wrapper with fade-up animation)
- Skeleton Loading (content-shaped skeletons on all pages)
- Micro-Interactions (button active:scale, card-hover utility with reduced-motion query)
- Dashboard Trend Indicators (StatCard with TrendingUp/TrendingDown icons)
- Error States (ErrorState with retry button on all data pages)
- Empty States (EmptyState with contextual icons and action CTAs)

**Workstream 3: E2E Tests (5 ACs)**
- Playwright config with 5 browser targets, helpers, mock-api
- 19 test files: auth, trainer (7), admin (3), ambassador (4), responsive, error states, dark mode, navigation
- Test helpers: loginAs(), logout(), mock-api fixtures

**Audit Fixes:**
- CRITICAL: LeaderboardSection type mismatch fixed (was referencing non-existent properties from hook)
- CRITICAL: StripeConnectSetup type cast fixed (was using `is_connected` instead of `has_account`)
- Keyboard accessibility: focus-visible rings added to exercise list, feature request, and branding color picker buttons
- Ambassador list cleanup: removed redundant variable, added aria-label to View button

**Quality**: Code review 8/10 APPROVE (1 round), QA 52/60 AC pass HIGH confidence (3 partial, 5 deferred), UX 8/10, Security 9/10 PASS, Architecture 8/10 APPROVE, Hacker 8/10, Final 8/10 SHIP.

### 4.20 In-App Direct Messaging (Pipeline 20) -- COMPLETED (2026-02-19)

Full-stack implementation of 1:1 direct messaging between trainers and trainees across Django backend, Flutter mobile, and Next.js web. 61 files changed, 6,117 insertions.

**What was built:**

**Backend (Django)**
- New `messaging` app with `Conversation` and `Message` models (unique constraint, 6 indexes, SET_NULL on trainee FK)
- 6 REST API endpoints with IsAuthenticated, row-level security, ScopedRateThrottle (30/min on write endpoints)
- Service layer (`messaging_service.py`) with frozen dataclass returns (SendMessageResult, MarkReadResult, UnreadCountResult)
- WebSocket consumer (`DirectMessageConsumer`) with JWT auth, typing indicators, read receipts, per-conversation channel groups
- N+1 query elimination via Subquery + Count annotations on conversation list
- Conversation archival on trainee removal (archive_conversations_for_trainee called in RemoveTraineeView)
- Impersonation read-only guard (SendMessageView + StartConversationView check JWT 'impersonating' claim)
- Push notifications via FCM with null-safety for SET_NULL recipient

**Mobile (Flutter)**
- Full messaging feature: conversations list, chat screen, new conversation flow
- WebSocket service with exponential backoff reconnection (1s → 30s cap)
- Riverpod state management: ConversationListNotifier, ChatNotifier, UnreadCountNotifier, NewConversationNotifier
- Typing indicators (animated 3-dot), read receipts (double checkmark), optimistic message updates
- Unread badge on both trainer and trainee navigation shells
- Accessibility: Semantics on MessageBubble, ConversationTile, TypingIndicator, ChatInput, ConversationListScreen

**Web Dashboard (Next.js)**
- Messages page with responsive split-panel layout (320px sidebar + chat view, single-panel on mobile)
- New conversation flow (NewConversationView) when trainee param present but no matching conversation
- Conversation list with relative timestamps, unread badges, empty/error states
- Chat view with date separators, infinite scroll, auto-scroll, 5s polling
- Message input with character counter (2000 max), Enter-to-send, Shift+Enter for newline
- Read receipt icons (Check/CheckCheck), scroll-to-bottom FAB
- Sidebar unread badge (desktop + mobile), shared getInitials utility
- 7 Playwright E2E tests

**Pipeline Results:**
- Code review: 2 rounds, all 5 critical + 9 major + 10 minor issues fixed. Score: 8/10 APPROVE.
- QA: 93 tests passed, 0 failed. 4 bugs found and fixed. Confidence: HIGH.
- Security audit: Score 9/10 PASS. 3 High + 2 Medium issues fixed (archived WS access, bare exception, archived message access, archived mark-read, null recipient).
- Architecture audit: Score 9/10 APPROVE. 4 fixes (business logic in views→services, query optimization, code dedup, null-safety).
- Hacker audit: Chaos Score 7/10. 2 critical flow bugs fixed (web new-conversation dead end, responsive layout). 5 significant fixes total.
- Final verdict: 9/10 SHIP.

### 4.21 Image Attachments in Direct Messages (Pipeline 21) -- COMPLETED (2026-02-19)

Added image attachment support to direct messages across all three stacks. Users can now send image-only, text-only, or combined text+image messages. 32 files changed, 1,949 insertions.

**What was built:**

**Backend (Django)**
- `image` ImageField on Message model with UUID-based upload paths (`message_images/{uuid}.{ext}`)
- MultiPartParser support on SendMessageView and StartConversationView (backward-compatible with JSON)
- Image validation: JPEG/PNG/WebP only, 5MB max, in view layer + Pillow validation on save
- `annotated_last_message_has_image` Subquery annotation for conversation list "Sent a photo" preview
- Push notification body shows "Sent a photo" for image-only messages
- SendMessageResult dataclass updated with `image_url: str | None`
- 35 new tests covering upload, validation, rejection, preview, push notifications

**Mobile (Flutter)**
- Image picker button (camera icon) with ImagePicker (gallery, 1920x1920 max, 85% quality compression)
- Image preview strip above text input with X remove button, 5MB client-side validation
- Optimistic send: image appears immediately with local file, replaces with server URL on success
- Message bubble with image display (rounded corners, max 300px), tap for fullscreen
- Full-screen InteractiveViewer with pinch-to-zoom (1.0x-4.0x), black background
- Loading/error states for images, accessibility labels ("Photo message")

**Web (Next.js)**
- Paperclip attach button with file input (JPEG/PNG/WebP filter)
- Image preview strip with remove, 5MB validation with toast errors
- FormData multipart upload via existing apiClient.postFormData
- Image in message bubbles with click-to-modal full-size viewer
- Dialog-based image modal with close button, sr-only title

**Pipeline Results:**
- Code review: 2 rounds, 4 critical + 3 major issues fixed. Score: 8/10 APPROVE.
- QA: 324 tests passed (35 new), 0 failed. Confidence: HIGH.
- Security audit: Score 9/10 PASS. No issues found.
- Architecture audit: Score 9/10 APPROVE. Clean extension of existing patterns.
- Hacker audit: Chaos Score 9/10. No dead UI or logic bugs found.
- Final verdict: 9/10 SHIP.

### 4.22 WebSocket Real-Time Web Messaging (Pipeline 22) -- COMPLETED (2026-02-19)

Replaced HTTP polling with WebSocket real-time messaging on the web dashboard. Zero backend changes — the existing `DirectMessageConsumer` already supported all needed events. 4 files changed, ~550 insertions.

**What was built:**

**WebSocket Hook (`use-messaging-ws.ts`)**
- New `useMessagingWebSocket` custom hook managing full WebSocket lifecycle per conversation
- JWT authentication via URL query parameter (standard for WebSocket, `encodeURIComponent` encoded)
- Token refresh before connection if expired, with `cancelledRef` pattern to prevent leaked connections on unmount during async gaps
- Exponential backoff reconnection (1s, 2s, 4s, 8s, 16s cap, max 5 attempts)
- 30s heartbeat ping with 5s pong timeout for connection health monitoring
- Tab visibility API reconnection — auto-reconnects when tab becomes visible
- React Query cache mutations: `appendMessageToCache` (dedup by ID), `updateConversationPreview`, `updateReadReceipts`
- Typed WebSocket events: `WsNewMessageEvent`, `WsTypingIndicatorEvent`, `WsReadReceiptEvent`, `WsPongEvent`

**Typing Indicators**
- `sendTyping()` with 3s debounce — sends `is_typing: true` at most once per 3s, auto-sends `is_typing: false` after 3s idle
- 4s display timeout — "Name is typing..." disappears after 4s without typing event
- Typing indicator positioned outside scroll area — always visible regardless of scroll position
- Wired existing `typing-indicator.tsx` component (animated dots with staggered delays)

**Connection State UI**
- `ConnectionBanner` component with two states: "Reconnecting..." (amber, Loader2 spinner) and "Updates may be delayed" (muted, WifiOff icon)
- Dark mode support on both banner variants
- `aria-live="polite"` on typing indicator, `role="status"` on connection banners

**Graceful Degradation**
- When WebSocket connected: HTTP polling disabled (interval set to 0)
- When WebSocket disconnected/failed: HTTP polling resumes at 5s
- Refetches once on WS reconnect to catch messages missed during disconnection

**Pipeline Results:**
- Code review: 2 rounds, 2 critical + 2 major issues fixed (race condition, typing indicator placement, markRead ordering, polling constant naming). Score: 8/10 APPROVE.
- QA: 31/31 AC pass, 35 backend tests pass, 0 new TS errors. Confidence: HIGH.
- Security audit: Score 9/10 PASS. JWT in URL param is standard for WS. No issues found.
- Architecture audit: Score 9/10 APPROVE. Clean separation of concerns, no tech debt introduced.
- Hacker audit: Chaos Score 9/10. No dead UI, visual bugs, or logic bugs found.
- Final verdict: 9/10 SHIP.

### 4.23 Message Editing and Deletion (Pipeline 23) -- COMPLETED (2026-02-19)

Full-stack message editing (within 15-minute window) and soft-deletion across Django backend, Flutter mobile, and Next.js web. 107 tests, 32 acceptance criteria verified.

**What was built:**

**Backend (Django)**
- `edited_at` (DateTimeField, nullable) and `is_deleted` (BooleanField) fields on Message model with migration
- Single RESTful `MessageDetailView` handling PATCH (edit) and DELETE (soft-delete) on `/api/messaging/conversations/<id>/messages/<message_id>/`
- Service layer: `edit_message()` and `delete_message()` with frozen dataclass returns (EditMessageResult, DeleteMessageResult)
- Race condition prevention: `transaction.atomic()` + `select_for_update()` on both operations
- Edit validation: sender-only, within 15-minute configurable window, not deleted, content not empty for text-only messages, 2000 char limit
- Delete validation: sender-only, not already deleted, no time limit
- Soft-delete clears content to empty string, sets image to None, deletes actual image file from storage
- WebSocket broadcasts: `chat.message_edited` and `chat.message_deleted` events via channel layer
- Conversation list preview: "This message was deleted" via `annotated_last_message_is_deleted` subquery
- Row-level security: participant check in view + sender check in service (defense in depth)
- Impersonation guard on both operations
- Rate limiting (30/min) via ScopedRateThrottle on unified view
- `EditMessageSerializer` with `allow_blank=True` for image message caption clearing (edge case 8)

**Mobile (Flutter)**
- Long-press context menu: Edit (pencil), Delete (trash, red), Copy (clipboard). Other users' messages show Copy only.
- Edit grayed out with "Edit window expired" subtitle when >15 minutes
- Edit bottom sheet: pre-filled TextFormField, character counter (X/2000), Save/Cancel, hasImage param allows empty for image messages
- Delete confirmation AlertDialog: "Delete this message? This can't be undone."
- Deleted messages: "[This message was deleted]" in italic gray, timestamp preserved, Semantics for accessibility
- Edited messages: "(edited)" next to timestamp in italic
- Optimistic updates with rollback on error for both edit and delete
- WebSocket handlers for `message_edited` and `message_deleted` events
- Error feedback: SnackBar on edit/delete failure with clearError()
- No debug prints (convention compliance)

**Web (Next.js)**
- Hover action icons (pencil/trash) on own messages, pencil hidden when edit window expired
- Inline edit mode: textarea with Save/Cancel, Esc cancels, Cmd/Ctrl+Enter saves (platform-detected)
- Delete confirmation dialog with `role="alertdialog"`, `aria-label`, Escape key dismissal
- Deleted messages: "[This message was deleted]" in muted italic with aria-label
- Edited messages: "(edited)" next to timestamp
- `useEditMessage()` and `useDeleteMessage()` mutation hooks (AC-32)
- WebSocket `onMessageEdited`/`onMessageDeleted` callbacks update local `allMessages` state directly
- `setQueriesData` for React Query cache sync across all pages
- Toast errors on failed edit/delete via sonner
- Image-only edit: Save button allows empty content when hasImage

**Pipeline Results:**
- Code review: 1 round, 4 critical + 8 major issues fixed (race conditions, missing rate limiting, crash risk, dead code, cache sync). Score: 7/10 → fixed.
- QA: 72 tests → 107 tests after audit agents. All pass. Confidence: HIGH.
- Security audit: Score 9/10 PASS. Row-level security gap fixed (conversation ID enumeration). Views merged into single MessageDetailView.
- Architecture audit: Score 9/10 APPROVE. RESTful single-resource endpoint, deduplicated _resolve_conversation helper, re-added mutation hooks for AC-32.
- UX audit: Score 9/10. 6 usability + 4 accessibility issues found and fixed (delete confirmation mouse leave, error feedback, platform keyboard hints, image-only edit, Semantics, ARIA roles).
- Hacker audit: Chaos Score 8/10. 4 bugs found and fixed (critical test URL mismatch, serializer validation gap, WS state sync for other party, debugPrint convention).
- Final verdict: 9/10 SHIP.

### 4.24 In-App Message Search (Pipeline 24) -- COMPLETED (2026-02-20)

Full-stack message search across all conversations with backend API, web dashboard UI, 42 tests, and comprehensive accessibility. All 25 acceptance criteria met.

**What was built:**

**Backend (Django)**
- `GET /api/messaging/search/?q=<query>&page=<page>` — case-insensitive substring search via `icontains`
- Service layer: `search_messages()` in `services/search_service.py` with frozen dataclass returns (`SearchMessageItem`, `SearchMessagesResult`)
- Row-level security: trainer sees only trainer's conversations, trainee sees only trainee's conversations, admin must impersonate
- Excludes soft-deleted messages and archived conversations
- Pagination via Django Paginator (20/page), page clamping for out-of-range
- `select_related()` with `.only()` for query optimization
- `SearchMessageResultSerializer` for API response serialization
- Rate limiting (30/min) via ScopedRateThrottle with `messaging` scope
- Null trainee handling (SET_NULL FK): `other_participant_id: None` with `[removed]` fallback

**Web (Next.js)**
- Search button in messages page header with Cmd/Ctrl+K keyboard shortcut (platform-detected)
- Sidebar search panel replacing conversation list when active
- Debounced input (300ms), 2-character minimum before firing API
- Highlighted search results with `<mark>` tags (XSS-safe via React JSX, no innerHTML)
- `truncateAroundMatch()` centers ~150 char window around first match
- Click result → navigate to conversation → scroll to message → 3s highlight flash animation (light + dark mode)
- Pagination (Previous/Next), skeleton loading, error/retry, empty state
- Escape key closes search, clear button returns focus to input
- Accessibility: `role="search"` landmark, `aria-live` regions, semantic `<nav>`/`<time>`, `aria-describedby`, `prefers-reduced-motion` support
- `keepPreviousData` for smooth pagination transitions

**Pipeline Results:**
- Code review: 1 round, 3 critical + 6 major issues fixed (regex stateful bug, admin role error, page reset race, double validation, null trainee FK, search result navigation). Score: 7/10 → fixed.
- QA: 42 tests. All pass. Confidence: HIGH.
- Security audit: Score 9/10 PASS. No critical/high issues. Row-level security at query level, XSS-safe highlighting, rate limiting.
- Architecture audit: Score 9/10 APPROVE. Clean layering, no new tech debt, scaling path documented.
- UX audit: Score 9/10. 6 usability + 9 accessibility issues found and fixed (idle state, focus management, ARIA landmarks, semantic HTML, dark mode contrast).
- Hacker audit: Chaos Score 7/10. 4 bugs found and fixed (AC-15 scroll-to-message, keepPreviousData, scroll reset, date formatting guard).
- Final verdict: 9/10 SHIP.

### 4.15 Acceptance Criteria

- [x] Completing a workout persists all exercise data to DailyLog.workout_data
- [x] Trainer receives notification when trainee starts or finishes a workout
- [x] Trainee sees their real assigned program, not sample data
- [x] No print() debug statements in workout_repository.dart
- [x] Trainee can switch between assigned programs via bottom sheet
- [x] Trainer can set layout type (classic/card/minimal) per trainee
- [x] Trainee's active workout screen renders the correct layout variant
- [x] Default layout is "classic" for all existing trainees (no migration data needed)
- [x] Layout config survives app restart (fetched from API, cached locally)
- [x] TrainerBranding model with all fields, validators, and get_or_create_for_trainer() classmethod
- [x] Trainer can customize branding (app name, colors, logo) via Settings > Branding
- [x] Trainee sees trainer's branding on login, splash, and throughout the app
- [x] Branding cached locally for offline persistence
- [x] Default FitnessAI theme when no branding configured
- [x] Row-level security: trainers see own branding, trainees see own trainer's branding

---

## 5. Roadmap

### Phase 1: Foundation Fix — ✅ COMPLETED (2026-02-13/14)
- ~~Fix all 5 bugs~~ ✅ Completed 2026-02-13
- ~~Implement workout layout system~~ ✅ Completed 2026-02-14

### Phase 2: White-Label Infrastructure — ✅ COMPLETED
- ~~TrainerBranding model: primary_color, secondary_color, logo_url, app_name~~ ✅ Completed 2026-02-14
- ~~Mobile reads branding config on login, applies to ThemeData~~ ✅ Completed 2026-02-14
- ~~Each trainer's trainees see the trainer's branding, not "FitnessAI"~~ ✅ Completed 2026-02-14
- ~~Custom splash screen per trainer~~ ✅ Completed 2026-02-14

### Phase 3: Ambassador System — ✅ COMPLETED (2026-02-14)
- ~~New User role: AMBASSADOR~~ ✅ Completed 2026-02-14
- ~~Ambassador dashboard: referred trainers, earnings, referral code~~ ✅ Completed 2026-02-14
- ~~Referral code system (8-char alphanumeric, registration integration)~~ ✅ Completed 2026-02-14
- ~~Revenue sharing logic: configurable commission rate per ambassador~~ ✅ Completed 2026-02-14
- ~~Admin can create/manage ambassadors and set commission rates~~ ✅ Completed 2026-02-14
- ~~Stripe Connect payout to ambassadors~~ ✅ Completed 2026-02-16 (Pipeline 18: Express account onboarding, admin payouts, payout history)

### Phase 4: Web Dashboard — ✅ COMPLETED
- ~~React/Next.js with shadcn/ui~~ ✅ Completed 2026-02-15 (Next.js 15 + React 19)
- ~~Trainer dashboard (trainee management, stats, notifications, invitations)~~ ✅ Completed 2026-02-15
- ~~Shared auth with existing JWT system~~ ✅ Completed 2026-02-15
- ~~Docker integration~~ ✅ Completed 2026-02-15
- ~~Trainer program builder (web)~~ ✅ Completed 2026-02-15 (full CRUD with exercise bank, assignment, schedule editor)
- ~~Trainer analytics (web)~~ ✅ Completed 2026-02-15 (adherence + progress sections)
- ~~Admin dashboard (trainer management, tiers, revenue, platform analytics)~~ ✅ Completed 2026-02-15 (7 sections: overview, trainers, subscriptions, tiers, coupons, users, settings)
- ~~Settings page (profile, theme toggle, notifications)~~ ✅ Completed 2026-02-15
- ~~Progress charts tab~~ ✅ Completed 2026-02-15 (weight trend, volume, adherence charts)

### Phase 5: Ambassador Enhancements -- ✅ COMPLETED (2026-02-15)
- ~~Monthly earnings chart (fl_chart bar chart on dashboard)~~ ✅ Completed 2026-02-15
- ~~Native share sheet (share_plus package)~~ ✅ Completed 2026-02-15
- ~~Commission approval/payment workflow (admin mobile + API)~~ ✅ Completed 2026-02-15
- ~~Ambassador password reset / magic link login~~ ✅ Completed 2026-02-15 (admin-created password validation)
- ~~Stripe Connect payout to ambassadors~~ ✅ Completed 2026-02-16 (Pipeline 18: Express onboarding, admin payouts, history)
- ~~Custom referral codes (ambassador-chosen, e.g., "JOHN20")~~ ✅ Completed 2026-02-15

### Phase 6: Offline-First + Performance -- COMPLETED (2026-02-15)
- ~~Drift (SQLite) local database for offline workout logging~~ ✅ Completed 2026-02-15
- ~~Sync queue for uploading logs when connection returns~~ ✅ Completed 2026-02-15
- ~~Background health data sync (HealthKit / Health Connect)~~ ✅ Completed 2026-02-15
- ~~App performance audit (60fps target, RepaintBoundary audit)~~ ✅ Completed 2026-02-15
- ~~Merging local pending data into home recent workouts, nutrition macro totals, and weight trends~~ ✅ Completed 2026-02-15
- ~~Per-card sync status badges on list items~~ ✅ Completed 2026-02-15 (workout + weight cards; food entry badges deferred)

### Phase 7: Social & Community -- ✅ COMPLETED (2026-02-16)
- ~~Forums / community feed (trainee-to-trainee)~~ ✅ Completed 2026-02-16 (trainer-scoped community feed with text posts, reactions, auto-posts, moderation)
- ~~Trainer announcements (broadcast to all trainees)~~ ✅ Completed 2026-02-16 (full CRUD, pinning, unread tracking, notification bell)
- ~~Achievement / badge system~~ ✅ Completed 2026-02-16 (15 predefined badges, streak/count calculation, hooks on workout/nutrition/weight, badge grid UI)
- ~~Leaderboards (opt-in, trainer-controlled)~~ ✅ Completed 2026-02-16 (Pipeline 18)

### Phase 8: Community & Platform Enhancements -- ✅ COMPLETED (2026-02-16)
- ~~Leaderboards (opt-in, trainer-controlled)~~ ✅ Completed 2026-02-16 (dense ranking, workout count + streak metrics, opt-in/opt-out, skeleton loading)
- ~~Push notifications (FCM) for announcements, achievements, community posts~~ ✅ Completed 2026-02-16 (device token management, announcement/comment notifications, platform-specific detection)
- ~~Rich text / markdown in announcements and posts~~ ✅ Completed 2026-02-16 (content_format field, flutter_markdown rendering)
- ~~Image attachments on community posts~~ ✅ Completed 2026-02-16 (multipart upload, JPEG/PNG/WebP, 5MB, UUID filenames, full-screen pinch-to-zoom)
- ~~Comment threads on community posts~~ ✅ Completed 2026-02-16 (flat comments, pagination, author/trainer delete, real-time count updates)
- ~~Real-time feed updates (WebSocket)~~ ✅ Completed 2026-02-16 (Django Channels, JWT auth, 4 event types, exponential backoff reconnection)
- ~~Stripe Connect payout to ambassadors~~ ✅ Completed 2026-02-16 (Express account onboarding, admin-triggered payouts, race condition protection, payout history)

### Phase 9: Web Dashboard Full Parity -- ✅ COMPLETED (2026-02-19)
- ~~Full feature parity for Trainer web dashboard (announcements, AI chat, branding, exercise bank, program assignment, goals, remove trainee, subscriptions, calendar, layout, impersonation, missed day, feature requests, leaderboard settings)~~ ✅ Completed 2026-02-19
- ~~Full feature parity for Admin web dashboard (ambassador management, upcoming/past due payments, settings)~~ ✅ Completed 2026-02-19
- ~~Ambassador web dashboard (dashboard, referrals, payouts, settings, auth/routing)~~ ✅ Completed 2026-02-19
- ~~UI/UX polish (login redesign, page transitions, skeletons, micro-interactions, trend indicators, error/empty states)~~ ✅ Completed 2026-02-19
- ~~E2E test suite (Playwright, 19 test files, 5 browser targets)~~ ✅ Completed 2026-02-19

### Phase 10: In-App Direct Messaging -- ✅ COMPLETED (2026-02-19)
- ~~In-app messaging (trainer-to-trainee direct messages)~~ ✅ Completed 2026-02-19 (full-stack: Django backend + Flutter mobile + Next.js web)
- ~~WebSocket real-time delivery (mobile)~~ ✅ Completed 2026-02-19 (DirectMessageConsumer with JWT auth, typing indicators, read receipts)
- ~~HTTP polling real-time delivery (web v1)~~ ✅ Completed 2026-02-19 (5s messages, 15s conversations, 30s unread count)
- ~~Unread badge across all platforms~~ ✅ Completed 2026-02-19 (mobile trainer + trainee shells, web desktop + mobile sidebars)
- ~~Push notifications for offline recipients~~ ✅ Completed 2026-02-19 (FCM integration)
- ~~Read receipts~~ ✅ Completed 2026-02-19 (double checkmark pattern)
- ~~Rate limiting (30/min)~~ ✅ Completed 2026-02-19 (ScopedRateThrottle)
- ~~Conversation archival on trainee removal~~ ✅ Completed 2026-02-19 (soft-archive, SET_NULL FK)

### Phase 11: Future Enhancements
- Video attachments on community posts
- Trainee web access
- ~~WebSocket support for web messaging (replace HTTP polling)~~ ✅ Completed 2026-02-19 (Pipeline 22)
- ~~Web typing indicators (component exists, awaiting WebSocket)~~ ✅ Completed 2026-02-19 (Pipeline 22)
- ~~Message editing and deletion~~ ✅ Completed 2026-02-19 (Pipeline 23)
- ~~Message search~~ ✅ Completed 2026-02-20 (Pipeline 24)
- ~~Advanced analytics and reporting~~ ✅ Completed 2026-02-20 (Pipeline 26 — calorie goal + trend chart; Pipeline 28 — trainer revenue analytics)
- ~~CSV data export~~ ✅ Completed 2026-02-21 (Pipeline 29 — trainer payments, subscribers, trainees as CSV)
- ~~Macro preset management (web dashboard)~~ ✅ Completed 2026-02-21 (Pipeline 30 — CRUD presets per trainee, copy-to-trainee, default toggle)
- Multi-language support
- Social auth (Apple/Google) mobile integration
- ~~Full impersonation token swap (web dashboard)~~ ✅ Completed 2026-02-20 (Pipeline 27 — trainer→trainee token swap, read-only trainee view page, impersonation banner)
- ~~Ambassador monthly earnings chart (web dashboard)~~ ✅ Completed 2026-02-20 (Pipeline 25)
- ~~Server-side pagination on ambassador list (web dashboard)~~ ✅ Completed 2026-02-20 (Pipeline 25)

---

## 6. Data Architecture Notes

### JSONField Schemas

**Program.schedule** (assigned to trainee):
```json
{
  "weeks": [
    {
      "week_number": 1,
      "days": [
        {
          "day_number": 1,
          "name": "Push Day",
          "exercises": [
            {
              "exercise_id": 42,
              "exercise_name": "Bench Press",
              "sets": 4,
              "reps": "8-10",
              "weight": 135,
              "unit": "lbs",
              "rest_seconds": 90,
              "notes": "Control the eccentric"
            }
          ]
        }
      ]
    }
  ]
}
```

**DailyLog.workout_data** (logged by trainee):
```json
{
  "sessions": [
    {
      "workout_name": "Push Day",
      "duration": "45:30",
      "exercises": [
        {
          "exercise_name": "Bench Press",
          "exercise_id": 42,
          "sets": [
            {"set_number": 1, "reps": 10, "weight": 135, "unit": "lbs", "completed": true},
            {"set_number": 2, "reps": 8, "weight": 145, "unit": "lbs", "completed": true}
          ],
          "timestamp": "2026-02-13T10:30:00Z"
        }
      ],
      "post_survey": { "...": "..." },
      "readiness_survey": { "...": "..." },
      "completed_at": "2026-02-13T11:15:30Z"
    }
  ],
  "exercises": [ "/* flat list of all exercises across all sessions for backward compat */" ],
  "workout_name": "Push Day",
  "duration": "45:30",
  "completed_at": "2026-02-13T11:15:30Z"
}
```
> **Note:** `sessions` array was added 2026-02-13 to support multiple workouts per day. Each session preserves its own metadata. The flat `exercises` key is maintained for backward compatibility.

**DailyLog.nutrition_data**:
```json
{
  "meals": [
    {
      "meal_type": "breakfast",
      "foods": [
        {"name": "Eggs", "protein": 12, "carbs": 1, "fat": 10, "calories": 142, "quantity": 2, "unit": "large"}
      ],
      "timestamp": "2026-02-13T08:00:00Z"
    }
  ],
  "totals": {"protein": 180, "carbs": 220, "fat": 65, "calories": 2185}
}
```

---

## 7. Technical Constraints

- **Offline support for trainee workout/nutrition/weight logging** — Shipped 2026-02-15 via Drift (SQLite). Sync queue with FIFO processing, exponential backoff, conflict detection. Pending: offline data not yet merged into list views (home recent workouts, nutrition macro totals, weight trends).
- **Single timezone assumed** — DailyLog uses `timezone.now().date()`. Multi-timezone trainees may see date boundary issues.
- **AI parsing is OpenAI-only** — Function Calling mode. No fallback provider yet. Rate limits apply.
- **Real-time updates on community feed and messaging** — WebSocket via Django Channels shipped for community feed (2026-02-16: new posts, deletions, comments, reactions) and direct messaging on mobile (2026-02-19) and web (2026-02-19 Pipeline 22: new messages, typing indicators, read receipts, graceful HTTP polling fallback). Trainer dashboard still requires manual refresh.
- **Web dashboard covers trainer, admin, and ambassador roles** — Web dashboard (Next.js) shipped for trainers and admins (2026-02-15), ambassador role added (2026-02-19). Full feature parity achieved for all three roles. Trainee web access not yet built.

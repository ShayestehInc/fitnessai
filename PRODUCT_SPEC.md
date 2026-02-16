# PRODUCT_SPEC.md — FitnessAI Product Specification

> Living document. Describes what the product does, what's built, what's broken, and what's next.
> Last updated: 2026-02-15 (Pipeline 16: Health Data Integration + Performance Audit + Offline UI Polish — Phase 6 Complete)

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

### 3.10 Other
| Feature | Status | Notes |
|---------|--------|-------|
| Calendar integration (Google/Microsoft) | 🟡 Partial | Backend API done, mobile basic |
| Feature request board | ✅ Done | In-app submission + voting |
| MCP server (Claude Desktop) | ✅ Done | Trainer can query data via Claude Desktop |
| TV mode | ❌ Placeholder | Screen exists but empty |
| Forums | ❌ Placeholder | Screen exists but empty |
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
- Stripe Connect payout to ambassadors — Not yet (future enhancement)

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
- Stripe Connect payout to ambassadors -- Deferred (requires Stripe dashboard configuration)
- ~~Custom referral codes (ambassador-chosen, e.g., "JOHN20")~~ ✅ Completed 2026-02-15

### Phase 6: Offline-First + Performance -- COMPLETED (2026-02-15)
- ~~Drift (SQLite) local database for offline workout logging~~ ✅ Completed 2026-02-15
- ~~Sync queue for uploading logs when connection returns~~ ✅ Completed 2026-02-15
- ~~Background health data sync (HealthKit / Health Connect)~~ ✅ Completed 2026-02-15
- ~~App performance audit (60fps target, RepaintBoundary audit)~~ ✅ Completed 2026-02-15
- ~~Merging local pending data into home recent workouts, nutrition macro totals, and weight trends~~ ✅ Completed 2026-02-15
- ~~Per-card sync status badges on list items~~ ✅ Completed 2026-02-15 (workout + weight cards; food entry badges deferred)

### Phase 7: Social & Community
- Forums / community feed (trainee-to-trainee)
- Trainer announcements (broadcast to all trainees)
- Achievement / badge system
- Leaderboards (opt-in, trainer-controlled)

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
- **No real-time updates** — Trainer dashboard requires manual refresh. WebSocket/SSE planned but not implemented.
- **Web dashboard is trainer + admin only** — Web dashboard (Next.js) shipped for trainers and admins (2026-02-15). Trainee web access not yet built.

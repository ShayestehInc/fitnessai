# Changelog

All notable changes to the FitnessAI platform are documented in this file.

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

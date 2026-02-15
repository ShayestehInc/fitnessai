# PRODUCT_SPEC.md — FitnessAI Product Specification

> Living document. Describes what the product does, what's built, what's broken, and what's next.
> Last updated: 2026-02-14

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
- Referral code system: 8-char alphanumeric codes, shared to trainers during registration
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
| Monthly earnings chart | ❌ Not started | Backend returns data, mobile needs chart widget (fl_chart) |
| Native share sheet | ❌ Not started | Currently clipboard-only; needs share_plus package |
| Commission approval workflow | ❌ Not started | Admin can view but not approve/pay from mobile |
| Ambassador password reset | ❌ Not started | Admin sets temp password; no self-service reset flow |

### 3.9 Other
| Feature | Status | Notes |
|---------|--------|-------|
| Calendar integration (Google/Microsoft) | 🟡 Partial | Backend API done, mobile basic |
| Feature request board | ✅ Done | In-app submission + voting |
| MCP server (Claude Desktop) | ✅ Done | Trainer can query data via Claude Desktop |
| TV mode | ❌ Placeholder | Screen exists but empty |
| Forums | ❌ Placeholder | Screen exists but empty |
| Offline-first with local DB | ❌ Not started | Drift/Hive planned but not implemented |

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

### 4.8 Acceptance Criteria

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

### Phase 4: Web Admin Dashboard
- React/Next.js with shadcn/ui
- Trainer dashboard (program builder, trainee management, analytics)
- Admin dashboard (trainer management, tiers, revenue, platform analytics)
- Shared auth with existing JWT system
- TypeScript interfaces auto-generated from Django serializers

### Phase 5: Ambassador Enhancements
- Monthly earnings chart (fl_chart bar chart on dashboard)
- Native share sheet (share_plus package)
- Commission approval/payment workflow (admin mobile + API)
- Ambassador password reset / magic link login
- Stripe Connect payout to ambassadors
- Custom referral codes (ambassador-chosen, e.g., "JOHN20")

### Phase 6: Offline-First + Performance
- Drift (SQLite) local database for offline workout logging
- Sync queue for uploading logs when connection returns
- Background health data sync (HealthKit / Health Connect)
- App performance audit (60fps target, RepaintBoundary audit)

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

- **No offline support yet** — requires Drift/Hive integration. All data currently requires network.
- **Single timezone assumed** — DailyLog uses `timezone.now().date()`. Multi-timezone trainees may see date boundary issues.
- **AI parsing is OpenAI-only** — Function Calling mode. No fallback provider yet. Rate limits apply.
- **No real-time updates** — Trainer dashboard requires manual refresh. WebSocket/SSE planned but not implemented.
- **Mobile only** — No web app exists yet. All management happens in the Flutter app.

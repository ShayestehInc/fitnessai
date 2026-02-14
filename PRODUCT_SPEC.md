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

### 2.4 Ambassador (PLANNED — not yet built)
- Admin-level user who sells the platform to trainers
- Earns monthly percentage of each trainer's subscription they referred
- Has dashboard showing their referred trainers and revenue

---

## 3. Feature Inventory

### 3.1 Authentication & Onboarding
| Feature | Status | Notes |
|---------|--------|-------|
| Email-only registration (no username) | ✅ Done | Djoser + JWT |
| JWT auth with refresh tokens | ✅ Done | |
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
| Workout calendar / history | 🟡 Partial | Calendar screen exists; data now persists via DailyLog |
| Program switcher | ✅ Done | Fixed 2026-02-13: Bottom sheet with active indicator + snackbar |
| Trainer-selectable workout layouts | ✅ Done | Shipped 2026-02-14: Classic / Card / Minimal per trainee |
| Missed day handling | ✅ Done | Skip or push (shifts program dates) |

### 3.3 Nutrition System
| Feature | Status | Notes |
|---------|--------|-------|
| Daily macro tracking | ✅ Done | Protein, carbs, fat, calories |
| Food search & logging | ✅ Done | |
| AI natural language food parsing | ✅ Done | "Had 2 eggs and toast" → structured macro data |
| Nutrition goals per trainee | ✅ Done | Trainer can set/override |
| Macro presets (Training Day, Rest Day) | ✅ Done | |
| Weekly nutrition plans | ✅ Done | Carb cycling support |
| Weight check-ins | ✅ Done | |
| Weight trend charts | ✅ Done | |

### 3.4 Trainer Dashboard
| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard overview (stats, activity) | ✅ Done | |
| Trainee list | ✅ Done | |
| Trainee detail (progress, adherence) | ✅ Done | |
| Trainee invitation system | ✅ Done | Email-based invite codes |
| Trainee goal editing | ✅ Done | |
| Trainee removal | ✅ Done | |
| Impersonation (log in as trainee) | ✅ Done | With audit trail |
| AI chat assistant | ✅ Done | Uses trainee context for personalized advice |
| Adherence analytics | ✅ Done | |
| Progress analytics | ✅ Done | |
| Trainer notifications | ✅ Done | Fixed 2026-02-13: Uses parent_trainer, migration created |

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

### 3.7 Other
| Feature | Status | Notes |
|---------|--------|-------|
| Calendar integration (Google/Microsoft) | 🟡 Partial | Backend API done, mobile basic |
| Feature request board | ✅ Done | In-app submission + voting |
| MCP server (Claude Desktop) | ✅ Done | Trainer can query data via Claude Desktop |
| TV mode | ❌ Placeholder | Screen exists but empty |
| Forums | ❌ Placeholder | Screen exists but empty |
| Offline-first with local DB | ❌ Not started | Drift/Hive planned but not implemented |

---

## 4. Current Sprint: Trainee Workout Fix + Layout System

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

### 4.3 Acceptance Criteria

- [x] Completing a workout persists all exercise data to DailyLog.workout_data
- [x] Trainer receives notification when trainee starts or finishes a workout
- [x] Trainee sees their real assigned program, not sample data
- [x] No print() debug statements in workout_repository.dart
- [x] Trainee can switch between assigned programs via bottom sheet
- [x] Trainer can set layout type (classic/card/minimal) per trainee
- [x] Trainee's active workout screen renders the correct layout variant
- [x] Default layout is "classic" for all existing trainees (no migration data needed)
- [x] Layout config survives app restart (fetched from API, cached locally)

---

## 5. Roadmap

### Phase 1: Foundation Fix — ✅ COMPLETED
- ~~Fix all 5 bugs~~ ✅ Completed 2026-02-13
- ~~Implement workout layout system~~ ✅ Completed 2026-02-14

### Phase 2: White-Label Infrastructure
- TrainerBranding model: primary_color, secondary_color, logo_url, app_name
- Mobile reads branding config on login, applies to ThemeData
- Each trainer's trainees see the trainer's branding, not "FitnessAI"
- Custom splash screen per trainer

### Phase 3: Web Admin Dashboard
- React/Next.js with shadcn/ui
- Trainer dashboard (program builder, trainee management, analytics)
- Admin dashboard (trainer management, tiers, revenue, platform analytics)
- Shared auth with existing JWT system
- TypeScript interfaces auto-generated from Django serializers

### Phase 4: Ambassador System
- New User role: AMBASSADOR
- Ambassador dashboard: referred trainers, monthly revenue, payout history
- Referral code system
- Revenue sharing logic: ambassador gets X% of each referred trainer's subscription
- Admin can set/adjust ambassador commission rates
- Stripe Connect payout to ambassadors

### Phase 5: Offline-First + Performance
- Drift (SQLite) local database for offline workout logging
- Sync queue for uploading logs when connection returns
- Background health data sync (HealthKit / Health Connect)
- App performance audit (60fps target, RepaintBoundary audit)

### Phase 6: Social & Community
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

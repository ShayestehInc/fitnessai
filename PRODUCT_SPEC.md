# PRODUCT_SPEC.md — FitnessAI Product Specification

> Living document. Describes what the product does, what's built, what's broken, and what's next.
> Last updated: 2026-02-13

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
| Program schedule display (trainee) | ⚠️ Buggy | **BUG-3:** Falls back to sample data too aggressively |
| Active workout screen | ⚠️ Buggy | Works visually but **BUG-1:** data never saves |
| Readiness survey (pre-workout) | ⚠️ Buggy | **BUG-2:** Trainer notification fails |
| Post-workout survey | ⚠️ Buggy | **BUG-1 + BUG-2:** Data lost + notification fails |
| Workout calendar / history | 🟡 Partial | Calendar screen exists but empty (no data persists) |
| Program switcher | ❌ Not done | **BUG-5:** Button exists but no functionality |
| Trainer-selectable workout layouts | ❌ Not done | **Priority 2:** Classic / Card / Minimal variants |
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
| Trainer notifications | ⚠️ Buggy | **BUG-2:** Never fires due to wrong attribute |

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

### 4.1 Bug Fixes Required

**BUG-1 [CRITICAL]: Workout data never persists**
- Location: `backend/workouts/survey_views.py` → `PostWorkoutSurveyView.post()`
- Problem: `# TODO: Save workout log to database` — the save was never implemented
- Impact: 100% data loss on every completed workout
- Fix: Add `_save_workout_to_daily_log()` method that writes to `DailyLog.workout_data` using `get_or_create` for today's date, merging exercises if multiple workouts in one day

**BUG-2 [HIGH]: Trainer notifications never fire**
- Location: `backend/workouts/survey_views.py` → lines ~56 and ~205
- Problem: `getattr(user, 'trainer', None)` — the User model has no `.trainer` attribute. The correct attribute is `user.parent_trainer`
- Impact: Trainer has zero visibility into when trainees are working out
- Fix: Replace with `user.parent_trainer` in both ReadinessSurveyView and PostWorkoutSurveyView

**BUG-3 [HIGH]: Sample data shown instead of real programs**
- Location: `mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`
- Problem: `_parseProgramWeeks()` calls `_generateSampleWeeks()` on any null/empty/failed parse. Real programs with valid schedules get replaced by hardcoded "Push Day / Pull Day / Legs"
- Impact: Trainee can never see their actual assigned program
- Fix: Only use sample data when trainee has zero programs. For empty/null schedules on real programs, show an informative empty state ("Your trainer hasn't built your schedule yet")

**BUG-4 [MEDIUM]: Debug prints in production**
- Location: `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
- Problem: 15+ `print('[WorkoutRepository]...')` statements
- Fix: Delete them all

**BUG-5 [MEDIUM]: Program switcher not implemented**
- Location: `mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart` ~line 362
- Problem: Menu item exists but callback is `// TODO: Show program switcher`
- Fix: Show bottom sheet with all assigned programs, tap to switch active program in provider state

### 4.2 New Feature: Trainer-Selectable Workout Layouts

**Goal:** Trainers choose which workout logging UI their trainees see. Three variants:

| Layout | Description | Best For |
|--------|------------|----------|
| `classic` | Traditional table — all sets visible at once, tap to edit | Experienced lifters who want overview |
| `card` | One set at a time — large input fields, swipe between sets | Beginners, simpler UX |
| `minimal` | Compact list — exercise name + quick-complete toggles | Speed loggers, high-volume training |

**Backend changes:**
- New model: `WorkoutLayoutConfig` in `trainer/models.py`
  - `trainee` (OneToOne → User)
  - `layout_type` (CharField: classic / card / minimal, default: classic)
  - `config_options` (JSONField: future per-layout settings like show_previous, auto_rest_timer)
  - `configured_by` (FK → User, the trainer who set it)
- New endpoints:
  - `GET/PUT /api/trainer/layout-config/<trainee_id>/` — trainer sets layout for trainee
  - `GET /api/trainer/my-layout/` — trainee fetches their own layout config
- Migration: `WorkoutLayoutConfig` table

**Mobile changes:**
- New: `layout_config_provider.dart` — fetches config from `/api/trainer/my-layout/` on app launch
- New: `layout_config_repository.dart` — API calls for layout config
- Modified: `active_workout_screen.dart` — switches between layout widgets based on config
- New widget files:
  - `classic_workout_layout.dart` — existing table-based UI extracted
  - `card_workout_layout.dart` — new one-set-at-a-time card UI
  - `minimal_workout_layout.dart` — new compact list UI
- Trainer side: Layout picker in trainee detail screen (dropdown or segmented control)

### 4.3 Acceptance Criteria

- [ ] Completing a workout persists all exercise data to DailyLog.workout_data
- [ ] Trainer receives notification when trainee starts or finishes a workout
- [ ] Trainee sees their real assigned program, not sample data
- [ ] No print() debug statements in workout_repository.dart
- [ ] Trainee can switch between assigned programs via bottom sheet
- [ ] Trainer can set layout type (classic/card/minimal) per trainee
- [ ] Trainee's active workout screen renders the correct layout variant
- [ ] Default layout is "classic" for all existing trainees (no migration data needed)
- [ ] Layout config survives app restart (fetched from API, cached locally)

---

## 5. Roadmap

### Phase 1: Foundation Fix (Current Sprint)
- Fix all 5 bugs
- Implement workout layout system
- Estimated: 1-2 days of agent pipeline runs

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
  "workout_name": "Push Day",
  "duration": "45:30",
  "post_survey": { ... },
  "readiness_survey": { ... },
  "completed_at": "2026-02-13T11:15:30Z"
}
```

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

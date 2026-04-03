# CLAUDE.md — FitnessAI Project Instructions

> Source of truth for all development. When told to "run the pipeline", see `PIPELINE.md`.

---

## Project Overview

Full-stack fitness platform connecting **Trainers** with **Trainees**, managed by a **Super Admin**. AI-powered workout/nutrition logging via natural language. Built for white-label resale to trainers.

- **Repository:** https://github.com/ShayestehInc/fitnessai
- **Owner:** Shayesteh Inc.

## Tech Stack

| Layer      | Technology            | Version                  |
| ---------- | --------------------- | ------------------------ |
| Backend    | Django REST Framework | 5.0                      |
| Database   | PostgreSQL            | 15+                      |
| Mobile     | Flutter               | 3.0+                     |
| State Mgmt | Riverpod              | 2.0                      |
| Navigation | go_router             | latest                   |
| AI         | OpenAI GPT-4o         | Function Calling         |
| Payments   | Stripe Connect        | latest                   |
| Auth       | Djoser + JWT          | Email-only (no username) |

## Project Structure

```
fitnessai/
├── backend/
│   ├── config/                 # settings.py, urls.py, wsgi/asgi
│   ├── core/                   # Shared permissions, utilities
│   ├── users/                  # Auth, User model (ADMIN/TRAINER/TRAINEE roles)
│   ├── workouts/               # Programs, DailyLog, Exercises, NutritionGoal, MacroPreset
│   │   ├── services/           # Business logic (macro_calculator, natural_language_parser)
│   │   ├── ai_prompts.py       # All AI prompt templates
│   │   └── survey_views.py     # Pre/post workout survey endpoints
│   ├── trainer/                # Trainer dashboard, invitations, impersonation, notifications
│   ├── subscriptions/          # Stripe Connect, tiers, coupons, payments
│   ├── calendars/              # Google/Microsoft calendar integration
│   ├── features/               # Feature request system
│   └── mcp_server/             # MCP server for Claude Desktop integration
├── mobile/
│   └── lib/
│       ├── core/               # api_client, theme, constants, router
│       ├── features/           # Feature-first architecture
│       └── shared/widgets/
├── .claude/agents/             # Subagent definitions (code-reviewer, security-reviewer, polish-reviewer)
├── CLAUDE.md                   # ← You are here
├── PIPELINE.md                 # Autonomous development pipeline instructions
└── PRODUCT_SPEC.md             # Product spec — source of truth for the product
```

## User Roles & Hierarchy

```
ADMIN (Super Admin — platform owner)
  └── TRAINER (Personal trainers — the paying customer)
        └── TRAINEE (End users — the trainer's clients)
```

- `User.parent_trainer` → ForeignKey from trainee to their trainer
- Trainers never see other trainers' data
- Admin can impersonate trainers; trainers can impersonate trainees
- Row-level security enforced in every ViewSet's `get_queryset()`

## Key Models

| Model                               | App      | Purpose                                                             |
| ----------------------------------- | -------- | ------------------------------------------------------------------- |
| `User`                              | users    | AbstractUser with role enum, email-as-username, `parent_trainer` FK |
| `UserProfile`                       | users    | Onboarding data (sex, age, height, weight, goals, diet type)        |
| `Exercise`                          | workouts | Exercise library with v6.5 rich tags                                |
| `DecisionLog`                       | workouts | Audit trail for automated decisions. UUID PK, undo support          |
| `UndoSnapshot`                      | workouts | Before/after state snapshots for reverting decisions                |
| `LiftSetLog`                        | workouts | Per-set performance tracking with canonical load/workload           |
| `LiftMax`                           | workouts | Cached e1RM + Training Max per exercise per trainee                 |
| `SplitTemplate`                     | workouts | Reusable split definitions                                          |
| `TrainingPlan`                      | workouts | Relational plan container (draft/active/completed/archived)         |
| `PlanWeek`/`PlanSession`/`PlanSlot` | workouts | Week → Session → Exercise slot hierarchy                            |
| `SetStructureModality`              | workouts | Set structure modality with guardrails                              |
| `Program`                           | workouts | (Legacy) Assigned to trainee with schedule JSONField                |
| `DailyLog`                          | workouts | Daily log with nutrition_data + workout_data JSONFields             |
| `NutritionGoal`                     | workouts | Daily macro targets (can be trainer-adjusted)                       |
| `TraineeInvitation`                 | trainer  | Invitation codes for onboarding new trainees                        |

## API Endpoint Map

| Area     | Base Path                   | Key Endpoints                                                     |
| -------- | --------------------------- | ----------------------------------------------------------------- |
| Auth     | `/api/auth/`                | `jwt/create/`, `jwt/refresh/`, `users/me/`                        |
| Users    | `/api/users/`               | `profiles/`, `profiles/onboarding/`, `me/`                        |
| Workouts | `/api/workouts/`            | `exercises/`, `programs/`, `daily-logs/`, `training-plans/`, etc. |
| AI Parse | `/api/workouts/daily-logs/` | `parse-natural-language/`, `confirm-and-save/`                    |
| Trainer  | `/api/trainer/`             | `dashboard/`, `trainees/`, `invitations/`, `impersonate/`         |
| Payments | `/api/payments/`            | `connect/onboard/`, `pricing/`, `checkout/subscription/`          |
| Admin    | `/api/admin/`               | `dashboard/`, `trainers/`, `tiers/`, `coupons/`                   |

---

## Backend Conventions (MANDATORY)

1. **Business logic in `services/`** — Views handle request/response only. Serializers handle validation only.
2. **Type hints on everything** — Return types, argument types. No `Any` unless unavoidable.
3. **Prefetching required** — Every queryset with related data MUST use `select_related()` / `prefetch_related()`.
4. **AI prompts in `ai_prompts.py`** — Never inline prompt strings in service logic.
5. **AI responses validated** — Parse with Pydantic/DRF serializer before saving to DB.
6. **Single `settings.py`** — No dev/prod split. Use environment variables.
7. **Row-level security** — Every ViewSet's `get_queryset()` filters by user role. No exceptions.
8. **JSONField for complex data** — Program schedules, daily logs, survey data are all JSON.

## Mobile Conventions (MANDATORY)

1. **Riverpod exclusively** — No `setState` for anything beyond ephemeral animation state.
2. **Max 150 lines per widget file** — Extract sub-widgets into separate files.
3. **Repository pattern** — Screen → Provider → Repository → ApiClient.
4. **Centralized theme** — Use `core/theme/app_theme.dart`. Never hardcode colors/fonts.
5. **`const` constructors everywhere** — Performance requirement.
6. **go_router** — Routes in `core/router/app_router.dart`. Type-safe.
7. **No debug prints** — Remove all `print()` before committing.
8. **API constants centralized** — All endpoint URLs in `core/constants/api_constants.dart`.

---

## Known Bugs

No known bugs at this time (as of 2026-02-14).

## Current Priorities (Ordered)

1. **White-label infrastructure** — Per-trainer branding (colors, logo, app name)
2. **Web admin dashboard** — React/Next.js for trainer + admin
3. **Ambassador user type** — New role with referral revenue sharing

---

## Running the Project

```bash
# Backend (Docker)
docker-compose up -d

# Backend (Manual)
cd backend && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate && python manage.py runserver

# Mobile
cd mobile && flutter pub get && flutter run -d ios

# Deploy to TestFlight (Fastlane)
cd mobile/ios && fastlane beta

# Seed data
docker-compose exec backend python manage.py seed_admin
docker-compose exec backend python manage.py seed_default_trainer
docker-compose exec backend python manage.py seed_exercises
```

## Testing & Linting

```bash
cd backend && python manage.py test
cd mobile && flutter test
cd mobile && flutter analyze
```

## Environment Variables

See `backend/example.env`. Critical: `SECRET_KEY`, `DEBUG`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`.

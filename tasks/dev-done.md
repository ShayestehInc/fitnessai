# Dev Done: Progression Engine (v6.5 Step 7)

## Date: 2026-03-09

## Files Created

- `backend/workouts/services/progression_engine_service.py` — Full progression engine with 5 evaluators and 4 public API functions
- `backend/workouts/management/commands/seed_progression_profiles.py` — Seed 5 system profiles
- `backend/workouts/migrations/0025_progression_engine.py` — Migration for ProgressionProfile, ProgressionEvent, FKs

## Files Modified

- `backend/workouts/models.py` — Added ProgressionProfile model (UUID PK, 5 progression types, rules/deload_rules/failure_rules JSON), ProgressionEvent model (trainee, exercise, plan_slot, event audit trail), TrainingPlan.default_progression_profile FK, PlanSlot.progression_profile FK
- `backend/workouts/serializers.py` — Added ProgressionProfileSerializer, ProgressionProfileListSerializer, ProgressionEventSerializer, ApplyProgressionInputSerializer
- `backend/workouts/views.py` — Added ProgressionProfileViewSet (full CRUD with role-based security), PlanSlotViewSet actions: next-prescription, apply-progression, progression-history, progression-readiness
- `backend/workouts/urls.py` — Registered progression-profiles route

## Key Decisions

1. **Slot override > plan default**: \_get_effective_profile resolves slot.progression_profile first, falls back to plan.default_progression_profile
2. **Gap detection**: >14 days since last session triggers automatic deload to 90% TM
3. **Consecutive failure detection**: Configurable per profile (default 2), triggers deload/reduce per failure_rules
4. **Frozen dataclasses**: NextPrescription, ProgressionReadiness, ProgressionEventResult — immutable return types
5. **Trainer override on apply-progression**: Optional override_sets/reps/load fields let trainers adjust the computed prescription before applying
6. **DecisionLog integration**: Every apply_progression creates a DecisionLog entry with full audit trail

## Progression Types Implemented

1. **Staircase Percent**: Step through TM percentages weekly, scheduled deload
2. **Rep Staircase**: Hold load, climb reps, bump load at top rung
3. **Double Progression**: Earn reps in range, increase load when all sets hit top
4. **Linear**: Fixed weight increment per session/week, deload on failure
5. **Wave-by-Month**: 4-week accumulation/build/intensify/deload cycle

## Edge Cases Handled

- No progression profile assigned → hold prescription
- No LiftMax → hold (no_max blocker)
- No history → hold (no_history)
- Gap > 14 days → auto-deload to 90% TM
- Consecutive failures → deload/reduce per profile rules
- Deload week → skip progression (deload_week blocker)
- Unsupported progression type → hold

## How to Test

1. Seed profiles: `python manage.py seed_progression_profiles`
2. Assign a profile to a plan or slot
3. GET `/api/workouts/plan-slots/{id}/next-prescription/` — see computed prescription
4. GET `/api/workouts/plan-slots/{id}/progression-readiness/` — check blockers
5. POST `/api/workouts/plan-slots/{id}/apply-progression/` — apply and create event
6. GET `/api/workouts/plan-slots/{id}/progression-history/` — view audit trail
7. CRUD on `/api/workouts/progression-profiles/` — manage profiles

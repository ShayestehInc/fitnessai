# Feature: Progression Engine (Staircase + Wave + Deload)

## Priority

Critical — Step 7 of v6.5 build order. Powers automatic load/rep adjustments. Foundation for session runner.

## User Story

As a **trainer**, I want to assign progression profiles to training plans and individual exercises so that my trainees' programs automatically adjust loads and reps based on their performance.

As a **trainee**, I want my next session prescription to be computed automatically based on my progression profile and recent performance so I know exactly what to lift.

## Acceptance Criteria

### Models

- [ ] ProgressionProfile model: name, slug, progression_type (choices), rules JSON, deload_rules JSON, failure_rules JSON, is_system, created_by
- [ ] progression_type choices: staircase_percent, rep_staircase, wave_by_month, double_progression, linear
- [ ] TrainingPlan gets default_progression_profile FK (nullable)
- [ ] PlanSlot gets progression_profile FK (nullable, overrides plan default)
- [ ] ProgressionEvent model: trainee, exercise, plan_slot FK, event_type (progression/deload/failure/reset/hold), old_prescription JSON, new_prescription JSON, reason_codes, decision_log FK
- [ ] All models use UUID primary keys

### Progression Rules (from packet)

- [ ] Staircase Percent: increase intensity +2.5-5% TM per week, 3-6 work weeks then deload, failure→repeat or reduce 2.5-5%
- [ ] Rep Staircase: hold load, climb reps (+1/wk), at top rung increase load (+2.5-5lb upper, +5-10lb lower), reset reps
- [ ] Double Progression: earn reps in range, when all sets hit top at target RIR, increase load, reps reset to low end
- [ ] Linear: +2.5-10lb per session/week, if fail twice deload 5-10% and rebuild
- [ ] Wave-by-Month: 4-week wave (accumulation 65-75%, build 70-80%, intensify 75-85%, deload 60-70%)
- [ ] Auto-progression gated by: completion, effort (RIR ±1), no pain flags

### Progression Service

- [ ] compute_next_prescription(slot, trainee_id) → NextPrescription dataclass
- [ ] evaluate_progression_readiness(slot, trainee_id) → ProgressionReadiness dataclass
- [ ] apply_progression(slot, prescription, actor_id) → ProgressionEvent
- [ ] get_progression_history(slot) → list of ProgressionEvents
- [ ] All decisions logged via DecisionLog

### API Endpoints

- [ ] CRUD for ProgressionProfile
- [ ] GET /plan-slots/{id}/next-prescription/
- [ ] POST /plan-slots/{id}/apply-progression/
- [ ] GET /plan-slots/{id}/progression-history/
- [ ] Row-level security on all endpoints

### Seed Data

- [ ] 5 system profiles: Staircase Percent, Rep Staircase, Double Progression, Linear, Wave-by-Month

## Edge Cases

1. No LiftMax for exercise — return "no_max" blocker
2. No LiftSetLog history — use plan prescription as-is
3. Gap > 2 weeks — deload 10% before resuming
4. Two consecutive failures — trigger deload
5. Slot profile overrides plan default
6. Deload week — skip progression, use deload modifiers
7. Exercise swapped mid-plan — reset progression
8. Multiple qualifying sets in same session — use best set
9. Rep staircase at top rung but load exceeds equipment — cap
10. TM changed by trainer — recalculate from new TM

## Technical Approach

- Models in `backend/workouts/models.py`
- Service in `backend/workouts/services/progression_engine_service.py`
- Serializers/views/urls in respective files
- Seed command `seed_progression_profiles.py`
- Migration

## Out of Scope

- Session runner UI (Step 8)
- End-of-session feedback (Step 9)
- DUP/WUP/Block/Concurrent periodization (defer)
- AI-powered profile selection

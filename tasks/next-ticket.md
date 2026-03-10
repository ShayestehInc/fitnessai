# Feature: Modality Library with Counting Rules and Guardrails

## Priority

Critical — Step 6 of v6.5 build order. Foundation for progression engine, session runner, and workload accuracy.

## User Story

As a **trainer**, I want each exercise slot in a training plan to have a set structure modality (straight sets, drop sets, myo-reps, supersets, etc.) so that my trainees get properly structured sessions with accurate volume tracking.

As a **trainee**, I want my plan to show exactly how each exercise should be performed (straight sets vs drop sets vs rest-pause, etc.) so I know the execution format, not just sets × reps.

## Acceptance Criteria

### Models

- [ ] SetStructureModality model with name, slug, description, volume_multiplier, use_when, avoid_when, is_system, created_by
- [ ] ModalityGuardrail model with modality FK, rule_type (use/avoid), condition_field, condition_operator, condition_value, error_message, is_active
- [ ] PlanSlot gets new fields: set_structure_modality FK (nullable), modality_details JSON, modality_volume_contribution Decimal
- [ ] All models use UUID primary keys
- [ ] 8 system modalities seeded: Straight Sets, Down Sets, Controlled Eccentrics, Giant Sets, Myo-reps, Drop Sets, Supersets, Occlusion

### Counting Rules (from packet)

- [ ] Straight Sets: 1.0x per working set
- [ ] Down Sets: 1.0x per working set
- [ ] Controlled Eccentrics: 1.0x per working set
- [ ] Giant Sets: 0.67x per set for primary muscle
- [ ] Myo-reps: 0.67x per mini-set (override to 1.0x if fatigue high)
- [ ] Drop Sets: 0.67x per drop set
- [ ] Supersets: pre-exhaust 2.0x (or 1.5x); non-overlapping 2.0x total (1.0 per muscle)
- [ ] Occlusion: 0.67x per working set

### Guardrails (from packet)

- [ ] Athletic movements (has athletic_skill_tags) cannot use drop sets, myo-reps, rest-pause, or metabolite circuits
- [ ] Heavy compounds in 5-10 rep range cannot use drop sets
- [ ] Controlled eccentrics avoid 20+ rep hypertrophy sets
- [ ] Occlusion avoid on compounds/core, max 1 mesocycle per muscle
- [ ] If exercise is systemically fatiguing → ban drop sets + myo-reps (unless coach override)
- [ ] If user doesn't have stable volume landmarks → ban giant sets
- [ ] Guardrail violations return clear error messages, not silent failures
- [ ] Trainer can override any guardrail with a DecisionLog entry

### Generator Integration

- [ ] A5 step enhanced: after setting sets/reps/rest, assign default modality based on goal + slot_role
- [ ] Default modality assignment: compounds get Straight Sets, accessories get Straight Sets or Down Sets, isolation can get varied modalities based on goal
- [ ] Modality assignment creates DecisionLog entry
- [ ] modality_volume_contribution computed: sets × volume_multiplier

### Modality Service

- [ ] get_modality_recommendations(slot_role, goal, exercise) → ranked list of valid modalities
- [ ] validate_modality_for_slot(modality, slot, exercise) → list of guardrail violations
- [ ] apply_modality_to_slot(slot, modality, actor_id) → updated slot + DecisionLog
- [ ] compute_volume_contribution(slot) → Decimal volume contribution
- [ ] get_session_volume_summary(session_id) → per-muscle volume with modality multipliers

### API Endpoints

- [ ] GET /api/workouts/modalities/ — list all modalities (system + trainer-created)
- [ ] POST /api/workouts/modalities/ — create custom modality (trainer only)
- [ ] GET/PUT/DELETE /api/workouts/modalities/{id}/ — CRUD
- [ ] GET /api/workouts/plan-slots/{id}/modality-recommendations/ — ranked valid modalities for slot
- [ ] POST /api/workouts/plan-slots/{id}/set-modality/ — apply modality to slot with guardrail check
- [ ] GET /api/workouts/plan-sessions/{id}/volume-summary/ — per-muscle volume with modality multipliers
- [ ] Row-level security on all endpoints

### Conventions

- [ ] All service methods return dataclasses, not dicts
- [ ] Business logic in services/, not views
- [ ] Type hints on all functions
- [ ] No raw queries — Django ORM only
- [ ] Proper prefetching on all querysets

## Edge Cases

1. Slot has no modality assigned — default to Straight Sets (volume_multiplier=1.0)
2. Trainer creates custom modality with multiplier > 2.0 — validate max 3.0x
3. Guardrail violation on modality assignment — return all violations, don't apply
4. Trainer overrides guardrail — create DecisionLog with override=True, apply modality
5. Exercise has no athletic_skill_tags — skip athletic guardrail check
6. Superset modality applied to slot — require paired_exercise_id in modality_details
7. Myo-reps with high fatigue override — multiplier changes from 0.67 to 1.0
8. Slot already has modality, re-assign — create UndoSnapshot before changing
9. Volume summary with mixed modalities in session — aggregate correctly per muscle
10. Deload week slots — force Straight Sets modality, ignore other assignments

## Technical Approach

- Add models to `backend/workouts/models.py`
- Create `backend/workouts/services/modality_service.py`
- Enhance `backend/workouts/services/training_generator_service.py` A5 step
- Add serializers to `backend/workouts/serializers.py`
- Add views to `backend/workouts/views.py`
- Register routes in `backend/workouts/urls.py`
- Generate migration

## Out of Scope

- Progression engine integration (Step 7)
- Session runner UI (Step 8)
- AI-powered modality selection
- Per-set modality tracking in LiftSetLog (modality is at PlanSlot level)

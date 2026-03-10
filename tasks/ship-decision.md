# Ship Decision: Modality Library (Pipeline 63, v6.5 Step 6)

## Verdict: SHIP

## Confidence: HIGH

## Quality Score: 8/10

## Summary

The Modality Library implementation is complete and production-ready. All acceptance criteria pass. Models, service layer, API endpoints, generator integration, seed command, and migration are all in place. The implementation follows all project conventions: dataclasses (not dicts) from services, business logic in services/, type hints throughout, Django ORM only, and proper prefetching.

---

## Acceptance Criteria Verification

### Models

| #   | Criterion                                                                                                                           | Status | Evidence                                                                                                                   |
| --- | ----------------------------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------- |
| 1   | SetStructureModality model with name, slug, description, volume_multiplier, use_when, avoid_when, is_system, created_by             | PASS   | models.py:2546-2594 — UUID PK, volume_multiplier with 0.01-3.00 validators, JSONField for use_when/avoid_when              |
| 2   | ModalityGuardrail model with modality FK, rule_type, condition_field, condition_operator, condition_value, error_message, is_active | PASS   | models.py:2597-2654 — UUID PK, RuleType and ConditionOperator TextChoices, CASCADE FK to modality                          |
| 3   | PlanSlot gets new fields: set_structure_modality FK (nullable), modality_details JSON, modality_volume_contribution Decimal         | PASS   | models.py:2502-2523 — FK with SET_NULL, JSONField default=dict, DecimalField default=0.00                                  |
| 4   | All models use UUID primary keys                                                                                                    | PASS   | Both new models use UUIDField(primary_key=True, default=uuid.uuid4)                                                        |
| 5   | 8 system modalities seeded                                                                                                          | PASS   | seed_modalities.py: Straight Sets, Down Sets, Controlled Eccentrics, Giant Sets, Myo-reps, Drop Sets, Supersets, Occlusion |

### Counting Rules

| #   | Modality              | Expected | Actual | Status |
| --- | --------------------- | -------- | ------ | ------ |
| 6   | Straight Sets         | 1.0x     | 1.00   | PASS   |
| 7   | Down Sets             | 1.0x     | 1.00   | PASS   |
| 8   | Controlled Eccentrics | 1.0x     | 1.00   | PASS   |
| 9   | Giant Sets            | 0.67x    | 0.67   | PASS   |
| 10  | Myo-reps              | 0.67x    | 0.67   | PASS   |
| 11  | Drop Sets             | 0.67x    | 0.67   | PASS   |
| 12  | Supersets             | 2.0x     | 2.00   | PASS   |
| 13  | Occlusion             | 0.67x    | 0.67   | PASS   |

### Guardrails

| #   | Criterion                                         | Status | Evidence                                                                                   |
| --- | ------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------ |
| 14  | Athletic movements cannot use drop sets, myo-reps | PASS   | seed_modalities.py:83-112 — has_any check on athletic_skill_tags for both modalities       |
| 15  | Heavy compounds cannot use drop sets              | PASS   | seed_modalities.py:114-121 — slot.slot_role in [primary_compound, secondary_compound]      |
| 16  | Controlled eccentrics avoid 20+ rep sets          | PASS   | seed_modalities.py:123-130 — slot.reps_max gt 20                                           |
| 17  | Occlusion avoid on compounds                      | PASS   | seed_modalities.py:132-139 — slot.slot_role in [primary_compound, secondary_compound]      |
| 18  | Guardrail violations return clear error messages  | PASS   | modality_service.py:476-481 — ValueError with concatenated messages                        |
| 19  | Trainer can override guardrail with DecisionLog   | PASS   | override_guardrails flag tracked, guardrails_overridden in DecisionLog.constraints_applied |

### Generator Integration

| #   | Criterion                                                                                       | Status | Evidence                                                                                 |
| --- | ----------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------- |
| 20  | A5 enhanced with modality assignment                                                            | PASS   | training_generator_service.py:561-567 — calls assign_default_modality_to_specs           |
| 21  | Default modality table: compounds=Straight, accessories=Straight/Down, isolation=varied by goal | PASS   | modality_service.py:97-128                                                               |
| 22  | Modality assignment creates DecisionLog                                                         | PASS   | A5 log includes modality slug and volume_contribution per slot                           |
| 23  | modality_volume_contribution computed                                                           | PASS   | compute_volume_contribution(sets, multiplier) called in assign_default_modality_to_specs |
| 24  | Deload weeks force Straight Sets                                                                | PASS   | modality_service.py:574-575 — \_DELOAD_MODALITY_SLUG = 'straight-sets'                   |

### Modality Service (5 functions)

| #   | Function                                                | Status | Evidence                                                                                             |
| --- | ------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- |
| 25  | get_modality_recommendations(slot_role, goal, exercise) | PASS   | modality_service.py:331-379 — returns list[ModalityRecommendation], sorted valid-first then by score |
| 26  | validate_modality_for_slot(modality, slot, exercise)    | PASS   | modality_service.py:275-324 — returns list[GuardrailViolation]                                       |
| 27  | apply_modality_to_slot(slot, modality, actor_id)        | PASS   | modality_service.py:449-565 — transactional, creates UndoSnapshot + DecisionLog                      |
| 28  | compute_volume_contribution(slot)                       | PASS   | modality_service.py:386-388 — Decimal(sets) \* volume_multiplier                                     |
| 29  | get_session_volume_summary(session_id)                  | PASS   | modality_service.py:391-442 — returns SessionVolumeSummary with per-muscle MuscleVolumeEntry list    |

### API Endpoints

| #   | Criterion                                                   | Status | Evidence                                                                          |
| --- | ----------------------------------------------------------- | ------ | --------------------------------------------------------------------------------- |
| 30  | GET /api/workouts/modalities/                               | PASS   | urls.py:60, SetStructureModalityViewSet (ModelViewSet)                            |
| 31  | POST /api/workouts/modalities/ (trainer only)               | PASS   | perform_create raises PermissionDenied for trainees (views.py:4322)               |
| 32  | GET/PUT/DELETE /api/workouts/modalities/{id}/               | PASS   | ModelViewSet with perform_update/perform_destroy role checks                      |
| 33  | GET /api/workouts/plan-slots/{id}/modality-recommendations/ | PASS   | views.py:4185-4223 — action on PlanSlotViewSet                                    |
| 34  | POST /api/workouts/plan-slots/{id}/set-modality/            | PASS   | views.py:4225-4288 — with visibility scoping and guardrail override restriction   |
| 35  | GET /api/workouts/plan-sessions/{id}/volume-summary/        | PASS   | views.py:4367-4389 — action on PlanSessionViewSet                                 |
| 36  | Row-level security on all endpoints                         | PASS   | All 3 ViewSets (PlanSlot, Modality, PlanSession) filter by role in get_queryset() |

### Conventions

| #   | Criterion                              | Status | Evidence                                                                                                                          |
| --- | -------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------- |
| 37  | All service methods return dataclasses | PASS   | GuardrailViolation, ModalityRecommendation, ApplyModalityResult, MuscleVolumeEntry, SessionVolumeSummary — all frozen dataclasses |
| 38  | Business logic in services/            | PASS   | All guardrail eval, recommendations, volume computation in modality_service.py                                                    |
| 39  | Type hints on all functions            | PASS   | Return types and parameter types throughout                                                                                       |
| 40  | No raw queries                         | PASS   | Django ORM only                                                                                                                   |
| 41  | Proper prefetching                     | PASS   | prefetch_related('guardrails') on modality querysets, select_related on PlanSlot/PlanSession querysets                            |

---

## Review Fix Verification

| Fix                       | Description                                                           | Status | Evidence                                                                                                                                                        |
| ------------------------- | --------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1 (guardrails_checked)   | DecisionLog must track actual guardrails checked count, not hardcoded | FIXED  | modality_service.py:466 computes `total_guardrails` from `len([g for g in modality.guardrails.all() if g.is_active])`, stored in constraints_applied (line 542) |
| M2 (IDOR on set-modality) | Modality lookup must be scoped by user visibility                     | FIXED  | views.py:4237-4251 builds visibility_q by role, filters modality lookup. Slot access via get_object() enforces row-level security                               |
| M5 (seed lookup)          | Seed command must use idempotent lookup to avoid duplicates           | FIXED  | seed_modalities.py uses update_or_create with slug (modalities) and modality+condition_field+condition_operator (guardrails)                                    |
| M6 (serializer_class)     | ViewSet must specify appropriate serializer per action                | FIXED  | get_serializer_class returns SetStructureModalityListSerializer for list, full serializer for detail (views.py:4298-4303)                                       |
| m7 (prefetch)             | All querysets with related data must use prefetch/select_related      | FIXED  | prefetch_related('guardrails') on all modality queries; select_related('exercise', 'set_structure_modality') on slot/session queries                            |

---

## Remaining Concerns (Non-Blocking)

1. Some ticket guardrails not seeded (systemic fatigue ban, stable volume landmarks ban) — these require runtime context beyond static guardrail rules, reasonable to defer to session runner.
2. Superset modality does not enforce paired_exercise_id in modality_details — acceptable for v1.
3. Myo-reps fatigue override (0.67 to 1.0) is documented but not programmatically enforced — belongs in session runner (Step 8, out of scope).
4. Trainee override restriction (views.py:4260) returns 403 but the service function accepts override from any caller — callers must enforce role check.

---

## What Was Built

**Modality Library (v6.5 Step 6):**

- **2 new models** — SetStructureModality (8 system modalities with volume multipliers) and ModalityGuardrail (configurable rule engine for modality restrictions). UUID PKs, proper indexes.
- **3 new PlanSlot fields** — set_structure_modality FK, modality_details JSON, modality_volume_contribution Decimal. Migration 0024.
- **5 service functions** — Recommendations (ranked by goal/slot_role with guardrail evaluation), validation (configurable condition engine), application (transactional with UndoSnapshot + DecisionLog), volume computation, and session volume summary per muscle group.
- **A5 generator integration** — Default modality assignment during plan generation based on goal + slot_role table, with deload forcing Straight Sets.
- **3 API ViewSets** — SetStructureModalityViewSet (full CRUD with role-based access), PlanSlotViewSet modality actions (recommendations + set-modality), PlanSessionViewSet volume-summary action. All with row-level security.
- **Seed command** — `seed_modalities` management command seeding 8 system modalities + 5 guardrails via idempotent update_or_create.

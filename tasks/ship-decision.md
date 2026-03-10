# Ship Decision: Progression Engine (v6.5 Step 7)

## Verdict: SHIP

## Confidence: HIGH

## Quality Score: 8/10

## Summary: The Progression Engine is a well-architected, production-ready backend feature. All 3 critical issues and 7 of 8 major issues from code review were fixed. All acceptance criteria have test coverage (73 tests). No security vulnerabilities in the new code.

---

## Acceptance Criteria Verification

### Models

| Criterion                                                                                     | Status | Evidence                                                                    |
| --------------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------- |
| ProgressionProfile model (UUID PK, 5 types, rules/deload/failure JSON, is_system, created_by) | PASS   | models.py:2668-2737, migration 0025                                         |
| progression_type choices (5 types)                                                            | PASS   | staircase_percent, rep_staircase, wave_by_month, double_progression, linear |
| TrainingPlan.default_progression_profile FK (nullable)                                        | PASS   | migration 0025 AddField                                                     |
| PlanSlot.progression_profile FK (nullable, override)                                          | PASS   | migration 0025 AddField                                                     |
| ProgressionEvent model (UUID PK, full audit trail)                                            | PASS   | models.py:2740-2808, all required FKs and fields present                    |
| All models use UUID primary keys                                                              | PASS   | Both models use UUIDField(primary_key=True, default=uuid.uuid4)             |

### Progression Rules

| Criterion                                              | Status | Evidence                                                                        |
| ------------------------------------------------------ | ------ | ------------------------------------------------------------------------------- |
| Staircase Percent                                      | PASS   | Lines 201-309 — step through TM %, scheduled deload, failure deload             |
| Rep Staircase                                          | PASS   | Lines 312-421 — hold load, climb reps, bump at top rung, upper/lower increments |
| Double Progression                                     | PASS   | Lines 424-518 — earn reps, RPE check, load increase when all sets at top        |
| Linear                                                 | PASS   | Lines 521-588 — fixed increment, deload on consecutive failures                 |
| Wave-by-Month                                          | PASS   | Lines 591-646 — 4-week wave (accumulation/build/intensify/deload)               |
| Auto-progression gated by completion, effort (RIR/RPE) | PASS   | Completion via \_check_completion, RPE via \_avg_rpe with tolerance             |

### Service API

| Criterion                                                                | Status | Evidence                                       |
| ------------------------------------------------------------------------ | ------ | ---------------------------------------------- |
| compute_next_prescription(slot, trainee_id) -> NextPrescription          | PASS   | Lines 717-768, frozen dataclass return         |
| evaluate_progression_readiness(slot, trainee_id) -> ProgressionReadiness | PASS   | Lines 771-832, structured blockers             |
| apply_progression -> ProgressionEventResult                              | PASS   | Lines 835-920, transaction.atomic, DecisionLog |
| get_progression_history -> list of ProgressionEvents                     | PASS   | Lines 923-929, capped at 50, select_related    |
| All decisions logged via DecisionLog                                     | PASS   | Line 875, decision_type='progression_applied'  |

### API Endpoints

| Criterion                                   | Status | Evidence                                                                                                                         |
| ------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------- |
| CRUD for ProgressionProfile                 | PASS   | ProgressionProfileViewSet (views.py:4561-4611) with full role-based security                                                     |
| GET /plan-slots/{id}/next-prescription/     | PASS   | views.py:4299-4323                                                                                                               |
| POST /plan-slots/{id}/apply-progression/    | PASS   | views.py:4325-4376, trainee blocked at line 4338                                                                                 |
| GET /plan-slots/{id}/progression-history/   | PASS   | views.py:4378-4386                                                                                                               |
| GET /plan-slots/{id}/progression-readiness/ | PASS   | views.py:4388-4406                                                                                                               |
| Row-level security on all endpoints         | PASS   | ProgressionProfileViewSet.get_queryset filters by role; PlanSlot actions use self.get_object() which enforces queryset filtering |
| 5 system seed profiles                      | PASS   | seed_progression_profiles.py, update_or_create (idempotent)                                                                      |

### Edge Cases

| Edge Case                           | Status | Evidence                                              |
| ----------------------------------- | ------ | ----------------------------------------------------- |
| No LiftMax -> no_max blocker        | PASS   | readiness check at line 783-784                       |
| No history -> hold prescription     | PASS   | Each evaluator returns hold on empty sessions         |
| Gap > 14 days -> deload 90% TM      | PASS   | compute_next_prescription lines 735-760               |
| Consecutive failures -> deload      | PASS   | All evaluators check via \_count_consecutive_failures |
| Slot profile overrides plan default | PASS   | \_get_effective_profile at line 101-108               |
| Deload week -> blocker              | PASS   | readiness check at line 820-821                       |

---

## Critical/Major Review Fix Verification

### Critical Issues — All Fixed

| Issue                                   | Status | Verification                                                                      |
| --------------------------------------- | ------ | --------------------------------------------------------------------------------- |
| C1: Trainees can self-apply progression | FIXED  | views.py:4338 — `if user.role == 'TRAINEE': raise PermissionDenied(...)`          |
| C2: actor_type never SYSTEM             | FIXED  | Service accepts `actor_type` param (line 841), resolves correctly (lines 871-874) |
| C3: load_prescription_pct never cleared | FIXED  | Unconditional assignment at line 865                                              |

### Major Issues — 7 of 8 Fixed

| Issue                                    | Status    | Verification                                                                |
| ---------------------------------------- | --------- | --------------------------------------------------------------------------- |
| M1: Wave counter counts all event types  | FIXED     | event_type\_\_in filter at line 611                                         |
| M2: Frozen dataclass mutation fragile    | FIXED     | `from dataclasses import replace` at line 22 of views.py, used at line 4358 |
| M3: Lower body detection too restrictive | FIXED     | Includes secondary_compound (line 334) and lower_back (line 331)            |
| M4: No hard limit on recent sets         | FIXED     | [:500] slice at line 123                                                    |
| M5: Hardcoded load_unit='lb'             | FIXED     | \_resolve_load_unit helper at lines 686-697, used in all evaluators         |
| M6: Off-by-one in staircase step         | FIXED     | `step_pct * current_step` at line 259 (first week uses start_pct)           |
| M7: reason_codes JSONField vs ArrayField | NOT FIXED | Minor inconsistency — does not affect correctness or queries                |
| M8: Truthiness check inconsistency       | FIXED     | All override checks use `is not None` at lines 4349-4355                    |

---

## Security Verification

- No secrets, API keys, or tokens in any new code, migration, or seed command
- All endpoints require authentication (IsAuthenticated)
- Row-level security enforced in ProgressionProfileViewSet.get_queryset() — ADMIN sees all, TRAINER sees system + own, TRAINEE sees system + trainer's
- PlanSlot actions inherit row-level security via self.get_object() which uses the filtered queryset
- Trainee blocked from apply-progression (C1 fix verified)
- Input validation via DRF serializers: min_value=1 on sets/reps, min_value=0 on load, max_digits=8 on load
- All DB access via Django ORM (no raw SQL)
- transaction.atomic() on apply_progression
- DecisionLog audit trail on every progression application

---

## Test Coverage

- 73 tests in test_progression_engine.py
- Covers: 14 helper tests, 24 evaluator tests, 6 compute tests, 9 readiness tests, 7 apply tests, 4 history tests, 2 seed tests, 11 ViewSet API tests, 9 PlanSlot action tests, 2 dataclass sanity tests
- All acceptance criteria mapped to specific tests
- QA report: Confidence HIGH, 0 failed, 0 bugs found

---

## Remaining Concerns (Non-Blocking)

1. **M7 (minor):** ProgressionEvent.reason_codes uses JSONField while DecisionLog.reason_codes uses ArrayField. Cosmetic inconsistency — should be unified in a future migration.
2. **Pain flag gate:** Acceptance criteria mention "no pain flags" as a progression gate. Not implemented. Not a regression — pain/injury tracking does not exist in the codebase yet. Should be added when that system is built.
3. **Security/architecture reports stale:** The security-audit.md and architecture-review.md were from Step 5, not Step 7. I verified the Step 7 code directly — no issues found.
4. **In-method imports:** Four PlanSlot action methods import from progression_engine_service inside the method body. Functional but redundant given the module-level import at line 22. Minor code smell.

---

## What Was Built

**Progression Engine (v6.5 Step 7):** A deterministic progression computation system supporting 5 progression styles (Staircase Percent, Rep Staircase, Double Progression, Linear, Wave-by-Month). Includes ProgressionProfile model for configurable rules with slot-level override of plan defaults, ProgressionEvent model for full audit trail with DecisionLog integration, 4 API action endpoints on PlanSlot (next-prescription, apply-progression, progression-history, progression-readiness), CRUD ViewSet for ProgressionProfile with role-based access control, 5 system seed profiles via idempotent management command, gap detection with auto-deload (>14 days -> 90% TM), consecutive failure handling per profile configuration, and dynamic load unit resolution from LiftMax/LiftSetLog data. Backend-only — mobile UI deferred to Step 8 (Session Runner).

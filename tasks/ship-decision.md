# Ship Decision: Training Generator Pipeline + Swap System (v6.5 Step 5)

## Verdict: SHIP

## Confidence: HIGH

## Quality Score: 9/10

## Summary

All 5 critical issues (C1-C5) and all 8 major issues (M1-M8) from the code review have been verified as fixed in the actual code. The security audit's primary concern (swap exercise privacy) was addressed. The architecture review gave 9/10 APPROVE. Every acceptance criterion passes. The implementation is well-structured, fully transactional, and follows all project conventions.

---

## Acceptance Criteria Verification

### Models

| #   | Criterion                                                                                           | Status | Evidence                                                                                                                                                           |
| --- | --------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | TrainingPlan model with trainee FK, name, goal, status, created_by                                  | PASS   | models.py:2271-2343 — UUID PK, Status TextChoices, GoalType TextChoices, trainee FK with CASCADE, split_template FK, indexes on (trainee, status) and (created_by) |
| 2   | PlanWeek model with plan FK, week_number, is_deload, modifiers                                      | PASS   | models.py:2346-2388 — UUID PK, intensity/volume DecimalFields with 0.30-2.00 validators, unique_week_per_plan constraint                                           |
| 3   | PlanSession model with week FK, day_of_week, label, order                                           | PASS   | models.py:2391-2436 — UUID PK, DayOfWeek IntegerChoices, unique_session_per_day_per_week constraint                                                                |
| 4   | PlanSlot model with all prescription fields + swap cache                                            | PASS   | models.py:2439-2521 — UUID PK, SlotRole TextChoices, sets/reps/rest with validators, swap_options_cache JSONField, PROTECT on exercise FK                          |
| 5   | SplitTemplate model with name, days_per_week, session_definitions, goal_type, is_system, created_by | PASS   | models.py:2209-2268 — UUID PK, GoalType TextChoices, session_definitions JSONField, indexes on (days_per_week, goal_type) and (is_system)                          |
| 6   | All models use UUID primary keys                                                                    | PASS   | All 5 new models use `UUIDField(primary_key=True, default=uuid.uuid4, editable=False)`                                                                             |
| 7   | Proper unique constraints and indexes                                                               | PASS   | 3 unique constraints + 6 indexes across all models                                                                                                                 |

### Generator Pipeline

| #   | Criterion                              | Status | Evidence                                                                                           |
| --- | -------------------------------------- | ------ | -------------------------------------------------------------------------------------------------- |
| 8   | A1: SELECT_PROGRAM_LENGTH              | PASS   | training_generator_service.py:303-327 — user-specified or goal-default                             |
| 9   | A2: SELECT_SPLIT_TEMPLATE              | PASS   | training_generator_service.py:330-398 — explicit ID or auto-select by days/goal                    |
| 10  | A3: BUILD_WEEKLY_SLOT_SKELETON         | PASS   | training_generator_service.py:401-492 — creates PlanWeek, PlanSession, and SlotSpec (not PlanSlot) |
| 11  | A4: ASSIGN_SLOT_ROLE                   | PASS   | training_generator_service.py:495-530 — position-based role assignment                             |
| 12  | A5: SET_SET_STRUCTURE                  | PASS   | training_generator_service.py:533-573 — 24-combo scheme table                                      |
| 13  | A6: SELECT_EXERCISE                    | PASS   | training_generator_service.py:576-662 — per-week used_ids, progressive fallback                    |
| 14  | A7: BUILD_SWAP_RECOMMENDATIONS         | PASS   | training_generator_service.py:665-745 — fully in-memory, zero per-slot queries                     |
| 15  | Each step creates DecisionLog          | PASS   | 7 `_log_decision()` calls, all IDs collected in `decision_log_ids`                                 |
| 16  | Pipeline is transactional              | PASS   | `transaction.atomic()` wrapping entire pipeline (line 787)                                         |
| 17  | Pipeline returns complete TrainingPlan | PASS   | `GeneratePlanResult` frozen dataclass with plan_id, counts, log IDs                                |

### Swap System

| #   | Criterion                                        | Status | Evidence                                                             |
| --- | ------------------------------------------------ | ------ | -------------------------------------------------------------------- |
| 18  | Same Muscle tab                                  | PASS   | swap_service.py:112-126 — cached + dynamic fallback                  |
| 19  | Same Pattern tab                                 | PASS   | swap_service.py:129-145 — pattern_tags overlap query                 |
| 20  | Explore All tab                                  | PASS   | swap_service.py:148-160 — all exercises with privacy filter          |
| 21  | Swap execution with DecisionLog + UndoSnapshot   | PASS   | swap_service.py:188-315 — both created in transaction                |
| 22  | Swap preserves set/rep prescription              | PASS   | Line 251: prescription intentionally preserved                       |
| 23  | Pre-computed swap_seed_ids with dynamic fallback | PASS   | Lines 704-726: checks seed_data first, falls back to in-memory pools |

### API Endpoints

| #   | Criterion                               | Status | Evidence                                        |
| --- | --------------------------------------- | ------ | ----------------------------------------------- |
| 24  | CRUD for TrainingPlan with nested reads | PASS   | views.py:3919-4058, urls.py:55                  |
| 25  | POST generate/                          | PASS   | views.py:4000-4034                              |
| 26  | GET swap-options/                       | PASS   | views.py:4091-4142                              |
| 27  | POST swap/                              | PASS   | views.py:4144-4179                              |
| 28  | CRUD for SplitTemplate                  | PASS   | views.py:4182-4230, urls.py:57                  |
| 29  | Row-level security on all endpoints     | PASS   | All 3 ViewSets filter by role in get_queryset() |

### Conventions

| #   | Criterion                              | Status | Evidence                                                                            |
| --- | -------------------------------------- | ------ | ----------------------------------------------------------------------------------- |
| 30  | Services return dataclasses, not dicts | PASS   | GeneratePlanResult, SwapOptions, SwapResult, SwapCandidate — all frozen dataclasses |
| 31  | Business logic in services/            | PASS   | Generator pipeline and swap logic fully in service modules                          |
| 32  | Type hints on all functions            | PASS   | Verified throughout both services and views                                         |
| 33  | No raw queries                         | PASS   | Django ORM exclusively                                                              |
| 34  | Proper prefetching                     | PASS   | List vs detail queryset split, annotated weeks_count                                |

---

## Critical Review Issues (C1-C5) — All Fixed

| Issue | Description                                                 | Status | Verification                                                                                                               |
| ----- | ----------------------------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------- |
| C1    | PlanSlot.exercise FK null in skeleton                       | FIXED  | SlotSpec dataclass used during A3-A5, PlanSlot created only after A6 via `_specs_to_plan_slots()` with explicit null check |
| C2    | used_ids global across all weeks                            | FIXED  | `used_ids: set[int] = set()` reset per week in `_a6_select_exercises()` (line 604)                                         |
| C3    | IDOR on SplitTemplate for trainees with null parent_trainer | FIXED  | `if user.parent_trainer_id is not None` guard in get_queryset (line 4202)                                                  |
| C4    | Trainee can create/update/delete SplitTemplates             | FIXED  | `PermissionDenied` raised in perform_create (4208), perform_update (4217), perform_destroy (4226)                          |
| C5    | Cached swap IDs bypass privacy filter                       | FIXED  | `privacy_q` applied on all three cached ID queries (lines 116-117, 131-132, 150-151)                                       |

## Major Review Issues (M1-M8) — All Fixed

| Issue | Description                                   | Status | Verification                                                                                                                        |
| ----- | --------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| M1    | N+1 on weeks_count in list serializer         | FIXED  | `annotate(weeks_count=Count('weeks'))` on list queryset (line 3943-3944), `IntegerField(read_only=True)` in serializer (line 1429)  |
| M2    | Overfetching on list endpoint                 | FIXED  | `self.action == 'list'` check in get_queryset (line 3940), lightweight select_related + annotate for list, full prefetch for detail |
| M3    | A7 fires N queries per slot                   | FIXED  | In-memory pools built from `all_exercises` list (lines 682-691), zero DB queries in A7 loop                                         |
| M4    | perform_create response broken                | FIXED  | `create()` overridden to return `TrainingPlanSerializer(plan).data` (line 3980)                                                     |
| M5    | Deep FK traversal without guaranteed prefetch | FIXED  | View passes plan_id/week_id/session_id explicitly to service (lines 4166-4168)                                                      |
| M6    | Exercise pool fetched twice                   | FIXED  | Single `_prefetch_exercise_pool()` call shared between A6 and A7 (lines 818-823)                                                    |
| M7    | Activate sets old plans to ARCHIVED           | FIXED  | Changed to `COMPLETED` (line 4045) with semantic comment                                                                            |
| M8    | session_definitions length not validated      | FIXED  | Cross-field `validate()` method in SplitTemplateSerializer (lines 1509-1521)                                                        |

## Security Audit Verification

| Issue                                       | Severity | Status                                                                                                                 |
| ------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| Swap exercise privacy (execute_swap)        | Medium   | FIXED — `trainer_id` parameter + `privacy_q` filter in execute_swap (lines 208-213)                                    |
| Split template privacy on explicit ID in A2 | Low      | NOT FIXED — bare `SplitTemplate.objects.get(pk=...)`. Acceptable: UUID unpredictability makes exploitation impractical |
| No secrets in code                          | N/A      | PASS                                                                                                                   |
| No injection vectors                        | N/A      | PASS                                                                                                                   |
| Auth on all endpoints                       | N/A      | PASS — `IsAuthenticated` on all 3 ViewSets                                                                             |
| Row-level security                          | N/A      | PASS — get_queryset filters by role on all ViewSets                                                                    |

## Architecture Review

- Score: 9/10, Recommendation: APPROVE
- Layered architecture followed correctly
- Bulk operations throughout (3 bulk_create calls)
- Proper transactional boundaries
- Frozen dataclasses at service boundaries
- Pattern-consistent with existing codebase

## Remaining Concerns (Non-Blocking)

1. `_is_compound()` uses naive string matching — could misclassify exercises (minor m1)
2. `_a2_select_split_template` does not privacy-filter explicit template ID (low risk — UUIDs)
3. `split_template_id` type is `str | None` instead of `uuid.UUID | None` (minor m5)
4. No endpoint-specific rate limiting on generate/ (low risk — global throttle applies)
5. Manual dict construction in swap_options response instead of serializer (minor m2)
6. `unique_session_per_day_per_week` prevents AM/PM splits — deliberate limitation for v1 (minor m4)

---

## What Was Built

**Training Generator Pipeline + Swap System (v6.5 Step 5)**

- **5 new models** — SplitTemplate, TrainingPlan, PlanWeek, PlanSession, PlanSlot — forming a relational plan hierarchy with UUID PKs, proper constraints, and indexes. Replaces flat Program.schedule JSON.
- **7-step deterministic pipeline** (A1-A7) — Selects program length, picks split template, builds skeleton, assigns slot roles, sets rep/set scheme, selects exercises with per-week variety, and pre-computes swap candidates. Fully transactional with complete DecisionLog audit trail.
- **Three-tab swap system** — Same Muscle, Same Pattern, Explore All tabs with pre-computed cache + dynamic fallback. Swap execution creates DecisionLog + UndoSnapshot, preserves prescription, prevents duplicates in session, enforces privacy.
- **REST API** — Full CRUD for TrainingPlan (with nested reads) and SplitTemplate. Generate endpoint, swap-options endpoint, swap execution endpoint. Pagination, role-based access control, and row-level security on all endpoints.
- **Security** — Privacy-filtered exercise queries (cached and dynamic), trainee blocked from template mutations, IDOR prevention on SplitTemplate, transactional swap with undo support.

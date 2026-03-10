# Code Review: Training Generator Pipeline + Swap System (v6.5 Step 5)

## Review Date: 2026-03-09

## Files Reviewed
- `backend/workouts/models.py` (lines 2203–2522)
- `backend/workouts/services/training_generator_service.py` (full file, 843 lines)
- `backend/workouts/services/swap_service.py` (full file, 345 lines)
- `backend/workouts/serializers.py` (lines 1325–1508)
- `backend/workouts/views.py` (lines 3914–4197)
- `backend/workouts/urls.py` (full file)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `training_generator_service.py:356-358` | **PlanSlot.exercise FK is NOT NULL but skeleton creates slots with `exercise_id=None`.** The model defines `exercise = models.ForeignKey(Exercise, on_delete=models.PROTECT)` with no `null=True`. Steps A3-A5 build PlanSlot objects in memory with `exercise_id=None`, which works as in-memory objects, but if anything causes a premature flush or save before A6, it will crash with IntegrityError. This is fragile — a future developer adding a `.save()` or a signal will hit a hard-to-debug error. | Either make the FK nullable (`null=True, blank=True`) to be explicit about the lifecycle, or restructure A3 to only create slot *specifications* (a separate dataclass) rather than PlanSlot model instances, converting to real model instances only after A6 assigns exercises. |
| C2 | `training_generator_service.py:541-586` | **`used_ids` tracks exercises globally across ALL sessions and ALL weeks, never resetting.** For an 8-week plan with 6 sessions/week × 6 slots = 288 total slots, `used_ids` accumulates everything. If the pool has 30 exercises, by week 3 all are "used" and the fallback (line 575: `_pick_exercise(any_pool, slot.slot_role, set())` — empties used_ids) fires constantly, assigning exercises from ANY muscle group to fill slots. This means week 5's "chest" slot might get a hamstring exercise. | Reset `used_ids` per week. Cross-session uniqueness within a single week is valuable; cross-week uniqueness defeats the purpose since trainees repeat exercises weekly. |
| C3 | `views.py:4174-4178` | **IDOR on SplitTemplate for trainees.** When a trainee's `parent_trainer` is None (possible if trainer is deleted, since `parent_trainer` uses SET_NULL), `Q(created_by=user.parent_trainer)` becomes `Q(created_by=None)`, matching ALL templates with `created_by=None` — including templates from other contexts. | Add guard: `if user.parent_trainer is None: return SplitTemplate.objects.filter(is_system=True)`. |
| C4 | `views.py:4180-4185` | **Trainee can create/update/delete SplitTemplates.** No role check in `perform_create`. A trainee can POST to `/api/workouts/split-templates/` and create templates. `perform_update` and `perform_destroy` only check `is_system` but not trainee role. | Add `if user.role == 'TRAINEE': raise PermissionDenied("Trainees cannot create split templates.")` at the top of `perform_create`, `perform_update`, and `perform_destroy`. Or add a custom permission class restricting write ops to TRAINER/ADMIN. |
| C5 | `swap_service.py:112-124` | **Cached swap IDs bypass privacy filter.** When `cached_muscle_ids` exist, the query is `Exercise.objects.filter(pk__in=cached_muscle_ids)` with NO `privacy_q` filter. A trainer-private exercise ID cached during plan generation could be served to a user in a different context (e.g., after the trainee is reassigned to a different trainer). | Apply `privacy_q` filter even when using cached IDs: `.filter(pk__in=cached_muscle_ids).filter(privacy_q)`. Same for `cached_pattern_ids` (line 128) and `cached_explore_ids` (line 146). |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `serializers.py:1437-1438` | **N+1 query: `get_weeks_count` calls `obj.weeks.count()` per plan in list view.** On a list of 20 plans, this fires 20 extra COUNT queries. | Use `annotate(weeks_count=Count('weeks'))` on the list queryset, then reference the annotation in the serializer with `serializers.IntegerField(source='weeks_count', read_only=True)`. |
| M2 | `views.py:3936-3940` | **Overfetching on list endpoint.** The list queryset prefetches `weeks__sessions__slots__exercise` for ALL plans, even though `TrainingPlanListSerializer` doesn't use nested weeks. For a trainer with 50 plans each having 288 slots, this loads ~14,400 slot + exercise objects for no reason. | Override `get_queryset` to check `self.action`: for `'list'`, only `select_related('trainee', 'split_template')` with the Count annotation; for `'retrieve'`, add the full prefetch. |
| M3 | `training_generator_service.py:686-714` | **A7 fires N queries per slot.** For each slot without cached `swap_seed_ids` (which is every slot in a freshly generated plan), it runs 2-3 DB queries (same_muscle, same_pattern, explore). For 288 slots, that's ~800 queries in A7 alone — inside a transaction. | Pre-compute: collect all unique muscle groups and pattern tags from assigned exercises, batch-query exercises grouped by muscle/pattern into in-memory pools, then assign swap options from those pools without per-slot queries. |
| M4 | `views.py:3949-3968` | **`perform_create` response is broken.** `TrainingPlanCreateSerializer` is a plain `Serializer` (not `ModelSerializer`). Setting `serializer.instance = plan` doesn't produce a proper response because the serializer's fields (e.g., `trainee_id: IntegerField`) don't match the model's attributes. The DRF `create()` method calls `serializer.data` which will serialize using the *input* serializer, not the detail serializer. | Override `create()` to return `TrainingPlanSerializer(plan).data` instead, or return a `Response` directly. |
| M5 | `swap_service.py:266` | **Deep FK traversal `slot.session.week.plan_id` without guaranteed prefetch.** The service accesses `.session.week.plan_id` which requires 3 FK lookups. While the ViewSet's `get_queryset` has `select_related`, the service doesn't enforce this — any other caller would trigger N+1. | Either pass `plan_id` as a parameter, or re-fetch within the service with explicit `select_related('session__week__plan')`. |
| M6 | `training_generator_service.py:506-518` | **Exercise pool fetch uses `only()` but A7 re-fetches the same exercises.** A6 fetches exercises with `.only(...)` into a pool, then A7 (line 656-661) does a *second* full query for the same exercises by PK to get `swap_seed_ids`, `primary_muscle_group`, and `pattern_tags`. These are already in memory from A6. | Pass the exercise pool from A6 to A7, or build `exercises_by_id` once and share it across both steps. |
| M7 | `views.py:4023-4032` | **`activate` sets deactivated plans to ARCHIVED, not COMPLETED.** A trainer who activates a new plan auto-archives the old one. The user can never properly "complete" a plan — it goes straight from ACTIVE to ARCHIVED. This conflates two semantically different states. | Either use a separate `complete` action, or set deactivated plans to `COMPLETED` instead of `ARCHIVED` when replaced by a new activation. |
| M8 | `serializers.py:1489-1507` | **`validate_session_definitions` does not validate that `len(session_definitions) == days_per_week`.** The model help_text says "Length must equal days_per_week" and the generator relies on this (line 332: `session_defs[session_idx]`), but the serializer doesn't enforce the constraint. A template with 3 `days_per_week` but 5 session definitions will pass validation but produce incorrect plans. | Add cross-field validation in a `validate()` method: `if len(data['session_definitions']) != data['days_per_week']: raise ValidationError(...)`. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `training_generator_service.py:149-156` | **`_is_compound` uses naive string matching.** 'press' matches 'leg press' (isolation-ish) and 'row' matches 'narrow' if in the exercise name. | Use word-boundary matching or structured tags from the Exercise model's `pattern_tags` field. |
| m2 | `views.py:4092-4129` | **Manual dict construction for swap options response.** 18 lines of repetitive dict comprehension for 3 tabs. | Use `dataclasses.asdict()` or a DRF serializer for SwapCandidate. |
| m3 | `training_generator_service.py:178` | **`options[:20]` silently truncates decision log options.** | Include `total_options_count` in the log alongside the truncated list. |
| m4 | `models.py:2429-2433` | **`unique_session_per_day_per_week` prevents two sessions per day.** AM/PM splits would be blocked. | If out of scope, add a comment documenting the deliberate limitation. |
| m5 | `training_generator_service.py:51-52` | **`split_template_id: str | None`** — should be `uuid.UUID | None` for type safety since the model uses UUIDField. | Change type to `uuid.UUID | None`. |
| m6 | `swap_service.py:259-261` | **DecisionLog `actor_type` defaults to USER when actor_id is None.** Should be SYSTEM. In practice `actor_id` is always set from `request.user.pk` in the view, but the service doesn't enforce this contract. | Default to `ActorType.SYSTEM` when `actor_id` is None, or make `actor_id` non-optional (required int). |
| m7 | `training_generator_service.py:72-103` | **`_SCHEME` dict keys use raw strings coupled to TextChoices enum values.** If enum values change, the scheme table silently breaks with no error — just falls through to `_DEFAULT_SCHEME`. | Use `PlanSlot.SlotRole.PRIMARY_COMPOUND` and `TrainingPlan.GoalType.BUILD_MUSCLE` as keys, or add a startup-time assertion that all enum combinations are covered. |

---

## Security Concerns

1. **C4:** Trainees can create/update/delete SplitTemplates — missing role-based write restriction.
2. **C3:** IDOR data leakage through `created_by=None` matching when trainee has no parent_trainer.
3. **C5:** Cached swap IDs bypass privacy filters, potentially exposing private exercises across trainers.
4. **No rate limiting** on the `generate` endpoint. Plan generation is expensive (hundreds of DB queries). A malicious user could trigger repeated generations to stress the database.

## Performance Concerns

1. **M1:** N+1 on `weeks_count` in list serializer (20 extra queries per page).
2. **M2:** Full hierarchy prefetch on list endpoint (thousands of unnecessary objects loaded).
3. **M3:** A7 fires ~800 queries for a typical 8-week plan.
4. **M6:** Exercise pool fetched twice (A6 and A7).

---

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| TrainingPlan model with all required fields | PASS | |
| PlanWeek model with plan FK, week_number, deload, modifiers | PASS | |
| PlanSession model with week FK, day_of_week, label, order | PASS | |
| PlanSlot model with all prescription fields + swap cache | PASS | |
| SplitTemplate model | PASS | |
| All models use UUID primary keys | PASS | |
| Proper unique constraints and indexes | PASS | |
| A1–A5 pipeline steps | PASS | |
| A6: SELECT_EXERCISE | PARTIAL | Broken variety for multi-week plans (C2) |
| A7: BUILD_SWAP_RECOMMENDATIONS | PASS | Performance issue (M3) but functionally correct |
| Each step creates DecisionLog | PASS | |
| Pipeline is transactional | PASS | |
| Same Muscle / Same Pattern / Explore All swap tabs | PASS | |
| Swap execution with DecisionLog + UndoSnapshot | PASS | |
| Swap preserves prescription | PASS | |
| CRUD for TrainingPlan with nested reads | PARTIAL | Create response broken (M4) |
| POST generate/ | PASS | |
| GET swap-options/ | PASS | |
| POST swap/ | PASS | |
| CRUD for SplitTemplate | PARTIAL | Missing role restrictions (C4) |
| Row-level security on all endpoints | PARTIAL | SplitTemplate has IDOR (C3) and missing write restriction (C4) |
| Services return dataclasses, not dicts | PASS | |
| Business logic in services, not views | PASS | |
| Type hints on all functions | PASS | |
| No raw queries | PASS | |
| Proper prefetching | PARTIAL | Overfetch on list (M2), N+1 in serializer (M1) |

---

## Quality Score: 6/10

## Recommendation: REQUEST CHANGES

### Summary
Strong architectural foundation — the relational plan hierarchy is well-designed, the pipeline is properly transactional, services correctly return dataclasses, and business logic lives in the right layer. However, 5 critical issues (3 security: trainee can write SplitTemplates, IDOR on SplitTemplate, cached swap IDs bypass privacy; 1 correctness: used_ids breaks multi-week variety; 1 fragility: non-null FK used as null in memory) and 8 major issues (N+1 queries, overfetching, broken create response, missing cross-field validation) must be addressed before merge. The security issues (C3, C4, C5) are the highest priority.

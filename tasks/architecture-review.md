# Architecture Review: Training Generator Pipeline + Swap System (v6.5 Step 5)

## Review Date: 2026-03-09

## Files Reviewed

- `backend/workouts/services/training_generator_service.py` (884 lines)
- `backend/workouts/services/swap_service.py` (352 lines)
- `backend/workouts/views.py` (TrainingPlanViewSet, PlanSlotViewSet, SplitTemplateViewSet — last ~300 lines)
- `backend/workouts/serializers.py` (new serializers — last ~200 lines)
- `backend/workouts/models.py` (SplitTemplate, TrainingPlan, PlanWeek, PlanSession, PlanSlot — last ~300 lines)
- `backend/workouts/urls.py`

## Architectural Alignment

- [x] Follows existing layered architecture — business logic in `services/`, views handle request/response, serializers handle validation
- [x] Models/schemas in correct locations (`workouts/models.py`)
- [x] No business logic in views — `generate()` delegates to service, `swap()` delegates to service
- [x] Consistent with existing patterns (UUID PKs, frozen dataclasses for service return types, `select_related`/`prefetch_related`)

### What's Good

1. **Service layer is exemplary.** The 7-step pipeline (`_a1` through `_a7`) is cleanly structured with each step as a focused function. `generate_training_plan()` orchestrates all steps inside `transaction.atomic()`. No business logic leaks into views.
2. **Frozen dataclasses for API boundaries.** `GeneratePlanResult`, `SwapResult`, `SwapOptions`, `SwapCandidate` are all frozen. `SlotSpec` is intentionally mutable (internal pipeline state) but never exposed beyond the service.
3. **Bulk operations throughout.** `PlanWeek.objects.bulk_create()`, `PlanSession.objects.bulk_create()`, `PlanSlot.objects.bulk_create()` — three bulk inserts instead of potentially thousands of individual creates.
4. **Single exercise pool fetch.** `_prefetch_exercise_pool()` loads all relevant exercises in one query, shared between steps A6 (exercise selection) and A7 (swap recommendation). No per-slot DB queries.
5. **DecisionLog audit trail.** Every pipeline step produces an auditable `DecisionLog` entry. Swaps create both a `DecisionLog` and an `UndoSnapshot` for reversibility.
6. **Proper `select_for_update()`** in `undo_swap()` to prevent race conditions during undo operations.

## Data Model Assessment

| Concern                            | Status | Notes                                                                                                                                                             |
| ---------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Schema changes backward-compatible | PASS   | All new tables — no modifications to existing models                                                                                                              |
| Migrations reversible              | PASS   | `CreateModel` is auto-reversible; `CASCADE`/`SET_NULL` deletes are clean                                                                                          |
| Indexes added for new queries      | PASS   | Indexes on `(trainee, status)`, `(created_by)`, `(session, order)`, `(exercise)`, `(days_per_week, goal_type)`, `(is_system)`                                     |
| No N+1 query patterns              | PASS   | See detailed analysis below                                                                                                                                       |
| UUID primary keys                  | PASS   | All 5 new models use `UUIDField(primary_key=True, default=uuid.uuid4)`                                                                                            |
| Unique constraints                 | PASS   | `unique_week_per_plan`, `unique_session_per_day_per_week`, `unique_slot_order_per_session`                                                                        |
| ON DELETE behavior                 | PASS   | `CASCADE` down the hierarchy (Plan->Week->Session->Slot), `SET_NULL` for optional FKs (split_template, created_by), `PROTECT` on Exercise (prevents orphan slots) |

## Query Performance Analysis

### Generator Pipeline (`generate_training_plan`)

- **Exercise pool**: 1-2 queries (primary_muscle_group, fallback to legacy muscle_group). **Good.**
- **Skeleton creation**: 2 bulk_create calls (weeks, sessions). **Good.**
- **Slot creation**: 1 bulk_create call. **Good.**
- **Decision logs**: 7 individual creates (fixed count per pipeline run). **Acceptable.**
- **A7 swap recommendations**: Computed entirely in-memory from pre-fetched pool. Zero additional DB queries. **Excellent.**

### Swap Service (`get_swap_options`)

- 1 query for session exercise IDs to exclude.
- 3 queries for the three tabs (same muscle, same pattern, explore) — bounded by `_MAX_RESULTS_PER_TAB = 15`. **Acceptable.**

### TrainingPlanViewSet

- **List**: `select_related('trainee', 'split_template')` + `annotate(weeks_count=Count('weeks'))`. Lightweight — no nested prefetch. **Good.**
- **Detail**: `select_related('trainee', 'split_template', 'created_by')` + `prefetch_related('weeks__sessions__slots__exercise')`. Full hierarchy in ~4 queries. **Good.**

### PlanSlotViewSet

- `select_related('exercise', 'session__week__plan__trainee')` — single JOIN for auth traversal. **Good.**

## Scalability Concerns

| #   | Area                 | Issue                                                                                                                                                                                                                                                      | Severity | Recommendation                                                                                                                     |
| --- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Generator pipeline   | A 52-week, 7-day plan generates 364 sessions and ~2,500+ slots in a single atomic transaction. The bulk_create handles this efficiently, but it is a large transaction.                                                                                    | Low      | No action needed. Duration_weeks is capped at 52 by serializer validation. Consider chunked bulk_create if plans grow beyond this. |
| 2   | DecisionLog growth   | Every pipeline run creates 7 entries. Every swap creates 1. With many users over time, this table will grow.                                                                                                                                               | Low      | Consider a retention/archival policy for entries older than N months. Not urgent.                                                  |
| 3   | Swap cache staleness | `swap_options_cache` is pre-computed at plan generation time. If exercises are added/removed later, the cache becomes stale. The `get_swap_options()` service correctly falls back to dynamic queries, but the cached IDs may reference deleted exercises. | Low      | The dynamic fallback handles this gracefully. No action needed.                                                                    |

## Technical Debt Assessment

| #   | Description                                                                                                                                                       | Severity | Notes                                                                                                                         |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 1   | `SlotSpec` dataclass is mutable (not frozen) while all other service dataclasses are frozen.                                                                      | Low      | Intentional — mutated during pipeline steps A4/A5/A6/A7. Internal to the service, never exposed via API. Pragmatic deviation. |
| 2   | `_SCHEME` and `_DEFAULT_SCHEME` lookup tables are hardcoded.                                                                                                      | Low      | Fine for now. If trainers need custom rep schemes per goal, these would need to move to the database. Premature to do so now. |
| 3   | Legacy fallback in `_prefetch_exercise_pool()` (lines 280-288) queries `muscle_group` when `primary_muscle_group` yields nothing.                                 | Low      | Backward-compat path. Should have a deprecation timeline — backfill `primary_muscle_group` and remove the fallback.           |
| 4   | `execute_swap()` takes string parameters `plan_id`, `week_id`, `session_id` that are only used for DecisionLog context and could be derived from the slot object. | Low      | Minor API surface cleanup. Not blocking.                                                                                      |

## Pattern Consistency

| Pattern                               | This Implementation                                                | Verdict    |
| ------------------------------------- | ------------------------------------------------------------------ | ---------- |
| UUID PKs                              | All new models                                                     | Consistent |
| Frozen dataclasses from services      | `GeneratePlanResult`, `SwapResult`, `SwapOptions`, `SwapCandidate` | Consistent |
| Service layer for business logic      | Generator pipeline and swap logic fully in services                | Consistent |
| DRF serializer validation             | All inputs validated before hitting services                       | Consistent |
| `select_related` / `prefetch_related` | Used correctly in all ViewSet querysets                            | Consistent |
| Row-level security in `get_queryset`  | All three new ViewSets implement role-based filtering              | Consistent |
| `bulk_create` for batch inserts       | Used for PlanWeek, PlanSession, PlanSlot                           | Consistent |
| `transaction.atomic()`                | Pipeline and swap operations are transactional                     | Consistent |
| Pagination                            | `TrainingPlanPagination` with `page_size=20`, `max_page_size=50`   | Consistent |

## Architecture Score: 9/10

This is a well-architected feature. The relational hierarchy (TrainingPlan -> PlanWeek -> PlanSession -> PlanSlot) is a significant improvement over the flat `Program.schedule` JSONField. The 7-step deterministic pipeline is cleanly structured, each step is a focused function that mutates in-memory `SlotSpec` objects and logs a `DecisionLog`. Query patterns are efficient with proper prefetching and bulk operations. The swap service correctly uses `select_for_update()` for undo safety. The only deductions are for minor items (mutable SlotSpec, legacy fallback without deprecation plan, redundant string params in execute_swap).

## Recommendation: APPROVE

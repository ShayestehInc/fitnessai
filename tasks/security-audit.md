# Security Audit: Training Generator Pipeline + Swap System (v6.5 Step 5)

## Audit Date: 2026-03-09

## Files Reviewed

- `backend/workouts/services/training_generator_service.py`
- `backend/workouts/services/swap_service.py`
- `backend/workouts/views.py` (TrainingPlanViewSet, PlanSlotViewSet, SplitTemplateViewSet)
- `backend/workouts/serializers.py` (PlanSlotSerializer, PlanSlotWriteSerializer, PlanSessionSerializer, PlanWeekSerializer, TrainingPlanSerializer, TrainingPlanListSerializer, TrainingPlanCreateSerializer, GeneratePlanSerializer, SwapExecuteSerializer, SplitTemplateSerializer)
- `backend/workouts/models.py` (SplitTemplate, TrainingPlan, PlanWeek, PlanSession, PlanSlot, DecisionLog, UndoSnapshot)
- `backend/workouts/urls.py`

## Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git diff
- [x] All user input sanitized (via DRF serializers with ChoiceField/IntegerField/UUIDField validators)
- [x] Authentication checked on all new endpoints (all ViewSets use `permission_classes = [IsAuthenticated]`)
- [x] Authorization — correct role/permission guards (see detailed analysis below)
- [x] No IDOR vulnerabilities on ViewSet queryset level (all three ViewSets filter by role)
- [x] No file uploads in new code
- [x] Error messages don't leak internals (ValueError messages are domain-specific)
- [x] CORS policy — no changes, inherits existing config

## Authorization Analysis (Detailed)

### TrainingPlanViewSet

- **get_queryset()**: ADMIN sees all, TRAINER sees only their trainees' plans (`trainee__parent_trainer=user`), TRAINEE sees only their own (`trainee=user`). **PASS**
- **\_resolve_trainee()**: Checks that a TRAINER can only create plans for their own trainees, and a TRAINEE can only target themselves. **PASS**
- **generate()**: Calls `_resolve_trainee()` before pipeline execution. **PASS**
- **activate() / archive()**: Uses `self.get_object()` which applies `get_queryset()` filtering. **PASS**

### PlanSlotViewSet

- **get_queryset()**: Traverses `session__week__plan__trainee` for row-level security. ADMIN sees all, TRAINER sees slots for their trainees, TRAINEE sees only their own. **PASS**
- **swap_options()**: Uses `self.get_object()` which enforces queryset filtering. **PASS**
- **swap()**: Uses `self.get_object()` which enforces queryset filtering. **PASS**

### SplitTemplateViewSet

- **get_queryset()**: ADMIN sees all, TRAINER sees system + own, TRAINEE sees system + their trainer's. **PASS**
- **perform_create()**: Blocks trainees from creating. Sets `is_system=True` only for admins. **PASS**
- **perform_update()**: Blocks trainees. Blocks non-admin from editing system templates. **PASS**
- **perform_destroy()**: Same guard as update. **PASS**

### DecisionLogViewSet

- **get_queryset()**: ADMIN sees all, TRAINER sees own + trainee decisions, TRAINEE sees only own. **PASS**

## Injection Vulnerabilities

None found. All database access uses Django ORM with parameterized queries. No raw SQL anywhere in the new code.

## Auth & Authz Issues

| #   | Severity | Endpoint/File                                                           | Issue                                                                                                                                                                                                                                                                                                                                                                                           | Recommendation                                                                                          |
| --- | -------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | Medium   | `swap_service.py:206-209` — `execute_swap()`                            | The swap service does not verify that `new_exercise_id` is accessible to the user (public or owned by their trainer). The exercise lookup uses a bare `Exercise.objects.get(pk=new_exercise_id)` without a privacy filter. A user could swap in an exercise belonging to a different trainer by guessing the integer ID. The view passes `actor_id` but not `trainer_id` for privacy filtering. | Add a `trainer_id` parameter to `execute_swap()` and filter the exercise lookup with `Q(is_public=True) | Q(created_by_id=trainer_id)`.                                        |
| 2   | Low      | `training_generator_service.py:334-338` — `_a2_select_split_template()` | When a `split_template_id` is explicitly provided, the lookup is `SplitTemplate.objects.get(pk=...)` without checking whether the template belongs to the requesting trainer or is a system template. A trainer could reference another trainer's custom template by guessing the UUID.                                                                                                         | Add a privacy check: filter with `Q(is_system=True)                                                     | Q(created_by_id=trainer_id)`. Low risk due to UUID unpredictability. |

## Data Exposure

| #   | Severity | Issue                                                                                                                                                                                                                                                                                                | Recommendation                                                                                                                    |
| --- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Low      | `PlanSlotSerializer` exposes `swap_options_cache` containing raw exercise IDs. These are re-validated via `privacy_q` in `get_swap_options()`, but the cached JSON in the read serializer could reveal exercise IDs from other trainers if the cache was populated when the exercise was accessible. | Consider excluding `swap_options_cache` from the read serializer or filtering cached IDs through privacy checks when serializing. |

## Rate Limiting

| #   | Severity | Issue                                                                                                                                                            | Recommendation                                                                                                |
| --- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 1   | Low      | `training-plans/generate/` is computationally expensive (creates many DB records in a single transaction). No endpoint-specific throttle beyond global defaults. | Consider adding throttling for the generate endpoint (e.g., 5 requests per minute per user) to prevent abuse. |

## Numeric Input Validation

| Field                        | Validation                                                | Status                                  |
| ---------------------------- | --------------------------------------------------------- | --------------------------------------- |
| `trainee_id`                 | `IntegerField`                                            | OK                                      |
| `days_per_week`              | `IntegerField(min_value=1, max_value=7)`                  | OK                                      |
| `duration_weeks`             | `IntegerField(min_value=1, max_value=52)`                 | OK                                      |
| `training_day_indices`       | `ListField(child=IntegerField(min_value=0, max_value=6))` | OK                                      |
| `goal`                       | `ChoiceField(choices=GoalType.choices)`                   | OK                                      |
| `difficulty`                 | `ChoiceField(choices=DifficultyLevel.choices)`            | OK                                      |
| `new_exercise_id` (swap)     | `IntegerField`                                            | OK — validated for existence in service |
| Model validators on PlanSlot | sets: 1-20, reps: 1-100, rest: 0-600                      | OK                                      |
| Model validators on PlanWeek | intensity/volume modifiers: 0.30-2.00                     | OK                                      |

## Security Score: 8/10

The implementation has strong security foundations. All ViewSets enforce authentication and row-level queryset filtering. Input validation is thorough via DRF serializers and model validators. The pipeline runs in a single atomic transaction preventing partial state. The two authorization gaps in the service layer (swap exercise privacy, split template privacy) are real but low-to-medium risk. No secrets, no injection vectors, no sensitive data leakage.

## Recommendation: CONDITIONAL PASS

Fix issue #1 (swap exercise privacy check in `execute_swap`) before shipping to production. Issue #2 is low risk due to UUID randomness but should be addressed in the next iteration.

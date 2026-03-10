# Code Review: LiftSetLog + LiftMax + Max/Load Engine (Pipeline 60)

## Review Date
2026-03-09

## Files Reviewed
- `backend/workouts/models.py` (lines 1887–2142) — LiftSetLog, LiftMax models
- `backend/workouts/services/max_load_service.py` — full file (302 lines)
- `backend/workouts/serializers.py` (lines 1193–1292) — LiftSetLogSerializer, LiftMaxSerializer, LiftMaxPrescribeSerializer
- `backend/workouts/views.py` (lines 3402–3627) — LiftSetLogPagination, LiftSetLogViewSet, LiftMaxViewSet
- `backend/workouts/urls.py` — router registrations
- `backend/workouts/migrations/0020_liftmax_liftsetlog.py`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `views.py:3482-3484` | **No ownership guard on update/delete.** `LiftSetLogViewSet` inherits `ModelViewSet` which provides `update`, `partial_update`, and `destroy`. `perform_update` has no role check — a trainer whose queryset includes the set log can modify a trainee's historical performance data. More importantly, **there is no `perform_destroy` override at all** — any user whose `get_queryset` includes the record can delete set logs. Trainers can delete their trainees' set logs silently. Deleting a set log leaves orphaned `source_set_id` references in `LiftMax.e1rm_history`. Set logs are historical records and should likely not be deletable, or at minimum require explicit ownership + audit. | 1) Restrict the viewset to `CreateModelMixin + ListModelMixin + RetrieveModelMixin` only (remove update/delete), OR 2) Add explicit ownership checks: only the trainee who created the set can update, and disallow deletion entirely. If update/delete are needed, add `perform_destroy` with an audit trail and cascade logic to recompute e1RM. |
| C2 | `views.py:3564` | **`trainee_id` in prescribe endpoint bypasses serializer validation.** `trainee_id` is read directly from `request.data` instead of being defined in `LiftMaxPrescribeSerializer`. If a client sends `trainee_id: "abc"` or `trainee_id: null`, `User.objects.get(id=trainee_id)` raises an unhandled `ValueError` or `TypeError`, producing a 500 response (and potentially leaking stack trace info in DEBUG mode). | Add `trainee_id = serializers.IntegerField(required=False)` to `LiftMaxPrescribeSerializer` and read from `serializer.validated_data`. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `models.py:2098-2101, 2118-2121` | **Unbounded JSONField arrays.** `e1rm_history` and `tm_history` grow without limit. Every qualifying set appends to `e1rm_history`. A trainee doing 4 sets of squats 3x/week for a year = ~624 entries per exercise. Multiply by 20+ exercises = 12,000+ entries across all LiftMax records. The arrays are serialized in full on every LiftMax API response. | Cap history at a reasonable length (e.g., 200 entries per array) and trim oldest entries on append in `update_max_from_set`. Alternatively, move history to a separate related model with proper pagination. |
| M2 | `max_load_service.py:271-274` | **Race condition on concurrent e1RM updates.** Two concurrent `update_max_from_set` calls for the same trainee+exercise: both call `get_or_create`, both read the same `e1rm_current`, both compute smoothed values, last writer wins. The earlier writer's history entry and e1RM update are silently overwritten. `@transaction.atomic` prevents partial writes but not lost updates. | After `get_or_create`, re-fetch with `select_for_update()`: `lift_max = LiftMaxModel.objects.select_for_update().get(pk=lift_max.pk)` to serialize concurrent updates at the DB level. |
| M3 | `models.py:1994-1998` | **`standardization_pass` defaults to `True` (fail-open).** Every set is assumed to pass standardization by default. If the mobile client doesn't send this field, all sets will update e1RM — including sets with poor form that should not qualify. This is particularly dangerous before the mobile UI implements standardization criteria. | Default to `False` (fail-closed). Sets must be explicitly marked as standardization-passing. This prevents premature e1RM pollution from unvalidated sets. |
| M4 | `views.py:3527-3540` | **History endpoint URL deviates from ticket spec.** The ticket specifies `GET /api/workouts/lift-maxes/{exercise_id}/history/`. The implementation uses `@action(detail=True)` which produces `GET /api/workouts/lift-maxes/{lift_max_uuid}/history/`. The client must know the LiftMax UUID, not the exercise ID. This is less ergonomic — the frontend naturally has the exercise ID, not the LiftMax PK. | Change to `@action(detail=False)` with `exercise_id` as a required query param, or add a custom URL route that takes `exercise_id` and looks up the LiftMax. |
| M5 | `views.py:3509, 3490` | **No pagination on LiftMaxViewSet.** `ReadOnlyModelViewSet` does not include pagination by default. An admin listing all LiftMax records, or a trainer with many trainees, will get an unbounded response. | Add `pagination_class = LiftSetLogPagination` (or a dedicated one) to `LiftMaxViewSet`. |
| M6 | `serializers.py:1245-1248` | **Type hint mismatch: `validate_entered_load_value` returns `float` but field is `DecimalField`.** DRF `DecimalField` produces `Decimal` objects after validation. The return type annotation says `float`, which is incorrect and could mislead type checkers. | Change signature to `def validate_entered_load_value(self, value: Decimal) -> Decimal:`. Same for the parameter type. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `views.py:3486-3487` | **Redundant `get_serializer_class` override.** Returns `LiftSetLogSerializer` which is already set as `serializer_class` on line 3417. | Remove the override — it adds noise with no behavior change. |
| m2 | `views.py:3603-3608` | **Extra DB query for `latest_unit` on every prescribe call.** Queries `LiftSetLog` to find the trainee's most recent unit for this exercise. This is a per-request DB hit that could be avoided. | Store `preferred_unit` on `LiftMax` model, updated alongside e1RM in `update_max_from_set`. |
| m3 | `max_load_service.py:180` | **No bounds check on `percentage` parameter.** `calculate_tm` accepts any Decimal. Negative or >100 values would produce nonsensical results. The model has validators (80-100), but the service method doesn't enforce this. | Add `assert Decimal("0") < percentage <= Decimal("100")` or raise `ValueError`. |
| m4 | `models.py:2039-2044` | **`__str__` accesses `self.exercise.name` without prefetch guarantee.** In admin list views or debugging, this triggers an N+1 query per LiftSetLog instance. | Acceptable for debugging; just note it in admin config with `select_related`. |
| m5 | `max_load_service.py:283` | **Orphaned history references.** `e1rm_history` entries store `source_set_id` pointing to LiftSetLog UUIDs. If set logs are deleted (see C1), these become dangling references. | Not a bug if deletion is prevented (see C1 fix). Document that history entries reference set IDs that must be preserved. |
| m6 | `serializers.py:1240-1243` | **`validate_completed_reps` is redundant.** `completed_reps` is a `PositiveIntegerField` — Django/DRF already reject negative values at the model and serializer level. | Remove the custom validator or keep it as defense-in-depth (acceptable either way). |

---

## Security Concerns

1. **C1 (IDOR on update/delete)** — Primary security issue. A trainer can modify their trainee's set logs (tampering with historical performance data), and any permitted user can delete records with no audit trail.
2. **C2 (unvalidated `trainee_id`)** — Causes 500 errors with malformed input. In DEBUG mode, stack traces could leak internal paths and model structure.
3. **Good practice:** The `prescribe` endpoint correctly masks authorization failures as 404s (prevents user enumeration). Row-level security in `get_queryset` is correctly implemented for all three roles.
4. **No secrets or credentials** found in any reviewed files.

## Performance Concerns

1. **M1 (unbounded history arrays)** — Performance degrades over time as JSON serialization of large arrays becomes expensive on every API response.
2. **M2 (race condition)** — Concurrent set logging produces incorrect e1RM values under load.
3. **M5 (no pagination on LiftMax)** — Unbounded responses for admin/trainer users.
4. **Indexes are well-designed** — Composite indexes cover the main query patterns. Unique constraint on (trainee, exercise, session_date, set_number) is correct.
5. `select_related('exercise', 'trainee')` is correctly used in both viewsets.

---

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| LiftSetLog model with all v6.5 fields | PASS | All fields present with correct types, computed fields, indexes |
| LiftMax model with e1RM, TM, history | PASS | Complete with unique constraint and validators |
| MaxLoadService with e1RM estimation | PASS | Epley + Brzycki, conservative min, rep capping, RPE=10 handling |
| Only standardization-passing sets update e1RM | PASS | Correctly checked in `update_max_from_set` (but default=True is risky, see M3) |
| LiftSetLog CRUD API | PARTIAL | CRUD works but update/delete lack ownership guards (C1) |
| LiftMax read API with history endpoint | PARTIAL | Works but URL pattern deviates from ticket (M4) |
| Load prescription endpoint | PARTIAL | Works but unvalidated trainee_id (C2) |
| Row-level security on all endpoints | PARTIAL | get_queryset is correct for all roles; update/delete ownership gap (C1) |
| Proper indexes for performance | PASS | Four indexes + unique constraint cover query patterns well |
| Service methods return dataclasses, not dicts | PASS | `E1RMEstimate` and `LoadPrescription` are frozen dataclasses |

---

## Quality Score: 6/10

The core implementation is strong — the service layer is clean, the math is correct, the dataclass pattern is well-applied, and the model design is thoughtful. However, the IDOR risk on update/delete (C1), the unvalidated input bypass (C2), the race condition (M2), and the fail-open standardization default (M3) are real issues that would cause problems in production. The history endpoint URL mismatch (M4) will create frontend integration friction.

## Recommendation: REQUEST CHANGES

**Must fix before merge:** C1, C2
**Should fix before merge:** M1, M2, M3, M4, M5, M6
**Can defer:** m1–m6

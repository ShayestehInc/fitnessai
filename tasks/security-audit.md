# Security Audit: Wire Nutrition Template Assignment

## Audit Date: 2026-03-05

## Files Reviewed
- `mobile/lib/features/nutrition/presentation/screens/template_assignment_screen.dart`
- `mobile/lib/features/nutrition/presentation/providers/nutrition_template_provider.dart`
- `mobile/lib/features/nutrition/data/repositories/nutrition_template_repository.dart`
- `mobile/lib/features/nutrition/data/models/nutrition_template_models.dart`
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` (lines 1841+)
- `mobile/lib/core/constants/api_constants.dart`
- `backend/workouts/views.py` (NutritionTemplateViewSet, NutritionTemplateAssignmentViewSet)
- `backend/workouts/serializers.py` (NutritionTemplateAssignmentCreateSerializer)
- git diff HEAD~2 -- mobile/

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] All user input sanitized (client-side validation + backend serializer validation)
- [x] Authentication checked on all new endpoints (IsAuthenticated on both ViewSets)
- [x] Authorization -- correct role/permission guards (FIXED: template scoping in create)
- [x] No IDOR vulnerabilities (FIXED: template cross-trainer access)
- [x] Error messages don't leak internals (error messages were sanitized in this diff)
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [ ] Rate limiting on sensitive endpoints (no rate limiting on assignment creation -- Low risk)
- [x] CORS policy appropriate (no changes to CORS)

## Issues Found

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 1 | **Medium** | `backend/workouts/views.py:2422` | **Cross-trainer template access (IDOR):** The `create` method on `NutritionTemplateAssignmentViewSet` fetched templates with an unscoped `NutritionTemplate.objects.get(pk=template_id)`. A trainer could assign another trainer's custom (non-system) template to their trainee by guessing/enumerating template IDs. | **FIXED.** Scoped the template lookup to `Q(is_system=True) | Q(created_by=user)` for trainers, matching the same scoping used in `NutritionTemplateViewSet.get_queryset()`. |
| 2 | **Low** | `backend/workouts/serializers.py:817-820` | **Weak JSONField validation on `parameters`:** The `validate_parameters` method only checks `isinstance(value, dict)`. It does not validate allowed keys or value ranges. A malicious client could inject arbitrarily large JSON payloads or unexpected keys into the `parameters` field. | No fix applied. Recommend adding a whitelist of allowed parameter keys (`meals_per_day`, `body_weight_lbs`, `body_fat_pct`, `lbm_lbs`) and numeric range validation in the serializer. |
| 3 | **Low** | `backend/workouts/views.py:2361-2368` | **No rate limiting on assignment creation:** The `NutritionTemplateAssignmentViewSet` has no throttling. A compromised trainer account could spam assignment creation. | No fix applied. Consider adding `throttle_classes = [UserRateThrottle]` or a custom throttle. |
| 4 | **Info** | `mobile/.../nutrition_template_models.dart:28` | **Trainee email exposed in assignment model:** The `NutritionTemplateAssignmentSerializer` returns `trainee_email`. Acceptable since only the owning trainer or the trainee themselves can access assignments (scoped by `get_queryset`). | No fix needed -- access is properly scoped. |

## Positive Findings

1. **Error messages sanitized:** The diff shows `e.toString()` in the catch block was replaced with a generic `'Failed to assign template. Please try again.'` message, preventing internal exception details from reaching the user.
2. **Trainee ownership verified in `create`:** Line 2415 correctly checks `trainee.parent_trainer_id != user.pk` before allowing assignment.
3. **Queryset scoping on assignments:** `get_queryset()` filters by `trainee__parent_trainer=user` for trainers, preventing cross-trainer data access on list/detail/update/destroy operations.
4. **Trainee self-scoping:** Trainees can only see their own assignments (`trainee=user`).
5. **Active assignment endpoint:** The `active` action also verifies trainer ownership at line 2471.
6. **Input validation on mobile:** Body weight (0-1000), body fat (1-70), meals per day (1-10) are all validated client-side before submission.
7. **No secrets in changed files:** Grep for API keys, passwords, tokens, and secrets returned zero matches across all changed mobile files.

## Security Score: 8/10

The one Medium issue (cross-trainer template IDOR) has been fixed. The remaining items are Low/Info severity and do not block shipping. The authorization model is sound -- every endpoint checks authentication and role-based access. Queryset scoping is consistently applied.

## Recommendation: PASS

The feature is safe to ship with the applied fix. The Low-severity items (parameter whitelist validation, rate limiting) should be addressed in a follow-up pass.

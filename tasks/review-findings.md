# Code Review Round 2: Ambassador System

## Review Date: 2026-02-14

## Files Reviewed

All 28 files in the ambassador feature across backend and mobile, including:
- `backend/ambassador/` (models, views, serializers, services, admin, urls, migrations)
- `backend/users/serializers.py`, `backend/users/models.py`
- `backend/core/permissions.py`, `backend/config/urls.py`, `backend/config/settings.py`
- `mobile/lib/features/ambassador/` (models, repository, providers, all screens)
- `mobile/lib/features/admin/presentation/screens/admin_ambassador*.dart`
- `mobile/lib/features/auth/` (register screen, auth repository, user model, auth provider)
- `mobile/lib/core/constants/api_constants.dart`, `mobile/lib/core/router/app_router.dart`

---

## Round 1 Fix Verification (12/12 VERIFIED)

| ID | Issue | Status |
|----|-------|--------|
| C-1 | `serializers.models.Sum` wrong import | FIXED -- now `django.db.models.Sum` (serializers.py:11) |
| C-2 | Bare `except Exception` in `get_trainer_subscription_tier()` | FIXED -- now catches `(AttributeError, ObjectDoesNotExist)` (serializers.py:63) |
| C-3 | SECURITY: Registration allowed ADMIN/AMBASSADOR role | FIXED -- choices restricted to TRAINEE/TRAINER (users/serializers.py:19) |
| C-4 | Race condition in ambassador user creation | FIXED -- single `User(...)` + `user.save()` (views.py:267-274) |
| M-1 | 3 separate COUNT queries | FIXED -- single `.aggregate()` with Case/When (views.py:60-67) |
| M-2 | N+1 on referral serialization | FIXED -- `.annotate(_total_commission=...)` in all 3 querysets |
| M-3 | Unbounded referrals | FIXED -- slicing + pagination applied everywhere |
| M-4 | Count query inside transaction | FIXED -- moved outside `transaction.atomic()` (referral_service.py:87-88) |
| M-5 | profile.save() without update_fields | FIXED -- `update_fields` added in both locations |
| M-6 | `ApiClient()` unauthenticated | FIXED -- uses `ref.watch(apiClientProvider)` (ambassador_provider.dart:7) |
| M-7 | refresh_cached_stats inside transaction | FIXED -- moved outside transaction (referral_service.py:145) |
| M-8 | user.save() without update_fields=['role'] | FIXED -- `update_fields=['role']` (users/serializers.py:47) |

---

## NEW Issues Found

### Critical Issues (must fix before merge)

None.

### Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M-NEW-1 | `backend/ambassador/serializers.py:61` | **Wrong related_name:** Uses `obj.trainer.trainee_subscription` (singular) but the Subscription model defines `related_name='trainee_subscriptions'` (plural). The `AttributeError` is caught, so every referral silently shows 'FREE' tier regardless of actual subscription status. This is a data correctness bug visible to ambassadors. | Use the correct related name `trainee_subscriptions` and access the active subscription appropriately (e.g., `.trainee_subscriptions.select_related('tier').first()`). Also need to update the `select_related` calls in views to prefetch this relationship. |
| M-NEW-2 | `backend/users/serializers.py:45-47` | **Two DB writes on registration:** `create_user(**validated_data)` saves the user with default role, then `user.save(update_fields=['role'])` overwrites it. This is two DB writes when one suffices. | Pass `role` into `create_user`: `User.objects.create_user(role=role, **validated_data)` and remove the second save. |
| M-NEW-3 | `backend/ambassador/views.py:60,119` | **Stale cached count:** Dashboard displays `profile.total_referrals` from the cached field (line 119) while computing live status counts from the DB (lines 60-67). If caching gets out of sync, the total won't match the sum of active+pending+churned. | Compute total from the aggregate (add a total Count) or use `active_count + pending_count + churned_count` for consistency. |

### Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m-1 | `backend/ambassador/models.py:77` | `save()` uses `*args: object, **kwargs: object` -- imprecise typing for Django's save() signature | Use `*args: Any, **kwargs: Any` |
| m-2 | `backend/ambassador/serializers.py:102` | Generic parameter on `Serializer[dict[str, Any]]` doesn't provide real type safety in DRF | Cosmetic; leave or remove |
| m-3 | `mobile/lib/features/auth/data/repositories/auth_repository.dart:41` | `print('Error fetching user info: $e')` -- violates "No debug prints" convention | Remove the print statement |
| m-4 | `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart:136,196,257,330,371` | Methods accept `dynamic data` instead of typed `AmbassadorDashboardData` | Use proper type annotation |
| m-5 | `backend/ambassador/services/referral_service.py:140` | Duck-typing `hasattr(period_start, 'date')` doesn't match type annotation `timezone.datetime` | Enforce type or update hint to `datetime | date` |
| m-6 | `backend/ambassador/views.py:52` | Dashboard `AmbassadorProfile.objects.get(user=user)` missing `select_related('user')` | Add `select_related('user')` for safety |
| m-7 | `mobile/lib/features/ambassador/presentation/screens/ambassador_referrals_screen.dart:130` | Filter status displayed in uppercase ("No ACTIVE referrals") | Add `.toLowerCase()` |

---

## Security Concerns

- C-3 fix is solid: registration restricted to TRAINEE/TRAINER only
- No secrets, API keys, or tokens in any changed files
- All endpoints properly guarded with IsAuthenticated + role-specific permissions
- IDOR protection in place: queries filter by authenticated user
- Admin endpoints correctly restricted to IsAdmin

## Performance Concerns

- M-NEW-1 is primarily a correctness issue (all tiers show FREE)
- M-NEW-2 causes unnecessary extra DB write on trainer registration
- The N+1 fixes (annotations, select_related) are well-implemented
- Pagination properly applied throughout
- Aggregate queries are efficient

---

## Quality Score: 7.5/10

## Recommendation: REQUEST CHANGES

### Rationale

All 12 Round 1 issues have been correctly and thoroughly fixed. The code quality has improved substantially. However:

1. **M-NEW-1** is a visible data correctness bug -- every ambassador sees "FREE" tier for all referred trainers regardless of actual subscription status. This undermines dashboard trustworthiness.
2. **M-NEW-2** is an unnecessary double write on every trainer registration.
3. **m-3** is a print statement that violates explicit project conventions.

With M-NEW-1 and M-NEW-2 fixed, this would be a clean APPROVE at 8+/10. The overall architecture, separation of concerns, permission model, and UI implementation are all solid.

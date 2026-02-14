# Code Review Round 1: Ambassador User Type & Referral Revenue Sharing

## Review Date
2026-02-14

## Files Reviewed
### Backend
- `backend/ambassador/models.py` — AmbassadorProfile, AmbassadorReferral, AmbassadorCommission
- `backend/ambassador/serializers.py` — All serializers, dashboard/admin serializers
- `backend/ambassador/views.py` — 6 view classes (3 ambassador, 3 admin)
- `backend/ambassador/urls.py` — URL patterns
- `backend/ambassador/services/referral_service.py` — ReferralService
- `backend/ambassador/admin.py` — Django admin registration
- `backend/users/serializers.py` — UserCreateSerializer referral code changes
- `backend/users/models.py` — Role.AMBASSADOR addition
- `backend/core/permissions.py` — IsAmbassador, IsAmbassadorOrAdmin

### Mobile
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart`
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart`
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart`
- `mobile/lib/features/ambassador/presentation/screens/*.dart` (4 files)
- `mobile/lib/features/admin/presentation/screens/admin_ambassadors_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_create_ambassador_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`
- `mobile/lib/core/constants/api_constants.dart`
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/features/auth/data/repositories/auth_repository.dart`
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart`
- `mobile/lib/features/auth/presentation/screens/register_screen.dart`

---

## Critical Issues Found (Round 1) — ALL FIXED

| # | File:Line | Issue | Fix Applied |
|---|-----------|-------|-------------|
| C-1 | `serializers.py:64` | `serializers.models.Sum` — wrong import path for Django's Sum. Would crash at runtime. | Replaced with proper `from django.db.models import Sum`. Also added annotation-based approach to avoid N+1. |
| C-2 | `serializers.py:53-58` | `get_trainer_subscription_tier()` triggers N+1 query per row, bare `except Exception` swallows all errors | Changed to catch `(AttributeError, ObjectDoesNotExist)` specifically. |
| C-3 | `users/serializers.py:18-19` | **SECURITY: Registration allowed ADMIN/AMBASSADOR role** — `User.Role.choices` includes all 4 roles, letting anyone self-register as admin. | Restricted to `[(User.Role.TRAINEE, 'Trainee'), (User.Role.TRAINER, 'Trainer')]`. |
| C-4 | `views.py:229-236` | Race condition — user created as TRAINEE then updated to AMBASSADOR in a second save. Brief window where user has wrong role. | Rewrote to construct `User()` with `role=AMBASSADOR` and `set_unusable_password()` in single save. |

## Major Issues Found (Round 1) — ALL FIXED

| # | File:Line | Issue | Fix Applied |
|---|-----------|-------|-------------|
| M-1 | `views.py:60-62` | Three separate COUNT queries for status breakdown | Replaced with single `aggregate()` using `Count(Case(When(...)))`. |
| M-2 | `views.py:92-93` | N+1 on recent_referrals — serializer methods query DB per row | Added `_total_commission` annotation via `Sum(Case(When(...)))` to all referral querysets. Serializer checks for annotation first. |
| M-3 | `views.py:274-276` | Unbounded referrals fetch in admin detail | Added `[:100]` limit. |
| M-4 | `services/referral_service.py:85` | `profile.referrals.count()` query inside transaction | Moved stat update outside transaction block. |
| M-5 | `views.py:307` | `profile.save()` without `update_fields` in PUT handler | Added `update_fields` list built dynamically based on which fields changed. |
| M-6 | `ambassador_provider.dart:7` | `AmbassadorRepository(ApiClient())` creates new unauthenticated client | Changed to `ref.watch(apiClientProvider)` from auth_provider, using shared authenticated client. |
| M-7 | `services/referral_service.py:143` | `refresh_cached_stats()` inside transaction triggers DB queries + save | Moved outside transaction block. |
| M-8 | `users/serializers.py:47` | `user.save()` without `update_fields` | Added `update_fields=['role']`. |

## Minor Issues Identified
- m-1: Unused `Any` import in serializers (kept for DashboardSerializer type hint)
- m-2: Admin URLs nested under ambassador app prefix vs /api/admin/ (acceptable — avoids circular imports)
- m-3: `AmbassadorListSerializer` is nearly identical to `AmbassadorProfileSerializer` (acceptable — serves different contexts)

---

## Quality Score: 5/10 (pre-fix) → Fixes applied

## Recommendation: BLOCK → Fixes applied, re-review needed

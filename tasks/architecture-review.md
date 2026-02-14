# Architecture Review: Ambassador Feature

## Review Date
2026-02-14

## Files Reviewed
### Backend
- `backend/ambassador/models.py` -- AmbassadorProfile, AmbassadorReferral, AmbassadorCommission
- `backend/ambassador/views.py` -- Dashboard, Referrals, ReferralCode, Admin CRUD views
- `backend/ambassador/serializers.py` -- All serializers
- `backend/ambassador/services/referral_service.py` -- ReferralService (business logic)
- `backend/ambassador/urls.py` -- URL configuration
- `backend/ambassador/admin.py` -- Django admin registration
- `backend/ambassador/apps.py` -- App config
- `backend/config/urls.py` -- Root URL includes
- `backend/config/settings.py` -- INSTALLED_APPS
- `backend/users/models.py` -- User model (AMBASSADOR role)
- `backend/core/permissions.py` -- IsAmbassador, IsAmbassadorOrAdmin

### Mobile
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart`
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart`
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_referrals_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_navigation_shell.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassadors_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/core/constants/api_constants.dart`

### Comparison patterns
- `backend/trainer/models.py`
- `backend/trainer/views.py`
- `mobile/lib/features/trainer/presentation/providers/trainer_provider.dart`

---

## Architectural Alignment
- [x] Follows existing layered architecture (Django app with models/views/serializers/services)
- [x] Business logic in `services/referral_service.py`, not in views -- correctly follows project convention
- [x] Models in correct location (`ambassador/models.py`)
- [x] Consistent with existing patterns (matches trainer app structure)
- [x] Mobile follows Repository -> Provider -> Screen pattern
- [x] API constants centralized in `api_constants.dart`
- [x] go_router routes properly configured with StatefulShellRoute for ambassador

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New app with new tables, no modifications to existing schema |
| Migrations reversible | PASS | Single initial migration, trivially reversible |
| Indexes added for new queries | PASS | Comprehensive indexes on all FK and filter fields |
| No N+1 query patterns | PASS | Annotations used for commission totals, select_related for FKs |
| Referral code uniqueness | PASS | Unique constraint + code generation with collision retry |
| Commission rate snapshot | PASS | Rate captured at commission creation time, decoupled from profile changes |
| Cached stats pattern | PASS | total_referrals/total_earnings cached on profile, refreshed explicitly |

### Data Model Strengths
1. **Commission rate snapshotting** is correctly implemented -- changing an ambassador's rate does not retroactively affect historical commissions.
2. **Referral code generation** has a collision-retry loop with a hard limit (100 attempts), preventing infinite loops.
3. **Cached aggregates** (total_referrals, total_earnings) on AmbassadorProfile avoid expensive aggregation queries on every dashboard load.
4. **Three-state referral lifecycle** (PENDING -> ACTIVE -> CHURNED with reactivation) correctly models the subscription lifecycle.

---

## Issues Found and Fixed

### Critical Issues

| # | File:Line | Issue | Fix Applied |
|---|-----------|-------|-------------|
| 1 | `views.py:266` | `AdminCreateAmbassadorView.post()` creates User and AmbassadorProfile in separate saves without a transaction. If profile creation fails (e.g., unique code collision after 100 retries), an orphan User with role=AMBASSADOR exists in the database. | Wrapped both creates in `transaction.atomic()` |

### Major Issues

| # | File:Line | Issue | Fix Applied |
|---|-----------|-------|-------------|
| 2 | `views.py` (3 locations) | The `_total_commission` annotation query (Sum/Case/When over commissions) was copy-pasted identically in `AmbassadorDashboardView`, `AmbassadorReferralsView`, and `AdminAmbassadorDetailView`. This violates DRY and creates a maintenance burden -- changing the commission status filter requires updating 3 places. | Extracted into `_annotate_referrals_with_commission()` helper function |
| 3 | `views.py:331` | `AdminAmbassadorDetailView.get()` returned referrals capped at `[:100]` and commissions at `[:50]` with no pagination. For high-performing ambassadors this silently drops data. | Replaced with proper `PageNumberPagination` using `referral_page` and `commission_page` query params |
| 4 | `models.py:149` | `AmbassadorReferral.Meta` uses deprecated `unique_together` instead of `UniqueConstraint`. Django docs recommend `constraints` with `UniqueConstraint` for new code. | Replaced with `models.UniqueConstraint(fields=['ambassador', 'trainer'], name='unique_ambassador_trainer_referral')` |
| 5 | `referral_service.py:180-191` | `handle_trainer_churn()` iterates referrals one-by-one with individual `save()` calls. With many referrals this causes N queries. | Replaced with single `queryset.update()` bulk operation. Return type changed to `int` (count of churned referrals). |
| 6 | `ambassador_repository.dart:71` | `getAmbassadorDetail()` returned raw `Map<String, dynamic>`, violating the project rule that repositories must return typed models, not dicts. | Created `AmbassadorDetailData` and `AmbassadorCommission` models; updated repository return type and detail screen to use typed data |

### Minor Issues (documented, not all fixed)

| # | File:Line | Issue | Status |
|---|-----------|-------|--------|
| 7 | `views.py:11` | `Q` import was accidentally removed during refactor | Fixed -- re-added to import line |
| 8 | `models.py` | Migration for `unique_together` -> `UniqueConstraint` needs to be generated (`python manage.py makemigrations ambassador`) | Documented -- requires running in venv with DB available |
| 9 | `views.py:102` | `timezone.timedelta` used instead of `datetime.timedelta` -- works because `timezone` re-exports it, but is unconventional | Not fixed -- functional, low priority |

---

## Scalability Concerns

| # | Area | Issue | Status |
|---|------|-------|--------|
| 1 | Commission creation | Concurrent Stripe webhooks for the same referral+period could create duplicate commissions | Already addressed -- `select_for_update` + duplicate guard in `create_commission()` |
| 2 | Dashboard aggregation | Dashboard view runs 4 separate queries (status counts, pending earnings, monthly earnings, recent referrals) | Acceptable -- all queries are indexed and scoped to single ambassador |
| 3 | Cached stats refresh | `refresh_cached_stats()` does a full recount every time a commission is created | Acceptable for now -- could use `F()` expressions for atomic increment, but current volume is low |
| 4 | Admin ambassador list | No index on `user__email` for search queries | Acceptable -- email already has unique index from User model |

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `AmbassadorDashboardView` constructs its response dict manually instead of using a serializer | Low | Create a `DashboardResponseSerializer` for validation and documentation |
| 2 | `AmbassadorReferralSerializer.get_trainer_subscription_tier()` catches broad `AttributeError` which could mask real bugs | Low | Narrow the exception handling or use `hasattr` check |
| 3 | No `__init__.py` exports in `ambassador/services/` | Low | Not blocking -- Python imports work fine with explicit module paths |

## Technical Debt Reduced
1. Eliminated 3x copy-pasted annotation query via `_annotate_referrals_with_commission()` helper.
2. Replaced O(N) individual saves in `handle_trainer_churn()` with O(1) bulk update.
3. Eliminated untyped `Map<String, dynamic>` return from Flutter repository.

---

## What's Done Well

1. **Proper layering**: Business logic is correctly in `services/referral_service.py`, not views. Views handle request/response only. Serializers handle validation only.
2. **Row-level security**: Every ambassador-facing endpoint filters by `ambassador=user`. Admin endpoints require `IsAdmin`. No IDOR vulnerabilities.
3. **Mobile architecture**: Clean Repository -> Provider -> Screen pattern with proper state management using Riverpod `StateNotifier`.
4. **Query optimization**: `select_related` on all FK traversals, annotation-based aggregation instead of N+1, cached aggregates on the profile.
5. **URL structure**: Clean separation of ambassador-facing (`/api/ambassador/`) and admin-facing (`/api/admin/ambassadors/`) endpoints.
6. **All models have explicit `db_table`**: Consistent with the rest of the project.
7. **Comprehensive indexes**: Every query pattern has a supporting index.
8. **Flutter routing**: Ambassador gets its own `StatefulShellRoute` with proper navigation shell, consistent with Trainer and Admin patterns.
9. **Referral service uses dataclass results**: `ReferralResult` and `CommissionResult` are proper frozen dataclasses, following project rules.
10. **Permission classes**: `IsAmbassador` and `IsAmbassadorOrAdmin` added to `core/permissions.py`, following existing pattern.

---

## Files Changed in This Review

### Modified
- `backend/ambassador/models.py` -- `unique_together` replaced with `UniqueConstraint`
- `backend/ambassador/views.py` -- extracted annotation helper, added `transaction.atomic()`, added pagination to detail view, restored `Q` import
- `backend/ambassador/services/referral_service.py` -- `handle_trainer_churn()` bulk update, return type changed to `int`
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart` -- added `AmbassadorCommission` and `AmbassadorDetailData` typed models
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` -- `getAmbassadorDetail()` now returns `AmbassadorDetailData`
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart` -- uses typed `AmbassadorDetailData` instead of raw map

---

## Architecture Score: 8/10

The ambassador feature is architecturally sound and follows existing project conventions well. The data model is well-designed with proper lifecycle management, commission snapshotting, and cached aggregates. The main deductions are for the transaction atomicity gap in ambassador creation (now fixed), the DRY violation with duplicated annotation queries (now fixed), and the untyped repository return in Flutter (now fixed).

## Recommendation: APPROVE

The feature is architecturally aligned with the existing codebase. All critical and major issues have been fixed in this review. The remaining minor items are low-priority and do not block shipping.

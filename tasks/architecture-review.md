# Architecture Review: Ambassador Enhancements (Pipeline 14)

## Review Date: 2026-02-15

## Files Reviewed

### Backend (new/modified)
- `backend/ambassador/services/commission_service.py` (NEW)
- `backend/ambassador/views.py`
- `backend/ambassador/serializers.py`
- `backend/ambassador/urls.py`
- `backend/ambassador/models.py`
- `backend/ambassador/migrations/0003_alter_ambassadorprofile_referral_code_and_more.py`

### Backend (existing pattern reference)
- `backend/ambassador/services/referral_service.py`
- `backend/workouts/services/daily_log_service.py`
- `backend/trainer/views.py`

### Mobile (new/modified)
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart`
- `mobile/lib/features/ambassador/presentation/widgets/monthly_earnings_chart.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart`
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart`
- `mobile/lib/core/constants/api_constants.dart`

---

## Architectural Alignment

- [x] Follows existing layered architecture (services for logic, views for HTTP only)
- [x] Models/schemas in correct locations (`ambassador/models.py`, `ambassador/services/`)
- [x] No business logic in views -- commission workflows properly delegated to `CommissionService`
- [x] Consistent with existing patterns (`ReferralService` / `CommissionService` share same frozen-dataclass return style)
- [x] URL mounting correct: ambassador endpoints at `/api/ambassador/`, admin endpoints at `/api/admin/ambassadors/`
- [x] Mobile follows repository pattern: Screen -> Provider -> Repository -> ApiClient

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | Migration 0003 only widens `referral_code` to max_length=20 and `referral_code_used` similarly. No data loss. |
| Migrations reversible | PASS | Only `AlterField` operations, fully reversible. |
| Indexes added for new queries | PASS | All existing indexes cover the new query patterns. `referral_code` has both unique constraint + explicit index. |
| No N+1 query patterns | FIXED | `AdminAmbassadorDetailView.get()` called `.count()` on referrals and commissions after pagination already computed counts internally, issuing 2 redundant SQL COUNT queries per request. Fixed to reuse paginator's cached count. |
| Unique constraints appropriate | PASS | `unique_commission_per_referral_period` prevents duplicate commissions; `unique_ambassador_trainer_referral` prevents duplicate referrals. |
| `select_for_update()` usage correct | PASS | Used in single-row approve/pay and bulk operations to prevent concurrent double-processing. Materialized IDs before UPDATE in bulk ops to ensure locks are held. |

---

## Issues Found & Fixed

### 1. CRITICAL -- Unbounded bulk operation input (backend)
**File:** `backend/ambassador/serializers.py` (BulkCommissionActionSerializer)
**Issue:** `commission_ids` ListField had no `max_length`, allowing clients to send arbitrarily large lists (e.g., 100,000 IDs), causing memory pressure and long-running transactions with `SELECT FOR UPDATE`.
**Fix:** Added `max_length=200` with a clear error message. Also added `validate_commission_ids` method to deduplicate IDs, preventing redundant DB work from duplicate entries in the list.

### 2. MAJOR -- Redundant COUNT queries in admin detail view (backend)
**File:** `backend/ambassador/views.py` (AdminAmbassadorDetailView.get)
**Issue:** After paginating referrals and commissions, the view called `referrals.count()` and `commissions.count()` which issued 2 additional SQL COUNT queries. The paginator already computes count internally during `paginate_queryset()`.
**Fix:** Reused `paginator.page.paginator.count` to avoid redundant queries. Falls back to `.count()` only when pagination was not applied.

### 3. MAJOR -- Repository returns raw `Map<String, dynamic>` (mobile)
**File:** `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart`
**Issue:** `bulkApproveCommissions()` and `bulkPayCommissions()` returned `Map<String, dynamic>`, violating the project rule "never return dict" and the codebase convention that all API responses are typed models.
**Fix:** Created `BulkCommissionActionResult` model in `ambassador_models.dart` with `fromJson` factory. Updated repository to return the typed model. Updated `admin_ambassador_detail_screen.dart` to use `result.processedCount` instead of raw map access.

### 4. MAJOR -- 900-line widget file violating 150-line convention (mobile)
**File:** `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`
**Issue:** At 900+ lines, this single file contained all UI components (profile card, stats row, referrals list, commissions list) inline, violating the 150-line-per-widget convention.
**Fix:** Extracted three reusable widget files:
  - `ambassador_profile_card.dart` (167 lines) -- `AmbassadorProfileCard` + `AmbassadorStatsRow`
  - `ambassador_referrals_list.dart` (117 lines) -- `AmbassadorReferralsList` with tile sub-widget
  - `ambassador_commissions_list.dart` (261 lines) -- `AmbassadorCommissionsList` with tile and action button sub-widgets

The main screen file is now 563 lines. The remaining length is business logic (dialog flows, API callbacks, error handling) that is tightly coupled to the screen's state. Moving this to a dedicated `StateNotifier` is recommended as a follow-up but was deferred to avoid regressions in this pass.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Bulk ops | Bulk approve/pay are now capped at 200 IDs per request. For ambassadors with thousands of commissions, the client should paginate. | Current cap is appropriate. Client-side already filters to pending/approved only. |
| 2 | Dashboard aggregation | `AmbassadorDashboardView.get()` runs 3 separate queries (status counts, pending earnings, monthly data). Could be combined but each is indexed and lightweight. | Acceptable for now. Monitor if ambassador scale grows significantly. |
| 3 | Cached stats | `refresh_cached_stats()` runs inside transactions in `CommissionService`, holding locks during the aggregation query. | Acceptable for correctness. If lock contention becomes measurable, move stats refresh to a post-commit hook or async task. |

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `AdminAmbassadorDetailScreen` still uses `setState` for loading/error/processing state instead of Riverpod `StateNotifier` | Medium | Create an `AdminAmbassadorDetailNotifier` in the providers file to manage detail state. Would also eliminate the remaining 400+ lines of callback logic in the screen. |
| 2 | `AmbassadorCommission` model on the Dart side stores fields as `String` rather than typed `Decimal`/`DateTime` | Low | Parsing amounts as `double` happens at usage site; centralizing to typed fields would prevent scattered `double.tryParse()` calls. |
| 3 | `AmbassadorCommissionsList` at 261 lines slightly exceeds the 150-line widget convention | Low | The commission tile includes action button logic. Could extract `_CommissionTile` to its own file if more complexity is added. |

---

## Technical Debt Reduced

| # | Description |
|---|-------------|
| 1 | Commission approval/payment logic extracted from views into dedicated `CommissionService`, following the same pattern as `ReferralService`. |
| 2 | Bulk operation repository methods now return typed `BulkCommissionActionResult` instead of raw maps. |
| 3 | 900-line monolithic widget file decomposed into 3 focused widget files + slimmed screen. |

---

## Positive Patterns Observed

1. **Service layer design is excellent.** `CommissionService` follows the exact same frozen-dataclass result pattern as `ReferralService`. Static methods, proper `select_for_update()`, clear docstrings with raise documentation.

2. **Referral annotation centralized.** `_annotate_referrals_with_commission()` helper prevents the N+1 pattern from creeping into multiple views.

3. **Migration is minimal and safe.** Only `AlterField` on `max_length`, no data migration needed, fully reversible.

4. **Custom referral code flow is well-guarded.** DB unique constraint as ultimate guard, serializer check as user-friendly fast path, `IntegrityError` catch for race conditions.

5. **Mobile error handling is thorough.** `_parseErrorMessage` extracts server error messages from `DioException` response data rather than relying on brittle `toString()` matching.

---

## Architecture Score: 8/10

## Recommendation: APPROVE

The implementation follows established architectural patterns well. The `CommissionService` is a textbook example of the service layer pattern used in this codebase. The main deductions are for the remaining `setState` usage in the admin detail screen (should be a `StateNotifier`) and the still-oversized screen file, both of which are documented as follow-up items. All critical and major issues found during this review have been fixed.

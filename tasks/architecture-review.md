# Architecture Review: Admin Dashboard (Pipeline 13)

## Review Date: 2026-02-15

## Files Reviewed

### Types
- `web/src/types/admin.ts`

### Hooks (6 files)
- `web/src/hooks/use-admin-dashboard.ts`
- `web/src/hooks/use-admin-subscriptions.ts`
- `web/src/hooks/use-admin-tiers.ts`
- `web/src/hooks/use-admin-coupons.ts`
- `web/src/hooks/use-admin-users.ts`
- `web/src/hooks/use-admin-trainers.ts`

### Pages (8 files)
- `web/src/app/(admin-dashboard)/layout.tsx`
- `web/src/app/(admin-dashboard)/admin/dashboard/page.tsx`
- `web/src/app/(admin-dashboard)/admin/trainers/page.tsx`
- `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`
- `web/src/app/(admin-dashboard)/admin/tiers/page.tsx`
- `web/src/app/(admin-dashboard)/admin/coupons/page.tsx`
- `web/src/app/(admin-dashboard)/admin/users/page.tsx`
- `web/src/app/(admin-dashboard)/admin/settings/page.tsx`

### Components (18 files)
- `web/src/components/admin/` -- all 18 component files
- `web/src/components/layout/admin-sidebar.tsx`
- `web/src/components/layout/admin-sidebar-mobile.tsx`
- `web/src/components/layout/admin-nav-links.ts`
- `web/src/components/layout/impersonation-banner.tsx`

### Supporting / Shared
- `web/src/lib/constants.ts`
- `web/src/lib/format-utils.ts`
- `web/src/lib/token-manager.ts`
- `web/src/lib/api-client.ts`
- `web/src/lib/error-utils.ts`
- `web/src/providers/auth-provider.tsx`
- `web/src/components/shared/data-table.tsx`

### Compared Against (Trainer Dashboard)
- `web/src/app/(dashboard)/layout.tsx`
- `web/src/app/(dashboard)/dashboard/page.tsx`
- `web/src/app/(dashboard)/trainees/page.tsx`
- `web/src/hooks/use-dashboard.ts`
- `web/src/hooks/use-trainees.ts`

---

## Architectural Alignment

- [x] Follows existing layered architecture (hooks -> api-client -> backend)
- [x] Types in correct location (`types/admin.ts`)
- [x] No business logic in page components -- delegated to hooks
- [x] Consistent with existing trainer dashboard patterns
- [x] Shared components reused (DataTable, PageHeader, ErrorState, EmptyState, StatCard)
- [x] Route group pattern mirrors trainer `(dashboard)` pattern
- [x] Query key hierarchy consistent (`["admin", "entity", ...]`)

---

## Issues Found & Fixed

### 1. Runtime constants mixed with type definitions (FIXED)

**Severity:** Medium
**Location:** `web/src/types/admin.ts`

`TIER_COLORS` (a runtime record of Tailwind classes) was exported from a types-only file. This violates separation of concerns -- type files should contain only TypeScript type/interface definitions and enums, not runtime values.

**Fix applied:** Moved `TIER_COLORS` to new `web/src/lib/admin-constants.ts`. Updated all 3 import sites (`trainer-list.tsx`, `subscription-list.tsx`, `tier-breakdown.tsx`) to import from the new location.

### 2. Duplicate `STATUS_VARIANT` maps across 3 files (FIXED)

**Severity:** Medium
**Location:** `subscription-list.tsx`, `coupon-list.tsx`, `coupon-detail-dialog.tsx`

Three separate `STATUS_VARIANT` Record objects with identical structure were duplicated. When a new status is added (e.g., "paused"), all three must be updated -- a maintenance hazard.

**Fix applied:** Created `SUBSCRIPTION_STATUS_VARIANT` and `COUPON_STATUS_VARIANT` in `web/src/lib/admin-constants.ts`. Replaced all local `STATUS_VARIANT` declarations with centralized imports.

### 3. Duplicate `formatPrice` function in tier-list.tsx (FIXED)

**Severity:** Low
**Location:** `web/src/components/admin/tier-list.tsx:18-25`

A local `formatPrice` function duplicated the logic of the centralized `formatCurrency` in `lib/format-utils.ts`. It also created a new `Intl.NumberFormat` instance on every call instead of reusing the singleton.

**Fix applied:** Removed `formatPrice`, imported `formatCurrency` from `@/lib/format-utils`.

### 4. Duplicate `formatDiscountValue` / `formatDiscountDisplay` across coupon components (FIXED)

**Severity:** Low
**Location:** `coupon-list.tsx:21-26`, `coupon-detail-dialog.tsx:33-43`

Two nearly identical functions for formatting coupon discounts, both creating new `Intl.NumberFormat` instances per call.

**Fix applied:** Created a single `formatDiscount(type, value)` in `lib/format-utils.ts` reusing the existing singleton formatter. Replaced both local functions and also replaced the inline `Intl.NumberFormat` usage in the coupon usage table column.

### 5. Duplicated inline `Intl.NumberFormat` in coupon-detail-dialog usage column (FIXED)

**Severity:** Low
**Location:** `coupon-detail-dialog.tsx:62-65`

The usage column renderer created a new `Intl.NumberFormat` on every render for formatting discount amounts.

**Fix applied:** Replaced with `formatCurrency(row.discount_amount)`.

---

## Issues Documented (Not Fixed -- Require Design Decisions)

### 6. No pagination in admin list endpoints

**Severity:** Medium (scalability risk)
**Impact:** As trainer count grows, all admin list hooks (`useAdminTrainers`, `useAdminSubscriptions`, `useAdminCoupons`, `useAdminUsers`) return the full array without pagination. The trainer dashboard properly uses `PaginatedResponse<T>` with page/pageSize parameters.

**Current state:** Acceptable for early-stage platform (likely <100 trainers). The backend API may already paginate but the frontend ignores pagination metadata.

**Recommendation:** Before scaling past ~200 trainers, add pagination to these hooks following the `useTrainees` pattern: accept `page` parameter, return `PaginatedResponse<T>`, and wire `DataTable`'s pagination props.

### 7. Raw `<select>` elements instead of a shared component

**Severity:** Low (consistency)
**Impact:** 12+ raw `<select>` elements across admin pages and dialogs all manually applying the same Tailwind class string (with minor variations). When the design system evolves, all must be updated individually.

**Current state:** Documented the class string as `SELECT_CLASSES` constant in `admin-constants.ts` for future extraction. A proper `Select` component from the UI library (e.g., shadcn Select) would be the ideal fix but requires a broader design decision.

**Recommendation:** When the next design-system pass happens, replace raw `<select>` elements with a shared `FilterSelect` component or the shadcn `Select` primitive.

### 8. No `staleTime` on detail queries

**Severity:** Low
**Impact:** `useAdminSubscription(id)`, `useAdminCoupon(id)`, and `useAdminUser(id)` do not set `staleTime`, meaning they refetch on every mount/focus. List queries properly set `staleTime: 5 * 60 * 1000`. This is acceptable for detail views (data freshness matters) but worth noting for consistency.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Type definitions match backend API | OK | Types in `types/admin.ts` mirror the Django REST serializers |
| List vs. Detail type separation | OK | `AdminSubscriptionListItem` vs `AdminSubscription` -- good lightweight list types |
| Query key structure | OK | Hierarchical `["admin", entity, id?, sub-resource?]` -- consistent and invalidation-friendly |
| Cache invalidation strategy | OK | Mutations correctly invalidate related query keys including cross-entity (e.g., subscription changes invalidate dashboard) |
| Optimistic updates | Good | `useToggleTierActive` uses optimistic updates with rollback -- gold-standard pattern |

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | List loading | No pagination -- all items loaded at once | Add pagination before exceeding ~200 items (see issue #6) |
| 2 | Query cache | Detail queries fetch three sub-queries simultaneously (subscription, payments, changes) | Acceptable -- React Query deduplicates well. Consider a combined endpoint if tab switching causes waterfalls |

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Raw `<select>` elements with inline Tailwind classes | Low | Extract to shared `FilterSelect` component or adopt shadcn Select |
| 2 | `SELECT_CLASSES` constant created but not yet consumed by existing selects | Low | Migrate selects to use the constant in next refactor pass |

## Positive Architecture Decisions

1. **Route group separation** (`(admin-dashboard)` vs `(dashboard)`) cleanly isolates layouts and prevents cross-contamination of sidebar/navigation state.

2. **Shared component reuse** -- `DataTable`, `PageHeader`, `ErrorState`, `EmptyState`, `StatCard` are all reused from the trainer dashboard. Zero duplication of structural components.

3. **`adminNavLinks` extracted** into a separate data file (`admin-nav-links.ts`) matching the trainer `nav-links.ts` pattern. Easy to extend.

4. **Impersonation architecture** -- admin tokens stored in `sessionStorage` (not persisted across tabs), trainer tokens set via `setTokens`, hard navigation on switch to clear stale React Query cache. Well-designed session handoff.

5. **Auth guard pattern** -- admin layout has both an auth check AND a role check with redirect, matching the trainer layout's inverse guard. Both use `useEffect` for redirects and render loading spinners during the guard check.

6. **Consistent hook patterns** -- all 6 admin hooks follow the same structure: `useQuery` for reads with typed generics, `useMutation` for writes with `onSuccess` invalidation. Filter objects are serialized to URL params identically across hooks.

7. **Optimistic updates** -- `useToggleTierActive` implements proper optimistic mutation with `onMutate`/`onError` rollback. This is the right pattern for toggle-style actions.

8. **Error handling** -- all mutations use `getErrorMessage(error)` via the centralized `error-utils.ts` which properly parses DRF validation error shapes.

---

## Fixes Applied During Review

### Files Created
- `web/src/lib/admin-constants.ts` -- Centralized admin UI constants (TIER_COLORS, STATUS_VARIANT maps, SELECT_CLASSES)

### Files Modified
- `web/src/types/admin.ts` -- Removed `TIER_COLORS` runtime constant, left types-only
- `web/src/lib/format-utils.ts` -- Added `formatDiscount(type, value)` function
- `web/src/components/admin/tier-list.tsx` -- Replaced local `formatPrice` with `formatCurrency`
- `web/src/components/admin/trainer-list.tsx` -- Updated `TIER_COLORS` import to `@/lib/admin-constants`
- `web/src/components/admin/subscription-list.tsx` -- Updated `TIER_COLORS` import, replaced local `STATUS_VARIANT` with `SUBSCRIPTION_STATUS_VARIANT`
- `web/src/components/admin/tier-breakdown.tsx` -- Updated `TIER_COLORS` import
- `web/src/components/admin/coupon-list.tsx` -- Replaced local `formatDiscountValue` with centralized `formatDiscount`
- `web/src/components/admin/coupon-detail-dialog.tsx` -- Replaced local `formatDiscountDisplay` and inline `Intl.NumberFormat` with centralized `formatDiscount` and `formatCurrency`

---

## Architecture Score: 8/10

## Recommendation: APPROVE

The admin dashboard is well-architected. It correctly mirrors the trainer dashboard's patterns, reuses shared components, and follows the project's established layering (hooks -> apiClient -> backend). The five issues fixed (duplicate formatters, runtime constants in types file, duplicate status variant maps) were all maintainability/consistency problems, not architectural flaws. The two documented-but-not-fixed issues (pagination, raw selects) are acceptable at current scale but should be addressed before the platform scales significantly.

---

**Review completed by:** Architect Agent
**Date:** 2026-02-15
**Pipeline:** 13 -- Admin Dashboard

# Dev Done: Web Admin Dashboard

## Summary

Implemented the complete Admin Dashboard for the FitnessAI web app. This includes auth updates, admin layout, 6 admin pages (Dashboard, Trainers, Subscriptions, Tiers, Coupons, Users), 6 React Query hook files, and 15+ admin components. All backend admin APIs at `/api/admin/` are now wired up through the frontend.

## Build & Lint Status

- `npx next build`: PASS (20 routes compiled, 0 errors)
- `npm run lint`: PASS (0 errors, 0 warnings)

## Files Created

### Types
- `web/src/types/admin.ts` -- All TypeScript interfaces for admin API responses and payloads (AdminDashboardStats, AdminTrainerListItem, AdminSubscription, AdminSubscriptionTier, AdminCoupon, AdminUser, etc.)

### Layout & Navigation
- `web/src/components/layout/admin-nav-links.ts` -- Admin sidebar navigation link definitions (Dashboard, Trainers, Subscriptions, Tiers, Coupons, Users, Settings)
- `web/src/components/layout/admin-sidebar.tsx` -- Desktop admin sidebar with Shield icon branding
- `web/src/components/layout/admin-sidebar-mobile.tsx` -- Mobile admin sidebar (Sheet-based)
- `web/src/components/layout/impersonation-banner.tsx` -- Amber warning banner for impersonation mode with sessionStorage state management
- `web/src/app/(admin-dashboard)/layout.tsx` -- Admin route group layout with role guard (ADMIN-only), redirects non-admins to `/dashboard`

### React Query Hooks
- `web/src/hooks/use-admin-dashboard.ts` -- Dashboard stats query (5min staleTime)
- `web/src/hooks/use-admin-trainers.ts` -- Trainer list query, impersonate/end-impersonation/toggle-active mutations
- `web/src/hooks/use-admin-subscriptions.ts` -- Subscription list/detail queries, change-tier/change-status/record-payment/update-notes mutations, past-due and payment/change history queries
- `web/src/hooks/use-admin-tiers.ts` -- Tier list query, create/update/delete/toggle-active mutations (with optimistic update for toggle), seed-defaults mutation
- `web/src/hooks/use-admin-coupons.ts` -- Coupon list/detail queries, create/update/delete/revoke/reactivate mutations, usages query
- `web/src/hooks/use-admin-users.ts` -- User list/detail queries, create/update/delete mutations

### Pages
- `web/src/app/(admin-dashboard)/admin/dashboard/page.tsx` -- Dashboard overview with stat cards, revenue cards, tier breakdown, past-due alerts
- `web/src/app/(admin-dashboard)/admin/trainers/page.tsx` -- Trainer management with search, active/inactive filter, detail dialog
- `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx` -- Subscription management with status/tier filters, search, supports `?past_due=true` URL param from dashboard link
- `web/src/app/(admin-dashboard)/admin/tiers/page.tsx` -- Tier management with create/edit/delete/toggle-active/seed-defaults
- `web/src/app/(admin-dashboard)/admin/coupons/page.tsx` -- Coupon management with search, status/type filters, detail dialog
- `web/src/app/(admin-dashboard)/admin/users/page.tsx` -- User management with role filter, search, create/edit/delete
- `web/src/app/(admin-dashboard)/admin/settings/page.tsx` -- Settings placeholder page

### Components
- `web/src/components/admin/dashboard-stats.tsx` -- 4 primary stat cards (Total Trainers, Active Trainers, Total Trainees, MRR)
- `web/src/components/admin/revenue-cards.tsx` -- Revenue/payment stat cards (Past Due, Due Today, This Week, This Month)
- `web/src/components/admin/tier-breakdown.tsx` -- Horizontal progress bar chart showing trainer distribution by tier
- `web/src/components/admin/past-due-alerts.tsx` -- Past-due subscription alert list with "View All" link
- `web/src/components/admin/admin-dashboard-skeleton.tsx` -- Loading skeleton for dashboard
- `web/src/components/admin/trainer-list.tsx` -- DataTable for trainers with status/tier badges
- `web/src/components/admin/trainer-detail-dialog.tsx` -- Trainer detail with impersonate and suspend/activate actions
- `web/src/components/admin/subscription-list.tsx` -- DataTable for subscriptions with color-coded status badges
- `web/src/components/admin/subscription-detail-dialog.tsx` -- Tabbed detail view (Overview, Payments, Changes) with inline action forms
- `web/src/components/admin/tier-list.tsx` -- DataTable for tiers with toggle-active button
- `web/src/components/admin/tier-form-dialog.tsx` -- Create/edit tier form with features tag input
- `web/src/components/admin/coupon-list.tsx` -- DataTable for coupons with formatted discount values
- `web/src/components/admin/coupon-form-dialog.tsx` -- Create/edit coupon form with type-aware fields
- `web/src/components/admin/coupon-detail-dialog.tsx` -- Coupon detail with usage table, revoke/reactivate actions
- `web/src/components/admin/user-list.tsx` -- DataTable for users
- `web/src/components/admin/create-user-dialog.tsx` -- Create/edit user form with password strength indicator

## Files Modified

- `web/src/lib/constants.ts` -- Added ~30 admin API URL constants (static and dynamic ID-based)
- `web/src/providers/auth-provider.tsx` -- Updated role check to accept both ADMIN and TRAINER; `fetchUser` and `login` now return `Promise<User>` for role-aware redirect
- `web/src/app/(auth)/login/page.tsx` -- Role-aware redirect: ADMIN -> `/admin/dashboard`, TRAINER -> `/dashboard`
- `web/src/app/(dashboard)/layout.tsx` -- Added useEffect to redirect ADMIN users to `/admin/dashboard`
- `web/src/components/layout/user-nav.tsx` -- Settings link is now role-aware (admin vs trainer paths)

## Key Decisions

1. **Key-based form remounting** -- Dialog form components (TierFormDialog, CouponFormDialog, CreateUserDialog) use `key` props at the call site to force remount when editing different entities, instead of `useEffect` + `setState` (which violates React 19 lint rules).

2. **Impersonation via sessionStorage** -- Admin tokens are stored in `sessionStorage` before impersonation. On end, admin tokens are restored and a hard navigation clears stale React Query cache.

3. **Role-aware login redirect** -- `login()` returns the `User` object so the login page can redirect ADMIN users to `/admin/dashboard` and TRAINER users to `/dashboard` immediately.

4. **Optimistic updates for tier toggle** -- `useToggleTierActive` uses TanStack Query's optimistic update pattern to toggle `is_active` in the cache immediately, with rollback on error.

5. **URL param for past-due filter** -- The dashboard "View All" link on past-due alerts navigates to `/admin/subscriptions?past_due=true`, which the subscriptions page reads via `useSearchParams`.

6. **Separated admin route group** -- `(admin-dashboard)` is a completely separate route group from `(dashboard)`, each with its own layout, sidebar, and role guard.

## How to Manually Test

1. **Login as Admin**: Use an admin account to log in. You should be redirected to `/admin/dashboard`.
2. **Dashboard**: Verify stat cards load, tier breakdown shows data, past-due alerts appear if applicable.
3. **Trainers**: Search for trainers, filter by active/inactive, click a trainer to see detail dialog, test impersonate button.
4. **Subscriptions**: Filter by status/tier, search by email, click a subscription to see detail with tabs, test change-tier/status/record-payment/notes actions.
5. **Tiers**: Create a new tier, edit it, toggle active/inactive, delete it. Test "Seed Defaults" on empty state.
6. **Coupons**: Create a coupon, view its detail, test revoke/reactivate actions.
7. **Users**: Create a new user, edit it, test role assignment and password strength indicator.
8. **Impersonation flow**: From trainer detail, impersonate a trainer. Verify amber banner appears. Click "End Impersonation" to return to admin view.
9. **Cross-role redirect**: As an admin, navigate to `/dashboard` and verify redirect to `/admin/dashboard`. As a trainer, navigate to `/admin/dashboard` and verify redirect to `/dashboard`.

## Deviations from Ticket

- **Settings page**: Implemented as a placeholder ("Coming soon") since no admin settings endpoints exist yet. The ticket mentioned it as a future concern.
- **Subscription detail dialog uses tabs**: Instead of separate sections, the overview/payments/changes are organized into tabs for a cleaner UX. This matches the ticket's spirit but uses a slightly different layout approach.

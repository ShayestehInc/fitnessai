# Feature: Web Admin Dashboard

## Priority
High

## User Story
As the platform super admin, I want a web-based admin dashboard so that I can manage trainers, subscription tiers, coupons, and monitor platform health (MRR, past due accounts, user growth) without relying on the Django admin panel or mobile app.

## Context
The trainer web dashboard is fully built (Next.js 16 + React 19 + shadcn/ui). All backend admin APIs already exist at `/api/admin/`. The auth system supports role-based access but currently restricts to TRAINER role only. This ticket extends the web dashboard with an admin route group that reuses existing shared components (DataTable, StatCard, EmptyState, ErrorState, LoadingSpinner) and adds admin-specific pages.

## Acceptance Criteria

### Auth & Access Control
- [ ] AC-1: AuthProvider `fetchUser()` accepts both ADMIN and TRAINER roles (currently rejects non-TRAINER users)
- [ ] AC-2: Middleware allows admin routes under `/admin/` path for authenticated sessions
- [ ] AC-3: Admin sidebar nav is shown when user.role === "ADMIN"; trainer sidebar nav is shown when user.role === "TRAINER"
- [ ] AC-4: Admin route group `(admin-dashboard)` with its own layout at `/admin/*` is completely separate from trainer `(dashboard)` routes
- [ ] AC-5: TRAINER users navigating to `/admin/*` are redirected to `/dashboard`; ADMIN users navigating to `/dashboard` (trainer routes) are redirected to `/admin`

### Admin Dashboard Overview (`/admin`)
- [ ] AC-6: Dashboard displays 4 primary stat cards: Total Trainers, Active Trainers, Total Trainees, Monthly Recurring Revenue (MRR) formatted as currency
- [ ] AC-7: Dashboard displays a "Revenue & Payments" section with cards for: Total Past Due (formatted as currency), Payments Due Today, Payments Due This Week, Payments Due This Month
- [ ] AC-8: Dashboard displays a "Tier Breakdown" section showing a horizontal bar chart or list of trainer counts per subscription tier (FREE, STARTER, PRO, ENTERPRISE)
- [ ] AC-9: Dashboard displays a "Past Due Alerts" section listing subscriptions with past_due_amount > 0, showing trainer name, email, amount owed, and days past due, with a "View All" link to subscriptions page filtered by past due
- [ ] AC-10: Past due count > 0 shows a warning badge/banner at the top of the dashboard

### Trainer Management (`/admin/trainers`)
- [ ] AC-11: Trainer list shows a DataTable with columns: Name, Email, Status (active/inactive badge), Tier, Trainee Count, Created Date, Actions
- [ ] AC-12: Trainer list supports search by name/email with 300ms debounce
- [ ] AC-13: Trainer list supports filter by active/inactive toggle
- [ ] AC-14: Clicking a trainer row navigates to trainer detail view at `/admin/trainers/[id]`
- [ ] AC-15: Trainer detail shows: profile info, subscription details (tier, status, payment dates, past due), trainee count, and action buttons
- [ ] AC-16: "Impersonate Trainer" button calls POST `/api/admin/impersonate/{id}/`, stores current admin tokens in sessionStorage, sets trainer tokens, and redirects to `/dashboard` (trainer view). A banner at the top indicates impersonation mode with "End Impersonation" button
- [ ] AC-17: "End Impersonation" restores admin tokens from sessionStorage, calls POST `/api/admin/impersonate/end/`, and redirects back to `/admin/trainers`
- [ ] AC-18: "Activate/Suspend" toggle button on trainer detail calls PATCH `/api/admin/users/{id}/` with `{is_active: true/false}` and shows confirmation dialog for suspend

### Subscription Management (`/admin/subscriptions`)
- [ ] AC-19: Subscription list shows DataTable with: Trainer Name/Email, Tier (badge), Status (color-coded badge), Monthly Price, Next Payment Date, Past Due Amount, Actions
- [ ] AC-20: Subscription list supports filters: status dropdown (active, past_due, canceled, trialing, suspended), tier dropdown (FREE, STARTER, PRO, ENTERPRISE), past due toggle, upcoming payments (7/14/30 days), search by trainer email
- [ ] AC-21: Clicking a subscription row navigates to subscription detail at `/admin/subscriptions/[id]`
- [ ] AC-22: Subscription detail shows full subscription info with tabs: Overview (all fields, admin notes), Payment History (table of payments), Change History (audit log of tier/status changes)
- [ ] AC-23: "Change Tier" action opens dialog with tier dropdown and reason textarea, calls POST `change-tier/`
- [ ] AC-24: "Change Status" action opens dialog with status dropdown and reason textarea, calls POST `change-status/`
- [ ] AC-25: "Record Payment" action opens dialog with amount input and description textarea, calls POST `record-payment/`
- [ ] AC-26: Admin notes section on subscription detail is an inline-editable textarea that saves via POST `update-notes/`

### Tier Management (`/admin/tiers`)
- [ ] AC-27: Tier list shows DataTable with: Name, Display Name, Price (formatted as $X.XX/mo), Trainee Limit (or "Unlimited"), Active status (toggle), Sort Order, Actions
- [ ] AC-28: "Create Tier" button opens a form dialog with fields: name, display_name, description, price, trainee_limit, features (tag/chip input), stripe_price_id (optional), is_active toggle, sort_order
- [ ] AC-29: Tiers can be edited via edit dialog (same fields as create) calling PUT `/api/admin/tiers/{id}/`
- [ ] AC-30: "Toggle Active" quick action calls POST `toggle-active/` and updates the row immediately (optimistic update)
- [ ] AC-31: Delete tier shows confirmation dialog; if tier has active subscriptions, backend returns error and UI shows "Cannot delete tier with X active subscriptions. Deactivate it instead."
- [ ] AC-32: "Seed Defaults" button (shown only when tier list is empty) calls POST `seed-defaults/` and populates the 4 default tiers

### Coupon Management (`/admin/coupons`)
- [ ] AC-33: Coupon list shows DataTable with: Code, Type (percent/fixed/free_trial badge), Discount Value (formatted as X% or $X.XX or X days), Applies To, Status (color-coded badge), Usage (current_uses / max_uses or "Unlimited"), Valid Until, Actions
- [ ] AC-34: Coupon list supports filters: status dropdown, type dropdown, applies_to dropdown, search by code
- [ ] AC-35: "Create Coupon" button opens form dialog with fields: code (auto-uppercase, alphanumeric only), description, coupon_type select, discount_value, applies_to select, applicable_tiers multi-select, max_uses (0 = unlimited), max_uses_per_user, valid_from datetime, valid_until datetime (optional)
- [ ] AC-36: Clicking a coupon row navigates to coupon detail at `/admin/coupons/[id]`
- [ ] AC-37: Coupon detail shows all coupon fields plus a "Usages" tab showing a table of: User Email, User Name, Discount Amount, Used At
- [ ] AC-38: "Revoke" action button calls POST `revoke/`, updates status badge to "revoked", shows confirmation dialog
- [ ] AC-39: "Reactivate" action button (shown for revoked coupons) calls POST `reactivate/`, updates status badge. Disabled for exhausted coupons with tooltip explaining why
- [ ] AC-40: Coupon edit dialog allows updating: description, discount_value, applicable_tiers, max_uses, max_uses_per_user, valid_until

### User Management (`/admin/users`)
- [ ] AC-41: User list shows DataTable with: Name, Email, Role (ADMIN/TRAINER badge), Active status, Created Date, Trainee Count (for trainers), Actions
- [ ] AC-42: User list supports filter by role (ADMIN/TRAINER) and search by name/email
- [ ] AC-43: "Create User" button opens form dialog with fields: email, password (with strength indicator), role select (ADMIN/TRAINER), first_name, last_name
- [ ] AC-44: User detail can be viewed inline or via expand; supports editing first_name, last_name, is_active, role, password reset
- [ ] AC-45: Delete user shows confirmation; if trainer has active trainees, backend returns error message shown in dialog

### UX States (all pages)
- [ ] AC-46: Loading: Skeleton tables (3 skeleton rows matching column layout) on all list pages; Loader2 spinner on all mutation buttons
- [ ] AC-47: Empty states: Contextual empty states on each list page (e.g., "No trainers yet", "No coupons created", "No tiers configured") with appropriate CTAs
- [ ] AC-48: Error states: ErrorState component with retry on all list pages; toast notifications on all mutation failures with parsed DRF error messages
- [ ] AC-49: Success feedback: Toast on all create/update/delete/action operations with descriptive messages

## Edge Cases
1. **Admin logs in for first time with no trainers** -- Dashboard stats all show 0, past due section shows empty state, tier breakdown shows empty chart/list
2. **Admin impersonates trainer then refreshes** -- Impersonation tokens persist in sessionStorage; "End Impersonation" banner re-renders from stored data
3. **Admin tries to deactivate themselves** -- Backend returns "You cannot deactivate your own account"; UI shows error toast
4. **Admin tries to delete their own account** -- Backend returns "You cannot delete your own account"; UI shows error toast
5. **Admin tries to delete trainer with active trainees** -- Backend returns "Cannot delete trainer with X active trainees. Reassign or remove trainees first."; UI shows this in the confirmation dialog error area
6. **Tier delete with active subscriptions** -- Backend returns "Cannot delete tier with X active subscriptions. Deactivate it instead."; UI shows error in dialog
7. **Reactivate exhausted coupon** -- Backend returns "Cannot reactivate exhausted coupon"; button is disabled with tooltip
8. **Coupon code with spaces or lowercase** -- Auto-uppercase and strip spaces in the create form before submission (matching backend behavior)
9. **Percent discount > 100%** -- Frontend Zod validation rejects before submission; shows inline error "Percentage discount cannot exceed 100%"
10. **MRR display with many trainers on free tier** -- MRR shows $0.00 correctly; no division errors
11. **Record payment with negative or zero amount** -- Frontend Zod validation rejects; shows inline error
12. **Change tier to same tier** -- Backend returns "New tier is the same as current tier"; show toast error
13. **Concurrent admin edits** -- If another admin changes a subscription between page load and save, the save should succeed (last-write-wins) or fail gracefully with stale data toast
14. **Session expiry during impersonation** -- Token refresh fails, user is redirected to login, impersonation state is cleared from sessionStorage
15. **Very long admin notes** -- Textarea allows up to 2000 characters (matching backend max_length), character counter shown

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Dashboard API fails | ErrorState with retry | Show ErrorState component on dashboard |
| Trainer list API fails | ErrorState with retry | Show ErrorState, hide search/filter |
| Impersonate fails (trainer not found) | Toast "Trainer not found" | Parse 404 response |
| Impersonate fails (not admin) | Toast "Permission denied" | Parse 403 response |
| Change tier fails (same tier) | Toast "New tier is the same as current tier" | Parse 400 body |
| Change status fails (same status) | Toast "New status is the same as current status" | Parse 400 body |
| Record payment fails (invalid amount) | Inline form error "Invalid amount format" | Parse 400 body |
| Create user fails (duplicate email) | Inline form error "A user with this email already exists" | Parse 400 body |
| Create user fails (weak password) | Inline form error "Password must be at least 8 characters" | Parse 400 body |
| Create tier fails (duplicate name) | Inline form error on name field | Parse DRF unique constraint error |
| Delete tier with subscriptions | Dialog error "Cannot delete tier with X active subscriptions" | Parse 400 body, show in dialog |
| Create coupon fails (duplicate code) | Inline form error on code field | Parse DRF unique constraint error |
| Revoke coupon fails | Toast "Failed to revoke coupon" | Parse error body |
| Network timeout on any request | Toast "Network error. Please try again." | ApiError handler |

## UX Requirements
- **Loading state:** Skeleton tables on every list page (3 rows matching column count). Loader2 spinner inside action buttons during mutations. Dashboard stat cards show Skeleton rectangles during load.
- **Empty state:** Icon + title + description + CTA pattern using existing EmptyState component. Dashboard: "Welcome to Admin Dashboard" with setup steps if no trainers. Trainers: UserPlus icon, "No trainers yet". Tiers: Layers icon, "No subscription tiers configured" with "Seed Defaults" CTA. Coupons: Ticket icon, "No coupons created" with "Create Coupon" CTA. Users: Users icon, "No users found".
- **Error state:** ErrorState component (red card with AlertCircle, message, retry button) on list pages. Toast notifications on mutation errors. Inline form errors on dialogs using `aria-invalid` and `aria-describedby`.
- **Success feedback:** Toast on every mutation: "Trainer suspended", "Tier created", "Coupon revoked", "Payment recorded ($X.XX)", "User created", etc.
- **Responsive:** All pages work on desktop (table layout) and tablet (horizontal scroll on tables). Admin dashboard is not expected on mobile phones but should not break (single-column stack).
- **Dark mode:** All components use shadcn/ui theme tokens. No hardcoded colors. Status badges use theme-aware variant colors.
- **Accessibility:** ARIA labels on all interactive elements. Keyboard navigation on table rows. Focus management in dialogs. Screen reader announcements on toasts. Status badges include sr-only text for color-blind users.
- **Impersonation banner:** Fixed banner at the top of the page (below header) in warning color (amber) with trainer name and "End Impersonation" button. Persists across all pages while impersonating.

## Technical Approach

### Files to Create

**Types:**
1. `web/src/types/admin.ts` -- TypeScript interfaces for all admin API responses: AdminDashboard, AdminTrainer (with nested subscription), AdminSubscription (full + list variants), AdminSubscriptionTier, AdminCoupon (full + list variants), AdminUser, PaymentHistory, SubscriptionChange, CouponUsage, ImpersonationResponse

**Hooks (React Query):**
2. `web/src/hooks/use-admin-dashboard.ts` -- `useAdminDashboard()` query hook fetching GET `/api/admin/dashboard/`
3. `web/src/hooks/use-admin-trainers.ts` -- `useAdminTrainers(search, active)` query, `useImpersonateTrainer()` mutation, `useEndImpersonation()` mutation
4. `web/src/hooks/use-admin-subscriptions.ts` -- `useAdminSubscriptions(filters)` query, `useAdminSubscription(id)` query, `useChangeTier()` mutation, `useChangeStatus()` mutation, `useRecordPayment()` mutation, `useUpdateNotes()` mutation, `usePaymentHistory(id)` query, `useChangeHistory(id)` query, `usePastDueSubscriptions()` query
5. `web/src/hooks/use-admin-tiers.ts` -- `useAdminTiers()` query, `useCreateTier()` mutation, `useUpdateTier()` mutation, `useDeleteTier()` mutation, `useToggleTierActive()` mutation, `useSeedDefaultTiers()` mutation
6. `web/src/hooks/use-admin-coupons.ts` -- `useAdminCoupons(filters)` query, `useAdminCoupon(id)` query, `useCreateCoupon()` mutation, `useUpdateCoupon()` mutation, `useDeleteCoupon()` mutation, `useRevokeCoupon()` mutation, `useReactivateCoupon()` mutation, `useCouponUsages(id)` query
7. `web/src/hooks/use-admin-users.ts` -- `useAdminUsers(role, search)` query, `useAdminUser(id)` query, `useCreateAdminUser()` mutation, `useUpdateAdminUser()` mutation, `useDeleteAdminUser()` mutation

**Layout & Navigation:**
8. `web/src/app/(admin-dashboard)/layout.tsx` -- Admin layout with admin-specific sidebar, header, impersonation banner, auth guard for ADMIN role
9. `web/src/app/(admin-dashboard)/admin/page.tsx` -- Admin dashboard overview page
10. `web/src/components/layout/admin-sidebar.tsx` -- Admin sidebar with nav links: Dashboard, Trainers, Subscriptions, Tiers, Coupons, Users, Settings
11. `web/src/components/layout/admin-nav-links.ts` -- Admin nav link definitions (LayoutDashboard, Users, CreditCard, Layers, Ticket, UserCog, Settings icons)
12. `web/src/components/layout/impersonation-banner.tsx` -- Amber banner component for impersonation mode, reads from sessionStorage, shows "Viewing as [trainer email]" with "End" button

**Admin Dashboard Page:**
13. `web/src/app/(admin-dashboard)/admin/page.tsx` -- Dashboard overview (stat cards, tier breakdown, past due alerts)
14. `web/src/components/admin/dashboard-stats.tsx` -- 4 primary stat cards (trainers, trainees, MRR) using StatCard
15. `web/src/components/admin/revenue-cards.tsx` -- Payment/past due stat cards section
16. `web/src/components/admin/tier-breakdown.tsx` -- Tier distribution chart or card list
17. `web/src/components/admin/past-due-alerts.tsx` -- List of past due subscriptions with quick actions

**Trainer Management Pages:**
18. `web/src/app/(admin-dashboard)/admin/trainers/page.tsx` -- Trainer list page
19. `web/src/app/(admin-dashboard)/admin/trainers/[id]/page.tsx` -- Trainer detail page
20. `web/src/components/admin/trainer-table.tsx` -- Trainer DataTable with columns
21. `web/src/components/admin/trainer-columns.tsx` -- Column definitions for trainer table
22. `web/src/components/admin/trainer-detail.tsx` -- Trainer detail view with subscription info and actions
23. `web/src/components/admin/impersonate-dialog.tsx` -- Confirmation dialog for impersonation

**Subscription Management Pages:**
24. `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx` -- Subscription list page with filters
25. `web/src/app/(admin-dashboard)/admin/subscriptions/[id]/page.tsx` -- Subscription detail page with tabs
26. `web/src/components/admin/subscription-table.tsx` -- Subscription DataTable
27. `web/src/components/admin/subscription-columns.tsx` -- Column definitions
28. `web/src/components/admin/subscription-detail.tsx` -- Detail view with tabs (Overview, Payments, Changes)
29. `web/src/components/admin/change-tier-dialog.tsx` -- Dialog for changing subscription tier
30. `web/src/components/admin/change-status-dialog.tsx` -- Dialog for changing subscription status
31. `web/src/components/admin/record-payment-dialog.tsx` -- Dialog for recording manual payment
32. `web/src/components/admin/subscription-filters.tsx` -- Filter bar with status, tier, past due, upcoming dropdowns

**Tier Management Pages:**
33. `web/src/app/(admin-dashboard)/admin/tiers/page.tsx` -- Tier list page
34. `web/src/components/admin/tier-table.tsx` -- Tier DataTable
35. `web/src/components/admin/tier-columns.tsx` -- Column definitions
36. `web/src/components/admin/create-tier-dialog.tsx` -- Create/edit tier form dialog with Zod validation
37. `web/src/components/admin/tier-features-input.tsx` -- Tag/chip input for tier features array

**Coupon Management Pages:**
38. `web/src/app/(admin-dashboard)/admin/coupons/page.tsx` -- Coupon list page with filters
39. `web/src/app/(admin-dashboard)/admin/coupons/[id]/page.tsx` -- Coupon detail page with usages
40. `web/src/components/admin/coupon-table.tsx` -- Coupon DataTable
41. `web/src/components/admin/coupon-columns.tsx` -- Column definitions
42. `web/src/components/admin/create-coupon-dialog.tsx` -- Create coupon form dialog with Zod validation
43. `web/src/components/admin/edit-coupon-dialog.tsx` -- Edit coupon form dialog
44. `web/src/components/admin/coupon-detail.tsx` -- Coupon detail with usages table
45. `web/src/components/admin/coupon-filters.tsx` -- Filter bar with status, type, applies_to dropdowns

**User Management Pages:**
46. `web/src/app/(admin-dashboard)/admin/users/page.tsx` -- User list page
47. `web/src/components/admin/user-table.tsx` -- User DataTable
48. `web/src/components/admin/user-columns.tsx` -- Column definitions
49. `web/src/components/admin/create-user-dialog.tsx` -- Create admin/trainer form dialog
50. `web/src/components/admin/edit-user-dialog.tsx` -- Edit user form dialog

### Files to Modify

1. `web/src/providers/auth-provider.tsx` -- Change role check from `userData.role !== UserRole.TRAINER` to allow both ADMIN and TRAINER roles. Redirect ADMIN to `/admin`, TRAINER to `/dashboard`.
2. `web/src/middleware.ts` -- Add `/admin` routes to protected paths. Add role-aware redirect logic: root `/` redirects ADMIN to `/admin`, TRAINER to `/dashboard`. Note: middleware cannot check role (no token access), so redirect logic happens client-side in AuthProvider and layouts.
3. `web/src/lib/constants.ts` -- Add all admin API URL constants under a new `ADMIN_API_URLS` section: ADMIN_DASHBOARD, ADMIN_TRAINERS, ADMIN_USERS, ADMIN_SUBSCRIPTIONS, ADMIN_TIERS, ADMIN_COUPONS, ADMIN_IMPERSONATE, ADMIN_PAST_DUE, ADMIN_UPCOMING_PAYMENTS, plus dynamic URL functions for detail/action endpoints.
4. `web/src/types/user.ts` -- Already has ADMIN in UserRole enum (no change needed, just confirming).
5. `web/src/lib/error-utils.ts` -- May need to extend `getErrorMessage()` to handle admin-specific error shapes (e.g., `{error: "..."}` format used by admin views alongside DRF field-level errors).
6. `web/src/app/page.tsx` -- Update root redirect to be role-aware (admin -> /admin, trainer -> /dashboard).

### Key Design Decisions

- **Separate route group:** Admin pages live under `(admin-dashboard)/admin/` route group with its own layout, completely isolated from the trainer `(dashboard)` routes. This prevents nav confusion and allows independent layouts.
- **Shared components:** Reuse DataTable, StatCard, EmptyState, ErrorState, LoadingSpinner, PageHeader, Badge, and all shadcn/ui primitives. No duplication.
- **Admin sidebar:** New component with admin-specific nav links. Reuses the same visual pattern as the trainer sidebar (256px width, same styling tokens) but with different links.
- **Impersonation flow:** Admin tokens stored in sessionStorage (not localStorage -- lost on tab close for safety). On impersonate: store admin tokens, set trainer tokens via setTokens(), redirect to trainer dashboard. On end: restore admin tokens, redirect to admin dashboard.
- **Inline vs page detail:** Trainers, subscriptions, and coupons get dedicated detail pages (enough data to warrant a full page). Tiers and users use dialog-based editing (simpler data models).
- **React Query patterns:** Follow existing hook patterns (staleTime: 5 minutes, queryKey conventions). Mutations invalidate related queries on success. Optimistic updates for toggle-active on tiers.
- **Zod validation:** All create/edit forms use Zod schemas matching backend validation rules. Errors shown inline using `aria-invalid` and `aria-describedby` patterns (matching existing settings page).
- **Error message parsing:** Admin backend uses both `{error: "..."}` (custom views) and DRF field-level errors (`{field: ["error"]}`) -- the `getErrorMessage()` utility handles both.
- **No backend changes needed:** All admin APIs already exist and are tested. This is a pure frontend feature.

### Dependencies
- All shadcn/ui components already installed (Dialog, Tabs, Select, Input, Button, Card, Badge, Toast, DropdownMenu, Tooltip, Skeleton)
- React Query v5 already configured
- Zod v4 already installed
- recharts already installed (for tier breakdown chart)
- lucide-react already installed (for icons)
- next-themes already installed (for dark mode)
- apiClient already supports GET/POST/PATCH/DELETE/postFormData

## Out of Scope
- Platform-wide analytics page with revenue trends over time (would need new backend endpoints for time-series data)
- Ambassador management from admin web dashboard (already available on mobile)
- Real-time updates via WebSocket/SSE (would need backend infrastructure)
- Bulk operations (e.g., suspend all past-due trainers, bulk tier change)
- Export to CSV/PDF for financial reports
- Admin settings page (notification preferences, platform config)
- Audit log page (all admin actions across the platform)
- Admin dark mode toggle (inherits from existing theme system)

# Code Review: Web Admin Dashboard

## Review Date: 2026-02-15

## Files Reviewed

**Types & Hooks:**
1. `web/src/types/admin.ts`
2. `web/src/hooks/use-admin-dashboard.ts`
3. `web/src/hooks/use-admin-trainers.ts`
4. `web/src/hooks/use-admin-tiers.ts`
5. `web/src/hooks/use-admin-coupons.ts`
6. `web/src/hooks/use-admin-subscriptions.ts`
7. `web/src/hooks/use-admin-users.ts`

**Auth & Layout:**
8. `web/src/providers/auth-provider.tsx`
9. `web/src/middleware.ts`
10. `web/src/app/(admin-dashboard)/layout.tsx`
11. `web/src/components/layout/admin-nav-links.ts`
12. `web/src/components/layout/admin-sidebar.tsx`
13. `web/src/components/layout/admin-sidebar-mobile.tsx`
14. `web/src/components/layout/impersonation-banner.tsx`
15. `web/src/components/layout/user-nav.tsx`

**Pages:**
16. `web/src/app/(admin-dashboard)/admin/dashboard/page.tsx`
17. `web/src/app/(admin-dashboard)/admin/trainers/page.tsx`
18. `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`
19. `web/src/app/(admin-dashboard)/admin/tiers/page.tsx`
20. `web/src/app/(admin-dashboard)/admin/coupons/page.tsx`
21. `web/src/app/(admin-dashboard)/admin/users/page.tsx`
22. `web/src/app/(admin-dashboard)/admin/settings/page.tsx`
23. `web/src/app/(auth)/login/page.tsx`
24. `web/src/app/(dashboard)/layout.tsx`

**Components:**
25. `web/src/components/admin/dashboard-stats.tsx`
26. `web/src/components/admin/revenue-cards.tsx`
27. `web/src/components/admin/tier-breakdown.tsx`
28. `web/src/components/admin/past-due-alerts.tsx`
29. `web/src/components/admin/admin-dashboard-skeleton.tsx`
30. `web/src/components/admin/trainer-list.tsx`
31. `web/src/components/admin/trainer-detail-dialog.tsx`
32. `web/src/components/admin/subscription-list.tsx`
33. `web/src/components/admin/subscription-detail-dialog.tsx`
34. `web/src/components/admin/tier-list.tsx`
35. `web/src/components/admin/tier-form-dialog.tsx`
36. `web/src/components/admin/coupon-list.tsx`
37. `web/src/components/admin/coupon-form-dialog.tsx`
38. `web/src/components/admin/coupon-detail-dialog.tsx`
39. `web/src/components/admin/user-list.tsx`
40. `web/src/components/admin/create-user-dialog.tsx`

**Supporting:**
41. `web/src/lib/constants.ts`
42. `web/src/lib/error-utils.ts`
43. `web/src/lib/api-client.ts`
44. `web/src/lib/token-manager.ts`

**Backend cross-reference:**
- `backend/subscriptions/views/admin_views.py` (permission classes, URL patterns)
- `backend/subscriptions/urls.py` (URL routing)
- `backend/config/urls.py` (top-level routing)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `web/src/middleware.ts:13-15, 24-25` | **Middleware redirects authenticated admins to `/dashboard` (trainer route) instead of admin dashboard.** When an admin visits `/login` with a valid session cookie, line 14 redirects to `/dashboard`. When an admin visits `/` with a session, line 25 also redirects to `/dashboard`. The admin lands on the trainer layout, which then fires a client-side redirect to `/admin/dashboard` (via `useEffect` in `(dashboard)/layout.tsx:28-32`). This causes a visible flash: admin sees the trainer loading spinner, then gets bounced to admin dashboard. More critically, if the `(dashboard)/layout.tsx` role guard has any timing issue or if the network is slow, the admin briefly sees the trainer dashboard content. **The middleware should be role-aware, but since it cannot read JWT claims (only the session cookie), the proper fix is to redirect to a neutral route that the client-side layout handles, OR store the user role in a separate cookie during login.** | The simplest fix: store `user_role` as a cookie alongside `has_session` in `token-manager.ts:setTokens()` -- add a `role` parameter. Then in middleware, read the role cookie and redirect to `/admin/dashboard` for admins, `/dashboard` for trainers. This eliminates the double-redirect flash. Alternatively, redirect both to `/` and let `page.tsx` handle role-based routing client-side (less ideal but acceptable). |
| C2 | `web/src/components/admin/coupon-form-dialog.tsx:112` | **Create coupon sends `applicable_tiers: []` always, ignoring ticket AC-35.** The ticket requires `applicable_tiers` multi-select to restrict which tiers the coupon applies to. The form dialog has no UI for selecting applicable tiers. The payload hardcodes `applicable_tiers: []` (empty array). If the backend interprets empty as "no tiers" (i.e., coupon applies to nothing), every created coupon will be non-functional for all tiers. If backend interprets empty as "all tiers," the admin loses the ability to restrict coupons to specific tiers. | Add a multi-select field for `applicable_tiers`. Use a set of checkboxes (one per tier: FREE, STARTER, PRO, ENTERPRISE) or a multi-select dropdown. Wire it into state and include it in both create and update payloads. The `UpdateCouponPayload` type already includes `applicable_tiers?: string[]`, so the update path just needs the UI. |
| C3 | `web/src/app/(admin-dashboard)/admin/coupons/page.tsx:65-71` | **"Edit from detail" opens create form instead of edit form -- overwrites coupon with blank data.** `handleEditFromDetail()` sets `setEditingCoupon(null)` and opens the form dialog. Because `coupon` is `null`, the form renders in create mode (all fields blank). If the admin fills it out and submits, a NEW coupon is created instead of updating the existing one. The comment on line 68 acknowledges this: "We don't have the full coupon data from the list item, so we open the form with null to trigger a create-style edit." This is a UX-breaking bug: the admin clicks "Edit" on an existing coupon and gets a create form. | Pass the fetched coupon data from the detail dialog to the parent. The detail dialog already has `useAdminCoupon(couponId)` which returns the full `AdminCoupon` object. Change `onEdit: () => void` to `onEdit: (coupon: AdminCoupon) => void` in `CouponDetailDialogProps`. In the detail dialog, call `onEdit(data)` instead of `onEdit()`. In `handleEditFromDetail`, receive the coupon: `function handleEditFromDetail(coupon: AdminCoupon) { setDetailOpen(false); setEditingCoupon(coupon); setFormOpen(true); }`. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `web/src/components/admin/subscription-detail-dialog.tsx:126-135` | **Action form state (`reason`, `newTier`, `newStatus`, etc.) leaks between actions.** If the admin clicks "Change Tier", types a reason, then clicks Cancel, and then clicks "Change Status", the `reason` state still contains the text from the tier change. The `resetAction()` function at line 139 resets `reason` to empty, but it is only called on Cancel and after successful submit. If the admin cancels via `setActionMode("none")` without going through `resetAction` (line 519 -- the Notes cancel button calls `setActionMode("none")` directly instead of `resetAction`), state bleeds. | Make all "Cancel" buttons consistently call `resetAction()`. The notes cancel at line 519 should call `resetAction()` instead of `setActionMode("none")`. Also, reset all form state when opening a NEW action mode by adding a reset at the top of each action button's `onClick`. |
| M2 | `web/src/components/admin/subscription-detail-dialog.tsx:1-583` | **Component is 583 lines -- far exceeds the 150-line convention.** This single file contains the dialog shell, overview tab with 4 inline action forms (tier/status/payment/notes), the payments tab, the changes tab, column definitions for 2 DataTables, and 7 handler functions. The file is difficult to scan, and changes to one action form risk breaking another. | Extract into at least 4 sub-components: `SubscriptionOverviewTab`, `SubscriptionPaymentsTab`, `SubscriptionChangesTab`, and separate action form components (`ChangeTierForm`, `ChangeStatusForm`, `RecordPaymentForm`, `AdminNotesForm`). |
| M3 | `web/src/components/admin/tier-form-dialog.tsx:36-51` | **Form state initialized via `useState(tier?.x ?? default)` is stale after dialog reuse without key change.** The `TierFormDialog` uses `key={editingTier?.id ?? "new"}` at the call site, which correctly forces remount when switching between tiers. However, if the admin: (1) creates tier A, (2) creates tier B (key is `"new"` both times), the form state from tier A persists because the key did not change. The user sees pre-filled fields from the previous creation. | After successful creation in `handleSubmit`, explicitly reset all state fields (or rely on the key changing). Since the key is `"new"` for both creates, the fix is to change the key to include a counter or timestamp: `key={editingTier?.id ?? \`new-${formOpen}\`}`. When `formOpen` toggles from `false` to `true`, the key changes, forcing remount. Alternatively, use `key={editingTier?.id ?? (formOpen ? "new" : "closed")}`. |
| M4 | `web/src/components/admin/create-user-dialog.tsx:95` | **Update user payload typed as `Record<string, unknown>` bypasses TypeScript safety.** The `UpdateUserPayload` type is correctly defined in `types/admin.ts`, but line 95 builds `const payload: Record<string, unknown> = { ... }` instead of using it. This means the compiler cannot verify that the payload matches the expected shape. If someone misspells a field name (e.g., `firstname` instead of `first_name`), TypeScript will not catch it. | Type the payload as `UpdateUserPayload`: `const payload: UpdateUserPayload = { first_name: firstName.trim(), last_name: lastName.trim(), is_active: isActive, role }; if (password) payload.password = password;`. Since `password` is optional in `UpdateUserPayload`, this works correctly. |
| M5 | `web/src/components/admin/dashboard-stats.tsx:11-18` and `web/src/components/admin/revenue-cards.tsx:16-23` and `web/src/components/admin/past-due-alerts.tsx:16-23` | **`formatCurrency` utility function duplicated 3 times across admin components.** Identical implementation in `dashboard-stats.tsx:11`, `revenue-cards.tsx:16`, `past-due-alerts.tsx:16`, `subscription-list.tsx:30`, `subscription-detail-dialog.tsx:40`, and `trainer-detail-dialog.tsx:34`. Six copies of the same function. If the currency formatting needs to change (e.g., to support multi-currency), six files must be updated. | Extract to `web/src/lib/format-utils.ts` as `export function formatCurrency(value: string): string { ... }` and import everywhere. |
| M6 | `web/src/components/admin/trainer-list.tsx:14-20` and `web/src/components/admin/subscription-list.tsx:22-28` and `web/src/components/admin/tier-breakdown.tsx:16-22` | **`TIER_COLORS` mapping duplicated 3 times.** Three components define the same `Record<string, string>` mapping tier names to Tailwind classes. If a new tier is added (or colors are adjusted for dark mode), all three must be updated simultaneously. | Extract to a shared constant file: `web/src/lib/tier-colors.ts` or `web/src/components/admin/constants.ts`. |
| M7 | `web/src/components/admin/coupon-form-dialog.tsx:70-88` | **Coupon form validation is incomplete -- missing validation for negative `maxUses` and `maxUsesPerUser`.** The form validates code format and discount value, but `maxUses` and `maxUsesPerUser` are parsed with `parseInt(maxUses, 10) || 0` and `parseInt(maxUsesPerUser, 10) || 1` respectively. If the admin enters `-5` for max uses, `parseInt("-5")` returns `-5`, which is truthy (not `|| 0`), so `-5` is sent to the backend. While the backend may reject this, the frontend should validate. Similarly, `maxUsesPerUser` of `0` would fallback to `1` due to `|| 1`, which silently overrides the user's input. | Add validation in `validate()`: `const maxUsesNum = parseInt(maxUses, 10); if (isNaN(maxUsesNum) || maxUsesNum < 0) newErrors.max_uses = "Must be 0 or greater";`. Same for `maxUsesPerUser` but with minimum 1. |
| M8 | `web/src/hooks/use-admin-trainers.ts:50-69` | **`useActivateDeactivateTrainer` mutation does not invalidate the specific subscription detail query.** When the admin suspends/activates a trainer via the trainer detail dialog, the mutation invalidates `["admin", "trainers"]` and `["admin", "dashboard"]` but NOT `["admin", "subscriptions"]`. If the admin had the subscriptions page open in another tab or navigates there next, the subscription status may be stale (still showing "active" when the trainer was just suspended). | Add `queryClient.invalidateQueries({ queryKey: ["admin", "subscriptions"] })` to the `onSuccess` callback. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `web/src/hooks/*.ts` | `"use client"` directive on all 6 hook files is unnecessary. Hooks are not components and inherit their render context from the calling component. | Remove `"use client"` from all hook files. Not harmful but noisy. |
| m2 | `web/src/components/admin/subscription-detail-dialog.tsx:94-98`, `subscription-list.tsx:66-68` | `row.status.replace("_", " ")` only replaces the FIRST underscore. The status `"past_due"` renders as `"past due"` (correct), but a hypothetical future status like `"pending_payment_review"` would render as `"pending payment_review"`. | Use `.replaceAll("_", " ")` or `.replace(/_/g, " ")`. |
| m3 | `web/src/app/(admin-dashboard)/admin/coupons/page.tsx:94-117` | Native `<select>` elements used for status and type filters instead of shadcn `Select` component. This is inconsistent with the rest of the UI and does not respect the shadcn theme in dark mode (native selects have opaque dropdown backgrounds). Same issue in subscriptions page (lines 79-102), users page (lines 72-83), coupon form dialog (lines 184-212), create user dialog (lines 204-215), and subscription detail dialog (lines 346-405). | Replace native `<select>` with shadcn `Select` component (`<Select><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>...</SelectContent></Select>`). |
| m4 | `web/src/components/admin/tier-form-dialog.tsx:290-299` | Native `<input type="checkbox">` used instead of shadcn `Checkbox` component. Same issue in `create-user-dialog.tsx:241-251`. Checkbox does not match the shadcn design system. | Replace with shadcn `Checkbox` component: `<Checkbox id="tier-active" checked={isActive} onCheckedChange={setIsActive} />`. |
| m5 | `web/src/components/admin/tier-form-dialog.tsx:86-93` | `name.toUpperCase().trim()` auto-uppercases the tier name on submit. This is correct for the `name` field (which is a slug-like identifier), but the behavior is not communicated to the user. If the admin types "Pro", the form submits "PRO" -- potentially confusing. | Add helper text below the name input: `"Will be auto-uppercased (e.g., PRO)"` or transform the input value in real-time: `onChange={(e) => setName(e.target.value.toUpperCase())}`. |
| m6 | `web/src/components/admin/past-due-alerts.tsx:98-103` | "View All" link only appears when `items.length > 5`. If there are exactly 5 past-due items, there is no link to the subscriptions page. The admin sees 5 items and has no way to navigate to the full filtered view. The threshold should be `>= 1` for the "View All" link (always show it when there are any past-due items), or at minimum `>= 5` (show when displaying all items). | Change `items.length > 5` to `items.length > 0` -- always show "View All" when there are past-due items. The link provides quick navigation even when all items fit. |
| m7 | `web/src/components/admin/coupon-detail-dialog.tsx:216-244` | The reactivate button is wrapped in a `Tooltip` that only shows content when `data.status === "exhausted"`. For revoked coupons, the tooltip wrapper exists but has no content, which may cause a layout shift or empty tooltip flash on hover in some Radix versions. | Move the tooltip wrapper inside the exhausted condition: `{data.status === "exhausted" ? (<Tooltip>...</Tooltip>) : (<Button onClick={handleReactivate} disabled={reactivate.isPending}>...</Button>)}`. |
| m8 | `web/src/components/admin/subscription-detail-dialog.tsx:484-494` | The admin notes textarea uses inline className that replicates the shadcn Textarea styles. If shadcn Textarea styles are updated, this textarea will become visually inconsistent. | Use the shadcn `Textarea` component. |
| m9 | `web/src/components/admin/create-user-dialog.tsx:51` | Password strength indicator uses hardcoded color classes (`text-destructive`, `text-amber-500`, `text-blue-500`, `text-green-500`). `text-amber-500`, `text-blue-500`, and `text-green-500` are not theme-aware -- they will not adjust in dark mode. | Use theme tokens: `text-destructive` (already correct), `text-warning` or a CSS custom property for amber, and the theme's success color. Alternatively, use shadcn Badge variants for the strength indicator. |
| m10 | `web/src/components/admin/trainer-detail-dialog.tsx:58-82` | `handleImpersonate` reads tokens synchronously via `getAccessToken()` / `getRefreshToken()` -- these read from `localStorage`. If `localStorage` is full or unavailable (incognito in some old browsers), they return `null` and the error message is generic ("Cannot impersonate: no active session"). This is minor but could confuse debugging. | The current error handling is adequate. Just noting for awareness. No action needed. |
| m11 | All pages | No page-level `<title>` or metadata for admin routes. Next.js App Router supports `export const metadata` or `generateMetadata()`. Without it, all admin pages show the same browser tab title, making it hard to distinguish tabs. | Add `export const metadata = { title: "Trainers - Admin" }` (or equivalent) to each page file. Note: since pages are `"use client"`, metadata must be set differently -- either via a `head.tsx` file in each route segment, or by using `useEffect` to set `document.title`. |

---

## Security Concerns

1. **Admin-only auth enforcement: PASS.** All backend admin endpoints use `[IsAuthenticated, IsAdminUser]` permission classes. `IsAdminUser` checks `request.user.is_admin()`. The frontend has role guards in both the admin layout (`user.role !== UserRole.ADMIN` redirects) and middleware (session check). A trainer who manually navigates to `/admin/dashboard` is client-side redirected to `/dashboard`, and if they somehow bypass that, all API calls return 403.

2. **Impersonation token storage: ACCEPTABLE.** Admin tokens are stored in `sessionStorage` during impersonation. `sessionStorage` is per-tab and cleared on tab close, which limits exposure. The tokens ARE accessible to XSS attacks within the same tab, but this is an inherent risk of client-side token storage. The impersonation flow correctly restores admin tokens and calls `ADMIN_IMPERSONATE_END` to audit trail the end of impersonation.

3. **No secrets exposed: PASS.** No API keys, passwords, tokens, or credentials in any committed file. `NEXT_PUBLIC_API_URL` is designed to be public. No `.env` files committed.

4. **IDOR prevention: PASS.** All admin API endpoints accept IDs in URLs (e.g., `/api/admin/users/123/`), but the backend enforces admin-only access via `IsAdminUser`. Since only admins can call these endpoints, and admins are authorized to manage all resources, there is no IDOR vulnerability. This is a legitimate admin panel, not a multi-tenant system.

5. **XSS prevention: PASS.** No `dangerouslySetInnerHTML` usage. All user-generated content (trainer names, emails, coupon codes, notes) is rendered via React JSX which auto-escapes. Admin notes textarea input is bounded at 2000 characters with `maxLength`.

6. **CSRF: N/A.** JWT Bearer token auth, not session cookies.

7. **`AdminEndImpersonationView` uses `[IsAuthenticated]` only, not `[IsAuthenticated, IsAdminUser]`.** This is CORRECT behavior: after impersonation, the request comes from the trainer's JWT tokens (since the frontend swapped them), so the admin permission check would fail. The endpoint just audits and returns. No security issue.

---

## Performance Concerns

1. **No pagination on any admin list endpoint.** `useAdminTrainers`, `useAdminSubscriptions`, `useAdminCoupons`, `useAdminUsers`, `useAdminTiers` all fetch arrays without pagination. If the platform scales to 500+ trainers, the trainers list fetches ALL trainers in one request. The DataTable component supports pagination (`totalCount`, `page`, `pageSize` props) but none of the admin hooks use it. For now (early-stage platform), this is acceptable. Should be addressed before scaling past ~200 trainers.

2. **Dashboard makes 2 parallel API calls.** `useAdminDashboard()` and `usePastDueSubscriptions()` fire simultaneously. The dashboard endpoint likely already computes past-due data internally (it returns `past_due_count`). The separate `usePastDueSubscriptions()` call in `PastDueAlerts` duplicates work. Consider including the past-due list in the dashboard API response to reduce to 1 call.

3. **Subscription detail dialog fires 3 queries simultaneously.** `useAdminSubscription(id)`, `usePaymentHistory(id)`, and `useChangeHistory(id)` all fire when the dialog opens. The subscription detail API already returns `recent_payments` and `recent_changes` in the response. The separate payment/change history hooks are redundant for the initial render. They could be used for pagination or "load all" but currently they just duplicate what the detail endpoint returns.

4. **`formatCurrency` called on every render.** Six components call `formatCurrency` in render paths without memoization. `Intl.NumberFormat` constructor is relatively expensive. Consider caching the formatter instance at module level: `const currencyFormatter = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });` and calling `currencyFormatter.format(num)`.

---

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | `AuthProvider.fetchUser()` accepts both `ADMIN` and `TRAINER` roles (line 41-43) |
| AC-2 | PASS | Middleware allows admin routes under `/admin/` for authenticated sessions |
| AC-3 | PASS | Admin sidebar shown in `(admin-dashboard)/layout.tsx`; trainer sidebar in `(dashboard)/layout.tsx` |
| AC-4 | PASS | Separate `(admin-dashboard)` route group with own layout at `/admin/*` |
| AC-5 | PASS | Admin layout redirects non-admins to `/dashboard`; Dashboard layout redirects admins to `/admin/dashboard` |
| AC-6 | PASS | 4 stat cards: Total Trainers, Active Trainers, Total Trainees, MRR |
| AC-7 | PASS | Revenue & Payments section with Past Due, Due Today, This Week, This Month |
| AC-8 | PASS | Tier Breakdown with horizontal progress bars per tier |
| AC-9 | PASS | Past Due Alerts section with trainer name, email, amount, days past due, "View All" link |
| AC-10 | PASS | Warning badge in PageHeader when `past_due_count > 0` |
| AC-11 | PASS | Trainer DataTable with Name, Email (sub-text), Status badge, Tier badge, Trainees, Joined |
| AC-12 | PASS | Search with 300ms debounce via `useDebounce` |
| AC-13 | PASS | Active/Inactive/All toggle buttons |
| AC-14 | PARTIAL | Clicking trainer row opens detail DIALOG, not page at `/admin/trainers/[id]`. Ticket says "navigates to trainer detail view at `/admin/trainers/[id]`" (AC-14). Dialog approach is acceptable UX but deviates from the ticket's URL-based navigation. |
| AC-15 | PASS | Trainer detail dialog shows profile, subscription, trainee count, action buttons |
| AC-16 | PASS | Impersonate stores admin tokens in sessionStorage, sets trainer tokens, redirects to `/dashboard` |
| AC-17 | PASS | End impersonation restores admin tokens, calls end endpoint, redirects to `/admin/trainers` |
| AC-18 | PASS | Activate/Suspend toggle with confirmation dialog for suspend |
| AC-19 | PASS | Subscription DataTable with Trainer, Tier, Status, Price, Next Payment, Past Due |
| AC-20 | PARTIAL | Status and tier dropdown filters present. Past due toggle is implemented via status=`past_due` filter. Search by email present. Missing: upcoming payments filter (7/14/30 days) -- `upcoming_days` is defined in `SubscriptionFilters` interface but no UI dropdown exposes it. |
| AC-21 | PARTIAL | Clicking subscription row opens detail DIALOG, not page at `/admin/subscriptions/[id]`. Same deviation as AC-14. |
| AC-22 | PASS | Tabbed detail with Overview (all fields, notes), Payments (table), Changes (audit log) |
| AC-23 | PASS | Change Tier inline form with tier dropdown and reason |
| AC-24 | PASS | Change Status inline form with status dropdown and reason |
| AC-25 | PASS | Record Payment inline form with amount and description |
| AC-26 | PASS | Admin notes inline-editable with 2000 char limit and counter |
| AC-27 | PASS | Tier DataTable with Name, Price, Trainee Limit, Active toggle, Order, Actions |
| AC-28 | PASS | Create Tier form dialog with all required fields |
| AC-29 | PASS | Edit tier via same form dialog with `PATCH` |
| AC-30 | PASS | Toggle Active with optimistic update and rollback |
| AC-31 | PASS | Delete tier with confirmation dialog; error displayed inline if backend rejects |
| AC-32 | PASS | Seed Defaults button shown only on empty state |
| AC-33 | PASS | Coupon DataTable with Code, Type, Discount, Applies To, Status, Usage, Valid Until |
| AC-34 | PASS | Status dropdown, type dropdown, search by code. Missing: `applies_to` filter dropdown. |
| AC-35 | FAIL | **`applicable_tiers` multi-select missing from create form (C2).** |
| AC-36 | PARTIAL | Clicking coupon opens DETAIL DIALOG, not page at `/admin/coupons/[id]`. Same dialog-vs-page deviation. |
| AC-37 | PASS | Coupon detail shows all fields plus Usages table |
| AC-38 | PASS | Revoke action with status update |
| AC-39 | PASS | Reactivate button shown for revoked coupons, disabled for exhausted with tooltip |
| AC-40 | FAIL | **Edit from detail opens CREATE form (C3).** Also missing `applicable_tiers` in edit (C2). |
| AC-41 | PASS | User DataTable with Name, Email, Role, Status, Trainees, Created |
| AC-42 | PASS | Role filter and search by name/email |
| AC-43 | PASS | Create User form with email, password (strength indicator), role, first/last name |
| AC-44 | PARTIAL | User detail via dialog (not inline expand). Supports editing first_name, last_name, is_active, role, password. |
| AC-45 | PASS | Delete user with confirmation, error shown in dialog if backend rejects |
| AC-46 | PASS | Skeleton tables on all list pages, Loader2 on mutation buttons |
| AC-47 | PASS | Contextual empty states with appropriate icons and CTAs on all pages |
| AC-48 | PASS | ErrorState with retry on all list pages, toast on mutation failures |
| AC-49 | PASS | Toast on all create/update/delete/action operations |

**Summary:** 2 FAIL, 5 PARTIAL, 42 PASS (out of 49 ACs)

---

## Edge Case Verification

| Edge Case | Status | Notes |
|-----------|--------|-------|
| 1. Admin logs in with no trainers | PASS | Dashboard stats show 0, empty tier breakdown, empty past-due |
| 2. Impersonate then refresh | PASS | `sessionStorage` persists, banner re-renders from stored data |
| 3. Admin deactivates themselves | PASS | Backend rejects, frontend shows error toast via `getErrorMessage` |
| 4. Admin deletes themselves | PASS | Backend rejects, frontend shows error in dialog |
| 5. Delete trainer with trainees | PASS | Backend error displayed in create-user dialog's delete section |
| 6. Tier delete with subscriptions | PASS | Error shown inline in delete confirmation dialog |
| 7. Reactivate exhausted coupon | PASS | Button disabled with tooltip explanation |
| 8. Coupon code uppercase/spaces | PASS | `code.toUpperCase().replace(/\s/g, "")` in real-time and on submit |
| 9. Percent discount > 100% | PASS | Zod-style validation rejects with inline error |
| 10. MRR with all free trainers | PASS | `formatCurrency("0.00")` returns `$0.00` |
| 11. Negative/zero payment amount | PASS | Validated in `handleRecordPayment` before submission |
| 12. Change tier to same tier | PASS | Backend rejects, toast shows error |
| 13. Concurrent admin edits | N/A | Last-write-wins (no optimistic locking), acceptable |
| 14. Session expiry during impersonation | PASS | 401 triggers token refresh; if refresh fails, redirects to login. `sessionStorage` is cleared on tab close. |
| 15. Very long admin notes | PASS | `maxLength={2000}`, character counter displayed |

---

## Quality Score: 7/10

### Breakdown:
- **Correctness: 7/10** -- 3 critical/major bugs (C2 missing applicable_tiers, C3 edit-from-detail broken, M1 state leakage). Everything else works correctly. No enum mismatches like the previous pipeline.
- **Architecture: 8/10** -- Clean separation of hooks, types, components, and pages. Proper use of React Query with query key conventions. Route group isolation is excellent. Subscription detail dialog is too large (M2).
- **Type Safety: 8/10** -- Types are well-defined and match the backend API shape. One payload uses `Record<string, unknown>` (M4) instead of the proper type. All other payloads are properly typed.
- **Accessibility: 9/10** -- Excellent ARIA usage: `aria-label` on all interactive elements, `aria-hidden` on decorative icons, `sr-only` for screen readers, `aria-invalid` and `aria-describedby` on form fields, `aria-current="page"` on nav links, `role="status"` on loading states, `role="alert"` on errors, `role="progressbar"` on tier breakdown bars, skip-to-content link in layout, keyboard navigation on table rows via DataTable.
- **UX States: 9/10** -- Loading skeletons, empty states, error states with retry, success toasts, and Loader2 spinners on every mutation button. Dashboard has dedicated skeleton component. Every page handles all 3 states correctly.
- **Error Handling: 8/10** -- All mutations use `try/catch` with `getErrorMessage` + `toast.error`. Delete dialogs show inline errors. `getErrorMessage` handles both DRF field errors and generic `{error: "..."}` responses. Minor gap: coupon validation (M7).
- **Performance: 7/10** -- No pagination on list queries (acceptable at current scale). Duplicate API calls for dashboard + past-due. `formatCurrency` duplication. No excessive re-render issues given component sizes.
- **Code Organization: 7/10** -- 6 duplicated `formatCurrency` functions (M5), 3 duplicated `TIER_COLORS` mappings (M6), native `<select>` instead of shadcn Select (m3), native checkbox instead of shadcn Checkbox (m4). These are quality issues, not correctness issues.

### Strengths:
- Comprehensive implementation covering all 6 admin pages with full CRUD
- Excellent accessibility -- one of the best I have reviewed
- Proper optimistic update for tier toggle with rollback
- Impersonation flow is well-designed (sessionStorage, hard navigation for cache clearing, audit trail)
- Role-based routing with guards at both layout and middleware levels
- Good use of key-based form remounting for dialog reuse
- Well-structured React Query hooks with proper cache invalidation chains

### Weaknesses:
- Missing `applicable_tiers` multi-select (C2) and broken edit-from-detail (C3)
- Significant code duplication (formatCurrency, TIER_COLORS)
- Subscription detail dialog at 583 lines violates the 150-line convention
- Native HTML form elements used instead of shadcn components in several places
- Double-redirect flash for admin login (C1)

---

## Recommendation: REQUEST CHANGES

**Rationale:** The implementation is substantially complete with good quality -- 42 of 49 acceptance criteria pass, accessibility is excellent, and the architecture is clean. However, three issues prevent an APPROVE:

1. **C1 (middleware double-redirect)** causes a visible UX flash for every admin login.
2. **C2 (`applicable_tiers` missing)** means admins cannot restrict coupons to specific tiers, which is a core coupon management feature.
3. **C3 (edit-from-detail broken)** means the "Edit" button on coupon detail creates a new coupon instead of editing the existing one.

These are fixable without significant refactoring.

**Must fix before re-review:**
1. **C1** -- Eliminate admin login double-redirect (store role in cookie or use neutral redirect)
2. **C2** -- Add `applicable_tiers` multi-select to coupon create/edit forms
3. **C3** -- Pass coupon data from detail dialog to edit form
4. **M1** -- Fix state leakage in subscription detail action forms
5. **M2** -- Extract subscription detail dialog into sub-components (150-line rule)
6. **M4** -- Type user update payload properly
7. **M5** -- Extract `formatCurrency` to shared utility
8. **M7** -- Add validation for negative maxUses/maxUsesPerUser

**Nice to fix (not blocking):**
- M3 (tier form stale state on consecutive creates)
- M6 (deduplicate TIER_COLORS)
- M8 (invalidate subscriptions on trainer activate/deactivate)
- m3 (native selects -> shadcn Select)
- m4 (native checkbox -> shadcn Checkbox)

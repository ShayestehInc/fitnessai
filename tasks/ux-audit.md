# UX Audit: Admin Dashboard (Pipeline 13)

## Audit Date: 2026-02-15

## Pages & Components Reviewed
- Admin layout: `web/src/app/(admin-dashboard)/layout.tsx`
- Dashboard page: `web/src/app/(admin-dashboard)/admin/dashboard/page.tsx`
- Trainers page: `web/src/app/(admin-dashboard)/admin/trainers/page.tsx`
- Users page: `web/src/app/(admin-dashboard)/admin/users/page.tsx`
- Tiers page: `web/src/app/(admin-dashboard)/admin/tiers/page.tsx`
- Coupons page: `web/src/app/(admin-dashboard)/admin/coupons/page.tsx`
- Subscriptions page: `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`
- Settings page: `web/src/app/(admin-dashboard)/admin/settings/page.tsx`
- Admin dashboard skeleton: `web/src/components/admin/admin-dashboard-skeleton.tsx`
- Dashboard stats: `web/src/components/admin/dashboard-stats.tsx`
- Revenue cards: `web/src/components/admin/revenue-cards.tsx`
- Past due alerts: `web/src/components/admin/past-due-alerts.tsx`
- Tier breakdown: `web/src/components/admin/tier-breakdown.tsx`
- Tier list: `web/src/components/admin/tier-list.tsx`
- Tier form dialog: `web/src/components/admin/tier-form-dialog.tsx`
- Trainer list: `web/src/components/admin/trainer-list.tsx`
- Trainer detail dialog: `web/src/components/admin/trainer-detail-dialog.tsx`
- User list: `web/src/components/admin/user-list.tsx`
- Create user dialog: `web/src/components/admin/create-user-dialog.tsx`
- Coupon list: `web/src/components/admin/coupon-list.tsx`
- Coupon form dialog: `web/src/components/admin/coupon-form-dialog.tsx`
- Coupon detail dialog: `web/src/components/admin/coupon-detail-dialog.tsx`
- Subscription list: `web/src/components/admin/subscription-list.tsx`
- Subscription detail dialog: `web/src/components/admin/subscription-detail-dialog.tsx`
- Subscription action forms: `web/src/components/admin/subscription-action-forms.tsx`
- Subscription history tabs: `web/src/components/admin/subscription-history-tabs.tsx`
- Admin sidebar: `web/src/components/layout/admin-sidebar.tsx`
- Admin sidebar mobile: `web/src/components/layout/admin-sidebar-mobile.tsx`
- Admin nav links: `web/src/components/layout/admin-nav-links.ts`
- Impersonation banner: `web/src/components/layout/impersonation-banner.tsx`
- Shared components: `page-header.tsx`, `data-table.tsx`, `empty-state.tsx`, `error-state.tsx`, `stat-card.tsx`
- Admin constants: `web/src/lib/admin-constants.ts`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | High | All list pages (Trainers, Users, Tiers, Coupons, Subscriptions) | Loading skeleton `<div>` containers had no `role="status"` or `aria-label`, making loading states invisible to screen readers. Users using assistive technology would not know data was loading. | Added `role="status"` and `aria-label="Loading {resource}..."` to all loading skeleton containers, plus `<span className="sr-only">` for additional context. -- FIXED |
| 2 | High | Past Due Alerts card | No error state when the past-due subscription fetch fails. The component only handled `isLoading` and data states. A network error would show a perpetually empty card with no way to retry. | Added `isError` and `refetch` destructuring from the hook, and an error state with `role="alert"`, descriptive message, and inline "Retry" button. -- FIXED |
| 3 | High | Coupon Detail Dialog | No error state when the coupon detail fetch fails. Only a loading spinner was shown. A failed fetch would leave users staring at an empty dialog indefinitely. | Added `coupon.isError` check with `role="alert"`, "Failed to load coupon details." message, and inline "Retry" button. -- FIXED |
| 4 | High | Subscription Detail Dialog | Same as above. No error state for subscription detail fetch failure. | Added `subscription.isError` check with `role="alert"`, "Failed to load subscription details." message, and inline "Retry" button. -- FIXED |
| 5 | Medium | Subscription List (status column) | Status labels like `past_due` were displayed as "Past due" (only first character capitalized). Multi-word statuses should capitalize each word for readability: "Past Due". | Changed from single `charAt(0).toUpperCase()` to `replace(/\b\w/g, c => c.toUpperCase())` for proper title case on all status values. -- FIXED |
| 6 | Medium | Trainers page (filter buttons) | Filter toggle buttons (All / Active / Inactive) had no `aria-pressed` attribute or grouping `role="group"`, making the current filter state invisible to screen readers. | Added `role="group"` with `aria-label="Filter trainers by status"` to the button container, and `aria-pressed` to each filter button reflecting its active state. -- FIXED |
| 7 | Medium | All native `<select>` elements | Native `<select>` elements across 6 files (filter toolbars, form dialogs, action forms) used inline className strings duplicated in 12+ places. Inconsistency risk was high, and several selects were missing the focus-visible transition class. | Extracted shared `SELECT_CLASSES` and `SELECT_CLASSES_FULL_WIDTH` constants into `web/src/lib/admin-constants.ts`. Replaced all inline select class strings with the shared constant reference. -- FIXED |
| 8 | Medium | Native checkboxes (tier form, user form, coupon form) | Raw `<input type="checkbox">` elements had minimal styling (`h-4 w-4 rounded border-input`) with no `accent-primary` color and no `focus-visible` ring. Keyboard focus was invisible, and the checkbox color did not match the design system primary color. | Added `accent-primary` for consistent color and `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` for keyboard navigation visibility. -- FIXED |
| 9 | Medium | Coupon list, coupon detail dialog | Both components defined local `STATUS_VARIANT` maps identical to the centralized `COUPON_STATUS_VARIANT` in `admin-constants.ts`. This duplication meant changes to status badge colors would need updating in 3 places. | Replaced local `STATUS_VARIANT` with imported `COUPON_STATUS_VARIANT` from `@/lib/admin-constants`. -- FIXED |
| 10 | Medium | Subscription History (change details column) | Change details used `->` ASCII arrow (`FREE -> PRO`) instead of a proper arrow character. The ASCII version is less readable and not screen-reader friendly. | Changed to `&rarr;` HTML entity with `aria-label="changed to"` for screen reader context. -- FIXED |
| 11 | Medium | All dialog loading spinners | Loading spinners in Coupon Detail, Subscription Detail, and Subscription History Tabs lacked `role="status"`, `aria-label`, `aria-hidden="true"` on the icon, and sr-only text. Screen readers would not announce the loading state. | Added `role="status"`, `aria-label`, `aria-hidden="true"` on Loader2 icons, and `<span className="sr-only">` text to all dialog loading indicators. -- FIXED |
| 12 | Low | Tiers page (delete dialog) | Delete confirmation text had `&quot;{name}\n&quot;` with a line break between the name and closing quote, rendering extra whitespace in the rendered text. | Moved closing `&quot;?` to same line as `{deleteTarget?.display_name}` to eliminate whitespace. -- FIXED |
| 13 | Low | Subscription History (empty states) | "No payment history" and "No change history" text was left-aligned in a `<p>` without centering, inconsistent with other empty states in the app which center their content. | Added `py-4 text-center` to both empty state paragraphs for visual consistency. -- FIXED |
| 14 | Low | Subscription History Tabs | The `PaymentHistoryTab` and `ChangeHistoryTab` components used a pattern of `if (data && data.length === 0)` followed by `if (data && data.length > 0)` followed by `return null`. This triple-branch pattern was unnecessarily complex and the `return null` branch was unreachable when data existed. | Simplified to `if (!data || data.length === 0)` for empty state and a single `return <DataTable>` for populated state, eliminating the dead `return null` branch. -- FIXED |
| 15 | Low | Coupon Detail Dialog title | The dialog title showed "Loading..." when data was not yet loaded, which was generic. When data loaded, the coupon code could potentially overflow the dialog title area on very long codes. | Changed loading title to "Coupon Details" (more descriptive) and added `max-w-[400px] truncate` with `title` attribute to the code display for overflow protection. -- FIXED |
| 16 | Low | Subscription Detail Dialog title | The dialog title could overflow when a trainer has a very long email address. | Added `truncate` class to `DialogTitle` to prevent layout overflow. -- FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A (4.1.2) | Loading skeleton containers on all 5 list pages had no ARIA live region or status role. Screen readers could not announce that content was loading. | Added `role="status"` and `aria-label` to all skeleton containers, plus `<span className="sr-only">` for status text. -- FIXED |
| 2 | A (4.1.2) | Filter toggle buttons on Trainers page had no `aria-pressed` attribute. Screen readers could not determine which filter was currently active. | Added `aria-pressed={boolean}` to each filter button and `role="group"` with `aria-label` to the container. -- FIXED |
| 3 | AA (2.4.7) | Native `<input type="checkbox">` elements in 3 form dialogs (tier, user, coupon) had no visible focus indicator when navigated via keyboard. | Added `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` classes. -- FIXED |
| 4 | A (4.1.2) | Dialog loading spinners in Coupon Detail, Subscription Detail, and both History Tabs used `<Loader2>` without `aria-hidden="true"`. Screen readers would attempt to read the SVG icon, producing meaningless output. | Added `aria-hidden="true"` to all loading `<Loader2>` icons and wrapped them in containers with `role="status"` and sr-only text. -- FIXED |
| 5 | A (1.3.1) | Subscription change history "Details" column used ASCII `->` which has no semantic meaning for screen readers. | Changed to `<span aria-label="changed to">&rarr;</span>` for proper screen reader context. -- FIXED |
| 6 | A (4.1.3) | Past Due Alerts card had no error announcement. When the fetch failed, the card simply rendered nothing, with no `role="alert"` or error message. | Added error state with `role="alert"` and descriptive message. -- FIXED |

---

## Missing States

### Admin Dashboard (`/admin/dashboard`)
- [x] Loading -- `AdminDashboardSkeleton` with full skeleton layout matching actual content structure
- [x] Error -- `ErrorState` with "Failed to load dashboard data" and retry button
- [x] Populated -- `DashboardStats` + `RevenueCards` + `TierBreakdown` + `PastDueAlerts`
- [x] Past due badge -- Shows count badge in header when `past_due_count > 0`

### Trainers Page (`/admin/trainers`)
- [x] Loading -- 3 skeleton rows with `role="status"`
- [x] Error -- `ErrorState` with retry
- [x] Empty (no data) -- `EmptyState` with Users icon, "No trainers have joined the platform yet."
- [x] Empty (filtered) -- `EmptyState` with "No trainers match your search criteria."
- [x] Populated -- `TrainerList` (DataTable) with clickable rows

### Users Page (`/admin/users`)
- [x] Loading -- 3 skeleton rows with `role="status"`
- [x] Error -- `ErrorState` with retry
- [x] Empty (no data) -- `EmptyState` with "Create User" CTA
- [x] Empty (filtered) -- `EmptyState` with search criteria message
- [x] Populated -- `UserList` (DataTable) with clickable rows

### Tiers Page (`/admin/tiers`)
- [x] Loading -- 3 skeleton rows with `role="status"`
- [x] Error -- `ErrorState` with retry
- [x] Empty -- `EmptyState` with "Seed Defaults" button (with loading spinner)
- [x] Populated -- `TierList` with edit, toggle, delete actions
- [x] Delete confirmation -- Dialog with error display and loading state
- [x] Toggle loading -- Per-row spinner while toggling active status

### Coupons Page (`/admin/coupons`)
- [x] Loading -- 3 skeleton rows with `role="status"`
- [x] Error -- `ErrorState` with retry
- [x] Empty (no data) -- `EmptyState` with "Create Coupon" CTA
- [x] Empty (filtered) -- `EmptyState` with filter message
- [x] Populated -- `CouponList` with clickable rows

### Subscriptions Page (`/admin/subscriptions`)
- [x] Loading -- 3 skeleton rows with `role="status"`
- [x] Error -- `ErrorState` with retry
- [x] Empty (no data) -- `EmptyState` with "No trainer subscriptions exist yet."
- [x] Empty (filtered) -- `EmptyState` with filter message
- [x] Populated -- `SubscriptionList` with clickable rows
- [x] Deep link -- `?past_due=true` URL param pre-selects status filter

### Settings Page (`/admin/settings`)
- [x] Placeholder -- `EmptyState` with "Coming soon" message

### Coupon Detail Dialog
- [x] Loading -- Centered spinner with `role="status"`
- [x] Error -- Alert with retry button
- [x] Populated -- Full detail view with actions
- [x] Revoke/Reactivate -- Loading spinners on action buttons
- [x] Usages loading -- Spinner in usages section
- [x] Usages empty -- "No usages recorded yet" text
- [x] Usages populated -- `DataTable` of usage records

### Subscription Detail Dialog
- [x] Loading -- Centered spinner with `role="status"`
- [x] Error -- Alert with retry button
- [x] Populated -- Tabbed interface (Overview, Payments, Changes)
- [x] Action forms -- Change Tier, Change Status, Record Payment, Edit Notes
- [x] Same-value validation -- Disables Confirm when selecting current tier/status
- [x] Payment/change history loading -- Spinners with `role="status"`
- [x] Payment/change history empty -- Centered "No history" text

### Past Due Alerts Card
- [x] Loading -- 3 pulse-animated placeholders with `role="status"`
- [x] Error -- Alert with retry button
- [x] Empty -- "No past due subscriptions" text
- [x] Populated -- Up to 5 alert items + "View All (N)" link to subscriptions page

### Impersonation Banner
- [x] Active -- Amber banner with trainer email and "End Impersonation" button
- [x] Ending -- Loading spinner with "Ending..." text, button disabled
- [x] Inactive -- Banner hidden (returns null)

---

## Copy Assessment

| Element | Copy | Verdict |
|---------|------|---------|
| Dashboard title | "Admin Dashboard" | Clear, matches nav |
| Dashboard description | "Platform overview and management" | Informative |
| Trainers title | "Trainers" | Clear |
| Trainers description | "Manage platform trainers" | Action-oriented |
| Trainers search | "Search by name or email..." | Clear expectation |
| Users title | "Users" | Clear |
| Users description | "Manage admin and trainer accounts" | Scoped appropriately |
| Tiers title | "Subscription Tiers" | Specific |
| Tiers description | "Manage platform subscription tiers" | Clear |
| Coupons title | "Coupons" | Clear |
| Coupons description | "Manage discount coupons" | Clear |
| Subscriptions title | "Subscriptions" | Clear |
| Subscriptions description | "Manage trainer subscriptions" | Scoped to trainers |
| Settings title | "Settings" | Clear |
| Settings placeholder | "Admin settings will be available in a future update." | Honest, sets expectation |
| Impersonation banner | "Viewing as {email}" | Clear context |
| End impersonation | "End Impersonation" | Action-oriented |
| Delete tier confirm | 'Are you sure you want to delete "{name}"? This action cannot be undone.' | Clear consequences |
| Suspend trainer confirm | "Are you sure you want to suspend {name}? They will lose access to their dashboard." | Specific consequence |
| Empty trainers | "No trainers have joined the platform yet." | Helpful, not blaming |
| Empty tiers | "Create tiers to define subscription plans for trainers." | Actionable guidance |
| Seed defaults button | "Seed Defaults" | Clear but could benefit from explanation |
| Password strength labels | "Too short" / "Weak" / "Fair" / "Good" / "Strong" | Progressive, clear |

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Page headers | Consistent | All 7 pages use shared `PageHeader` with title, description, optional actions |
| Loading states | Consistent (after fix) | All list pages use 3 skeleton rows with `role="status"` and `aria-label` |
| Error states | Consistent | All list pages use shared `ErrorState` with retry |
| Empty states | Consistent | All list pages use shared `EmptyState` with contextual messages for filtered vs. unfiltered |
| Data tables | Consistent | All lists use shared `DataTable` with `keyExtractor`, `onRowClick`, keyboard support |
| Dialog pattern | Consistent | All dialogs use shadcn Dialog with Header/Title/Description/Footer |
| Toast feedback | Consistent | All mutations show `toast.success()` or `toast.error()` with specific messages |
| Filter controls | Consistent (after fix) | All native `<select>` elements use shared `SELECT_CLASSES` constant |
| Search pattern | Consistent | All searchable pages use `useDebounce(300)` + `useMemo` for filters |
| Destructive actions | Consistent | All destructive actions (delete, suspend, revoke) have confirmation UI |
| Badge colors | Consistent (after fix) | Tier and status badge colors use centralized constants from `admin-constants.ts` |
| Checkbox styling | Consistent (after fix) | All native checkboxes use `accent-primary` and focus-visible ring |

---

## Responsiveness Assessment

| Aspect | Status |
|--------|--------|
| Layout | Sidebar hidden on mobile (`lg:block`), Sheet drawer for mobile nav |
| Filter toolbars | `flex-col gap-3 sm:flex-row sm:items-center` -- stacks on mobile, row on desktop |
| DataTables | Wrapped in `overflow-x-auto` for horizontal scroll on narrow screens |
| Dialog content | `max-w-md` / `max-w-lg` / `max-w-2xl` / `max-w-3xl` with `max-h-[80vh] overflow-y-auto` |
| Dashboard stat cards | `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4` responsive grid |
| Tier breakdown bars | Full width with percentage-based progress bars |
| Impersonation banner | Flex row with `justify-between` -- works at all sizes |
| Form dialogs | Grids use `grid-cols-2` / `grid-cols-3` that stack naturally in dialogs |
| Page header | `flex-col gap-1 sm:flex-row sm:items-center sm:justify-between` |

---

## Fixes Implemented

### 1. All List Pages (Trainers, Users, Tiers, Coupons, Subscriptions)
- **Added `role="status"` and `aria-label`** to all loading skeleton containers
- **Added `<span className="sr-only">`** text inside each skeleton for screen reader announcement

### 2. `web/src/app/(admin-dashboard)/admin/trainers/page.tsx`
- **Added `role="group"` and `aria-label`** to filter button container
- **Added `aria-pressed`** to each filter toggle button (All / Active / Inactive)

### 3. `web/src/components/admin/past-due-alerts.tsx`
- **Added error state** with `role="alert"`, destructive text, and inline "Retry" button
- **Added `role="status"` and `aria-label`** to loading skeleton container

### 4. `web/src/components/admin/coupon-detail-dialog.tsx`
- **Added error state** for coupon fetch failure with `role="alert"` and "Retry" button
- **Added `role="status"` and `aria-hidden="true"`** to loading spinners
- **Replaced local `STATUS_VARIANT`** with centralized `COUPON_STATUS_VARIANT`
- **Improved dialog title**: "Coupon Details" default, truncated code display with `title` attribute

### 5. `web/src/components/admin/subscription-detail-dialog.tsx`
- **Added error state** for subscription fetch failure with `role="alert"` and "Retry" button
- **Added `role="status"` and `aria-hidden="true"`** to loading spinner
- **Added `truncate`** to `DialogTitle` to prevent long email overflow

### 6. `web/src/components/admin/subscription-list.tsx`
- **Fixed status capitalization**: Changed from `charAt(0).toUpperCase()` to `replace(/\b\w/g, c => c.toUpperCase())` for proper title case ("Past Due" instead of "Past due")

### 7. `web/src/components/admin/subscription-history-tabs.tsx`
- **Added `role="status"` and `aria-label`** to both loading spinners with `aria-hidden="true"` on icons
- **Changed arrow symbol** from ASCII `->` to `&rarr;` with `aria-label="changed to"`
- **Centered empty state text** with `py-4 text-center`
- **Simplified branch logic**: Eliminated dead `return null` branches

### 8. `web/src/components/admin/coupon-list.tsx`
- **Replaced local `STATUS_VARIANT`** with imported `COUPON_STATUS_VARIANT` from `admin-constants.ts`

### 9. `web/src/components/admin/subscription-action-forms.tsx`
- **Replaced inline select class strings** with `SELECT_CLASSES_FULL_WIDTH` constant

### 10. `web/src/components/admin/create-user-dialog.tsx`
- **Replaced inline select class string** with `SELECT_CLASSES_FULL_WIDTH` constant
- **Improved checkbox styling**: Added `accent-primary` and `focus-visible` ring classes

### 11. `web/src/components/admin/tier-form-dialog.tsx`
- **Improved checkbox styling**: Added `accent-primary` and `focus-visible` ring classes

### 12. `web/src/components/admin/coupon-form-dialog.tsx`
- **Replaced inline select class strings** with `SELECT_CLASSES_FULL_WIDTH` constant
- **Improved checkbox styling**: Added `accent-primary` and `focus-visible` ring classes

### 13. `web/src/app/(admin-dashboard)/admin/coupons/page.tsx`
- **Replaced inline select class strings** with imported `SELECT_CLASSES` constant

### 14. `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`
- **Replaced inline select class strings** with imported `SELECT_CLASSES` constant

### 15. `web/src/app/(admin-dashboard)/admin/users/page.tsx`
- **Replaced inline select class string** with imported `SELECT_CLASSES` constant

### 16. `web/src/app/(admin-dashboard)/admin/tiers/page.tsx`
- **Fixed delete dialog text spacing**: Moved closing quote to same line as display name

---

## Items Not Fixed (Require Design Decisions or Out of Scope)

1. **Pagination on list pages** -- Trainers, Users, Coupons, and Subscriptions lists currently render all results without pagination. The `DataTable` component supports `totalCount`, `page`, `pageSize`, and `onPageChange` props, but these are not wired up. For large datasets (100+ trainers), pagination or virtual scrolling should be added. Requires backend API changes to return paginated responses.

2. **Native `<select>` vs. shadcn Select** -- The codebase uses native `<select>` elements rather than the shadcn `Select` component (Radix UI). Native selects have limited styling (especially in dark mode where `<option>` background cannot be styled). Migrating to the Radix Select component would provide full theme consistency. This is a design system decision that affects all form selects across the admin dashboard.

3. **Bulk actions on list pages** -- There is no way to select multiple items and perform bulk actions (e.g., suspend multiple trainers, delete multiple coupons, change tier for multiple subscriptions). This would be valuable for admins managing many records.

4. **Confirmation for dangerous status changes** -- The subscription action forms allow changing status to "suspended" or "canceled" without a confirmation step. The tier change and status change forms have a "Confirm" button, but no warning about the consequences of a destructive status change. Consider adding amber/red warning text when selecting "suspended" or "canceled" as the new status.

5. **Admin dashboard data freshness indicator** -- There is no indication of when the dashboard data was last fetched. Adding a "Last updated: X minutes ago" indicator with a refresh button would help admins trust the displayed numbers.

6. **Coupon code copy-to-clipboard** -- The coupon code is displayed in `font-mono` but there is no one-click copy button. Admins frequently need to share coupon codes.

---

## Overall UX Score: 8/10

### Breakdown:
- **State Handling:** 9/10 -- After fixes, every component handles loading (with proper ARIA), error (with retry), empty (with contextual messages), and populated states. Past Due Alerts and detail dialogs now have error recovery paths.
- **Accessibility:** 8/10 -- All loading states now have `role="status"` and sr-only text. Filter buttons have `aria-pressed`. Checkboxes have focus-visible indicators. DataTable rows have keyboard support (`tabIndex`, `onKeyDown`). Skip-to-content link in layout. Remaining gap: native `<select>` elements are less accessible than Radix Select.
- **Visual Consistency:** 9/10 -- All select elements use shared class constants. Badge colors centralized. Skeleton loading patterns are uniform. Checkbox styling is consistent. Status labels use proper title case.
- **Copy Clarity:** 9/10 -- All copy is clear and actionable. Empty states differentiate between "no data yet" and "no results match your filter". Confirmation dialogs explain consequences. Toast messages include entity names.
- **Responsiveness:** 8/10 -- Layout adapts well (sidebar collapse, filter stacking, table scroll). Stat cards grid is responsive. Dialog sizing adapts. Minor concern: Coupons filter toolbar has 4 selects that may crowd on tablet screens.
- **Feedback & Interaction:** 8/10 -- All mutations show spinners and success/error toasts. Destructive actions have confirmations. Impersonation has clear banner and end flow. Tier toggle shows per-row loading. Remaining gap: no bulk actions, no clipboard copy for coupons.

### Strengths:
- Comprehensive shared component system (PageHeader, EmptyState, ErrorState, DataTable, StatCard)
- Skip-to-content link and semantic navigation with `aria-label` and `aria-current="page"`
- DataTable with keyboard navigation (Enter/Space to open row, focus-visible ring)
- Impersonation banner with clear context and easy exit
- Deep linking support (subscriptions `?past_due=true`)
- Centralized constants for badge colors and select styling (DRY)

### Areas for Future Improvement:
- Migrate native `<select>` to shadcn/Radix Select for full dark mode and theming support
- Add pagination to all list pages for large datasets
- Add bulk selection and actions to list pages
- Add copy-to-clipboard for coupon codes
- Add dashboard data freshness indicator
- Add warning text for destructive subscription status changes

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 13 -- Admin Dashboard (Next.js 16 + React 19 + shadcn/ui)
**Verdict:** PASS -- All critical accessibility and usability issues fixed. 16 files modified with 16 usability fixes and 6 accessibility fixes. Build passes clean with no TypeScript or lint errors.

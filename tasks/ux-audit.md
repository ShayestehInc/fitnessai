# UX Audit: Admin Dashboard Mobile Responsiveness (Pipeline 38)

## Audit Date: 2026-02-24
## Pipeline: 38
## Auditor: UX Auditor
## Scope: 21 admin dashboard files audited at 375px mobile width

---

## Summary

The admin dashboard mobile-responsive implementation is solid overall. The existing patterns from Pipeline 37 (column hiding with `hidden md:table-cell`, responsive stacking with `flex-col sm:flex-row`, `max-h-[90dvh] overflow-y-auto` on dialogs) are applied consistently across all admin pages. I found 5 issues -- 0 critical, 1 major, and 4 minor -- and fixed all of them.

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | `admin-constants.ts` `SELECT_CLASSES` | Native `<select>` elements used on subscriptions, coupons, and users filter bars have `h-9` (36px height), falling below the 44px WCAG minimum touch target for mobile. These are primary filter controls used on every admin list page. | Changed `h-9` to `h-11 sm:h-9` so selects are 44px on mobile and revert to 36px on desktop. Since `SELECT_CLASSES` is a shared constant, this fix propagates to all admin filter selects and full-width form selects automatically. | **FIXED** |
| 2 | Minor | `past-due-full-list.tsx` Mail button | The Mail reminder button lacks `aria-label` (screen readers would announce nothing meaningful) and lacks minimum touch target sizing on mobile. | Added `aria-label` with the trainer name/email, `aria-hidden="true"` on the icon, and `min-h-[44px] min-w-[44px] sm:min-h-0 sm:min-w-0` for mobile touch compliance. | **FIXED** |
| 3 | Minor | `coupon-detail-dialog.tsx` title code display | The coupon code span in the dialog title uses `max-w-[400px]`, which exceeds the usable width of a dialog on a 375px screen (dialog is `max-w-2xl` but viewport-constrained, leaving approximately 300px for content). Long codes would force horizontal overflow of the title area. | Changed to `max-w-[200px] sm:max-w-[400px]` so the truncation breakpoint is appropriate for small screens. | **FIXED** |
| 4 | Minor | `admin-sidebar-mobile.tsx` nav links | Mobile sidebar navigation links use `py-2` (8px vertical padding) resulting in approximately 36px total height, below the 44px WCAG touch target minimum. These are the primary navigation controls on mobile. | Added `min-h-[44px]` to the link class string to enforce compliant touch targets. | **FIXED** |
| 5 | Minor | `ambassador-detail-dialog.tsx` icon accessibility | Six Lucide icons (3 Loader2 spinners, Check, 2 DollarSign) in the action buttons lack `aria-hidden="true"`, causing screen readers to potentially announce SVG content. | Added `aria-hidden="true"` to all six icons. | **FIXED** |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA (2.5.8 Target Size) | Native `<select>` filter elements at 36px height on mobile; sidebar nav links at approximately 36px; past-due Mail button without min size. | **FIXED** -- All now meet 44px minimum via responsive classes. |
| 2 | A (1.1.1 Non-text Content) | Past-due Mail button has no accessible name; ambassador detail icons lack `aria-hidden`. | **FIXED** -- Added `aria-label` and `aria-hidden="true"` as appropriate. |

---

## Missing States Checklist

- [x] **Loading / skeleton** -- All list pages (trainers, subscriptions, coupons, users) render `Skeleton` blocks during loading with proper `role="status"` and `aria-label`. Ambassador list has its own skeleton. Dialog components (subscription-detail, coupon-detail) show centered `Loader2` with `sr-only` text. All render correctly at 375px.
- [x] **Empty / zero data** -- All list pages use `EmptyState` component with contextual messages (search-filtered vs no data). Ambassador list has separate search/no-data messages with CTA. DataTable shows "No results found." for inline empty. Coupon usages section shows "No usages recorded yet". All center well at 375px.
- [x] **Error / failure** -- All list pages use `ErrorState` with retry button. Subscription and coupon detail dialogs have inline error alerts with retry links. Form dialogs display `toast.error` on submission failure. Delete confirmation in create-user-dialog shows inline error via `deleteError` state.
- [x] **Success / confirmation** -- All mutations fire `toast.success` on completion. Destructive actions (suspend trainer, delete user, revoke coupon) have confirmation steps before execution.
- [x] **Offline / degraded** -- React Query retry handles transient failures. Not applicable beyond that for this admin dashboard.
- [x] **Permission denied** -- Layout redirects non-admin users to `/dashboard` and unauthenticated users to `/login`.

---

## Responsive Behavior Assessment (375px)

| Component Type | Observations | Status |
|----------------|-------------|--------|
| **List pages** (trainers, subscriptions, coupons, users) | Search input goes full-width on mobile. Filter selects stack vertically via `flex-col sm:flex-row`. PageHeader stacks title and actions. Tables hide secondary columns (`hidden md:table-cell`). Horizontal scroll with gradient hint on tables. | PASS |
| **DataTable** (shared) | Rows are keyboard-navigable with `tabIndex`, `role="button"`, focus ring. Pagination has 44px touch targets. Column hiding consistent. Scroll hint gradient fades at end. | PASS |
| **Detail dialogs** (trainer, subscription, coupon, ambassador) | All use `max-h-[90dvh] overflow-y-auto` for tall content. Grids use `grid-cols-2` or `grid-cols-2 sm:grid-cols-3` for responsive info layouts. Subscription detail tabs scroll horizontally with `overflow-x-auto` wrapper. | PASS |
| **Form dialogs** (coupon, tier, create-user, create-ambassador) | All use `max-h-[90dvh] overflow-y-auto`. Form fields use `grid-cols-1 sm:grid-cols-2` or `grid-cols-2` (which is fine at 375px with gap-4). DialogFooter buttons stack naturally. | PASS |
| **Card-based lists** (ambassador, past-due, upcoming-payments) | Use `flex items-center justify-between` with `min-w-0 flex-1` for truncation. Metadata items use `flex-wrap gap-x-3 gap-y-1` to handle wrapping at narrow widths. | PASS |
| **Admin layout** | Mobile sidebar via Sheet component (w-64). Header hamburger button at `lg:hidden`. Skip-to-content link present. Main content has `p-4 lg:p-6` padding. | PASS |

---

## Positive Patterns Observed

1. **Consistent dialog sizing** -- All dialogs cap at `max-h-[90dvh]` with `overflow-y-auto`, preventing content from being unreachable on small screens. `dvh` correctly accounts for mobile browser chrome.
2. **Proper truncation** -- Name/email cells use `min-w-0` + `truncate` pattern consistently across all list components, preventing text overflow at any width.
3. **Touch target compliance on key controls** -- Ambassador list's Eye button, trainer page filter buttons, and DataTable pagination buttons all already have `min-h-[44px] min-w-[44px]` from prior pipeline work.
4. **Form validation** -- All form dialogs (coupon, tier, user, ambassador) have client-side validation with inline error messages using `aria-invalid` and `aria-describedby` linking to error text. Password strength indicator in create-user-dialog.
5. **Confirmation for destructive actions** -- Trainer suspend and user delete both use inline confirmation UI rather than browser `confirm()`, with proper cancel buttons.
6. **Accessibility infrastructure** -- Skip-to-content link in layout, `role="status"` on loading states, `sr-only` text for spinners, `aria-label` on filter inputs and button groups, `aria-pressed` on toggle filter buttons.

---

## Consistency Checks

- [x] All table column hiding uses `hidden md:table-cell` pattern.
- [x] All filter bars use `flex-col gap-3 sm:flex-row sm:items-center` stacking pattern.
- [x] All search inputs use `w-full sm:max-w-sm` sizing pattern.
- [x] All dialog contents use `max-h-[90dvh] overflow-y-auto` pattern.
- [x] All form dialogs use `DialogFooter` for action buttons.
- [x] All destructive mutations show `toast.error` on failure.
- [x] All loading states use either `Skeleton` or `Loader2` with `sr-only` text.
- [x] Coupon detail dialog `max-w-2xl`, subscription detail `max-w-3xl`, trainer/user dialogs `max-w-md`, tier/coupon forms `max-w-lg` -- all appropriate for their content density.

---

## Not Fixed (Informational -- Not Real Issues)

| # | Severity | Observation | Notes |
|---|----------|------------|-------|
| 1 | Info | Coupon list shows 5 visible columns on mobile (Code, Type, Discount, Status, Usage). This is dense but the horizontal scroll with gradient hint handles it. | The `overflow-x-auto` + scroll hint pattern works. Hiding "Usage" on mobile could be considered but it provides important context alongside "Status". Not worth the trade-off. |
| 2 | Info | Tier list has inline Edit/Delete action buttons in a table column. On mobile these stack vertically (`flex-col gap-1 sm:flex-row`), which is correct but increases row height. | The stacking behavior is appropriate. No change needed. |
| 3 | Info | Ambassador list uses a custom card layout rather than DataTable. This is actually the superior mobile pattern. | The ambassador list pattern could inform a future "card mode" for DataTable on mobile, as noted in Pipeline 37's audit. |

---

## Overall UX Score: 8/10

**Rationale:** The admin dashboard mobile implementation is well-executed with consistent patterns applied across all 21 files. All five core states (loading, empty, error, success, confirmation) are properly handled across every page and dialog. Accessibility is strong with ARIA attributes, keyboard navigation, screen reader text, and focus management. The responsive behavior at 375px is thoroughly handled with column hiding, stacking, and proper overflow management.

The one major issue (36px select touch targets on filter bars used across 3+ pages) was a shared constant problem that affected multiple pages simultaneously -- now fixed. The minor issues were all small accessibility gaps (missing aria-labels/aria-hidden, title overflow, nav link sizing) that are typical of a first mobile pass and are now resolved.

The score reflects the quality after fixes. Pre-fix score would have been 7/10 due to the touch target issue affecting multiple primary interactive controls on mobile.

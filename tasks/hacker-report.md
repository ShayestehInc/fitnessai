# Hacker Report: Admin Dashboard Post-Pipeline 38 Audit

## Date: 2026-02-24

## Files Audited
### Admin components:
- `web/src/components/admin/coupon-detail-dialog.tsx`
- `web/src/components/admin/coupon-form-dialog.tsx`
- `web/src/components/admin/coupon-list.tsx`
- `web/src/components/admin/subscription-detail-dialog.tsx`
- `web/src/components/admin/subscription-action-forms.tsx`
- `web/src/components/admin/subscription-history-tabs.tsx`
- `web/src/components/admin/subscription-list.tsx`
- `web/src/components/admin/trainer-detail-dialog.tsx`
- `web/src/components/admin/trainer-list.tsx`
- `web/src/components/admin/ambassador-detail-dialog.tsx`
- `web/src/components/admin/ambassador-list.tsx`
- `web/src/components/admin/create-ambassador-dialog.tsx`
- `web/src/components/admin/create-user-dialog.tsx`
- `web/src/components/admin/tier-form-dialog.tsx`
- `web/src/components/admin/tier-list.tsx`
- `web/src/components/admin/dashboard-stats.tsx`
- `web/src/components/admin/revenue-cards.tsx`
- `web/src/components/admin/tier-breakdown.tsx`
- `web/src/components/admin/past-due-alerts.tsx`
- `web/src/components/admin/past-due-full-list.tsx`
- `web/src/components/admin/upcoming-payments-list.tsx`
- `web/src/components/admin/admin-dashboard-skeleton.tsx`
- `web/src/components/admin/user-list.tsx`

### Layout:
- `web/src/components/layout/admin-sidebar.tsx`
- `web/src/components/layout/admin-sidebar-mobile.tsx`
- `web/src/components/layout/admin-nav-links.ts`
- `web/src/components/layout/header.tsx`
- `web/src/app/(admin-dashboard)/layout.tsx`

### Admin pages:
- `web/src/app/(admin-dashboard)/admin/dashboard/page.tsx`
- `web/src/app/(admin-dashboard)/admin/trainers/page.tsx`
- `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`
- `web/src/app/(admin-dashboard)/admin/coupons/page.tsx`
- `web/src/app/(admin-dashboard)/admin/tiers/page.tsx`
- `web/src/app/(admin-dashboard)/admin/users/page.tsx`
- `web/src/app/(admin-dashboard)/admin/ambassadors/page.tsx`
- `web/src/app/(admin-dashboard)/admin/upcoming-payments/page.tsx`
- `web/src/app/(admin-dashboard)/admin/past-due/page.tsx`
- `web/src/app/(admin-dashboard)/admin/settings/page.tsx`

### Shared:
- `web/src/components/shared/data-table.tsx`
- `web/src/components/shared/page-header.tsx`
- `web/src/components/shared/error-state.tsx`
- `web/src/components/ui/dialog.tsx`
- `web/src/lib/admin-constants.ts`
- `web/src/hooks/use-admin-coupons.ts`
- `web/src/app/globals.css` (table-scroll-hint)

---

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Low | `admin/coupons/[id]/`, `admin/subscriptions/[id]/`, `admin/trainers/[id]/` | Empty `[id]` route directories | These directories either contain page files or don't exist | Three empty `[id]` directories exist with no `page.tsx`. Navigating directly to `/admin/coupons/123` would show a Next.js 404. Not a functional issue since these entities use dialog-based detail views, but dead code. |

**Assessment:** No dead buttons found. All admin dialog buttons (Edit, Revoke, Reactivate, Impersonate, Suspend, Activate, Create, Delete, Change Tier, Change Status, Record Payment, Save Notes, Approve All, Pay All, Trigger Payout) are properly wired with handlers, loading states, error handling, and toast feedback. The "Send Reminder" email button on the Past Due page shows a `toast.info` placeholder, which is intentional (not yet wired to a backend endpoint) and clearly communicates what it would do.

---

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| -- | -- | -- | -- | -- |

**Assessment:** The admin dashboard mobile-responsive work from Pipeline 38 is well-executed:

- **Admin sidebar mobile** (`admin-sidebar-mobile.tsx`): Properly uses Sheet component with `side="left"`, `w-64`, nav links with `onClick={() => onOpenChange(false)}` to close on navigation. Correct `aria-label`, `aria-current`, and icon `aria-hidden` attributes.
- **Admin sidebar desktop** (`admin-sidebar.tsx`): Properly uses `hidden lg:block` with `lg:` breakpoint, matching the `lg:hidden` hamburger button in the header.
- **All admin dialogs**: Every dialog uses `max-h-[90dvh] overflow-y-auto` on `DialogContent`. This prevents overflow on mobile viewports with on-screen keyboards.
- **DataTable**: Scroll hint gradient, `overflow-x-auto`, column hiding via `hidden md:table-cell`, responsive pagination with compact mobile buttons.
- **Filter bars** (coupons, subscriptions, users): Use `flex-col sm:flex-row` for stacking on mobile.
- **Coupon detail dialog title**: Uses `max-w-[200px] truncate sm:max-w-[400px]` -- responsive truncation for long coupon codes. Well done.
- **Page headers**: Use `flex-col sm:flex-row` with gap for title/actions stacking.
- **Ambassador stats grid**: `grid-cols-3` works at all breakpoints since the ambassador detail dialog uses `sm:max-w-lg`, ensuring the 3-column grid always has enough room.

No visual bugs found in the admin section.

---

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 2 | Medium | Coupon detail dialog - usages error state | 1. Open a coupon detail dialog. 2. Simulate the usages API returning an error (e.g., 500). | User should see an error message with a retry option. | **Before fix:** The usages section showed nothing -- no loading spinner, no error message, no empty state. The `usages.isError` case was completely unhandled, leaving a silent failure with just the "Usages" heading and blank space below it. |
| 3 | Medium | Past Due full list - error state | 1. Navigate to `/admin/past-due`. 2. API returns an error. | User should see an error message with retry. | **Before fix:** Component only destructured `data` and `isLoading` from `useQuery`. If the API failed, the user would see the empty state ("No past due payments") instead of an error, which is misleading -- it suggests all payments are current when in reality the data failed to load. |
| 4 | Medium | Upcoming Payments list - error state | 1. Navigate to `/admin/upcoming-payments`. 2. API returns an error. | User should see an error message with retry. | **Before fix:** Same pattern as Past Due -- only `data` and `isLoading` destructured. API errors silently fell through to the empty state ("No upcoming payments"), giving false confidence that there are no payments due. |
| 5 | Medium | Trainer detail dialog - stale suspend confirm | 1. Open trainer A's detail dialog. 2. Click "Suspend Trainer" to show the inline confirmation. 3. Close the dialog without confirming. 4. Open trainer B's detail dialog. | Trainer B's dialog should show the default action buttons (Impersonate, Suspend). | **Before fix:** The `showSuspendConfirm` state was not reset when the dialog re-opened for a different trainer because no `key` prop was used. The suspend confirmation for trainer A would still be visible, now targeted at trainer B. Clicking "Confirm Suspend" would suspend the wrong trainer -- trainer B instead of trainer A. |
| 6 | Medium | Subscription detail dialog - stale action mode | 1. Open subscription A's detail dialog. 2. Click "Change Tier" to expand the tier change form. 3. Close the dialog. 4. Open subscription B's detail dialog. | Subscription B's dialog should show the default overview with action buttons. | **Before fix:** The `actionMode` state was not reset because no `key` prop was used. The tier change form from subscription A's session would still be open, with the old tier pre-selected and the old reason text filled in. Submitting could apply the wrong tier change to subscription B. |

---

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 7 | Low | Empty [id] routes | Remove the three empty `[id]` directories (`admin/coupons/[id]`, `admin/subscriptions/[id]`, `admin/trainers/[id]`). They have no page files and serve no purpose. If detail pages are planned, they should be created with actual content when needed. |
| 8 | Medium | Past Due page | Add a "Send All Reminders" bulk action button at the top of the Past Due page. Currently each past-due trainer must be reminded individually via the Mail icon button. For an admin managing 20+ past-due accounts, a bulk action would save significant time. |
| 9 | Low | Ambassador list | Add pagination to the ambassador list. Currently uses `useAdminAmbassadors(1, debouncedSearch)` with page hardcoded to `1`. If there are more than 20 ambassadors (default page size), the rest are invisible. |

---

## Summary
- Dead UI elements found: 1 (3 empty route directories -- cosmetic dead code)
- Visual bugs found: 0
- Logic bugs found: 5 (all fixed)
- Improvements suggested: 3
- Items fixed by hacker: 5 issues across 7 files

### Files Changed by Hacker
1. **`web/src/components/admin/coupon-detail-dialog.tsx`** -- Added `usages.isError` handling with retry button in the Usages section
2. **`web/src/components/admin/past-due-full-list.tsx`** -- Added `isError` destructuring from `useQuery` and `ErrorState` component for API failures
3. **`web/src/components/admin/upcoming-payments-list.tsx`** -- Added `isError` destructuring from `useQuery` and `ErrorState` component for API failures
4. **`web/src/app/(admin-dashboard)/admin/trainers/page.tsx`** -- Added `key={selectedTrainer?.id ?? "none"}` to `TrainerDetailDialog` to force remount and reset stale state when switching trainers
5. **`web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`** -- Added `key={selectedSubId ?? "none"}` to `SubscriptionDetailDialog` to force remount and reset stale state when switching subscriptions

## Chaos Score: 4/10

The admin dashboard is in solid shape after Pipeline 38. The mobile-responsive work is thorough: every dialog has `max-h-[90dvh] overflow-y-auto`, all list pages use `flex-col sm:flex-row` filter stacking, the DataTable provides scroll hints and column hiding, and the admin mobile sidebar properly closes on navigation. The issues I found are subtle: three components with missing error states that would silently show empty-state messages on API failure (giving false confidence to the admin), and two dialogs with stale internal state when re-opened for different entities. All five issues are now fixed. The codebase follows consistent patterns (key-based remounting for dialogs with forms, ErrorState for API failures, toast feedback for mutations), and these fixes bring the remaining components into alignment with those established patterns.

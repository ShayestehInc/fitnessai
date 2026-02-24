# Dev Done: Admin Dashboard Mobile Responsiveness (Pipeline 38)

## Date
2026-02-24

## Summary
Made all admin dashboard pages fully mobile-friendly using CSS-only Tailwind utility classes. Consistent `md:` breakpoint (768px) matching Pipelines 36/37 patterns.

## Files Changed (23 files)

### Table Column Hiding (5 files)
1. **`web/src/components/admin/trainer-list.tsx`** — Added `className: "hidden md:table-cell"` to Trainees and Joined columns
2. **`web/src/components/admin/subscription-list.tsx`** — Added to Next Payment and Past Due columns
3. **`web/src/components/admin/coupon-list.tsx`** — Added to Applies To and Valid Until columns
4. **`web/src/components/admin/user-list.tsx`** — Added to Trainees and Created columns
5. **`web/src/components/admin/tier-list.tsx`** — Added to Trainee Limit and Order columns; action buttons now stack vertically on mobile (`flex flex-col gap-1 sm:flex-row`)

### Dialog Overflow Fixes (9 files)
6. **`web/src/components/admin/subscription-detail-dialog.tsx`** — Changed `max-h-[85vh]` to `max-h-[90dvh]`
7. **`web/src/components/admin/coupon-detail-dialog.tsx`** — Changed `max-h-[80vh]` to `max-h-[90dvh]`
8. **`web/src/components/admin/coupon-form-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`
9. **`web/src/components/admin/trainer-detail-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`; suspend/activate confirm buttons now stack on mobile (`flex flex-col gap-2 sm:flex-row`)
10. **`web/src/components/admin/tier-form-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`
11. **`web/src/components/admin/create-user-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`
12. **`web/src/components/admin/create-ambassador-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`
13. **`web/src/components/admin/ambassador-detail-dialog.tsx`** — Added `max-h-[90dvh] overflow-y-auto`
14. **`web/src/app/(admin-dashboard)/admin/tiers/page.tsx`** — Added `max-h-[90dvh] overflow-y-auto` to delete confirmation dialog

### Filter Input Fixes (4 pages)
15. **`web/src/app/(admin-dashboard)/admin/trainers/page.tsx`** — Changed `max-w-sm` to `w-full sm:max-w-sm`
16. **`web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx`** — Same
17. **`web/src/app/(admin-dashboard)/admin/coupons/page.tsx`** — Same
18. **`web/src/app/(admin-dashboard)/admin/users/page.tsx`** — Same

### Subscription History Tables (1 file)
19. **`web/src/components/admin/subscription-history-tabs.tsx`** — Hidden Description column on payments table and By/Reason columns on changes table on mobile

### Ambassador List Mobile Fix (1 file)
20. **`web/src/components/admin/ambassador-list.tsx`** — Added `flex-wrap` + `gap-x-4 gap-y-1` to metadata row

### Payment Cards Mobile Fix (2 files)
21. **`web/src/components/admin/past-due-full-list.tsx`** — Added `flex-wrap` + `gap-x-3 gap-y-1` to metadata row
22. **`web/src/components/admin/upcoming-payments-list.tsx`** — Same

### Layout Fix (1 file)
23. **`web/src/app/(admin-dashboard)/layout.tsx`** — Changed `h-screen` to `h-dvh` for Mobile Safari address bar compatibility

## Key Decisions
- **`dvh` units**: Used `90dvh` for dialogs instead of `vh` to properly account for Mobile Safari address bar
- **Consistent `md:` breakpoint**: 768px for all mobile/desktop transitions, matching P36/P37 patterns
- **Column hiding strategy**: Essential columns (Name, Status, Price) always visible; supplementary columns (dates, counts) hidden on mobile
- **No JS viewport detection**: All responsive behavior via Tailwind utility classes only

## Deviations from Ticket
- None. All 15 acceptance criteria addressed.

## Verification
- Dashboard stats grid: `sm:grid-cols-2 lg:grid-cols-4` (already responsive)
- Revenue cards: Same responsive grid (already responsive)
- Tier breakdown: Simple card layout (already responsive)
- Past due alerts: Card list with `min-w-0 flex-1 truncate` (already responsive)
- Settings page: `max-w-2xl` constrained (already responsive)
- PageHeader: Already has `flex-wrap` on actions wrapper

## How to Test
1. Open any admin page in Chrome DevTools responsive mode
2. Test at 320px (iPhone SE), 375px (iPhone), 768px (iPad), 1024px+ (desktop)
3. Verify tables show only essential columns on mobile
4. Open any dialog and verify it's scrollable within viewport
5. Check filter inputs stretch full width on mobile
6. Verify no horizontal body scroll on any page

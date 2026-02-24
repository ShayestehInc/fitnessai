# Code Review Round 1: Admin Dashboard Mobile Responsiveness (Pipeline 38)

## Review Date
2026-02-24

## Files Reviewed
23 files changed (all CSS-only Tailwind class modifications)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `coupon-form-dialog.tsx:202` | **Coupon form `grid grid-cols-2` for Type/Applies To unreadable at 375px.** On mobile, two `<select>` elements in a 2-column grid inside a dialog (~340px content area) will each be ~155px wide — barely fitting the longest option ("Free Trial (days)"). Labels truncate, the select dropdowns are cramped. | Change `grid grid-cols-2 gap-4` to `grid grid-cols-1 gap-4 sm:grid-cols-2`. |
| C2 | `tier-form-dialog.tsx:177` | **Tier form `grid grid-cols-3` for Price/Limit/Sort is unusable at 375px.** Three number inputs in a 3-column grid inside a dialog (~340px content area) gives each input ~100px. Labels like "Price ($/mo)" and "Trainee Limit" will wrap awkwardly, and the inputs are too narrow to comfortably type numbers. | Change `grid grid-cols-3 gap-4` to `grid grid-cols-1 gap-4 sm:grid-cols-3`. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `subscription-detail-dialog.tsx:84` | **Subscription detail tabs not scrollable at 375px.** The `<TabsList>` contains 3 triggers ("Overview", "Payments", "Changes") which might overflow at narrow widths. The tabs are inside a `max-w-3xl` dialog that collapses to full screen on mobile. Without a scroll wrapper, tabs could overlap. | Wrap `<TabsList>` in `<div className="overflow-x-auto">` like P37 did for trainee detail tabs. |
| M2 | Various admin pages | **AC14 not addressed: touch targets below 44px.** Filter buttons on trainers page (All/Active/Inactive) use `size="sm"` (h-8 = 32px). Ambassador list Eye button, coupon action buttons (Edit/Revoke/Reactivate), and DataTable row targets are all below 44px. P37 used `min-h-[44px] min-w-[44px] sm:min-h-0 sm:min-w-0` pattern. | Add `min-h-[44px]` to key mobile interactive elements: trainers filter buttons, ambassador detail Eye button, and subscription action form buttons. Keep existing desktop sizes. |
| M3 | `create-user-dialog.tsx:277` | **Delete user confirmation buttons `flex gap-2` should stack on mobile**, matching the trainer-detail-dialog pattern. When the confirm card appears, "Confirm Delete" and "Cancel" sit side-by-side. On narrow dialogs, they can clip. | Change `flex gap-2` to `flex flex-col gap-2 sm:flex-row`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `coupon-detail-dialog.tsx:41-63` | Coupon usage table `Used At` column shows `"MMM d, yyyy HH:mm"` which is long (16+ chars) inside a dialog. At mobile width, this column takes significant space. | Add `className: "hidden md:table-cell"` to the `used_at` column. Users can tap the row or see the detail for exact times. |
| m2 | `ambassador-list.tsx:84` | Ambassador list card `flex items-center justify-between gap-4` doesn't handle narrow screens where email + badge + earnings overlap. | Add `flex-col sm:flex-row` to the card layout, or reduce the gap to `gap-2`. |
| m3 | `subscription-action-forms.tsx:146` | Action buttons "Change Tier", "Change Status", "Record Payment", "Edit Notes" — four buttons with `flex-wrap gap-2` look fine at most widths but could be more explicit. | Consider `grid grid-cols-2 gap-2 sm:flex sm:flex-wrap` to make the 4 buttons a 2x2 grid on mobile. |

---

## Security Concerns
None. All changes are CSS-only Tailwind class modifications. No new endpoints, no auth changes, no data handling.

## Performance Concerns
None. Pure CSS changes, no additional JS computation or DOM manipulation.

## Acceptance Criteria Verification

| AC # | Criterion | Status | Notes |
|------|-----------|--------|-------|
| 1 | Trainer list hides Trainees/Joined on mobile | PASS | `hidden md:table-cell` |
| 2 | Subscription list hides Next Payment/Past Due on mobile | PASS | `hidden md:table-cell` |
| 3 | Coupon list hides Applies To/Valid Until on mobile | PASS | `hidden md:table-cell` |
| 4 | User list hides Trainees/Created on mobile | PASS | `hidden md:table-cell` |
| 5 | Tier list hides Trainee Limit/Order on mobile | PASS | `hidden md:table-cell` |
| 6 | Tier action buttons stack on mobile | PASS | `flex flex-col sm:flex-row` |
| 7 | All dialogs have `max-h-[90dvh] overflow-y-auto` | PASS | All 9 admin dialogs + tier delete |
| 8 | Subscription detail dialog usable at 375px | **FAIL** | Tabs not scroll-wrapped (M1). Form grids in coupon/tier dialogs too cramped (C1, C2). |
| 9 | Filter inputs use `w-full sm:max-w-sm` | PASS | All 4 pages |
| 10 | Ambassador metadata wraps on mobile | PASS | `flex-wrap` added |
| 11 | Trainer detail confirm buttons stack on mobile | PASS | `flex flex-col sm:flex-row` |
| 12 | Page headers use responsive stacking | PASS | Verified, handled by PageHeader |
| 13 | Past due / upcoming payment cards readable at 375px | PASS | `flex-wrap` added |
| 14 | Touch targets >= 44px | **FAIL** | Not addressed (M2) |
| 15 | No horizontal body scroll | PASS | Column hiding + dvh layout |

**Summary: 13/15 PASS, 2/15 FAIL**

---

## Quality Score: 7/10

**What is good:**
- All 5 table column hiding implementations are correct and consistent
- Dialog overflow protection is comprehensive (all 10 dialogs)
- Filter input responsive widths properly applied
- Ambassador and payment card metadata wrapping properly addressed
- Layout `h-dvh` fix applied
- History tab column hiding is a good proactive addition
- Build passes clean

**What prevents a higher score:**
- Two critical form layout issues (coupon form 2-col, tier form 3-col) will be unusable at mobile width
- Touch targets not addressed at all (AC14)
- Subscription detail tabs missing scroll wrapper
- Delete confirmation in create-user-dialog doesn't stack on mobile like trainer-detail does

## Recommendation: REQUEST CHANGES

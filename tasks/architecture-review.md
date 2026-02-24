# Architecture Review: Trainer Dashboard Mobile Responsiveness

## Review Date
2026-02-24

## Files Reviewed
- `web/src/components/shared/data-table.tsx`
- `web/src/components/trainees/trainee-columns.tsx`
- `web/src/components/trainees/trainee-activity-tab.tsx`
- `web/src/components/programs/program-list.tsx`
- `web/src/components/programs/program-builder.tsx`
- `web/src/components/programs/exercise-row.tsx`
- `web/src/components/exercises/exercise-list.tsx`
- `web/src/components/invitations/invitation-columns.tsx`
- `web/src/components/analytics/revenue-section.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/app/(dashboard)/ai-chat/page.tsx`
- `web/src/app/(dashboard)/messages/page.tsx`
- `web/src/app/globals.css`
- `web/src/app/(dashboard)/layout.tsx`

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations (no backend changes -- pure frontend CSS/JSX)
- [x] No business logic in routers/views (all changes are presentational)
- [x] Consistent with existing patterns

### Overall Assessment

The implementation follows a CSS-first strategy using Tailwind responsive breakpoints, which is the correct approach for this codebase. Pipeline 36 established this pattern for the trainee web portal and this work extends it consistently to the trainer dashboard. All responsiveness lives in the view layer (component className props and globals.css). No state management, API, or business logic was touched.

The only JavaScript added was a minimal scroll event listener for the `table-scroll-hint` gradient. This is the right layer for that concern since it is a pure UI affordance that cannot be achieved with CSS alone.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend/schema changes |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | No new queries |
| No N+1 query patterns | N/A | No data fetching changes |

---

## Detailed Findings

### 1. Column Hiding via `className` Property (Good Architecture Decision)

The `hidden md:table-cell` pattern applied through the `Column.className` property keeps the DataTable component generic. Columns are always rendered in the DOM (important for accessibility) but visually hidden below `md` (768px). This is architecturally superior to conditionally filtering the columns array in JavaScript, which would change the component's data contract, cause hydration mismatches with SSR, and make the logic harder to reason about.

All five table components use the identical pattern:
```ts
{ className: "hidden md:table-cell" }
```

Applied consistently to:
- `trainee-columns.tsx` (Program, Joined -- 2 columns)
- `program-list.tsx` (Goal, Used, Created -- 3 columns)
- `invitation-columns.tsx` (Program, Expires -- 2 columns)
- `revenue-section.tsx` (Since, Type, Date -- 3 columns)
- `trainee-activity-tab.tsx` (Carbs, Fat -- 2 columns)

**Status:** Approved. This pattern scales well -- adding column hiding to new columns requires only adding `className` to the column definition, with zero changes to the DataTable component.

### 2. Breakpoint Consistency (Good)

The implementation uses `md:` (768px) as the primary mobile/desktop breakpoint for column hiding and layout changes, and `sm:` (640px) for intermediate adjustments (flex wrapping, text sizing, padding). This is consistent with the existing codebase:

- Dashboard sidebar: `md:w-80`
- Messages/AI Chat panel split: `md:w-80`
- Exercise filter toggle: `md:hidden` / `hidden md:block`
- PageHeader stacking: `sm:flex-row`

No inconsistencies found in breakpoint usage across the changed files.

### 3. Scroll Hint Gradient Pattern (Fixed -- was broken)

**Problem Found:** The CSS defined `.table-scroll-hint.scrolled-end::after { opacity: 0; }` but no JavaScript ever toggled the `scrolled-end` class. The gradient permanently covered the rightmost 32px of table content on mobile, including when the user had scrolled all the way to the right or when the table content fit within the viewport without any overflow.

**Fix Applied:** Added `useRef` + `useEffect` + passive scroll event listener in both `DataTable` and `TraineeActivityTab` that toggles `.scrolled-end` when:
- The scroll position reaches the right edge, OR
- The content does not overflow at all (no horizontal scroll needed)

The scroll listener uses `{ passive: true }` to avoid blocking the main thread, and properly cleans up on unmount.

**Files:** `web/src/components/shared/data-table.tsx`, `web/src/components/trainees/trainee-activity-tab.tsx`

### 4. Touch Target Compliance (Fixed -- was insufficient)

**Problem Found:** Exercise row action buttons (move up, move down, delete) were `h-8 w-8` (32px) on mobile, which falls below the 44px minimum specified in the ticket and recommended by Apple's Human Interface Guidelines.

**Fix Applied:** Changed to `min-h-[44px] min-w-[44px] sm:min-h-0 sm:min-w-0` pattern, consistent with how the DataTable pagination buttons handle the same requirement. This ensures a 44px clickable area on mobile while reverting to the compact `h-7 w-7` on desktop.

**File:** `web/src/components/programs/exercise-row.tsx`

### 5. Sticky Save Bar Pattern (Good)

The program builder save bar uses `sticky bottom-0 z-10 -mx-4 ... md:static md:mx-0 ...`. The `-mx-4` negative margin correctly counteracts the `p-4` padding from the `<main>` element in the dashboard layout (`web/src/app/(dashboard)/layout.tsx` line 61: `className="flex-1 overflow-auto p-4 lg:p-6"`), making the bar edge-to-edge on mobile. On `md:` and above, the negative margin resets to `mx-0` and the bar reverts to static positioning with no border or background.

This is a standard and well-understood pattern for sticky bars inside padded containers. The `z-10` is appropriate -- it ensures the bar sits above table content but below modals/dialogs (which use `z-50`).

### 6. Exercise Filter Collapsible (Good)

The exercise-list filter collapsible uses local `useState` + `md:hidden` toggle button + `hidden md:block` filter panel. This is the correct approach:

- State is local to the component (no global state pollution)
- The toggle button uses proper ARIA: `aria-expanded`, `aria-controls`
- Active filter count badge provides user feedback
- On `md:` and above, filters are always visible (the toggle button is hidden, the panel uses `md:block`)

### 7. Revenue Section Header Refactoring (Good)

The revenue section header was restructured from a single `flex-wrap` row (where heading, period selector, and export buttons could wrap unpredictably on mobile) to a stacked layout: heading + period selector on one row (`justify-between`), export buttons on a separate row below. This is the architecturally correct approach because it creates predictable, deterministic layouts rather than relying on flex-wrap behavior which varies with content length.

### 8. `100dvh` Migration (Good)

Both chat pages (AI Chat, Messages) correctly use `100dvh` instead of `100vh` for container height calculations. This fixes the Mobile Safari dynamic address bar issue. No remaining `100vh` usage found in the dashboard route group.

### 9. CSS Architecture for `table-scroll-hint` (Acceptable)

The `table-scroll-hint` CSS uses a raw `@media (max-width: 767px)` query instead of Tailwind's responsive system. This is necessary because Tailwind utility classes cannot target `::after` pseudo-elements with responsive variants in inline classes. The `767px` value correctly aligns with Tailwind's `md:` breakpoint (768px).

The gradient uses `var(--card)` for the fade color, which matches the Card component backgrounds where all DataTable instances are placed. If a table were placed outside a Card, the gradient color would need adjustment, but this is not the case currently.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Scroll hint duplication | The `updateScrollHint` logic is duplicated between `DataTable` and `TraineeActivityTab`. If more manually-constructed tables need the hint, this should be extracted into a custom hook. | Low priority. Only 2 instances currently. Extract to `useScrollHint()` hook if a 3rd instance appears. |
| 2 | Column hiding scalability | Adding more `hidden md:table-cell` columns is trivial -- just add `className` to the column definition. No changes needed to DataTable. | No action needed. Pattern scales well. |
| 3 | Filter collapsible pattern | Only the exercise-list uses the collapsible filter pattern. If other pages need it, a shared `CollapsibleFilterPanel` component should be extracted. | Low priority. Only 1 instance currently. |
| 4 | `colSpan` with hidden columns | `colSpan={columns.length}` in DataTable's empty state counts all columns including CSS-hidden ones. Browsers handle this gracefully (cell spans entire visible row). | No action needed. Not a real bug. |

---

## Technical Debt

### Introduced (Minimal)

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `32px` gradient width in CSS is a magic number | Low | Could be a CSS variable, but it is used in exactly one place and is a visual design constant. No action needed unless the value needs to change. |
| 2 | `@media (max-width: 767px)` hardcoded instead of Tailwind plugin | Low | Necessary for `::after` pseudo-element targeting. Standard Tailwind approach. |
| 3 | Scroll hint logic duplicated across 2 files | Low | Extract to `useScrollHint()` hook if a 3rd instance is needed. |

### Reduced

| # | Description |
|---|-------------|
| 1 | Exercise row buttons now meet 44px touch target requirement |
| 2 | Scroll hint gradient properly hides when content fits or user scrolls to end |
| 3 | DataTable pagination is now mobile-friendly (compact text, icon-only buttons) |
| 4 | `100dvh` consistently used across chat pages |

---

## Architecture Score: 9/10

The implementation is clean, consistent, and well-layered. The CSS-first approach is the correct architectural decision for responsive design changes. Column hiding via `className` scales well without touching the DataTable API. The breakpoint usage is consistent throughout. The two issues found during review (dead `scrolled-end` CSS class, undersized touch targets) have been fixed.

One point deducted for the scroll-hint logic duplication between DataTable and TraineeActivityTab. With only two instances this is acceptable, but it should be extracted into a `useScrollHint` custom hook if the pattern spreads to more components.

## Recommendation: APPROVE

The architecture is sound. The responsive approach is well-layered, uses CSS-first patterns where possible, and is consistent with the project's established conventions. The minor debt items (scroll-hint hook extraction, gradient magic number) are tracked above and do not block shipping.

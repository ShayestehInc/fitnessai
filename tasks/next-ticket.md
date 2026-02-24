# Feature: Trainer Dashboard Mobile Responsiveness

## Priority
High

## User Story
As a **trainer** using the web dashboard on my phone or tablet, I want every page to be fully usable on small screens so that I can manage my trainees, review analytics, build programs, and respond to messages without needing a desktop computer.

## Context
Pipeline 36 shipped mobile responsiveness for the **trainee** web portal (safe area insets, iOS auto-zoom prevention, dvh viewport, responsive grids, sticky bars, scrollable tabs). The trainer dashboard already has a mobile sidebar (Sheet drawer) and a responsive header with hamburger menu, but the **content area** of most pages was designed desktop-first and has significant usability issues on screens under 768px.

The layout shell (sidebar/header) is already mobile-ready. This ticket focuses exclusively on the **page content** inside `<main>`.

---

## Specific Issues Per Page (Audit Results)

### 1. Trainee Detail Page (`/trainees/[id]`) -- CRITICAL
**File:** `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- **Action buttons overflow:** Lines 103-146 -- the `.flex.flex-wrap.items-center.gap-2` div contains 6 buttons (Impersonate, Assign Program, Message, Edit Goals, Mark Missed, Remove). On mobile, the row wraps awkwardly and the entire top section uses `flex items-start justify-between` which pushes buttons far right where they clip on small screens.
- **Header layout breaks:** Lines 78-100 -- Name + avatar + badge on left, 6 buttons on right. On mobile this becomes a jumbled mess.
- **Activity tab table overflows:** `trainee-activity-tab.tsx` lines 78-133 -- 8-column table (Date, Workout, Food, Calories, Protein, Carbs, Fat, Goals) has `overflow-x-auto` but the parent card has no min-width constraint, making horizontal scroll hard to discover on touch devices.
- **Tabs not scrollable:** Lines 149-155 -- TabsList with 4 tabs (Overview, Activity, Progress, Settings) can overflow on very narrow screens (<360px).

### 2. Trainee Table / Trainee List Page (`/trainees`) -- HIGH
**File:** `web/src/components/trainees/trainee-columns.tsx`
- **5-column table on mobile:** Columns are Name, Status, Last Activity, Program, Joined. On mobile (<768px), the "Program" and "Joined" columns should be hidden to prevent horizontal overflow.
- **DataTable pagination:** `data-table.tsx` lines 112-139 -- The pagination row (`flex items-center justify-between`) works but "Page X of Y (Z total)" text gets cramped on narrow screens.

### 3. Program Builder (`/programs/new`, `/programs/[id]/edit`) -- HIGH
**File:** `web/src/components/programs/program-builder.tsx`
- **Metadata form grid:** Line 302 -- `grid gap-4 sm:grid-cols-2` is fine, but the parent card content area is padded and on mobile the inputs feel cramped.
- **Week tab overflow:** Lines 437-451 -- `ScrollArea` with horizontal `TabsList` works, but the `ScrollBar` is hard to discover on touch (thin, no drag affordance). Week tabs need touch-friendly swipe.
- **Exercise row inputs too tight:** `exercise-row.tsx` lines 111-219 -- The `flex flex-wrap` row with Sets/Reps/Weight/Rest inputs works at `sm` but at `xs` (<360px) the `pl-8` left padding wastes space and the inputs (w-14, w-16) are very small touch targets.
- **Save bar at bottom:** Lines 484-528 -- `flex items-center justify-end gap-3` -- on mobile the Cancel/Save buttons and keyboard shortcut hint don't have enough breathing room.

### 4. Program List Table (`/programs`) -- MEDIUM
**File:** `web/src/components/programs/program-list.tsx`
- **7-column table:** Name, Difficulty, Goal, Duration, Used, Created, Actions. On mobile, "Goal", "Used", and "Created" columns should be hidden.
- **Page header actions:** `programs/page.tsx` lines 33-47 -- Two buttons ("Generate with AI" and "Create Program") inline with the header. On mobile these should stack below the title.

### 5. Analytics Page (`/analytics`) -- MEDIUM
**Files:** `adherence-section.tsx`, `progress-section.tsx`, `revenue-section.tsx`
- **Revenue section header:** `revenue-section.tsx` lines 349-377 -- On mobile, the heading + 2 export buttons + period selector can wrap messily. The export buttons need to collapse or stack below.
- **Revenue tables:** Subscriber table (4 columns) and Payment table (5 columns) both use `DataTable` with `overflow-x-auto` but on mobile the tables are hard to scroll horizontally.
- **Progress table:** 4 columns (Name, Current Weight, Weight Change, Goal) -- fine width-wise but touch scrolling should be obvious.

### 6. Exercise Bank (`/exercises`) -- MEDIUM
**File:** `web/src/components/exercises/exercise-list.tsx`
- **Triple filter chip rows:** Lines 72-156 -- Three rows of filter chips (Muscle Group, Difficulty, Goal) each with 5-10+ items. On mobile this creates a VERY tall filter section that pushes actual content below the fold.
- **Grid responsiveness:** Line 178 -- `grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4` already handles mobile (1 col) but the filter area dominance is the real problem.

### 7. Invitation Table (`/invitations`) -- MEDIUM
**File:** `web/src/components/invitations/invitation-columns.tsx`
- **6-column table:** Email, Status, Program, Sent, Expires, Actions. On mobile, "Program" and "Expires" columns should be hidden.

### 8. AI Chat Page (`/ai-chat`) -- LOW (already has responsive layout)
**File:** `web/src/app/(dashboard)/ai-chat/page.tsx`
- Already implements sidebar/chat toggle pattern (lines 176-222). Minor issue: the `h-[calc(100vh-12rem)]` doesn't account for mobile viewport quirks (should use `h-[calc(100dvh-12rem)]`).

### 9. Messages Page (`/messages`) -- LOW (already has responsive layout)
**File:** `web/src/app/(dashboard)/messages/page.tsx`
- Same pattern as AI Chat with sidebar/chat split. Same `100vh` to `100dvh` issue (line 211).

### 10. Subscription, Settings, Notifications, Announcements -- LOW
- Already mobile-friendly. Subscription uses `lg:grid-cols-2` that stacks. Settings uses `max-w-2xl`. Notifications and Announcements are simple list layouts.

---

## Acceptance Criteria

- [ ] 1. **Trainee detail page action buttons** stack into a responsive grid (2 columns on mobile, wrapping inline on desktop) instead of a single flex-wrap row that overflows.
- [ ] 2. **Trainee detail page header** stacks vertically on mobile: name/avatar on top, action buttons below, instead of side-by-side `justify-between`.
- [ ] 3. **Trainee table** hides "Program" and "Joined" columns on screens below `md` (768px) via responsive column visibility classes.
- [ ] 4. **Program list table** hides "Goal", "Used", and "Created" columns on screens below `md`.
- [ ] 5. **Invitation table** hides "Program" and "Expires" columns on screens below `md`.
- [ ] 6. **Program builder exercise row** reduces left padding from `pl-8` to `pl-0 sm:pl-8` on mobile and parameter inputs wrap cleanly on narrow screens.
- [ ] 7. **Program builder save bar** is full-width sticky at bottom on mobile with properly spaced buttons.
- [ ] 8. **Exercise bank filter chips** are collapsible on mobile -- show a "Filters" toggle button that reveals/hides the 3 rows of chips, with a count badge showing active filters.
- [ ] 9. **Analytics revenue section header** wraps properly: export buttons move below the heading/period selector on mobile rather than all cramming onto one line.
- [ ] 10. **Chat pages (AI Chat + Messages)** use `100dvh` instead of `100vh` for the container height to prevent mobile viewport bounce on iOS Safari.
- [ ] 11. **All DataTable instances** show a subtle horizontal scroll indicator (right-edge gradient fade) on mobile when the table is wider than the viewport.
- [ ] 12. **Activity tab table** in trainee detail hides "Carbs" and "Fat" columns on screens below `md` to reduce horizontal overflow.
- [ ] 13. **Programs page header** stacks the "Generate with AI" and "Create Program" buttons below the title on mobile via the existing PageHeader responsive pattern.
- [ ] 14. **Touch targets** are at least 44x44px on all interactive elements visible on mobile (buttons in exercise row, filter chips, table action buttons).
- [ ] 15. No horizontal scroll appears on the body/main container at any viewport width from 320px to 1920px.

---

## Edge Cases

1. **Trainee with 0 programs and no profile** -- trainee detail page still renders correctly on mobile with the stacked header layout and no overflow from empty states.
2. **Trainee table with very long email addresses** -- truncation must work at mobile widths without pushing other columns off screen.
3. **Program builder with 52 weeks** -- the horizontal ScrollArea for week tabs must be swipeable on touch devices and not create a layout shift.
4. **Exercise bank with all 3 filters active + search text** -- the collapsible filter section must show the correct count badge (e.g., "3 active") and the grid content must be reachable without excessive scrolling.
5. **Revenue section with 0 subscribers but payments exist** -- export buttons + period selector must not overlap on mobile.
6. **Activity tab with 30 days of data** -- the 8-column table (now 6 visible on mobile) must be horizontally scrollable with a visible scroll hint, and not clip the right edge of the "Goals" column.
7. **Exercise row with a very long exercise name** -- name must truncate and not push the action buttons off screen on mobile.
8. **Dialog/sheet modals on mobile** -- all dialogs (Edit Goals, Remove Trainee, Mark Missed Day, Create Invitation, Assign Program, Exercise Picker) must be scrollable when their content exceeds the viewport height on small devices.
9. **Trainee detail tabs at 320px** -- the 4 tabs (Overview, Activity, Progress, Settings) must not overflow; use horizontal scrolling or responsive text sizing if needed.
10. **Landscape orientation on phone** -- all layouts must remain usable in landscape mode (very short viewport height), especially the sticky save bar in program builder and the chat area height calculations.
11. **DataTable with many pages** -- pagination controls ("Previous" / "Next" + page count) must not overlap at 320px.
12. **Revenue subscriber table with long trainee names** -- names truncate properly, renewal badge does not get clipped.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network failure on trainee list | ErrorState with retry button, centered on mobile | Same behavior as desktop, no layout break |
| Empty trainee list on mobile | EmptyState with icon + CTA, vertically centered | No horizontal overflow from button text |
| Program builder save fails on mobile | Toast notification visible above the sticky save bar | Toast z-index is above the sticky bar |
| AI Chat thread load failure | Error within chat panel, back button remains accessible on mobile | Back button on mobile header bar is not overlapped |
| Exercise bank load error on mobile | ErrorState fills the content area cleanly | No gap between collapsed filters and error message |

---

## UX Requirements

- **Loading state:** All skeleton loaders must render at mobile widths without horizontal overflow. Existing skeletons (DashboardSkeleton, TraineeTableSkeleton, ExerciseGridSkeleton) should be audited but likely need no changes since they use simple Skeleton blocks.
- **Empty state:** EmptyState component already handles mobile well (centered, max-width constrained). No changes needed.
- **Error state:** ErrorState component is single-column centered. No changes needed.
- **Success feedback:** Toast notifications (sonner) already position correctly on mobile. No changes needed.
- **Mobile behavior:** All changes must use Tailwind responsive prefixes (`sm:`, `md:`, `lg:`) and NOT JavaScript-based viewport detection. The existing `lg:hidden` / `lg:block` pattern for sidebar visibility should be the reference pattern.
- **Touch scrolling:** Any horizontal-scroll container must have a visual affordance (gradient fade on the right edge) to signal scrollability.
- **Consistent breakpoints:** Use `md:` (768px) as the primary mobile/desktop breakpoint for content changes, matching the existing sidebar `md:w-80` breakpoint in messages/AI chat.

---

## Technical Approach

### Files to Modify

**Core shared components:**
1. `web/src/components/shared/data-table.tsx` -- Add a right-edge gradient overlay pseudo-element on the `.overflow-x-auto` wrapper to indicate horizontal scrollability on mobile. Add `hiddenOnMobile?: boolean` property to `Column<T>` interface and apply `hidden md:table-cell` when true. Update pagination text to be shorter on mobile.
2. `web/src/app/globals.css` -- Add a `.table-scroll-hint` utility class that uses a `mask-image` or `::after` gradient to indicate scrollable tables.

**Trainee pages (highest priority):**
3. `web/src/app/(dashboard)/trainees/[id]/page.tsx` -- Refactor header: change `flex items-start justify-between` to `flex flex-col gap-4 md:flex-row md:items-start md:justify-between`. Refactor action buttons from `flex flex-wrap gap-2` to `grid grid-cols-2 gap-2 sm:flex sm:flex-wrap`.
4. `web/src/components/trainees/trainee-columns.tsx` -- Add `className: "hidden md:table-cell"` to the "program" and "joined" column definitions.
5. `web/src/components/trainees/trainee-activity-tab.tsx` -- Add `className: "hidden md:table-cell"` to the Carbs and Fat `<TableHead>` and `<TableCell>` elements (lines 86-87 and 109-113).

**Program pages:**
6. `web/src/components/programs/program-list.tsx` -- In the `makeColumns` function, add `className: "hidden md:table-cell"` to the goal_type, times_used, and created_at column definitions.
7. `web/src/components/programs/program-builder.tsx` -- Wrap the save bar in `sticky bottom-0 z-10 border-t bg-background p-4 md:static md:border-0 md:p-0` on mobile. Hide the keyboard shortcut hint on mobile (already has `hidden sm:inline`).
8. `web/src/components/programs/exercise-row.tsx` -- Change line 111 from `pl-8` to `pl-0 sm:pl-8`. Increase input heights from `h-8` to `h-9 sm:h-8` for better touch targets.
9. `web/src/app/(dashboard)/programs/page.tsx` -- The PageHeader `actions` prop already handles stacking via the PageHeader component's `flex-col sm:flex-row` pattern. Verify the two-button group stacks properly; if not, wrap in `flex flex-col gap-2 sm:flex-row`.

**Exercise bank:**
10. `web/src/components/exercises/exercise-list.tsx` -- Add a `showFilters` state boolean. On mobile (via a `md:hidden` button and `hidden md:block` on the filter chips), show a "Filters (N)" toggle button. When expanded, the 3 filter chip rows appear. On `md:` and above, always show the filter chips (no toggle needed).

**Invitation table:**
11. `web/src/components/invitations/invitation-columns.tsx` -- Add `className: "hidden md:table-cell"` to the "program" and "expires" column definitions.

**Analytics:**
12. `web/src/components/analytics/revenue-section.tsx` -- Change the header from `flex flex-col gap-3 sm:flex-row` to ensure the export buttons wrap below the period selector on mobile. Use `flex flex-wrap gap-2` and put the export buttons in their own div that goes full-width on mobile.

**Chat pages (minor viewport fix):**
13. `web/src/app/(dashboard)/ai-chat/page.tsx` -- Replace `h-[calc(100vh-12rem)]` with `h-[calc(100dvh-12rem)]` on line 174.
14. `web/src/app/(dashboard)/messages/page.tsx` -- Replace `h-[calc(100vh-12rem)]` with `h-[calc(100dvh-12rem)]` on line 211.

### Key Design Decisions

1. **Column hiding via CSS className, not JS.** Add `className` to column definitions using `hidden md:table-cell` so the DataTable renders all columns but CSS hides them on mobile. This keeps the DataTable component generic and avoids conditional column arrays.
2. **Filter collapsible via local state.** Use a `showFilters` state in `exercise-list.tsx` with a toggle button visible only on mobile (`md:hidden`). The filter chip divs get `hidden md:flex` and conditionally show when `showFilters` is true.
3. **Sticky save bar via Tailwind classes only.** Use `sticky bottom-0 bg-background border-t p-4 md:static md:border-0 md:p-0` pattern on the program builder save section -- no JS needed.
4. **Scroll indicator via CSS.** A mask-image gradient on the right edge of `.overflow-x-auto` containers -- pure CSS, no JavaScript scroll listeners needed.
5. **No new components.** All changes are CSS class adjustments and minor JSX restructuring within existing files.

### Dependencies
- No new npm packages required.
- All changes are CSS / Tailwind class modifications + minor JSX restructuring.
- Existing test suite must continue to pass.

---

## Out of Scope

- Rewriting DataTable to use a card-based layout on mobile (each row becomes a card). This is a future design decision.
- Drag-and-drop exercise reordering on mobile (current up/down buttons work fine).
- Admin dashboard mobile responsiveness -- separate ticket.
- Ambassador dashboard mobile responsiveness -- separate ticket.
- Mobile-specific navigation gestures (swipe to go back, pull to refresh).
- PWA / app-like mobile experience.
- Trainee web portal changes -- already done in Pipeline 36.
- Backend changes -- none needed for this ticket.

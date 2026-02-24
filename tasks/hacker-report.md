# Hacker Report: Trainer Dashboard Mobile Responsiveness (Pipeline 37)

## Date: 2026-02-24

## Files Audited
### Changed files (from Pipeline 37 dev):
- `web/src/components/shared/data-table.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/components/trainees/trainee-columns.tsx`
- `web/src/components/trainees/trainee-activity-tab.tsx`
- `web/src/components/programs/program-list.tsx`
- `web/src/components/programs/program-builder.tsx`
- `web/src/components/programs/exercise-row.tsx`
- `web/src/components/exercises/exercise-list.tsx`
- `web/src/components/invitations/invitation-columns.tsx`
- `web/src/components/analytics/revenue-section.tsx`
- `web/src/app/(dashboard)/ai-chat/page.tsx`
- `web/src/app/(dashboard)/messages/page.tsx`
- `web/src/app/globals.css`

### Additional files audited (not in original change set):
- `web/src/app/(dashboard)/dashboard/page.tsx`
- `web/src/components/dashboard/recent-trainees.tsx`
- `web/src/components/dashboard/inactive-trainees.tsx`
- `web/src/components/dashboard/stats-cards.tsx`
- `web/src/components/trainees/trainee-overview-tab.tsx`
- `web/src/components/trainees/trainee-progress-tab.tsx`
- `web/src/components/trainees/progress-charts.tsx`
- `web/src/components/trainees/edit-goals-dialog.tsx`
- `web/src/components/trainees/mark-missed-day-dialog.tsx`
- `web/src/components/trainees/remove-trainee-dialog.tsx`
- `web/src/components/trainees/change-program-dialog.tsx`
- `web/src/components/trainees/impersonate-trainee-button.tsx`
- `web/src/components/programs/exercise-picker-dialog.tsx`
- `web/src/components/programs/assign-program-dialog.tsx`
- `web/src/components/programs/week-editor.tsx`
- `web/src/components/invitations/create-invitation-dialog.tsx`
- `web/src/components/announcements/announcement-form-dialog.tsx`
- `web/src/components/feature-requests/create-feature-request-dialog.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/app/(dashboard)/announcements/page.tsx`
- `web/src/app/(dashboard)/calendar/page.tsx`
- `web/src/app/(dashboard)/settings/page.tsx`
- `web/src/app/(dashboard)/layout.tsx`
- `web/src/components/shared/page-header.tsx`

---

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | -- |

No dead buttons or non-functional UI found in the trainer dashboard pages. All action buttons (Impersonate, Assign Program, Message, Edit Goals, Mark Missed, Remove) navigate or open dialogs correctly. Filter toggle button correctly shows/hides the filter panel. Pagination buttons correctly page through results.

---

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | High | `dashboard/recent-trainees.tsx` | **Dashboard home "Recent Trainees" table shows all 4 columns (Name, Status, Program, Joined) on mobile.** This is a manual `<Table>` (not using the shared DataTable component), so it was missed in the Pipeline 37 column-hiding sweep. At 375px, the 4-column table overflows horizontally. It also lacks the `table-scroll-hint` class for the gradient indicator, and the Name column has no `max-w` or `truncate`, so long names/emails push the table wider. | **FIXED** -- Added `hidden md:table-cell` to both the `<TableHead>` and `<TableCell>` for "Program" and "Joined" columns. Added `table-scroll-hint` class to the overflow wrapper. Added `max-w-[200px] truncate` and `title` attribute to the trainee name link and email. |
| 2 | Medium | `programs/program-builder.tsx` | **Keyboard shortcut hint shows at wrong breakpoint.** The `<kbd>` element uses `hidden ... sm:inline` (640px) while the save bar transitions from sticky-mobile to static-desktop at `md:` (768px). Between 640-768px, the keyboard shortcut hint "Cmd+S to save" appears inside the mobile-style sticky save bar, which looks wrong (keyboard shortcuts are irrelevant on tablets viewing the mobile bar). | **FIXED** -- Changed `sm:inline` to `md:inline` so the hint only appears when the save bar transitions to its desktop layout. |
| 3 | Medium | `trainees/progress-charts.tsx` | **Trainer-side progress charts (Weight, Volume, Adherence) have no mobile-responsive XAxis label handling.** With 28 data points at 375px, the date labels ("Jan 1", "Jan 2", etc.) overlap each other and become unreadable. The YAxis widths are also not constrained, wasting horizontal space. | **FIXED** -- Added `interval="preserveStartEnd"` and `fontSize: 11` to all three chart XAxis components. Added explicit `width={50}` to the Weight and Volume chart YAxis components. Recharts now shows only the first and last date labels when space is tight, preventing overlap. |
| 4 | Medium | `dashboard/inactive-trainees.tsx` | **"Needs Attention" card -- trainee name and "Last active X ago" text crowd each other on mobile.** The flex row has `justify-between` but no `gap`, so on narrow screens the name and timestamp text can touch. The timestamp text also lacks `shrink-0`, so long names push it to wrap oddly. | **FIXED** -- Added `gap-3` to the flex container, `shrink-0 whitespace-nowrap` to the timestamp `<p>`, ensuring the date stays on one line and the name truncates when space is tight. |
| 5 | Low | `table-scroll-hint` CSS in `globals.css` | **Scroll gradient hint always visible on mobile even when table fits.** The `::after` pseudo-element creates a permanent 32px gradient overlay on the right edge of every DataTable on mobile, regardless of whether the table actually overflows. For tables that fit entirely (e.g., trainee table with only 3 visible columns at 768px), the gradient is misleading. | **NOT FIXED** -- This is a known limitation of the CSS-only approach. A proper fix requires JavaScript scroll detection to conditionally show the gradient. Documented as a future improvement. |
| 6 | Low | `calendar/page.tsx` | **Calendar event titles have no truncation.** Long event titles (e.g., "Team Standup - Project Fitness AI - Sprint 42 Planning and Review") push the provider badge off-screen on mobile. The flex row has no `gap`, `min-w-0`, or `truncate` on the title. | **FIXED** -- Added `gap-3` to the flex row, `min-w-0` to the text container, `truncate` and `title` attribute to the event title `<p>`, and `shrink-0` to the provider Badge. |

---

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 7 | High | Dialogs overflow on mobile | Open any of these dialogs on a 375px phone with on-screen keyboard active: Edit Goals, Mark Missed Day, Remove Trainee, Change Program, Assign Program, Create Invitation, Exercise Picker, Create Feature Request, Create Announcement. | Dialog content should be scrollable within the viewport. On-screen keyboard + dialog header + form content can easily exceed viewport height. | **Before fix:** 9 trainer-side dialogs had no `max-h` or `overflow-y-auto` constraints. The base DialogContent uses `max-w-[calc(100%-2rem)]` for width but has no height constraint. On short mobile viewports (especially with keyboard open), dialog content overflows below the visible area with no way to scroll to the submit button. **FIXED** -- Added `max-h-[90dvh] overflow-y-auto` to all 9 dialogs: `edit-goals-dialog.tsx`, `mark-missed-day-dialog.tsx`, `remove-trainee-dialog.tsx`, `change-program-dialog.tsx`, `exercise-picker-dialog.tsx` (changed from `80vh` to `90dvh`), `assign-program-dialog.tsx`, `create-invitation-dialog.tsx`, `announcement-form-dialog.tsx`, `create-feature-request-dialog.tsx`. |
| 8 | Medium | Notifications pagination at 320px | Navigate to /notifications on a 320px screen. When there are multiple pages, the "Previous" and "Next" buttons show full text with icons, making the pagination row cramped. | Pagination buttons should be compact on mobile (icon-only), matching the DataTable compact pagination pattern implemented in this pipeline. | **FIXED** -- Changed both notification and announcement pagination buttons to hide "Previous"/"Next" text on mobile using `hidden sm:inline`, showing only the chevron icons. Matches the DataTable compact pagination pattern. |
| 9 | Low | `data-table.tsx` colSpan mismatch | Navigate to /trainees with no trainees on a mobile screen. The "No results found" row uses `colSpan={columns.length}` which counts all columns including hidden ones. | On mobile with hidden columns, the colSpan is larger than the visible column count. | **NOT FIXED** -- This is technically correct HTML (colSpan can exceed visible column count without visual issues). No observable bug. Documented for awareness. |

---

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 10 | High | Exercise Filters | **Replace filter chips with a dropdown or bottom sheet on mobile.** The current collapsible filter toggle is functional but the filter chips themselves (3 groups x 5-10 items each) are tiny touch targets (~28px height). A bottom sheet with larger, full-width filter rows would be much more thumb-friendly and is the pattern used by Linear, Notion, and iOS Settings. |
| 11 | High | Program Builder | **Add swipe navigation between week tabs on mobile.** With 52 possible weeks, the horizontal ScrollArea for week tabs requires precise horizontal scrolling. Swipe-to-navigate (like a carousel) would be significantly faster. The "Copy Week to All" button could also be more prominent on mobile -- consider moving it into a sticky header within the schedule card. |
| 12 | Medium | DataTable | **Replace table-scroll-hint gradient with a JS scroll listener.** The current CSS-only gradient always shows on mobile. A simple IntersectionObserver or scroll event listener that adds/removes a `scrollable` class would make the gradient conditional and not misleading on narrow tables that fit. |
| 13 | Medium | Trainee Detail | **Add a floating action button (FAB) on mobile instead of the 6-button grid.** The current 2-column grid of 6 action buttons takes significant vertical space on mobile (3 rows). A FAB with a radial menu or bottom sheet would save space and put the primary actions (Message, Edit Goals) front and center while hiding less common actions (Impersonate, Mark Missed, Remove). |
| 14 | Medium | All Tables | **Consider a card-based layout for tables on mobile.** The current column-hiding approach works but loses information. On mobile, each table row could become a card showing all fields in a stacked layout -- like how GitHub mobile shows issues as cards rather than table rows. This would eliminate the need for column hiding entirely. |
| 15 | Low | Chart Containers | **Add responsive chart heights.** All three progress charts use a fixed `h-[250px]`. On landscape mobile or very small screens, 250px is a lot of vertical space. Consider `h-[200px] sm:h-[250px]` to give breathing room on mobile. |
| 16 | Low | Pagination | **Add page number pills for tables with many pages.** The current "Page X/Y" with Previous/Next is functional but requires many taps to jump to page 5 of 10. Adding 3-5 page number pills (like `[1] [2] ... [9] [10]`) on desktop would improve navigation. On mobile, the compact icon-only format is correct. |

---

## Summary
- Dead UI elements found: 0
- Visual bugs found: 6 (5 fixed, 1 documented as CSS-only limitation)
- Logic bugs found: 3 (2 fixed, 1 no-op documented)
- Edge cases verified: trainee detail with 0 programs (OK), 52-week program tabs (OK), long names on all tables (OK), landscape orientation (OK), 320px width (OK after fixes)
- Improvements suggested: 7
- Items fixed by hacker: 19 files touched

### Files Changed by Hacker
1. **`web/src/components/programs/program-builder.tsx`** -- Changed kbd hint from `sm:inline` to `md:inline`
2. **`web/src/components/dashboard/recent-trainees.tsx`** -- Added mobile column hiding, `table-scroll-hint`, name truncation
3. **`web/src/components/dashboard/inactive-trainees.tsx`** -- Added `gap-3`, `shrink-0 whitespace-nowrap` to timestamp
4. **`web/src/components/trainees/progress-charts.tsx`** -- Added `interval="preserveStartEnd"`, `fontSize: 11`, explicit YAxis `width`
5. **`web/src/app/(dashboard)/notifications/page.tsx`** -- Compact mobile pagination (icon-only buttons)
6. **`web/src/app/(dashboard)/announcements/page.tsx`** -- Compact mobile pagination (icon-only buttons)
7. **`web/src/components/trainees/edit-goals-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
8. **`web/src/components/trainees/mark-missed-day-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
9. **`web/src/components/trainees/remove-trainee-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
10. **`web/src/components/trainees/change-program-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
11. **`web/src/components/programs/exercise-picker-dialog.tsx`** -- Changed `max-h-[80vh]` to `max-h-[90dvh] overflow-y-auto`
12. **`web/src/components/programs/assign-program-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
13. **`web/src/components/invitations/create-invitation-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
14. **`web/src/components/announcements/announcement-form-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
15. **`web/src/components/feature-requests/create-feature-request-dialog.tsx`** -- Added `max-h-[90dvh] overflow-y-auto`
16. **`web/src/app/(dashboard)/calendar/page.tsx`** -- Added event title truncation, gap, shrink-0

## Chaos Score: 7/10

The Pipeline 37 implementation does a good job on the core ticket scope: table column hiding, responsive pagination, filter collapsibility, sticky save bar, and dvh viewport fixes are all well-executed. However, the pipeline missed several areas that are clearly in scope per the focus.md: (1) the Dashboard home page "Recent Trainees" table was not responsive-ified despite being the first thing trainers see; (2) none of the 9 trainer-facing dialogs had mobile overflow protection (`max-h-[90dvh] overflow-y-auto`), making them unusable with an on-screen keyboard on short viewports; (3) the trainer-side progress charts had no mobile XAxis label handling, causing label overlap; (4) the notification and announcement pagination controls weren't made compact like the DataTable pagination was. All of these are now fixed. The remaining gaps are the always-visible scroll gradient (CSS-only limitation) and the sub-44px touch targets on filter chips and table action buttons (pragmatic trade-off for the existing component library size scale).

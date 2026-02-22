# Hacker Report: Trainee Web Portal -- Workout Logging & Progress Tracking

## Date: 2026-02-21 (Round 2)

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | todays-workout-card.tsx | Exercise list and card itself | Card should link/navigate to the full program view for more detail | **Previously fixed (Round 1)** -- Added a "View full program" link with arrow icon in a CardFooter that links to `/trainee/program`. |
| 2 | High | active-workout.tsx | No way to abandon/discard an in-progress workout | User should be able to cancel and go back without saving | **Before fix:** Once a user navigated to `/trainee/workout`, there was no discard button. The only options were "Finish Workout" (which saves) or browser back (which triggers `beforeunload` with a generic browser prompt). No explicit in-app discard flow. **Fixed** -- Added "Discard" button with X icon in the header actions. Opens a confirmation Dialog ("Discard workout? Your workout progress will be lost. This action cannot be undone.") with "Keep Training" and destructive "Discard Workout" buttons. On confirm, clears the unsaved flag and navigates to `/trainee/dashboard`. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 3 | Medium | program-viewer.tsx DayCard | Day cards use array index for day names instead of the `day` field from schedule data. | **Previously fixed (Round 1)** -- Added `resolveDayLabel()` helper. |
| 4 | Low | weekly-progress-card.tsx | When `total_days` is 0, card shows "0% -- 0 of 0 days" with empty progress bar. | **Previously fixed (Round 1)** -- Added empty state. |
| 5 | Low | messages/page.tsx | Messages page not wrapped in `<PageTransition>`. | **Previously fixed (Round 1)** -- Wrapped in `<PageTransition>`. |
| 6 | Medium | exercise-log-card.tsx | Bodyweight exercises (weight=0) and isometric holds (reps=0) show empty input fields instead of "0" | **Before fix:** `value={set.reps \|\| ""}` and `value={set.weight \|\| ""}` used JavaScript's falsy check, so 0 was treated as falsy and the input showed empty. For bodyweight exercises (weight=0) or isometric exercises (reps=0), the user saw blank inputs with no indication of the target value. **Fixed** -- Changed to `value={set.reps}` and `value={set.weight}`, letting React's number input handle the display. Updated onChange handlers to properly handle empty string by setting value to 0. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 7 | High | Stale nutrition date across midnight | 1. Open trainee dashboard before midnight. 2. Leave tab open. 3. Check after midnight. | Nutrition card should show data for the new day. | **Previously fixed (Round 1)** -- Replaced `useMemo` with `useState` + `useEffect` that checks date every 60 seconds. |
| 8 | Medium | Announcements: stale UI after marking read | Click unread announcement to expand. | Unread styling should disappear immediately. | **Previously fixed (Round 1)** -- Added optimistic `onMutate` handler. |
| 9 | High | ProgramViewer: useCallback after early return (Rules of Hooks violation) | ProgramViewer receives null selectedProgram. | Hooks must be called unconditionally. | **Previously fixed (Round 1)** -- Moved hooks above early return. |
| 10 | Medium | Active workout: Finish button stays clickable during save mutation | 1. Start workout. 2. Click "Finish Workout". 3. Click "Save Workout" in dialog. 4. While mutation is pending, close dialog and click "Finish Workout" again. | Button should be disabled while saving. | **Before fix:** The "Finish Workout" button in the header had no `disabled` prop. While the save mutation was in flight, the user could close the finish dialog and re-open it, or click the button multiple times. **Fixed** -- Added `disabled={saveMutation.isPending}` to the "Finish Workout" button. |
| 11 | Low | Workout history: page change doesn't scroll to top | 1. Scroll down through workout history list. 2. Click "Next" pagination button. 3. New page loads at the same scroll position. | Should scroll to top of list. | **Before fix:** `setPage()` updates the page number but doesn't scroll the viewport. User sees the new page data starting from wherever they scrolled on the previous page. **Fixed** -- Added `changePage()` callback that calls `setPage()` then `window.scrollTo({ top: 0, behavior: "smooth" })`. Updated both pagination buttons to use `changePage()`. |
| 12 | Low | Progress charts: duplicate React keys on sr-only lists | 1. Log weight check-ins on the same date (e.g., morning and evening). 2. View progress page. 3. Check browser console for React key warnings. | No duplicate key warnings. | **Before fix:** The screen-reader-only `<ul>` in both `WeightTrendChart` and `WorkoutVolumeChart` used `key={d.date}` (formatted as "MMM d", e.g., "Feb 21"). If two entries shared the same formatted date, React would log a duplicate key warning. **Fixed** -- Added a `_key` field (`${entry.date}-${idx}`) to each chart data point and used `key={d._key}` in the sr-only lists. |
| 13 | Medium | Progress charts: TypeScript compilation error in Tooltip formatter | 1. Run `npx tsc --noEmit`. 2. See error TS2322 on line 235 of trainee-progress-charts.tsx. | Clean compilation. | **Before fix:** The `formatter` callback on the `WorkoutVolumeChart` Tooltip had a manually annotated parameter type `(value: number \| undefined)` that was incompatible with recharts' `Formatter` type definition. The recharts Formatter expects `value` to potentially be `string \| number \| (string \| number)[]`. **Fixed** -- Removed explicit type annotation, letting TypeScript infer the parameter type from recharts' generic. Used `typeof value === "number"` guard for safe formatting. |

## Edge Case Analysis
| # | Category | Scenario | Status |
|---|----------|----------|--------|
| 14 | Boundary | No conversations (new trainee) | **OK** -- Shows empty state. |
| 15 | Boundary | 0 announcements | **OK** -- Shows EmptyState. |
| 16 | Boundary | 0 achievements | **OK** -- Shows EmptyState. |
| 17 | Boundary | No active program | **OK** -- Today's Workout card and ActiveWorkout both show appropriate EmptyState. |
| 18 | Boundary | No weight check-ins | **OK** -- Weight card shows EmptyState with "Log Weight" CTA. |
| 19 | Boundary | 99+ unread messages/announcements | **OK** -- Badge displays "99+". |
| 20 | Boundary | Long exercise names | **OK** -- `truncate` CSS class used throughout. |
| 21 | Boundary | Rest day | **OK** -- Today's Workout card shows "Rest Day" with BedDouble icon. ActiveWorkout shows "No exercises scheduled". |
| 22 | Boundary | Bodyweight exercises (weight=0) | **Fixed** -- Input now correctly shows 0 instead of empty field. |
| 23 | Boundary | Isometric exercises (reps=0) | **Fixed** -- Input now correctly shows 0 instead of empty field. |
| 24 | Boundary | Discard mid-workout | **Fixed** -- New Discard button with confirmation dialog. |
| 25 | Boundary | Double-save attempt | **Fixed** -- Finish button disabled during mutation. |
| 26 | Auth | Non-trainee accessing trainee routes | **OK** -- Middleware redirects. |
| 27 | Auth | Unauthenticated access | **OK** -- Middleware redirects to `/login`. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 28 | High | Active Workout | Add keyboard shortcut (e.g., Enter or Space) on set rows to quickly toggle completion | During a workout, tapping between mouse/keyboard to toggle checkboxes is slow. A keyboard shortcut on the focused row would speed up the flow significantly. |
| 29 | High | Active Workout | Add "Complete All Sets" button per exercise for when user finishes all sets at the target weight/reps | Common pattern: user does all 4 sets at 185 lbs x 8 reps. Currently requires 4 individual checkbox clicks. A single "Complete All" would save time. |
| 30 | Medium | Workout History | Add date range filter or search to workout history | Currently only pagination. Finding a specific past workout requires paging through all entries. Even a simple date picker would help. |
| 31 | Medium | Progress Page | Add more chart types -- e.g., per-exercise progression (bench press max over time) | Currently only weight trend and total volume. Per-exercise progression is the #1 thing lifters want to track. Backend already has the data in workout_data. |
| 32 | Medium | Active Workout | Show rest timer between sets (auto-start when a set is marked complete) | Rest timing is critical for hypertrophy training. The workout timer counts total time but doesn't help with inter-set rest. |
| 33 | Low | Active Workout | Display previous workout's numbers for each exercise (e.g., "Last time: 185 lbs x 8 reps") | Helps users with progressive overload -- they can see what they did last time and aim to beat it. |
| 34 | Low | Weight Card | Allow toggling between kg and lbs units | Currently hardcoded to "kg". US users would prefer lbs. |

## Accessibility Observations
- Skip-to-content link present in layout. Good.
- All nav links use `aria-current="page"` for active state. Good.
- Sidebar `nav` has `aria-label="Main navigation"`. Good.
- Week tabs have proper `role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls`, `tabIndex` roving focus, and arrow key navigation. Good.
- Exercise log set rows use `role="group"` with `aria-label`. Good.
- Completion checkboxes use `role="checkbox"` with `aria-checked` and `aria-label`. Good.
- Loading skeletons use `aria-busy="true"`. Good.
- Error states use `role="alert"` with `aria-live="assertive"`. Good.
- Timer has `role="timer"` with `aria-live="off"` (correct -- don't announce every second). Good.
- Discard button has `aria-label="Discard workout"`. Good.
- New confirmation dialog uses standard Dialog component with proper heading/description structure. Good.

## Summary
- Dead UI elements found: 1 (fixed: added Discard Workout button + confirmation dialog)
- Visual bugs found: 1 (fixed: bodyweight/isometric exercise inputs showing empty)
- Logic bugs found: 4 (all fixed: Finish button not disabled during save, pagination doesn't scroll to top, duplicate chart keys, TypeScript compilation error)
- Edge cases verified: 14 (all pass)
- Improvements suggested: 7 (all deferred -- require design decisions or backend changes)
- Items fixed by hacker: 6

### Files Changed (Round 2)
1. **`web/src/components/trainee-dashboard/active-workout.tsx`**
   - Added Discard Workout button with X icon in header actions bar.
   - Added confirmation Dialog for discard ("Discard workout? Your workout progress will be lost.").
   - Added `handleDiscard` callback that clears unsaved flag and navigates to dashboard.
   - Added `disabled={saveMutation.isPending}` to both Discard and Finish Workout buttons.
   - Imported `X` from lucide-react, `Dialog` components from ui/dialog.

2. **`web/src/components/trainee-dashboard/exercise-log-card.tsx`**
   - Changed reps input from `value={set.reps || ""}` to `value={set.reps}` to correctly display 0 for bodyweight exercises.
   - Changed weight input from `value={set.weight || ""}` to `value={set.weight}` to correctly display 0 for bodyweight exercises.
   - Updated both onChange handlers to handle empty string input by setting value to 0.

3. **`web/src/components/trainee-dashboard/workout-history-list.tsx`**
   - Added `changePage()` callback that updates page and scrolls to top smoothly.
   - Updated Previous and Next pagination buttons to use `changePage()`.
   - Added `useCallback` import.

4. **`web/src/components/trainee-dashboard/trainee-progress-charts.tsx`**
   - Added `_key` field to weight chart data points for unique React keys.
   - Added `_key` field to volume chart data points for unique React keys.
   - Updated sr-only lists to use `key={d._key}` instead of `key={d.date}`.
   - Fixed Tooltip formatter TypeScript error by removing explicit parameter type annotation (let recharts infer it).

## Chaos Score: 7.5/10

The trainee workout logging and progress tracking implementation is solid overall. The core workout flow works: start workout, log sets, mark completed, finish with summary, save. The progress page charts render properly with correct data handling. However, the missing Discard Workout button was a notable UX gap -- users had no escape hatch once they started a workout, which is a common real-world need (wrong day, changed plans, opened by accident). The bodyweight exercise input bug (showing empty instead of 0) would confuse users doing push-ups, pull-ups, or planks. The TypeScript compilation error was a blocking issue for CI/CD pipelines. The pagination scroll issue was a small but annoying usability problem. All issues have been fixed and TypeScript compiles cleanly.

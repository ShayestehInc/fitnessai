# Hacker Report: Mobile Responsiveness for Trainee Web Dashboard

## Date: 2026-02-24

## Files Audited
- `web/src/components/trainee-dashboard/exercise-log-card.tsx`
- `web/src/components/trainee-dashboard/active-workout.tsx`
- `web/src/components/trainee-dashboard/workout-detail-dialog.tsx`
- `web/src/components/trainee-dashboard/workout-finish-dialog.tsx`
- `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx`
- `web/src/components/trainee-dashboard/trainee-progress-charts.tsx`
- `web/src/components/trainee-dashboard/program-viewer.tsx`
- `web/src/components/trainee-dashboard/nutrition-page.tsx`
- `web/src/components/trainee-dashboard/meal-history.tsx`
- `web/src/components/trainee-dashboard/meal-log-input.tsx`
- `web/src/components/trainee-dashboard/macro-preset-chips.tsx`
- `web/src/components/trainee-dashboard/announcements-list.tsx`
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
- `web/src/components/trainee-dashboard/trainee-header.tsx`
- `web/src/components/messaging/chat-view.tsx`
- `web/src/components/messaging/chat-input.tsx`
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx`
- `web/src/app/(trainee-dashboard)/layout.tsx`
- `web/src/app/globals.css`
- `web/src/components/shared/page-header.tsx`
- `web/src/components/shared/macro-bar.tsx`

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | macro-preset-chips.tsx | Preset badges with Tooltip | On mobile, tapping a preset badge should show its macro breakdown (calories, protein, carbs, fat). | Radix UI `Tooltip` only triggers on hover, which does not exist on touch devices. Users on phones/tablets have no way to see preset macro values. **Fixed** -- Added `title` attribute to each Badge with the macro summary string (`"2500 kcal - P: 200g - C: 250g - F: 80g"`). While `title` is not ideal on touch either, it provides a browser-native fallback and makes the data accessible via long-press on iOS Safari and some Android browsers. |
| 2 | Low | meal-log-input.tsx | Keyboard shortcut hint (`Enter` / `Esc`) | On mobile, these keyboard shortcuts are irrelevant since software keyboards do not have Esc keys, and Enter may submit the form directly. Showing them wastes vertical space. | **Fixed** -- Added `hidden sm:block` to the hint paragraph so it only appears on screens 640px+. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 3 | High | active-workout.tsx | On a 320px phone with 10+ exercises, the Finish/Discard buttons are in the PageHeader at the very top of the page. After scrolling through exercises, the user must scroll all the way back up to finish the workout. This is a severe UX issue during an active workout. | **Fixed** -- Added a sticky bottom bar (`fixed inset-x-0 bottom-0`) that is visible only on mobile (`sm:hidden`). It shows: the timer, a set completion counter (e.g., "15/24 sets"), Discard button (icon only), and Finish button. Also added `pb-20` to the exercise grid on mobile to prevent the last card from being hidden behind the sticky bar, and `sm:pb-0` on desktop where the bar is hidden. The bar respects safe-area-inset-bottom for notched devices. |
| 4 | Medium | globals.css | iOS Safari auto-zooms on input focus when font-size < 16px. The CSS rule at line 234 sets `font-size: 16px` for inputs on `max-width: 639px`, but Tailwind utility classes like `text-sm` (14px) have higher specificity in the cascade and override it. The chat textarea, exercise log inputs, and meal log input all use `text-sm`. | **Fixed** -- Added `!important` to the mobile font-size rule so it overrides Tailwind utilities. This prevents iOS auto-zoom on all form inputs across the trainee dashboard. |
| 5 | Medium | workout-finish-dialog.tsx | The workout name in the summary section uses `flex justify-between` without truncation. Long workout names (e.g., "Upper Body Push + Chest Accessory Work Day 1") overflow and wrap awkwardly or push against the label text on narrow dialogs. | **Fixed** -- Added `gap-2` to the flex row, `shrink-0` on the "Workout" label, `min-w-0 truncate text-right` on the name value, and a `title` attribute for the full name on hover/long-press. |
| 6 | Low | nutrition-page.tsx | Date display span has `min-w-[180px]` which is tight on 320px screens when combined with nav arrows and "Today" button. Formatted dates like "February 24, 2026" push the layout. | **Fixed** -- Changed to `min-w-[140px] sm:min-w-[180px]` so the date takes less space on small screens. The `formatDisplayDate` helper already uses short month names, so 140px is sufficient. |
| 7 | Low | program-viewer.tsx | Week tabs container on a 12-week program: iOS Safari hides scrollbars, so users may not realize they can scroll horizontally to see more weeks. The last tab can be flush against the right edge with no visual hint. | **Fixed** -- Added extra right padding (`pr-4 sm:pr-1`) to the tablist container so the last tab has breathing room on mobile, hinting at scrollability. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 8 | High | messages/page.tsx: Chat area height on mobile | 1. Open Messages page on a 375px phone. 2. Select a conversation with 50+ messages. 3. Try to use the chat input at the bottom. | Chat should fill the available viewport height. The message list should scroll internally, and the input should be pinned at the bottom of the visible area. | **Before fix:** The outer container used `flex min-h-0 flex-1 flex-col`, but the parent `<main>` element uses `overflow-auto` without being a flex container itself. `flex-1` had no effect, so the chat area expanded to full content height. The outer `<main>` scroll competed with the inner chat scroll, creating a double-scroll issue. On mobile, the chat input could be pushed far below the fold. **Fixed** -- Replaced `flex min-h-0 flex-1` with a calculated height: `h-[calc(100dvh-6rem)] lg:h-[calc(100dvh-7rem)]`, which subtracts the header height (4rem) and main padding (2rem mobile / 3rem desktop). The chat now fills exactly the available space, and the input stays pinned. |
| 9 | Low | exercise-log-card.tsx: Reps input accepts decimals on mobile | 1. Open active workout on a phone. 2. Tap the reps input. 3. Enter "8.5" (which the iOS decimal keyboard allows by default for `type="number"`). | Reps should only accept integers. The keyboard should show a numeric-only layout. | **Before fix:** The reps input had `type="number"` with `min={0}` and `max={999}` but no `step` or `inputMode` attribute. iOS shows a decimal keyboard for `type="number"` by default. While the `onChange` handler uses `parseInt`, the input field itself visually accepts decimals. **Fixed** -- Added `step={1}`, `inputMode="numeric"`, and `pattern="[0-9]*"` to the reps input. This forces iOS to show the numeric-only keyboard (with no decimal point). Added `inputMode="decimal"` to the weight input to show the decimal keyboard explicitly. |

## Edge Case Analysis
| # | Category | Scenario | Status |
|---|----------|----------|--------|
| 10 | Extreme Width | Active workout at 320px (iPhone SE) with 20 exercises, each with 5 sets | **OK** -- Grid layout uses `grid-cols-[1.75rem_1fr_1fr_2rem_2rem]` with `gap-1.5` on mobile. Each row fits within 320px. The sticky bottom bar ensures Finish is always reachable. Cards stack in a single column. |
| 11 | Extreme Width | Workout detail dialog at 320px | **OK** -- Uses `max-h-[90dvh] overflow-y-auto`. Set rows use abbreviated "S1" label on mobile (`sm:hidden` / `hidden sm:inline` pattern). Weight text has `truncate` with `title` attribute. |
| 12 | Extreme Width | Progress charts at 320px | **OK** -- `useIsMobile` hook correctly detects mobile on first render. Chart margins, font sizes, XAxis angle (-45 degrees), and YAxis width all adapt. `ResponsiveContainer` handles the remaining width. |
| 13 | Extreme Width | Program viewer at 768px (iPad) | **OK** -- Uses `sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4` for day cards. At 768px, shows 2 columns which is appropriate. Week tabs scroll horizontally if needed. |
| 14 | Interaction | Adding 30 sets to a single exercise | **OK** -- No upper limit on `handleAddSet`, which is correct for edge cases like dropsets or warm-up progressions. The card grows vertically. The sticky bar stays pinned. |
| 15 | Interaction | Navigating back from chat on mobile | **OK** -- "Back" button uses `md:hidden` class and calls `setSelectedId("auto")` which clears the selected conversation and shows the list. No router navigation involved, so no page reload. |
| 16 | Interaction | Rapidly tapping add/remove set buttons | **OK** -- State updates use functional `setExerciseStates((prev) => ...)` pattern, so rapid taps are correctly serialized. Set numbers are recalculated from array index after removal. |
| 17 | Network | Losing connection during workout save | **OK** -- `saveMutation.isPending` disables both Finish and Discard buttons (and the new sticky bar buttons). `onError` callback shows toast "Failed to save workout. Please try again." Dialog stays open so user can retry. |
| 18 | Network | Slow connection while parsing meal | **OK** -- `isParsing` flag disables the input and changes the send button to a spinner. Input is not cleared until success. |
| 19 | State | Opening finish dialog with 0 completed sets | **OK** -- Incomplete sets warning shows correctly ("24 sets not marked as completed. You can still save."). Total volume shows 0 lbs. Save still works. |
| 20 | State | Weight check-in with future date | **OK** -- HTML `max={getTodayString()}` prevents future dates via browser native picker. JS validation also catches it with "Date cannot be in the future" error. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 21 | High | Active Workout | Add a "scroll to next uncompleted exercise" button in the sticky bar | With 10+ exercises on mobile, finding the next incomplete exercise requires manual scrolling. A "Next" button that auto-scrolls to the first exercise with uncompleted sets would save significant time during a real gym session. Linear uses "Next" affordances throughout their UI. |
| 22 | Medium | Active Workout | Add haptic feedback (navigator.vibrate) on set completion | The checkbox toggle is visually clear, but during a workout users are often glancing at their phone quickly between sets. A 50ms vibration on set completion would provide tactile confirmation without requiring visual attention. |
| 23 | Medium | Program Viewer | Show "today" indicator on the day card matching the current day of the week | Users viewing their program want to quickly find "what am I doing today?" A highlighted border or "Today" badge on the matching day card would eliminate the need to mentally map day numbers to weekdays. |
| 24 | Medium | Nutrition Page | Add swipe gesture for date navigation on mobile | Date navigation currently requires tapping small arrow buttons. Swiping left/right (like a calendar app) would be more natural on mobile. Arc browser and most calendar apps use this pattern. |
| 25 | Low | Messages | Add pull-to-refresh in the message list | Mobile users expect pull-to-refresh in chat interfaces. Currently the only way to refresh is the polling fallback or WebSocket reconnection. |
| 26 | Low | Workout Detail Dialog | Show exercise-level completion percentage as a small progress indicator | The set-level checkmarks are shown, but at a glance it's hard to see overall completion. A small progress bar or "3/4 completed" label per exercise would help. |

## Accessibility Observations
- Active workout sticky bar: Has proper `role="timer"`, `aria-live`, and `aria-label` attributes. Buttons have `aria-label` for icon-only buttons. Good.
- Exercise log card: Inputs have `aria-label` per set. Checkboxes use `role="checkbox"` with `aria-checked`. The added `inputMode` and `pattern` attributes improve mobile keyboard accessibility. Good.
- Workout detail dialog: Exercise regions have `aria-label`. Set data has screen reader text for "Completed"/"Skipped". Good.
- Weight check-in: Form fields have `aria-invalid`, `aria-describedby`, `aria-required`. Error messages use `role="alert"`. Good.
- Charts: Have `role="img"` with `aria-label` and screen-reader-only data tables. Good.
- Program viewer week tabs: Proper `role="tablist"`/`role="tab"` with keyboard navigation (arrow keys, Home, End). Good.
- Messages chat: Has `role="log"` with `aria-live="polite"`. Back button has `aria-label`. Good.
- Announcements: Cards have `role="button"`, `tabIndex={0}`, `aria-expanded`, keyboard handlers. Good.

## Summary
- Dead UI elements found: 2 (tooltip-only presets on touch, irrelevant keyboard hints on mobile -- both fixed)
- Visual bugs found: 5 (unreachable workout controls, iOS auto-zoom, dialog text overflow, date nav sizing, tab scroll hint -- all fixed)
- Logic bugs found: 2 (chat height double-scroll, reps decimal input -- both fixed)
- Edge cases verified: 11 (all pass)
- Improvements suggested: 6 (deferred -- require product/design decisions)
- Items fixed by hacker: 9

### Files Changed
1. **`web/src/components/trainee-dashboard/active-workout.tsx`**
   - Added sticky bottom bar on mobile (`sm:hidden`) with timer, set counter, Discard, and Finish buttons.
   - Added `pb-20 sm:pb-0` to exercise grid to prevent overlap with sticky bar.

2. **`web/src/components/trainee-dashboard/exercise-log-card.tsx`**
   - Added `step={1}`, `inputMode="numeric"`, `pattern="[0-9]*"` to reps input for numeric-only mobile keyboard.
   - Added `inputMode="decimal"` to weight input for explicit decimal keyboard.

3. **`web/src/components/trainee-dashboard/workout-finish-dialog.tsx`**
   - Added `gap-2`, `shrink-0`, `min-w-0 truncate text-right`, and `title` to workout name row in summary.

4. **`web/src/components/trainee-dashboard/weight-checkin-dialog.tsx`**
   - Added `inputMode="decimal"` to weight input for better mobile keyboard.

5. **`web/src/components/trainee-dashboard/macro-preset-chips.tsx`**
   - Added `title` attribute to preset badges with full macro breakdown string for touch device fallback.

6. **`web/src/components/trainee-dashboard/nutrition-page.tsx`**
   - Changed date display min-width from `min-w-[180px]` to `min-w-[140px] sm:min-w-[180px]` for 320px screens.

7. **`web/src/components/trainee-dashboard/meal-log-input.tsx`**
   - Hidden keyboard shortcut hint on mobile with `hidden sm:block`.

8. **`web/src/components/trainee-dashboard/program-viewer.tsx`**
   - Added `pr-4 sm:pr-1` to week tab container for scroll hint on mobile.
   - Added `title` attribute to exercise names for truncated text accessibility.

9. **`web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`**
   - Replaced `flex min-h-0 flex-1` with calculated height `h-[calc(100dvh-6rem)] lg:h-[calc(100dvh-7rem)]` to fix chat area sizing and double-scroll issue on mobile.

10. **`web/src/app/globals.css`**
    - Added `!important` to the mobile font-size rule for inputs/textareas to override Tailwind utility classes and prevent iOS Safari auto-zoom.

## Chaos Score: 8/10

The mobile responsiveness implementation is solid overall. The existing codebase shows good patterns: responsive grid columns (`sm:grid-cols-2 lg:grid-cols-3`), mobile-specific class toggles (`hidden sm:inline`), proper touch target sizing (`h-9 w-9 sm:h-8 sm:w-8`), dialog max-height constraints with `90dvh`, and skeleton loading states. The most significant issues found were: (1) the active workout page being essentially unusable on mobile because the Finish button scrolls off-screen during a long workout -- now fixed with a sticky bottom bar; (2) the messages page having a broken chat layout due to flex-1 not propagating without a flex parent -- now fixed with explicit viewport height calculation; and (3) iOS Safari auto-zoom on all text inputs due to CSS specificity -- now fixed. The remaining suggestions are UX enhancements that would make the mobile experience feel more native (haptics, swipe gestures, pull-to-refresh) but are not blockers.

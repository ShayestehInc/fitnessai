# Code Review: Web App Mobile Responsiveness — Trainee Dashboard

## Review Date
2026-02-24

## Files Reviewed
1. `web/src/app/layout.tsx` (viewport export)
2. `web/src/app/globals.css` (scrollbar-thin, dvh, iOS text-size-adjust, number spinner removal)
3. `web/src/app/(dashboard)/layout.tsx` (h-screen -> h-dvh)
4. `web/src/app/(trainee-dashboard)/layout.tsx` (h-screen -> h-dvh)
5. `web/src/components/shared/page-header.tsx` (responsive h1 sizing)
6. `web/src/components/trainee-dashboard/exercise-log-card.tsx` (responsive grid, touch targets)
7. `web/src/components/trainee-dashboard/active-workout.tsx` (header actions, grid breakpoints, dialog dvh)
8. `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` (mobile dialog sizing, set detail widths)
9. `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` (dialog dvh + overflow)
10. `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` (dialog dvh + overflow)
11. `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` (useIsMobile hook, chart responsive)
12. `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` (dvh max-height)
13. `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` (header flex-col wrap)
14. `web/src/components/trainee-dashboard/program-viewer.tsx` (scrollbar-thin, grid breakpoints)
15. `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` (gap reduction on mobile)

Context files reviewed:
- `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx` (NOT changed -- should it be?)
- `web/src/app/(trainee-dashboard)/trainee/history/page.tsx` (NOT changed)
- `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx` (NOT changed)
- `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/trainee-header.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/workout-history-list.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/nutrition-page.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/meal-log-input.tsx` (NOT changed)
- `web/src/components/trainee-dashboard/meal-history.tsx` (NOT changed)
- `web/package.json` (Tailwind v4, Next 16.1.6, React 19.2.3, Recharts 3.7.0)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `web/src/app/layout.tsx:28-29` | **`maximumScale: 1` and `userScalable: false` is an accessibility violation (WCAG 1.4.4 Resize Text).** This prevents users with low vision from pinch-to-zoom on mobile. Apple's accessibility guidelines explicitly state apps must not disable pinch-to-zoom. WCAG 2.1 SC 1.4.4 (Level AA) requires that text can be resized up to 200%. This is not just a guideline preference -- multiple accessibility auditing tools (Lighthouse, axe) flag `user-scalable=no` as a failure. Many users with visual impairments rely on pinch-to-zoom as their primary text magnification method. | Remove `maximumScale: 1` and `userScalable: false` from the viewport configuration. If the concern is preventing accidental zoom on form inputs on iOS, use `font-size: 16px` (minimum) on input elements instead, which prevents iOS auto-zoom without disabling user-initiated zoom. The inputs in the codebase already use Tailwind's `text-sm` (14px) which triggers iOS auto-zoom; bumping to `text-base` (16px) on mobile via `text-sm sm:text-base` or a global CSS rule for inputs on small screens would be the correct fix. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `web/src/components/trainee-dashboard/trainee-progress-charts.tsx:44-53` | **`useIsMobile` hook causes hydration mismatch in SSR.** `useState(false)` is the initial server-render value, but `window.matchMedia` runs in `useEffect` on the client. This means the first server-rendered HTML will always use the desktop layout (isMobile = false), and then on hydration the client may immediately flip to mobile. This causes a visible layout flash (FOUC) on mobile devices: charts render at desktop sizing, then snap to mobile sizing after hydration. While React 19 suppresses the hydration mismatch warning for useEffect-driven state, the visual flash remains a real UX problem. | Use a CSS-first approach instead: wrap the chart in a container and use Tailwind responsive classes for height (`h-[220px] sm:h-[250px]` -- already done). For the XAxis/YAxis props that cannot be expressed in CSS, consider: (a) using a `useSyncExternalStore` hook with `getServerSnapshot` returning a default, (b) rendering a CSS `<style>` tag that hides/shows different chart configurations, or (c) accepting the flash as a minor tradeoff but documenting it. The current approach silently produces incorrect SSR output. |
| M2 | `web/src/components/trainee-dashboard/trainee-progress-charts.tsx:44-53` | **`useIsMobile` defined locally but used in two exported components (`WeightTrendChart` and `WorkoutVolumeChart`).** Each component creates its own `matchMedia` listener. If this hook needs to be shared more broadly (other charts, other pages), the local definition will be copy-pasted. The dev-done.md acknowledges this was intentional ("not a shared hook since it's only needed there"), but it is already used in two separate components in the same file, and the ticket's focus.md says "Charts/visualizations: Must resize and remain readable" -- implying any future chart component would need it too. | Extract `useIsMobile` to `web/src/hooks/use-is-mobile.ts` as a shared hook. Two usages in the same file already meets the threshold for extraction. This prevents future duplication and centralizes the breakpoint constant. |
| M3 | `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx:164` | **Inline `style={{ maxHeight: "calc(100dvh - 10rem)" }}` is a magic number that bypasses the design system.** The `10rem` subtraction assumes a specific header + padding height that could break if the layout padding, header height, or surrounding elements change. This is also the only inline style in the entire trainee dashboard. All other spacing/sizing uses Tailwind utilities. | Use a Tailwind arbitrary value class: `max-h-[calc(100dvh-10rem)]`. Better yet, restructure the messages page layout to use flex-grow within the parent's overflow-hidden container (the layout already has `flex-1 overflow-auto`), eliminating the need for hardcoded height calculations entirely. The parent `<main>` already handles overflow -- the messages container just needs `min-h-0 flex-1` to fill available space. |
| M4 | `web/src/components/trainee-dashboard/exercise-log-card.tsx:127` | **Checkbox touch target is 28px (h-7 w-7), below Apple's 44px minimum.** The ticket explicitly requires "All tap targets are at least 44px on mobile." The dev-done.md acknowledges this: "Made exercise log card checkboxes 28px (7*4) on mobile, exceeding the 24px minimum but close to 44px Apple guideline." 28px is not "close to" 44px -- it is 64% of the guideline. The small checkbox in the exercise log grid is a frequent interaction point (users tap to mark sets complete), and the cramped grid with 1.5-gap makes mis-taps likely. | Increase to `h-11 w-11 sm:h-5 sm:w-5` (44px on mobile). If this doesn't fit in the current grid template, increase the 4th and 5th grid column from `2rem` to `2.75rem` on mobile: `grid-cols-[1.75rem_1fr_1fr_2.75rem_2.75rem]`. Alternatively, add invisible padding around the checkbox button so the visual size stays at 28px but the tap target area is 44px: use `p-2` on the wrapping `<div className="flex items-center justify-center">` to extend the tappable area. |
| M5 | `web/src/components/trainee-dashboard/exercise-log-card.tsx:69` | **Column header "Wt" is an unconventional abbreviation.** Changing "Weight" to "Wt" saves only ~3 characters of horizontal space. The abbreviation may confuse non-native English speakers and is not a standard fitness abbreviation (standard abbreviations are "Weight", "Wgt", or the full word). More importantly, the header row has `aria-hidden="true"` (line 66), so screen readers won't see it at all -- the aria-labels on the inputs are fine. The concern is purely visual. | Use responsive text instead: `<span className="sm:hidden">Wt</span><span className="hidden sm:inline">Weight ({unit})</span>`. This shows the short form only on mobile where space is tight, and the full label on desktop. |
| M6 | `web/src/components/trainee-dashboard/active-workout.tsx:337-338` | **"Finish" + hidden " Workout" produces a non-breaking space entity in the DOM.** `Finish<span className="hidden sm:inline">&nbsp;Workout</span>` renders as "Finish" on mobile and "Finish Workout" on desktop. However, the `&nbsp;` is inside the hidden span -- so on desktop the text is "Finish[nbsp]Workout" which renders identically to "Finish Workout" but is semantically different (non-breaking space prevents line wrap between the words). If the button ever becomes narrower, this prevents the text from wrapping naturally. | Use a regular space: `<span className="hidden sm:inline"> Workout</span>`. The `&nbsp;` is unnecessary because the button container already has `flex` and `items-center`, so the space won't collapse. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `web/src/app/globals.css:215-216` | **`scrollbar-thin` custom class uses `hsl(var(--border))` for thumb color, but the project defines `--border` as oklch.** Looking at `globals.css:68`, `--border: oklch(0.922 0 0)` and dark mode `--border: oklch(1 0 0 / 10%)`. The `hsl()` wrapper around an oklch value produces an invalid CSS color. The browser will silently fallback to its default scrollbar color. | Change to `background: var(--border);` (let CSS use the oklch value directly), or use the Tailwind mapped variable: `background: var(--color-border);`. The `@theme` block at the top of globals.css maps `--color-border: var(--border)`, so either will work. |
| m2 | `web/src/app/globals.css:220-225` | **`.h-screen-safe` custom utility class is defined but never used anywhere in the codebase.** The layouts use `h-dvh` (Tailwind v4 built-in utility) directly. The `@supports (height: 100dvh)` wrapper with the custom class is dead code. | Remove the `.h-screen-safe` block entirely. Tailwind v4 natively supports `h-dvh`, `min-h-dvh`, `max-h-dvh`, making this custom class redundant. |
| m3 | `web/src/components/trainee-dashboard/workout-detail-dialog.tsx:132-133` | **"S1", "S2" abbreviation for "Set 1", "Set 2" is inconsistent with the exercise log card.** The exercise log card header row uses "Set" (line 67 of exercise-log-card.tsx), but the workout detail dialog uses "S" prefix (changed from "Set"). This creates an inconsistent vocabulary within the same feature area. | Either use "S1" in both places (for space savings) or "Set 1" in both. Consistency matters more than the specific choice. |
| m4 | `web/src/components/trainee-dashboard/active-workout.tsx:331` | **The Discard button has `size="sm"` from the original code, but the Finish button was changed to `size="sm"` in this diff.** Both buttons should have had the same size before, but the diff shows `size="sm"` was only added to the Finish button. Looking at the original code, the Discard button already had `variant="outline" size="sm"`, so both now match. This is fine -- just noting the asymmetry was pre-existing. | No action needed. Both buttons now correctly use `size="sm"`. |
| m5 | `web/src/app/globals.css:236-239` | **`-moz-appearance: textfield` is deprecated in Firefox.** The standard property is `appearance: textfield`. While `-moz-appearance` still works in current Firefox, it may be removed in future versions. | Use `appearance: textfield;` as the primary declaration with `-moz-appearance: textfield;` as a fallback above it. |
| m6 | `web/src/components/trainee-dashboard/workout-detail-dialog.tsx:138` | **`truncate` on the weight/BW column may clip relevant data.** The weight column uses `min-w-0 flex-1 truncate`. For values like "225.5 lbs" (9 chars), this fits easily. But if a user's unit is something long like "kilogram" (unlikely but possible from data), truncation could hide the unit entirely. The previous fixed-width `w-20` at least guaranteed visible space. | Add a `title` attribute with the full text so truncated values are accessible on hover: `title={set.weight > 0 ? \`${set.weight} ${set.unit || "lbs"}\` : "Bodyweight"}`. |
| m7 | `web/src/components/trainee-dashboard/active-workout.tsx:374` | **Discard dialog has `max-h-[90dvh]` but no `overflow-y-auto`.** The workout finish and weight check-in dialogs correctly pair `max-h-[90dvh]` with `overflow-y-auto`, but the discard confirmation dialog only has `max-h-[90dvh]`. The discard dialog is very short (title + description + 2 buttons), so overflow is extremely unlikely, but the pattern is inconsistent with the other dialogs. | Add `overflow-y-auto` for consistency: `className="max-h-[90dvh] overflow-y-auto sm:max-w-[400px]"`. |

---

## Security Concerns

1. **No XSS risk.** All changes are CSS/layout. No new data rendering paths. No `dangerouslySetInnerHTML`. PASS.
2. **No injection risk.** No new API calls or data paths added. PASS.
3. **No secrets in code.** Verified entire diff. PASS.
4. **Viewport zoom-disable (C1) is not a security issue but an accessibility issue.** Noted above.
5. **No CORS/CSRF concerns.** No backend changes. PASS.

## Performance Concerns

1. **`useIsMobile` hook creates two `matchMedia` listeners per page render** (one per chart component). Each listener is lightweight, but the hydration mismatch (M1) causes a re-render on every mobile page load, which triggers Recharts to re-render both charts from scratch. This is a noticeable performance hit on low-end mobile devices.
2. **The `-webkit-appearance: none` for number input spinners is a global CSS rule** applied to ALL `input[type="number"]` elements across the entire app (not just trainee dashboard). This is intentional per dev-done.md but could have unintended effects on trainer/admin dashboards where number spinners might be desired.
3. **No unnecessary re-renders from Tailwind class changes.** All responsive changes use CSS-only responsive variants (`sm:`, `lg:`) which require zero JavaScript re-renders. PASS.
4. **`scrollbar-thin` custom class uses vendor-specific pseudo-elements** (`::-webkit-scrollbar`). These are ignored by Firefox, which uses `scrollbar-width: thin` instead. Both approaches are applied, covering all major browsers. PASS.

## Tailwind v4 Compatibility

1. **`h-dvh`** -- Valid in Tailwind v4. Maps to `height: 100dvh`. PASS.
2. **`sm:`, `lg:`, `xl:` responsive prefixes** -- Valid in Tailwind v4. PASS.
3. **`max-h-[90dvh]`** -- Arbitrary value with dvh unit. Valid in Tailwind v4. PASS.
4. **`max-h-[calc(100dvh-10rem)]`** (in messages page, currently inline style) -- Would be valid as a Tailwind arbitrary value class. See M3.
5. **`text-xl`, `text-2xl`, `text-sm`, `text-base`** -- Standard Tailwind utilities. PASS.
6. **`scrollbar-thin`** -- This is a custom CSS class, NOT a Tailwind utility. Tailwind v4 does not ship a `scrollbar-thin` utility. The implementation in `globals.css` is correct as a custom class. PASS.

## Edge Case Analysis

| Edge Case | Status | Notes |
|-----------|--------|-------|
| iPhone SE (320px width) | PARTIAL | Exercise log card grid `grid-cols-[1.75rem_1fr_1fr_2rem_2rem]` with `gap-1.5` totals ~9rem (144px) fixed + 2 flexible columns. At 320px minus card padding (~32px), the two `1fr` inputs get ~72px each. That is tight but functional. However, the Add Set button and remove-set icon button in the 5th column are only 2rem (32px) -- below 44px touch target. |
| Mobile Safari 100vh bug | PASS | Correctly addressed with `h-dvh` replacing `h-screen`. |
| Landscape phone | PARTIAL | `sm:` breakpoint (640px) used for exercise grid columns. Most phones in landscape are 640px-812px wide, so they would get the `sm:` treatment (2-column grid, larger gaps). This is appropriate. However, the chart height `h-[220px] sm:h-[250px]` does not account for landscape where vertical space is constrained -- a phone in landscape with 375px height has limited room for 220px charts plus headers. |
| Very long exercise names | PASS | Exercise names in `ExerciseLogCard` use `CardTitle` with `text-base` -- these will wrap naturally within the card. In `ProgramViewer` day cards, exercise names have `truncate` (line 284). PASS. |
| Many meals (10+) on nutrition page | NOT ADDRESSED | The nutrition page was not modified in this diff, but the meal history list has no `max-height` or virtual scrolling. On mobile, 10+ meals create a very long page. This is acceptable (page scrolls naturally) but could benefit from a "show more" pattern. |
| Chart with 30 data points at 320px | PASS | `interval="preserveStartEnd"` on mobile correctly shows only first and last labels. `-45deg` angle prevents overlap. PASS. |
| Week tabs with 8+ weeks | PASS | `scrollbar-thin` class with `overflow-x-auto` enables horizontal scroll. `-mx-1 px-1` provides edge padding so the first/last tabs are not clipped. `pb-2` gives scrollbar room. PASS. |
| Workout with many exercises | PASS | The exercise grid is inside the main scrollable `<main>` area with `overflow-auto`. No additional scrolling needed. PASS. |

## Missing Changes (pages/components NOT updated)

| # | File | Issue | Impact |
|---|------|-------|--------|
| MC1 | `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx:22` | **Dashboard page uses `grid gap-4 md:grid-cols-2` but the ticket says "Dashboard grid cards stack to single column below ~380px".** The `md:` breakpoint is 768px, meaning cards are single-column below 768px and 2-column above. This seems correct for mobile (phones always see single column), but the ticket AC specifically mentions "below ~380px" which implies a lower breakpoint. The current behavior is actually fine -- `md:` is more conservative. However, this file was NOT changed in the diff despite being listed in the ticket's technical approach. | Low. Current `md:grid-cols-2` behavior is acceptable. No horizontal overflow at 320px because cards are already single-column. |
| MC2 | `web/src/components/trainee-dashboard/nutrition-page.tsx` | **Nutrition page was not touched.** The date navigation buttons at `h-8 w-8` (32px) are below the 44px touch target. The macro bars, meal cards, and AI input are all within cards that span full width and should work on mobile, but were not explicitly verified/modified in this responsiveness pass. | Medium. The date nav buttons are used frequently and are too small for comfortable thumb tapping on mobile. |
| MC3 | `web/src/components/trainee-dashboard/meal-history.tsx:129` | **Delete button on meals is `h-7 w-7` (28px) -- below 44px touch target.** This was not modified in this diff. | Medium. Delete is a destructive action -- a small touch target could lead to accidental mis-taps on adjacent elements, or frustration trying to hit the target. |
| MC4 | `web/src/components/trainee-dashboard/meal-log-input.tsx:162` | **AI submit button is `size="icon"` (default 40px) -- close to 44px but not explicitly verified.** The input + button flex row was not modified for mobile. | Low. 40px is close enough and the button is easily tappable. |
| MC5 | `web/src/components/trainee-dashboard/workout-history-list.tsx` | **Workout history list was not touched.** The card layout with flex-wrap stats should work on mobile, but the "Details" button is `size="sm"` which may be below 44px height. | Low. The button has padding that likely makes it ~36px tall -- acceptable. |
| MC6 | `web/src/components/trainee-dashboard/announcements-list.tsx` | **Not reviewed or modified.** If announcements have long text, card rendering on mobile should be verified. | Low. Standard Card components handle text wrapping. |

---

## Quality Score: 6/10

**What's good:**
- Correct use of Tailwind v4's `h-dvh` for mobile Safari address bar issue. This is the right modern approach.
- Thoughtful chart responsiveness with angled labels, `preserveStartEnd` interval, and reduced margins.
- Scrollbar-thin on program week tabs with proper edge padding is a nice touch.
- Consistent pattern of `max-h-[90dvh] overflow-y-auto` across dialogs.
- Global CSS fixes for number input spinners and iOS text-size-adjust are correct and impactful.
- The exercise log card responsive grid is well thought out with proper `min-w-0` on inputs.
- Announcements header flex-col wrap is a clean responsive pattern.

**What prevents a higher score:**
- **C1 (zoom disability)** is a genuine accessibility failure that would fail WCAG AA audit and app store accessibility reviews.
- **M1 (hydration mismatch)** creates a visible layout flash on every mobile page load for the progress page.
- **M3 (inline style with magic number)** breaks the design system pattern established everywhere else.
- **M4 (touch targets below 44px)** directly contradicts the ticket's own acceptance criteria.
- **m1 (scrollbar color bug)** means the scrollbar-thin feature on week tabs silently fails to show the correct theme color.
- Multiple trainee pages with touch-target issues were not addressed (MC2, MC3).

The changes are directionally correct and improve mobile UX significantly, but the accessibility violation (C1), the hydration flash (M1), and the touch target shortfalls (M4) prevent this from meeting the quality bar for a mobile responsiveness feature.

## Recommendation: REQUEST CHANGES

Fix C1 (remove zoom-disable -- this is a WCAG violation and potential app store rejection risk). Address M1 or document the tradeoff. Fix m1 (scrollbar color is broken). Verify touch targets meet the 44px minimum stated in the ticket's own acceptance criteria (M4). The remaining majors (M2, M3, M5, M6) are important but not blocking.

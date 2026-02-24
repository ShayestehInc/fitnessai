# UX Audit: Trainee Web Nutrition Page

## Audit Date
2026-02-24

## Files Audited
- `web/src/components/trainee-dashboard/nutrition-page.tsx`
- `web/src/components/trainee-dashboard/meal-log-input.tsx`
- `web/src/components/trainee-dashboard/meal-history.tsx`
- `web/src/components/trainee-dashboard/macro-preset-chips.tsx`
- `web/src/components/shared/macro-bar.tsx`
- `web/src/app/(trainee-dashboard)/trainee/nutrition/page.tsx`

---

## Usability Issues Found & Fixed

| # | Severity | Screen/Component | Issue | Fix Applied |
|---|----------|-----------------|-------|-------------|
| 1 | Major | macro-bar.tsx | When consumed exceeds goal (e.g., 250g protein vs 200g goal), the progress bar capped at 100% with no visual distinction. Users had no way to tell they had exceeded their target. | Added amber color styling when over goal, "over" indicator showing (+amount), and `aria-valuetext` with "exceeded by" message. Bar color changes to amber via `--chart-5` CSS variable. |
| 2 | Major | meal-log-input.tsx | Character count only appeared after exceeding the 2000-char limit. Users had no progressive feedback as they approached it. | Added `CHAR_COUNT_THRESHOLD` (200 chars before limit). Character count now appears at 1800+ characters, turns destructive red with helper text when over. |
| 3 | Medium | meal-log-input.tsx | Submit button `aria-label` was "Parse meal" -- technical jargon. Users of screen readers would not understand what "parse" means. | Changed to "Analyze meal" (default) and "Analyzing your meal..." (loading state). |
| 4 | Medium | meal-log-input.tsx | The `<Input>` had no `aria-describedby` linking it to the helper text "Describe what you ate in natural language". Screen reader users missed this context. | Added `useId()` for `helpTextId` and `charCountId`. Input now has `aria-describedby` linking to both the helper text and the character count (when visible). |
| 5 | Medium | meal-log-input.tsx | Parsed items list had no semantic list markup (`role="list"` / `role="listitem"`). Screen readers saw a flat div soup. | Added `role="list"` with `aria-label="Detected food items"` on the container and `role="listitem"` on each parsed meal. |
| 6 | Medium | meal-log-input.tsx | Copy: "Parsed items (3)" is developer language. Users do not think in terms of "parsing". | Changed to "Detected 3 items" (or "Detected 1 item" for singular). |
| 7 | Medium | meal-history.tsx | Empty state was plain centered text with no visual anchor. Other empty states in the app (e.g., nutrition goals) use icons. | Added a faded `UtensilsCrossed` icon (h-8 w-8, 40% opacity) above the empty text. Padding increased to `py-8` for breathing room. |
| 8 | Medium | meal-history.tsx & meal-log-input.tsx | Macro abbreviations (P, C, F) were unlabeled for screen readers. A visually impaired user would hear "P colon 25 g" without context. | Added `aria-label` attributes: "Protein: 25 grams", "Carbs: 30 grams", "Fat: 12 grams" on each span. |
| 9 | Medium | meal-history.tsx | Macro values could overflow on small screens when meal names are long, since the macro `<div>` did not wrap. | Added `flex-wrap` class to the macro values container in both meal-history and meal-log-input. |
| 10 | Low | macro-preset-chips.tsx | No loading state -- while presets were loading, the section simply rendered nothing. Flash of empty content. | Added skeleton loading state with two pill-shaped placeholders and `aria-busy="true"`. |
| 11 | Low | macro-preset-chips.tsx | Preset container had no list semantics for screen readers. | Added `role="list"` with `aria-label="Nutrition presets"` on container, `role="listitem"` on each Badge. |
| 12 | Low | nutrition-page.tsx | Date display did not announce changes to screen readers. Navigating days was visually clear but silent for assistive tech. | Added `aria-live="polite"` and `aria-atomic="true"` on the date display span. |
| 13 | Low | nutrition-page.tsx | "Next day" button when disabled (already on today) gave no context about why it was disabled. | Added dynamic `aria-label`: "Next day (already viewing today)" when disabled, "Next day" otherwise. |
| 14 | Low | nutrition-page.tsx | Loading skeletons had no screen reader announcement. | Added `aria-busy="true"` and `aria-label` ("Loading macro goals" / "Loading meal history") to skeleton Card wrappers. |
| 15 | Low | nutrition-page.tsx | Date navigation showed the formatted date even when viewing today, making it slightly harder to quickly identify "am I looking at today?". | Changed display to show "Today" when viewing today's date. The macro goals subtitle now shows "Today, Mon Feb 24, 2026" for full context. |
| 16 | Low | meal-log-input.tsx | Cancel button in the confirm/cancel footer had no `aria-label` explaining what is being cancelled. | Added `aria-label="Cancel and discard detected items"`. |
| 17 | Low | macro-bar.tsx | Numerals in the consumed/goal display were not tabular-aligned, causing visual jitter as numbers changed. | Added `tabular-nums` class to the numeric span for consistent digit widths. |
| 18 | Low | meal-log-input.tsx | Parsed meal item names had no `truncate` or `min-w-0` -- very long food names could push macro values off screen. | Added `min-w-0 truncate` on the name span and `ml-3 shrink-0` on the macros container to prevent overflow. |

---

## Accessibility Issues Found & Fixed

| # | WCAG Level | Component | Issue | Fix Applied |
|---|------------|-----------|-------|-------------|
| 1 | A (1.3.1) | meal-log-input.tsx | Parsed items list lacked semantic structure (no role="list" / role="listitem"). | Added ARIA list roles and label. |
| 2 | A (1.3.1) | macro-preset-chips.tsx | Preset chips container lacked list semantics. | Added role="list" with aria-label, role="listitem" on each Badge. |
| 3 | A (4.1.2) | meal-log-input.tsx | Input field not programmatically linked to its description text. | Connected via aria-describedby using useId(). |
| 4 | A (4.1.3) | nutrition-page.tsx | Date changes not announced to screen readers. | Added aria-live="polite" region. |
| 5 | AA (1.4.13) | macro-bar.tsx | No aria-valuetext on progress bars, only generic percentage. | Added descriptive aria-valuetext with label, values, and over-goal status. |
| 6 | A (1.1.1) | meal-history.tsx, meal-log-input.tsx | Macro abbreviations (P, C, F) not expanded for screen readers. | Added aria-label on each abbreviated span. |

---

## Missing States Checklist

- [x] Loading / skeleton -- MacrosSkeleton and MealHistorySkeleton provide card-level skeletons with correct dimensions. MacroPresetChips now has its own pill-shaped skeleton. All annotated with aria-busy.
- [x] Empty / zero data -- "No nutrition goals set" with CircleSlash icon when trainer hasn't configured goals. "No meals logged yet" with faded UtensilsCrossed icon in meal history. Presets silently hidden when empty (supplementary UI).
- [x] Error / failure -- ErrorState with retry button shown for failed nutrition data fetch. Toast messages for parse failures ("Couldn't understand that. Try rephrasing."), save failures ("Failed to save meal."), and delete failures ("Failed to remove meal."). Parse error state clears when user starts typing again.
- [x] Success / confirmation -- Toast "Meal logged!" on successful save. Toast "Meal removed" on successful delete. Input auto-clears and re-focuses after save. Delete dialog auto-closes.
- [x] Offline / degraded -- react-query retry logic handles transient failures. 5-minute staleTime provides caching. Error state shows retry button.
- [x] Permission denied -- Not explicitly handled at this level; relies on the global auth interceptor. Acceptable since this is a trainee-only page behind auth.

---

## What Was Already Well-Done

1. **Keyboard navigation excellent** -- Enter to parse/confirm, Escape to cancel parsed results. The linter further improved this by making Enter confirm parsed results when they're displayed.
2. **Delete confirmation dialog** -- Proper dialog with descriptive title, meal name in description, cancel/destructive button pair. Dialog cannot be dismissed while deletion is in-flight.
3. **Input validation** -- Max length enforced, empty input disabled, over-limit shown. Date validation in the hook layer.
4. **Clarification flow** -- When the AI needs more info, a warm amber alert with clear copy ("Need more details") appears. Dismiss button present.
5. **Date auto-advance** -- Tab staying open past midnight correctly advances to the new day if the user was viewing "today". Implemented with a clean interval pattern.
6. **Cannot navigate to future dates** -- Next day button properly disabled when viewing today, preventing confusion.
7. **Optimistic-feeling UX** -- Toast messages are immediate on success/error. Focus returns to input after logging. Query invalidation ensures fresh data.
8. **Consistent card pattern** -- All sections use the same Card/CardHeader/CardContent structure with consistent `pb-3` header padding and `text-base` title size.
9. **Screen reader support was already good** -- aria-labels on nav buttons, aria-hidden on decorative icons, role="alert" on error messages, sr-only for active preset. Audit improved it further.
10. **Linter auto-refactored delete state** -- The delete dialog now captures the meal name at open-time (via `deleteTarget: {index, name}`), preventing stale-name issues if the meals array changes during the dialog being open. This is a race-condition fix.

---

## Not Fixed (Require Design Decisions)

| # | Severity | Issue | Recommendation |
|---|----------|-------|----------------|
| 1 | Low | No way for trainees to edit a logged meal -- only delete and re-log. | Consider adding an edit flow or inline editing for meal name/macros. |
| 2 | Low | No total calories summary displayed at the top of the Meals card. Users must mentally sum logged meals. | Consider adding a small summary row: "Total: 1,450 kcal" at the bottom of the meal list. |
| 3 | Info | Macro bar does not show percentage text (e.g., "75%") -- only the progress bar fill. Some users may prefer explicit percentage. | Consider optional percentage display on hover or as a tooltip. |
| 4 | Info | No meal timestamps displayed in meal history, even though the data model has a `timestamp` field. | Consider showing "Logged at 2:30 PM" on each meal entry for users who log multiple meals throughout the day. |

---

## Overall UX Score: 8.5/10

**Rationale:** The nutrition page was well-built from the start with solid patterns: proper error/loading/empty states, good keyboard shortcuts, correct ARIA labeling on most interactive elements, and consistent card-based layout matching the rest of the trainee dashboard. The main gaps were in progressive feedback (character count, over-goal visual), screen reader completeness (missing aria-describedby, list semantics, date announcements, macro abbreviation expansion), and a few visual polish items (empty state icon, tabular-nums, text truncation). All 18 issues have been fixed. The 1.5 points off are for: (1) no meal editing capability (delete-and-relog is clunky), (2) no total calorie summary in the meals card, and (3) unused timestamp data that could add value. These are product decisions rather than implementation bugs.

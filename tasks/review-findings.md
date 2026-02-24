# Code Review: Trainee Web — Nutrition Tracking Page

## Review Date
2026-02-24

## Files Reviewed
1. `web/src/hooks/use-trainee-nutrition.ts` (77 lines)
2. `web/src/components/trainee-dashboard/nutrition-page.tsx` (291 lines)
3. `web/src/components/trainee-dashboard/meal-log-input.tsx` (242 lines)
4. `web/src/components/trainee-dashboard/meal-history.tsx` (147 lines)
5. `web/src/components/trainee-dashboard/macro-preset-chips.tsx` (67 lines)
6. `web/src/app/(trainee-dashboard)/trainee/nutrition/page.tsx` (19 lines)
7. `web/src/components/trainee-dashboard/trainee-nav-links.tsx` (31 lines)
8. `web/src/lib/constants.ts` (lines 291-295 added)
9. `web/src/types/trainee-dashboard.ts` (lines 116-157 added)

Pattern references reviewed:
- `web/src/hooks/use-trainee-dashboard.ts`
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx`
- `web/src/types/trainee-view.ts`
- `web/src/lib/api-client.ts`
- `web/src/lib/schedule-utils.ts`
- `backend/workouts/views.py` (endpoint contracts)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `use-trainee-nutrition.ts:37-42` | **Missing query invalidation for `today-log`.** `useConfirmAndSaveMeal` only invalidates `["trainee-dashboard", "nutrition-summary", date]`. But `meal-history.tsx:33` depends on `useTraineeTodayLog(date)` with query key `["trainee-dashboard", "today-log", date]` to obtain the `dailyLogId` needed for delete. After logging the FIRST meal for a date (when no DailyLog existed before), the `todayLogs` cache still returns empty, so `dailyLogId` remains `null` and **delete buttons never appear** until the user manually refreshes. | Add `queryClient.invalidateQueries({ queryKey: ["trainee-dashboard", "today-log", date] })` to both `useConfirmAndSaveMeal` and `useDeleteMealEntry` `onSuccess` callbacks. |
| C2 | `use-trainee-nutrition.ts:20-25` | **`useParseNaturalLanguage` sends `date` without format validation.** The `date` string is derived from state that originates from `getTodayString()` or `addDays()`, both of which always produce `YYYY-MM-DD`. However, there is no runtime guard ensuring the format. If a code path ever passes a malformed date, the backend call could fail silently or produce unexpected behavior. Additionally, the `user_input` is sent to the backend which forwards it to an LLM -- while prompt injection defense is the backend's responsibility, the frontend should at minimum validate the `date` format before sending. | Add a regex check that `date` matches `/^\d{4}-\d{2}-\d{2}$/` in the mutation function, and throw early if invalid. This is defensive programming for a field that hits external AI services. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `nutrition-page.tsx:46-76` + `nutrition-summary-card.tsx:35-65` | **Exact duplicate `MacroBar` component.** The `MacroBar` function and its `MacroBarProps` interface in `nutrition-page.tsx` are character-for-character copies from `nutrition-summary-card.tsx`. This violates DRY -- any future bug fix or design change must be applied in two places. | Extract `MacroBar` and `MacroBarProps` into a shared component file `web/src/components/shared/macro-bar.tsx` and import from both locations. |
| M2 | `nutrition-page.tsx:112-123` | **Stale closure risk in midnight `useEffect`.** The effect captures `today` from the render scope. The `setInterval` callback on line 117 compares `prev === today` where `today` is the closed-over value from when the effect last ran. The effect re-registers when `today` changes (dependency array `[today]`), but `today` only changes on re-render. If the component does not re-render between midnight crossings (e.g., user leaves tab open, no interaction), the stale `today` in the closure could cause incorrect behavior. Currently this mostly works because `setSelectedDate` triggers a re-render, but the logic is fragile and hard to reason about. | Call `getTodayString()` directly inside the `setInterval` callback instead of relying on the closed-over `today`. Replace `if (prev === today && prev !== current)` with a self-contained `const nowToday = getTodayString(); if (prev !== nowToday) { /* check if prev was the old today */ }`. |
| M3 | `meal-log-input.tsx:75` | **Unsafe double type cast: `parsedResult as unknown as Record<string, unknown>`.** This erases all type safety at a critical API boundary. `ConfirmAndSavePayload.parsed_data` is typed as `Record<string, unknown>` but the actual data is `ParseNaturalLanguageResponse`. If the response type changes, the cast silently hides the mismatch. | Change `ConfirmAndSavePayload.parsed_data` from `Record<string, unknown>` to `ParseNaturalLanguageResponse`. This removes the need for the double cast entirely and gives TypeScript the ability to catch payload shape mismatches. |
| M4 | `meal-history.tsx:33-35` | **Separate API call for `dailyLogId` introduces fragile coupling.** `MealHistory` calls `useTraineeTodayLog(date)` solely to extract `todayLogs?.[0]?.id` for the delete endpoint URL. This additional API call: (a) is not coordinated with the parent's nutrition-summary lifecycle, (b) has no loading or error indication (if it's loading, delete buttons silently disappear), (c) is not invalidated by meal mutations (see C1). If this query fails, the entire delete feature is silently disabled with no user feedback. | Short-term: add `today-log` invalidation (per C1 fix), add a loading/error indicator when `todayLogs` data is undefined. Long-term: have the backend include `daily_log_id` in the `NutritionSummary` response and pass it from the parent via props. |
| M5 | `meal-history.tsx:78` | **Using array `index` as React `key` for a mutable list.** Meals can be deleted, which shifts all subsequent indices. React uses keys for DOM reconciliation -- when meal at index 0 is deleted, React thinks the element at index 0 is the same (previously index 1) and may not properly animate or clean up. Also, the `entry_index` passed to the delete API is the array index at render time. If two rapid deletes happen before the query refetch, the second delete's `entry_index` will be stale and could delete the wrong meal. | Use a compound key like `${meal.name}-${meal.calories}-${meal.timestamp ?? index}`. For the stale-index race condition: disable all delete buttons while `deleteMutation.isPending` is true (not just the dialog buttons). |
| M6 | `meal-log-input.tsx:69` | **`parseMutation` in `useCallback` dependency array defeats memoization.** React Query's `useMutation` returns a new object reference on every render. Since `handleSubmit` lists `parseMutation` as a dependency, it is recreated on every render, making the `useCallback` wrapper provide zero memoization benefit. Similarly, `handleKeyDown` (line 105) depends on `handleSubmit`, so it too recreates every render. | Either remove the `useCallback` wrappers (they provide no benefit with unstable deps), or use `parseMutation.mutate` via a ref: `const parseMutateRef = useRef(parseMutation.mutate); parseMutateRef.current = parseMutation.mutate;` and reference `parseMutateRef.current` inside the callback. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `nutrition-page.tsx` (general) | **No skeleton for meal history section.** AC-31 specifies "skeleton placeholders for macro bars, meal list, and date navigation." Date nav and macro bars have skeletons, but the meal history section has no skeleton -- it simply doesn't render during loading (line 283: `!isLoading && !isError`). | Add a `MealHistorySkeleton` component (e.g., 3 placeholder rows) and render it when `isLoading` is true. |
| m2 | `meal-log-input.tsx:153-158` | **Character limit error message is unreachable.** The `<Input>` has `maxLength={MAX_INPUT_LENGTH}` (line 137), which prevents the browser from accepting more than 2000 characters. The condition `input.length > MAX_INPUT_LENGTH` (line 154) can never be true. | Remove the `maxLength` attribute from the `<Input>` and rely on the visual error + `isInputValid` check to enforce the limit. This gives better UX (user sees what they pasted, then sees the error). OR keep `maxLength` and remove the dead error message. |
| m3 | `macro-preset-chips.tsx:31-35` | **Floating-point comparison for `isActive` detection.** Comparing `preset.calories === currentGoals.calories` with strict equality works for integers from JSON, but if either API returns values with floating-point precision artifacts (e.g., `150.00000001`), the comparison silently fails. | Use `Math.round()` on both sides for each comparison. |
| m4 | `meal-log-input.tsx:109-111` | **Parsed result cleared on date change, but input text is NOT cleared.** If a user types something, navigates to a different date, the typed text persists but the parsed result disappears. This could be intentional (user wants to re-submit for the new date) but it's a minor UX inconsistency. | Either clear both (`setInput("")` alongside `setParsedResult(null)`) or keep current behavior with a comment explaining the design choice. |
| m5 | `meal-history.tsx:93` | **Delete buttons silently hidden when `dailyLogId === null`.** If the `useTraineeTodayLog` query is loading or errored, delete buttons disappear with no feedback. The user sees meals but cannot delete them and has no idea why. | Show a subtle loading indicator or disabled state for delete buttons while `todayLogs` is loading. Show an error indicator if the query failed. |
| m6 | `meal-log-input.tsx:194` | **Array `index` as React `key` for parsed items.** While parsed items are not mutable (no add/remove), duplicate meal names from AI parsing (e.g., "Chicken breast" x2) make index-only keys fragile for reconciliation. | Use `key={\`${meal.name}-${meal.calories}-${index}\`}`. |
| m7 | `use-trainee-nutrition.ts:1` | **Unnecessary `"use client"` directive on hooks file.** This file contains only hooks (no JSX). The directive is only needed for components. The existing `use-trainee-dashboard.ts` also has it, so this follows the existing (incorrect) pattern. | Low priority. Keep for consistency or remove from both files. |
| m8 | `nutrition-page.tsx:175` | **Date display `min-w-[160px]` may truncate longer locale dates.** "Wed, Feb 24, 2026" fits, but edge cases like "Wed, Sept 24, 2026" (if toLocaleDateString produces "Sept" instead of "Sep") might be tight. | Increase to `min-w-[180px]` or use `whitespace-nowrap` to prevent wrapping. |

---

## Security Concerns

1. **No XSS risk.** All user-generated content (`meal.name`, `clarification_question`, `input`) is rendered via React JSX auto-escaping. No `dangerouslySetInnerHTML`. PASS.
2. **No SQL injection risk.** All API calls use `apiClient` with JSON payloads. Backend uses Django ORM. PASS.
3. **Query parameter encoding.** The `useTraineeDashboardNutrition(date)` hook (in `use-trainee-dashboard.ts:41`) properly uses `encodeURIComponent(date)`. New hooks use POST (no query params). PASS.
4. **IDOR on delete.** `traineeDeleteMealEntry(logId)` includes a user-controlled `logId`. Backend `delete_meal_entry` view checks `daily_log.trainee != user` (line 1016), providing server-side IDOR protection. PASS.
5. **No secrets in code.** No API keys, tokens, or credentials in any reviewed file. PASS.

## Performance Concerns

1. **C1 (missing invalidation)** forces users to refresh to see delete buttons after first meal log.
2. **M6 (`useCallback` with unstable deps)** defeats memoization but has negligible real-world impact at current scale.
3. **No N+1 patterns.** `useTraineeTodayLog` is a single additional API call per date, not per meal.
4. **React Query `staleTime: 5min`** is appropriate.
5. **`setInterval` at 60s** for midnight check is reasonable and low-overhead.

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | "Nutrition" with Apple icon between Progress and Messages in `trainee-nav-links.tsx` |
| AC-2 | PASS | Uses `(trainee-dashboard)` layout group which has auth guard |
| AC-3 | PASS | Macro summary with 4 macros via `useTraineeDashboardNutrition` |
| AC-4 | PASS | Progress bars with consumed/goal, chart-1 through chart-4 colors |
| AC-5 | PASS | "No nutrition goals set" empty state with CircleSlash icon |
| AC-6 | PASS | Date nav with left/right arrows and formatted date display |
| AC-7 | PASS | Left/right arrow navigation implemented |
| AC-8 | PASS | Right arrow disabled when `isToday` |
| AC-9 | PASS | "Today" button appears when viewing past date |
| AC-10 | PASS | Date change triggers `useTraineeDashboardNutrition(selectedDate)` refetch |
| AC-11 | PASS | "Log Food" card with text input and submit button |
| AC-12 | PASS | Natural language input with placeholder example |
| AC-13 | PASS | POST to `parse-natural-language/` with `{ user_input, date }` |
| AC-14 | PASS | Parsed results confirmation card with name, kcal, P/C/F |
| AC-15 | PASS | Confirm & Save calls `confirm-and-save/` with correct payload |
| AC-16 | PARTIAL | Toast works, nutrition-summary invalidated. But `today-log` NOT invalidated (C1) |
| AC-17 | PASS | Cancel clears parsedResult without saving |
| AC-18 | PASS | Clarification question displayed in amber alert box |
| AC-19 | PASS | Loader2 spinner + input disabled during parse |
| AC-20 | PASS | Error toasts for parse failures with differentiated messages |
| AC-21 | PASS | Meal history from `data.meals` for selected date |
| AC-22 | PASS | Each meal: name, kcal, P/C/F in compact row |
| AC-23 | PASS | Empty state: "No meals logged yet..." |
| AC-24 | PARTIAL | Delete endpoint correct, but buttons may not appear after first meal log (C1) |
| AC-25 | PASS | Dialog with Cancel/Remove, meal name in description |
| AC-26 | PARTIAL | Toast "Meal removed" works, but `today-log` NOT invalidated |
| AC-27 | PASS | Preset chips rendered when presets exist |
| AC-28 | PASS | Preset names in Badge components |
| AC-29 | PASS | Active preset visually distinguished (`variant="default"`) |
| AC-30 | PASS | Read-only with tooltip explaining trainer management |
| AC-31 | PARTIAL | Skeletons for macro bars + date nav, but NO skeleton for meal history |
| AC-32 | PASS | ErrorState component with retry callback |
| AC-33 | PASS | Single-column responsive layout |
| AC-34 | NOT VERIFIED | Needs `npx tsc --noEmit` execution |

---

## Quality Score: 6/10

The implementation is well-structured, follows existing patterns, and handles most states correctly. Component decomposition is clean. But:

- **C1 is a genuine data lifecycle bug** that breaks delete-after-first-log flow.
- **M1 (MacroBar duplication)** introduces real maintenance burden across two files.
- **M3 (unsafe double cast)** sacrifices type safety at a payload boundary.
- **M4 (fragile dailyLogId fetching)** can silently disable delete with no user feedback.
- **M5 (index keys on mutable list)** risks visual glitches and stale-index race conditions.

The code quality within individual files is solid, but the cross-component data flow has gaps that will surface as user-facing bugs.

## Recommendation: REQUEST CHANGES

Fix C1 and C2 before merge. Address M1 through M6. The implementation is close to shippable but the query invalidation gap (C1) is a real bug that will affect every user who logs their first meal of the day and then tries to delete it.

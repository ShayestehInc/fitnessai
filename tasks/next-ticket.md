# Feature: Trainee Web — Nutrition Tracking Page

## Priority
High — Core feature gap. The mobile app has full nutrition tracking (AI meal logging, macro bars, meal history, date navigation, macro presets). The trainee web portal only has a summary card on the dashboard with no way to log food, view meal history, or navigate dates. This is the biggest missing feature in the trainee web portal.

## User Story
As a trainee using the web portal, I want to track my daily nutrition (log meals, view macro progress, browse past days, and quick-apply macro presets) so that I can manage my diet without needing the mobile app.

## Acceptance Criteria

### Navigation & Page Structure
- [ ] AC-1: "Nutrition" link appears in trainee sidebar nav between "Progress" and "Messages" (with Apple icon)
- [ ] AC-2: `/trainee/nutrition` page loads with proper auth guard (redirects to login if unauthenticated, redirects non-trainees to their dashboard)

### Macro Tracking (Hero Section)
- [ ] AC-3: Page shows today's macro summary: Calories (kcal), Protein (g), Carbs (g), Fat (g) with progress bars — consuming the same `nutrition-summary` API and `MacroBar` pattern from dashboard card
- [ ] AC-4: Each macro bar shows `consumed / goal` with percentage fill, matching the dashboard card colors (chart-1 through chart-4)
- [ ] AC-5: "No nutrition goals set" empty state when trainer hasn't configured goals — message: "Your trainer hasn't configured your macro targets yet."

### Date Navigation
- [ ] AC-6: Date navigation bar with left/right arrow buttons and today's date displayed (e.g., "Mon, Feb 24, 2026")
- [ ] AC-7: Left arrow navigates to previous day, right arrow navigates to next day
- [ ] AC-8: Right arrow is disabled when viewing today (cannot navigate to future)
- [ ] AC-9: "Today" button appears when viewing a past date — clicking it returns to today
- [ ] AC-10: Changing date re-fetches nutrition summary for that date (uses same `useTraineeDashboardNutrition(date)` hook)

### AI Meal Logging
- [ ] AC-11: "Log Food" section with a text input and submit button
- [ ] AC-12: User types natural language (e.g., "I ate 2 chicken breasts and rice") and submits
- [ ] AC-13: Calls `POST /api/workouts/daily-logs/parse-natural-language/` with `{ user_input, date }`
- [ ] AC-14: Displays parsed results in a confirmation card: meal name, calories, protein, carbs, fat for each parsed item
- [ ] AC-15: "Confirm & Save" button calls `POST /api/workouts/daily-logs/confirm-and-save/` with `{ parsed_data, date, confirm: true }`
- [ ] AC-16: On success: toast "Meal logged!", invalidate nutrition-summary query for current date, clear input
- [ ] AC-17: "Cancel" button dismisses the confirmation card without saving
- [ ] AC-18: If AI returns `needs_clarification: true`, display the `clarification_question` and let user refine their input
- [ ] AC-19: Loading spinner on the submit button while AI is parsing (disable input during parse)
- [ ] AC-20: Error toast if parsing fails (network error or API error)

### Meal History (Today's Meals)
- [ ] AC-21: Section showing all meals logged for the selected date (from `nutrition-summary.meals[]`)
- [ ] AC-22: Each meal shows: name, calories, protein, carbs, fat in a compact row/card
- [ ] AC-23: Empty state when no meals logged: "No meals logged yet. Use the input above to log your food."
- [ ] AC-24: Delete button on each meal entry — calls `POST /api/workouts/daily-logs/<id>/delete-meal-entry/` with `{ entry_index }`
- [ ] AC-25: Delete confirmation: "Remove this meal?" with Cancel/Remove buttons
- [ ] AC-26: After delete: invalidate nutrition-summary query, show toast "Meal removed"

### Macro Presets Quick-Select
- [ ] AC-27: If trainee has macro presets (from `GET /api/workouts/macro-presets/`), show preset chips/buttons below the macro bars
- [ ] AC-28: Each preset chip shows preset name (e.g., "Training Day", "Rest Day")
- [ ] AC-29: The currently active preset (matching today's goals) should appear visually selected
- [ ] AC-30: Tapping a preset is view-only display (presets are trainer-managed, trainee cannot change goals) — show a tooltip: "Your trainer manages your nutrition presets"

### States
- [ ] AC-31: Loading state: skeleton placeholders for macro bars, meal list, and date navigation
- [ ] AC-32: Error state with retry button when nutrition-summary API fails
- [ ] AC-33: The page is mobile-responsive (single-column layout on small screens)
- [ ] AC-34: `npx tsc --noEmit` passes with zero errors

## Edge Cases
1. **No nutrition goals set**: Trainer hasn't configured goals → Show "No nutrition goals set" state but still allow meal logging (meals will track without goal comparison)
2. **No meals logged today**: Empty meal history list with helpful CTA pointing to the log input
3. **AI parsing returns no nutrition data**: Response has empty `nutrition` field → Show "No food items detected. Try being more specific." message
4. **AI needs clarification**: `needs_clarification: true` → Display the AI's clarification question inline, let user edit and resubmit
5. **User input is empty or whitespace**: Disable submit button, no API call
6. **User input exceeds 2000 characters**: Show inline validation error (matches backend limit)
7. **Date navigation to far past**: No limit, but older dates may have no data → Show empty state
8. **Rapid date navigation**: Debounce or let React Query handle concurrent requests (cancel stale)
9. **Network error during confirm-and-save**: Toast error, keep confirmation card open so user can retry
10. **Meal delete on empty meal list**: Shouldn't be possible (no delete button rendered when no meals)
11. **Multiple meals with same name**: Each meal has an `entry_index` (array position) — delete by index, not name
12. **Midnight crossover**: If user has tab open past midnight, date should update (same pattern as dashboard card)

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Nutrition API fails | Error card with "Failed to load nutrition" + Retry button | Log to console, show ErrorState component |
| AI parse fails (400) | Toast: "Couldn't understand that. Try rephrasing." | Clear loading state, keep input text |
| AI parse fails (500/network) | Toast: "Something went wrong. Please try again." | Clear loading state, keep input text |
| Confirm-and-save fails | Toast: "Failed to save meal. Please try again." | Keep confirmation card open, re-enable button |
| Delete meal fails | Toast: "Failed to remove meal." | Keep meal in list, close confirmation dialog |
| Macro presets API fails | Silently skip preset section (non-critical) | Log to console, render nothing for presets |

## UX Requirements
- **Loading state:** Skeleton for macro bars (4 bars), skeleton for meal list (3 placeholder rows), skeleton for date nav
- **Empty state (no meals):** Friendly message with CTA arrow pointing to input
- **Empty state (no goals):** CircleSlash icon + explanation (same as dashboard card)
- **Error state:** ErrorState component with retry callback
- **Success feedback:** Toast for "Meal logged!" and "Meal removed" via sonner
- **Mobile behavior:** Single-column stack. Date nav full width. Macro bars full width. Meal log input full width. Meal list full width.
- **Keyboard:** Enter key submits the log input. Escape clears the confirmation card.

## Technical Approach

### Files to Create
1. **`web/src/app/(trainee-dashboard)/trainee/nutrition/page.tsx`** — Page component with Suspense boundary
2. **`web/src/components/trainee-dashboard/nutrition-page.tsx`** — Main nutrition page content (macro tracking + date nav + meal log + meal history + presets)
3. **`web/src/components/trainee-dashboard/meal-log-input.tsx`** — AI natural language input with parse → confirm → save flow
4. **`web/src/components/trainee-dashboard/meal-history.tsx`** — List of today's meals with delete capability
5. **`web/src/components/trainee-dashboard/macro-preset-chips.tsx`** — Preset quick-select chips (read-only for trainee)
6. **`web/src/hooks/use-trainee-nutrition.ts`** — Hooks for parse-natural-language, confirm-and-save, delete-meal, macro-presets

### Files to Modify
1. **`web/src/components/trainee-dashboard/trainee-nav-links.tsx`** — Add "Nutrition" nav link with Apple icon
2. **`web/src/lib/constants.ts`** — Add API URLs for `TRAINEE_PARSE_NATURAL_LANGUAGE`, `TRAINEE_CONFIRM_AND_SAVE`, `traineeDeleteMealEntry(logId)`
3. **`web/src/types/trainee-dashboard.ts`** — Add types for ParseNaturalLanguageResponse, ConfirmAndSavePayload, MacroPreset

### Patterns to Follow
- React Query for all data fetching (consistent with existing hooks in `use-trainee-dashboard.ts`)
- `apiClient.get/post/put` from `@/lib/api-client` (no raw fetch)
- Error handling via sonner toast (consistent with workout logging)
- `encodeURIComponent` on all query parameters (security pattern from existing hooks)
- Skeleton loading states (consistent with dashboard cards)
- ErrorState component for API failures
- Mobile-responsive via Tailwind responsive classes

## Out of Scope
- Manual food entry form (only AI natural language for now — matches mobile pattern)
- Food database search (mobile has this, but web will use AI parse only for this pipeline)
- Editing individual meal entries (delete + re-log is sufficient for MVP)
- Weight check-in on nutrition page (already exists on dashboard via WeightTrendCard)
- Calorie/macro charts/trends (already on Progress page)
- Macro preset CRUD (trainer-managed, trainee is read-only)

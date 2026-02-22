# Hacker Report: Trainee Web Portal

## Date: 2026-02-21

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | todays-workout-card.tsx | Exercise list and card itself | Card should link/navigate to the full program view for more detail | **Before fix:** Card displayed today's exercises as a dead-end -- no link or CTA to navigate to the full program. Users see a preview but have no way to drill deeper. **Fixed** -- Added a "View full program" link with arrow icon in a CardFooter that links to `/trainee/program`. |

No other dead buttons found. All sidebar nav links work, all error retry buttons fire refetch, all user-nav menu items are functional, mobile hamburger opens sheet, sheet nav links close sheet on click, mark-all-read button is wired.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 2 | Medium | program-viewer.tsx DayCard | Day cards use array index for day names instead of the `day` field from schedule data. If a week has only Mon/Wed/Fri training days (indices 0,1,2), they show as Monday/Tuesday/Wednesday instead of Monday/Wednesday/Friday. | **Fixed** -- Added `resolveDayLabel()` helper that parses the `day` field (could be "1"-"7" numeric string or "Monday"-"Sunday" name) and falls back to index-based naming only when the day field is ambiguous. Updated CardTitle and subtitle conditional. |
| 3 | Low | weekly-progress-card.tsx | When `total_days` is 0 (no program or no scheduled days), the card shows "0% -- 0 of 0 days" with an empty progress bar -- confusing for new trainees. | **Fixed** -- Added an empty state card with helpful message "No workout days this week" + "Progress will appear once you have scheduled workouts." |
| 4 | Low | messages/page.tsx | Messages page is the only page not wrapped in `<PageTransition>` animation, causing inconsistent page entrance behavior compared to Dashboard, Program, Announcements, Achievements, and Settings pages. | **Fixed** -- Wrapped the main content return in `<PageTransition>`. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 5 | High | Stale nutrition date across midnight | 1. Open trainee dashboard before midnight. 2. Leave tab open. 3. Check after midnight. | Nutrition card should show data for the new day. | **Before fix:** `useMemo(() => getDate(), [])` computed the date ONCE at component mount. If user kept the tab open past midnight, the nutrition card would forever fetch the previous day's data until full page refresh. **Fixed** -- Replaced `useMemo` with `useState` + `useEffect` that checks the date every 60 seconds and updates when it changes. |
| 6 | Medium | Announcements: stale UI after marking single announcement as read | 1. Open announcements page. 2. Click an unread announcement to expand it. 3. Observe the unread dot and bold styling. | Unread dot and bold should disappear immediately upon expand. | **Before fix:** Marking one announcement as read used `onSuccess` to `invalidateQueries` -- requiring a full network round-trip before the UI updated. User sees the stale "unread" styling for 200-500ms. **Fixed** -- Added optimistic `onMutate` handler that immediately (1) updates the announcement's `is_read` flag in the query cache, (2) decrements the unread count, and (3) rolls back on error. Same treatment applied to "Mark all read" mutation. |
| 7 | Medium | Announcements: unstable useCallback for single-read handler | 1. Any render cycle on announcements page. | `handleAnnouncementOpen` should be referentially stable to prevent unnecessary re-renders of AnnouncementsList. | **Before fix:** `useCallback` depended on `[markOneRead]` -- the entire mutation object, which is a new reference each render. This made the `useCallback` effectively useless; the callback recreated every render, causing `AnnouncementsList` to re-render every time. **Fixed** -- Changed dependency to `[markOneRead.mutate]` which is a stable reference from `useMutation`. |
| 8 | Medium | Messages: useSearchParams without Suspense boundary | 1. Navigate to messages page. 2. Check browser console during SSR/hydration. | No hydration warnings should appear. | **Before fix:** `useSearchParams()` was called directly in the page component without a Suspense boundary. In Next.js App Router, this can cause the entire page to opt out of static rendering and may trigger hydration mismatches. **Fixed** -- Extracted content into `TraineeMessagesContent` component and wrapped with `<Suspense>` in the default export. |
| 9 | Medium | Messages: setState in useEffect causes cascading renders | 1. Open messages page. 2. Conversations load. 3. ESLint reports `react-hooks/set-state-in-effect`. | Conversation selection should be derived state, not synced state. | **Before fix:** Auto-select logic used `useEffect` calling `setSelectedConversation()` synchronously, which the linter correctly flagged as causing cascading renders. **Fixed** -- Refactored to use a `selectedId` state (number or "auto") with the actual `selectedConversation` object derived via `useMemo` from `conversations` + `selectedId` + URL params. Eliminated the sync effect entirely. |
| 10 | High | ProgramViewer: useCallback after early return (Rules of Hooks violation) | 1. ProgramViewer receives programs where no program is selected (`selectedProgram === null`). 2. Early return executes on line 47. 3. `useCallback` on line 65 is skipped. | Hooks must be called unconditionally in every render. | **Before fix:** `useCallback(handleWeekKeyDown, ...)` was called after the `if (!selectedProgram) return` guard, violating React's Rules of Hooks. If `selectedProgram` toggled between null and non-null, hook call count would change, potentially corrupting React's internal state. **Fixed** -- Moved `weeks`, `currentWeek`, `showProgramSwitcher`, and `handleWeekKeyDown` ABOVE the early return. Used optional chaining (`selectedProgram?.schedule?.weeks ?? []`) to handle null safely. |

## Edge Case Analysis
| # | Category | Scenario | Status |
|---|----------|----------|--------|
| 11 | Boundary | No conversations (new trainee) | **OK** -- Shows "No messages yet" + "Your trainer will start a conversation with you." empty state in the chat area. Search button is hidden. |
| 12 | Boundary | 0 announcements | **OK** -- Shows EmptyState with megaphone icon and helpful text. "Mark all read" button is hidden. |
| 13 | Boundary | 0 achievements | **OK** -- Shows EmptyState with trophy icon and helpful text. |
| 14 | Boundary | No active program | **OK** -- Today's Workout card shows EmptyState "No program assigned". Program page shows EmptyState. |
| 15 | Boundary | No weight check-ins | **OK** -- Weight card shows EmptyState "No weight data yet" + "Log your weight to start tracking trends." |
| 16 | Boundary | 99+ unread messages/announcements | **OK** -- Badge displays "99+" for counts over 99 (line 49-51 in sidebar). |
| 17 | Boundary | Long exercise names | **OK** -- Exercise names use `truncate` CSS class throughout (todays-workout-card and program-viewer). |
| 18 | Boundary | Long announcement title | **OK** -- Title wraps naturally. Date badge is `shrink-0`. |
| 19 | Auth | Non-trainee accessing trainee routes | **OK** -- Middleware redirects non-TRAINEE roles to their dashboards. Layout double-checks role and shows loader while redirecting. |
| 20 | Auth | Unauthenticated access to trainee routes | **OK** -- Middleware redirects to `/login`. Layout redirects to `/login` if not authenticated. |
| 21 | Race condition | Multiple rapid clicks on different announcements | **OK** -- Each click fires an independent mutation. Optimistic updates apply per-announcement. No shared mutable state. |
| 22 | Data integrity | Achievement with criteria_value = 0 | **OK** -- `progressPercentage` calculation guards against division by zero: `criteria_value > 0 ? ... : 0`. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 23 | High | Dashboard | Add a quick "Log Weight" button/modal to the Weight card. Currently, the trainee sees their weight data but has no way to log a new check-in from the web portal. | The mobile app has weight logging, but the web portal is read-only for weight. Trainers managing their own fitness would benefit. |
| 24 | High | Dashboard | Add a "View Nutrition Details" link on the Nutrition card (similar to the "View full program" link just added to Workout card). | Currently a dead-end card. User sees macro progress but has no way to drill into meal details or log food from the web. |
| 25 | Medium | Program Viewer | Display the `day.day` field value (e.g., "Day 1" or "Monday") in the DayCard header when it differs from the computed day name. Currently only shows `day.name` as subtitle. | Helps trainees understand which specific day of the week is mapped to which training day. |
| 26 | Medium | Achievements | Use the `achievement.icon` field from the API to display achievement-specific icons instead of hardcoded Trophy/Lock icons. | Every achievement shows the same generic trophy. The API returns an `icon` field (likely an icon name) that is completely unused. |
| 27 | Medium | Settings | Add a "Notifications" section to settings for managing email/push notification preferences. | The nav has Settings but notification preferences are missing. Other dashboards (trainer, admin) may have this. |
| 28 | Low | Weight card | Allow toggling between kg and lbs units in the WeightTrendCard. | Currently hardcoded to "kg". Users in the US would prefer lbs. |
| 29 | Low | Header | Add a greeting or time-of-day context (e.g., "Good morning") to the header instead of just the user's name. | The dashboard page has "Welcome back, {name}" but the header shows just the name. Small polish item. |

## Accessibility Observations
- Skip-to-content link is present in the layout (line 58-63). Good.
- All nav links use `aria-current="page"` for active state. Good.
- Sidebar `nav` has `aria-label="Main navigation"`. Good.
- Week tabs have proper `role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls`, `tabIndex` roving focus, and arrow key navigation. Good.
- Announcement cards have `role="button"`, `tabIndex={0}`, `aria-expanded`, and keyboard Enter/Space handlers. Good.
- Progress bars have `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax`. Good.
- Loading states use `role="status"` and `aria-label`. Good.
- Error states use `role="alert"` and `aria-live="assertive"`. Good.

## Summary
- Dead UI elements found: 1 (fixed: added "View full program" link)
- Visual bugs found: 3 (all 3 fixed)
- Logic bugs found: 6 (all 6 fixed)
- Edge cases verified: 12 (all pass)
- Improvements suggested: 7 (all deferred -- require design decisions or backend endpoints)
- Items fixed by hacker: 10

### Files Changed
1. **`web/src/components/trainee-dashboard/todays-workout-card.tsx`**
   - Added `Link` import and `CardFooter` import.
   - Added "View full program" link with ArrowRight icon in a CardFooter.

2. **`web/src/components/trainee-dashboard/nutrition-summary-card.tsx`**
   - Replaced stale `useMemo(() => date, [])` with `useState` + `useEffect` that checks the date every 60 seconds.
   - Removed unused `useMemo` import.

3. **`web/src/components/trainee-dashboard/program-viewer.tsx`**
   - Added `resolveDayLabel()` helper function that correctly maps day field values to day names.
   - Moved hooks above early return to fix Rules of Hooks violation.
   - Updated DayCard to use `dayLabel` instead of hardcoded `DAY_NAMES[dayIndex]`.

4. **`web/src/components/trainee-dashboard/weekly-progress-card.tsx`**
   - Added empty state when `total_days === 0` instead of showing "0% 0 of 0 days".

5. **`web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`**
   - Wrapped with `<Suspense>` boundary for `useSearchParams()`.
   - Wrapped main content return in `<PageTransition>` for consistency.
   - Refactored auto-select from sync-via-effect to derived-via-useMemo (eliminated lint warning).
   - Wrapped `handleSelectConversation` and `handleBackToList` in `useCallback`.

6. **`web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx`**
   - Fixed `handleAnnouncementOpen` `useCallback` dependency from `[markOneRead]` to `[markOneRead.mutate]`.

7. **`web/src/hooks/use-trainee-announcements.ts`**
   - Added optimistic update with rollback to `useMarkAnnouncementRead()` (onMutate/onError/onSettled).
   - Added optimistic update with rollback to `useMarkAnnouncementsRead()` (onMutate/onError/onSettled).

## Chaos Score: 7/10

The Trainee Web Portal is well-structured with consistent patterns: every page handles loading/error/empty states, accessibility is above average with proper ARIA attributes throughout, and the mobile responsive design works via the Sheet component. However, the Rules of Hooks violation in ProgramViewer was a serious correctness bug that could corrupt React's hook state. The stale midnight date in NutritionSummaryCard would silently show wrong-day data. The lack of Suspense around `useSearchParams` is a Next.js best-practice violation. And the `setState-in-effect` pattern for conversation selection caused unnecessary cascading renders. All issues have been fixed, but the number and severity of logic bugs (6, including 2 High) pulls the score down from what would otherwise be an 8.

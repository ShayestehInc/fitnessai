# UX Audit: Trainee Web -- Workout Logging & Progress Tracking (Pipeline 33)

## Audit Date
2026-02-21

## Components Audited
- Active Workout: `web/src/components/trainee-dashboard/active-workout.tsx`
- Exercise Log Card: `web/src/components/trainee-dashboard/exercise-log-card.tsx`
- Workout Finish Dialog: `web/src/components/trainee-dashboard/workout-finish-dialog.tsx`
- Workout History List: `web/src/components/trainee-dashboard/workout-history-list.tsx`
- Workout Detail Dialog: `web/src/components/trainee-dashboard/workout-detail-dialog.tsx`
- Trainee Progress Charts: `web/src/components/trainee-dashboard/trainee-progress-charts.tsx`
- Weight Trend Card: `web/src/components/trainee-dashboard/weight-trend-card.tsx`
- Weight Check-In Dialog: `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx`
- Today's Workout Card: `web/src/components/trainee-dashboard/todays-workout-card.tsx`
- Workout Page: `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx`
- History Page: `web/src/app/(trainee-dashboard)/trainee/history/page.tsx`
- Progress Page: `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx`

---

## Usability Issues Found & Fixed

| # | Severity | Screen/Component | Issue | Fix Applied |
|---|----------|-----------------|-------|-------------|
| 1 | Major | Workout Finish Dialog | No warning shown when user has incomplete (unchecked) sets. User could save a workout with 0 completed sets without realizing they forgot to check boxes. | Added amber warning alert showing count of incomplete sets ("3 sets not marked as completed. You can still save.") with `AlertTriangle` icon |
| 2 | Major | Workout Finish Dialog | Dialog can be closed (dismissed) while save mutation is pending, which could cause the user to lose their workout data or trigger confusing behavior | Added guard in `onOpenChange` to prevent closing while `isPending` is true. Cancel button already had `disabled={isPending}` |
| 3 | Major | Active Workout | Missing discard button -- user could only finish or close tab. No way to deliberately abandon a workout and return to dashboard | Linter/pipeline added Discard button with AlertDialog confirmation ("Your workout progress will be lost. This action cannot be undone.") with destructive styling |
| 4 | Medium | Workout History List | Pagination showed only "Page 1" with no total page count. User has no sense of how much history exists | Changed to "Page 1 of N" format with totalPages calculated from `data.count` and page size |
| 5 | Medium | Workout History List | Pagination buttons scrolled content but page position stayed at bottom. After clicking "Next", user sees the bottom of the new page | Added `window.scrollTo({ top: 0, behavior: "smooth" })` on page change via `changePage` callback |
| 6 | Medium | Workout Detail Dialog | No duration shown in workout detail. User can see exercises and sets but not how long the workout took | Added `getDuration()` helper to extract duration from workout data. Duration displayed next to date with a Clock icon |
| 7 | Medium | Workout Detail Dialog | Exercise heading used `<h4>` without parent `<h3>`, creating a heading hierarchy gap | Changed to `<p className="font-medium">` since this is inside a dialog with its own title. Exercises wrapped in `role="region"` with `aria-label` instead |
| 8 | Medium | Weight Trend Card | Weight change section used non-null assertion `previous!.date` which is a code smell. Also lacked screen reader context for the trend | Replaced with null-safe `previous && (...)` guard. Added `aria-label` describing the trend direction and magnitude in natural language |
| 9 | Medium | Weight Check-In Dialog | Save button text stays as "Save" during pending state. User only sees spinner but no text change confirming action is in progress | Changed to "Saving..." text during pending state for clearer feedback |
| 10 | Minor | Today's Workout Card | "View full program" link lacks context when read by screen reader without surrounding card visible | Added `aria-label` with program name: "View full program: Push Pull Legs" |
| 11 | Minor | Today's Workout Card | Exercise list `<ul>` had no accessible label | Added `aria-label="Today's exercises"` |
| 12 | Minor | Today's Workout Card | "View full program" link had no visible focus indicator for keyboard navigation | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 rounded` classes |

---

## Accessibility Issues Found & Fixed

| # | WCAG Level | Component | Issue | Fix Applied |
|---|------------|-----------|-------|-------------|
| 1 | AA | Active Workout (timer) | Timer display used `aria-label` on `<span>` but lacked proper `role="timer"`. Screen readers may not announce time updates appropriately | Changed timer container to `role="timer"` with `aria-live="off"` (to avoid constant announcements) and `aria-label` with formatted time |
| 2 | AA | Active Workout (loading) | Loading skeleton had no `aria-busy` attribute. Screen readers don't know the region is loading | Added `aria-busy="true"` and `aria-label="Loading workout data"` |
| 3 | AA | Exercise Log Card (header row) | Header row labels ("Set", "Reps", "Weight") were read by screen readers in addition to the per-input `aria-label`s, causing double-reading | Added `aria-hidden="true"` to header row since each input already has its own descriptive `aria-label` |
| 4 | AA | Exercise Log Card (Add Set) | "Add Set" button lacked context for which exercise it belongs to when read in isolation | Added `aria-label="Add set to {exerciseName}"` |
| 5 | AA | Exercise Log Card (icons) | Check icon, Trash icon, and Plus icon missing `aria-hidden="true"`, causing screen readers to potentially read SVG content | Added `aria-hidden="true"` to all decorative icons in the component |
| 6 | AA | Workout Finish Dialog | Summary section had no ARIA landmark or label. Screen reader reads it as undifferentiated text | Added `role="region"` and `aria-label="Workout summary"` to the summary container |
| 7 | AA | Workout Finish Dialog | Loader spinner icon missing `aria-hidden` | Added `aria-hidden="true"` to Loader2 icon |
| 8 | AA | Workout History List (pagination) | Pagination wrapped in a `<div>` with no semantic meaning. Buttons lacked descriptive `aria-label` | Changed to `<nav aria-label="Workout history pagination">`. Added `aria-label="Go to previous page"` and `aria-label="Go to next page"` to buttons |
| 9 | AA | Workout History List (loading) | Loading skeleton list had no `aria-busy` | Added `aria-busy="true"` and `aria-label="Loading workout history"` |
| 10 | AA | Workout History List (Eye icon) | Eye icon in Details button missing `aria-hidden` | Added `aria-hidden="true"` |
| 11 | AA | Workout History List (chevron icons) | Chevron icons in pagination buttons missing `aria-hidden` | Added `aria-hidden="true"` to both ChevronLeft and ChevronRight |
| 12 | AA | Workout Detail Dialog (icons) | Check and X icons in completed/skipped badges missing `aria-hidden` | Added `aria-hidden="true"` to both icons |
| 13 | AA | Workout Detail Dialog (loading) | Loading skeleton in dialog missing `aria-busy` | Added `aria-busy="true"` and `aria-label="Loading workout details"` |
| 14 | AA | Workout Detail Dialog (empty) | Empty state message had no `role="status"` for screen reader announcement | Added `role="status"` |
| 15 | AA | Progress Charts (skeletons) | All chart skeleton loading states missing `aria-busy` | Added `aria-busy="true"` to `ChartSkeleton` component (affects WeightTrendChart, WorkoutVolumeChart, WeeklyAdherenceCard) |
| 16 | AA | Weight Trend Card (skeleton) | Card skeleton missing `aria-busy` | Added `aria-busy="true"` |
| 17 | AA | Today's Workout Card (skeleton) | Card skeleton missing `aria-busy` | Added `aria-busy="true"` |
| 18 | AA | Today's Workout Card (Play, CheckCircle icons) | Footer button icons missing `aria-hidden` | Added `aria-hidden="true"` to Play and CheckCircle2 icons |
| 19 | AA | Weight Trend Card (Plus icons) | Plus icons in "Log Weight" buttons missing `aria-hidden` | Added `aria-hidden="true"` to all Plus icons |
| 20 | AA | Progress Charts (Plus icon) | Plus icon in "Log Weight" button missing `aria-hidden` | Added `aria-hidden="true"` |
| 21 | AA | Play icon (history empty state) | Play icon in "Start Workout" link missing `aria-hidden` | Added `aria-hidden="true"` |

---

## Missing States Checklist

- [x] Loading / skeleton -- All components have proper skeleton or spinner loading states with `aria-busy`
- [x] Empty / zero data -- Active workout (no program, no exercises), history (no workouts), progress (no weight data, no volume data, no adherence data), today's workout (no program, rest day, no exercises, no scheduled day)
- [x] Error / failure -- All data-fetching components have `ErrorState` with retry button
- [x] Success / confirmation -- Workout save shows toast "Workout saved!", weight check-in shows toast "Weight check-in saved", error toasts on failures
- [x] Offline / degraded -- Not applicable (web portal; no offline support expected)
- [x] Permission denied -- Layout handles role-based redirects
- [x] Disabled -- Save/Finish buttons disabled during pending. Cancel disabled during save.

---

## Responsive Design Assessment

The implementation uses responsive patterns well:
- Exercise log cards use `md:grid-cols-2` to show 2-up on desktop, 1-up on mobile
- Dialogs use `sm:max-w-[425px]` and `sm:max-w-[600px]` with full-width on mobile
- Progress page uses `lg:grid-cols-2` for side-by-side charts on desktop
- PageHeader flex-wraps actions below title on small screens
- Exercise set grids use `grid-cols-[2.5rem_1fr_1fr_2.5rem_2.5rem]` which scales appropriately

No responsive issues found.

---

## What Was Already Well-Done

1. **Beforeunload protection** in active workout -- prevents accidental navigation away from unsaved workout
2. **One-time snapshot pattern** for workout initialization -- prevents live query updates from changing exercise data mid-workout
3. **Timer with tabular-nums** -- monospace font for timer prevents jittery number rendering
4. **Volume calculation** -- correctly multiplies weight x reps only for completed sets in the finish dialog
5. **Dual workout data formats** -- detail dialog handles both `exercises` and `sessions` formats (web vs mobile app)
6. **Pagination with API-driven previous/next** -- doesn't rely on client-side page math, uses API response flags
7. **Screen reader chart fallbacks** -- charts wrapped in `role="img"` with hidden `<ul>` lists for screen reader consumption
8. **Weekly adherence progress bar** -- proper `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and descriptive `aria-label`
9. **Motivational copy** in adherence card -- contextual encouragement based on percentage tier
10. **Today's workout card** -- properly detects if workout was already logged today and changes CTA from "Start Workout" to "View Today's Workout"
11. **Weight check-in form validation** -- client-side validation with proper ARIA (`aria-invalid`, `aria-describedby`), server-side error parsing, and field-level error display
12. **Neutral trend colors** for weight change -- wisely avoids green/red since user goal (gain vs lose) is unknown

---

## Overall UX Score: 9/10

**Rationale:** The workout logging and progress tracking features are built on a strong UX foundation with excellent state management, thoughtful error handling, and good data visualization. The primary issues found were accessibility gaps (missing `aria-hidden` on decorative icons, missing `aria-busy` on loading states, missing semantic landmarks on pagination) and two notable UX gaps: (1) no incomplete-sets warning in the finish dialog (users could save without realizing they hadn't checked off their sets), and (2) the dialog could be dismissed while saving. All issues have been fixed. The remaining gap to a perfect score would be: adding animations when sets are completed (a subtle checkmark animation), adding haptic-style visual feedback when toggling completion checkboxes, and providing an undo mechanism for accidentally submitted workouts.

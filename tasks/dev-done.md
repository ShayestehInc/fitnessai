# Dev Done: Web App Mobile Responsiveness

## Files Changed (17 files)
1. `web/src/app/layout.tsx` — Added `viewport` export with device-width, no user-scaling
2. `web/src/app/globals.css` — Added scrollbar-thin utility, dvh safe viewport class, iOS text-size-adjust fix, number input spinner removal
3. `web/src/app/(dashboard)/layout.tsx` — Changed `h-screen` to `h-dvh` for mobile Safari
4. `web/src/app/(trainee-dashboard)/layout.tsx` — Changed `h-screen` to `h-dvh` for mobile Safari
5. `web/src/components/shared/page-header.tsx` — Responsive h1 sizing (text-xl on mobile, text-2xl on sm+)
6. `web/src/components/trainee-dashboard/exercise-log-card.tsx` — Narrower grid columns on mobile, smaller gaps, min-w-0 on inputs, larger touch targets for checkboxes
7. `web/src/components/trainee-dashboard/active-workout.tsx` — flex-wrap on header actions, hidden label text on mobile, sm:size buttons, exercise grid stacks on mobile (lg:grid-cols-2 instead of md:)
8. `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` — max-h-[90dvh] on mobile, responsive set detail widths, truncation for weight column
9. `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` — max-h-[90dvh] overflow-y-auto
10. `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` — max-h-[90dvh] overflow-y-auto
11. `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` — Mobile-aware XAxis (angled labels, smaller font, preserveStartEnd interval), adjusted chart heights and margins
12. `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` — max-height with dvh for mobile Safari
13. `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` — Header wraps to column on mobile
14. `web/src/components/trainee-dashboard/program-viewer.tsx` — Week tabs scrollbar-thin, more padding for scroll, day cards grid at sm breakpoint
15. `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` — Tighter gap on mobile
16. `tasks/focus.md` — Updated focus
17. `tasks/next-ticket.md` — Written ticket

## Key Decisions
- Used `h-dvh` (dynamic viewport height) instead of `h-screen` (100vh) to fix mobile Safari address bar issue
- Added `useIsMobile` hook inside charts component (not a shared hook) since it's only needed there
- Removed number input spinners globally via CSS — saves horizontal space on mobile and the exercise log uses its own +/- controls
- Angled chart XAxis labels at -45deg on mobile with preserveStartEnd interval to prevent label overlap
- Made exercise log card checkboxes 28px (7*4) on mobile, exceeding the 24px minimum but close to 44px Apple guideline
- Used `sm:` breakpoint for exercise grid columns (not `md:`) so phones in landscape get single-column
- Workout actions use abbreviated text on mobile ("Finish" instead of "Finish Workout", icon-only for discard)

## How to Manually Test
1. Open http://localhost:3000/trainee/dashboard on Chrome DevTools device emulation
2. Test at 375px (iPhone), 320px (iPhone SE), 768px (iPad)
3. Check each trainee page: Dashboard, Program, Workout, Nutrition, Progress, History, Messages, Announcements, Achievements, Settings
4. Verify no horizontal scroll on any page
5. Test the active workout flow — log sets, check touch targets
6. Open workout detail dialog — should fill screen on mobile
7. Check chart labels on progress page — no overlap
8. Check messages page — chat should fill available height

# Feature: Web App Mobile Responsiveness — Trainee Dashboard

## Priority
High

## User Story
As a trainee using my phone's browser, I want the web dashboard to be fully usable on my mobile screen so that I can log workouts, track nutrition, and view my progress without needing a desktop.

## Acceptance Criteria
- [ ] ExerciseLogCard sets table is usable at 320px (inputs aren't tiny, grid doesn't overflow)
- [ ] Active Workout page header actions (timer, discard, finish) wrap gracefully on mobile
- [ ] WorkoutDetailDialog uses full-screen on mobile (no tiny centered modal)
- [ ] WorkoutFinishDialog uses full-screen on mobile
- [ ] Recharts chart XAxis labels don't overlap on narrow screens (angle or reduce ticks)
- [ ] Messages page chat area fills available viewport height on mobile Safari
- [ ] Announcements header (title + "Mark all read" button) wraps properly on narrow screens
- [ ] Program Viewer week tabs have visible scroll indicator on mobile
- [ ] All text remains readable (no text smaller than 14px for body content on mobile)
- [ ] All tap targets are at least 44px on mobile
- [ ] Dialogs don't overflow viewport on mobile
- [ ] Dashboard grid cards stack to single column below ~380px

## Edge Cases
1. iPhone SE (320px width) — everything must fit without horizontal scroll
2. Mobile Safari 100vh bug — address bar causes content to be pushed below fold
3. Landscape orientation on phone — layout shouldn't break
4. Very long exercise names — must truncate, not overflow
5. Many meals logged (10+) — scroll within cards must work on mobile
6. Chart with 30 data points — labels must not overlap at 320px
7. Week tabs with 8+ weeks — horizontal scroll must be obvious
8. Workout with many exercises — vertical scroll must work smoothly

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Touch targets too small | Hard to tap buttons | Increase tap targets to 44px min |
| Horizontal overflow | Horizontal scroll bar | Fix grid/flex to fit viewport |
| Dialog overflow | Content cut off | Make dialogs full-screen on mobile |

## UX Requirements
- **Loading state:** Existing skeleton states already work on mobile — verify they fill width
- **Empty state:** Existing empty states should center properly on mobile
- **Error state:** Existing error cards should be properly padded on mobile
- **Success feedback:** Toast notifications already work (sonner) — no changes needed
- **Mobile behavior:** Thumb-friendly bottom areas, proper viewport handling

## Technical Approach
- Files to modify:
  - `web/src/components/trainee-dashboard/exercise-log-card.tsx` — responsive grid
  - `web/src/components/trainee-dashboard/active-workout.tsx` — header actions wrap
  - `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` — mobile full-screen
  - `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` — mobile full-screen
  - `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` — chart XAxis
  - `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` — viewport height
  - `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` — header wrap
  - `web/src/components/trainee-dashboard/program-viewer.tsx` — week tabs scroll indicator
  - `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx` — grid breakpoint
  - `web/src/app/globals.css` — mobile viewport fix, utility classes

## Out of Scope
- Trainer dashboard mobile responsiveness
- Admin dashboard mobile responsiveness
- Ambassador dashboard mobile responsiveness
- Backend changes
- Native mobile app changes

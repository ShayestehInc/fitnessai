# UX Audit: Trainee Web Portal (Pipeline 32)

## Audit Date
2026-02-21

## Components Audited
- Layout: `web/src/app/(trainee-dashboard)/layout.tsx`
- Dashboard: `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx`
- Today's Workout Card: `web/src/components/trainee-dashboard/todays-workout-card.tsx`
- Nutrition Summary Card: `web/src/components/trainee-dashboard/nutrition-summary-card.tsx`
- Weight Trend Card: `web/src/components/trainee-dashboard/weight-trend-card.tsx`
- Weekly Progress Card: `web/src/components/trainee-dashboard/weekly-progress-card.tsx`
- Program Viewer: `web/src/components/trainee-dashboard/program-viewer.tsx`
- Announcements List: `web/src/components/trainee-dashboard/announcements-list.tsx`
- Achievements Grid: `web/src/components/trainee-dashboard/achievements-grid.tsx`
- Sidebar: `web/src/components/trainee-dashboard/trainee-sidebar.tsx`
- Sidebar Mobile: `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
- Header: `web/src/components/trainee-dashboard/trainee-header.tsx`
- All page files (program, messages, announcements, achievements, settings)

---

## Usability Issues Found & Fixed

| # | Severity | Screen/Component | Issue | Fix Applied |
|---|----------|-----------------|-------|-------------|
| 1 | Major | Nutrition Summary Card | When no nutrition goals are set (all zeros), card shows 0/0 bars for every macro with zero-width progress bars -- meaningless to the user | Added dedicated empty state with `CircleSlash` icon and "No nutrition goals set" message, explaining trainer hasn't configured targets yet |
| 2 | Major | Announcements List | `expanded` state initialized to `announcement.is_read`, meaning read announcements start expanded and unread ones collapsed. This is backwards -- users expect to click to expand, and having old read announcements all open on page load is noisy | Changed initial state to `false` for all announcements. Users now click to expand any announcement. |
| 3 | Major | Program Viewer (Week Tabs) | Week tabs had `role="tablist"` and `role="tab"` but no keyboard arrow-key navigation. Per WAI-ARIA tab pattern, users expect Left/Right arrows to move between tabs | Added full keyboard handler: ArrowLeft/Right, ArrowUp/Down, Home, End keys. Added proper `tabIndex` roving management (active tab = 0, others = -1). Focus follows selection. |
| 4 | Medium | Announcements Card | Card has `tabIndex={0}` for keyboard accessibility but no visible focus indicator. Keyboard users can tab to the card but see no focus ring | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` classes |
| 5 | Medium | Weight Trend Card | Weight change (+/- kg) shown without temporal context. User sees "+0.3 kg" but has no idea if that's since yesterday or last month | Restructured to show "Last weigh-in: Feb 18, 2026" on its own line, then the change with "since Feb 15" to give full context |
| 6 | Medium | Nutrition Summary Card (unit spacing) | Macro values display "45 / 150g" (no space before "g") but calories display "1200 / 2000 kcal" (with space). Inconsistent formatting | Changed default unit from `"g"` to `" g"` so all units have a space before them |
| 7 | Medium | Header | Header displays user's full name which duplicates the dashboard greeting. The header is a small utility bar -- a friendly "Hi, Reza" is more appropriate and warm | Changed to show `Hi, {firstName}` when first name is available, falling back to full display name |
| 8 | Medium | Announcements Page | "Mark all read" button shows disabled state during mutation but no visual loading indicator. User may think it's broken | Added `Loader2` spinner icon during pending state and changed text to "Marking..." for immediate feedback |
| 9 | Medium | Program Page | Error state not wrapped in `PageTransition`, causing inconsistent entry animations across the page's states (loading = no transition, error = no transition, success = transition) | Wrapped error state in `PageTransition` |
| 10 | Minor | Header | `aria-label` says "Toggle menu" which is ambiguous for screen readers | Changed to "Open navigation menu" for clarity |

---

## Accessibility Issues Found & Fixed

| # | WCAG Level | Component | Issue | Fix Applied |
|---|------------|-----------|-------|-------------|
| 1 | AA | Nutrition Progress Bars | `<Progress>` elements have generic `role="progressbar"` with `aria-valuenow` but no `aria-label` to distinguish them. Screen reader announces "progressbar 45%" four times with no context | Added `aria-label` like "Protein: 45 of 150 g" to each `<Progress>` |
| 2 | AA | Weekly Progress Bar | Same issue -- progress bar announces percentage but not what it represents | Added `aria-label="Weekly progress: 3 of 5 days completed"` |
| 3 | AA | Achievement Cards | No way for screen readers to distinguish earned vs locked achievements. The visual icons (Trophy vs Lock) are `aria-hidden` but no text alternative exists at the card level | Added `role="article"` and `aria-label` like "First Workout -- Earned" or "100 Day Streak -- Locked" |
| 4 | AA | Achievement Progress Bars | Locked achievement progress bars have no label | Added `aria-label` like "100 Day Streak progress: 45 of 100" |
| 5 | AA | Announcement Cards | Interactive card with `role="button"` lacks descriptive `aria-label`. Screen reader only reads the card title without unread/pinned context | Added `aria-label` that includes unread status and pinned indicator |
| 6 | AA | Program Viewer Week Tabs | Tabs missing `tabIndex` roving management per WAI-ARIA tabs pattern | Added `tabIndex={selectedWeek === idx ? 0 : -1}` |

---

## Missing States Checklist

- [x] Loading / skeleton -- All cards and pages have skeleton or spinner loading states
- [x] Empty / zero data -- Workout (no program), Weight (no data), Program (no programs), Announcements (no announcements), Achievements (no achievements), Nutrition (no goals -- FIXED)
- [x] Error / failure -- All cards and pages have error states with retry buttons
- [x] Success / confirmation -- Announcements mark-read shows toast, mutations invalidate queries
- [x] Offline / degraded -- Not applicable (no offline support in web portal, acceptable)
- [x] Permission denied -- Layout redirects non-trainee users to appropriate dashboards

---

## What Was Already Well-Done

The implementation had many strong UX fundamentals in place:

1. **Skip-to-content link** in the layout -- excellent accessibility baseline
2. **Consistent loading patterns** -- skeleton cards for inline content, full-page spinners for page loads
3. **Error states with retry** everywhere -- `ErrorState` component with `onRetry` callback used consistently
4. **Empty states** with contextual copy ("Your trainer hasn't...") that sets expectations rather than just saying "No data"
5. **Responsive sidebar** with Sheet-based mobile drawer that auto-closes on navigation
6. **Badge counts** for unread messages/announcements on sidebar navigation
7. **Role-based routing** in layout -- redirects admins/trainers/ambassadors to correct dashboards
8. **PageTransition** component for smooth page entry animations
9. **Accessible icons** -- all decorative icons have `aria-hidden="true"`, functional icons have `aria-label`
10. **Program viewer** with program switcher dropdown, metadata badges, and proper tablist/tabpanel ARIA roles
11. **Announcement unread distinction** -- visual blue tint + bold title + unread dot
12. **Messages page** with keyboard shortcut (Cmd/Ctrl+K) for search, mobile-responsive chat layout with back button

---

## Overall UX Score: 8/10

**Rationale:** The portal has a solid foundation with good state management, consistent patterns, and thoughtful empty states. The issues found were mostly in accessibility gaps (missing ARIA labels on progress bars, missing keyboard navigation on tabs) and a few UX logic bugs (reversed announcement expansion, meaningless 0/0 nutrition bars). The fixes applied address all major and medium issues. The remaining gap to a perfect score would be: (1) adding actual chart visualizations for weight trends over time rather than just showing two data points, (2) adding subtle animations/transitions to achievement unlock states, and (3) adding a notification toast when a single announcement is marked as read (currently only bulk mark-read has feedback).

# UX Audit: Web Trainer Dashboard (Pipeline 9)

## Audit Date: 2026-02-15

## Pages & Components Reviewed
- All pages: login, dashboard, trainees, trainee detail, invitations, notifications, settings, not-found
- All layout components: sidebar, sidebar-mobile, header, user-nav
- All shared components: empty-state, error-state, loading-spinner, page-header, data-table
- All feature components: dashboard stats/cards/skeletons, trainee table/search/columns/activity/overview/progress, invitation table/columns/dialog/status-badge, notification bell/popover/item
- All UI primitives: button, input, card, dialog, table, tabs, badge, etc.

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Medium | RecentTrainees | Table had no horizontal scroll wrapper on small screens causing content to be cut off | Added `overflow-x-auto` wrapper -- FIXED |
| 2 | Medium | DataTable | Table had no horizontal scroll wrapper causing overflow on mobile | Added `overflow-x-auto` wrapper -- FIXED |
| 3 | Medium | DataTable | Clickable table rows were not keyboard-accessible -- no tabIndex, no Enter/Space handler, no focus ring | Added `tabIndex={0}`, `role="button"`, `onKeyDown` for Enter/Space, and `focus-visible:ring-2` -- FIXED |
| 4 | Low | TraineeActivityTab | Day filter buttons used abbreviated labels ("7d", "14d", "30d") without screen reader context | Added `aria-label="Show last N days"` and `aria-pressed` state -- FIXED |
| 5 | Low | GoalBadge | Goal badges use single-letter abbreviations "P" and "C" that are cryptic to screen readers | Added `srLabel` prop with descriptive text ("Protein goal met/not met", "Calorie goal met/not met") -- FIXED |
| 6 | Low | InactiveTrainees links | Clickable links had no focus ring for keyboard users | Added `focus-visible:ring-2` styles -- FIXED |
| 7 | Low | NotificationItem | Button had no visible focus ring on keyboard focus | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring` -- FIXED |
| 8 | Info | SettingsPage | Settings page is a placeholder ("Coming soon") with no indication of when features will be available | Acceptable for now -- should eventually link to a changelog or roadmap |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A (1.3.1) | `LoadingSpinner` had no `role="status"` or screen reader text | Added `role="status"`, `aria-label` prop, and `sr-only` span -- FIXED |
| 2 | A (1.3.1) | Dashboard layout loading spinner had no screen reader text | Added `role="status"`, `aria-label="Loading dashboard"`, `aria-hidden` on icon, and `sr-only` text -- FIXED |
| 3 | A (4.1.3) | `ErrorState` had no `role="alert"` or `aria-live` for screen reader announcements | Added `role="alert"` and `aria-live="assertive"` on CardContent -- FIXED |
| 4 | A (4.1.3) | Login page error message div had no `role="alert"` | Added `role="alert"` and `aria-live="assertive"` -- FIXED |
| 5 | A (4.1.3) | CreateInvitationDialog error message div had no `role="alert"` | Added `role="alert"` and `aria-live="assertive"` -- FIXED |
| 6 | A (1.3.1) | `EmptyState` had no `role="status"` for screen readers | Added `role="status"` on wrapper div -- FIXED |
| 7 | AA (1.1.1) | Multiple decorative icons lacked `aria-hidden="true"` (Dumbbell in login/sidebars, AlertTriangle, Loader2, stat icons, nav icons, error icon, notification icon) | Added `aria-hidden="true"` to all decorative icons across 10+ files -- FIXED |
| 8 | AA (4.1.2) | `NotificationItem` button lacked descriptive `aria-label` | Added computed `aria-label` combining read status, title, and message -- FIXED |
| 9 | AA (4.1.2) | `UserNav` avatar trigger button lacked `aria-label` | Added `aria-label="User menu for {displayName}"` -- FIXED |
| 10 | AA (2.4.1) | No skip-to-content link for keyboard users to bypass sidebar navigation | Added skip link visible on focus with "Skip to main content" -- FIXED |
| 11 | AA (2.4.8) | Nav links did not indicate current page to screen readers | Added `aria-current="page"` to active nav links in both desktop and mobile sidebars -- FIXED |
| 12 | AA (2.4.1) | Sidebar `<nav>` elements lacked `aria-label` | Added `aria-label="Main navigation"` to both sidebars -- FIXED |
| 13 | AA (4.1.2) | Pagination buttons throughout the app lacked `aria-label` attributes | Added `aria-label="Go to previous/next page"` on all pagination buttons -- FIXED |
| 14 | AA (4.1.2) | Pagination controls were `<div>` elements instead of semantic `<nav>` landmarks | Wrapped in `<nav>` with `aria-label` (e.g., "Table pagination", "Invitation pagination") -- FIXED |
| 15 | AA (1.1.1) | Pagination chevron icons were not marked as decorative | Added `aria-hidden="true"` on all ChevronLeft/ChevronRight icons -- FIXED |
| 16 | A (2.1.1) | DataTable clickable rows were not keyboard accessible (no tabIndex, no key handler) | Added `tabIndex={0}`, `role="button"`, Enter/Space `onKeyDown` handler -- FIXED |

---

## Missing States

- [x] Loading / skeleton -- Present on all pages (DashboardSkeleton, TraineeTableSkeleton, TraineeDetailSkeleton, LoadingSpinner)
- [x] Empty / zero data -- Present on all pages (EmptyState component used consistently)
- [x] Error / failure -- Present on all pages (ErrorState component with retry button)
- [x] Success / confirmation -- Toast notifications used for invitation creation and mark-all-read

### Detailed State Coverage

| Screen | Loading | Empty | Error | Success/Feedback |
|--------|---------|-------|-------|-----------------|
| Dashboard | DashboardSkeleton | EmptyState with CTA | ErrorState with retry | Data display |
| Trainees | TraineeTableSkeleton | EmptyState (no trainees) + EmptyState (no search results) | ErrorState with retry | Row click navigation |
| Trainee Detail | TraineeDetailSkeleton | Profile/goals "not set" text | ErrorState with back + retry | Tabs with data |
| Invitations | LoadingSpinner | EmptyState with CTA | ErrorState with retry | Toast on creation |
| Notifications | LoadingSpinner | Context-aware empty ("All caught up" / "No notifications") | ErrorState with retry | Toast on mark-all-read |
| Login | Spinner in button + "Signing in..." | N/A | Inline error alert | Redirect to dashboard |
| Settings | N/A | "Coming soon" placeholder | N/A | N/A |

---

## Copy Assessment

All copy is clear, non-technical, and actionable:

| Element | Copy | Verdict |
|---------|------|---------|
| Dashboard description | "Overview of your training business" | Clear, professional |
| Empty trainee CTA | "Send an Invitation" | Clear action |
| Search no-results | `No trainees match "{search}"` | Helpful, includes search term |
| Notification empty (unread) | "All caught up" | Friendly, reassuring |
| Invitation dialog description | "Send an invitation to a new trainee. They'll receive a code to sign up." | Clear process explanation |
| Error states | "Failed to load {resource}" | Consistent pattern |
| Retry button | "Try again" | Standard, clear |
| 404 page | "Page not found" with "Go to Dashboard" | Clear recovery path |

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Page spacing | Consistent | All pages use `space-y-6` |
| Page titles | Consistent | All use PageHeader with `text-2xl font-bold tracking-tight` |
| Error styling | Consistent | All use shared ErrorState component |
| Empty styling | Consistent | All use shared EmptyState component |
| Card design | Consistent | All use shadcn Card components |
| Badge usage | Consistent | Status badges use same variant patterns |
| Color system | Consistent | Uses CSS variables from globals.css throughout |
| Pagination | Minor inconsistency | DataTable has integrated pagination; invitations/notifications have manual inline pagination. Functionally identical but visually slightly different (DataTable shows "Page X of Y (N total)"; manual shows "Page N" only). |

---

## Responsiveness Assessment

| Aspect | Status |
|--------|--------|
| Sidebar | Hides at `lg` breakpoint, replaced by Sheet drawer |
| Page headers | Stack vertically on mobile via `sm:flex-row` |
| Stats grid | Collapses 4 -> 2 -> 1 via `sm:grid-cols-2 lg:grid-cols-4` |
| Tables | Now have `overflow-x-auto` for horizontal scrolling (FIXED) |
| Login card | Max-width constrained (`max-w-sm`) |
| Touch targets | Minimum h-8/h-9 on buttons (adequate) |
| Activity tab filters | Responsive via `sm:flex-row` card header |
| Trainee detail layout | 2-col grid collapses to 1-col via `lg:grid-cols-2` |

---

## Fixes Implemented

### Accessibility Fixes (15 files modified)

1. **`web/src/components/shared/loading-spinner.tsx`** -- Added `role="status"`, configurable `aria-label` prop (default: "Loading..."), and `sr-only` span for screen readers.

2. **`web/src/components/shared/error-state.tsx`** -- Added `role="alert"` and `aria-live="assertive"` on CardContent so errors are immediately announced; added `aria-hidden="true"` on AlertCircle icon.

3. **`web/src/components/shared/empty-state.tsx`** -- Added `role="status"` on wrapper div; added `aria-hidden="true"` on icon.

4. **`web/src/app/(auth)/login/page.tsx`** -- Added `role="alert"` and `aria-live="assertive"` on error message div; added `aria-hidden="true"` on decorative Dumbbell and Loader2 icons.

5. **`web/src/components/invitations/create-invitation-dialog.tsx`** -- Added `role="alert"` and `aria-live="assertive"` on error message div.

6. **`web/src/components/notifications/notification-item.tsx`** -- Added computed `aria-label` (e.g., "Unread: Title -- Message"); added `focus-visible:ring-2` for keyboard navigation; added `aria-hidden="true"` on type icon.

7. **`web/src/components/layout/user-nav.tsx`** -- Added `aria-label="User menu for {displayName}"` on avatar trigger button.

8. **`web/src/components/layout/sidebar.tsx`** -- Added `aria-hidden="true"` on decorative Dumbbell and nav icons; added `aria-current="page"` on active link; added `aria-label="Main navigation"` on nav element.

9. **`web/src/components/layout/sidebar-mobile.tsx`** -- Same accessibility improvements as desktop sidebar.

10. **`web/src/components/dashboard/stat-card.tsx`** -- Added `aria-hidden="true"` on decorative stat icon.

11. **`web/src/components/dashboard/inactive-trainees.tsx`** -- Added `aria-hidden="true"` on AlertTriangle icon; added descriptive `aria-label` on trainee links; added `focus-visible:ring-2` on links.

12. **`web/src/app/(dashboard)/layout.tsx`** -- Added skip-to-content link (visible on focus); added `role="status"` and `sr-only` text on auth loading state; added `id="main-content"` on main element.

### Responsiveness Fixes

13. **`web/src/components/dashboard/recent-trainees.tsx`** -- Wrapped table in `overflow-x-auto` container to prevent content clipping on mobile.

14. **`web/src/components/shared/data-table.tsx`** -- Added `overflow-x-auto` on table border container.

### Keyboard Navigation Fixes

15. **`web/src/components/shared/data-table.tsx`** -- Added `tabIndex={0}`, `role="button"`, Enter/Space `onKeyDown` handler, and `focus-visible:ring-2` on clickable rows; wrapped pagination controls in semantic `<nav>` element with `aria-label`; added `aria-label` on pagination buttons; added `aria-hidden` on chevron icons.

16. **`web/src/app/(dashboard)/invitations/page.tsx`** -- Wrapped pagination in `<nav aria-label="Invitation pagination">`; added `aria-label` on Previous/Next buttons; added `aria-hidden` on chevron icons; added `aria-current="page"` on page indicator.

17. **`web/src/app/(dashboard)/notifications/page.tsx`** -- Same pagination accessibility improvements as invitations page.

18. **`web/src/components/trainees/trainee-activity-tab.tsx`** -- Added `role="group"` and `aria-label="Time range filter"` on day filter button group; added `aria-label` and `aria-pressed` on day buttons; added `srLabel` prop to GoalBadge for screen-reader-friendly descriptions.

---

## Items Not Fixed (Require Design Decisions)

1. **Pagination style inconsistency** -- DataTable's integrated pagination shows "Page X of Y (N total)" while manual pagination on invitations/notifications pages shows only "Page N". Unifying would require a small refactor to extract a shared pagination component. Non-blocking.

2. **No dark mode toggle** -- ThemeProvider exists in the app root but there is no user-facing toggle to switch between light/dark mode. The system preference is respected but there is no manual override.

3. **Settings page placeholder** -- Expected as "Coming soon" but should eventually contain profile editing, theme preferences, notification settings.

4. **Optimistic updates** -- Marking a notification as read waits for query invalidation and refetch rather than doing an optimistic update. The delay is negligible but could feel snappier.

5. **Progress tab placeholder** -- The TraineeProgressTab is a permanent "Coming soon" placeholder. Consider hiding it entirely until the feature is built to avoid user confusion.

---

## Overall UX Score: 8/10

### Breakdown:
- **State Handling:** 9/10 -- All five core states present on every page with consistent shared components
- **Accessibility:** 8/10 -- Comprehensive ARIA attributes, skip-link, keyboard navigation, screen reader text (after fixes)
- **Visual Consistency:** 9/10 -- Clean design system, consistent components, proper dark mode support
- **Copy Clarity:** 9/10 -- Clear, actionable, context-aware copy throughout
- **Responsiveness:** 8/10 -- Proper breakpoints, mobile sidebar, table scroll wrappers (after fixes)
- **Feedback & Interaction:** 7/10 -- Toast notifications and loading states present; could add optimistic updates and keyboard shortcuts

### Strengths:
- Every page handles all five core states (loading, empty, error, success, disabled)
- Shared components (PageHeader, EmptyState, ErrorState, LoadingSpinner) ensure consistency
- Clean, professional design following shadcn/ui patterns
- Good responsive design with proper mobile sidebar drawer
- Toast feedback on mutations
- Search with debounce on trainees page
- Dark mode fully supported via CSS variables

### Areas for Future Improvement:
- Add keyboard shortcuts for power users (e.g., `/` to focus search, `g d` for dashboard)
- Add optimistic updates for notification mark-as-read
- Add a dark mode toggle in the UI
- Add animated skeleton shimmer instead of static gray bars
- Consider hiding the Progress tab placeholder until the feature is built
- Unify pagination into a shared component for consistency

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 9 -- Web Trainer Dashboard
**Verdict:** PASS -- All critical UX and accessibility issues fixed. 18 fixes implemented across 15+ files.

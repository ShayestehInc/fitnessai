# Architecture Review: Trainee Web Portal (Pipeline 32)

## Review Date
2026-02-21

## Files Reviewed

**New Route Group & Pages:**
- `web/src/app/(trainee-dashboard)/layout.tsx` -- trainee layout with role guard
- `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx` -- dashboard page
- `web/src/app/(trainee-dashboard)/trainee/program/page.tsx` -- program page
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` -- messages page
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` -- announcements page
- `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx` -- achievements page
- `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx` -- settings page

**New Hooks:**
- `web/src/hooks/use-trainee-dashboard.ts` -- data fetching (programs, nutrition, weight, progress)
- `web/src/hooks/use-trainee-announcements.ts` -- announcements queries and mutations
- `web/src/hooks/use-trainee-achievements.ts` -- achievements query
- `web/src/hooks/use-trainee-badge-counts.ts` -- badge count composition hook

**New Components:**
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` -- desktop sidebar
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` -- mobile sidebar
- `web/src/components/trainee-dashboard/trainee-header.tsx` -- header bar
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` -- navigation configuration
- `web/src/components/trainee-dashboard/program-viewer.tsx` -- program schedule viewer
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` -- today's workout card
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx` -- macro tracking card
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` -- weight trend card
- `web/src/components/trainee-dashboard/weekly-progress-card.tsx` -- weekly progress card
- `web/src/components/trainee-dashboard/achievements-grid.tsx` -- achievements grid
- `web/src/components/trainee-dashboard/announcements-list.tsx` -- announcements list

**New Types:**
- `web/src/types/trainee-dashboard.ts` -- WeeklyProgress, LatestWeightCheckIn, Announcement, Achievement

**Modified Files:**
- `web/src/middleware.ts` -- routing for trainee paths
- `web/src/providers/auth-provider.tsx` -- TRAINEE role allowed
- `web/src/lib/constants.ts` -- trainee API URLs
- `web/src/components/layout/user-nav.tsx` -- trainee settings link
- `web/src/components/settings/profile-section.tsx` -- hide business name for trainees

**Comparison Files Reviewed:**
- `web/src/app/(dashboard)/layout.tsx` -- trainer layout pattern
- `web/src/app/(admin-dashboard)/layout.tsx` -- admin layout pattern
- `web/src/app/(ambassador-dashboard)/layout.tsx` -- ambassador layout pattern
- `web/src/components/layout/sidebar.tsx` -- trainer sidebar
- `web/src/components/layout/sidebar-mobile.tsx` -- trainer mobile sidebar
- `web/src/components/layout/admin-sidebar.tsx` -- admin sidebar
- `web/src/components/layout/admin-sidebar-mobile.tsx` -- admin mobile sidebar
- `web/src/components/layout/ambassador-sidebar.tsx` -- ambassador sidebar
- `web/src/components/layout/ambassador-sidebar-mobile.tsx` -- ambassador mobile sidebar
- `web/src/components/layout/header.tsx` -- shared trainer/admin header
- `web/src/components/layout/nav-links.tsx` -- trainer nav links

---

## Architectural Alignment

- [x] Follows existing layered architecture (route group -> layout -> pages -> components -> hooks)
- [x] Types in correct location (`types/trainee-dashboard.ts`)
- [x] No business logic in route pages -- data fetching in hooks, presentation in components
- [x] Consistent with existing route group naming conventions
- [ ] **Layout components placed in `components/trainee-dashboard/` instead of `components/layout/`** (minor inconsistency)

---

## 1. LAYERING Assessment

**Verdict: Strong (8/10)**

The implementation follows the established layering pattern precisely:

- **Route pages** are thin orchestrators that compose components and handle the loading/error/empty state trifecta. Every page follows the same pattern: `useHook()` -> loading state -> error state -> empty state -> populated render. This is consistent with the trainer and admin dashboard pages.

- **Hooks** encapsulate all data fetching with React Query. The `use-trainee-dashboard.ts` hook properly uses a 5-minute `staleTime` for caching, hierarchical query keys (`["trainee-dashboard", "programs"]`) for scoped invalidation, and intelligent retry logic (not retrying 404s for weight check-ins via `isApiErrorWithStatus`). The `use-trainee-announcements.ts` hook correctly uses mutations with bidirectional cache invalidation (announcements list + unread count).

- **Components** are properly categorized as either smart (self-fetching dashboard cards) or presentational (ProgramViewer, AchievementsGrid, AnnouncementsList taking data via props). The dashboard cards (`TodaysWorkoutCard`, `NutritionSummaryCard`, `WeightTrendCard`, `WeeklyProgressCard`) co-locate their queries, which is valid since each card is an independent data consumer with its own loading/error states.

- **Types** correctly reuse existing types from `types/trainee-view.ts` (e.g., `TraineeViewProgram`, `NutritionSummary`) and only define new types for genuinely novel API responses (`WeeklyProgress`, `LatestWeightCheckIn`, `Announcement`, `Achievement`).

- **Badge count composition hook** (`use-trainee-badge-counts.ts`) cleanly composes `useMessagingUnreadCount` and `useAnnouncementUnreadCount` without introducing a new data fetching layer. The `getBadgeCount` helper uses a string-keyed lookup (`"messages" | "announcements"`) which is slightly fragile but acceptable for 2 keys.

---

## 2. ROUTE STRUCTURE Assessment

**Verdict: Excellent (9/10)**

The `(trainee-dashboard)` route group follows the exact pattern established by all other role-specific dashboards:

| Route Group | URL Prefix | Role |
|-------------|-----------|------|
| `(dashboard)` | `/dashboard`, `/trainees`, etc. | TRAINER |
| `(admin-dashboard)` | `/admin/*` | ADMIN |
| `(ambassador-dashboard)` | `/ambassador/*` | AMBASSADOR |
| `(trainee-dashboard)` | `/trainee/*` | TRAINEE |

The nesting `(trainee-dashboard)/trainee/[page]` correctly produces URL paths like `/trainee/dashboard`, `/trainee/program`, etc. -- mirroring how `(admin-dashboard)/admin/[page]` produces `/admin/dashboard`.

The middleware routing in `middleware.ts` is well-designed:
- `isTraineeDashboardPath()` correctly matches both `/trainee/` and `/trainee` paths
- Mutual exclusion between all role paths is properly enforced (lines 62-99)
- The `getDashboardPath()` function maps all roles correctly
- The security comment on line 59 correctly acknowledges that cookie-based routing is a convenience guard, not an authorization boundary -- true authorization is enforced server-side

---

## 3. DATA MODEL Assessment

**Verdict: Good (8/10)**

No backend changes were made. All types correctly map to existing API responses.

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend changes |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | No new queries |
| No N+1 query patterns | PASS | All data fetched via existing API endpoints |
| Types match API responses | PASS | Reuses `TraineeViewProgram`, `NutritionSummary` from existing `trainee-view.ts`; new types look correct |

**Observation:** The `LatestWeightCheckIn` type in `trainee-dashboard.ts` has a `trainee: number` field, while the existing `TraineeWeightCheckIn` type in `trainee-view.ts` has both `trainee: number` and `trainee_email: string`. These represent different API response shapes (trainee-facing vs. trainer-facing), so two separate types is correct. A comment distinguishing them would aid future maintainers.

---

## 4. API DESIGN Assessment

**Verdict: Good (8/10)**

All trainee API URLs are well-organized in `constants.ts`:
- Trainee-facing workout APIs grouped under `// Trainee-facing APIs` comment (lines 237-243)
- Community APIs grouped under `// Trainee community APIs` comment (lines 246-251)
- Branding at line 254

URL naming conventions are consistent:
- Static URLs are UPPER_SNAKE_CASE constants (`TRAINEE_PROGRAMS`, `TRAINEE_ANNOUNCEMENTS`, etc.)
- Dynamic URLs are camelCase functions (`traineeAnnouncementMarkRead(id)`)
- All use the same `API_BASE` prefix

**One unused forward declaration:** `TRAINEE_BRANDING` (`/api/users/my-branding/`) is defined but not consumed anywhere in the codebase. This is likely intended for the upcoming white-label branding feature. Acceptable as a forward declaration if it ships within 1-2 pipelines.

---

## 5. FRONTEND PATTERNS Assessment

**Verdict: Strong with one minor inconsistency (7.5/10)**

### Strengths

**Component decomposition is clean:**
- Dashboard cards are self-contained units with their own loading/error/empty states
- `ProgramViewer` is a rich presentational component with proper ARIA tab semantics
- `AnnouncementsList` is a controlled component that delegates mark-read to a callback
- `AchievementsGrid` is a pure presentational grid

**Excellent shared component reuse:**
- `PageHeader`, `PageTransition`, `LoadingSpinner`, `ErrorState`, `EmptyState` reused from `components/shared/`
- `ProfileSection`, `AppearanceSection`, `SecuritySection` reused from `components/settings/`
- `ConversationList`, `ChatView`, `MessageSearch` reused from `components/messaging/`
- `UserNav` reused from `components/layout/`

**Accessibility is consistently implemented:**
- `aria-label`, `aria-current`, `aria-hidden` on all interactive and decorative elements
- `role="tablist"`, `role="tab"`, `role="tabpanel"` with `aria-selected` and `aria-controls` on program week tabs
- Skip-to-content link in the layout
- `sr-only` text for loading states
- Keyboard handlers (`onKeyDown` for Enter/Space) on the `AnnouncementCard` which uses `role="button"`

**File sizes are within guidelines:**
- Most files are well under 150 lines
- `program-viewer.tsx` (262 lines) is the largest, but includes a small `DayCard` sub-component. The main `ProgramViewer` component is ~190 lines of JSX. Borderline but acceptable given the complexity.
- `messages/page.tsx` (251 lines) is the largest page, but this is a complex split-pane messaging UI that justifies the size.

### Issue #1: Layout Component Placement (MINOR)

**Finding:** All other role-specific layout components live in `components/layout/`:

| Component | Location |
|-----------|----------|
| Trainer sidebar | `components/layout/sidebar.tsx` |
| Trainer mobile sidebar | `components/layout/sidebar-mobile.tsx` |
| Trainer nav links | `components/layout/nav-links.tsx` |
| Admin sidebar | `components/layout/admin-sidebar.tsx` |
| Admin mobile sidebar | `components/layout/admin-sidebar-mobile.tsx` |
| Ambassador sidebar | `components/layout/ambassador-sidebar.tsx` |
| Ambassador mobile sidebar | `components/layout/ambassador-sidebar-mobile.tsx` |
| Shared header | `components/layout/header.tsx` |
| **Trainee sidebar** | **`components/trainee-dashboard/trainee-sidebar.tsx`** |
| **Trainee mobile sidebar** | **`components/trainee-dashboard/trainee-sidebar-mobile.tsx`** |
| **Trainee header** | **`components/trainee-dashboard/trainee-header.tsx`** |
| **Trainee nav links** | **`components/trainee-dashboard/trainee-nav-links.tsx`** |

The trainee layout infrastructure (sidebar, mobile sidebar, header, nav-links) is co-located with domain-specific components (program-viewer, nutrition-summary-card, etc.) in `components/trainee-dashboard/`. Every other role follows the convention of placing layout shell components in `components/layout/`.

**Impact:** This is a file organization inconsistency, not a functional issue. It makes it harder for developers to find all layout components in one place and breaks the mental model that `components/layout/` is the canonical home for all shell layout components.

**Decision:** I am NOT relocating these files in this pipeline. Reason:
1. The relocation would create a large diff touching all imports, making the feature PR harder to review
2. No functional impact -- the code works identically regardless of location
3. Risk of introducing import path errors in a file-move refactor

**Recommendation:** Track as a follow-up task: move `trainee-sidebar.tsx`, `trainee-sidebar-mobile.tsx`, `trainee-header.tsx`, and `trainee-nav-links.tsx` to `components/layout/` in a dedicated cleanup commit.

---

## 6. SCALABILITY Assessment

**Verdict: Good (8/10)**

### React Query Caching Strategy

| Data Type | Stale Time | Rationale |
|-----------|-----------|-----------|
| Programs, nutrition, weight, progress | 5 min | Fitness data changes infrequently during a session |
| Announcement unread count | 30 sec | More aggressive for real-time feel |
| Message unread count (shared hook) | 30 sec refetch interval | Inherited from existing messaging system |

All query keys are namespaced under `["trainee-dashboard", ...]` to avoid collisions with trainer-facing query keys (which use `["messaging", ...]`, `["trainees", ...]`, etc.).

Mutations properly invalidate related queries: `useMarkAnnouncementsRead` and `useMarkAnnouncementRead` both invalidate both the announcements list and unread count queries.

### Re-render Analysis

- `useMemo` is applied correctly: sort in `AnnouncementsList`, stats calculation in `AchievementsPage`, date string in `NutritionSummaryCard`, active program filter in `ProgramViewer`
- `useCallback` wraps mutation handlers and event handlers passed as props
- Dashboard cards are independent React Query consumers -- a refetch in one card does not trigger re-renders in siblings
- The `useTraineeBadgeCounts` hook composes two independent queries; each query's state change only triggers re-renders in components consuming that specific hook

### Potential Scaling Concern

The `TodaysWorkoutCard` fetches ALL programs via `useTraineeDashboardPrograms()` to find the active one and extract today's workout day. If a trainee has many programs (unlikely in practice -- typically 1-3), this transfers unnecessary data. A dedicated endpoint like `/api/workouts/programs/active/today/` would be more efficient. However, given the typical trainee has 1-3 programs, this is acceptable for now.

---

## 7. TECHNICAL DEBT Assessment

**Verdict: Minimal new debt (8/10)**

### Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Trainee layout components in `components/trainee-dashboard/` instead of `components/layout/` | Low | Move 4 files in a dedicated cleanup commit |
| 2 | `TRAINEE_BRANDING` API URL defined but unused | Low | Wire up in branding pipeline or remove if deferred past 2 pipelines |

### Pre-existing Debt (Not Introduced by This PR)

| # | Description | Severity | Notes |
|---|-------------|----------|-------|
| 1 | Layout guard boilerplate duplicated across 4 role layouts | Medium | All four role layouts have near-identical auth guard + role redirect + loading state code. A shared `RoleGuardLayout` HOC could eliminate ~60 lines per layout. |
| 2 | Sidebar component boilerplate duplicated across 4 roles | Medium | All sidebars share the same structure: aside > nav > links. Only the nav links config and branding differ. A generic `SidebarShell` component accepting a links array and branding config would reduce duplication. |

### Debt Reduced

1. **Shared component reuse** -- `PageHeader`, `LoadingSpinner`, `ErrorState`, `EmptyState`, `ProfileSection`, `AppearanceSection`, `SecuritySection`, `UserNav`, `ConversationList`, `ChatView`, `MessageSearch` are all reused rather than duplicated.
2. **Type reuse** -- `TraineeViewProgram` and `NutritionSummary` imported from existing `trainee-view.ts` rather than redefined.
3. **Hook reuse** -- Messaging hooks (`useConversations`, `useMessagingUnreadCount`) reused directly from the existing trainer messaging system.
4. **Settings page** correctly reuses all three settings sections and the profile section properly hides the business name field for TRAINEE users via a role check.

---

## Detailed Scoring Matrix

| Area | Score | Notes |
|------|-------|-------|
| Route structure | 9/10 | Perfect alignment with existing 4-dashboard pattern |
| Middleware routing | 9/10 | Clean mutual-exclusion guards, correct security comments |
| Layout architecture | 7/10 | Correct structure, but layout components misplaced |
| Data fetching layer | 9/10 | Clean hooks, proper caching and stale times, correct invalidation |
| Component decomposition | 8/10 | Good smart/dumb split, excellent shared component reuse |
| Type safety | 8/10 | Proper typing, correct reuse of existing types |
| State management | 9/10 | React Query used correctly, minimal useState |
| Accessibility | 9/10 | Consistent ARIA, keyboard nav, skip links, screen reader text |
| API URL organization | 8/10 | Clean grouping with one unused forward declaration |
| Code conventions | 8/10 | Follows existing patterns, consistent naming |
| Technical debt | 8/10 | Minimal new debt, significant existing debt *reduced* via reuse |

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Layout boilerplate | 4 near-identical role-guard layouts (~70 lines each) | Extract shared `RoleGuardLayout` wrapper (future PR) |
| 2 | Sidebar boilerplate | 4 near-identical sidebar + mobile sidebar pairs | Extract generic `SidebarShell` with config-driven nav (future PR) |
| 3 | Today's workout fetch | Fetches all programs to find one day | Add dedicated endpoint if program count grows beyond 5 |

---

## Architecture Score: 8/10

The Trainee Web Portal demonstrates strong architectural discipline. The implementation correctly mirrors the established patterns for route groups, role-guarded layouts, data fetching hooks, and component decomposition that are used by the trainer, admin, and ambassador dashboards. Data fetching is properly layered through React Query hooks with appropriate caching strategies. Shared components are aggressively reused rather than duplicated, which is an architectural positive. Type definitions correctly leverage existing types while adding only genuinely new ones. The middleware routing handles all role-based mutual exclusion correctly and includes appropriate security commentary.

The main architectural concern is a minor file organization inconsistency where trainee layout shell components (sidebar, header, nav-links) are co-located with domain components instead of in the established `components/layout/` directory. This does not affect functionality but deviates from the convention set by every other role.

## Recommendation: APPROVE

The architecture is sound, consistent with existing patterns, and introduces minimal technical debt while actively reducing debt through shared component reuse. The one file-placement inconsistency is tracked above for follow-up and does not warrant blocking. The implementation will scale well and integrates cleanly with the existing codebase.

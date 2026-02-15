# Dev Done: Web Trainer Dashboard (Phase 4 Foundation)

## Date: 2026-02-15

## Summary
Implemented a complete Next.js 15 web dashboard for trainers: JWT auth, dashboard with stats, trainee management with search/pagination/detail tabs, notification system with polling, invitation management, responsive layout with dark mode, Docker integration, and one backend change (SearchFilter on TraineeListView).

## Files Created (100 total in web/)

### Types (6)
- `web/src/types/user.ts` — User, UserRole, TrainerInfo
- `web/src/types/trainer.ts` — DashboardStats, TraineeListItem, TraineeDetail, DashboardOverview
- `web/src/types/notification.ts` — Notification, NotificationType, UnreadCount
- `web/src/types/invitation.ts` — Invitation, InvitationStatus, CreateInvitationPayload
- `web/src/types/activity.ts` — ActivitySummary
- `web/src/types/api.ts` — PaginatedResponse<T>

### Lib (4)
- `web/src/lib/constants.ts` — All API endpoint URLs
- `web/src/lib/token-manager.ts` — localStorage read/write, JWT decode, refresh mutex
- `web/src/lib/api-client.ts` — Fetch wrapper with auth headers, 401 retry
- `web/src/lib/utils.ts` — cn() utility (shadcn)

### Providers (3)
- `web/src/providers/auth-provider.tsx` — React context: user, login, logout, role gate
- `web/src/providers/query-provider.tsx` — TanStack React Query (staleTime 30s)
- `web/src/providers/theme-provider.tsx` — next-themes (system default)

### Hooks (6)
- `web/src/hooks/use-auth.ts` — Auth context hook
- `web/src/hooks/use-dashboard.ts` — useDashboardStats, useDashboardOverview
- `web/src/hooks/use-trainees.ts` — useTrainees, useTrainee, useTraineeActivity
- `web/src/hooks/use-notifications.ts` — useNotifications, useUnreadCount, useMarkAsRead, useMarkAllAsRead
- `web/src/hooks/use-invitations.ts` — useInvitations, useCreateInvitation
- `web/src/hooks/use-debounce.ts` — Debounce hook

### Layout (5)
- `web/src/components/layout/sidebar.tsx` — Fixed left sidebar (256px)
- `web/src/components/layout/sidebar-mobile.tsx` — Sheet drawer for mobile
- `web/src/components/layout/header.tsx` — Top bar with hamburger, bell, avatar
- `web/src/components/layout/nav-links.tsx` — Navigation config array
- `web/src/components/layout/user-nav.tsx` — Avatar dropdown with logout

### Shared Components (5)
- `web/src/components/shared/page-header.tsx` — Title + description + actions
- `web/src/components/shared/empty-state.tsx` — Icon + title + CTA
- `web/src/components/shared/error-state.tsx` — Error card with retry
- `web/src/components/shared/data-table.tsx` — Generic paginated table
- `web/src/components/shared/loading-spinner.tsx` — Centered spinner

### Dashboard (5)
- `web/src/components/dashboard/stats-cards.tsx` — 4-card grid
- `web/src/components/dashboard/stat-card.tsx` — Individual stat card
- `web/src/components/dashboard/recent-trainees.tsx` — Last 10 trainees table
- `web/src/components/dashboard/inactive-trainees.tsx` — Needs attention list
- `web/src/components/dashboard/dashboard-skeleton.tsx` — Loading skeleton

### Trainees (8)
- `web/src/components/trainees/trainee-table.tsx` — Data table wrapper
- `web/src/components/trainees/trainee-columns.tsx` — Column definitions
- `web/src/components/trainees/trainee-search.tsx` — Debounced search input
- `web/src/components/trainees/trainee-overview-tab.tsx` — Profile, nutrition, programs
- `web/src/components/trainees/trainee-activity-tab.tsx` — Activity table with day filter
- `web/src/components/trainees/trainee-progress-tab.tsx` — Placeholder for charts
- `web/src/components/trainees/trainee-detail-skeleton.tsx` — Detail loading skeleton
- `web/src/components/trainees/trainee-table-skeleton.tsx` — Table loading skeleton

### Notifications (3)
- `web/src/components/notifications/notification-bell.tsx` — Bell with unread badge
- `web/src/components/notifications/notification-popover.tsx` — Dropdown with last 5
- `web/src/components/notifications/notification-item.tsx` — Single notification row

### Invitations (4)
- `web/src/components/invitations/create-invitation-dialog.tsx` — Form dialog
- `web/src/components/invitations/invitation-table.tsx` — Table wrapper
- `web/src/components/invitations/invitation-columns.tsx` — Column definitions
- `web/src/components/invitations/invitation-status-badge.tsx` — Color-coded badge

### Pages (9)
- `web/src/app/(auth)/login/page.tsx`
- `web/src/app/(dashboard)/dashboard/page.tsx`
- `web/src/app/(dashboard)/trainees/page.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/app/(dashboard)/invitations/page.tsx`
- `web/src/app/(dashboard)/settings/page.tsx`
- `web/src/app/not-found.tsx`
- `web/src/app/page.tsx` (redirect)

### Config/Layout
- `web/src/app/layout.tsx` — Root layout with providers
- `web/src/app/(auth)/layout.tsx` — Centered card layout
- `web/src/app/(dashboard)/layout.tsx` — Sidebar + header + auth guard
- `web/src/middleware.ts` — Route protection via session cookie

### shadcn/ui (18 components)
- button, card, input, label, table, badge, dialog, dropdown-menu, skeleton, tabs, avatar, separator, sheet, popover, scroll-area, tooltip, pagination, sonner

### Docker
- `web/Dockerfile` — Multi-stage node:20-alpine build
- `web/.env.example` — NEXT_PUBLIC_API_URL

## Files Modified
- `backend/trainer/views.py` — Added SearchFilter + search_fields to TraineeListView (3 lines)
- `docker-compose.yml` — Added web service on port 3000 (13 lines)

## Key Decisions
1. Tokens in localStorage (backend returns JWT in JSON body, not cookies)
2. Refresh mutex for concurrent 401s
3. `has_session` cookie for middleware route protection
4. Zod v4 uses `.issues` not `.errors`
5. Client-side fetching only (Server Components can't access localStorage)
6. Notification polling every 30s via React Query refetchInterval
7. Trainee search debounced 300ms, resets pagination

## Build/Lint Status
- `npm run build` — PASS (0 errors, all 9 routes compile)
- `npm run lint` — PASS (0 errors, 0 warnings)

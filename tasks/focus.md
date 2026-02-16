# Pipeline 13 Focus: Admin Dashboard (Web)

## Priority
Complete the final Phase 4 item: Admin dashboard for the web application. This gives the platform super admin full management capabilities via the web.

## Context
- The trainer web dashboard is fully built (Pipelines 9-12)
- Backend admin APIs already exist at `/api/admin/`
- Existing patterns: DataTable, PageHeader, EmptyState, ErrorState, LoadingSpinner, StatCard
- Auth system with role-based access already in place
- shadcn/ui component library available

## Scope
- Admin-only section with role-gated access (ADMIN users only)
- Admin dashboard overview (platform stats: trainers, trainees, revenue, growth)
- Trainer management (list, view details, activate/suspend)
- Subscription tier management (CRUD)
- Coupon management (CRUD)
- User management (list all users, view by role)
- Platform analytics (revenue trends, user growth)

# Pipeline 38 Focus: Admin Dashboard Mobile Responsiveness

## Priority
Make the **admin web dashboard** fully mobile-friendly. The trainee portal was optimized in Pipeline 36, the trainer dashboard in Pipeline 37 — now apply the same treatment to the admin-facing pages.

## Scope
All pages under the `(admin-dashboard)` layout used by super admins:
- Admin dashboard overview (stats, revenue, tier breakdown)
- Trainer management (list, detail, impersonation)
- Subscription management (list, detail, actions)
- Tier management (CRUD, toggle active)
- Coupon management (CRUD, filters, usage history)
- User management (list, create/edit)
- Ambassador management (list, create, detail, commissions)
- Admin settings (platform config, security, profile)
- Upcoming/past due payments

## Key Areas
1. Tables (trainer list, subscription list, tier list, coupon list, user list, ambassador list) — responsive column hiding on mobile
2. Dialog/modal overflow — all admin dialogs scrollable at mobile viewport
3. Touch targets — minimum 44px on interactive elements
4. Form layouts — stack vertically on mobile
5. Stat cards — responsive grid
6. Action buttons — stack or grid on mobile
7. Detail dialogs with tabs — scrollable/responsive

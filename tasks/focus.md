# Pipeline 19 Focus: Web Dashboard Full Parity + UI Polish + E2E Tests

## Priority
Bring the web dashboard to FULL feature parity with the mobile app for Trainer, Admin, and Ambassador roles. Redesign the UI to world-class standards. Write comprehensive E2E tests.

## Three Workstreams

### Workstream 1: Feature Parity (41 missing features)

#### Trainer Features (10 missing)
1. **Program Assignment** — Assign program to trainee from trainee detail page
2. **Program Management** — Change/swap/end program from trainee detail
3. **Edit Trainee Goals** — Modify trainee goals (macros, weight target, etc.)
4. **Remove/Deactivate Trainee** — Remove trainee with confirmation
5. **Trainer Announcements** — Create/edit/delete/pin announcements, list view
6. **Trainer AI Chat** — AI assistant interface for trainers
7. **Branding/White-Label** — Logo, colors, app name configuration
8. **Exercise Bank** — Browse, create custom exercises
9. **Trainer Subscription Management** — View/manage subscription, pricing, Stripe Connect
10. **Calendar Integration** — Google/Microsoft calendar sync

#### Admin Features (5 missing)
11. **Ambassador Management Module** — List ambassadors, detail view, create new
12. **Ambassador Commissions** — Approve/pay commissions, bulk actions
13. **Upcoming Payments Calendar** — Payment schedule visualization
14. **Past Due Alerts Page** — Dedicated past due management
15. **Admin Settings** — Full security/platform settings (not placeholder)

#### Ambassador Features (4 missing — entire role)
16. **Ambassador Dashboard** — Earnings overview, referral stats, share link
17. **Ambassador Payouts** — Stripe Connect onboarding, payout history
18. **Ambassador Referrals** — Referral tracking, conversion stats
19. **Ambassador Settings** — Profile, commission preferences

#### Community/Social Features (5 missing)
20. **Announcements Feed** — View announcements (trainee-facing, but trainers manage from web)
21. **Community Feed** — Social feed with posts, reactions, comments
22. **Achievements** — Badge grid, progress tracking
23. **Leaderboard** — Rankings view
24. **Feature Requests** — Submit, view, vote on feature requests

### Workstream 2: UI/UX Polish & Design Overhaul
- **Login page redesign** — Fitness-themed with motion/animations (particles, gradients, dynamic elements)
- **Animations & transitions** — Page transitions, skeleton loading, micro-interactions, hover effects
- **Dashboard critique** — Evaluate spacing, typography, color usage, card design, data visualization
- **Responsive design** — Ensure all new pages work on tablet/mobile web
- **Dark mode** — Ensure new pages support the existing dark mode toggle
- **Empty states** — Beautiful empty states for all new pages
- **Loading states** — Skeleton shimmer loading for all data-dependent views
- **Error states** — Helpful error messages with retry actions

### Workstream 3: E2E Testing
- **Playwright or Cypress** E2E test suite
- Test every role: Trainer, Admin, Ambassador
- Test every feature: login, navigation, CRUD operations, edge cases
- Test responsive behavior
- Test dark mode
- Test error states (invalid input, network errors)
- Test authentication/authorization (role-based access)

## Context
- Web: Next.js 15 + React 19 + TypeScript + shadcn/ui + TanStack React Query
- Backend: Django REST Framework (all APIs already exist from mobile implementation)
- All backend APIs already exist — this is frontend-only work for feature parity
- Existing web dashboard pattern: `web/src/` with app router, components, hooks, lib, providers, types

## What NOT to build
- Trainee web access (trainee role is mobile-only)
- Real-time WebSocket on web (use polling/refresh for V1)
- Mobile-specific features (offline sync, health data, push notifications)
- New backend APIs (everything needed already exists)

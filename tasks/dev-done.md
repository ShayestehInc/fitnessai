# Dev Done: Pipeline 19 — Web Dashboard Feature Parity, UI/UX Polish, E2E Tests

## Date: 2026-02-19

## Summary
Implemented comprehensive web dashboard update across three workstreams:
1. **Feature Parity** — Brought web dashboard to parity with mobile app features across trainer, admin, and ambassador roles
2. **UI/UX Polish** — Redesigned login page, added animations, micro-interactions, skeleton loading, page transitions
3. **E2E Tests** — Set up Playwright with 16+ test spec files across all user roles

---

## Files Changed/Created

### Infrastructure & Config
- `web/package.json` — Added framer-motion, @playwright/test, e2e scripts
- `web/playwright.config.ts` — Multi-browser Playwright configuration (Chromium, Firefox, WebKit, mobile)
- `web/src/lib/constants.ts` — Added ~30 new API URL entries
- `web/src/middleware.ts` — Added AMBASSADOR role routing and redirect guards
- `web/src/providers/auth-provider.tsx` — Accept AMBASSADOR role
- `web/src/app/globals.css` — Added CSS keyframes (gradient-shift, float), card-hover utility, prefers-reduced-motion

### Types (7 New)
- `web/src/types/announcement.ts` — Announcement, CreateAnnouncementPayload, UpdateAnnouncementPayload
- `web/src/types/ai-chat.ts` — ChatMessage, AiChatRequest, AiChatResponse, AiProvider
- `web/src/types/branding.ts` — TrainerBranding, UpdateBrandingPayload
- `web/src/types/subscription.ts` — StripeConnectStatus, TrainerPayment, TrainerSubscriber, TrainerPricing
- `web/src/types/calendar.ts` — CalendarConnection, CalendarEvent
- `web/src/types/feature-request.ts` — FeatureRequest, FeatureComment, CreateFeatureRequestPayload
- `web/src/types/ambassador.ts` — Ambassador, AmbassadorDashboardData, AmbassadorSelfReferral, AmbassadorPayout, etc.

### Hooks (10 New, 1 Modified)
- `web/src/hooks/use-announcements.ts` — CRUD mutations with queryClient invalidation
- `web/src/hooks/use-ai-chat.ts` — Local state + sendMessage with streaming
- `web/src/hooks/use-branding.ts` — useBranding, useUpdateBranding, useUploadLogo, useRemoveLogo
- `web/src/hooks/use-subscription.ts` — Stripe Connect status/onboard/dashboard, pricing, payments, subscribers
- `web/src/hooks/use-calendar.ts` — Connections, Google auth, events, disconnect
- `web/src/hooks/use-feature-requests.ts` — Feature requests CRUD + votes + comments
- `web/src/hooks/use-trainee-goals.ts` — useUpdateTraineeGoals
- `web/src/hooks/use-leaderboard-settings.ts` — useLeaderboardSettings, useUpdateLeaderboardSetting
- `web/src/hooks/use-admin-ambassadors.ts` — Full admin ambassador CRUD + commission management
- `web/src/hooks/use-ambassador.ts` — Ambassador self-service (dashboard, referrals, payouts, connect)
- `web/src/hooks/use-exercises.ts` — **Modified**: Added useCreateExercise, useUpdateExercise

### Layout & Navigation (5 New, 3 Modified)
- `web/src/components/layout/nav-links.tsx` — **Modified**: Added 6 trainer nav items (AI Chat, Exercises, Announcements, Feature Requests, Subscription, Calendar)
- `web/src/components/layout/admin-nav-links.ts` — **Modified**: Added 3 admin nav items (Ambassadors, Upcoming Payments, Past Due)
- `web/src/components/layout/user-nav.tsx` — **Modified**: Ambassador role routing
- `web/src/components/layout/ambassador-nav-links.ts` — **New**: 4 items (Dashboard, Referrals, Payouts, Settings)
- `web/src/components/layout/ambassador-sidebar.tsx` — **New**: Desktop sidebar
- `web/src/components/layout/ambassador-sidebar-mobile.tsx` — **New**: Mobile sheet sidebar
- `web/src/app/(ambassador-dashboard)/layout.tsx` — **New**: Ambassador layout with auth guards
- `web/src/app/(dashboard)/layout.tsx` — **Modified**: AMBASSADOR redirect

### Auth & Login (3 files)
- `web/src/components/auth/login-hero.tsx` — **New**: Animated hero with gradient, floating icons, tagline
- `web/src/app/(auth)/layout.tsx` — **Modified**: Two-column grid layout
- `web/src/app/(auth)/login/page.tsx` — **Modified**: Redesigned with framer-motion animations

### Shared Components & UI (3 files)
- `web/src/components/shared/page-transition.tsx` — **New**: framer-motion fade+slide wrapper
- `web/src/components/ui/button.tsx` — **Modified**: Added active:scale-[0.98] micro-interaction
- `web/src/components/dashboard/stat-card.tsx` — **Modified**: Added trend indicator (TrendingUp/Down)

### Trainer Features — Announcements (5 files)
- `web/src/components/announcements/announcement-list-skeleton.tsx`
- `web/src/components/announcements/announcement-delete-dialog.tsx`
- `web/src/components/announcements/announcement-form-dialog.tsx`
- `web/src/components/announcements/announcement-list.tsx`
- `web/src/app/(dashboard)/announcements/page.tsx`

### Trainer Features — AI Chat (6 files)
- `web/src/components/ai-chat/chat-skeleton.tsx`
- `web/src/components/ai-chat/suggestion-chips.tsx`
- `web/src/components/ai-chat/chat-message.tsx`
- `web/src/components/ai-chat/trainee-selector.tsx`
- `web/src/components/ai-chat/chat-container.tsx`
- `web/src/app/(dashboard)/ai-chat/page.tsx`

### Trainer Features — Exercises (6 files)
- `web/src/components/exercises/exercise-grid-skeleton.tsx`
- `web/src/components/exercises/exercise-card.tsx`
- `web/src/components/exercises/create-exercise-dialog.tsx`
- `web/src/components/exercises/exercise-detail-dialog.tsx`
- `web/src/components/exercises/exercise-list.tsx`
- `web/src/app/(dashboard)/exercises/page.tsx`

### Trainer Features — Subscription (2 files)
- `web/src/components/subscription/subscription-skeleton.tsx`
- `web/src/app/(dashboard)/subscription/page.tsx`

### Trainer Features — Calendar (2 files)
- `web/src/components/calendar/calendar-skeleton.tsx`
- `web/src/app/(dashboard)/calendar/page.tsx`

### Trainer Features — Feature Requests (4 files)
- `web/src/components/feature-requests/feature-list-skeleton.tsx`
- `web/src/components/feature-requests/create-feature-request-dialog.tsx`
- `web/src/components/feature-requests/feature-request-list.tsx`
- `web/src/app/(dashboard)/feature-requests/page.tsx`

### Trainer Features — Settings (3 files)
- `web/src/components/settings/branding-section.tsx` — White-label branding (colors, logo, app name)
- `web/src/components/settings/leaderboard-section.tsx` — Leaderboard metric toggles
- `web/src/app/(dashboard)/settings/page.tsx` — **Modified**: Added BrandingSection + LeaderboardSection

### Trainee Detail Enhancements (8 files)
- `web/src/components/trainees/edit-goals-dialog.tsx` — Edit nutrition goals (calories, protein, carbs, fat)
- `web/src/components/trainees/remove-trainee-dialog.tsx` — Remove with "REMOVE" confirmation
- `web/src/components/trainees/assign-program-action.tsx` — Assign/change program trigger
- `web/src/components/trainees/change-program-dialog.tsx` — Program selection dialog
- `web/src/components/trainees/layout-config-selector.tsx` — Workout layout picker (default/compact/detailed)
- `web/src/components/trainees/impersonate-trainee-button.tsx` — Trainer impersonation with audit warning
- `web/src/components/trainees/mark-missed-day-dialog.tsx` — Mark missed workout day
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — **Modified**: Added all actions + Settings tab

### Admin Features (8 files)
- `web/src/components/admin/ambassador-list.tsx` — Ambassador management with search
- `web/src/components/admin/create-ambassador-dialog.tsx` — Create ambassador form with validation
- `web/src/components/admin/ambassador-detail-dialog.tsx` — Detail + bulk approve/pay/payout
- `web/src/components/admin/upcoming-payments-list.tsx` — Payment forecast list
- `web/src/components/admin/past-due-full-list.tsx` — Overdue payments with severity colors
- `web/src/app/(admin-dashboard)/admin/ambassadors/page.tsx`
- `web/src/app/(admin-dashboard)/admin/upcoming-payments/page.tsx`
- `web/src/app/(admin-dashboard)/admin/past-due/page.tsx`
- `web/src/app/(admin-dashboard)/admin/settings/page.tsx` — **Modified**: Replaced "Coming soon" placeholder

### Ambassador Features (11 files)
- `web/src/components/ambassador/ambassador-dashboard-skeleton.tsx`
- `web/src/components/ambassador/dashboard-earnings-card.tsx`
- `web/src/components/ambassador/referral-code-card.tsx` — Copy/edit referral code
- `web/src/components/ambassador/recent-referrals-list.tsx`
- `web/src/components/ambassador/referral-list.tsx` — Full referral list with search
- `web/src/components/ambassador/stripe-connect-setup.tsx` — Payout account setup (3 states)
- `web/src/components/ambassador/payout-history.tsx` — Payout tracking
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/referrals/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/payouts/page.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/settings/page.tsx`

### E2E Tests (19 files)
- `web/e2e/helpers/auth.ts` — Login helper with test users for all 3 roles
- `web/e2e/helpers/test-utils.ts` — Shared utilities (waitForPageLoad, expectToast, expectEmptyState, etc.)
- `web/e2e/helpers/mock-api.ts` — API mocking helpers (mockLogin, mockDashboardStats, mockPaginatedList)
- `web/e2e/auth.spec.ts` — Login form, validation, error handling, responsive hero
- `web/e2e/navigation.spec.ts` — Route guards for all dashboard paths
- `web/e2e/responsive.spec.ts` — Mobile vs desktop layout tests
- `web/e2e/dark-mode.spec.ts` — Dark/light mode rendering
- `web/e2e/error-states.spec.ts` — 404 handling, API failure
- `web/e2e/trainer/dashboard.spec.ts` — Dashboard stats, navigation
- `web/e2e/trainer/trainees.spec.ts` — Trainee list, detail, actions
- `web/e2e/trainer/announcements.spec.ts` — CRUD dialog, validation
- `web/e2e/trainer/exercises.spec.ts` — Exercise bank, create dialog, validation
- `web/e2e/trainer/settings.spec.ts` — All settings sections visible
- `web/e2e/trainer/ai-chat.spec.ts` — Chat UI elements
- `web/e2e/trainer/feature-requests.spec.ts` — Submit dialog
- `web/e2e/trainer/subscription.spec.ts` — Stripe Connect status
- `web/e2e/trainer/calendar.spec.ts` — Calendar connections
- `web/e2e/admin/dashboard.spec.ts` — Admin nav, ambassador/payment pages
- `web/e2e/admin/ambassadors.spec.ts` — Ambassador CRUD, validation
- `web/e2e/admin/settings.spec.ts` — Platform config, security, profile
- `web/e2e/ambassador/dashboard.spec.ts` — Earnings cards, referral code
- `web/e2e/ambassador/referrals.spec.ts` — Referral list, search
- `web/e2e/ambassador/payouts.spec.ts` — Stripe Connect setup, history
- `web/e2e/ambassador/settings.spec.ts` — Profile, appearance, security

---

## Key Decisions

1. **framer-motion for animations** — Used framer-motion v12 for page transitions and login animations. CSS keyframes for background gradients to reduce JS overhead.

2. **PageTransition wrapper** — Created reusable `PageTransition` component wrapping framer-motion `AnimatePresence` + `motion.div` for consistent fade-in/slide-up on every page.

3. **Ambassador as separate route group** — Created `(ambassador-dashboard)` route group matching the pattern of `(admin-dashboard)` for complete role isolation with its own layout, sidebar, and auth guards.

4. **Stat card trend indicator** — Extended existing `StatCard` with optional `trend` and `trendLabel` props. Backward compatible.

5. **Button micro-interaction** — Added `active:scale-[0.98]` to button base styles for subtle press feedback. Works with `prefers-reduced-motion`.

6. **Remove trainee confirmation** — Requires typing "REMOVE" to confirm, preventing accidental deletion. Redirects to trainee list after success.

7. **Login two-column layout** — Desktop shows animated hero on left, form on right. Mobile shows form only. Hero has floating icons, gradient animation, feature pills.

8. **Branding section** — Preset color swatches + hex input with regex validation. Logo upload with file type/size validation (5MB, JPEG/PNG/WebP). Live preview.

9. **E2E test structure** — Organized by role with shared helpers. Tests designed to work with or without a running backend. Mock API helpers available for CI.

---

## Deviations from Ticket

- **Community features tab** — The community tab on trainee detail was not created because the backend community endpoints are not directly connected to the per-trainee context. Can be added as a follow-up.
- **Monthly earnings chart** — Omitted standalone chart component for ambassador dashboard because the data type doesn't include monthly breakdown array. The stat cards show the key metrics.
- **Onboarding checklist** — The dashboard onboarding checklist component was deferred as it requires specific backend endpoint for checklist state tracking.

---

## How to Manually Test

### Login Page
1. Navigate to `/login`
2. Desktop: Two-column layout with animated hero and form
3. Mobile: Form only, hero hidden
4. Submit empty form: browser validation
5. Invalid credentials: error toast

### Trainer Features
1. Login as trainer
2. Verify 6 new nav items: AI Chat, Exercises, Announcements, Feature Requests, Subscription, Calendar
3. Visit each page: content or empty states with proper skeletons
4. Settings: Branding (color pickers, logo upload, preview) and Leaderboard sections
5. Trainee detail: action buttons (Edit Goals, Assign Program, View as Trainee, Mark Missed, Remove)
6. Trainee detail Settings tab: Layout config selector

### Admin Features
1. Login as admin
2. Verify 3 new nav items: Ambassadors, Upcoming Payments, Past Due
3. Ambassadors: search, create dialog, detail with commission actions
4. Settings: Platform config, security notice, profile, appearance

### Ambassador Features
1. Login as ambassador -> `/ambassador/dashboard`
2. Stat cards, referral code (copy/edit), recent referrals
3. Referrals page: search, list
4. Payouts: Stripe Connect setup, payout history
5. Settings: profile, appearance, security

### E2E Tests
```bash
cd web
npx playwright install
npx playwright test
# or
npx playwright test --headed
```

# Dev Done: Full Trainer→Trainee Impersonation Token Swap (Web Dashboard)

## Date
2026-02-20

## Files Changed

### New Files
- `web/src/types/trainee-view.ts` — TypeScript types for impersonation response, trainee programs, nutrition summary, weight check-ins, and trainer impersonation state
- `web/src/hooks/use-trainee-view.ts` — React Query hooks for trainee-facing APIs (useTraineeProfile, useTraineePrograms, useNutritionSummary, useWeightCheckIns)
- `web/src/components/layout/trainer-impersonation-banner.tsx` — Trainer→trainee impersonation banner with sessionStorage management and end-impersonation handler
- `web/src/app/(trainee-view)/layout.tsx` — Minimal layout with impersonation banner, no sidebar, centered content
- `web/src/app/(trainee-view)/trainee-view/page.tsx` — Read-only trainee dashboard with 4 data cards
- `web/src/components/trainee-view/profile-card.tsx` — Profile summary card (name, email, onboarding status)
- `web/src/components/trainee-view/program-card.tsx` — Active program card with today's exercises
- `web/src/components/trainee-view/nutrition-card.tsx` — Today's nutrition card with macro progress bars
- `web/src/components/trainee-view/weight-card.tsx` — Recent weight check-ins with trend indicator

### Modified Files
- `web/src/components/trainees/impersonate-trainee-button.tsx` — Replaced no-op onSuccess with full token swap: save trainer tokens to sessionStorage, set trainee tokens, set TRAINEE role cookie, hard navigate to /trainee-view
- `web/src/middleware.ts` — Added TRAINEE role routing to /trainee-view, added isTraineeViewPath guard, updated getDashboardPath for TRAINEE
- `web/src/providers/auth-provider.tsx` — Allow TRAINEE role in fetchUser when trainer impersonation state exists in sessionStorage
- `web/src/lib/constants.ts` — Added TRAINEE_PROGRAMS, TRAINEE_NUTRITION_SUMMARY, TRAINEE_WEIGHT_CHECKINS, TRAINEE_USER_PROFILE URL constants

## Key Decisions
1. **Auth-provider modification**: The auth-provider rejects non-TRAINER/ADMIN/AMBASSADOR roles. Added a check for active trainer impersonation state in sessionStorage to allow TRAINEE role through.
2. **Separate sessionStorage key**: Using `fitnessai_trainer_impersonation` (different from the admin `fitnessai_impersonation` key) to avoid conflicts if admin→trainer→trainee chains ever exist.
3. **Nutrition summary endpoint**: Used the `/api/workouts/daily-logs/nutrition-summary/` endpoint instead of separate nutrition-goals + daily-logs calls. It returns goals, consumed, remaining, and meals in one response.
4. **Hard navigation**: Both start and end impersonation use `window.location.href` (not `router.push`) to clear React Query cache and force fresh data.
5. **No backend changes**: Backend `StartImpersonationView` and `EndImpersonationView` already return everything needed.

## Deviations from Ticket
- None. All 24 acceptance criteria are addressed.

## How to Manually Test
1. Log in as a trainer
2. Go to Trainees → click on a trainee
3. Click "View as Trainee" → confirm in dialog
4. Verify: amber banner appears, trainee view page shows 4 cards, URL is /trainee-view
5. Verify: Profile card shows trainee's name/email
6. Verify: Program card shows active program or "No program assigned"
7. Verify: Nutrition card shows today's macros or "No data logged today"
8. Verify: Weight card shows recent check-ins or "No weight data"
9. Click "End Impersonation" in the banner
10. Verify: redirected back to /trainees/{id}, trainer tokens restored, trainer dashboard accessible

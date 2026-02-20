# Pipeline 27 Focus: Full Trainer→Trainee Impersonation (Web Dashboard)

## Priority
Complete the trainer→trainee impersonation flow on the web dashboard. The button and confirmation dialog exist but the actual token swap is a no-op. This is the highest-impact remaining Phase 11 item with the least new infrastructure needed.

## Why This Feature
1. **Explicitly listed in Phase 11** — "Full impersonation token swap (web dashboard)" is marked as partial.
2. **Backend is 100% complete** — `StartImpersonationView` already returns trainee JWT tokens with impersonation metadata.
3. **Pattern is proven** — Admin→trainer impersonation works end-to-end with token swap, sessionStorage save, and impersonation banner. Same pattern, different roles.
4. **Button exists but does nothing useful** — `ImpersonateTraineeButton` calls the API, gets tokens back, then just redirects to `/dashboard`. The trainer never actually sees the trainee's view.
5. **Key trainer workflow** — Trainers need to see what their trainees see to debug issues and verify program assignments.

## Scope
- Web: Wire token swap in `ImpersonateTraineeButton` (save trainer tokens, set trainee tokens)
- Web: New `TrainerImpersonationBanner` component for the trainer→trainee impersonation banner
- Web: New `(trainee-view)` route group with a read-only trainee dashboard page
- Web: Trainee view page calls trainee-facing APIs (programs, daily logs, nutrition goals, weight check-ins)
- Web: Middleware update to route TRAINEE role to `/trainee-view`
- Web: "End Impersonation" restores trainer tokens and redirects back to trainee detail page

## What NOT to build
- Full trainee web experience (that's a separate multi-pipeline initiative)
- Write/edit capabilities in the trainee view (read-only only)
- Mobile impersonation changes (already works on mobile)
- New backend endpoints (backend is complete)

# UX Audit: Full Trainer→Trainee Impersonation Token Swap (Pipeline 27)

## Audit Date
2026-02-20

## Files Audited
- All 13 changed/new files in the trainee-view feature

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Minor | trainee-view/page.tsx | Read-Only badge `text-amber-600` lacks dark mode contrast | Added `dark:border-amber-400 dark:text-amber-400` | FIXED |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| — | — | All components have proper ARIA attributes | No fixes needed |

Items verified:
- Banner: `role="status"`, `aria-live="polite"`, `sr-only` impersonation mode text
- Skip to content link in layout
- Macro progress bars: `role="progressbar"` with `aria-valuenow/min/max/label`
- All decorative icons: `aria-hidden="true"`
- Loading states: `role="status"`, `aria-label`, `sr-only` loading text
- Error states: `role="alert"`, retry buttons with clear labels
- Buttons: proper disabled state during pending operations

## Missing States
- [x] Loading / skeleton — All 4 cards have dedicated skeleton components
- [x] Empty / zero data — Contextual empty states per card
- [x] Error / failure — ErrorState with retry per card
- [x] Success / confirmation — Toast on impersonation start
- [x] Offline / degraded — React Query retry + 5-min staleTime
- [x] Permission denied — Layout guard + middleware redirect
- [x] Disabled — Button disabled during pending mutations

## Overall UX Score: 9/10

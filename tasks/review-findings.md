# Code Review: Trainee Web — Trainer Branding Application (Pipeline 34)

## Review Date: 2026-02-23

## Files Reviewed
- `web/src/hooks/use-trainee-branding.ts` (new)
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` (modified)
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` (modified)

## Critical Issues (must fix before merge)
None found.

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | trainee-sidebar.tsx:66-70 | Dead CSS variable `--sidebar-accent-brand` set on aside but never consumed | Remove the `style` prop entirely | FIXED |
| 2 | use-trainee-branding.ts:7 | `TraineeBranding` type not exported | Export the interface | FIXED |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | trainee-sidebar.tsx:153 | Hardcoded `"#6366F1"` for case-sensitive color comparison | Created `hasCustomPrimaryColor()` helper with `.toLowerCase()` | FIXED |
| 2 | trainee-sidebar-mobile.tsx:89 | Same hardcoded color comparison | Same fix applied | FIXED |

## Security Concerns
- None. No user input rendered as HTML. Logo URLs from trusted backend. `next/image` with `unoptimized` is safe.

## Performance Concerns
- None. React Query caches branding with 5-min staleTime. Logo is small (max 1024x1024 at source, rendered at 24x24).

## Quality Score: 8/10
## Recommendation: APPROVE

All issues found in R1 have been fixed. Code is clean, focused, and well-structured.

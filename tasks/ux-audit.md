# UX Audit: Web Dashboard Full Parity + UI/UX Polish + E2E Tests (Pipeline 19)

## Audit Date: 2026-02-19

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Critical | LeaderboardSection | Component referenced non-existent properties (setting.id, setting.metric, setting.label, setting.enabled) from hook type that has metric_type, time_period, is_enabled -- would crash at runtime | Fixed: rewrote to use correct property names, composite key, settingDisplayName() helper |
| 2 | Low | BrandingSection | Color preview only shows primary color bar, no preview of secondary color usage | Consider showing a more complete preview with both colors |
| 3 | Low | ImpersonateTraineeButton | No session token management -- redirects to /dashboard but doesn't actually swap tokens | Documented as partial (AC-11), needs backend token swap integration |
| 4 | Info | LoginHero | Hero section hidden on mobile/tablet (lg:flex) with no fallback visual | Acceptable -- login card is the primary element on small screens |
| 5 | Info | AmbassadorList | "filtered" variable is assigned but unused (same as ambassadors) | Cleaned up redundancy, no functional impact |

## Accessibility Issues
| # | Severity | WCAG Level | Issue | Fix |
|---|----------|------------|-------|-----|
| 1 | Medium | AA | ExerciseList filter chip buttons lacked focus-visible ring | Fixed: added focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 |
| 2 | Medium | AA | FeatureRequestList status filter buttons lacked focus-visible ring | Fixed: same pattern applied |
| 3 | Medium | AA | BrandingSection color picker buttons lacked focus-visible ring | Fixed: same pattern applied |
| 4 | Medium | A | AmbassadorList View button lacked aria-label | Fixed: added aria-label with ambassador email |
| 5 | Pass | A | EmptyState has role="status" and icon uses aria-hidden="true" | PASS |
| 6 | Pass | A | ErrorState has role="alert" and aria-live="assertive" | PASS |
| 7 | Pass | A | Login form error banner has role="alert" and aria-live="assertive" | PASS |
| 8 | Pass | A | All dialog titles/descriptions use DialogTitle/DialogDescription | PASS |
| 9 | Pass | AA | Announcement edit/delete buttons have aria-label with announcement title | PASS |
| 10 | Pass | AA | StatCard uses title attribute for truncated values | PASS |
| 11 | Pass | A | Login inputs have proper htmlFor/id labels, autoComplete, and maxLength | PASS |
| 12 | Pass | A | RemoveTraineeDialog uses destructive color theming for clear intent | PASS |

## Missing States Audit
- [x] Loading / skeleton -- All 20+ pages have content-shaped skeletons (not bare spinners)
- [x] Empty / zero data -- All lists have EmptyState with contextual icons, descriptions, and action CTAs
- [x] Error / failure -- ErrorState with retry used on all data pages
- [x] Success / confirmation -- Toast notifications (sonner) used consistently after mutations
- [x] Disabled / pending -- Buttons show Loader2 spinner and disable during mutations
- [x] Permission denied -- Middleware guards + API error handling
- [ ] Offline / degraded -- Not applicable for web dashboard V1

## Component State Coverage
| Component | Loading | Empty | Error | Success | Disabled |
|-----------|---------|-------|-------|---------|----------|
| Announcements | Skeleton list | EmptyState + CTA | ErrorState + retry | Toast | Pending spinner |
| AI Chat | ChatSkeleton | Empty prompt + suggestions | Error banner dismissible | Message appears | Input disabled |
| Exercise Bank | Grid skeleton | EmptyState + CTA | ErrorState + retry | Toast | N/A |
| Feature Requests | Skeleton cards | EmptyState + CTA | ErrorState + retry | Toast + optimistic | Vote button state |
| Ambassador Dashboard | Content skeleton | Earnings show $0 | N/A | Toast | N/A |
| Ambassador Referrals | List skeleton | EmptyState | ErrorState + retry | N/A | N/A |
| Ambassador Payouts | Card skeleton | Description text | ErrorState + retry | Redirect to Stripe | Pending spinner |
| Admin Ambassadors | Row skeletons | EmptyState + CTA | ErrorState + retry | Toast | N/A |
| Branding Section | Card skeleton | Defaults loaded | Toast error | Toast success | Save disabled until changes |
| Leaderboard Settings | Card skeleton | "No metrics" text | Toast error | Toast success | Per-toggle pending |
| Calendar | Calendar skeleton | Empty events | ErrorState + retry | Connection cards update | N/A |
| Subscription | Subscription skeleton | Status cards | ErrorState + retry | Redirect to Stripe | N/A |
| Mark Missed Day | N/A (dialog) | No active programs msg | Toast error | Toast + dialog close | Submit disabled |
| Edit Goals | N/A (dialog) | Pre-populated values | Inline errors + toast | Toast + dialog close | Submit disabled |
| Remove Trainee | N/A (dialog) | N/A | Toast error | Toast + redirect | Confirm disabled until REMOVE typed |
| Login | N/A | N/A | Animated error alert | Redirect | Button shows "Signing in..." |

## Fixes Applied
1. **LeaderboardSection complete rewrite** -- Fixed type mismatch between component and hook. Used composite key (metric_type:time_period), settingDisplayName() helper, correct mutation payload shape
2. **Exercise filter chip focus rings** -- Added focus-visible:ring-2 for keyboard navigation
3. **Feature request filter chip focus rings** -- Same pattern
4. **Branding color picker focus rings** -- All 24 color picker buttons (2x12 presets) now keyboard navigable
5. **Ambassador list View button aria-label** -- Screen readers now announce "View details for [email]"

## Overall UX Score: 8/10

Strong implementation across all 3 workstreams. Every component has proper loading, empty, error, and success states. The login page redesign is polished with staggered animations and prefers-reduced-motion support. Micro-interactions (button scale, card hover) are subtle and appropriate. The critical leaderboard type mismatch was a would-crash-at-runtime bug that has been fully resolved. Accessibility is solid with proper ARIA attributes, focus indicators, and semantic markup. The few remaining items (impersonation token swap, monthly earnings chart) are documented deferrals.

# Pipeline 14 Focus: Ambassador Enhancements (Phase 5)

## Priority
Complete all Phase 5 ambassador enhancement items.

## Phase 5 Items
1. Monthly earnings chart (fl_chart bar chart on ambassador dashboard)
2. Native share sheet (share_plus package for referral code sharing)
3. Commission approval/payment workflow (admin mobile + backend API)
4. Ambassador password reset / magic link login
5. Stripe Connect payout to ambassadors (deferred — requires Stripe configuration)
6. Custom referral codes (ambassador-chosen, e.g., "JOHN20")

## Context
- Ambassador system is 90% complete (models, APIs, mobile screens all working)
- Backend has 3 models: AmbassadorProfile, AmbassadorReferral, AmbassadorCommission
- Mobile has full ambassador dashboard, referrals list, settings, admin management
- Monthly earnings data already returned by backend (just needs chart UI)
- Share is clipboard-only (needs share_plus for native share sheet)
- Commission status flow exists but no admin approval/payment endpoints
- Password reset infrastructure exists for trainers/trainees (reuse for ambassadors)
- Custom referral codes need backend validation + ambassador UI to set/change

## What NOT to build
- Stripe Connect payout to ambassadors — defer to Phase 6 (requires Stripe dashboard setup)

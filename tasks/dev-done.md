# Dev Done: Ambassador User Type & Referral Revenue Sharing

## Summary
Full implementation of the Ambassador role with referral tracking, commission management, and dashboard UI. Ambassadors recruit trainers for the platform and earn monthly commissions from referred trainers' subscriptions.

## Files Created

### Backend — New Django App (`ambassador/`)
- `backend/ambassador/__init__.py`
- `backend/ambassador/apps.py` — AppConfig
- `backend/ambassador/models.py` — AmbassadorProfile, AmbassadorReferral, AmbassadorCommission
- `backend/ambassador/serializers.py` — All model serializers + dashboard/admin serializers
- `backend/ambassador/views.py` — Ambassador dashboard, referrals, referral-code; Admin list, create, detail/update
- `backend/ambassador/urls.py` — URL patterns for both ambassador and admin endpoints
- `backend/ambassador/admin.py` — Django admin registration
- `backend/ambassador/services/__init__.py`
- `backend/ambassador/services/referral_service.py` — ReferralService with process_referral_code, create_commission, handle_trainer_churn
- `backend/ambassador/migrations/__init__.py`
- `backend/ambassador/migrations/0001_initial.py` — Auto-generated

### Mobile — Ambassador Feature
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart` — Data models (AmbassadorDashboardData, AmbassadorProfile, AmbassadorReferral, etc.)
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` — API calls
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart` — Riverpod state management
- `mobile/lib/features/ambassador/presentation/screens/ambassador_navigation_shell.dart` — 3-tab navigation
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` — Dashboard with earnings, referral code, stats
- `mobile/lib/features/ambassador/presentation/screens/ambassador_referrals_screen.dart` — Filterable referral list
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart` — Profile, commission, logout

### Mobile — Admin Ambassador Management
- `mobile/lib/features/admin/presentation/screens/admin_ambassadors_screen.dart` — Searchable list with active/inactive filter
- `mobile/lib/features/admin/presentation/screens/admin_create_ambassador_screen.dart` — Form with commission rate slider
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart` — Detail with referral list, activate/deactivate

## Files Modified

### Backend
- `backend/users/models.py` — Added AMBASSADOR to Role enum, added is_ambassador() method
- `backend/core/permissions.py` — Added IsAmbassador, IsAmbassadorOrAdmin permission classes
- `backend/config/settings.py` — Added 'ambassador' to INSTALLED_APPS
- `backend/config/urls.py` — Added ambassador URL include
- `backend/users/serializers.py` — Added referral_code field to UserCreateSerializer, process referral on registration
- `backend/users/migrations/0005_alter_user_role.py` — Auto-generated for role choices update

### Mobile
- `mobile/lib/features/auth/data/models/user_model.dart` — Added isAmbassador getter
- `mobile/lib/core/constants/api_constants.dart` — Added 9 ambassador endpoints
- `mobile/lib/core/router/app_router.dart` — Added ambassador shell with 3 branches, ambassador redirect, admin ambassador routes
- `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Added referralCode parameter to register
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` — Added referralCode parameter to register
- `mobile/lib/features/auth/presentation/screens/register_screen.dart` — Added optional referral code field (shown only for TRAINER role)
- `mobile/lib/features/admin/presentation/screens/admin_dashboard_screen.dart` — Added Ambassadors quick action button

## Key Design Decisions
1. **Referral code = 8-char uppercase alphanumeric** — Human-readable, auto-generated
2. **Commission rate snapshot** — Frozen at time of charge, admin changes only affect future commissions
3. **Silent referral code handling** — Invalid/missing codes never block registration (logged as warning)
4. **First referral wins** — If trainer already has a referral, subsequent codes ignored
5. **Self-referral blocked** — Email match check prevents ambassador from referring themselves
6. **Soft-delete for ambassadors** — is_active=False preserves historical data
7. **Referral code only for TRAINER registration** — UI field conditionally shown
8. **Three status states** — PENDING → ACTIVE (first payment) → CHURNED (cancel); CHURNED → ACTIVE (resubscribe)

## Acceptance Criteria Status
- [x] AC-1: AMBASSADOR role + is_ambassador()
- [x] AC-2: IsAmbassador + IsAmbassadorOrAdmin permissions
- [x] AC-3: AmbassadorProfile model
- [x] AC-4: AmbassadorReferral model
- [x] AC-5: AmbassadorCommission model
- [x] AC-6: GET /api/ambassador/dashboard/
- [x] AC-7: GET /api/ambassador/referrals/ (paginated)
- [x] AC-8: GET /api/ambassador/referral-code/
- [x] AC-9: GET /api/admin/ambassadors/ (with search)
- [x] AC-10: POST /api/admin/ambassadors/create/
- [x] AC-11: PUT /api/admin/ambassadors/<id>/
- [x] AC-12: GET /api/admin/ambassadors/<id>/
- [x] AC-13: referral_code field on registration
- [x] AC-14: Commission creation service (ready for subscription webhook integration)
- [x] AC-15: Ambassador navigation shell (3 tabs)
- [x] AC-16: Router redirect for ambassador users
- [x] AC-17: Dashboard screen with stats, earnings chart, recent referrals
- [x] AC-18: Referral code card with copy + share
- [x] AC-19: Referrals screen with status filter
- [x] AC-20: Settings screen with profile, commission rate, earnings
- [x] AC-21: Ambassadors button on admin dashboard
- [x] AC-22: Admin ambassador list with search/filter
- [x] AC-23: Admin create ambassador screen
- [x] AC-24: Admin ambassador detail with referrals and activate/deactivate
- [x] AC-25: Referral code field on trainer registration screen

## Manual Testing
1. Create ambassador: Admin → Ambassadors → Create → Fill form → Submit
2. Ambassador login: Use ambassador email → Should redirect to /ambassador
3. Ambassador dashboard: Shows earnings, referral code, stats
4. Copy referral code: Tap copy icon → Should show green snackbar
5. Share referral code: Tap share button → Copies share message to clipboard
6. Referrals screen: Filter by Active/Pending/Churned
7. Trainer registration with code: Register → Select Trainer role → Enter referral code → Submit
8. Admin ambassador detail: Admin → Ambassadors → Tap ambassador → See referral list
9. Deactivate ambassador: Detail → Tap pause icon → Confirm

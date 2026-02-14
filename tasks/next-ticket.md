# Feature: Ambassador User Type & Referral Revenue Sharing

## Priority
High — #4 priority per CLAUDE.md (skipping Web Dashboard which requires greenfield React/Next.js project). Directly impacts trainer acquisition and platform revenue growth.

## User Story
As an **admin**, I want to create ambassador accounts with referral codes and commission rates so that ambassadors can recruit trainers for the platform.

As an **ambassador**, I want a dashboard showing my referred trainers, monthly earnings, and total commission so that I can track my referral revenue.

As a **trainer**, I want to enter a referral code during registration so that the ambassador who referred me gets credited.

## Acceptance Criteria

### Backend — User Role
- [ ] AC-1: `AMBASSADOR` added to `User.Role` TextChoices enum. `is_ambassador()` helper method added.
- [ ] AC-2: `IsAmbassador` and `IsAmbassadorOrAdmin` permission classes added to `core/permissions.py`.

### Backend — Models (new `ambassador` app)
- [ ] AC-3: `AmbassadorProfile` model — OneToOneField to User (AMBASSADOR), `referral_code` (unique, auto-generated), `commission_rate` (DecimalField, default 0.20), `is_active` (BooleanField, default True), `total_referrals` (cached count), `total_earnings` (cached Decimal), `created_at`, `updated_at`.
- [ ] AC-4: `AmbassadorReferral` model — ForeignKey to ambassador (User), ForeignKey to trainer (User), `referral_code_used` (CharField), `status` (PENDING/ACTIVE/CHURNED), `referred_at` (auto_now_add), `activated_at` (null — set when trainer's first subscription payment clears), `churned_at` (null).
- [ ] AC-5: `AmbassadorCommission` model — ForeignKey to ambassador (User), ForeignKey to referral (AmbassadorReferral), `commission_rate` (snapshot at time of charge), `base_amount` (trainer's subscription payment), `commission_amount` (calculated), `status` (PENDING/APPROVED/PAID), `period_start`, `period_end`, `created_at`.

### Backend — Ambassador API
- [ ] AC-6: `GET /api/ambassador/dashboard/` — Returns: total_referrals, active_referrals, total_earnings, pending_earnings, monthly_earnings (last 6 months), recent_referrals (last 5). Requires IsAmbassador.
- [ ] AC-7: `GET /api/ambassador/referrals/` — List of ambassador's referred trainers with status, subscription tier, and commission earned. Requires IsAmbassador. Paginated.
- [ ] AC-8: `GET /api/ambassador/referral-code/` — Returns the ambassador's referral code and a shareable message. Requires IsAmbassador.

### Backend — Admin API
- [ ] AC-9: `GET /api/admin/ambassadors/` — List all ambassadors with stats (referrals, earnings, active status). Requires IsAdmin. Search by email/name.
- [ ] AC-10: `POST /api/admin/ambassadors/` — Create a new ambassador account (email, first_name, last_name, commission_rate). Auto-generates referral code. Requires IsAdmin.
- [ ] AC-11: `PUT /api/admin/ambassadors/<id>/` — Update ambassador's commission_rate, is_active status. Requires IsAdmin.
- [ ] AC-12: `GET /api/admin/ambassadors/<id>/` — Ambassador detail with full referral list and commission history. Requires IsAdmin.

### Backend — Registration Integration
- [ ] AC-13: `POST /api/auth/users/` (registration) — Accept optional `referral_code` field. If valid, create `AmbassadorReferral` linking the new trainer to the ambassador. If invalid/expired, silently ignore (don't block registration).
- [ ] AC-14: When a referred trainer's subscription payment succeeds, create an `AmbassadorCommission` record. Set referral status to ACTIVE on first payment.

### Mobile — Ambassador Shell
- [ ] AC-15: Ambassador navigation shell with 3 tabs: Dashboard, Referrals, Settings.
- [ ] AC-16: Splash screen + router redirect ambassador users to `/ambassador` route.

### Mobile — Ambassador Dashboard
- [ ] AC-17: Dashboard screen showing: total referrals, active referrals, total earnings, pending earnings, monthly earnings chart (last 6 months), recent referrals list.
- [ ] AC-18: Referral code card with "Copy Code" and "Share" buttons.

### Mobile — Referrals Screen
- [ ] AC-19: List of referred trainers with: name, email, status badge (pending/active/churned), subscription tier, date referred, total commission earned from this trainer.

### Mobile — Ambassador Settings
- [ ] AC-20: Settings screen showing: profile info (email, name), commission rate (read-only, admin-set), referral code, total lifetime earnings.

### Mobile — Admin Ambassador Management
- [ ] AC-21: "Ambassadors" section in admin dashboard with count tile.
- [ ] AC-22: Admin ambassador list screen with search and active/inactive filter.
- [ ] AC-23: Admin create ambassador screen (email, first_name, last_name, commission_rate).
- [ ] AC-24: Admin ambassador detail screen showing referrals and commission history.

### Mobile — Registration
- [ ] AC-25: Optional "Referral Code" field on trainer registration screen. Hint: "Have a referral code? Enter it here."

## Edge Cases
1. **Invalid referral code on registration** — Silently ignore. Don't block trainer from registering. Log a warning.
2. **Ambassador account deactivated** — Existing referrals stay active (trainer still connected). No new commissions generated. Ambassador dashboard shows "Account suspended" banner.
3. **Trainer churns (cancels subscription)** — Mark referral as CHURNED. No more commissions generated for this trainer. If trainer resubscribes, referral reactivates.
4. **Ambassador refers themselves** — Reject. Email match check in registration.
5. **Duplicate referral** — If trainer already has an ambassador, the first referral wins. Subsequent codes are silently ignored.
6. **Commission rate changed by admin** — New rate applies to future commissions only. Historical commissions keep their snapshot rate.
7. **Trainer downgrades tier** — Commission recalculates based on new subscription amount.
8. **Ambassador has zero referrals** — Dashboard shows empty state with encouragement and share CTA.
9. **Very long referral code sharing** — Code should be short and human-friendly (8 chars, alphanumeric).
10. **Admin deletes ambassador** — Soft-delete (is_active=False). Historical data preserved.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Ambassador dashboard API fails | Error state with retry button | Return cached data if available |
| Referral code copy fails | "Failed to copy" snackbar | Fallback to text selection |
| Admin creates ambassador with existing email | "Email already in use" error | 400 response with clear message |
| Commission calculation fails | Admin sees pending commission with error flag | Log error, mark commission as PENDING for manual review |
| Referral code not found during registration | Nothing (silent ignore) | Log warning, continue registration normally |

## UX Requirements
- **Loading state:** Skeleton loader on dashboard and referral list.
- **Empty state:** Dashboard with 0 referrals shows "Share your referral code to start earning" with prominent Share button.
- **Error state:** Error icon + message + Retry button.
- **Success feedback:** Green SnackBar on referral code copy, ambassador creation.
- **Ambassador dashboard tone:** Revenue-focused. Show earnings prominently. Monthly chart shows growth trend.

## Technical Approach

### Backend (files to create/modify)
- **Create:** `backend/ambassador/` — New Django app (models.py, views.py, serializers.py, urls.py, services/, admin.py, apps.py)
- **Create:** `backend/ambassador/models.py` — AmbassadorProfile, AmbassadorReferral, AmbassadorCommission
- **Create:** `backend/ambassador/serializers.py` — Serializers for all models + dashboard stats
- **Create:** `backend/ambassador/views.py` — Ambassador dashboard, referrals, admin CRUD
- **Create:** `backend/ambassador/services/referral_service.py` — Referral code generation, commission calculation
- **Create:** `backend/ambassador/urls.py` — URL patterns
- **Create:** `backend/ambassador/migrations/` — Initial migration
- **Modify:** `backend/users/models.py` — Add AMBASSADOR to Role enum, add is_ambassador()
- **Modify:** `backend/core/permissions.py` — Add IsAmbassador, IsAmbassadorOrAdmin
- **Modify:** `backend/config/urls.py` — Add ambassador URL include
- **Modify:** `backend/config/settings.py` — Add 'ambassador' to INSTALLED_APPS
- **Modify:** `backend/users/serializers.py` — Add referral_code field to registration serializer
- **Modify:** `backend/users/views.py` — Handle referral_code in registration flow

### Mobile (files to create/modify)
- **Create:** `mobile/lib/features/ambassador/` — New feature directory
- **Create:** `mobile/lib/features/ambassador/data/models/ambassador_models.dart` — Data models
- **Create:** `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` — API calls
- **Create:** `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart` — State management
- **Create:** `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart`
- **Create:** `mobile/lib/features/ambassador/presentation/screens/ambassador_referrals_screen.dart`
- **Create:** `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart`
- **Create:** `mobile/lib/features/ambassador/presentation/screens/ambassador_navigation_shell.dart`
- **Modify:** `mobile/lib/core/router/app_router.dart` — Add ambassador routes + redirect
- **Modify:** `mobile/lib/core/constants/api_constants.dart` — Add ambassador endpoints
- **Modify:** `mobile/lib/features/auth/data/models/user_model.dart` — Add isAmbassador getter
- **Modify:** `mobile/lib/features/auth/presentation/screens/register_screen.dart` — Add referral code field
- **Modify:** `mobile/lib/features/admin/presentation/screens/admin_dashboard_screen.dart` — Add ambassador tile
- **Create:** `mobile/lib/features/admin/presentation/screens/admin_ambassadors_screen.dart`
- **Create:** `mobile/lib/features/admin/presentation/screens/admin_create_ambassador_screen.dart`
- **Create:** `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`

### Key Design Decisions
1. **New Django app (`ambassador/`)** — Clean separation, not cluttered in trainer/ or subscriptions/
2. **Referral code = 8-char alphanumeric** — Short, shareable, human-readable (e.g., "ABC12DEF")
3. **Commission rate per ambassador** — Admin can customize per ambassador, default 20%
4. **Commission snapshot** — Rate is frozen at time of charge, not retroactively changed
5. **Soft-delete for ambassadors** — `is_active=False` preserves history
6. **Silent referral code handling** — Invalid codes on registration never block the trainer
7. **Monthly commission granularity** — One commission record per referred trainer per month

## Out of Scope
- Automated Stripe payouts to ambassadors (future: Stripe Connect for ambassadors)
- Ambassador tier system (bronze/silver/gold with different rates)
- Ambassador marketing portal (landing pages, tracking links)
- Real-time referral notifications (WebSocket)
- Ambassador-to-ambassador referrals (multi-level)
- Commission approval workflow (auto-approved for MVP)

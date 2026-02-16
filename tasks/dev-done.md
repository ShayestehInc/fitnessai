# Dev Done: Ambassador Enhancements (Phase 5)

## Date: 2026-02-15

## Build & Lint Status
- `python manage.py makemigrations ambassador`: PASS (1 migration created)
- `flutter pub get`: PASS (fl_chart 0.69.2, share_plus 10.1.4 installed)
- `flutter analyze`: PASS (0 new errors/warnings -- 1 pre-existing info-level lint only)

## Files Created

### Backend
- `backend/ambassador/services/commission_service.py` -- CommissionService with approve_commission, pay_commission, bulk_approve, bulk_pay. Uses select_for_update() for concurrency safety. Returns frozen dataclass results (CommissionActionResult, BulkActionResult).
- `backend/ambassador/migrations/0003_alter_ambassadorprofile_referral_code_and_more.py` -- Migration to increase referral_code and referral_code_used max_length from 8 to 20.

### Mobile
- `mobile/lib/features/ambassador/presentation/widgets/monthly_earnings_chart.dart` -- MonthlyEarningsChart stateless widget using fl_chart BarChart. Empty state with muted icon. Theme-aware bar colors. Tooltip on touch. Accessibility labels per bar and for container. MonthlyEarningsChartSkeleton for loading state.

## Files Modified

### Backend
- `backend/ambassador/models.py` -- AmbassadorProfile.referral_code max_length 8->20 with updated help_text. AmbassadorReferral.referral_code_used max_length 8->20.
- `backend/ambassador/serializers.py` -- Added BulkCommissionActionSerializer (commission_ids ListField, min_length=1). Added CustomReferralCodeSerializer (regex validation, strip/uppercase, uniqueness check excluding current profile).
- `backend/ambassador/views.py` -- Added 4 new admin views: AdminCommissionApproveView, AdminCommissionPayView, AdminBulkApproveCommissionsView, AdminBulkPayCommissionsView. Updated AmbassadorReferralCodeView with PUT method for custom referral codes. Added import for CommissionService and new serializers.
- `backend/ambassador/urls.py` -- Added 4 URL patterns to admin_urlpatterns for commission approve/pay/bulk-approve/bulk-pay.

### Mobile
- `mobile/pubspec.yaml` -- Added fl_chart: ^0.69.0 and share_plus: ^10.0.0.
- `mobile/lib/core/constants/api_constants.dart` -- Added 4 static methods: adminAmbassadorCommissionApprove, adminAmbassadorCommissionPay, adminAmbassadorBulkApprove, adminAmbassadorBulkPay.
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` -- Added 5 methods: updateReferralCode (PUT), approveCommission, payCommission, bulkApproveCommissions, bulkPayCommissions.
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart` -- Added updateReferralCode method to AmbassadorDashboardNotifier.
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` -- Inserted MonthlyEarningsChart between referral code card and stats row. Replaced clipboard-only _shareCode with Share.share() native share sheet + clipboard fallback on exception. Added share_plus import.
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart` -- Replaced static referral code _buildInfoRow with _buildReferralCodeRow (shows edit icon). Added _showEditReferralCodeDialog with TextFormField (auto-uppercase formatter, alphanumeric filter, max 20 chars), client-side 4-char min validation, loading state on Save, inline server error display. Added _UpperCaseTextInputFormatter class.
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart` -- Added per-commission action buttons (Approve for PENDING, Mark Paid for APPROVED). Per-commission loading via Set<int> _processingCommissionIds. Bulk "Approve All Pending" TextButton.icon in commission header. Confirmation dialogs for all actions. Error message parsing for known server errors. _isBulkProcessing state.

## Key Decisions

1. **Separate commission_service.py**: Kept alongside referral_service.py for single-responsibility. Each service file stays under 200 lines.
2. **Bulk operations skip non-qualifying**: Bulk approve skips non-PENDING; bulk pay skips non-APPROVED. Returns processed_count + skipped_count rather than erroring.
3. **share_plus v10 API**: Uses `Share.share(text)` static method (not SharePlus.instance).
4. **No password reset code changes**: Djoser reset_password is role-agnostic. Login screen already has "Forgot your password?" link. Works for AMBASSADOR users with zero code changes (Feature 4 -- verified).
5. **referral_code_used also widened to 20**: Since custom codes can be up to 20 chars, the referral_code_used field on AmbassadorReferral must also support the wider length.

## Deviations from Ticket

- AC-5: Used fl_chart ^0.69.0 instead of ~0.68.0 (latest stable on pub.dev).
- AC-10: Used share_plus ^10.0.0 instead of ~9.0.0 (latest stable on pub.dev, v9 no longer maintained).
- Both are compatible API-wise with the ticket requirements.

## How to Manually Test

### 1. Monthly Earnings Chart
- Log in as ambassador, view dashboard
- Chart shows between referral code card and stats row
- Empty state shows "No earnings data yet" with bar chart icon
- Tap bars for tooltip with month name and dollar amount

### 2. Native Share Sheet
- On ambassador dashboard, tap "Share Referral Code"
- Native OS share sheet opens with referral message
- Copy button next to code still copies just the code (unchanged)

### 3. Commission Approval/Payment
- Log in as admin, navigate to ambassador detail
- PENDING commissions show blue "Approve" button
- APPROVED commissions show green "Mark Paid" button
- "Approve All Pending" button in commission section header when PENDING exists
- Confirmation dialog before each action
- Loading spinner per-commission during API call
- Success/error snackbar after action

### 4. Ambassador Password Reset
- On login screen, tap "Forgot your password?"
- Enter ambassador email, submit
- 204 response (Djoser default, role-agnostic)
- After resetting password, ambassador can log in and routes to /ambassador

### 5. Custom Referral Codes
- Log in as ambassador, go to Settings
- Edit icon next to referral code in Ambassador Details
- Tap edit: dialog with pre-filled current code
- Auto-uppercases input, filters non-alphanumeric
- "4-20 alphanumeric characters" helper text
- Min 4 char client-side validation
- Server validates uniqueness, returns inline error if taken
- Success closes dialog, snackbar shows new code, dashboard refreshes

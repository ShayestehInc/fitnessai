# Feature: Ambassador Enhancements (Phase 5)

## Priority
High

## User Stories

### US-1: Monthly Earnings Chart
As an ambassador, I want to see a bar chart of my monthly earnings on the dashboard so that I can visualize my income trend over the past 6 months and understand whether my referral efforts are growing.

### US-2: Native Share Sheet
As an ambassador, I want to share my referral code and message via the native iOS/Android share sheet so that I can send it through WhatsApp, iMessage, email, or any other app without manually copying and pasting.

### US-3: Commission Approval and Payment Workflow
As an admin, I want to approve and mark commissions as paid from the ambassador detail screen (mobile) so that I can manage the full commission lifecycle without needing to access the Django admin.

### US-4: Ambassador Password Reset
As an ambassador, I want to reset my password via the existing "Forgot Password?" flow so that I am not locked out of my account when I forget my admin-assigned temporary password.

### US-5: Custom Referral Codes
As an ambassador, I want to choose a custom, memorable referral code (e.g., "JOHN20") so that I can create a branded code that is easier for trainers to remember when they sign up.

---

## Acceptance Criteria

### Monthly Earnings Chart (US-1)
- [ ] AC-1: Ambassador dashboard screen displays a bar chart below the earnings card, showing monthly earnings for the last 6 months.
- [ ] AC-2: Each bar is labeled with the month abbreviation (e.g., "Sep", "Oct") and the dollar amount is shown on tap/hover.
- [ ] AC-3: The chart uses the app's primary color (theme-aware) for bars and adapts to light/dark mode.
- [ ] AC-4: When `monthlyEarnings` is an empty array, the chart area displays an empty state: "No earnings data yet" with a muted chart icon.
- [ ] AC-5: The `fl_chart` package (version ~0.68.0) is added to `pubspec.yaml` and no other chart package is introduced.

### Native Share Sheet (US-2)
- [ ] AC-6: Tapping "Share Referral Code" on the dashboard opens the native OS share sheet with the referral message.
- [ ] AC-7: The share message format is: "Join FitnessAI and grow your training business! Use my referral code {CODE} when you sign up."
- [ ] AC-8: If the share action is cancelled by the user, no snackbar or error is shown (silent dismiss).
- [ ] AC-9: The copy-to-clipboard button remains as a separate action (icon button next to the code).
- [ ] AC-10: The `share_plus` package (version ~9.0.0) is added to `pubspec.yaml`.

### Commission Approval/Payment Workflow (US-3)
- [ ] AC-11: Backend exposes `POST /api/admin/ambassadors/<id>/commissions/<commission_id>/approve/` that transitions a PENDING commission to APPROVED.
- [ ] AC-12: Backend exposes `POST /api/admin/ambassadors/<id>/commissions/<commission_id>/pay/` that transitions an APPROVED commission to PAID.
- [ ] AC-13: Backend exposes `POST /api/admin/ambassadors/<id>/commissions/bulk-approve/` that accepts `{"commission_ids": [1,2,3]}` and approves all PENDING commissions in the list atomically.
- [ ] AC-14: Backend exposes `POST /api/admin/ambassadors/<id>/commissions/bulk-pay/` that accepts `{"commission_ids": [1,2,3]}` and pays all APPROVED commissions in the list atomically.
- [ ] AC-15: Attempting to approve an already-APPROVED or PAID commission returns 400 with a descriptive error.
- [ ] AC-16: Attempting to pay a PENDING commission (not yet approved) returns 400 with a descriptive error.
- [ ] AC-17: On the admin ambassador detail screen (mobile), each commission tile with status PENDING shows an "Approve" action button.
- [ ] AC-18: On the admin ambassador detail screen (mobile), each commission tile with status APPROVED shows a "Mark Paid" action button.
- [ ] AC-19: A "Bulk Approve All Pending" button appears in the commission section header when there are PENDING commissions.
- [ ] AC-20: Commission status updates reflect immediately in the UI after a successful API call (optimistic update with rollback on failure).
- [ ] AC-21: After approving or paying, the ambassador's `total_earnings` cached field is recalculated by calling `refresh_cached_stats()`.

### Ambassador Password Reset (US-4)
- [ ] AC-22: The ambassador login flow uses the same login screen as all other roles (this already works since login is role-agnostic JWT).
- [ ] AC-23: The "Forgot your password?" link on the login screen navigates to `/forgot-password`, which calls Djoser's `POST /api/auth/users/reset_password/`.
- [ ] AC-24: Djoser's password reset endpoint works for AMBASSADOR-role users without any role restriction (verify it does not filter by role).
- [ ] AC-25: After reset, the ambassador can log in with their new password and is routed to `/ambassador` dashboard.

### Custom Referral Codes (US-5)
- [ ] AC-26: Backend exposes `PUT /api/ambassador/referral-code/` that allows the authenticated ambassador to set a custom referral code.
- [ ] AC-27: Custom codes must be 4-20 characters, alphanumeric only (A-Z, 0-9), stored uppercase.
- [ ] AC-28: Custom codes are validated for uniqueness across all ambassador profiles.
- [ ] AC-29: If the requested code is already taken, the API returns 400 with `{"referral_code": ["This referral code is already in use."]}`.
- [ ] AC-30: The ambassador settings screen shows the current referral code with an "Edit" icon button next to it.
- [ ] AC-31: Tapping "Edit" opens a dialog with a text field pre-filled with the current code, a "Save" button, and a "Cancel" button.
- [ ] AC-32: The dialog validates the code client-side (4-20 chars, alphanumeric only) before submitting.
- [ ] AC-33: After a successful code change, the dashboard and settings screens update to show the new code.
- [ ] AC-34: The `AmbassadorProfile.referral_code` model field `max_length` is increased from 8 to 20 (migration required).

---

## Edge Cases

1. **Monthly chart with only 1 month of data:** The chart should still render with a single bar (not crash or look broken). The X-axis should show that single month label.

2. **Monthly chart with months having $0 earnings:** Months with no commissions should not appear as bars (they are excluded from the API response). The chart should only show months that have data. If all 6 months are $0 (empty array), show the empty state.

3. **Share sheet not available on emulator/simulator:** `share_plus` can throw a `PlatformException` on some emulators. Wrap the share call in a try-catch and fall back to clipboard copy with a snackbar if sharing fails.

4. **Bulk approve with mixed statuses:** If the admin sends `commission_ids` that include both PENDING and non-PENDING commissions, the backend should only approve the PENDING ones and return a result indicating how many were approved vs. skipped.

5. **Concurrent commission approval:** Two admins approve the same commission simultaneously. The backend uses `select_for_update()` to prevent double-processing. The second request should return 400 ("Commission is already APPROVED").

6. **Custom code conflicts with auto-generated codes:** An ambassador sets custom code "ABC12345" and later a new ambassador's auto-generated code tries to use the same 8-char substring. Since auto-generated codes are exactly 8 characters from the same alphabet, ensure the uniqueness constraint covers both custom and auto-generated codes in the same `referral_code` column (already the case).

7. **Custom code with leading/trailing whitespace or lowercase:** The backend should strip whitespace and uppercase the input before validation and storage. "  john20  " becomes "JOHN20".

8. **Custom code that is profane or reserved:** While we do not implement a profanity filter in this phase, the code must be at least 4 characters (preventing trivially short codes like "A") and alphanumeric only (preventing special characters). Reserved words like "ADMIN" or "TEST" are not blocked in this phase.

9. **Password reset email for non-existent ambassador email:** Djoser's default behavior returns 204 regardless of whether the email exists (to prevent email enumeration). Verify this behavior is preserved for ambassadors.

10. **Ambassador sets custom code, then admin creates a new ambassador whose auto-generated code collides:** The `AmbassadorProfile.save()` retry logic (3 retries on IntegrityError) already handles this. The new ambassador gets a different auto-generated code.

11. **Commission approval when ambassador is deactivated:** Approving a commission for a deactivated ambassador should still work (the commission was earned when they were active). The `is_active` flag only prevents new commission creation.

12. **Empty commission_ids array in bulk endpoints:** Return 400 with `{"commission_ids": ["This field is required and must contain at least one ID."]}`.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Chart data fails to load (API error) | Dashboard shows error state with retry button (existing behavior). Chart section is simply absent. | Error caught in provider, stored in state.error |
| Share sheet throws PlatformException | "Share message copied to clipboard!" snackbar (fallback) | Catch PlatformException, copy to clipboard, show snackbar |
| Approve commission fails (network error) | "Failed to approve commission. Please try again." error snackbar | Revert optimistic UI update, show error |
| Approve commission fails (already approved) | "Commission is already approved." warning snackbar | 400 response parsed, specific message shown |
| Pay commission fails (not yet approved) | "Commission must be approved before it can be marked as paid." warning snackbar | 400 response parsed, specific message shown |
| Bulk approve with 0 qualifying commissions | "No pending commissions to approve." info snackbar | 200 response with `approved_count: 0` |
| Custom code fails uniqueness check | Dialog shows inline error: "This referral code is already in use." | 400 response, field-level error parsed and shown under text field |
| Custom code fails format validation (client) | Dialog shows inline error: "Code must be 4-20 alphanumeric characters." | Validation runs before API call |
| Password reset email not received | Success screen shows "Check your spam folder" hint and "Didn't receive it? Try again" link | Existing forgot_password_screen.dart behavior (already implemented) |
| Password reset for deactivated ambassador | Djoser sends reset email regardless of is_active on User model (Django is_active controls login, not email). If User.is_active=False, they cannot log in even after reset. | Djoser default behavior |

---

## UX Requirements

### Monthly Earnings Chart
- **Loading state:** Chart area shows a shimmer/skeleton placeholder (same height as the rendered chart, ~180px) while dashboard data loads.
- **Empty state:** Centered muted bar chart icon (Icons.bar_chart) with "No earnings data yet" text in bodySmall style. Same height as chart would be (~180px).
- **Populated state:** Vertical bar chart with rounded-top bars. X-axis = month abbreviation (e.g., "Sep"). Y-axis = dollar amounts with "$" prefix. Touch a bar to see tooltip with exact amount. Bars use `theme.colorScheme.primary` with 0.8 opacity. Grid lines are subtle (dividerColor).
- **Chart height:** Fixed 180px. No horizontal scroll needed (max 6 bars always fit).
- **Section header:** "Monthly Earnings" with bodyLarge style, placed between the referral code card and the stats row.
- **Accessibility:** Semantics label on the chart container: "Monthly earnings chart showing earnings for the last 6 months". Each bar should have a semantics label like "September: $150.00".

### Native Share Sheet
- **Trigger:** The existing "Share Referral Code" ElevatedButton on the dashboard.
- **Behavior:** Opens native share sheet. No loading indicator needed (OS handles it).
- **Fallback:** If share fails, copy to clipboard and show green snackbar "Share message copied to clipboard!".
- **Copy button:** Remains unchanged (copies just the code, not the full message).

### Commission Approval/Payment Workflow
- **Action buttons:** Small outlined buttons inside each commission tile. "Approve" in blue for PENDING, "Mark Paid" in green for APPROVED. PAID commissions show no button (status badge only).
- **Button loading state:** While the API call is in flight, the button shows a 16px CircularProgressIndicator and is disabled.
- **Bulk button:** Appears as a TextButton with icon (Icons.check_circle_outline) in the commission section header row, right-aligned. Label: "Approve All Pending" in primary color. Shows loading spinner while in flight.
- **Confirmation dialog:** Both individual and bulk actions show a confirmation dialog. Individual: "Approve $X.XX commission for trainer@email.com?". Bulk: "Approve X pending commissions totaling $Y.YY?".
- **Success feedback:** Green snackbar: "Commission approved" / "Commission marked as paid" / "X commissions approved".
- **Refresh:** After any commission action, refresh the full ambassador detail to get updated stats.

### Ambassador Password Reset
- **No new UI needed.** The existing login screen already has "Forgot your password?" which navigates to ForgotPasswordScreen. This works for all roles since Djoser's reset_password endpoint is role-agnostic. Verify and document that it works for ambassadors.

### Custom Referral Codes
- **Settings screen:** Below the "Referral Code" row in the Ambassador Details card, show the current code with an IconButton (Icons.edit, size 18) to the right of the code value.
- **Edit dialog:** AlertDialog with title "Change Referral Code", a TextFormField pre-filled with the current code (all caps, max 20 chars), helper text "4-20 alphanumeric characters", inline validation error below the field, "Cancel" and "Save" buttons.
- **Input formatting:** Auto-uppercase as the user types (TextInputFormatter). Strip non-alphanumeric characters.
- **Loading state:** Save button shows CircularProgressIndicator while API call is in flight. Cancel button is disabled during save.
- **Success:** Dialog closes, snackbar "Referral code updated to {CODE}", dashboard refreshes to show new code.
- **Error:** Dialog stays open, inline error shown below the text field.

---

## Technical Approach

### 1. Monthly Earnings Chart

**Package addition:**
- File: `mobile/pubspec.yaml` — Add `fl_chart: ~0.68.0` to dependencies.

**New widget file:**
- File: `mobile/lib/features/ambassador/presentation/widgets/monthly_earnings_chart.dart` — New file. Stateless widget `MonthlyEarningsChart` that takes `List<MonthlyEarnings>` and renders a `BarChart` from `fl_chart`. Handles empty list with empty state widget. Fixed 180px height. Theme-aware colors. Tooltip on bar touch. Semantics labels.

**Modified files:**
- File: `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` — In `_buildContent()`, insert the chart widget between `_buildReferralCodeCard` and `_buildStatsRow`. Import the new widget.

### 2. Native Share Sheet

**Package addition:**
- File: `mobile/pubspec.yaml` — Add `share_plus: ~9.0.0` to dependencies.

**Modified files:**
- File: `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` — In `_shareCode()`, replace `Clipboard.setData` with `Share.share(message)` from `share_plus`. Wrap in try-catch, fall back to clipboard on `PlatformException`.

### 3. Commission Approval/Payment Workflow

**Backend — New service file:**
- File: `backend/ambassador/services/commission_service.py` — New file. `CommissionService` class with:
  - `approve_commission(commission_id: int, ambassador_profile_id: int) -> CommissionActionResult` — Uses `select_for_update()` to lock the commission row. Validates the commission belongs to the ambassador. Validates status is PENDING. Transitions to APPROVED. Calls `profile.refresh_cached_stats()`.
  - `pay_commission(commission_id: int, ambassador_profile_id: int) -> CommissionActionResult` — Same lock pattern. Validates status is APPROVED. Transitions to PAID. Calls `profile.refresh_cached_stats()`.
  - `bulk_approve(commission_ids: list[int], ambassador_profile_id: int) -> BulkActionResult` — Locks all matching PENDING commissions. Bulk updates to APPROVED. Returns approved_count and skipped_count.
  - `bulk_pay(commission_ids: list[int], ambassador_profile_id: int) -> BulkActionResult` — Locks all matching APPROVED commissions. Bulk updates to PAID. Returns paid_count and skipped_count.
  - Result dataclasses: `CommissionActionResult(success: bool, message: str)` and `BulkActionResult(success: bool, processed_count: int, skipped_count: int, message: str)`.

**Backend — New views:**
- File: `backend/ambassador/views.py` — Add 4 new view classes:
  - `AdminCommissionApproveView(APIView)` — POST handler calling `CommissionService.approve_commission()`.
  - `AdminCommissionPayView(APIView)` — POST handler calling `CommissionService.pay_commission()`.
  - `AdminBulkApproveCommissionsView(APIView)` — POST handler with `BulkCommissionActionSerializer` validation.
  - `AdminBulkPayCommissionsView(APIView)` — POST handler with `BulkCommissionActionSerializer` validation.
  All views have `[IsAuthenticated, IsAdmin]` permissions.

**Backend — New serializer:**
- File: `backend/ambassador/serializers.py` — Add `BulkCommissionActionSerializer` with `commission_ids = serializers.ListField(child=serializers.IntegerField(), min_length=1)`.

**Backend — URL additions:**
- File: `backend/ambassador/urls.py` — Add to `admin_urlpatterns`:
  - `path('<int:ambassador_id>/commissions/<int:commission_id>/approve/', ...)`
  - `path('<int:ambassador_id>/commissions/<int:commission_id>/pay/', ...)`
  - `path('<int:ambassador_id>/commissions/bulk-approve/', ...)`
  - `path('<int:ambassador_id>/commissions/bulk-pay/', ...)`

**Mobile — Repository additions:**
- File: `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` — Add 4 new methods:
  - `Future<void> approveCommission(int ambassadorId, int commissionId)`
  - `Future<void> payCommission(int ambassadorId, int commissionId)`
  - `Future<Map<String, dynamic>> bulkApproveCommissions(int ambassadorId, List<int> commissionIds)`
  - `Future<Map<String, dynamic>> bulkPayCommissions(int ambassadorId, List<int> commissionIds)`

**Mobile — API constants:**
- File: `mobile/lib/core/constants/api_constants.dart` — Add 4 new endpoint getters:
  - `static String adminAmbassadorCommissionApprove(int ambassadorId, int commissionId) => '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/$commissionId/approve/';`
  - `static String adminAmbassadorCommissionPay(int ambassadorId, int commissionId) => '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/$commissionId/pay/';`
  - `static String adminAmbassadorBulkApprove(int ambassadorId) => '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/bulk-approve/';`
  - `static String adminAmbassadorBulkPay(int ambassadorId) => '$apiBaseUrl/admin/ambassadors/$ambassadorId/commissions/bulk-pay/';`

**Mobile — Admin detail screen changes:**
- File: `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart` — Modify `_buildCommissionTile()` to add:
  - "Approve" OutlinedButton (blue) when `commission.status == 'PENDING'`.
  - "Mark Paid" OutlinedButton (green) when `commission.status == 'APPROVED'`.
  - Loading state per-commission (track in a `Set<int> _processingCommissionIds`).
  - Confirmation dialogs before each action.
  - `_buildCommissionsList()` header gets a "Approve All Pending" TextButton (visible when any PENDING commissions exist).
  - After any action: call `_loadDetail()` to refresh.

### 4. Ambassador Password Reset

**Backend verification (test only, no code changes):**
- File: `backend/ambassador/tests/test_password_reset.py` — New test file. Test that `POST /api/auth/users/reset_password/` with an ambassador's email returns 204. Test that a non-existent email also returns 204 (Djoser's anti-enumeration behavior). This confirms the existing flow works for ambassadors.

**No mobile changes needed.** The existing login screen's "Forgot your password?" link, ForgotPasswordScreen, and ResetPasswordScreen all work for any role. The router already redirects ambassadors to `/ambassador` after login (line ~708 of app_router.dart).

### 5. Custom Referral Codes

**Backend — Model migration:**
- File: `backend/ambassador/models.py` — Change `AmbassadorProfile.referral_code` field:
  - `max_length=8` -> `max_length=20`
  - Update `help_text` to: "Unique 4-20 char alphanumeric referral code (auto-generated or custom)"
- Run `python manage.py makemigrations ambassador` to generate migration.

**Backend — Serializer:**
- File: `backend/ambassador/serializers.py` — Add `CustomReferralCodeSerializer`:
  - `referral_code = serializers.RegexField(regex=r'^[A-Z0-9]{4,20}$', error_messages={'invalid': 'Code must be 4-20 alphanumeric characters (A-Z, 0-9).'})`
  - `validate_referral_code(self, value)` — strip, uppercase, check uniqueness excluding current user's profile.

**Backend — View update:**
- File: `backend/ambassador/views.py` — Update `AmbassadorReferralCodeView` to handle PUT:
  - Validate with `CustomReferralCodeSerializer`.
  - Update `profile.referral_code`.
  - Return updated code and share message.

**Mobile — Repository:**
- File: `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` — Add `Future<ReferralCodeData> updateReferralCode(String code)` method calling `PUT /api/ambassador/referral-code/`.

**Mobile — Provider:**
- File: `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart` — Add `Future<bool> updateReferralCode(String code)` to `AmbassadorDashboardNotifier` that calls repository, reloads dashboard on success, returns success/failure.

**Mobile — Settings screen:**
- File: `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart` — Modify the "Referral Code" `_buildInfoRow` to add an edit icon button. Add `_showEditReferralCodeDialog()` method with:
  - AlertDialog with TextFormField (pre-filled, `FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))`, `UpperCaseTextInputFormatter`, maxLength 20).
  - Client-side validation (min 4 chars).
  - Loading state on Save button.
  - Inline error display from server response.
  - On success: close dialog, show snackbar, refresh dashboard.

---

## Out of Scope
- Stripe Connect payout to ambassadors (deferred to Phase 6 — requires Stripe dashboard configuration)
- Push notifications for commission status changes
- Ambassador earnings export (CSV/PDF)
- Ambassador-to-ambassador referral chains (multi-level marketing)
- Web dashboard ambassador views (admin can manage via mobile or Django admin)
- Profanity filter for custom referral codes
- Rate limiting on custom code change frequency (can be added later if abused)

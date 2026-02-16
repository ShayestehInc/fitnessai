# Hacker Report: Ambassador Enhancements (Pipeline 14)

## Date: 2026-02-15

## Focus Areas
Ambassador Enhancements Phase 5: monthly earnings chart, native share sheet, commission approval/payment workflow, custom referral codes. Backend (commission_service.py, views.py, serializers.py, urls.py, models.py) and Mobile (dashboard screen, settings screen, admin detail screen, chart widget, repository, provider, models, API constants).

---

## Dead Buttons & Non-Functional UI

| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | admin_ambassador_detail_screen.dart | "Bulk Pay All Approved" button | Should exist alongside "Approve All Pending" for symmetry -- backend supports bulk-pay endpoint | Missing entirely. Backend has `bulk-pay/` endpoint, mobile has `bulkPayCommissions` repository method, but no UI to trigger it. **FIXED**: Added "Pay All" TextButton.icon (green) next to "Approve All" in commission header. Includes confirmation dialog with total amount and success/error snackbar. |
| 2 | Low | admin_ambassador_detail_screen.dart | Individual commission action buttons during bulk processing | Should be disabled when bulk approve/pay is in flight to prevent conflicting concurrent mutations | Buttons remained fully tappable during `_isBulkProcessing`. **FIXED**: Pass `isProcessing || _isBulkProcessing` to `_buildCommissionActionButton`, disabling individual actions while bulk operation runs. |

---

## Visual Misalignments & Layout Bugs

| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | High | ambassador_dashboard_screen.dart | Referral code card: `fontSize: 24` + `letterSpacing: 4` on code text means a 20-char custom code like "SUPERSUMMERDEAL2026" is ~600px wide, overflowing the card on all phone screens. Previously codes were always 8 chars so it fit, but the max_length increase to 20 broke this. | **FIXED**: Wrapped code Text in `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` so long codes scale down to fit the available width while short codes remain full size. |
| 2 | Medium | admin_ambassador_detail_screen.dart | Profile card: `Code: ${profile.referralCode}` text in the Row alongside the status badge has no overflow protection. With a 20-char code, it pushes the status badge off-screen or causes Row overflow. | **FIXED**: Wrapped in `Flexible` with `overflow: TextOverflow.ellipsis`. |
| 3 | Medium | admin_ambassador_detail_screen.dart | Commission tile: Single Row with trainer email + amount column + status badge + action button. With long emails (e.g., "verylongtraineremail@verylongdomain.com") + "$1,250.00" + "APPROVED" badge + "Mark Paid" button, the Row overflows on typical 375px phone widths. | **FIXED**: Restructured tile to two-row Column layout. Top row: email (Expanded + ellipsis) + commission amount. Bottom row: period + base amount (Expanded + ellipsis) + status badge + action button. Prevents overflow at any screen width. |
| 4 | Medium | ambassador_dashboard_screen.dart | Earnings card: `\$${data.totalEarnings}` displays raw decimal strings like "10500.00" with no comma grouping. For an ambassador with $10,500 in earnings, the display reads "$10500.00" -- hard to parse quickly and feels unprofessional. Same for pending earnings. | **FIXED**: Added `_formatCurrency()` helper that formats with comma grouping (e.g., "$10,500.00"). Applied to both `totalEarnings` and `pendingEarnings` displays. |

---

## Broken Flows & Logic Bugs

| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | High | ambassador_dashboard_screen.dart | Share referral code on emulator/platform without share_plus plugin registered | Should fall back to clipboard copy with snackbar | Only caught `PlatformException`. share_plus v10 can throw `MissingPluginException` (which is NOT a subclass of PlatformException) on emulators or web. The catch block would miss it, causing an unhandled exception crash. **FIXED**: Changed `on PlatformException` to `catch (_)` to handle all exception types with clipboard fallback. |
| 2 | Medium | monthly_earnings_chart.dart | Ambassador has monthly earnings entries but all amounts are "0.00" (e.g., all commissions still PENDING, not APPROVED/PAID) | Should show "No earnings data yet" empty state | Renders invisible zero-height bars with a 100-unit Y-axis, gridlines, and axis labels -- a confusing empty-looking chart. **FIXED**: Added `_maxEarning > 0` check alongside `isEmpty` to route all-zero data to the empty state. |

---

## Edge Case Analysis (Verified Clean)

| # | Scenario | Current Behavior | Risk |
|---|----------|-----------------|------|
| 1 | Custom code of exactly 4 chars ("ABCD") | Backend regex `^[A-Z0-9]{4,20}$` passes. Client-side `code.length < 4` check passes. Dialog helper text says "4-20 alphanumeric characters." | Low -- Clean |
| 2 | Custom code of exactly 20 chars | Backend regex passes. Client-side `maxLength: 20` enforces hard limit. Character counter shows "20/20". | Low -- Clean |
| 3 | Approve already-approved commission | Backend `CommissionService.approve_commission` checks `commission.status == APPROVED` and returns `CommissionActionResult(success=False, message="Commission is already approved.")`. View returns 400. Mobile `_parseErrorMessage` extracts server message from DioException response data. | Low -- Clean |
| 4 | Pay a PENDING commission (not yet approved) | Backend returns 400 with "Commission must be approved before it can be marked as paid." Mobile displays server error in snackbar. | Low -- Clean |
| 5 | Bulk approve with empty list | `BulkCommissionActionSerializer` has `min_length=1` on `commission_ids`. Returns 400 with "This field is required and must contain at least one ID." | Low -- Clean |
| 6 | Bulk approve with mixed statuses | Backend filters `status=PENDING` from the locked set. Non-pending IDs are skipped. Returns `processed_count` + `skipped_count`. | Low -- Clean |
| 7 | Concurrent code changes (two ambassadors claim same code) | Serializer checks uniqueness first (fast path). `profile.save()` has DB unique constraint as real guard. `IntegrityError` caught and returns 400. | Low -- Clean |
| 8 | 0 months of earnings data | `monthlyEarnings.isEmpty` triggers empty state with muted bar chart icon and "No earnings data yet" text. | Low -- Clean |
| 9 | 1 month of earnings data | Chart renders single bar. `monthlyEarnings.length <= 3` triggers wider bar width (32px instead of 20px) so it doesn't look tiny. | Low -- Clean |
| 10 | Chart data with 6 months of data | Max 6 bars always fit in 180px height container. Bar width is 20px with spacing. No horizontal scroll needed. | Low -- Clean |
| 11 | Commission for deactivated ambassador | Backend allows approve/pay regardless of `profile.is_active` (correct -- commission was earned when active). | Low -- Clean |
| 12 | Password reset for ambassador | Djoser's `POST /api/auth/users/reset_password/` is role-agnostic. Returns 204 regardless of whether email exists (anti-enumeration). Ambassador can reset and log in, routing to `/ambassador` dashboard. | Low -- Clean |
| 13 | Share cancelled by user | `Share.share()` returns normally on cancel. No snackbar shown (AC-8 silent dismiss). | Low -- Clean |
| 14 | `select_for_update()` concurrency on commission approve | Two admins approve same commission: first gets lock, transitions to APPROVED, releases. Second gets lock, finds status is APPROVED, returns 400 "already approved." No double-processing. | Low -- Clean |

---

## Product Improvement Suggestions

| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Dashboard earnings card | Add period-over-period trend indicator (e.g., "+12% vs last month" with up arrow) next to total earnings | Currently it is a static number. Ambassadors are motivated by growth trends. Every good earnings dashboard (Stripe, Shopify Partners) shows deltas. |
| 2 | High | Commission list (admin) | Add "Mark All Approved as Paid" button | **FIXED** -- Added "Pay All" bulk button. Was missing despite backend support. |
| 3 | Medium | Dashboard chart | Add tap-to-drill-down from chart bar to that month's commission list | Currently the chart shows aggregate earnings. Tapping a bar should navigate to a filtered commission list for that month. |
| 4 | Medium | Settings screen | Add referral code preview of how the share message will look with the new code, shown live in the edit dialog | Ambassadors want to see the full share message before committing to a code change. A small preview below the text field would reduce back-and-forth. |
| 5 | Medium | Admin ambassador detail | Show pending vs approved vs paid commission totals in the stats card | Currently only shows total earnings. Breaking down by status helps admins see how much they owe (approved but unpaid). |
| 6 | Medium | Dashboard | Add a "copy share message" button alongside the share button | Some users prefer to manually paste into specific chats rather than use the share sheet. The current copy button copies only the code, not the full message. |
| 7 | Low | Commission tile (admin) | Add date formatting (e.g., "Jan 15 - Feb 14") instead of raw ISO date strings ("2026-01-15 - 2026-02-14") | Raw ISO dates are harder to scan quickly. |
| 8 | Low | Chart | Show month + year in tooltip when tapping a bar (e.g., "Sep 2025: $150.00") instead of just month abbreviation | If the chart spans a year boundary (e.g., Oct 2025 - Mar 2026), showing only month abbreviation in the tooltip is ambiguous. |
| 9 | Low | Dashboard | Add pull-to-refresh haptic feedback | The RefreshIndicator works but has no haptic feedback on iOS, which feels less polished than native apps. |
| 10 | Low | Admin ambassador list | Add commission status breakdown (pending/approved/paid counts) as small badges on each ambassador card | Helps admins quickly identify which ambassadors need commission review without drilling into detail screens. |

---

## Backend Issues Found

| # | Severity | File | Issue | Status |
|---|----------|------|-------|--------|
| 1 | Low | commission_service.py | `_refresh_ambassador_stats` runs inside the `transaction.atomic()` block. The `refresh_cached_stats()` method does a `.save(update_fields=['total_referrals', 'total_earnings'])` which commits within the same transaction. If the stats aggregation query is slow (many commissions), the `select_for_update()` lock is held longer than necessary. For high-volume ambassadors, this could increase lock contention. | Not fixed -- acceptable for current scale. Worth extracting stats refresh outside the transaction block if commission volume grows past ~1000 per ambassador. |
| 2 | Low | views.py | `AmbassadorDashboardView.get()` runs 4 separate queries (status_counts, pending_earnings, monthly_data, recent_referrals). Could be reduced to 2-3 with a single annotated query. | Not fixed -- N is bounded (always exactly 4 queries regardless of data volume), so not a performance concern at current scale. |

---

## Summary

- Dead UI elements found: 2
- Visual bugs found: 4
- Logic bugs found: 2
- Edge cases verified clean: 14
- Improvements suggested: 10
- Items fixed by hacker: 8

## Chaos Score: 7/10

### Rationale
The Ambassador Enhancements implementation is solid overall. The backend commission service uses `select_for_update()` for concurrency safety, status transitions have proper guard clauses, bulk operations correctly skip non-qualifying commissions, and the custom referral code flow has both serializer-level validation and DB-level unique constraint as a race condition guard.

The main gaps were:
- **Missing "Pay All Approved" bulk button** -- The backend endpoint existed, the repository method existed, but the UI never wired it up. This left admins having to click "Mark Paid" on each commission individually, which at 20+ commissions per ambassador is a significant UX burden.
- **Share sheet exception handling too narrow** -- Only catching `PlatformException` when `share_plus` v10 can throw `MissingPluginException` on emulators/web. Would cause unhandled exception crashes in development and on web.
- **Long custom referral codes overflowing UI** -- The `max_length` increase from 8 to 20 on the model was properly handled in backend validation and the settings edit dialog, but the dashboard display card and admin profile card were still sized for 8-char codes. 20-char codes with large font + letter spacing would overflow.
- **All-zero chart confusing instead of empty** -- If an ambassador has only PENDING commissions (not yet APPROVED/PAID), the monthly earnings chart shows zero-height bars with gridlines and axis labels, which looks broken rather than informative.
- **Missing currency formatting** -- Raw decimal strings displayed as-is. "$10500.00" instead of "$10,500.00".

**Good:**
- `select_for_update()` on all commission mutations prevents double-processing
- `IntegrityError` catch on custom code save prevents race condition between validation and save
- Chart widget handles all edge cases (1 bar, 6 bars, dynamic bar width, tooltip, accessibility labels)
- Commission action buttons have per-item loading spinners + confirmation dialogs
- Error parsing extracts server messages from DioException for user-friendly error display
- `_UpperCaseTextInputFormatter` + `FilteringTextInputFormatter` ensure only valid characters in code input
- Backend `CustomReferralCodeSerializer` strips whitespace and uppercases before validation
- `BulkCommissionActionSerializer` enforces `min_length=1` for empty array protection

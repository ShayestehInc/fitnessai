# Code Review: Ambassador Enhancements (Phase 5)

## Review Date: 2026-02-15

## Files Reviewed
### Backend (6 files)
- `backend/ambassador/services/commission_service.py` (NEW, 270 lines)
- `backend/ambassador/views.py` (MODIFIED, 520 lines)
- `backend/ambassador/serializers.py` (MODIFIED, 196 lines)
- `backend/ambassador/urls.py` (MODIFIED, 42 lines)
- `backend/ambassador/models.py` (MODIFIED, 279 lines)
- `backend/ambassador/migrations/0003_alter_ambassadorprofile_referral_code_and_more.py` (NEW, 24 lines)

### Mobile (8 files)
- `mobile/lib/features/ambassador/presentation/widgets/monthly_earnings_chart.dart` (NEW, 300 lines)
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` (MODIFIED, 512 lines)
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart` (MODIFIED, 416 lines)
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart` (MODIFIED, 133 lines)
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart` (MODIFIED, 200 lines)
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart` (MODIFIED, 899 lines)
- `mobile/lib/core/constants/api_constants.dart` (MODIFIED, 199 lines)
- `mobile/pubspec.yaml` (MODIFIED, 74 lines)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C-1 | `backend/ambassador/services/commission_service.py:88-90, 150-152, 191-193, 247-249` | **`refresh_cached_stats()` called OUTSIDE the transaction block.** The `with transaction.atomic()` block commits the status change, then `refresh_cached_stats()` runs outside it. If `refresh_cached_stats()` fails (e.g., DB timeout), the commission status is updated but the cached stats are stale with no way to detect this. Worse, `refresh_cached_stats()` itself calls `self.save(update_fields=...)` which is NOT wrapped in a transaction with the status change -- so the aggregate query could read partially committed data from other concurrent operations. The stats refresh should be inside the transaction to ensure atomicity, OR at least be wrapped in its own try-catch so failures are logged rather than causing 500 errors. | Move `profile = AmbassadorProfile.objects.get(...)` and `profile.refresh_cached_stats()` inside the `with transaction.atomic():` block. This ensures the lock held by `select_for_update` is still active and the aggregation reads a consistent snapshot. Alternatively, wrap in a separate try-except that logs warnings but does not crash the request. |
| C-2 | `backend/ambassador/views.py:218-249` | **Custom referral code PUT endpoint has no race condition protection (TOCTOU).** The `CustomReferralCodeSerializer.validate_referral_code()` checks uniqueness with `.filter().exists()`, then the view saves the code in a separate operation. Between the check and the save, another request could claim the same code. The DB `unique=True` constraint will raise `IntegrityError` which is not caught anywhere, resulting in an unhandled 500 error to the client. | Wrap the validate+save in `transaction.atomic()`, AND catch `IntegrityError` on the `profile.save()` call, returning a 400 response with `{"referral_code": ["This referral code is already in use."]}`. The DB constraint is the real guard; the serializer check is just a user-friendly fast path. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M-1 | `admin_ambassador_detail_screen.dart` (899 lines) | **File is 899 lines -- massively exceeds the 150-line-per-widget-file convention.** The project CLAUDE.md mandates "Max 150 lines per widget file -- extract sub-widgets into separate files." This file was already over the limit before this PR, and the new commission action code (approval/pay buttons, bulk approve, confirmation dialogs, error parsing) added roughly 200 more lines. | Extract at minimum: (1) `_buildCommissionTile` + `_buildCommissionActionButton` into `widgets/admin_ambassador_commission_tile.dart`, (2) the commission list section with bulk button into `widgets/admin_ambassador_commissions_section.dart`, (3) the referral tile builder into `widgets/admin_ambassador_referral_tile.dart`. Each extraction should bring the main screen file significantly closer to the limit. |
| M-2 | `ambassador_dashboard_screen.dart` (512 lines) and `ambassador_settings_screen.dart` (416 lines) | **Both files exceed the 150-line convention by 3x+.** Same rule violation as M-1. The dashboard has the earnings card, referral code card, stats row, and recent referrals all inline. The settings screen has the full edit referral code dialog inline. | Extract sub-widgets: `widgets/earnings_card.dart`, `widgets/referral_code_card.dart`, `widgets/stats_row.dart`, `widgets/recent_referrals_list.dart`. For settings: extract `widgets/edit_referral_code_dialog.dart`. |
| M-3 | `backend/ambassador/services/commission_service.py:173-189` | **Bulk `select_for_update()` lock acquisition depends on `.count()` evaluation order.** The queryset `commissions` has `select_for_update()` but is lazy. The locks are only acquired when `commissions.count()` evaluates on line 185. Then `pending_commissions.update()` on line 186 generates a separate `UPDATE ... WHERE ...` SQL statement. While the rows ARE locked in the transaction (because `.count()` triggered the `SELECT FOR UPDATE`), the code is fragile: if `.count()` were removed or reordered after `.update()`, the lock would not be held before the update. | Make the locking explicit and obvious. Either: (1) force evaluation with `list(commissions.values_list('id', flat=True))` first, then filter and update by those IDs, or (2) add a clear comment explaining why `.count()` must remain before `.update()` for correctness. Option 1 is safer. |
| M-4 | `ambassador_provider.dart:53-62` | **`updateReferralCode` sets `state.error` on failure, polluting dashboard state.** When the referral code update throws, the notifier catches it and sets `state = state.copyWith(error: e.toString())`. This causes the ENTIRE ambassador dashboard to show an error state (error banner replaces all content). The error should only be shown in the dialog, which already has its own try-catch. | Either rethrow the exception so the dialog's catch handles it: `catch (e) { rethrow; }`, or return false without polluting state: `catch (_) { return false; }`. The dialog at `ambassador_settings_screen.dart:339-350` already catches and displays errors inline. |
| M-5 | `backend/ambassador/services/commission_service.py:88-90, 150-152, 191-193, 247-249` | **No validation that `ambassador_profile_id` exists before `AmbassadorProfile.objects.get()`.** If an admin sends a request with a non-existent `ambassador_id` in the URL, the commission lookup returns "Commission not found" (safe), but then the `AmbassadorProfile.objects.get(id=ambassador_profile_id)` call on the refresh line throws an unhandled `DoesNotExist` resulting in a 500 error. This path is reachable when `result.success` is False in the individual methods (the view returns 400 before reaching refresh), but in the bulk methods, `refresh_cached_stats()` is ALWAYS called regardless of whether any commissions were found. | Add a guard: `try: profile = AmbassadorProfile.objects.get(id=ambassador_profile_id)` with a `DoesNotExist` catch. Or validate the ambassador exists in the view before calling the service. The view already has `ambassador_id` from the URL but never validates it maps to a real profile. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m-1 | `monthly_earnings_chart.dart:26-29` | **Not using `theme.textTheme.bodyLarge` directly for header style.** The "Monthly Earnings" header creates a manual `TextStyle` extracting `color` from `bodyLarge` rather than using `theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)`. This pattern is used throughout the codebase so it is consistent, but it bypasses the centralized theme. | Use `style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)`. Not blocking. |
| m-2 | `ambassador_dashboard_screen.dart:499` | **`catch (_)` in `_shareCode` swallows ALL exceptions.** The ticket says to catch `PlatformException` specifically, but this catches everything including unexpected fatal errors. | Change to `on PlatformException catch (_)` to only catch the expected exception type. Other exceptions should propagate. |
| m-3 | `ambassador_settings_screen.dart:273` | **Counter text `'${controller.text.length}/20'` does not update on every keystroke.** The `counterText` reads `controller.text.length` at build time. The `onChanged` callback only calls `setDialogState` when clearing `errorText`, so the counter does not refresh on normal typing. | Either add `setDialogState(() {})` in `onChanged` unconditionally, OR remove `counterText` entirely and let `maxLength: 20` auto-generate the counter (Flutter default). |
| m-4 | `ambassador_settings_screen.dart:325` | **Using `this.context` inside an async gap after `Navigator.pop`.** `ScaffoldMessenger.of(this.context)` after popping the dialog could reference a context being disposed. The `mounted` check helps but accessing the state's `context` after a dialog pop is fragile. | Capture `final messenger = ScaffoldMessenger.of(context);` before the async gap, then use `messenger.showSnackBar(...)`. |
| m-5 | `backend/ambassador/views.py:105` | **`timezone.timedelta` is not an explicit import.** `timezone.timedelta(days=180)` works because Django's `timezone` module happens to import `timedelta` from `datetime`. This is an implementation detail, not a documented public API. | Add `from datetime import timedelta` at the top and use `timedelta(days=180)` directly. |
| m-6 | `backend/ambassador/views.py:239` | **`profile.save(update_fields=['referral_code', 'updated_at'])` -- `updated_at` is redundant.** The `auto_now=True` on `updated_at` means Django automatically includes it in `update_fields`. Listing it explicitly is harmless but misleading. | Remove `'updated_at'` from the list, leaving `update_fields=['referral_code']`. |
| m-7 | `backend/ambassador/serializers.py:169-172` | **Ticket specified `RegexField` but implementation uses `CharField`.** The `CustomReferralCodeSerializer` uses `CharField(min_length=4, max_length=20)` with a manual regex check in `validate_referral_code`. The ticket called for `RegexField`. However, the current approach is actually better because it strips whitespace and uppercases BEFORE the regex check, which `RegexField` does not support. | Acceptable deviation. Add a comment explaining why `CharField` is used over `RegexField`. |
| m-8 | `admin_ambassador_detail_screen.dart:367-380` | **`_parseErrorMessage` uses string matching on `error.toString()`.** This is brittle -- if the backend error message wording changes, the parsing breaks silently. | Consider parsing the DioException's response data directly (e.g., `(e as DioException).response?.data['error']`) instead of string matching on `toString()`. This is more robust and less brittle. |

---

## Security Concerns

1. **Permission checks are correct.** All 4 new admin views use `[IsAuthenticated, IsAdmin]`. The referral code PUT uses `[IsAuthenticated, IsAmbassador]`. Verified against `core/permissions.py`.

2. **No IDOR vulnerability.** Commission operations filter by `ambassador_profile_id` from the URL path, and only admins can access these URLs. An admin could manipulate `ambassador_id` but they are authorized to manage any ambassador.

3. **Bulk commission_ids from different ambassadors.** An admin could send commission IDs belonging to a different ambassador in the bulk payload. The service correctly filters by `ambassador_profile_id=ambassador_profile_id`, so cross-ambassador IDs are silently skipped. This is correct and safe.

4. **Custom referral code validation is sound.** The `RegExp(r'^[A-Z0-9]{4,20}$')` after strip/uppercase prevents injection. Alphanumeric only. The TOCTOU race (C-2) is a reliability issue, not a security issue.

5. **No secrets or credentials in any changed file.** Verified.

---

## Performance Concerns

1. **`refresh_cached_stats()` runs 2 queries after every commission action.** The `referrals.count()` and `commissions.filter().aggregate()` queries are unavoidable for correctness. For individual operations this is fine; for bulk operations it runs only once (good design).

2. **Admin detail view runs extra `.count()` queries.** Lines 392-393 call `referrals.count()` and `commissions.count()` separately from the paginator's internal count. This adds 2 unnecessary DB queries per request. These could use the paginator's `page.paginator.count` instead.

3. **Monthly earnings chart aggregation** uses `TruncMonth` over 180 days with the `created_at` index. Efficient at current scale.

---

## Quality Score: 7/10

### Breakdown:
- **Correctness: 7/10** -- Two critical issues (transaction boundary, TOCTOU race). All acceptance criteria are implemented.
- **Architecture: 8/10** -- Clean service layer with frozen dataclasses. Good separation of concerns. The 150-line violation is severe.
- **Security: 9/10** -- Proper auth on all endpoints. No IDOR. No secrets. Correct role checks.
- **Type Safety: 8/10** -- Backend has full type hints. Mobile models are well-typed. Minor `catch (_)` overly broad.
- **Mobile Patterns: 6/10** -- 899 line file is a significant violation. Dashboard and settings also over limit. Riverpod used correctly. Repository pattern followed.

### Strengths:
- Commission service with frozen dataclasses is clean and follows project conventions
- `select_for_update()` on individual operations is correct
- `BulkCommissionActionSerializer` with `min_length=1` correctly handles empty array edge case
- Mobile UI handles loading, error, and success states for all new features
- Confirmation dialogs before all destructive/irreversible actions
- Per-commission loading state tracking via `Set<int>` is a good UX pattern
- Chart empty state, skeleton loading, and accessibility labels are all present

### Weaknesses:
- Transaction boundary on stats refresh (C-1) is the most important fix
- TOCTOU on referral code (C-2) will produce 500 errors under concurrent usage
- Three mobile files massively exceed 150-line convention (899, 512, 416 lines)
- Error state pollution in provider (M-4) can break the dashboard UI on referral code failure

---

## Recommendation: REQUEST CHANGES

**Blocking issues that must be fixed:**
1. **C-1:** Move `refresh_cached_stats()` inside the transaction block (or add error handling around it)
2. **C-2:** Catch `IntegrityError` on referral code save and return 400

**Should fix before merge:**
3. **M-4:** Stop polluting dashboard error state from `updateReferralCode`
4. **M-5:** Add ambassador profile existence validation before `refresh_cached_stats()`

**Recommended but not blocking:**
5. **M-1/M-2:** Extract sub-widgets to meet 150-line convention (can be a follow-up)
6. **M-3:** Make bulk operation lock acquisition more explicit

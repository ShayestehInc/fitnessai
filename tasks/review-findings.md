# Code Review Round 2: Ambassador Enhancements (Phase 5)

## Review Date: 2026-02-15

## Round 1 Fix Verification

### C-1: `refresh_cached_stats()` called OUTSIDE the transaction block -- FIXED

All four service methods (`approve_commission`, `pay_commission`, `bulk_approve`, `bulk_pay`) now call `_refresh_ambassador_stats(ambassador_profile_id)` **inside** the `with transaction.atomic():` block. Each has a clear comment: "Refresh cached stats inside the transaction so the aggregation reads a consistent snapshot while the lock is still held." Logger calls remain correctly outside the transaction.

**Verified at:** `commission_service.py` lines 107, 169, 216, 277.

### C-2: Custom referral code PUT endpoint TOCTOU / no IntegrityError catch -- FIXED

The `put` method now wraps `profile.save(update_fields=['referral_code'])` in a `try/except IntegrityError` block (lines 240-248), returning 400 with `{'referral_code': ['This referral code is already in use.']}`. The `IntegrityError` import is at line 10. Comment explains the DB constraint as the real guard.

**Verified at:** `views.py` lines 240-248.

### M-3: Bulk `select_for_update()` lock acquisition fragile -- FIXED

Both `bulk_approve` and `bulk_pay` now materialise locked IDs with `list(....values_list('id', flat=True))` before running `UPDATE`. Comments explain the design. Lock order is explicit and safe.

**Verified at:** `commission_service.py` lines 193-201, 254-262.

### M-4: `updateReferralCode` polluting dashboard error state -- FIXED

`updateReferralCode` now has no try-catch; exceptions propagate to the calling dialog. Docstring explains the design. The dialog in `ambassador_settings_screen.dart` lines 341-352 catches and displays errors locally via `setDialogState`.

**Verified at:** `ambassador_provider.dart` lines 52-59.

### M-5: No validation that `ambassador_profile_id` exists -- FIXED

Standalone helper `_refresh_ambassador_stats` (lines 33-48) wraps `AmbassadorProfile.objects.get()` in `try/except DoesNotExist`, logs a warning, and returns early. All four service methods use this helper.

**Verified at:** `commission_service.py` lines 33-48.

### Minor Issues

| # | Status | Notes |
|---|--------|-------|
| m-1 | NOT FIXED (acceptable) | Chart header still uses manual TextStyle. Consistent with codebase. Non-blocking. |
| m-2 | FIXED | `_shareCode` now catches `on PlatformException` instead of `catch (_)`. |
| m-3 | FIXED | `onChanged` always calls `setDialogState`, counter updates on every keystroke. |
| m-4 | FIXED | `ScaffoldMessenger` captured before async gap. |
| m-5 | FIXED | Direct `from datetime import timedelta` import, `timedelta(days=180)` used. |
| m-6 | FIXED | `update_fields=['referral_code']` without redundant `updated_at`. |
| m-7 | FIXED | Docstring on `CustomReferralCodeSerializer` explains CharField vs RegexField. |
| m-8 | FIXED | `_parseErrorMessage` extracts from `DioException.response?.data['error']` instead of string matching. |

---

## New Issues

| # | Severity | File | Issue | Notes |
|---|----------|------|-------|-------|
| N-1 | Minor | `admin_ambassador_detail_screen.dart` (900 lines) | Still 6x over 150-line convention. Pre-existing, acknowledged as follow-up in Round 1. No regression. | Follow-up task to extract sub-widgets. Not blocking. |
| N-2 | Minor | `ambassador_dashboard_screen.dart` (512 lines), `ambassador_settings_screen.dart` (418 lines) | Same as N-1. Pre-existing file length violations. | Follow-up task. Not blocking. |
| N-3 | Nit | `views.py:400-402` | `referrals.count()` and `commissions.count()` run separate queries duplicating paginator counts. Minimal impact at current scale. | Could use `paginator.page.paginator.count` when page is not None. |

No new critical or major issues found.

---

## Quality Score: 8/10

### Breakdown:
- **Correctness: 9/10** -- Both critical issues fixed correctly. All edge cases handled.
- **Architecture: 8/10** -- Clean `_refresh_ambassador_stats` extraction. Materialised IDs pattern is explicit and safe.
- **Security: 9/10** -- IntegrityError caught. No IDOR. No secrets. Auth verified.
- **Type Safety: 8/10** -- Full type hints on backend. Mobile correctly typed.
- **Mobile Patterns: 7/10** -- Provider correctly stops polluting state. File length violations are pre-existing.

### Strengths:
- Every critical and major issue from Round 1 fixed correctly and completely
- `_refresh_ambassador_stats` is a clean, defensive helper with proper logging
- Materialised IDs pattern in bulk methods is explicit and safe
- ScaffoldMessenger capture before async gap is the correct Flutter pattern
- DioException response data parsing is more robust than string matching

### Weaknesses:
- Three mobile files still exceed 150-line convention (pre-existing, follow-up)
- Minor redundant count queries in admin detail view

---

## Recommendation: APPROVE

All 2 critical and 5 major issues from Round 1 are verified fixed. 7 of 8 minor issues also fixed. No new critical or major issues introduced. The code is production-ready.

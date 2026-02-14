# Hacker Report: Ambassador Feature

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Critical | admin_create_ambassador_screen.dart | Create Ambassador form | Ambassador can log in after being created | `set_unusable_password()` was called -- ambassador had no way to authenticate. No password set, no activation email sent. **FIXED**: Added password field to backend serializer, view, repository, provider, and create screen. Admin now sets a temporary password. |
| 2 | High | admin_ambassador_detail_screen.dart | Commission rate display | Admin can edit the commission rate from the detail screen | Rate was display-only. No edit mechanism existed anywhere for individual ambassadors (only at creation time). **FIXED**: Added edit icon in AppBar, tappable Rate stat tile, and a slider dialog to update the commission rate. |
| 3 | High | admin_ambassador_detail_screen.dart | Commission History section | Admin sees the full commission history for an ambassador | Backend API returns `commissions` in the detail response, but the mobile screen never parsed or displayed them. Data was silently discarded. **FIXED**: Added `AmbassadorCommission` model, commission parsing in `_loadDetail()`, and a full Commission History section with styled tiles. |
| 4 | Medium | ambassador_dashboard_screen.dart | "Share Referral Code" button | Opens native share sheet (iOS/Android) | Only copies text to clipboard. The `share_plus` package is not installed. The button icon shows `Icons.share` but behavior is copy-to-clipboard. Partial fix: snackbar text clarifies "copied to clipboard." Full fix requires adding `share_plus` dependency -- documented below. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | ambassador_referrals_screen.dart | Empty state shows raw enum "No CHURNED referrals" instead of lowercase | **FIXED**: Added `_friendlyFilterLabel()` method that maps `ACTIVE` -> `active`, `PENDING` -> `pending`, etc. Empty state now reads "No active referrals" etc. |
| 2 | Low | admin_ambassadors_screen.dart | Email text in ambassador tile can overflow without ellipsis on narrow screens | **FIXED** (by linter): Added `overflow: TextOverflow.ellipsis` to email Text widget. |
| 3 | Low | admin_ambassador_detail_screen.dart | Email text in profile card can overflow | **FIXED**: Added `overflow: TextOverflow.ellipsis`. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Ambassador avatar crash | 1. Create referral where trainer has no firstName and email local part is empty string (e.g., `@domain.com`). 2. View dashboard or referrals screen. | Avatar shows fallback character | `displayName[0]` throws `RangeError` on empty string. **FIXED**: Added `AmbassadorUser.initials` getter with empty-string guard, returns `?` as fallback. All avatar usages now use `.initials` instead of `displayName[0].toUpperCase()`. |
| 2 | High | Admin ambassador list pull-to-refresh loses filters | 1. Search for "john" in admin ambassadors screen. 2. Pull to refresh. | Results still filtered by "john" | `RefreshIndicator` called `loadAmbassadors()` with no params, clearing the active search and filter. **FIXED**: Pull-to-refresh now passes `_searchController.text.trim()` and `_activeFilter` to `loadAmbassadors()`. |
| 3 | High | Settings screen shows "Inactive" before data loads | 1. Navigate to ambassador settings tab. 2. Before dashboard API returns, check Status row. | Shows "--" or loading indicator | `dashState.data?.isActive == true` evaluates to `false` when `data` is null, displaying "Inactive" incorrectly. **FIXED**: Changed to show "--" when `dashState.data` is null. |
| 4 | Medium | AmbassadorDetailData counts always zero | `referralsCount` and `commissionsCount` fields parsed from JSON keys `referrals_count` and `commissions_count` that don't exist in backend response | Counts should reflect actual data | Fields always defaulted to 0 regardless of actual list contents. **FIXED**: Changed to computed getters `referrals.length` and `commissions.length`. |
| 5 | Low | Ambassador detail screen: _isToggling field declared but never changed | `_isToggling` was declared but the linter restructured the toggle flow with a confirmation dialog -- toggle state was not always tracked | Toggle button should show loading state during API call | Linter partially fixed this. The `_isToggling` state is now properly set/unset around the update call. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Ambassador creation | Add an email invitation flow: when admin creates ambassador, system sends an email with login credentials or a magic link. | Currently admin must manually communicate the password out-of-band. A proper invitation email would be more professional and secure. |
| 2 | High | Share referral code | Install `share_plus` and use the native share sheet instead of clipboard copy. | The share button's icon (`Icons.share`) implies a native share sheet, but it only copies to clipboard. Using the real share sheet would let ambassadors share via WhatsApp, SMS, email, etc. with one tap. |
| 3 | High | Ambassador earnings | Add a monthly earnings chart/graph on the ambassador dashboard. | The backend already returns `monthly_earnings` data, but the mobile dashboard only shows the recent referrals list and stat tiles. A simple bar chart would make the earnings trend visible at a glance. |
| 4 | Medium | Commission management | Add bulk approve/pay commissions for admin in the detail screen. | Currently there's no way for admin to approve or pay commissions from the mobile app. The status is display-only. |
| 5 | Medium | Referral code customization | Let admin (or ambassador) choose a custom referral code (e.g., "JOHN20") instead of random alphanumeric. | Custom codes are more memorable and brandable. Many referral programs (e.g., Uber, Robinhood) allow this. |
| 6 | Low | Ambassador dashboard | Add a "time since last referral" or "streak" indicator. | Gamification encourages continued engagement. Showing "Last referral: 3 days ago" or "2 referrals this month" keeps ambassadors motivated. |
| 7 | Low | Admin list view | Show an active/inactive badge on each ambassador tile in the admin list. | Currently the only indicator is the circle avatar color (teal vs grey), which is subtle. An explicit status badge would be clearer. |

## Items NOT Fixed (Need Design Decisions or Backend Changes)
| # | Severity | Description | Steps to Reproduce | Suggested Approach |
|---|----------|-------------|-------------------|--------------------|
| 1 | High | No native share sheet -- `share_plus` not installed | Tap "Share Referral Code" on ambassador dashboard | Add `share_plus: ^7.0.0` to `pubspec.yaml`, run `flutter pub get`, update `_shareCode()` to use `Share.share(message)`. |
| 2 | High | No commission approval/payment workflow in mobile | Admin views commission history but can't change status | Add approve/pay buttons on commission tiles in admin detail screen. Create backend endpoint `PATCH /api/admin/ambassadors/<id>/commissions/<id>/` for status updates. |
| 3 | Medium | No password reset flow anywhere in the app | Ambassador forgets password -> no recovery mechanism | Implement Djoser password reset endpoints (`/api/auth/users/reset_password/`, `/api/auth/users/reset_password_confirm/`) and add a "Forgot Password" link on the login screen. |
| 4 | Medium | `AmbassadorReferral` model has redundant FKs | `ambassador` (User FK) and `ambassador_profile` (AmbassadorProfile FK) both exist -- denormalization risk if they get out of sync | Consider removing `ambassador` FK and accessing the user through `ambassador_profile.user`. Requires migration. |
| 5 | Low | No ambassador earnings chart despite backend support | Backend returns `monthly_earnings` list in dashboard response | Add `fl_chart` package and render a simple bar chart in `ambassador_dashboard_screen.dart` showing monthly earnings trend. |

## Summary
- Dead UI elements found: 4
- Visual bugs found: 3
- Logic bugs found: 5
- Improvements suggested: 7
- Items fixed by hacker: 10
- Items needing design decisions: 5

## Chaos Score: 6/10
The ambassador feature has the most critical bug I found in any feature during this pass: newly created ambassadors could not log in because the backend called `set_unusable_password()` with no alternative authentication mechanism. This would have been immediately discovered in production and would block the entire ambassador workflow. The second most impactful issue was the admin detail screen silently discarding commission data returned by the backend -- the data was there, nobody was showing it. The `displayName[0]` crash was lurking as a time bomb that would trigger on edge-case user data. On the positive side, the overall architecture is clean (proper repository pattern, Riverpod state management, well-structured models), the referral code processing backend is solid with proper idempotency checks, and the UI handles loading/error/empty states consistently across screens.

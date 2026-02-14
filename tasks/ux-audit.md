# UX Audit: Ambassador Feature

## Audit Date: 2026-02-14

## Files Reviewed
- `mobile/lib/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_referrals_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_settings_screen.dart`
- `mobile/lib/features/ambassador/presentation/screens/ambassador_navigation_shell.dart`
- `mobile/lib/features/ambassador/presentation/providers/ambassador_provider.dart`
- `mobile/lib/features/ambassador/data/models/ambassador_models.dart`
- `mobile/lib/features/ambassador/data/repositories/ambassador_repository.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassadors_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_create_ambassador_screen.dart`
- `mobile/lib/features/admin/presentation/screens/admin_ambassador_detail_screen.dart`
- `mobile/lib/features/auth/presentation/screens/register_screen.dart`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | High | Navigation Shell `_NavItem` | Touch targets too small (64px wide, no height constraint). Below 48dp Material minimum. No visual tap feedback (GestureDetector instead of InkWell). | Switched to InkWell with 72x48dp minimum size, added borderRadius for splash. | FIXED |
| 2 | High | Admin Ambassadors list tile | Used GestureDetector with no visual feedback on tap. Users get no indication the tile is tappable. | Replaced with Material + InkWell for splash/highlight feedback. | FIXED |
| 3 | High | Admin Ambassador Detail toggle | Activate/deactivate ambassador has no confirmation dialog. Critical action performed with a single tap. No loading feedback during the network call. No error feedback on failure. | Added confirmation AlertDialog with contextual messaging. Added loading spinner in app bar during toggle. Added error snackbar on failure. | FIXED |
| 4 | Medium | Settings Screen logout | No confirmation dialog before logout. Accidental taps could sign the user out. | Added confirmation AlertDialog before performing logout. | FIXED |
| 5 | Medium | Admin Create Ambassador form | Form fields remain editable during submission. User could modify fields while request is in-flight. | Wrapped form in AbsorbPointer during submission with AnimatedOpacity visual feedback. | FIXED |
| 6 | Medium | Referrals Screen empty state | Shows raw status enum text ("No ACTIVE referrals") instead of user-friendly cased text. | Added `_friendlyFilterLabel()` helper to lowercase status names for display. | FIXED |
| 7 | Medium | Settings Screen ambassador details | No loading or error states. Shows "--" placeholders when data hasn't loaded yet, with no indicator that loading is in progress and no way to retry on error. | Added inline loading spinner next to section header, error banner with retry button, proper state branching. | FIXED |
| 8 | Low | Dashboard empty state | Generic message with no call-to-action. User lands on an empty screen with no guidance. | Added welcoming headline, descriptive subtext, and a Refresh button. | FIXED |
| 9 | Low | All error states | Used hardcoded `Colors.red` for error icons and text. Not theme-consistent. Raw error messages displayed without headline. | Changed all error states to use `theme.colorScheme.error`, added user-friendly headline text ("Something went wrong", "Could not load referrals", etc.), moved raw error to secondary muted text with maxLines/overflow. | FIXED |
| 10 | Low | All retry buttons | Plain text "Retry" button with no icon indicating the action. | Changed all retry buttons to `ElevatedButton.icon` with refresh icon. | FIXED |
| 11 | Low | Dashboard stat labels | Font size was 11px, borderline legible on smaller screens. | Increased to 12px for better readability. | FIXED |
| 12 | Low | Suspended banner copy | "Account suspended. Contact admin for details." is terse and slightly alarming. | Reworded to "Your account is currently suspended. Please contact the admin team for assistance." -- more empathetic and actionable. | FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A | Navigation shell nav items had no Semantics labels for screen readers | Added `Semantics(label, button, selected)` wrapper to `_NavItem` | FIXED |
| 2 | A | Dashboard stat tiles (Total/Active/Pending/Churned) not labeled for screen readers | Added `Semantics(label: '$label referrals: $value')` to each stat tile | FIXED |
| 3 | A | Share referral code button had no semantic description of what code it shares | Added `Semantics(button, label: 'Share referral code $code')` wrapper | FIXED |
| 4 | A | Suspended banner not announced as a warning to screen readers | Added `Semantics(label)` with full warning text to suspended banner | FIXED |
| 5 | A | Admin ambassador list tiles had no semantic descriptions | Added `Semantics(button, label)` with ambassador name, referral count, and status | FIXED |
| 6 | A | Admin detail stat tiles not labeled for screen readers | Added `Semantics(label: '$label: $value')` to each stat tile | FIXED |
| 7 | A | Settings info rows not announced as label-value pairs | Added `Semantics(label: '$label: $value')` to each info row | FIXED |
| 8 | A | Logout button had no semantic description | Added `Semantics(button, label: 'Log out of your account')` wrapper | FIXED |
| 9 | A | Create ambassador commission slider not announced | Added `Semantics(label)` wrapper around the commission rate slider section | FIXED |
| 10 | A | Referral cards in referrals screen not announced as a unit | Added `Semantics(label)` wrapper with name, status, and commission info | FIXED |

---

## Missing States Assessment

### Ambassador Dashboard Screen
- [x] Loading / skeleton -- CircularProgressIndicator shown
- [x] Empty / zero data -- Welcome message with refresh button (improved)
- [x] Error / failure -- Theme-colored error with headline, detail, retry (improved)
- [x] Success / confirmation -- SnackBar on copy/share actions
- [x] Offline / degraded -- N/A (handled by error state)
- [x] Permission denied -- N/A (route-level guard)
- [x] Suspended state -- Warning banner shown

### Ambassador Referrals Screen
- [x] Loading / skeleton -- CircularProgressIndicator shown
- [x] Empty / zero data -- Context-aware message based on filter (improved)
- [x] Error / failure -- Theme-colored error with headline, detail, retry (improved)
- [x] Success / confirmation -- Pull-to-refresh supported
- [x] Filter states -- Filter chips with visual selection state

### Ambassador Settings Screen
- [x] Loading / skeleton -- Inline spinner in section header (added)
- [x] Empty / zero data -- "--" placeholders when data not yet loaded
- [x] Error / failure -- Inline error banner with retry (added)
- [x] Success / confirmation -- Logout confirmation dialog (added)

### Admin Ambassadors Screen
- [x] Loading / skeleton -- CircularProgressIndicator shown
- [x] Empty / zero data -- Empty state with icon and text
- [x] Error / failure -- Theme-colored error with headline, detail, retry (improved)
- [x] Success / confirmation -- Pull-to-refresh supported

### Admin Create Ambassador Screen
- [x] Loading / skeleton -- Button loading indicator
- [x] Form submission -- AbsorbPointer + opacity during submission (added)
- [x] Error / failure -- SnackBar with error message
- [x] Success / confirmation -- SnackBar with referral code, auto-pop
- [x] Validation states -- Per-field validation messages

### Admin Ambassador Detail Screen
- [x] Loading / skeleton -- CircularProgressIndicator shown
- [x] Empty / zero data -- Empty referrals state
- [x] Error / failure -- Theme-colored error with headline, detail, retry (improved)
- [x] Toggle loading -- Loading spinner in app bar during toggle (added)
- [x] Toggle confirmation -- AlertDialog confirmation (added)
- [x] Toggle error feedback -- Error snackbar on failure (added)

### Ambassador Navigation Shell
- [x] Active state -- Color + weight change on selected tab
- [x] Touch feedback -- InkWell splash effect (added)
- [x] Minimum touch targets -- 72x48dp (improved)

---

## Copy & Messaging Review

| # | Location | Original Copy | Improved Copy | Rationale |
|---|----------|--------------|---------------|-----------|
| 1 | Dashboard suspended banner | "Account suspended. Contact admin for details." | "Your account is currently suspended. Please contact the admin team for assistance." | More empathetic, uses "your" for personal connection, "admin team" implies humans not a system |
| 2 | Dashboard empty state | "Share your referral code to start earning!" | "Welcome, Ambassador!" + "Share your referral code to start earning commissions on every trainer you refer." | Adds a warm greeting, explains the value proposition more clearly |
| 3 | Referrals empty state (filtered) | "No ACTIVE referrals" | "No active referrals" + "Try a different filter or check back later." | Lowercased status, added helpful guidance |
| 4 | Referrals empty state (unfiltered) | "No referrals yet" | "No referrals yet" + "Share your referral code to get started." | Added actionable guidance |
| 5 | Create ambassador error snackbar | "Failed to create ambassador" | "Failed to create ambassador. Please try again." | Added actionable guidance |
| 6 | All error states | Raw error string only | "Something went wrong" / "Could not load X" headline + raw error as secondary text | User-friendly headline separates the "what" from the technical "why" |

---

## Consistency Review

### Positive Patterns (Consistent Across Files)
- Card containers use consistent `theme.cardColor` + `borderRadius: 12` + `border: theme.dividerColor`
- Status colors are consistent: green=active, orange=pending, red=churned, grey=default
- Typography uses theme text styles consistently (bodyLarge, bodySmall)
- Spacing uses consistent 16px/24px padding patterns
- All screens use `theme.scaffoldBackgroundColor` for scaffold and app bar

### Issues Found and Fixed
- Error states now use consistent pattern: icon + headline + detail + retry button (previously inconsistent across screens)
- Stat tile labels now use consistent 12px font (was 11px in some places)
- Retry buttons now consistently use `ElevatedButton.icon` with refresh icon
- Touch feedback now consistently uses InkWell (was GestureDetector in some places)

---

## Fixes Applied Summary

### 1. Navigation Shell Touch Targets (ambassador_navigation_shell.dart)
- Replaced `GestureDetector` with `InkWell` for proper Material ripple/splash feedback
- Increased touch target from 64px wide / unconstrained height to 72x48dp minimum
- Added `Semantics(label, button, selected)` for screen reader support

### 2. Dashboard Error State (ambassador_dashboard_screen.dart)
- Replaced hardcoded `Colors.red` with `theme.colorScheme.error`
- Added user-friendly "Something went wrong" headline
- Moved raw error to secondary muted text with `maxLines: 4` and `TextOverflow.ellipsis`
- Changed retry button to `ElevatedButton.icon` with refresh icon

### 3. Dashboard Empty State (ambassador_dashboard_screen.dart)
- Added "Welcome, Ambassador!" headline
- Added descriptive subtext about earning commissions
- Added Refresh button CTA

### 4. Dashboard Suspended Banner (ambassador_dashboard_screen.dart)
- Improved copy to be more empathetic and actionable
- Added `Semantics` label for screen reader warning announcement

### 5. Dashboard Stat Tiles (ambassador_dashboard_screen.dart)
- Added `Semantics(label)` for screen reader support
- Increased label font from 11px to 12px for readability

### 6. Dashboard Share Button (ambassador_dashboard_screen.dart)
- Added `Semantics(button, label)` with referral code for screen readers

### 7. Referrals Error State (ambassador_referrals_screen.dart)
- Same pattern as dashboard: theme-colored, headline, detail, retry icon button

### 8. Referrals Empty State (ambassador_referrals_screen.dart)
- Added `_friendlyFilterLabel()` to convert "ACTIVE" to "active" for display
- Added contextual subtext based on filter state
- Added padding for consistent spacing

### 9. Referral Cards (ambassador_referrals_screen.dart)
- Added `Semantics(label)` with name, status, and commission for screen readers

### 10. Settings Error/Loading States (ambassador_settings_screen.dart)
- Added inline loading spinner in section header row
- Added error banner with retry button when data fails to load
- Extracted `_buildAmbassadorDetailsCard()` for cleaner state management

### 11. Settings Logout Confirmation (ambassador_settings_screen.dart)
- Added confirmation AlertDialog before logout
- Used `theme.colorScheme.error` for destructive action styling
- Added `Semantics` to logout button

### 12. Settings Info Rows (ambassador_settings_screen.dart)
- Added `Semantics(label)` to each info row for screen readers

### 13. Admin List Tiles (admin_ambassadors_screen.dart)
- Replaced `GestureDetector` with `Material` + `InkWell` for tap feedback
- Added `Semantics(button, label)` for screen readers
- Added `TextOverflow.ellipsis` on email to prevent overflow

### 14. Admin List Error State (admin_ambassadors_screen.dart)
- Same pattern as others: theme-colored, headline, detail, retry icon button

### 15. Admin Detail Confirmation Dialog (admin_ambassador_detail_screen.dart)
- Added AlertDialog confirmation before activate/deactivate with contextual messaging
- Added `_isToggling` flag with loading spinner in app bar
- Added error snackbar on toggle failure

### 16. Admin Detail Error State (admin_ambassador_detail_screen.dart)
- Same pattern: theme-colored, headline, detail, retry icon button

### 17. Admin Detail Stat Tiles (admin_ambassador_detail_screen.dart)
- Added `Semantics(label)` for screen readers
- Increased label font from 11px to 12px

### 18. Create Ambassador Form (admin_create_ambassador_screen.dart)
- Wrapped form in `AbsorbPointer` during submission to prevent editing
- Added `AnimatedOpacity` for visual feedback during submission
- Added `prefixIcon` to form fields for visual clarity
- Added `textInputAction` for proper keyboard flow
- Added `textCapitalization` for name fields
- Added `hintText` for email field
- Added `Semantics` to commission slider section
- Set button height to 48dp minimum
- Improved success snackbar duration to 4 seconds (longer since it shows the referral code)

---

## Items Not Fixed (Need Design Decisions)

| # | Area | Issue | Suggested Approach |
|---|------|-------|-------------------|
| 1 | Dashboard earnings card | Uses hardcoded `Colors.white70` and `Colors.white` for text on gradient background. Acceptable for gradient cards, but not theme-driven. | Consider creating semantic color constants like `onGradientPrimary` / `onGradientSecondary` in theme. |
| 2 | Share referral code | Currently copies to clipboard instead of using platform share sheet. | Integrate `share_plus` package for native sharing (would require dependency addition). |
| 3 | Register screen referral code field | Only shown for TRAINER role. No indication that ambassador referral codes exist or can be used. | Consider adding helper text that clarifies this is an ambassador referral code. Not modified since instruction was to focus on ambassador files only. |
| 4 | Referrals screen | No pagination -- loads all referrals at once. | For ambassadors with many referrals, add infinite scroll pagination. |

---

## Overall UX Score: 8/10

The ambassador feature's mobile UI is well-structured with proper state handling for the core states (loading, populated, empty, error). The fixes applied improve accessibility significantly by adding Semantics widgets throughout, enhance usability by adding confirmation dialogs for destructive actions, improve error states with user-friendly messaging, and fix touch target sizes for Material accessibility compliance. The main remaining gaps are around native sharing (clipboard-only) and pagination for the referrals list.

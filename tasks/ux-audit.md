# UX Audit: Web Dashboard Phase 2 (Pipeline 10)

## Audit Date: 2026-02-15

## Pages & Components Reviewed
- Settings page: `settings/page.tsx`, `profile-section.tsx`, `appearance-section.tsx`, `security-section.tsx`
- Progress charts: `progress-charts.tsx`, `trainee-progress-tab.tsx`
- Notification click-through: `notification-item.tsx`, `notification-popover.tsx`, `notification-bell.tsx`, `notifications/page.tsx`
- Invitation row actions: `invitation-actions.tsx`, `invitation-columns.tsx`
- Supporting: `use-settings.ts`, `use-progress.ts`, `use-invitations.ts`, `use-notifications.ts`, `user-nav.tsx`, `auth-provider.tsx`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | High | UserNav (header) | Avatar did not render profile image -- only showed fallback initials even when user had a `profile_image` set. After uploading a photo in Settings, the header avatar did not visually reflect it. | Added `AvatarImage` rendering with `user.profile_image` to `user-nav.tsx` -- FIXED |
| 2 | High | InvitationActions | Dropdown menu stayed open after clicking "Resend" or "Copy Code", creating visual clutter while the mutation was in flight. | Added controlled `open` state to DropdownMenu; actions now close the dropdown immediately on click -- FIXED |
| 3 | High | InvitationActions | Cancel confirmation dialog's destructive button had no loading indicator -- user had no feedback that the cancellation was processing. | Added `Loader2` spinner and `aria-hidden` to the "Cancel invitation" button when `cancel.isPending` -- FIXED |
| 4 | Medium | SecuritySection | Submitting the password form with an empty "New password" field showed "Password must be at least 8 characters" which is misleading for a blank field. Similarly, empty confirm field had no specific message. | Added distinct validation: empty new password shows "New password is required"; empty confirm shows "Please confirm your new password" -- FIXED |
| 5 | Medium | Adherence Chart | Y-axis displayed raw numeric ticks (0, 1, 2, 3) which are meaningless for stacked boolean data (food/workout/protein). | Removed Y-axis ticks and axis line; set minimal width. The Legend and tooltip provide sufficient context. -- FIXED |
| 6 | Medium | Adherence Chart | Bar colors used hardcoded HSL values (`hsl(142, 76%, 36%)`, etc.) instead of the extracted `CHART_COLORS` constant that maps to `--chart-N` CSS custom properties, breaking in dark mode. | Replaced hardcoded HSL with `CHART_COLORS.food`, `.workout`, `.protein` for theme-aware colors -- FIXED |
| 7 | Medium | Volume Chart | Tooltip displayed raw numbers without thousands separators (e.g., "125000" instead of "125,000"). | Added `formatNumber()` formatter to the Volume chart tooltip using `Intl.NumberFormat` -- FIXED |
| 8 | Medium | Settings Page | Error state retry used `window.location.reload()` -- a full page reload instead of a targeted refetch, inconsistent with every other page in the app. | Changed to `refreshUser()` from auth context for consistent behavior -- FIXED |
| 9 | Low | ProfileSection (image overlay) | Loading spinner overlay on avatar during image upload/delete had Loader2 icon without `aria-hidden="true"`, exposed to screen readers as meaningless content. | Added `aria-hidden="true"` to overlay Loader2 -- FIXED |
| 10 | Low | NotificationPopover | Loading spinner in popover had no `role="status"` or screen reader text. | Added `role="status"`, `aria-label`, and `sr-only` span -- FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA (4.1.2) | AppearanceSection radio group buttons all had `tabIndex` of 0, meaning Tab key would stop on every option instead of the selected one. Arrow keys did not move selection. | Implemented proper radio group keyboard navigation: only selected radio has `tabIndex={0}`, others have `tabIndex={-1}`. Arrow keys (Left/Right/Up/Down) cycle selection and move focus. Added `focus-visible:ring-2` for focus indicator. -- FIXED |
| 2 | AA (4.1.2) | SecuritySection password inputs had no `aria-describedby` linking to error messages, so screen readers could not announce inline errors. | Added `aria-describedby` pointing to error `<p id="...">` elements and `aria-invalid` on each input when validation fails. -- FIXED |
| 3 | A (1.1.1) | SecuritySection error messages had `role="alert"` but no `id` for `aria-describedby` linkage. | Added unique IDs (`currentPassword-error`, `newPassword-error`, `confirmPassword-error`) to error paragraphs. -- FIXED |
| 4 | A (1.3.1) | ProfileSection email field had hint text "Email cannot be changed" not linked to the input. | Added `aria-describedby="email-hint"` to the email input and `id="email-hint"` to the hint text. -- FIXED |
| 5 | A (1.1.1) | NotificationPopover loading Loader2 icon not marked as decorative. | Added `aria-hidden="true"` -- FIXED |
| 6 | AA (4.1.2) | InvitationActions cancel dialog Loader2 not marked as decorative. | Added `aria-hidden="true"` on the spinner icon -- FIXED |

---

## Missing States

### Settings Page
- [x] Loading / skeleton -- `SettingsSkeleton` renders three card placeholders while auth data loads
- [x] Empty / zero data -- N/A (settings always has data when user is authenticated)
- [x] Error / failure -- `ErrorState` with retry if user fails to load
- [x] Success / confirmation -- Toast notifications on profile save, image upload/remove, password change
- [x] Disabled -- Save button disabled when form is unchanged (`isDirty` check) or mutation pending

### Progress Charts
- [x] Loading / skeleton -- `ProgressSkeleton` renders three chart card placeholders
- [x] Empty / zero data -- Per-chart `EmptyState` with relevant icon and message (Scale, Dumbbell, CalendarCheck)
- [x] Error / failure -- `ErrorState` with retry if progress data fetch fails
- [x] Success / confirmation -- Data display in charts

### Notifications (Click-Through)
- [x] Loading -- Spinner in popover; `LoadingSpinner` on full page
- [x] Empty -- Context-aware: "All caught up" (unread filter) / "No notifications" (all filter) / "No notifications yet" (popover)
- [x] Error -- `ErrorState` with retry on full page; inline error with retry in popover
- [x] Navigable feedback -- ChevronRight indicator on notifications with `trainee_id`; toast for non-navigable mark-as-read

### Invitation Actions
- [x] Loading -- Button `disabled` state during mutations; spinner on cancel dialog
- [x] Confirmation -- Destructive cancel action requires confirmation dialog
- [x] Success -- Toast on copy, resend, cancel
- [x] Error -- Toast on resend/cancel failure; clipboard error handling

---

## Copy Assessment

| Element | Copy | Verdict |
|---------|------|---------|
| Profile card title | "Profile" | Clear |
| Profile card description | "Update your personal information and profile image" | Informative, tells user what they can do |
| Email hint | "Email cannot be changed" | Clear, explains why field is disabled |
| Appearance description | "Choose how the dashboard looks to you" | Friendly, personal |
| Security description | "Update your password" | Direct |
| Password validation (empty) | "New password is required" | Clear, specific to blank field |
| Password validation (short) | "Password must be at least 8 characters" | Standard, clear |
| Password validation (mismatch) | "Passwords do not match" | Standard |
| Confirm validation (empty) | "Please confirm your new password" | Clear, actionable |
| Cancel dialog title | "Cancel invitation?" | Clear question |
| Cancel dialog body | "This will cancel the invitation sent to **{email}**. They will no longer be able to use this invitation code to sign up." | Explains consequences clearly |
| Cancel dialog actions | "Keep invitation" / "Cancel invitation" | Clear, non-ambiguous |
| Chart empty states | "No weight data" / "No workout data" / "No activity data" | Consistent pattern |
| Chart empty descriptions | "...will appear here once the trainee logs them." | Sets expectation, non-alarming |
| Toast messages | "Profile updated" / "Invitation resent" / "Invitation cancelled" / etc. | Concise, past-tense confirmation |

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Card spacing | Consistent | All settings cards use `space-y-6` between them |
| Tooltip styling | Consistent (after fix) | All charts now use shared `tooltipContentStyle` constant |
| Chart colors | Consistent (after fix) | Adherence chart now uses `CHART_COLORS` constant instead of hardcoded HSL |
| Error state | Consistent | All pages use shared `ErrorState` component with retry |
| Empty state | Consistent | All chart empty states use shared `EmptyState` with relevant icons |
| Toast feedback | Consistent | All mutations provide success/error toasts |
| Button loading state | Consistent (after fix) | All pending mutations show Loader2 spinner in the button |
| Dropdown actions | Consistent | Actions close the dropdown, show appropriate feedback |

---

## Responsiveness Assessment

| Aspect | Status |
|--------|--------|
| Settings layout | `max-w-2xl` constrains width, cards stack vertically naturally |
| Profile form grid | `sm:grid-cols-2` for first/last name, stacks on mobile |
| Theme selector | `flex gap-3` with `flex-1` buttons -- adapts to container width |
| Charts | `ResponsiveContainer` from recharts handles resize automatically |
| Chart container | Fixed `h-[250px]` height is appropriate for all viewport sizes |
| Invitation dropdown | Touch-friendly trigger button (`h-8 w-8`), dropdown aligns to end |
| Notification popover | `w-80` fixed width with `ScrollArea` for overflow |

---

## Fixes Implemented

### 1. `web/src/components/layout/user-nav.tsx`
Added `AvatarImage` import and rendering so the header avatar displays the user's profile image when one exists. Previously only showed initials fallback.

### 2. `web/src/components/settings/appearance-section.tsx`
Implemented proper ARIA radio group keyboard navigation:
- Selected radio gets `tabIndex={0}`, unselected get `tabIndex={-1}` (roving tabindex pattern)
- Arrow key handler (Left/Right/Up/Down) cycles through options, moves focus, and updates theme
- Added `focus-visible:ring-2` focus indicator on radio buttons

### 3. `web/src/components/settings/security-section.tsx`
- Improved validation: separate "required" messages for empty fields vs. length/match errors
- Added `aria-describedby` on all three password inputs linking to their error paragraphs
- Added `aria-invalid` on inputs when validation fails
- Added `id` attributes on error paragraphs for `aria-describedby` linkage

### 4. `web/src/components/settings/profile-section.tsx`
- Added `aria-hidden="true"` on image upload overlay spinner
- Added `aria-describedby="email-hint"` on read-only email field
- Added `id="email-hint"` on the "Email cannot be changed" hint text

### 5. `web/src/app/(dashboard)/settings/page.tsx`
- Changed error retry from `window.location.reload()` to `refreshUser()` for consistency

### 6. `web/src/components/trainees/progress-charts.tsx`
- Replaced hardcoded HSL colors in Adherence chart with `CHART_COLORS` constant for dark mode support
- Removed misleading Y-axis numeric ticks from Adherence chart (0,1,2,3 were meaningless for boolean data)
- Added `formatNumber()` with `Intl.NumberFormat` to Volume chart tooltip for thousand separators

### 7. `web/src/components/invitations/invitation-actions.tsx`
- Added controlled `open`/`onOpenChange` state to DropdownMenu
- All action handlers now close the dropdown immediately via `setDropdownOpen(false)`
- Added `Loader2` spinner with `aria-hidden` to Cancel dialog's destructive button during mutation

### 8. `web/src/components/notifications/notification-popover.tsx`
- Added `role="status"`, `aria-label`, and `sr-only` span to loading state
- Added `aria-hidden="true"` on loading spinner icon

---

## Items Not Fixed (Require Design Decisions or Out of Scope)

1. **Form state does not re-sync on external user data changes** -- If user data changes in another tab, the profile form won't reflect it until the page is remounted. The `isDirty` comparison handles post-save correctly. Adding `useEffect` for sync is flagged by the strict React 19 `react-hooks/set-state-in-effect` lint rule. Acceptable trade-off.

2. **Notification optimistic updates** -- Marking a notification as read waits for query invalidation rather than optimistic UI. Non-blocking; the latency is negligible.

3. **Pagination style inconsistency** -- DataTable pagination shows "Page X of Y (N total)" while notification page shows "Page N" only. A shared pagination component would unify this. Non-blocking.

---

## Overall UX Score: 9/10

### Breakdown:
- **State Handling:** 9/10 -- Every component handles all relevant states (loading, empty, error, success, disabled)
- **Accessibility:** 9/10 -- Proper ARIA attributes, roving tabindex on radio group, error message linkage, decorative icons marked, screen reader text
- **Visual Consistency:** 9/10 -- Shared tooltip styles, theme-aware chart colors, consistent card layout, matching button patterns
- **Copy Clarity:** 10/10 -- All copy is clear, specific, and actionable. Validation messages distinguish between empty and invalid states.
- **Responsiveness:** 9/10 -- Proper responsive grids, charts auto-resize, mobile-friendly touch targets
- **Feedback & Interaction:** 9/10 -- Immediate dropdown close, loading spinners on all mutations, confirmation dialog for destructive actions, toast on every mutation

### Strengths:
- Comprehensive state handling across all four features
- Clean separation of concerns (shared EmptyState/ErrorState components)
- Theme-aware chart styling with CSS custom properties
- Proper destructive action confirmation with clear copy
- Consistent toast feedback pattern across all mutations
- Good form validation with specific, helpful error messages

### Areas for Future Improvement:
- Add optimistic updates for notification mark-as-read
- Consider adding unsaved changes warning when navigating away from a dirty profile form
- Add keyboard shortcut hints (e.g., "Enter to save" on profile form)
- Consider animated skeleton shimmer for chart loading states

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 10 -- Web Dashboard Phase 2
**Verdict:** PASS -- All critical and major UX and accessibility issues fixed. 8 component files modified with 10 usability fixes and 6 accessibility fixes.

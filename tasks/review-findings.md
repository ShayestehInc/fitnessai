# Code Review: Web Dashboard Phase 2 — Settings, Progress Charts, Notifications & Invitations

## Review Date
2026-02-15

## Files Reviewed

### New Files (8)
- `web/src/types/progress.ts`
- `web/src/hooks/use-progress.ts`
- `web/src/hooks/use-settings.ts`
- `web/src/components/settings/profile-section.tsx`
- `web/src/components/settings/appearance-section.tsx`
- `web/src/components/settings/security-section.tsx`
- `web/src/components/trainees/progress-charts.tsx`
- `web/src/components/invitations/invitation-actions.tsx`

### Modified Files (11)
- `web/src/lib/constants.ts`
- `web/src/lib/api-client.ts`
- `web/src/hooks/use-invitations.ts`
- `web/src/app/(dashboard)/settings/page.tsx`
- `web/src/components/trainees/trainee-progress-tab.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/components/notifications/notification-item.tsx`
- `web/src/components/notifications/notification-popover.tsx`
- `web/src/components/notifications/notification-bell.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/components/invitations/invitation-columns.tsx`

### Context Files Reviewed for Contract Verification
- `web/src/types/user.ts` (User type shape)
- `web/src/types/notification.ts` (Notification interface + data field)
- `web/src/types/invitation.ts` (Invitation interface + status enum)
- `web/src/providers/auth-provider.tsx` (Auth state management)
- `web/src/hooks/use-auth.ts` (Auth hook)
- `web/src/hooks/use-notifications.ts` (Existing notification hooks)
- `web/src/components/shared/empty-state.tsx` (Shared component contract)
- `web/src/components/shared/error-state.tsx` (Shared component contract)
- `web/src/providers/theme-provider.tsx` (Theme provider config)
- `backend/users/views.py` (UpdateUserProfileView, UploadProfileImageView)
- `backend/users/serializers.py` (UserSerializer fields)
- `backend/users/urls.py` (URL routing)
- `backend/config/urls.py` (Top-level URL config)
- `backend/config/settings.py` (Djoser config, serializer mapping)
- `backend/trainer/views.py` (TraineeProgressView, InvitationDetailView, ResendInvitationView)
- `backend/trainer/urls.py` (Invitation + progress URL routing)
- `backend/trainer/models.py` (TraineeActivitySummary fields)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `use-settings.ts:37,55,69` | **React Query cache update targets a key that nothing reads -- profile/image updates will never reflect in the header.** The auth system uses React Context (`useState<User>` in `AuthProvider`), NOT React Query. `queryClient.setQueryData(["current-user"], response.user)` writes to a React Query cache key that no `useQuery` reads. The user nav dropdown in the header gets `user` from `useAuth()` which reads from context state. After saving profile, uploading image, or deleting image, the header shows the OLD name/avatar until a full page reload. **AC-10 is broken.** | Three options: (A) Expose a `refreshUser` method from `AuthProvider` that re-calls `fetchUser()` to update context state, then call it from each mutation's `onSuccess`. (B) Add `queryClient.invalidateQueries` for a key that IS read (requires migrating auth to React Query). (C) Simplest fix: have each mutation's `onSuccess` refetch `/api/auth/users/me/` and update auth context directly. Recommend option A: add `refreshUser` to `AuthContext`, call it in `useUpdateProfile`, `useUploadProfileImage`, and `useDeleteProfileImage` onSuccess callbacks. |
| C2 | `profile-section.tsx:31-35` | **Form state initializes from `user` once at mount and never syncs back.** `useState(user?.first_name ?? "")` captures the value at initial render. After a successful profile update, the auth context user is stale (due to C1), so if the component re-renders or the user navigates away and back, the form shows stale data. Even after C1 is fixed, there is no `useEffect` to sync form state when `user` changes (e.g., after the auth context refreshes). The form could show "old name" even though the save succeeded and the header updated. | Add a sync effect: `useEffect(() => { if (user) { setFirstName(user.first_name); setLastName(user.last_name); setBusinessName(user.business_name ?? ""); } }, [user]);` |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `appearance-section.tsx:41` | **Hydration mismatch causes theme selector to flash.** On server render, `theme` from `useTheme()` is `undefined`. So `aria-checked={theme === value}` is `false` for all three options, and the `border-primary bg-accent` class is not applied to any button. On client hydration, the theme resolves and the correct button lights up, causing a visual flash. | Standard next-themes fix: add `const [mounted, setMounted] = useState(false); useEffect(() => setMounted(true), []);` and only apply the checked style when `mounted`: `aria-checked={mounted ? theme === value : undefined}` with the visual class gated on `mounted && theme === value`. Alternatively, show a skeleton until mounted. |
| M2 | `progress-charts.tsx:177-262` | **Adherence chart is a grouped bar chart, but AC-14 specifies "stacked bar".** The three `<Bar>` elements lack a `stackId` prop, so recharts renders them side-by-side (grouped) rather than stacked. This is a spec mismatch. With 28 days of data and 3 side-by-side bars per day, the chart becomes very dense and hard to read. Stacked bars (max height = 3) would show "how many of 3 goals were hit" per day more clearly. | Add `stackId="adherence"` to all three `<Bar>` elements. Adjust YAxis domain to `[0, 3]` and ticks to `[0, 1, 2, 3]`. Update the tooltip formatter to show the actual metric name rather than yes/no. Alternatively, if grouped is the intended design, update AC-14 to say "grouped bar chart" and document the deviation. |
| M3 | `invitation-actions.tsx:43-47` | **`navigator.clipboard.writeText` can throw synchronously in restrictive contexts.** Some browsers throw if the Clipboard API is entirely unavailable (HTTP without localhost, cross-origin iframes without `clipboard-write` permission). The `.then(success, failure)` pattern only catches promise rejections, not synchronous exceptions from the API call itself. | Wrap in try/catch: `const handleCopy = () => { try { navigator.clipboard.writeText(invitation.invitation_code).then(() => toast.success("Invitation code copied"), () => toast.error("Failed to copy code")); } catch { toast.error("Failed to copy code"); } };` |
| M4 | `progress-charts.tsx:51,127,197` | **`new Date(entry.date)` can produce Invalid Date, causing `format()` to throw.** Backend returns `str(w.date)` as `YYYY-MM-DD`. While this is reliable, any unexpected format (null, empty string, malformed data) would crash the chart rendering. This pattern appears in all three chart components. | Use `parseISO` from `date-fns` for stricter parsing, and add a defensive check: `const d = parseISO(entry.date); const label = isValid(d) ? format(d, "MMM d") : entry.date;`. Or wrap the `.map()` in a try/catch with a fallback to raw date strings. |
| M5 | `profile-section.tsx:78` | **File input reset happens before upload completes.** `e.target.value = ""` fires immediately after `uploadImage.mutate()`, which is async. If the upload fails server-side, the file input is already cleared, so the user cannot retry uploading the same file without re-selecting it from the file picker. | Move `e.target.value = ""` into the `onSuccess` callback of `uploadImage.mutate`, or add it to both `onSuccess` and `onError`. Current behavior is not catastrophic but is a minor UX regression. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `security-section.tsx:89` | **`confirmPassword` missing from `handleSubmit` useCallback dependency array.** The `useCallback` lists `[currentPassword, newPassword, validate, changePassword]` but not `confirmPassword`. Since `validate` closure captures `confirmPassword`, the behavior is correct, but ESLint exhaustive-deps would flag this. | Add `confirmPassword` to the dependency array. |
| m2 | `security-section.tsx:108,127,148` | **Error clearing on keystroke sets empty string instead of removing key.** `setErrors((prev) => ({ ...prev, current_password: "" }))` leaves a key with value `""`. Works because `""` is falsy, but the errors object accumulates empty keys. | Use destructuring to remove the key: `setErrors(({ current_password: _, ...rest }) => rest);` |
| m3 | `use-progress.ts:13` | **No `staleTime` on progress query.** Progress data changes infrequently, but without `staleTime`, React Query refetches on every mount and window focus. For a trainer viewing multiple trainees, this causes unnecessary API calls. | Add `staleTime: 5 * 60 * 1000` (5 minutes) to reduce unnecessary refetches. |
| m4 | `notification-popover.tsx:24` | **Magic number `5` for popover notification limit.** `.slice(0, 5)` is a hardcoded constant with no explanation. | Extract to a named constant: `const POPOVER_MAX_ITEMS = 5;` |
| m5 | `progress-charts.tsx:76` | **YAxis `domain` uses string math `"dataMin - 2"`.** While recharts supports this syntax, it's an undocumented-feeling API that could break across versions. | Calculate domain explicitly: `const min = Math.min(...data.map(d => d.weight_kg)); domain={[Math.floor(min) - 2, Math.ceil(max) + 2]}`. |
| m6 | `invitation-actions.tsx:36-38` | **Client-side status derivation duplicates backend logic.** `is_expired && status === "PENDING"` maps to `"EXPIRED"` on the client. If the backend ever returns `status: "EXPIRED"` directly, this logic would conflict. | Add a comment explaining why this derivation exists: `// Backend keeps status=PENDING even after expiration; is_expired flag distinguishes`. |
| m7 | `settings/page.tsx:46` | **Error retry uses `window.location.reload()`.** This is a full page reload, heavier than a targeted refetch. Other error states use React Query's `refetch()`. | Acceptable given auth uses context not React Query. Once C1 is resolved (if auth migrates), revisit. |
| m8 | `notification-bell.tsx:30` | **`NotificationPopover` may render and fire queries even when popover is closed.** Radix Popover may or may not lazy-mount `PopoverContent`. If it doesn't, `useNotifications()` inside the popover fires on every render of the bell. | Conditionally render: `{open && <NotificationPopover onClose={() => setOpen(false)} />}`. This guarantees no wasted API calls when the popover is closed. |
| m9 | `use-settings.ts:11` | **`business_name` typed as `string` in payload but `User.business_name` is `string | null`.** Sending `""` when user has `null` business_name stores empty string instead of null in the database. | Minor data integrity issue. Either type as `string | null` and handle null in the form, or accept `""` as equivalent to null. Add a comment. |

---

## Security Concerns

**No security issues found in the new code.** Specifically verified:

1. **No XSS risk.** All user content rendered via JSX auto-escaping. No `dangerouslySetInnerHTML`.
2. **Clipboard API usage is benign** -- only writes the invitation code, not sensitive data.
3. **Password fields** use `type="password"`, `autoComplete="current-password"` / `"new-password"`. Password values are never logged or stored in state beyond the component lifecycle.
4. **File upload validation** is defense-in-depth: client validates type + size before upload; server re-validates both. The `accept` attribute on the file input provides a first UX filter.
5. **No IDOR risk.** All API calls use authenticated endpoints. Row-level security is enforced on the backend (verified: `TraineeProgressView` checks `parent_trainer`, `InvitationDetailView` filters by `trainer`, `ResendInvitationView` filters by `trainer`).
6. **Profile image URL from backend** is rendered via `<img>` tag (AvatarImage), limiting exploit surface to image rendering.
7. **Djoser `set_password` endpoint** requires `current_password`, preventing unauthorized password changes even if the session is hijacked.

---

## Performance Concerns

1. **Progress chart data mapping** creates new arrays on every render (3 `.map()` calls). For typical data sizes (< 30 weight entries, < 28 volume/adherence entries), this is negligible. If data grows, consider `useMemo`.
2. **No `staleTime` on progress query** (m3) means unnecessary refetches when switching tabs on the trainee detail page.
3. **Notification popover may fire queries when closed** (m8) -- depends on Radix Popover mounting behavior.
4. **Backend progress endpoint** uses `Avg('total_volume')` with `values('date').annotate()` -- this is a single aggregation query, not N+1. Efficient.
5. **FormData upload** correctly skips `Content-Type: application/json` header, letting the browser set `multipart/form-data` boundary. Verified in `buildHeaders()`.

No critical performance issues.

---

## Acceptance Criteria Verification

### Settings Page (AC-1 through AC-10)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-1 | Three sections: Profile, Appearance, Security | PASS | `settings/page.tsx:55-57` renders `ProfileSection`, `AppearanceSection`, `SecuritySection` |
| AC-2 | Profile editable fields + save + toast | PASS | `profile-section.tsx:37-48` calls PATCH, shows toast. Fields: first_name, last_name, business_name |
| AC-3 | Email read-only | PASS | `profile-section.tsx:189-199` disabled Input with `bg-muted` class |
| AC-4 | Profile image upload/remove | PASS | `profile-section.tsx:107-151` upload button + remove button. POST/DELETE endpoints correct |
| AC-5 | Theme toggle (Light/Dark/System) | PASS | `appearance-section.tsx:14-57` uses `useTheme()`, immediate, persists via next-themes localStorage |
| AC-6 | Password change form | PASS | `security-section.tsx:99-168` has 3 fields, calls Djoser endpoint, parses errors inline |
| AC-7 | Validation: maxLength, min 8 chars, confirm match | PASS | maxLength on inputs (150/200/128), validate() checks length >= 8 and match |
| AC-8 | Loading skeleton | PASS | `settings/page.tsx:11-26` SettingsSkeleton with 3 card placeholders |
| AC-9 | Error state with retry | PASS | `settings/page.tsx:40-49` ErrorState with window.location.reload() |
| AC-10 | Header reflects updated name immediately | **FAIL** | C1: `setQueryData(["current-user"])` writes to unread cache. Auth context not updated. |

### Progress Charts (AC-11 through AC-17)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-11 | Fetches progress, shows 3 charts | PASS | `trainee-progress-tab.tsx:27,44-46` fetches and renders WeightChart, VolumeChart, AdherenceChart |
| AC-12 | Weight trend line chart + empty state | PASS | `progress-charts.tsx:31-101` LineChart with date/weight axes, "No weight data" empty state |
| AC-13 | Volume bar chart + empty state | PASS | `progress-charts.tsx:107-171` BarChart with "No workout data" empty state |
| AC-14 | Adherence stacked bar with legend | **PARTIAL** | M2: Chart is grouped (no `stackId`), not stacked. Legend IS present with 3 colors. |
| AC-15 | Charts responsive | PASS | All charts use `ResponsiveContainer width="100%" height="100%"` |
| AC-16 | Loading skeleton | PASS | `trainee-progress-tab.tsx:12-24` ProgressSkeleton with 3 chart placeholders |
| AC-17 | Error state with retry | PASS | `trainee-progress-tab.tsx:33-39` ErrorState with refetch |

### Notification Click-Through (AC-18 through AC-21)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-18 | Click with trainee_id navigates | PASS | `notification-popover.tsx:29-32` and `notifications/page.tsx:48-51` use getNotificationTraineeId + router.push |
| AC-19 | Click without trainee_id only marks read | PASS | getNotificationTraineeId returns null, no navigation occurs |
| AC-20 | Works in both popover and full page | PASS | Both components implement the same pattern |
| AC-21 | Backend includes trainee_id in data | NOT VERIFIED | Dev-done.md claims backend already sends it. No backend changes made. Need to verify `survey_views.py` and `trainer/views.py` send `data={'trainee_id': ...}` for relevant notification types. |

### Invitation Row Actions (AC-22 through AC-28)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-22 | "..." dropdown menu per row | PASS | `invitation-columns.tsx:51-56` adds actions column with `InvitationActions` |
| AC-23 | PENDING: Copy, Resend, Cancel | PASS | `invitation-actions.tsx:40-41` canResend=true, canCancel=true for PENDING |
| AC-24 | EXPIRED: Copy, Resend | PASS | canResend=true, canCancel=false for EXPIRED |
| AC-25 | ACCEPTED/CANCELLED: Copy only | PASS | Both canResend=false, canCancel=false |
| AC-26 | Copy Code copies to clipboard + toast | PASS | `invitation-actions.tsx:43-47` |
| AC-27 | Resend calls POST + toast + refresh | PASS | `invitation-actions.tsx:50-54` + `use-invitations.ts:30-39` invalidates query |
| AC-28 | Cancel: confirmation dialog + DELETE + toast + refresh | PASS | `invitation-actions.tsx:57-65,106-132` + `use-invitations.ts:42-51` |

### Summary: 24/28 ACs PASS, 1 FAIL (AC-10), 1 PARTIAL (AC-14), 1 NOT VERIFIED (AC-21), 1 unrelated to new code.

---

## Edge Cases Verification

| # | Edge Case | Handled? | Notes |
|---|-----------|----------|-------|
| 1 | Profile save with no changes | YES | PATCH is idempotent; save button always enabled |
| 2 | Upload >5MB image | YES | Client check at profile-section.tsx:56 |
| 3 | Upload non-image file | YES | Client check at profile-section.tsx:61-68 + `accept` attr |
| 4 | Wrong current password | YES | Djoser error parsed inline at security-section.tsx:67-68 |
| 5 | Common/weak password | YES | Djoser validation at security-section.tsx:70-71 |
| 6 | Profile update network failure | YES | onError toast, form state preserved |
| 7 | Zero weight check-ins | YES | WeightChart empty state |
| 8 | Zero workouts | YES | VolumeChart empty state |
| 9 | Zero activity summaries | YES | AdherenceChart empty state |
| 10 | All three charts empty | YES | Each shows individual empty state |
| 11 | Notification data is empty `{}` | YES | getNotificationTraineeId returns null |
| 12 | trainee_id points to removed trainee | YES | Navigation proceeds; trainee detail handles 404 |
| 13 | Resend cancelled invitation | YES | Backend returns 400; onError toast |
| 14 | Cancel last invitation | YES | Query invalidation; table shows empty state |
| 15 | Double-click resend/cancel | PARTIAL | Resend button disabled via isPending, cancel dialog button disabled. But dropdown can be re-opened for a second resend click before first resolves. |

---

## Quality Score: 6/10

### Breakdown
- **Functionality: 6/10** -- C1 breaks a core AC (header update after save). M2 deviates from spec (grouped vs stacked).
- **Code Quality: 8/10** -- Clean decomposition, proper TypeScript types, good component structure, consistent patterns.
- **Security: 9/10** -- No issues found. Defense-in-depth on file uploads. Proper password field handling.
- **Performance: 8/10** -- Reasonable for scope. Minor optimization opportunities (staleTime, useMemo).
- **Edge Cases: 8/10** -- Nearly all handled. Double-click partially addressed.
- **Architecture: 5/10** -- C1 is a fundamental disconnect between React Context (auth) and React Query (mutations). The mutations update a cache that nothing reads. This is an architectural mismatch that needs resolution.

### What Keeps It at 6
- **C1 is a show-stopper for AC-10.** The user saves their profile, sees a success toast, but their name in the header doesn't change. This erodes trust in the save action.
- **M2 is a spec deviation.** The adherence chart looks different from what was specified.
- **M1 causes a visual flash** on the theme selector on every page load.

### Positives
- All API endpoint URLs match the backend routing.
- API response shapes match backend serializer output (verified against `UserSerializer`, `TraineeProgressView`, `TraineeInvitationSerializer`).
- Comprehensive loading, empty, and error states for every feature.
- Good accessibility: ARIA labels, roles, keyboard-navigable elements.
- Shared `getNotificationTraineeId` helper avoids code duplication between popover and full page.
- Invitation action visibility is correctly context-sensitive per status.
- File upload has both client-side and server-side validation.
- Controlled popover pattern for notification bell enables programmatic close on navigation.

---

## Recommendation: REQUEST CHANGES

### Must fix before approve:
1. **C1** -- Fix the React Query / Auth Context disconnect so profile updates reflect in the header nav immediately (AC-10)
2. **C2** -- Add useEffect to sync form state when user data changes in context
3. **M1** -- Fix hydration mismatch in AppearanceSection theme selector (standard next-themes mounted pattern)
4. **M2** -- Either add `stackId` to adherence chart bars (matching AC-14 spec) or explicitly document the grouped chart as an intentional deviation

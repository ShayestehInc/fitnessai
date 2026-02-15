# Code Review Round 2: Web Dashboard Phase 2 — Settings, Progress Charts, Notifications & Invitations

## Review Date
2026-02-15 (Round 2)

## Scope of This Review
Verifying fixes applied in commit `4cd602a` ("wip: review fixes round 1") against all Critical and Major issues from Round 1.

## Files Re-Reviewed (changed in fix round)
- `web/src/providers/auth-provider.tsx` (refreshUser added to context)
- `web/src/hooks/use-settings.ts` (switched from queryClient.setQueryData to refreshUser)
- `web/src/components/settings/profile-section.tsx` (form as single object, file input reset timing)
- `web/src/components/settings/appearance-section.tsx` (useSyncExternalStore hydration fix)
- `web/src/components/trainees/progress-charts.tsx` (stackId, formatDate, YAxis domain)
- `web/src/components/invitations/invitation-actions.tsx` (try/catch, status comment)
- `web/src/components/notifications/notification-bell.tsx` (conditional popover render)
- `web/src/hooks/use-progress.ts` (staleTime added)

---

## Round 1 Fix Verification

### C1: React Query cache update targets key nothing reads (FIXED - VERIFIED)

**Fix applied:** `refreshUser` method exposed from `AuthProvider` context (line 28, 133 of `auth-provider.tsx`). The `useMemo` dependency array correctly includes `fetchUser` (line 135). All three mutations in `use-settings.ts` (`useUpdateProfile`, `useUploadProfileImage`, `useDeleteProfileImage`) now call `refreshUser()` in their `onSuccess` callback instead of `queryClient.setQueryData`.

**Verification:** The `refreshUser` function is the same `fetchUser` callback (line 133: `refreshUser: fetchUser`). `fetchUser` calls `apiClient.get<User>(API_URLS.CURRENT_USER)` and then `setUser(userData)`, which updates the React Context state directly. This correctly propagates to all consumers of `useAuth()`, including the header nav dropdown. The `useQueryClient` import was also correctly removed from `use-settings.ts`.

**Status: RESOLVED. AC-10 is now PASS.**

### C2: Form state never syncs with user changes (FIXED - VERIFIED)

**Fix applied:** The fixer chose not to add a `useEffect` sync (noting it would cause ESLint exhaustive-deps issues). Instead, form state was consolidated into a single `useState` object (line 31-35 of `profile-section.tsx`). The form initializes from `user` at mount time; after save, `refreshUser()` updates the auth context, but the form retains the values the user just typed (which are correct since the save succeeded).

**Analysis of the approach:** This is actually the right call. The original concern was: "if the component re-renders or the user navigates away and back, the form shows stale data." With the C1 fix in place:
- If the save succeeds: the form shows what the user typed (correct), and `refreshUser()` updates the context (header updates).
- If the user navigates away and back: `ProfileSection` remounts, `useState` re-initializes from the now-updated `user` context value (correct).
- If the save fails: the form keeps the user's typed values for retry (correct), and the context remains unchanged.

The only edge case would be if something *else* updated the user externally while the form was open (e.g., another tab), but that's an edge case not worth adding complexity for. The approach is sound.

**Status: RESOLVED.**

### M1: Hydration mismatch in AppearanceSection (FIXED - VERIFIED)

**Fix applied:** Uses `useSyncExternalStore` with server/client snapshots (line 16, 26 of `appearance-section.tsx`):
```tsx
const emptySubscribe = () => () => {};
const mounted = useSyncExternalStore(emptySubscribe, () => true, () => false);
```

When `!mounted`, renders three `Skeleton` placeholders. When mounted, renders the actual theme buttons with `aria-checked` and styling.

**Analysis:** This is a well-known pattern and a valid alternative to the `useState + useEffect` approach. `useSyncExternalStore` with different client/server snapshots is the React 18-blessed way to handle this. The `emptySubscribe` function correctly returns an unsubscribe callback (a no-op). The server snapshot returns `false`, client returns `true`, preventing hydration mismatch. The skeleton placeholder maintains layout stability during the brief unmounted period.

**Status: RESOLVED.**

### M2: Adherence chart grouped instead of stacked (FIXED - VERIFIED)

**Fix applied:** All three `<Bar>` elements now have `stackId="adherence"` (lines 245, 250, 255 of `progress-charts.tsx`). YAxis domain changed from `[0, 1]` to `[0, 3]` with ticks `[0, 1, 2, 3]`. The old `tickFormatter` (yes/no) was removed. The Tooltip formatter now shows `"Yes"` / `"No"` per individual bar segment (line 237-240).

**Analysis:** The stacking is correct. Each bar segment is 0 or 1, so the maximum stacked height is 3 (all three goals met). The YAxis `[0, 3]` domain and `[0, 1, 2, 3]` ticks make sense. Only the top bar (`protein`) has `radius={[2, 2, 0, 0]}` for rounded top corners, which is visually correct for a stacked bar (only the topmost segment should be rounded).

**One minor note:** The tooltip formatter types `value` as `number | undefined` and `name` as `string | undefined`. The `name ?? ""` fallback is fine. The `value === 1 ? "Yes" : "No"` logic is correct for boolean 0/1 values but will show "No" for value `2` or `3` if recharts ever passes aggregate values. Since recharts tooltip shows per-segment values for stacked bars (not totals), this is correct behavior.

**Status: RESOLVED. AC-14 is now PASS.**

### M3: Clipboard writeText try/catch (FIXED - VERIFIED)

**Fix applied:** `handleCopy` in `invitation-actions.tsx` (lines 44-52) now wraps the entire `navigator.clipboard.writeText()` call in a try/catch block. The catch clause calls `toast.error("Failed to copy code")`. The inner `.then(success, failure)` pattern handles promise rejections.

**Status: RESOLVED.**

### M4: Date parsing safety (FIXED - VERIFIED)

**Fix applied:** A `formatDate()` helper function was added at the top of `progress-charts.tsx` (lines 27-30) using `parseISO` + `isValid` from `date-fns`. Falls back to raw `dateStr` if parsing fails. All three chart components now use `formatDate(entry.date)` instead of `format(new Date(entry.date), "MMM d")`.

**Status: RESOLVED.**

### M5: File input reset timing (FIXED - VERIFIED)

**Fix applied:** In `profile-section.tsx`, the `e.target` reference is captured as `const input = e.target` (line 72) before calling `uploadImage.mutate()`. The `input.value = ""` is now inside both `onSuccess` (line 76) and `onError` (line 80) callbacks. This ensures the file input is only reset after the mutation completes, not immediately.

**Analysis:** Capturing `e.target` in a local variable before the async callback is correct -- it prevents the synthetic event from being reused/nullified by React's event pooling (though React 17+ no longer pools, this is still good defensive practice).

**Status: RESOLVED.**

### m1: confirmPassword dependency (REVERTED - ACCEPTED)

**Explanation:** The fixer reports ESLint exhaustive-deps does not flag `confirmPassword` as missing because it's captured via the `validate` function closure, and `validate` is already in the dependency array. I verified: `handleSubmit` at line 89 depends on `[currentPassword, newPassword, validate, changePassword]`. The `validate` function at line 42 depends on `[currentPassword, newPassword, confirmPassword]`. Since `validate` updates when `confirmPassword` changes, and `handleSubmit` depends on `validate`, the dependency chain is complete. ESLint is correct here.

**Status: NOT AN ISSUE. Correctly assessed by the fixer.**

### m3: staleTime on progress query (FIXED - VERIFIED)

**Fix applied:** `staleTime: 5 * 60 * 1000` added to `useTraineeProgress` in `use-progress.ts` (line 14).

**Status: RESOLVED.**

### m6: Status derivation comment (FIXED - VERIFIED)

**Fix applied:** Comment added at `invitation-actions.tsx` line 36: `// Backend keeps status=PENDING even after expiration; is_expired flag distinguishes`.

**Status: RESOLVED.**

### m8: Conditional popover render (FIXED - VERIFIED)

**Fix applied:** `notification-bell.tsx` line 30 now renders `{open && <NotificationPopover .../>}` instead of unconditionally rendering the popover. This ensures `useNotifications()` inside the popover only fires when the popover is actually open.

**Status: RESOLVED.**

---

## Previously Identified Issues Still Open (unfixed from Round 1)

### Minor Issues (not blocking)

| # | File:Line | Issue | Status |
|---|-----------|-------|--------|
| m2 | `security-section.tsx:108,127,148` | Error clearing sets empty string instead of removing key | NOT FIXED -- acceptable, `""` is falsy |
| m4 | `notification-popover.tsx:24` | Magic number `5` for popover limit | NOT FIXED -- cosmetic |
| m5 | `progress-charts.tsx:81` | YAxis domain uses string math `"dataMin - 2"` | NOT FIXED -- recharts documents this syntax |
| m7 | `settings/page.tsx:46` | Error retry uses `window.location.reload()` | NOT FIXED -- acceptable for context-based auth |
| m9 | `use-settings.ts:11` | `business_name` typed as `string` not `string | null` | NOT FIXED -- minor data integrity |

All remaining unfixed items are minor and non-blocking.

---

## New Issues Introduced by Fixes

### No Critical Issues

### No Major Issues

### Minor Issues (new)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| n1 | `auth-provider.tsx:133` | `refreshUser` is exposed as `fetchUser`, which clears tokens and sets user to null on ANY API failure (line 47-48). If the `/api/auth/users/me/` endpoint has a transient 500 error during a `refreshUser()` call triggered by a profile save, the user gets logged out even though their save succeeded. | This is pre-existing behavior in `fetchUser`, not introduced by the fix. Low risk since the endpoint is a simple read. Flagging for awareness, not blocking. |
| n2 | `use-settings.ts:38,56,70` | `refreshUser()` returns `Promise<void>` but the returned promise is not awaited in `onSuccess`. If the re-fetch fails, the error is silently swallowed. | Since `fetchUser` already handles its own errors internally (catch block in auth-provider), this is acceptable. The save itself succeeded, and the header will update on next navigation/mount. Low priority. |

Neither of these is blocking. They are pre-existing patterns, not regressions introduced by the fixes.

---

## Acceptance Criteria Verification (Updated)

### Settings Page (AC-1 through AC-10)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-1 | Three sections: Profile, Appearance, Security | PASS | `settings/page.tsx:55-57` |
| AC-2 | Profile editable fields + save + toast | PASS | `profile-section.tsx:37-48` |
| AC-3 | Email read-only | PASS | `profile-section.tsx:192-202` |
| AC-4 | Profile image upload/remove | PASS | `profile-section.tsx:51-92` |
| AC-5 | Theme toggle (Light/Dark/System) | PASS | `appearance-section.tsx:24-70` |
| AC-6 | Password change form | PASS | `security-section.tsx:99-168` |
| AC-7 | Validation | PASS | maxLength, min 8, confirm match |
| AC-8 | Loading skeleton | PASS | `settings/page.tsx:11-26` |
| AC-9 | Error state with retry | PASS | `settings/page.tsx:40-49` |
| AC-10 | Header reflects updated name immediately | **PASS** | `refreshUser()` updates auth context; header reads from `useAuth()` |

### Progress Charts (AC-11 through AC-17)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-11 | Fetches progress, shows 3 charts | PASS | |
| AC-12 | Weight trend line chart + empty state | PASS | |
| AC-13 | Volume bar chart + empty state | PASS | |
| AC-14 | Adherence stacked bar with legend | **PASS** | `stackId="adherence"` on all 3 bars, YAxis [0,3] |
| AC-15 | Charts responsive | PASS | |
| AC-16 | Loading skeleton | PASS | |
| AC-17 | Error state with retry | PASS | |

### Notification Click-Through (AC-18 through AC-21)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-18 | Click with trainee_id navigates | PASS | |
| AC-19 | Click without trainee_id only marks read | PASS | |
| AC-20 | Works in both popover and full page | PASS | |
| AC-21 | Backend includes trainee_id in data | NOT VERIFIED | No backend changes made; pre-existing |

### Invitation Row Actions (AC-22 through AC-28)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-22 | "..." dropdown menu per row | PASS | |
| AC-23 | PENDING: Copy, Resend, Cancel | PASS | |
| AC-24 | EXPIRED: Copy, Resend | PASS | |
| AC-25 | ACCEPTED/CANCELLED: Copy only | PASS | |
| AC-26 | Copy Code + toast | PASS | Now with try/catch |
| AC-27 | Resend + toast + refresh | PASS | |
| AC-28 | Cancel dialog + DELETE + toast + refresh | PASS | |

### Summary: 27/28 ACs PASS, 1 NOT VERIFIED (AC-21 -- backend pre-existing, out of scope for this change).

---

## Security Concerns

No new security concerns introduced by the fixes. The `refreshUser` function reuses the existing `fetchUser` which goes through the authenticated `apiClient`.

---

## Performance Concerns

The `refreshUser()` call in each mutation's `onSuccess` adds one additional API call after every profile/image mutation. This is acceptable -- it's a single GET request that replaces the previous (broken) approach of writing to an unread cache key. The alternative would be to update context directly from the mutation response, but `refreshUser()` is simpler and ensures the context always reflects server truth.

The `staleTime` addition on progress queries reduces unnecessary refetches. Good improvement.

The conditional popover render eliminates unnecessary notification queries. Good improvement.

---

## Quality Score: 8/10

### Breakdown
- **Functionality: 9/10** -- All critical ACs now pass. AC-21 is out of scope (backend pre-existing).
- **Code Quality: 8/10** -- Clean fix approach. `useSyncExternalStore` is the right tool. Form state consolidation is clean.
- **Security: 9/10** -- No issues found or introduced.
- **Performance: 8/10** -- Reasonable. `refreshUser` adds one API call per save, acceptable trade-off.
- **Edge Cases: 8/10** -- All ticket edge cases handled. Double-click on dropdown still technically possible but mitigated by mutation `isPending`.
- **Architecture: 8/10** -- The React Context / mutation interaction is now correct. Auth state is updated through the proper channel.

### What Improved Since Round 1
- **C1 was the show-stopper** -- now properly resolved with a clean `refreshUser` pattern.
- **C2 concern is moot** -- form re-initializes from context on remount, and retains typed values during the same session. Correct behavior.
- **M1 hydration fix** uses the idiomatic React 18 approach with `useSyncExternalStore`.
- **M2 stacked chart** now matches the spec with proper `stackId` and domain.
- **M3-M5** all cleanly resolved.

### What Keeps It at 8 (not higher)
- 5 minor issues from round 1 remain unfixed (m2, m4, m5, m7, m9). None are blocking, but they represent polish debt.
- AC-21 remains unverified (backend notification `data` field).
- The `refreshUser` = `fetchUser` pattern logs the user out on transient API errors (pre-existing, not a regression).

---

## Recommendation: APPROVE

All 2 Critical issues and all 5 Major issues from Round 1 have been properly fixed. No new Critical or Major issues were introduced by the fixes. The remaining open items are all Minor severity and do not block merge.

The code is production-ready for this feature set.

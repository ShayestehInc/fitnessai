# Hacker Report: Pipeline 10 - Web Dashboard Phase 2 (Settings, Progress, Notifications, Invitations)

## Date: 2026-02-15

## Focus Areas
Settings page (profile/appearance/security), progress charts (weight/volume/adherence), notification click-through navigation, invitation row actions (copy/resend/cancel)

---

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | NotificationPopover | Non-navigable notification click | User gets feedback when clicking | Clicking a notification without `trainee_id` marks as read silently -- no visual feedback, popover stays open. **FIXED**: Added toast "Marked as read" for non-navigable unread notifications. |
| 2 | Medium | NotificationsPage | Non-navigable notification click | User gets feedback | Same issue on full notifications page -- click marks as read but no visible confirmation. **FIXED**: Added matching toast feedback. |
| 3 | Low | ProfileSection | Save button always clickable | Disabled when nothing changed | Save button was always enabled even with pristine form, wasting API calls and confusing users. **FIXED**: Added `isDirty` check comparing trimmed form values to user data. Button disabled when form matches server state. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | SettingsPage | Loading skeleton and error state used full-width container while success state used `max-w-2xl`, causing content width to jump on load | **FIXED**: Applied `max-w-2xl` consistently to loading, error, and success wrapper divs. |
| 2 | Low | progress-charts.tsx (AdherenceChart) | Bar fill colors used hardcoded HSL values (`hsl(142, 76%, 36%)`, etc.) instead of the defined `CHART_COLORS` constant that uses theme-aware CSS variables | **FIXED**: Bars now use `CHART_COLORS.food`, `CHART_COLORS.workout`, `CHART_COLORS.protein` which reference `--chart-N` CSS custom properties, ensuring proper dark mode support. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | ProfileSection file input ref | Previous pipeline's linter auto-fix converted `useRef<HTMLInputElement>` to a callback ref pattern with `fileInputNodeRef` module variable, but the `onClick` handler still called `fileInputRef.current?.click()` which doesn't work on a callback function | Upload button triggers file picker | Upload button silently failed -- `.current` property doesn't exist on callback refs. **FIXED**: Reverted to proper `useRef<HTMLInputElement>(null)` which is accessed only in event handlers (not during render), satisfying React 19 ESLint rules. |
| 2 | Medium | ProfileSection form state sync | After saving profile, form should reflect latest server data so `isDirty` resets to false | Save button disables after successful save | Initial ref-during-render sync pattern violated React 19 ESLint `react-hooks/refs` rule. `useEffect` + `setState` pattern violated `react-hooks/set-state-in-effect` rule. **FIXED**: Removed both patterns. The `isDirty` comparison against `user` prop naturally evaluates to `false` after save because `refreshUser()` fetches data matching what was just submitted. No explicit sync needed. |
| 3 | Low | ProfileSection form trimming | Type "  John  " in first name, save | Spaces trimmed before sending to API | Values were sent as-is with leading/trailing whitespace. **FIXED**: Added `.trim()` on all form values in `handleSave` and in `isDirty` comparison. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | NotificationItem | Add stronger visual distinction between navigable and non-navigable notifications | Non-navigable notifications have hover/click affordances identical to navigable ones (minus the chevron). Users click expecting navigation and get only a "Marked as read" toast. Consider cursor differences or adding subtle "(info only)" text for non-navigable items. |
| 2 | Medium | InvitationActions | For ACCEPTED invitations, "Copy Code" is nearly useless | An accepted invitation code has already been used. Consider hiding the actions menu entirely for accepted/cancelled invitations, or adding a "View trainee" action for accepted ones that links to the onboarded trainee. |
| 3 | Medium | Progress charts | Add period selector (7d/14d/30d/all) like the Activity tab | Weight chart shows "last 30 check-ins" and volume/adherence show "last 4 weeks" with no way to change. Users wanting longer-term trend visibility have no option. Backend `days` parameter could support this easily. |
| 4 | Medium | SecuritySection | Add password strength indicator | The mobile app has a visual password strength indicator for change-password but the web version doesn't. Would improve parity and user guidance. |
| 5 | Low | SettingsPage | Add notification preferences section | `tasks/focus.md` specifically mentions notification preferences as part of Settings, but only profile/appearance/security were implemented. Backend would need a preferences model/endpoint. |
| 6 | Low | ProfileSection | Add unsaved changes warning on route navigation | If a user edits the form fields then clicks a sidebar link, changes are silently lost. Consider `window.onbeforeunload` or Next.js router event interception. |
| 7 | Low | VolumeChart Y-axis | Add unit label to volume Y-axis | The Y-axis shows raw numbers with no unit. Volume is "weight x reps in kg" which isn't self-evident. |
| 8 | Low | Invitations | Add status filter and search | As invitation count grows, trainers need to filter by status (pending/accepted/expired/cancelled) or search by email. The table currently has no filtering capability. |

## Cannot Fix (Need Design/Backend Changes)
| # | Area | Issue | Suggested Approach |
|---|------|-------|-------------------|
| 1 | Notifications | No way to delete individual notifications from the full page | Backend has `DELETE /api/trainer/notifications/<id>/`. Add a delete button or swipe gesture per notification on the full page. |
| 2 | Progress charts | Backend volume query uses `Avg('total_volume')` instead of `Sum` | For days with multiple `TraineeActivitySummary` entries, `Avg` may not represent what the trainer expects. Likely needs backend discussion on the intended aggregation semantics. |
| 3 | Settings | Email change not supported | The email field is disabled with "Email cannot be changed" hint. This is a known limitation but should be documented in a future roadmap ticket. |

---

## Summary
- Dead UI elements found: 3
- Visual bugs found: 2
- Logic bugs found: 3
- Improvements suggested: 8
- Cannot-fix items documented: 3
- Items fixed by hacker: 6

## Chaos Score: 7/10

### Rationale
The Phase 2 implementation is solid overall. Settings page with profile editing, theme toggle, and password change works well. Progress charts render correctly with proper empty states, themed colors, and accessible tooltips. Notification click-through navigation works for trainee-linked notifications. Invitation row actions (copy/resend/cancel) with confirmation dialog are well-implemented.

**Good:**
- Settings page sections are well-separated with Card components and proper form validation
- Appearance section uses proper `radiogroup` ARIA pattern with roving tabIndex and arrow key navigation
- Security section has comprehensive error handling -- inline field errors from Djoser API and fallback toast
- Progress charts have proper loading skeletons, error retry, and empty states for each chart type
- Invitation actions properly handle status-based visibility (resend for PENDING/EXPIRED, cancel for PENDING only)
- Cancel invitation uses a confirmation dialog to prevent accidental cancellation
- Notification click-through correctly parses `trainee_id` from notification data, handles both number and string types

**Concerns:**
- The React 19 ESLint rules (`react-hooks/refs`, `react-hooks/set-state-in-effect`) are extremely strict and caused the linter to mangle valid patterns. The ref-during-render auto-fix broke the file input completely. Teams should be cautious about auto-fixing these rules.
- Non-navigable notifications need better UX distinction from navigable ones
- No notification preferences despite being in the focus
- Invitation table lacks search/filter for larger trainer accounts
- Progress charts have no date range selector

**Risk Assessment:**
- **Critical**: File input ref was broken by linter auto-fix. Fixed.
- **Low Risk**: All other issues are UX improvements, not data loss or security concerns.
- **Low Risk**: Form dirty tracking ensures no accidental empty saves, trim prevents whitespace-only submissions.

# Hacker Report: Trainer Notifications Dashboard + Ambassador Commission Webhook

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | TrainerNotificationsScreen | Tap notification with no traineeId | Shows "Trainee no longer available" snackbar per ticket edge case #3 | **Was**: silently did nothing when traineeId was null. **Fixed**: snackbar "Trainee no longer available" now shown. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | NotificationCard | Future timestamps from server clock skew would produce negative duration in `_formatRelativeTime`, resulting in confusing output like "-2m ago" or "0m ago" | **Fixed**: Added `diff.isNegative` guard before checking `diff.inMinutes < 1`. Now shows "Just now" for any future timestamp. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Medium | Notification pagination error handling | 1. Open notifications screen 2. Scroll to bottom to trigger loadMore 3. Network fails during page fetch | Error is logged; page counter rolls back | **Was**: `catch (_)` silently swallowed the error with zero logging, violating project error-handling rule ("NO exception silencing"). Page counter correctly rolled back but nobody knew why it failed. **Fixed**: Replaced bare `catch (_)` with `catch (error, stackTrace)` that calls `developer.log()` with full error details and stack trace. |
| 2 | Medium | Error state pull-to-refresh | 1. Open notifications screen 2. Network fails on initial load 3. Error state appears 4. Try to pull-to-refresh | User can pull-to-refresh to retry without tapping button | **Was**: Error state was a static `Center` widget -- not scrollable, so pull-to-refresh gesture was impossible. User had to tap the "Retry" button. **Fixed**: Wrapped error state in `RefreshIndicator` + `LayoutBuilder` + `SingleChildScrollView` + `AlwaysScrollableScrollPhysics`, matching the same pattern already used for the empty state. |
| 3 | Low | Notification data JSON parsing | API returns `data: "malformed"` or `data: [1,2,3]` instead of expected Map | Model falls back to empty `{}` | **Was**: `(json['data'] as Map<String, dynamic>?) ?? {}` uses an unsafe cast -- if `data` is a List or String, `as Map<String, dynamic>?` throws a TypeError, crashing the entire notification list. **Fixed**: Changed to a safe `is Map<String, dynamic>` type check with fallback to `{}`. |
| 4 | Low | Trainer Dashboard | 1. View program detail 2. Schedule template has unparseable JSON | Error handled gracefully | **Was**: Used `debugPrint()` in production code (same pattern as BUG-4 which was fixed previously -- all debug prints should be removed). **Fixed**: Replaced `debugPrint()` with a clarifying comment. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Notifications | Add periodic badge polling (e.g. every 60s) while trainer is on dashboard screen | The badge count only refreshes when the notifications provider is invalidated (screen focus, pull-to-refresh). Trainers who leave the dashboard open for extended periods won't see new notification counts. A simple `Timer.periodic` in the dashboard screen's `initState` that calls `ref.invalidate(unreadNotificationCountProvider)` every 60 seconds would keep the badge fresh. |
| 2 | High | Notifications | Add haptic feedback on swipe-to-dismiss | The Dismissible swipe gesture feels dead without tactile feedback. Adding `HapticFeedback.lightImpact()` in the `confirmDismiss` callback would match native iOS/Android notification drawer UX. |
| 3 | Medium | Notifications | Add notification type filter chips | Trainers with many trainees will get flooded with mixed notification types. A horizontal filter chip bar (All / Workouts / Readiness / Check-ins) at the top of the notifications screen would let them focus on what matters. The backend already supports query parameter filtering -- just add `?notification_type=workout_completed` support to the queryset. |
| 4 | Medium | Notifications | Batch delete via long-press multi-select | Currently only one-at-a-time delete via swipe. Power users managing 20+ trainees need to clear old notifications faster. Add long-press to enter selection mode with a "Delete selected (N)" action bar. Requires a new bulk-delete backend endpoint. |
| 5 | Medium | Notifications | Deep-link to relevant trainee context | Tapping a "workout completed" notification navigates to the generic trainee detail screen. It should deep-link to the trainee's workout log for that specific day, since the `data` JSON already contains `workout_name` and date info. Similarly, "check_in" notifications should navigate to the weight trends screen. |
| 6 | Low | Notification Badge | Animate badge count transitions | When unread count changes (e.g. 3 -> 5 -> 0), the badge number snaps instantly. An `AnimatedSwitcher` with a scale/fade transition would make the change feel polished. |
| 7 | Low | Ambassador Commission Webhook | Surface commission creation to admin | When the webhook creates a commission, there's zero admin-facing visibility except log files. Creating a `TrainerNotification` (or a new `AdminNotification` model) when commissions are created would close the feedback loop. |
| 8 | Low | Webhook Resilience | `_handle_invoice_payment_failed` does not affect ambassador referral state | If a referred trainer's invoice fails, the referral stays ACTIVE even though the trainer may be about to churn. Consider adding an "AT_RISK" transient state or at least logging it as a warning so the ambassador dashboard can surface it. |

## Things I Could NOT Fix (Need Design Decisions or Major Changes)
| # | Area | Issue | Steps to Reproduce | Suggested Approach |
|---|------|-------|--------------------|--------------------|
| 1 | Real-time | No real-time notification updates | Open notifications screen. Have trainee complete workout. Notification does NOT appear until manual pull-to-refresh. | Implement WebSocket channel (Django Channels) or Server-Sent Events for the `trainer_notifications` table. Out of scope per ticket (explicitly listed in "Out of Scope"). |
| 2 | Testing | No end-to-end test for commission webhook flow | Commission creation is only testable via Stripe CLI `stripe trigger invoice.paid` or manual events | Add a Django management command (`simulate_webhook_event`) to inject test events locally without Stripe dependency. Also add integration tests that mock `stripe.Webhook.construct_event`. |
| 3 | Preferences | No notification preferences screen | Trainer cannot mute specific notification types (e.g. only see workout completions, not readiness surveys) | Add a `NotificationPreference` model (per trainer, per notification_type, enabled boolean) and a settings screen. Ticket explicitly marks this as out of scope for MVP. |
| 4 | Pagination | No "end of list" indicator | Scroll all the way down past the last page. Loading spinner appears briefly then vanishes silently. | When `hasMore` becomes false after the last page fetch, show a subtle "You've seen all notifications" message at the bottom of the list instead of just ending. Minor UX polish. |

## Summary
- Dead UI elements found: 1
- Visual bugs found: 1
- Logic bugs found: 4
- Improvements suggested: 8
- Items fixed by hacker: 5
- Items needing design decisions: 4

## Chaos Score: 8/10

The implementation is solid overall. The notification flow works end-to-end: backend creates notifications from survey views (readiness + post-workout), the API exposes them with proper pagination and read/unread filtering, and mobile displays them with good UX patterns (date grouping, optimistic updates, swipe-to-dismiss with undo snackbar, skeleton loading shimmer, proper empty/error/loading states).

The ambassador commission webhook is well-structured with proper duplicate guards (`UniqueConstraint` + `select_for_update`), rate snapshot at charge time, inactive ambassador checks, and graceful handling of both first-payment and recurring-payment scenarios. The fallback pattern (try TraineeSubscription first, then Subscription) is clean and handles all event types consistently.

The issues I found were all edge-case and polish-level: a missing snackbar for the deleted-trainee case (ticket edge case #3), a clock-skew guard for relative timestamps, a malformed JSON defense in the model parser, a stale `debugPrint` in production code, a silenced exception in pagination, and a non-scrollable error state. All five issues were fixed. No critical or high-severity bugs were found.

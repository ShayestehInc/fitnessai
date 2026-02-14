# Feature: Trainer Notifications Dashboard + Ambassador Commission Webhook

## Priority
High — Trainer notifications are the #1 engagement feature for trainer retention. Ambassador commissions complete the referral revenue loop that's fully built but never triggers.

## User Story
As a **trainer**, I want to see a notifications feed of trainee activity (readiness surveys, completed workouts, weight check-ins) so that I stay engaged and can respond to my trainees in real time.

As an **ambassador**, I want my commission to be automatically created when a referred trainer pays their platform subscription so that my earnings dashboard reflects real revenue.

As a **trainer who cancels**, I want the ambassador referral to be marked as churned so that commission tracking stays accurate.

## Acceptance Criteria

### Backend — Notification API
- [ ] AC-1: `GET /api/trainer/notifications/` — Returns paginated list of trainer's notifications, newest first. Includes `id`, `notification_type`, `title`, `message`, `data`, `is_read`, `read_at`, `created_at`. Requires IsTrainer. Supports `?is_read=true|false` filter.
- [ ] AC-2: `GET /api/trainer/notifications/unread-count/` — Returns `{"unread_count": N}` for the authenticated trainer. Requires IsTrainer. Single COUNT query.
- [ ] AC-3: `POST /api/trainer/notifications/<id>/read/` — Marks a single notification as read. Sets `is_read=True` and `read_at=now()`. Returns 200 with updated notification. Requires IsTrainer. Only the notification's own trainer can mark it.
- [ ] AC-4: `POST /api/trainer/notifications/mark-all-read/` — Marks all unread notifications for the trainer as read. Returns `{"marked_count": N}`. Uses bulk update for efficiency. Requires IsTrainer.
- [ ] AC-5: `DELETE /api/trainer/notifications/<id>/` — Deletes a single notification. Requires IsTrainer. Only the notification's own trainer can delete it.

### Backend — Ambassador Commission Webhook
- [ ] AC-6: When `invoice.paid` fires for a trainer's platform subscription (`Subscription` model), look up the trainer. If the trainer has an active `AmbassadorReferral`, call `ReferralService.create_commission()` with the subscription amount and billing period.
- [ ] AC-7: When `checkout.session.completed` fires for a trainer's platform subscription, create the `Subscription` record if needed and trigger the same commission logic as AC-6 for the first payment.
- [ ] AC-8: When `customer.subscription.deleted` fires for a trainer's platform subscription, call `ReferralService.handle_trainer_churn(trainer)` to mark ambassador referrals as CHURNED.
- [ ] AC-9: The webhook must handle both `TraineeSubscription` (existing behavior) and `Subscription` (platform) lookups for invoice events. If the subscription_id doesn't match a TraineeSubscription, try Subscription next.

### Mobile — Notifications Screen
- [ ] AC-10: New `TrainerNotificationsScreen` accessible from a bell icon in the trainer dashboard app bar. Shows paginated list of notifications grouped by date (Today, Yesterday, Earlier).
- [ ] AC-11: Each notification card shows: icon based on `notification_type`, title, message preview (max 2 lines), relative timestamp ("2m ago", "1h ago", "Yesterday"), and unread indicator (colored dot).
- [ ] AC-12: Notification bell icon in dashboard app bar shows unread count badge (red circle with number). Badge hidden when count is 0. Count refreshes on screen focus and pull-to-refresh.
- [ ] AC-13: "Mark All Read" button in notifications screen app bar. Shows confirmation and updates all cards instantly.
- [ ] AC-14: Tapping a notification marks it as read and navigates to the relevant trainee detail screen (using `data.trainee_id` from the notification's JSON data field). If no trainee_id, just marks as read.
- [ ] AC-15: Pull-to-refresh on notifications screen. Loading skeleton on first load. Empty state with illustration when no notifications exist.
- [ ] AC-16: Swipe-to-dismiss on individual notification cards (calls DELETE endpoint).

### Mobile — Data Layer
- [ ] AC-17: `TrainerNotification` data model in `trainer/data/models/` with fields matching the API response.
- [ ] AC-18: Notification methods added to `TrainerRepository`: `getNotifications(page, isRead)`, `getUnreadCount()`, `markNotificationRead(id)`, `markAllRead()`, `deleteNotification(id)`.
- [ ] AC-19: Notification providers in `trainer/presentation/providers/`: `notificationsProvider` (paginated list), `unreadNotificationCountProvider` (int), with proper invalidation on mark-read/mark-all-read/delete actions.

## Edge Cases
1. **No notifications** — Empty state shows friendly message: "All caught up! You'll see trainee activity here." with an illustration icon.
2. **100+ unread notifications** — Badge shows "99+" instead of exact count to prevent overflow.
3. **Notification for deleted trainee** — Tapping navigates nowhere gracefully (trainee_id no longer valid). Show snackbar "Trainee no longer available."
4. **Concurrent mark-all-read** — Bulk update uses `filter(is_read=False)` so concurrent calls are safe (second call marks 0).
5. **Webhook for non-existent trainer** — Log warning and return 200 (Stripe requires 200 response).
6. **Duplicate invoice.paid for same period** — `ReferralService.create_commission()` already has duplicate detection via `UniqueConstraint` and `select_for_update()`. Safe to call multiple times.
7. **Ambassador deactivated between referral and first payment** — `create_commission()` checks `profile.is_active` and skips if inactive.
8. **Trainer subscription downgraded** — Commission calculated on actual payment amount from invoice, not the cached subscription amount.
9. **Webhook signature verification fails** — Return 400, log error. Already handled.
10. **Large notification list performance** — Paginated (20 per page), indexed on `(trainer, created_at)` and `(trainer, is_read)`.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Notification list API fails | Error state with retry button | Return cached provider state if available |
| Mark-as-read API fails | Snackbar "Failed to update notification" | Revert optimistic UI update |
| Delete notification API fails | Snackbar "Failed to delete" | Restore dismissed card |
| Mark-all-read API fails | Snackbar "Failed to mark all read" | Revert badge count |
| Webhook commission creation fails | N/A (no user-facing UI) | Log error, commission stays uncreated, will retry on next invoice |
| Notification for deleted trainee | "Trainee no longer available" snackbar | Mark notification as read anyway |

## UX Requirements
- **Loading state:** Skeleton shimmer cards (3 placeholder notification shapes) on first load.
- **Empty state:** Centered illustration icon (bell with checkmark), "All caught up!" headline, "Trainee activity notifications will appear here" subtitle.
- **Error state:** Error icon + "Couldn't load notifications" + Retry button.
- **Success feedback:** Green snackbar on mark-all-read. Smooth fade animation on individual mark-as-read (dot disappears).
- **Badge:** Red circle, white text, positioned top-right of bell icon. Shows "99+" for counts > 99.
- **Notification types visual mapping:**
  - `trainee_readiness` → Green pulse icon (fitness)
  - `workout_completed` → Blue checkmark icon
  - `workout_missed` → Orange warning icon
  - `goal_hit` → Gold star icon
  - `check_in` → Purple scale icon
  - `message` → Gray chat icon
  - `general` → Gray info icon
- **Swipe-to-dismiss:** Red background with trash icon revealed on swipe left.
- **Date grouping:** "Today", "Yesterday", "Feb 12", "Feb 11", etc.

## Technical Approach

### Backend (files to create/modify)

**Create:**
- `backend/trainer/notification_views.py` — New views: `NotificationListView`, `UnreadCountView`, `MarkNotificationReadView`, `MarkAllReadView`, `DeleteNotificationView`
- `backend/trainer/notification_serializers.py` — `TrainerNotificationSerializer` (read-only serializer for the notification model)

**Modify:**
- `backend/trainer/urls.py` — Add notification URL patterns:
  - `notifications/` → list
  - `notifications/unread-count/` → count
  - `notifications/<int:pk>/read/` → mark read
  - `notifications/mark-all-read/` → mark all read
  - `notifications/<int:pk>/` → delete
- `backend/subscriptions/views/payment_views.py` — Modify `_handle_invoice_paid()` to also look up `Subscription` (platform) and call `ReferralService.create_commission()`. Modify `_handle_subscription_deleted()` to call `ReferralService.handle_trainer_churn()`. Modify `_handle_checkout_completed()` for first platform subscription payment.

### Mobile (files to create/modify)

**Create:**
- `mobile/lib/features/trainer/data/models/trainer_notification_model.dart` — `TrainerNotification` data model
- `mobile/lib/features/trainer/presentation/screens/trainer_notifications_screen.dart` — Full notifications screen with date grouping, swipe-to-dismiss, mark-all-read
- `mobile/lib/features/trainer/presentation/providers/notification_provider.dart` — `notificationsProvider`, `unreadNotificationCountProvider`
- `mobile/lib/features/trainer/presentation/widgets/notification_card.dart` — Individual notification card widget with type-based icon, unread dot, relative time
- `mobile/lib/features/trainer/presentation/widgets/notification_badge.dart` — Badge widget for bell icon overlay

**Modify:**
- `mobile/lib/features/trainer/data/repositories/trainer_repository.dart` — Add notification API methods
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` — Add notification bell icon with badge to app bar
- `mobile/lib/core/constants/api_constants.dart` — Add notification endpoint constants
- `mobile/lib/core/router/app_router.dart` — Add `/trainer/notifications` route

### Key Design Decisions
1. **Separate view file** for notifications (`notification_views.py`) — Keeps trainer views file manageable, clear separation of notification concerns.
2. **Bulk update for mark-all-read** — Single SQL UPDATE query, not N individual saves. Efficient for trainers with many notifications.
3. **Platform subscription webhook integration** — Extend existing `_handle_invoice_paid()` to also check `Subscription` model when `TraineeSubscription` is not found, rather than creating a separate webhook endpoint.
4. **Date grouping on mobile** — Computed client-side from `created_at` timestamps. No server-side grouping needed.
5. **Optimistic UI updates** — Mark-as-read and delete update the UI immediately, revert on API failure.
6. **Separate notification providers** — `unreadNotificationCountProvider` is separate from the list provider so the badge can poll independently without loading the full list.

## Out of Scope
- Push notifications (APNs/FCM) — Future enhancement, this is in-app only
- Notification preferences/settings (which types to receive) — All types shown for MVP
- Real-time WebSocket updates — Uses polling/pull-to-refresh for MVP
- Notification sounds/vibration — Future enhancement
- Ambassador dashboard UI changes for commission display — Already built in Pipeline 4
- Stripe payout to ambassadors — Out of scope per ambassador ticket

# Dev Done: Trainer Notifications Dashboard + Ambassador Commission Webhook

## Date: 2026-02-14

## Files Created
1. `backend/trainer/notification_serializers.py` — Read-only serializer for TrainerNotification model
2. `backend/trainer/notification_views.py` — 5 views: NotificationListView, UnreadCountView, MarkNotificationReadView, MarkAllReadView, DeleteNotificationView
3. `mobile/lib/features/trainer/data/models/trainer_notification_model.dart` — Data model with fromJson, copyWith, traineeId helper
4. `mobile/lib/features/trainer/presentation/providers/notification_provider.dart` — Riverpod providers: unreadNotificationCountProvider, notificationsProvider (with AsyncNotifier for pagination + optimistic updates)
5. `mobile/lib/features/trainer/presentation/widgets/notification_badge.dart` — Bell icon with red unread count badge (99+ cap)
6. `mobile/lib/features/trainer/presentation/widgets/notification_card.dart` — Notification card with type-based icon, unread dot, relative time, swipe-to-dismiss
7. `mobile/lib/features/trainer/presentation/screens/trainer_notifications_screen.dart` — Full notifications screen with date grouping, skeleton loader, empty/error states, mark-all-read, pagination

## Files Modified
1. `backend/trainer/urls.py` — Added 5 notification URL patterns
2. `backend/subscriptions/views/payment_views.py` — Modified `_handle_invoice_paid()` to also handle Subscription (platform) and create ambassador commissions; modified `_handle_subscription_deleted()` to handle trainer churn for ambassador referrals; modified `_handle_checkout_completed()` for first platform subscription payment; added `_create_ambassador_commission()` helper method
3. `mobile/lib/features/trainer/data/repositories/trainer_repository.dart` — Added 5 notification API methods
4. `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` — Added NotificationBadge widget to app bar
5. `mobile/lib/core/constants/api_constants.dart` — Added 5 notification endpoint constants
6. `mobile/lib/core/router/app_router.dart` — Added /trainer/notifications route

## Key Decisions
1. **Separate notification views file** — Kept notification views in `notification_views.py` separate from the main `views.py` to avoid bloat (main views file is already large).
2. **Platform subscription fallback in webhook** — When `invoice.paid` fires, first tries TraineeSubscription lookup (existing behavior), then falls back to Subscription (platform) lookup for ambassador commissions.
3. **Optimistic UI updates** — All mutation operations (mark-read, mark-all-read, delete) update the UI immediately and revert on API failure.
4. **AsyncNotifier for notifications** — Used `AsyncNotifierProvider` instead of simple `FutureProvider` to support pagination (loadMore), optimistic mutations (markRead, markAllRead, deleteNotification), and proper state management.
5. **Bulk update for mark-all-read** — Single SQL UPDATE query rather than N individual saves.
6. **Ambassador commission uses invoice amount_paid** — Extracts the actual paid amount from the Stripe invoice (in cents) rather than relying on cached subscription amounts, ensuring accuracy for downgrades/prorations.

## Deviations from Ticket
None — all acceptance criteria addressed.

## How to Test

### Backend Notifications
```bash
# List notifications
curl -H "Authorization: Bearer <trainer_token>" http://localhost:8000/api/trainer/notifications/

# Get unread count
curl -H "Authorization: Bearer <trainer_token>" http://localhost:8000/api/trainer/notifications/unread-count/

# Mark single as read
curl -X POST -H "Authorization: Bearer <trainer_token>" http://localhost:8000/api/trainer/notifications/1/read/

# Mark all as read
curl -X POST -H "Authorization: Bearer <trainer_token>" http://localhost:8000/api/trainer/notifications/mark-all-read/

# Delete notification
curl -X DELETE -H "Authorization: Bearer <trainer_token>" http://localhost:8000/api/trainer/notifications/1/
```

### Ambassador Commission Webhook
- Use Stripe CLI to send test `invoice.paid` event with a subscription_id matching a trainer's Subscription record
- Verify AmbassadorCommission record is created in the database
- Send `customer.subscription.deleted` event and verify referral status changes to CHURNED

### Mobile
- Login as a trainer
- Verify bell icon appears in dashboard app bar with badge count
- Tap bell → navigates to notifications screen
- Pull to refresh
- Tap a notification → marks as read, navigates to trainee detail
- Swipe left on notification → deletes
- "Mark All Read" button → all dots disappear, badge resets

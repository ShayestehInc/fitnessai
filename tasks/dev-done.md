# Dev Done: Wire Churn Push Notifications to FCM

## Date: 2026-03-05

## Summary
Wired the existing churn detection system (compute_retention management command) to actually send FCM push notifications via the core notification_service, instead of just logging the intent.

## Files Changed

### Backend
1. **backend/trainer/services/retention_notification_service.py** — Core change. Added two helper functions that call `core.services.notification_service.send_push_notification`. Both `create_churn_alerts` and `send_re_engagement_pushes` now send FCM pushes after creating TrainerNotification records.

2. **backend/users/models.py** — Added `re_engagement` BooleanField to NotificationPreference (default=True). Added to VALID_CATEGORIES.

3. **backend/users/serializers.py** — Added `re_engagement` to NotificationPreferenceSerializer fields.

4. **backend/users/migrations/0011_add_re_engagement_notification_pref.py** — Migration for the new field.

5. **backend/users/tests/test_notification_preferences.py** — Updated expected categories set and count (10 -> 11).

### Mobile
6. **mobile/lib/core/services/push_notification_service.dart** — Added deep link handling for `churn_alert` and `re_engagement` types.

7. **mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart** — Added "Re-engagement Reminders" toggle to the trainee Updates section.

## Key Decisions
- Trainer churn alerts send individual pushes per at-risk trainee (personalized messages).
- Re-engagement push copy: "We miss you! Your trainer [name] is cheering you on."
- Deep link for re-engagement goes to `/home` (the trainee home screen).
- Deep link for churn_alert goes to `/trainer/trainees/:id` (trainee detail).

## How to Test
1. Run `python manage.py compute_retention` with at-risk trainees.
2. Verify FCM pushes sent (check logs).
3. Toggle "Re-engagement Reminders" in trainee notification preferences.
4. Tap churn_alert notification -> trainer trainee detail page.
5. Tap re_engagement notification -> home screen.

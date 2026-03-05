# Architecture Review: Notification Preferences, Reminders & Dead UI Cleanup (Pipeline 42)

## Review Date
2026-03-04

## Files Reviewed
### Backend
- `backend/users/models.py` — NotificationPreference model
- `backend/users/views.py` — NotificationPreferenceView
- `backend/users/serializers.py` — NotificationPreferenceSerializer
- `backend/users/urls.py` — Route registration
- `backend/users/migrations/0008_add_notification_preference.py` — Migration
- `backend/core/services/notification_service.py` — Preference checking + FCM sending

### Mobile
- `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- `mobile/lib/core/services/reminder_service.dart`
- `mobile/lib/core/router/app_router.dart` — New routes and adaptive page pattern
- `mobile/lib/core/constants/api_constants.dart` — API endpoint constant

---

## Architectural Alignment
- [x] Follows existing layered architecture (Provider -> Repository -> ApiClient)
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views
- [x] Consistent with existing patterns
- [x] Routes registered in `app_router.dart`
- [x] API constants centralized in `api_constants.dart`
- [x] Row-level security: `NotificationPreferenceView` is scoped to the authenticated user via `get_or_create_for_user(request.user)`

### Details

**Backend layering is correct.** `NotificationPreferenceView` is a thin GET/PATCH handler that delegates to the model's `get_or_create_for_user` classmethod and the DRF serializer. The notification-filtering business logic lives in `notification_service.py` via `_check_notification_preference()` (single-user) and batch filtering in `send_push_to_group()`. This matches the project convention of keeping business logic in `services/`.

**Mobile follows repository pattern.** Screen -> Provider (AsyncNotifier) -> Repository -> ApiClient. The `NotificationPreferencesNotifier` handles optimistic updates with rollback. `NotificationPreferencesRepository` handles API calls with response validation. `ReminderService` is appropriately placed in `core/services/` as a platform-level singleton wrapping `flutter_local_notifications`.

**Riverpod usage is correct.** `AsyncNotifierProvider` is the right choice for server-synced state. Optimistic update pattern (set AsyncData, revert on error, rethrow for UI toast) is well-implemented.

**Router changes are consistent.** All 3 new routes (`/notification-preferences`, `/reminders`, `/help-support`) use `adaptivePage()` helper, matching the ~85 existing routes converted in this pipeline.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New table only; no existing column changes. All boolean fields default to `True`, so existing users with no row behave as "all enabled" (code checks `pref is None -> True`). |
| Migrations reversible | PASS | `CreateModel` is auto-reversible (Django drops the table). `RenameIndex` is also reversible. |
| Indexes added for new queries | PASS | OneToOne FK to User provides implicit unique index. `send_push_to_group` queries filter by `user_id__in` + specific boolean field, which is fine at current scale (one row per user). |
| No N+1 query patterns | PASS | `send_push_notification` does a single query for one user's preference. `send_push_to_group` does a single batch query filtering opted-out users. No loops over individual preference checks. |

### Model design decision: individual boolean fields vs JSONField

The ticket spec suggested a JSONField for categories. The implementation uses individual boolean fields instead. This is the **better choice** because:
1. Database-level filtering works natively (`NotificationPreference.objects.filter(new_message=False)`) -- essential for `send_push_to_group` batch filtering.
2. Schema-enforced validation -- no runtime parsing of JSON structure needed.
3. `VALID_CATEGORIES` frozenset provides a single source of truth for validation.
4. Adding new categories requires a migration but also forces explicit handling everywhere.

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | `get_or_create_for_user` on every request | Called on every GET/PATCH to the preferences endpoint. At current scale this is fine. If it becomes a hot path, consider creating the row during user registration. | Low priority. No action needed now. |
| 2 | `send_push_to_group` category filtering | Single query with `user_id__in` + boolean filter. Efficient at any reasonable scale. | No action needed. |
| 3 | `ReminderService` singleton | Singleton with lazy initialization. Thread-safe for Dart's single-isolate model. `SharedPreferences` batch write via `Future.wait`. | No action needed. |
| 4 | `NotificationPreferenceSerializer` response size | Returns all 9 boolean fields. Constant size, no pagination concern. | No action needed. |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Forward-looking preference fields without send callsites | Low | 5 of the 9 preference categories (`trainee_workout`, `trainee_weight_checkin`, `trainee_started_workout`, `trainee_finished_workout`, `churn_alert`, `achievement_earned`) have toggles but no existing notification send calls in the codebase. This is not debt from Pipeline 42 -- those notification triggers don't exist yet. When they are built, they must use the `category=` parameter. |
| 2 | `ReminderService.onNotificationTapped` callback not wired to navigation | Low | The callback hook and payloads ('workout', 'meal', 'weight') are in place but not connected to go_router navigation during app initialization. This completes the infrastructure; wiring to navigation is a separate task (AC-15 partially addressed). |
| 3 | `NotificationPreferenceSerializer` uses standard DRF `ModelSerializer` | Low | Project rules specify `rest_framework_dataclasses` for API responses. However, the entire codebase (58 usages across 11 files) uses standard DRF serializers. Changing just this one serializer would be inconsistent. This is a codebase-wide concern, not a Pipeline 42 issue. No action taken. |

## Technical Debt Reduced
- Removed ~25 `print()` statements from `admin_repository.dart`
- Removed all `print()` and `LogInterceptor` from `api_client.dart`
- Replaced broken `widget_test.dart` with a working smoke test
- Wired 5 dead UI buttons to actual destinations
- Standardized ~85 routes to use `adaptivePage`/`adaptiveFullscreenPage` for consistent iOS/Android navigation

## API Design Assessment

The `NotificationPreferenceView` endpoint is RESTful and consistent:
- `GET /api/users/notification-preferences/` -- returns current state
- `PATCH /api/users/notification-preferences/` -- partial update
- `IsAuthenticated` permission -- correct, since both trainers and trainees have preferences
- Serializer excludes `user`, `created_at`, `updated_at` from writable fields
- Auto-creates preference row on first access -- matches `UserProfile.get_or_create` pattern used elsewhere
- Consistent with existing endpoint patterns at `/api/users/leaderboard-opt-in/` and `/api/users/device-token/`

## Positive Architectural Observations

1. **Fail-open design**: `_check_notification_preference` returns `True` on `DatabaseError`/`ConnectionError`, ensuring notifications are never silently dropped due to infrastructure issues. The exception scope is deliberately narrow (not bare `except`).

2. **Batch filtering in `send_push_to_group`**: Rather than checking preferences one-by-one in a loop, the implementation does a single `filter(user_id__in=..., category=False)` query to find opted-out users, then excludes them from the send list. This is O(1) queries regardless of group size.

3. **Category validation**: `VALID_CATEGORIES` frozenset on the model serves as a single source of truth. `is_category_enabled()` raises `ValueError` for invalid categories (catching bugs early). `send_push_to_group` logs a warning for invalid categories but doesn't crash (resilient in production).

4. **Optimistic updates with proper rollback**: The `NotificationPreferencesNotifier` sets `AsyncData(previous)` on failure (not `AsyncError`), so the UI shows the reverted state without flashing an error widget. The error is rethrown so the screen can show a toast.

5. **ReminderSettings is immutable**: Uses `copyWith` pattern. Clean separation between data (ReminderSettings), persistence (SharedPreferences), and scheduling (FlutterLocalNotificationsPlugin).

6. **Timezone handling**: Uses `flutter_timezone` package to get the actual IANA timezone name from the platform, with UTC fallback. This is correct for `zonedSchedule` which requires a named timezone.

## No Architectural Fixes Required

After thorough review, no architectural issues were found that warrant code changes. The implementation is well-layered, the data model is sound, the API design is consistent, and scalability patterns are appropriate for the current and foreseeable scale.

## Architecture Score: 9/10
## Recommendation: APPROVE

### Rationale
The implementation makes sound architectural decisions throughout. The data model design (individual boolean fields over JSONField) enables efficient batch queries. Backend layering is correct with business logic in the service layer. The mobile side follows the repository pattern with proper Riverpod state management. The notification service handles both single-user and group filtering efficiently with no N+1 queries. The only deductions are for the unwired notification tap callback and the forward-looking preference fields without corresponding send callsites, both of which are minor and intentional infrastructure-first decisions.

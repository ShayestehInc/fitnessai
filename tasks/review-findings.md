# Code Review: Wire FCM Push Notifications End-to-End for Community Events

## Review Date: 2026-03-05

## Files Reviewed
- `backend/users/models.py` (lines 298-396 -- NotificationPreference model)
- `backend/users/migrations/0010_add_community_event_notification_pref.py`
- `backend/community/services/event_service.py` (full file, 246 lines)
- `backend/community/trainer_views.py` (full file, 856 lines -- event views at 461-623)
- `backend/community/management/commands/send_event_reminders.py` (full file, 22 lines)
- `backend/core/services/notification_service.py` (full file -- read for contract verification)
- `mobile/lib/core/services/push_notification_service.dart` (full file, 240 lines)
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` (full file, 288 lines)
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart` (lines 95-130)
- `mobile/lib/core/router/app_router.dart` (line 847 -- route verification)
- `tasks/next-ticket.md`
- `tasks/dev-done.md`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `backend/community/services/event_service.py:198-245` | **Duplicate reminders on every cron run.** `send_event_reminders()` queries events with `starts_at > now` AND `starts_at <= now + 15min`. The cron runs every 5 minutes. An event starting in 14 minutes will match on three consecutive cron runs (at T-15, T-10, T-5), sending the same users up to 3 reminder notifications. There is no `reminder_sent` flag or tracking to prevent re-sends. | Add a `reminder_sent_at` DateTimeField to `CommunityEvent`. After successfully sending reminders for an event, set `reminder_sent_at = timezone.now()`. Filter the query to exclude events where `reminder_sent_at IS NOT NULL`. Alternatively, narrow the window to match the cron interval (e.g., `starts_at__gt=now, starts_at__lte=now + timedelta(minutes=5)`) so each event only falls in one 5-minute window. |
| C2 | `mobile/lib/core/services/push_notification_service.dart:219-233` | **Payload encoding is fragile and will break on special characters.** `_buildPayload` joins data entries as `key=value` with `&` separator. `_parsePayload` splits on `&` then on the first `=`. If any data value contains `=` or `&` characters, parsing produces incorrect results, potentially misrouting notification taps or losing the event_id. While current payloads only use `type` and `event_id` (safe values), this is a latent correctness bug that will bite on any future string additions. | Use `jsonEncode(data)` for encoding and `jsonDecode(payload) as Map<String, dynamic>` for decoding. This handles all special characters and is simpler. Alternatively use `Uri(queryParameters: data.map((k, v) => MapEntry(k, v.toString()))).query` for encoding and `Uri(query: payload).queryParameters` for decoding. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `backend/community/services/event_service.py:107-133` | **`notify_event_created` sends to banned users.** The query fetches all active trainees of the trainer. Users banned from the community (via `UserBan` with `is_active=True`) should not receive event notifications. | Add `.exclude(id__in=UserBan.objects.filter(trainer=event.trainer, is_active=True).values('user_id'))` to the trainee query, or join against the ban table. |
| M2 | `backend/community/services/event_service.py:216-243` | **N+1 query pattern in `send_event_reminders`.** The method loops over events and issues a separate RSVP query + FCM batch call per event. With many concurrent events (e.g., a trainer running multiple concurrent sessions), this generates N+1 queries. | Pre-fetch all RSVPs for the matched events in a single query: `EventRSVP.objects.filter(event__in=events, status='going').values('event_id', 'user_id')`, then group by event_id in Python. |
| M3 | `backend/community/services/event_service.py:218` | **Import inside a loop.** `from core.services.notification_service import send_push_to_group` is inside the `for event in events` loop body. Python caches imports, but this is needlessly placed inside the loop and reads as a code smell. | Move the import to the top of the method body, before the loop starts. |
| M4 | `mobile/lib/core/services/push_notification_service.dart:38-42` | **Swallowing all Firebase initialization errors.** The empty `catch (_)` block means if Firebase fails to initialize for a real reason (e.g., misconfigured `google-services.json`, missing `GoogleService-Info.plist`), the service silently proceeds, then crashes when trying to use `FirebaseMessaging.instance`. | Check `Firebase.apps.isNotEmpty` before calling `initializeApp()`. If initialization truly fails, set `_initialized = false` and return early so the service degrades gracefully instead of crashing later. |
| M5 | `mobile/lib/core/services/push_notification_service.dart:117-129` | **Token registration failure is completely silenced.** If the backend rejects the token (401 expired JWT, 500 server error), the user will never register their device and will never receive push notifications until next app launch. No retry, no logging. | Log the error with `debugPrint` or a logger. Consider resetting `_initialized = false` on auth failure (401) so the next `initialize()` call retries. |
| M6 | `mobile/lib/features/auth/presentation/providers/auth_provider.dart:61,90,158,189,209` | **`_pushService.initialize()` is not awaited in any of the 5 call sites.** The call is fire-and-forget. If it throws (e.g., `Firebase.initializeApp` throws before the catch), the exception is unhandled and will surface as an unhandled Future error, potentially crashing the app in debug mode. | Add `await` or wrap in `unawaited()` (from `dart:async`) to make the intent explicit. If fire-and-forget is desired, at minimum add `.catchError((_) {})` to prevent unhandled exceptions. |
| M7 | `backend/community/trainer_views.py:556-558` | **Update notification body is unhelpful.** The notification body is just the event title with "Event Updated" as the title. The user has no idea what changed -- was the time moved? Was the meeting link updated? | Include what changed in the body, e.g., `body=f"{event.title} - time/location updated"` or list the specific changed fields. |
| M8 | `backend/community/trainer_views.py:577-590` | **DELETE handler does not actually delete the event.** The HTTP DELETE verb and 204 response imply resource deletion, but the implementation only transitions to CANCELLED. The event still exists. Frontend code calling DELETE and expecting the resource to be gone will be confused if it fetches the event list again and the cancelled event is still there. | Either (a) document this clearly in the API response by returning 200 with the updated event body and CANCELLED status, or (b) rename the endpoint to a PATCH status transition and keep the current DELETE for actual deletion. The current design is misleading. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `backend/community/services/event_service.py:107,136,167,198` | **Repetitive try/except/import/log boilerplate.** All four notification methods follow the exact same pattern: try, lazy import, query user_ids, call send_push_to_group, except+log. 20+ lines of boilerplate per method. | Extract a helper: `_send_event_push(user_ids, title, body, event_id, notif_type)` that encapsulates the try/except/import/send pattern. |
| m2 | `backend/community/services/event_service.py:84-89` | **`transition_status` has no state machine validation.** Any status can be set to any other status (e.g., `completed -> scheduled`, `cancelled -> live`). | Add a mapping of allowed transitions and raise `ValueError` for invalid ones. |
| m3 | `mobile/lib/core/services/push_notification_service.dart:154` | **`message.hashCode` as notification ID.** `hashCode` is not guaranteed unique and can collide, potentially replacing a previous notification with a newer one. | Use `message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch` for a more stable ID. |
| m4 | `mobile/lib/core/services/push_notification_service.dart:235-239` | **`_getPlatform()` returns 'web' for desktop platforms.** Flutter desktop (macOS, Linux, Windows) would incorrectly report as 'web'. | Return 'unknown' or the actual platform name for non-mobile platforms. |
| m5 | `mobile/lib/core/services/push_notification_service.dart:212-215` | **Navigation error silenced.** `catch (_)` hides real bugs in routing configuration. | At minimum log the error. Better: catch only `GoException` or similar. |
| m6 | `backend/community/management/commands/send_event_reminders.py` | **No `--dry-run` flag.** For a cron-based management command, dry-run mode is essential for production debugging. | Add `self.add_arguments(parser)` with a `--dry-run` flag that logs what would be sent without calling `send_push_to_group`. |

---

## Security Concerns

1. **No issues with auth/authz.** All event endpoints correctly check `IsAuthenticated` + `IsTrainer` permissions and filter by `trainer=user` in queries. No IDOR risk.
2. **Data payload values are all strings.** `str(event.id)` is used consistently across all notification calls. The `send_push_to_group` signature expects `dict[str, str]` and all callers comply. FCM string-only data requirement is satisfied.
3. **No secrets in code.** Firebase credentials loaded from environment variable, not hardcoded. Migration file contains no sensitive data.
4. **No injection risk.** Event titles in notification bodies come from trainer input (validated by serializer). FCM handles display escaping.
5. **Notification preference check is robust.** `send_push_to_group` in `notification_service.py` validates the category string against `VALID_CATEGORIES` before querying, preventing injection via the `**{category: False}` dynamic filter (line 167).

## Performance Concerns

1. **C1 (duplicate reminders)** is also a performance concern -- sends 3x the intended FCM messages, wasting quota.
2. **M2 (N+1 in reminders loop)** -- O(N) queries where N = number of upcoming events. Acceptable at small scale but will degrade.
3. **Synchronous notification dispatch in request cycle.** All notification sends happen inline in the HTTP request handler (no Celery/background task). For event creation to a trainer with 500 trainees, this adds measurable latency to the 201 response. The existing announcement pattern does the same, so this is consistent, but worth noting as a scaling concern.

---

## Acceptance Criteria Verification

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC1 | `community_event` field on NotificationPreference with migration | PASS | models.py:343-346, migration 0010, added to VALID_CATEGORIES |
| AC2 | Push to all trainees on event creation | PASS | trainer_views.py:510-511 calls notify_event_created() |
| AC3 | Push to RSVP'd users on cancellation | PASS | trainer_views.py:587-588 and 619-620 |
| AC4 | Push to RSVP'd users on time/location change | PASS | trainer_views.py:556-572, checks field intersection |
| AC5 | Push to 'going' users 15 min before event | PASS* | event_service.py:198-245 + mgmt command. *C1: duplicate sends |
| AC6 | `initialize()` called after login | PASS | auth_provider.dart:61, 90, 158, 189, 209 |
| AC7 | `deactivateToken()` called on logout | PASS | auth_provider.dart:100 |
| AC8 | Foreground handler displays local notification | PASS | push_notification_service.dart:148-169 |
| AC9 | Tap navigates to event detail | PASS | push_notification_service.dart:193-201, route confirmed at app_router.dart:847 |
| AC10 | "Community Events" toggle in preferences | PASS | notification_preferences_screen.dart:111-116 |
| AC11 | Data payloads include `type` and `event_id` | PASS | All 4 notification types verified |
| AC12 | Notifications respect category opt-out | PASS | `category='community_event'` passed, notification_service.py:153-177 filters |

**Result: 12/12 acceptance criteria met.** AC5 is functionally met but has a duplicate-send bug (C1).

---

## Quality Score: 6/10

The implementation is functionally complete -- all 12 acceptance criteria pass. The architecture follows existing patterns well (fire-and-forget notifications, lazy Firebase import, `send_push_to_group` contract). The notification preference integration is clean. The mobile deep linking is properly wired with all 4 event notification types routed correctly. Token lifecycle (register on login, deactivate on logout) is solid.

However, C1 (duplicate reminders) is a production bug that will spam users, and C2 (fragile payload encoding) is a correctness issue that will break on future changes. Multiple error-handling gaps (M4, M5, M6) mean failures during push setup are invisible. The N+1 query in the reminder loop (M2) and the misleading DELETE semantics (M8) are architectural concerns that should be addressed before this ships.

## Recommendation: REQUEST CHANGES

**Must fix before re-review:**
- C1 (duplicate reminders -- production bug)
- C2 (payload encoding -- correctness)
- M6 (unawaited initialize -- potential crash)

**Should fix:**
- M1 (banned users get notifications)
- M2 (N+1 queries)
- M3 (import in loop)
- M4 (Firebase init error handling)
- M5 (silent token registration failure)
- M7 (unhelpful update notification body)
- M8 (misleading DELETE semantics)

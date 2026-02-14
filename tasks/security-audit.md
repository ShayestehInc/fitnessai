# Security Audit: Trainer Notifications Dashboard + Ambassador Commission Webhook

## Audit Date: 2026-02-14 (Pipeline 5)

## Files Reviewed
- `backend/trainer/notification_views.py` (created)
- `backend/trainer/notification_serializers.py` (created)
- `backend/trainer/urls.py` (modified)
- `backend/trainer/models.py` (TrainerNotification model -- reviewed)
- `backend/subscriptions/views/payment_views.py` (modified -- `_handle_invoice_paid`, `_handle_checkout_completed`, `_handle_subscription_deleted`, `_create_ambassador_commission`)
- `backend/ambassador/services/referral_service.py` (called by webhook -- reviewed)
- `backend/core/permissions.py` (IsTrainer permission class -- reviewed)
- `backend/config/settings.py` (DRF defaults, throttle, CORS, auth -- reviewed)
- `mobile/lib/features/trainer/presentation/providers/notification_provider.dart` (created)
- `mobile/lib/features/trainer/presentation/widgets/notification_card.dart` (created)
- `mobile/lib/features/trainer/presentation/widgets/notification_badge.dart` (created)
- `mobile/lib/features/trainer/presentation/screens/trainer_notifications_screen.dart` (created)
- `mobile/lib/features/trainer/data/repositories/trainer_repository.dart` (modified)
- `mobile/lib/features/trainer/data/models/trainer_notification_model.dart` (created)
- `mobile/lib/core/constants/api_constants.dart` (modified)

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (`.env` files in `.gitignore`, `example.env` uses placeholders only)
- [x] All user input sanitized (notification content is server-generated, not user-supplied)
- [x] Authentication checked on all new endpoints (all 5 notification endpoints require `IsAuthenticated`)
- [x] Authorization -- correct role/permission guards (`IsTrainer` on all notification endpoints)
- [x] No IDOR vulnerabilities (all queries filter by `trainer=request.user`, tested with row-level security tests)
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [x] Rate limiting on sensitive endpoints (global DRF throttle: 120/min for authenticated users applies)
- [x] Error messages don't leak internals (generic error messages, no stack traces exposed)
- [x] CORS policy appropriate (restricted in production, open only in DEBUG mode)
- [x] Webhook signature verification in place (`stripe.Webhook.construct_event` with `STRIPE_WEBHOOK_SECRET`)
- [x] Stripe API key loaded from `settings.STRIPE_SECRET_KEY` (env var), not hardcoded

---

## 1. SECRETS

**Result: PASS**

Grepped all new/changed files (backend and mobile) for patterns: `api_key`, `password`, `secret`, `token`, `sk_live`, `pk_live`, `sk_test`, `pk_test`, `SECRET_KEY`, `PRIVATE_KEY`, `AWS_ACCESS`, `OPENAI_API_KEY`, `AKIA`, `eyJ`. No hardcoded secrets found.

- `stripe.api_key = settings.STRIPE_SECRET_KEY` (line 36 of `payment_views.py`) -- reads from environment variable, not hardcoded. Existing pattern, not new.
- `.env` files are in `.gitignore` and not tracked by git.
- `example.env` uses placeholder values only (e.g., `your-stripe-secret-key-here`).
- No tokens, credentials, or API keys in any mobile Dart files.

---

## 2. INJECTION

**Result: PASS**

| # | Type | File:Line | Issue | Status |
|---|------|-----------|-------|--------|
| 1 | SQL Injection | N/A | All queries use Django ORM exclusively. No raw SQL, `RawSQL()`, `extra()`, or `cursor.execute()` in any new code. | PASS |
| 2 | XSS | N/A | All responses are JSON via DRF. Notification `title`/`message` are server-generated from stored user data (names from DB), not from HTTP request bodies. Flutter renders text natively (no HTML rendering). | PASS |
| 3 | Command Injection | N/A | No shell commands, `os.system()`, or `subprocess` calls. | PASS |
| 4 | Path Traversal | N/A | No file operations in notification or webhook features. | PASS |
| 5 | Parameter Injection | `notification_views.py:50-53` | `is_read` query parameter is parsed via safe string comparison (`lower() in ('true', '1', 'yes')`) and then passed as a Python boolean to `.filter(is_read=is_read)`. No injection vector. | PASS |

---

## 3. AUTH & AUTHZ

**Result: PASS**

### Endpoint Authorization Matrix

| # | Endpoint | Method | Auth | Permission | Row-Level Security | Status |
|---|----------|--------|------|------------|-------------------|--------|
| 1 | `GET /api/trainer/notifications/` | GET | IsAuthenticated | IsTrainer | `filter(trainer=request.user)` | PASS |
| 2 | `GET /api/trainer/notifications/unread-count/` | GET | IsAuthenticated | IsTrainer | `filter(trainer=request.user, is_read=False)` | PASS |
| 3 | `POST /api/trainer/notifications/<pk>/read/` | POST | IsAuthenticated | IsTrainer | `.get(pk=pk, trainer=request.user)` -- returns 404 for wrong trainer | PASS |
| 4 | `POST /api/trainer/notifications/mark-all-read/` | POST | IsAuthenticated | IsTrainer | `filter(trainer=request.user, is_read=False)` | PASS |
| 5 | `DELETE /api/trainer/notifications/<pk>/` | DELETE | IsAuthenticated | IsTrainer | `.get(pk=pk, trainer=request.user)` -- returns 404 for wrong trainer | PASS |
| 6 | `POST /api/payments/webhook/` | POST | None (webhook) | None | Verified via Stripe webhook signature | PASS |

### IDOR Analysis

- **NotificationListView**: `get_queryset()` filters by `trainer=cast(User, self.request.user)`. A trainer can only see their own notifications. No user-supplied trainer ID parameter.
- **MarkNotificationReadView**: Uses `.get(pk=pk, trainer=trainer)` -- the notification must belong to the authenticated trainer. If trainer A tries to mark trainer B's notification (pk=X), they get 404.
- **DeleteNotificationView**: Same pattern -- `.get(pk=pk, trainer=trainer)`. Cross-trainer deletion is impossible.
- **MarkAllReadView**: Filters by `trainer=request.user`. Only marks the authenticated trainer's notifications.
- **UnreadCountView**: Counts only `trainer=request.user` notifications.

**Test Coverage:** 59 tests pass for notification views, including dedicated `NotificationRowLevelSecurityTests` and `NotificationPermissionTests` that verify:
- Trainer A cannot see/read/delete trainer B's notifications
- Mark-all-read only affects own notifications
- Unauthenticated users get 401
- Trainees get 403

**No IDOR vulnerabilities found.**

### Webhook Security

- `StripeWebhookView` validates the webhook payload via `stripe.Webhook.construct_event()` with `settings.STRIPE_WEBHOOK_SECRET`.
- Invalid payloads return 400 ("Invalid payload").
- Invalid signatures return 400 ("Invalid signature").
- The webhook handler processes only known event types and silently ignores unknown ones (returns 200).
- All user lookups in webhook handlers use validated data from the Stripe-verified event object.

---

## 4. DATA EXPOSURE

**Result: PASS**

### Serializer Field Exposure

`TrainerNotificationSerializer` exposes exactly: `id`, `notification_type`, `title`, `message`, `data`, `is_read`, `read_at`, `created_at`.

- The `trainer` FK is correctly **excluded** from the serialized output. A notification does not reveal which trainer it belongs to (beyond the fact that the authenticated trainer is viewing their own).
- The `data` JSONField contains operational data: `trainee_id`, `trainee_name`, `workout_name`, `readiness_score`, `survey_data`. This data is appropriate for the trainer to see -- it's about their own trainees.

### Error Messages

All error responses use generic messages:
- `"Notification not found"` (404)
- No stack traces, no internal paths, no query details

### Webhook Logging

- Logger messages in webhook handlers reference `trainer.email` and `subscription_id`, which are appropriate for server-side logs. These are not returned to the client.
- All webhook responses return only `{"received": true}`, `{"error": "Invalid payload"}`, or `{"error": "Invalid signature"}`.

---

## 5. WEBHOOK COMMISSION SECURITY

**Result: PASS**

### Commission Creation Flow

| Check | Status | Details |
|-------|--------|---------|
| Signature verification | PASS | `stripe.Webhook.construct_event()` validates payload + signature before any processing |
| Duplicate prevention | PASS | `ReferralService.create_commission()` uses `select_for_update()` on referral row + checks for existing commission for same `(referral, period_start, period_end)` |
| Zero-amount protection | PASS | `_create_ambassador_commission()` checks `base_amount <= 0` and skips (no free-tier abuse) |
| Inactive ambassador check | PASS | `create_commission()` checks `profile.is_active` and skips if inactive |
| Concurrent webhook safety | PASS | `select_for_update()` prevents race conditions from duplicate Stripe webhook deliveries |
| MultipleObjectsReturned handling | PASS | `_create_ambassador_commission()` catches `MultipleObjectsReturned` and uses `.first()` as fallback |
| Non-existent trainer handling | PASS | `User.DoesNotExist` caught, logged as warning, returns 200 (Stripe requires 200) |
| Missing period dates handling | PASS | Checks `period_start_ts` and `period_end_ts` before proceeding |

### Subscription Type Separation

- `_handle_invoice_paid()` correctly separates `TraineeSubscription` (trainee-to-trainer payments) from `Subscription` (platform subscriptions). It tries `TraineeSubscription` first, and only falls back to `Subscription` if not found. No data mixing.
- `_handle_subscription_deleted()` follows the same pattern. Trainer churn is only triggered for `Subscription` (platform) cancellations, not `TraineeSubscription` cancellations. Verified by test `test_subscription_deleted_trainee_sub_does_not_churn_referral`.
- `_handle_checkout_completed()` uses `payment_type == 'platform_subscription'` metadata to distinguish platform checkouts from trainee-to-trainer checkouts.

---

## 6. CORS/CSRF

**Result: PASS**

- CORS is conditional on `DEBUG`: `CORS_ALLOW_ALL_ORIGINS = True` only in DEBUG mode. Production uses `CORS_ALLOWED_ORIGINS` from environment variable.
- The API uses JWT authentication exclusively (`DEFAULT_AUTHENTICATION_CLASSES: JWTAuthentication`). No session-based authentication, so CSRF attacks are not applicable.
- The webhook endpoint (`StripeWebhookView`) has `permission_classes = []` but does not set `authentication_classes = []`. DRF's default JWT authentication will still attempt to parse the Authorization header. Since Stripe doesn't send an Authorization header, the user will be set to `AnonymousUser`, and since `permission_classes = []` means no permission check runs, this works correctly. See Minor Observation #1 below.

---

## 7. RATE LIMITING

**Result: PASS**

Global rate limiting is configured in `settings.py`:
- `AnonRateThrottle`: 30/minute
- `UserRateThrottle`: 120/minute
- `RegistrationThrottle`: 5/hour

All notification endpoints inherit the default `UserRateThrottle` (120/min). This is appropriate -- trainers polling for unread count or refreshing the list will not hit this limit under normal usage.

The webhook endpoint uses `permission_classes = []`, which means DRF's default throttle classes still apply (specifically `AnonRateThrottle` at 30/min for unauthenticated requests). Stripe's webhook delivery rate is well within this limit, but if needed, the webhook view could set `throttle_classes = []` to avoid any throttling. This is an informational observation, not a vulnerability.

---

## Minor Observations (Informational -- No Fix Needed)

| # | Severity | File:Line | Observation | Notes |
|---|----------|-----------|-------------|-------|
| 1 | Low | `payment_views.py:420` | Webhook view has `permission_classes = []` but does not explicitly set `authentication_classes = []`. | DRF's default JWT authentication will still attempt to parse incoming requests. Since Stripe doesn't send an Authorization header, the request is treated as `AnonymousUser` and `permission_classes = []` allows it through. Setting `authentication_classes = []` explicitly would be cleaner and avoid unnecessary JWT parsing overhead. Not a vulnerability -- just a best-practice recommendation. |
| 2 | Low | `notification_views.py:32` | `page_size_query_param = 'page_size'` allows clients to request up to 50 items per page. | Capped at `max_page_size = 50`. This is reasonable and not exploitable. An abusive client could make many requests, but global rate limiting (120/min) prevents abuse. |
| 3 | Low | `payment_views.py:519-523` | `_handle_checkout_completed` creates an `invoice_stub` dict with `amount_total` from session for first-payment commission. | The `amount_total` comes from the Stripe-verified event data (post signature verification), so it cannot be tampered with. Safe. |
| 4 | Info | All notification endpoints | No per-endpoint throttle on mark-all-read. | A trainer could rapidly call mark-all-read, but impact is limited (idempotent operation on their own data). Global 120/min throttle applies. |

---

## Critical/High Issues Found: **NONE**

No Critical or High severity issues were identified. No fixes were required.

---

## Test Results

- **Notification view tests:** 59/59 passing (includes permission, IDOR, and row-level security tests)
- **Subscription/webhook tests:** 31/31 passing (includes ambassador commission and churn tests)
- **Pre-existing failure:** 2 errors from `mcp_server` module import (`ModuleNotFoundError: No module named 'mcp'`) -- unrelated to this feature

---

## Security Score: 9/10

The implementation demonstrates strong security practices:
- Consistent use of row-level security (all queries filter by authenticated trainer)
- Proper Stripe webhook signature verification
- No secrets in code or committed files
- Proper IDOR prevention with composite lookups (`pk=pk, trainer=trainer`)
- Race condition protection for commission creation (`select_for_update()` + duplicate check)
- Comprehensive test coverage including permission and row-level security tests (59 + 31 = 90 passing tests)

Deductions:
- -0.5: Webhook view could be more explicit with `authentication_classes = []` (minor best-practice gap, not a vulnerability)
- -0.5: No per-endpoint throttle on notification mutation endpoints (global throttle applies but a dedicated throttle would be more robust)

## Recommendation: PASS

No Critical or High issues found. No fixes required. The implementation is secure and follows established project patterns for authentication, authorization, IDOR prevention, and webhook security.

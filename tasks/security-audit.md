# Security Audit: Community Events Feature

## Audit Date: 2026-03-05

## Files Reviewed
- `mobile/lib/features/community/data/models/event_model.dart`
- `mobile/lib/features/community/data/repositories/event_repository.dart`
- `mobile/lib/features/community/presentation/providers/event_provider.dart`
- `mobile/lib/features/community/presentation/widgets/event_type_badge.dart`
- `mobile/lib/features/community/presentation/widgets/rsvp_button.dart`
- `mobile/lib/features/community/presentation/widgets/event_card.dart`
- `mobile/lib/features/community/presentation/screens/event_list_screen.dart`
- `mobile/lib/features/community/presentation/screens/event_detail_screen.dart`
- `mobile/lib/features/community/presentation/screens/trainer_event_list_screen.dart`
- `mobile/lib/features/community/presentation/screens/trainer_event_form_screen.dart`
- `backend/community/views.py` (TraineeEventListView, TraineeEventDetailView, TraineeEventRSVPView)
- `backend/community/trainer_views.py` (TrainerEventListCreateView, TrainerEventDetailView, TrainerEventStatusView)
- `backend/community/services/event_service.py`
- `backend/community/serializers/event_serializers.py`
- `backend/community/models.py` (CommunityEvent, EventRSVP)

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (DRF serializer validation with ChoiceField, CharField max_length, URLField, IntegerField min_value)
- [x] Authentication checked on all new endpoints (IsAuthenticated on all views)
- [x] Authorization -- correct role/permission guards (IsTrainee for trainee views, IsTrainer for trainer views)
- [x] No IDOR vulnerabilities (all querysets scoped by trainer ownership)
- [x] File uploads validated (N/A -- no file uploads in events)
- [ ] Rate limiting on sensitive endpoints (no throttling on RSVP or event creation -- Low risk)
- [x] Error messages don't leak internals (FIXED: status reflection)
- [x] CORS policy appropriate (no changes)

## Issues Found

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 1 | **High** | `backend/community/trainer_views.py:584` | **IDOR in TrainerUnbanView:** The `delete` method fetched `User.objects.get(id=user_id)` without scoping to the trainer's trainees. Any authenticated trainer could unban any user in the system by guessing user IDs. | **FIXED.** Scoped lookup to `User.objects.get(id=user_id, parent_trainer=user, role=User.Role.TRAINEE)`. |
| 2 | **Medium** | `backend/community/trainer_views.py:582` | **User input reflected in error message:** `TrainerEventStatusView.patch()` reflected `new_status` (raw user input) verbatim in the error response: `f'Invalid status: {new_status}'`. Could be used for XSS if rendered in a web client. | **FIXED.** Error message now lists valid status values instead of reflecting user input. |
| 3 | **Medium** | `backend/community/services/event_service.py:30` | **No guard against RSVP to cancelled/completed events:** `EventService.rsvp()` had no status check. A crafted API request could RSVP to cancelled events, bypassing the mobile UI guard. | **FIXED.** Added status check that raises `ValueError` for cancelled/completed events; view returns 409 Conflict. |
| 4 | **Low** | `backend/community/serializers/event_serializers.py:15-17` | **User email exposed in EventRSVPSerializer:** `user_email`, `user_first_name`, `user_last_name` are returned for each RSVP. This is only served to the owning trainer via `TrainerEventDetailView`, which prefetches RSVPs. Acceptable given the trainer-trainee relationship. | No fix needed -- access is properly scoped. |
| 5 | **Low** | `backend/community/views.py:1526` | **No cancelled-event guard on RSVP endpoint (redundant with Fix 3):** The view fetches the event but does not check `event.status` before calling `EventService.rsvp()`. Now covered by the service-level check. | Covered by Fix 3. |
| 6 | **Info** | `mobile/.../event_detail_screen.dart:259` | **Meeting URL opened via url_launcher:** The `_launchUrl` method validates the URI with `Uri.tryParse` and `canLaunchUrl` before opening. Properly guarded. | No fix needed. |

## Auth & Authz Analysis

### Trainee Endpoints
| Endpoint | Auth | Permission | Scoping | Status |
|----------|------|------------|---------|--------|
| GET /api/community/events/ | IsAuthenticated | IsTrainee | `trainer=user.parent_trainer` | OK |
| GET /api/community/events/:id/ | IsAuthenticated | IsTrainee | `trainer=user.parent_trainer` | OK |
| POST /api/community/events/:id/rsvp/ | IsAuthenticated | IsTrainee | `trainer=user.parent_trainer` | OK |
| DELETE /api/community/events/:id/rsvp/ | IsAuthenticated | IsTrainee | `trainer=user.parent_trainer` | OK |

### Trainer Endpoints
| Endpoint | Auth | Permission | Scoping | Status |
|----------|------|------------|---------|--------|
| GET /api/trainer/events/ | IsAuthenticated | IsTrainer | `trainer=user` | OK |
| POST /api/trainer/events/ | IsAuthenticated | IsTrainer | Creates with `trainer=user` | OK |
| GET /api/trainer/events/:id/ | IsAuthenticated | IsTrainer | `trainer=user` | OK |
| PUT/PATCH /api/trainer/events/:id/ | IsAuthenticated | IsTrainer | `trainer=user` | OK |
| DELETE /api/trainer/events/:id/ | IsAuthenticated | IsTrainer | `trainer=user` | OK |
| PATCH /api/trainer/events/:id/status/ | IsAuthenticated | IsTrainer | `trainer=user` | OK |

## Positive Security Findings

1. **Row-level security consistently applied:** Every queryset filters by `trainer=user` or `trainer=user.parent_trainer`.
2. **DRF serializer validation:** `CommunityEventCreateSerializer` uses `ChoiceField` for event_type (prevents injection), `URLField` for meeting_url (validates URL format), `IntegerField(min_value=1)` for max_attendees.
3. **No raw SQL:** All queries use Django ORM.
4. **Error messages are generic:** Mobile provider catches `DioException` and shows user-friendly messages; backend returns generic error strings.
5. **Space ownership validated:** When associating an event with a space, the trainer's ownership of the space is verified.
6. **Status transitions via service layer:** `EventService.transition_status()` centralizes status changes, providing a single point of audit.

## Security Score: 8/10

The High-severity IDOR in `TrainerUnbanView` has been fixed. The Medium issues (reflected input, missing cancelled-event guard) have also been fixed. Remaining Low-severity items (user info in RSVP serializer, rate limiting) are acceptable for current usage patterns.

## Recommendation: PASS

All Critical and High issues have been resolved. The feature is safe to ship.

# Code Review: Session Feedback + Trainer Routing Rules — v6.5 Step 9

## Review Date

2026-03-10

## Files Reviewed

- `backend/workouts/models.py` (SessionFeedback, PainEvent, TrainerRoutingRule additions)
- `backend/workouts/services/feedback_service.py` (new)
- `backend/workouts/feedback_serializers.py` (new)
- `backend/workouts/feedback_views.py` (new)
- `backend/workouts/urls.py` (modified)
- `backend/workouts/migrations/0028_session_feedback.py` (new)

## Critical Issues (must fix before merge)

| #   | File:Line                   | Issue                                                                                                                                                                        | Suggested Fix                                                                                 |
| --- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| C1  | `feedback_views.py:105-113` | **Broken OneToOne existence check.** `hasattr(active_session, 'feedback')` always returns True for OneToOneField (it's a descriptor). The try/except pattern was convoluted. | Fixed: Replaced with `SessionFeedback.objects.filter(active_session=active_session).exists()` |

## Major Issues (should fix)

| #   | File:Line                     | Issue                                                                                                                                                                                      | Suggested Fix                                                      |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------ |
| M1  | `feedback_service.py:276-288` | **\_create_notification propagated DB exceptions.** If TrainerNotification.objects.create fails, the entire feedback submission would fail even though the feedback was already committed. | Fixed: Wrapped in try/except with logging, returns None on failure |
| M2  | `feedback_service.py:338-356` | **Standalone pain notification had no error handling.** Same issue as M1 for the log_pain_event path.                                                                                      | Fixed: Added try/except with logging                               |

## Minor Issues (nice to fix)

| #   | File:Line                   | Issue                                                                                   | Suggested Fix                                                                    |
| --- | --------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| m1  | `feedback_serializers.py`   | Uses ModelSerializer instead of rest_framework_dataclasses per project convention.      | Acceptable for model serializers; convention applies to API response dataclasses |
| m2  | `feedback_views.py:196-213` | PainEventViewSet.list duplicates pagination logic that ListModelMixin already provides. | Low priority — works correctly as-is                                             |

## Security Concerns

- All endpoints have IsAuthenticated permission
- Role enforcement correct: trainee-only for submit/log, trainer/admin for routing rules
- IDOR prevented: session ownership check via `trainee=user` in submit endpoint
- Cross-trainer protection on routing rule update/delete

## Performance Concerns

- select_related used properly in get_queryset methods
- Pagination enabled on list endpoints
- No N+1 patterns detected

## Quality Score: 8/10

## Recommendation: APPROVE

All critical and major issues have been fixed. The implementation is clean, follows project conventions, and handles edge cases properly.

# Dev Done: Step 9 — Session Feedback + Trainer Routing Rules

## Date

2026-03-10

## Files Created

1. **`backend/workouts/services/feedback_service.py`** (~446 lines) — Core feedback service:
   - `submit_feedback()` — Creates SessionFeedback + PainEvents in transaction, evaluates routing rules, creates TrainerNotifications, logs DecisionLog
   - `evaluate_routing_rules()` — Checks all active rules for a trainer against feedback/pain data
   - `_check_rule()` — Per-rule evaluation for 5 rule types (low_rating, pain_report, high_difficulty, recovery_concern, form_breakdown)
   - `_create_notification()` — Creates TrainerNotification with structured data payload
   - `log_pain_event()` — Standalone pain event + routing rule check
   - `get_feedback_history()`, `get_pain_history()` — Query helpers with select_related
   - `DEFAULT_ROUTING_RULES` — 5 default rule configs
   - `create_default_routing_rules()` — Idempotent trainer initialization

2. **`backend/workouts/feedback_serializers.py`** — Serializers:
   - `PainEventInputSerializer` — Input validation for pain events (17 body regions, pain_score 1-10, sensation_type, onset_phase, warmup_effect)
   - `PainEventSerializer` — Read serializer with exercise_name
   - `FeedbackRatingsSerializer` — Sub-object for 6 rating scales (1-5)
   - `SubmitFeedbackInputSerializer` — Full feedback input with friction_reasons validation
   - `SessionFeedbackSerializer` — Read serializer
   - `TrainerRoutingRuleSerializer` — CRUD with threshold_value JSON validation
   - `TrainerRoutingRuleListSerializer` — Lightweight list view

3. **`backend/workouts/feedback_views.py`** — 3 ViewSets:
   - `SessionFeedbackViewSet` — list + submit (POST /{session_pk}) + for-session (GET /{session_pk}). Trainee-only submission, ownership checks, duplicate prevention (409)
   - `PainEventViewSet` — list (body_region filter) + retrieve + log (POST). Trainee-only logging
   - `TrainerRoutingRuleViewSet` — Full ModelViewSet CRUD (trainer/admin only) + defaults (GET) + initialize (POST). Cross-trainer protection on update/delete

4. **`backend/workouts/migrations/0028_session_feedback.py`** — Migration for SessionFeedback, PainEvent, TrainerRoutingRule

## Files Modified

1. **`backend/workouts/models.py`** — Added 3 models:
   - `SessionFeedback`: OneToOneField→ActiveSession, 6 nullable rating fields (1-5), completion_state enum, friction_reasons JSONField, recovery_concern bool, notes
   - `PainEvent`: 17 BodyRegion choices, 4 Side choices, pain_score 1-10, 7 SensationType choices, 5 OnsetPhase choices, 3 WarmupEffect choices
   - `TrainerRoutingRule`: 6 rule_type choices, threshold_value JSON, notification_method (in_app/email/both), unique_together (trainer, rule_type)

2. **`backend/workouts/urls.py`** — Registered 3 routes: session-feedback, pain-events, routing-rules

## API Endpoints

- `POST /api/workouts/session-feedback/submit/{session_pk}/` — Submit feedback
- `GET /api/workouts/session-feedback/for-session/{session_pk}/` — Get feedback for session
- `GET /api/workouts/session-feedback/` — List feedback (role-filtered)
- `POST /api/workouts/pain-events/log/` — Log standalone pain event
- `GET /api/workouts/pain-events/` — List (body_region filter)
- `GET /api/workouts/pain-events/{id}/` — Retrieve
- `CRUD /api/workouts/routing-rules/` — Trainer routing rules
- `GET /api/workouts/routing-rules/defaults/` — Default templates
- `POST /api/workouts/routing-rules/initialize/` — Create defaults for trainer

## Key Design Decisions

1. SessionFeedback uses OneToOneField → single feedback per session enforced at DB level
2. PainEvent is a separate model (not embedded JSON) for queryability and history
3. Routing rule evaluation runs outside the main transaction — notification side effects shouldn't roll back feedback creation
4. TrainerRoutingRule uses unique_together(trainer, rule_type) — one rule per type per trainer
5. `create_default_routing_rules()` is idempotent — checks existing types before creating

## How to Test

```bash
cd backend && python manage.py check
cd backend && python manage.py migrate

# Submit feedback (trainee auth required)
POST /api/workouts/session-feedback/submit/{session_pk}/
{"completion_state": "completed_all", "ratings": {"overall": 4, "difficulty": 3}, "friction_reasons": [], "recovery_concern": false, "notes": "Great session"}

# Log pain event
POST /api/workouts/pain-events/log/
{"body_region": "knee", "pain_score": 7, "side": "left", "sensation_type": "sharp"}

# Initialize default routing rules (trainer auth)
POST /api/workouts/routing-rules/initialize/
```

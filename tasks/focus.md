# Focus: Trainer Packet v6.5 — Step 9: End-of-Session Feedback + Trainer Routing Rules

## Priority

Critical — Step 9 of the v6.5 build order. Closes the feedback loop: trainee rates their session, reports pain, and the system automatically routes alerts to their trainer based on configurable rules.

## What to Build

### 1. SessionFeedback Model

- Links to ActiveSession (one feedback per session)
- completion_state, 6 rating scales (1-5), friction_reasons JSON, recovery_concern boolean, notes

### 2. PainEvent Model

- Trainee pain/discomfort tracking: body_region, side, pain_score (1-10), sensation_type, onset_phase, warmup_effect

### 3. TrainerRoutingRule Model

- Configurable alert rules: low_rating, pain_report, missed_sessions, high_difficulty, recovery_concern
- Threshold values, notification method, is_active flag

### 4. Feedback Service

- submit_feedback → evaluates routing rules → creates trainer notifications
- Pain event logging, feedback/pain history queries

### 5. API Endpoints

- POST/GET /sessions/{id}/feedback/
- CRUD /pain-events/
- CRUD /trainer-routing-rules/
- GET /trainer-routing-rules/defaults/

## What NOT to Build

- Mobile UI (separate step)
- AI-powered feedback analysis
- Push notifications (use existing TrainerNotification model)

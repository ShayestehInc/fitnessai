# Focus: Trainer Packet v6.5 — Step 8: Client Session Runner (Backend Only)

## Priority

Critical — Step 8 of the v6.5 build order. The session runner is the runtime engine that a trainee interacts with during a workout. Without it, the progression engine (Step 7) has no live data source.

## What to Build

### 1. ActiveSession + ActiveSetLog Models

- ActiveSession tracks an in-progress workout for a trainee, linked to a PlanSession
- ActiveSetLog tracks per-set data (weight, reps, RPE, rest time, timestamps) within an active session
- Only one active session per trainee at a time

### 2. Session Runner Service

- start_session, log_set, skip_set, complete_session, abandon_session
- get_current_prescription integrates with progression engine for next-set guidance
- get_session_status returns full progress overview
- complete_session triggers LiftSetLog creation + progression evaluation

### 3. Rest Timer Service

- Compute rest durations based on slot_role and modality
- Default rest times: primary_compound=180s, secondary_compound=120s, isolation=90s, accessory=60s
- Modality overrides (e.g., cluster sets get shorter rest between clusters)

### 4. API Endpoints

- POST /sessions/start/ — start a session
- GET /sessions/{id}/status/ — current session status with prescription
- POST /sessions/{id}/log-set/ — log a completed set
- POST /sessions/{id}/skip-set/ — skip current set
- POST /sessions/{id}/complete/ — complete session
- POST /sessions/{id}/abandon/ — abandon session
- GET /sessions/active/ — get trainee's active session (if any)

## What NOT to Build

- Mobile/Flutter session runner UI (separate step)
- End-of-session feedback page (Step 9)
- Pain event tracking (separate step)
- Real-time WebSocket push (defer — polling is fine for now)

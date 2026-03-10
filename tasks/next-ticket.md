# Feature: Client Session Runner (Backend Only)

## Priority

Critical — Step 8 of v6.5 build order. The session runner is the runtime bridge between the training plan and actual performance data. Without it, progressions are theoretical and LiftSetLog entries must be created manually.

## User Story

As a **trainee**, I want to start a workout session from my plan and be guided through each exercise/set with prescribed load/reps, log my actual performance set-by-set, and have rest timers computed for me, so that my workout is structured and my data is captured accurately.

As a **trainer**, I want my trainee's session data to flow automatically into the progression engine so that their next workout is adjusted based on real performance without my manual intervention.

## Acceptance Criteria

### Models

- [ ] `ActiveSession` model with fields: id (UUID PK), trainee FK, plan_session FK, status (not_started/in_progress/completed/abandoned), started_at, completed_at, abandoned_at, abandon_reason, current_slot_index (int), notes, created_at, updated_at
- [ ] `ActiveSetLog` model with fields: id (UUID PK), active_session FK, plan_slot FK, exercise FK, set_number (1-based), prescribed_load, prescribed_reps_min, prescribed_reps_max, prescribed_load_unit, completed_load_value, completed_load_unit, completed_reps, rpe, rest_prescribed_seconds, rest_actual_seconds, set_started_at, set_completed_at, status (pending/completed/skipped), skip_reason, notes, created_at
- [ ] Only ONE active session (status=in_progress) per trainee at a time — enforced by DB constraint + service validation
- [ ] ActiveSession.current_slot_index defaults to 0 (first slot)
- [ ] ActiveSetLog.status choices: pending, completed, skipped

### Session Runner Service (`session_runner_service.py`)

- [ ] `start_session(trainee, plan_session_id)` — creates ActiveSession, pre-populates ActiveSetLog rows (status=pending) for every set of every slot using progression engine prescriptions, returns ActiveSession with full status
- [ ] `get_current_prescription(active_session)` — returns the next pending set's prescription (exercise name, set number, load, reps, rest time) by reading ActiveSetLog rows in order
- [ ] `log_set(active_session_id, set_data)` — marks current pending ActiveSetLog as completed with actual performance, auto-advances to next pending set, returns updated status
- [ ] `skip_set(active_session_id, reason)` — marks current pending ActiveSetLog as skipped with reason, advances to next, returns updated status
- [ ] `complete_session(active_session_id)` — validates all sets completed/skipped, marks session completed, creates LiftSetLog entries from completed ActiveSetLogs, triggers progression engine evaluation for each slot, returns session summary
- [ ] `abandon_session(active_session_id, reason)` — marks session abandoned, saves any completed sets to LiftSetLog, does NOT trigger progression evaluation, returns summary
- [ ] `get_session_status(active_session_id)` — returns full session state: overall progress (X of Y sets done), per-slot progress, current prescription, elapsed time
- [ ] `get_active_session(trainee_id)` — returns the in_progress session or None
- [ ] All methods enforce row-level security (trainee can only access their own sessions)
- [ ] All state transitions logged via DecisionLog

### Rest Timer Service (`rest_timer_service.py`)

- [ ] `get_rest_duration(plan_slot, set_number)` — returns rest seconds
- [ ] Default rest by slot_role: primary_compound=180, secondary_compound=120, isolation=90, accessory=60
- [ ] If PlanSlot.rest_seconds is set (non-default), use it as override
- [ ] If PlanSlot has a set_structure_modality with rest rules in modality_details, use those
- [ ] Between exercises (last set of slot N to first set of slot N+1), add 30s bonus rest
- [ ] Returns a RestPrescription dataclass: rest_seconds, source (slot_default/slot_role_default/modality_override/trainer_override), is_between_exercises

### API Endpoints

- [ ] `POST /api/workouts/sessions/start/` — body: `{plan_session_id: UUID}` — returns full session status
- [ ] `GET /api/workouts/sessions/{id}/status/` — returns full session state
- [ ] `POST /api/workouts/sessions/{id}/log-set/` — body: `{load_value, load_unit, completed_reps, rpe, rest_actual_seconds, notes}` — returns updated status
- [ ] `POST /api/workouts/sessions/{id}/skip-set/` — body: `{reason}` — returns updated status
- [ ] `POST /api/workouts/sessions/{id}/complete/` — returns session summary with progression results
- [ ] `POST /api/workouts/sessions/{id}/abandon/` — body: `{reason}` — returns summary
- [ ] `GET /api/workouts/sessions/active/` — returns active session or 404
- [ ] All endpoints require authentication (JWT)
- [ ] All endpoints enforce trainee-only access (403 for trainer/admin unless impersonating)
- [ ] 409 Conflict if starting a session when one is already in_progress
- [ ] 400 Bad Request if logging a set on a completed/abandoned session
- [ ] 404 if session belongs to different trainee

### Integration with Progression Engine

- [ ] On start_session: call `compute_next_prescription(slot, trainee_id)` for each PlanSlot to pre-fill prescribed load/reps into ActiveSetLog rows
- [ ] On complete_session: for each slot with completed sets, create LiftSetLog entries and then call `apply_progression(slot, ...)` to advance the progression state
- [ ] Progression evaluation uses only completed sets (not skipped) when determining if criteria are met

### Serializers

- [ ] `ActiveSessionSerializer` — full session with nested set logs, using `rest_framework_dataclasses` per project conventions
- [ ] `ActiveSetLogSerializer` — individual set log
- [ ] `SessionStatusSerializer` — response format for status endpoint: overall_progress, slots_progress, current_prescription, elapsed_seconds
- [ ] `LogSetRequestSerializer` — validates log-set input
- [ ] `StartSessionRequestSerializer` — validates plan_session_id
- [ ] `SessionSummarySerializer` — response for complete/abandon: total_sets, completed_sets, skipped_sets, duration_seconds, progression_results[]

## Edge Cases

1. **Trainee starts a session while another is in_progress** — Return 409 Conflict with message "You have an active session. Complete or abandon it first." Include the active session ID in the error response so the client can resume it.

2. **Trainee tries to log a set on a completed/abandoned session** — Return 400 Bad Request. Session is immutable after completion.

3. **All sets for a slot are skipped** — Do NOT create LiftSetLog entries for that slot. Do NOT trigger progression evaluation for that slot. Mark the slot as fully_skipped in the session summary.

4. **PlanSession has zero slots** — Return 400 Bad Request on start_session. A session with no exercises cannot be started.

5. **PlanSlot's exercise has no LiftMax and no progression profile** — Prescription falls back to PlanSlot's base prescription (sets/reps_min/reps_max). Load is null. This is valid — the trainee enters their own load when logging.

6. **Trainee abandons mid-session with some sets completed** — Save completed sets to LiftSetLog (they count as real data). Pending and skipped sets are NOT saved. Do not run progression evaluation (abandonment signals something went wrong).

7. **Network disconnection / stale session** — ActiveSessions older than 4 hours with status=in_progress should be considered stale. Add a `check_stale_sessions(trainee_id)` helper that auto-abandons sessions older than 4 hours when start_session or get_active_session is called. Reason: "auto_abandoned_stale".

8. **Concurrent API calls (race condition)** — Use `select_for_update()` when transitioning session status or logging sets. Prevent double-logging the same set number via DB unique constraint on (active_session, plan_slot, set_number).

9. **PlanSlot has a superset modality** — When PlanSlot.set_structure_modality indicates a superset, the ActiveSetLog rows should be interleaved (A1, B1, A2, B2 pattern). The paired_exercise_id from modality_details identifies the partner. Rest timer uses modality-specific rules (shorter rest between superset partners, full rest after the pair).

10. **Trainee logs a set with zero reps** — Valid (represents a failed attempt). The set is marked completed with 0 reps. This counts as a failure for progression evaluation purposes.

11. **Plan or PlanSession is deleted/archived while session is in_progress** — The ActiveSession keeps its FK references. The session can still be completed or abandoned. Use on_delete=SET_NULL on plan_session FK with null=True so the session survives.

## Error States

| Trigger                              | User Sees                                                            | System Does                   |
| ------------------------------------ | -------------------------------------------------------------------- | ----------------------------- |
| Start with active session exists     | 409 `{"error": "active_session_exists", "active_session_id": "..."}` | Return existing session ID    |
| Start with invalid plan_session_id   | 404 `{"error": "plan_session_not_found"}`                            | Validate FK                   |
| Start with 0-slot PlanSession        | 400 `{"error": "no_exercises_in_session"}`                           | Check slots count             |
| Log set on completed session         | 400 `{"error": "session_already_completed"}`                         | Reject mutation               |
| Log set on abandoned session         | 400 `{"error": "session_already_abandoned"}`                         | Reject mutation               |
| Log set with no pending sets         | 400 `{"error": "no_pending_sets"}`                                   | All sets done                 |
| Skip set with no pending sets        | 400 `{"error": "no_pending_sets"}`                                   | All sets done                 |
| Complete with pending sets remaining | 400 `{"error": "pending_sets_remaining", "count": N}`                | Force skip or log first       |
| Access another trainee's session     | 404 (opaque)                                                         | Filter by trainee in queryset |
| Stale session auto-abandoned         | Session returned with status=abandoned, reason=auto_abandoned_stale  | Transparent to user           |

## UX Requirements (API response design — no UI)

- **Status response:** Must include everything the mobile client needs in a SINGLE call: current exercise name, set number, prescribed load/reps/rest, overall progress fraction, per-slot completion status, elapsed time since session start.
- **Log-set response:** Returns the updated status (same shape as GET status) so the client doesn't need a separate GET call.
- **Complete response:** Returns a summary object with total duration, sets completed/skipped, and a list of progression results (one per slot that was evaluated).
- **Error responses:** Always include an `error` code string (machine-readable) AND a `message` string (human-readable).

## Technical Approach

### Files to Create

- `backend/workouts/models.py` — Add ActiveSession and ActiveSetLog models (append to existing file)
- `backend/workouts/services/session_runner_service.py` — Session Runner Service (new file)
- `backend/workouts/services/rest_timer_service.py` — Rest Timer Service (new file)
- `backend/workouts/session_views.py` — ViewSet for session endpoints (new file, keeps views.py clean)
- `backend/workouts/session_serializers.py` — Serializers for session request/response (new file)
- `backend/workouts/migrations/XXXX_add_active_session_models.py` — Auto-generated migration

### Files to Modify

- `backend/workouts/urls.py` — Register session endpoints
- `backend/workouts/views.py` — Import session views (or use separate include)

### Key Design Decisions

1. **Pre-populate all ActiveSetLog rows on start** — When a session starts, create one ActiveSetLog per prescribed set per slot. This makes the "what's next" query trivial (first pending row) and prevents ordering ambiguity. The mobile client just walks through rows in order.

2. **Separate ActiveSetLog from LiftSetLog** — ActiveSetLog is ephemeral runtime state. LiftSetLog is permanent performance record. On complete_session, we copy completed ActiveSetLogs into LiftSetLogs. This keeps the LiftSetLog table clean (no half-finished sessions) and lets us safely delete old ActiveSessions.

3. **Dataclass return types** — All service functions return frozen dataclasses, never dicts. Consistent with progression_engine_service.py patterns.

4. **select_for_update on status transitions** — Prevents race conditions when completing/abandoning sessions or logging concurrent sets.

5. **Stale session cleanup is lazy** — No cron job. Stale sessions are cleaned up when the trainee next calls start_session or get_active_session. Simple and sufficient for current scale.

### Dependencies

- Progression Engine Service (Step 7) — `compute_next_prescription()`, `apply_progression()`
- LiftSetLog model — target for completed set data
- PlanSession / PlanSlot models — source of the workout template
- DecisionLog model — audit trail

### Migration Notes

- ActiveSession and ActiveSetLog are new tables (no data migration needed)
- FK to PlanSession uses SET_NULL so sessions survive plan changes
- Unique constraint on (trainee, status) WHERE status='in_progress' — partial unique index ensures only one active session per trainee

## Out of Scope

- Mobile/Flutter session runner UI
- End-of-session feedback page (Step 9)
- Pain event tracking / PainTriage
- Real-time WebSocket push for rest timer countdown
- Session templates / session history listing
- Superset interleaving (note: model supports it, but the interleaving logic is deferred to UI step)
- Warm-up set generation

# Changelog

All notable changes to the FitnessAI platform are documented in this file.

---

## [2026-03-10] — Pipeline 72: v6.5 Step 15 (Analytics + Correlations)

### Added

- Backend: Correlation analytics service — Pearson r computation for cross-metric correlations (protein↔strength, sleep↔volume, calorie↔workout, food↔workout logging)
- Backend: Pattern detection — 5 insight types: high_adherence, low_protein_adherence, volume_plateau, overtraining_risk, sleep_declining
- Backend: Cohort comparison — high vs low adherence cohort analysis across weekly volume, protein adherence, workout consistency
- Backend: Exercise progression tracking — e1RM history analysis with gaining/plateau/declining trend classification
- Backend: 3 API endpoints: GET /analytics/correlations/, GET /analytics/trainee/{id}/patterns/, GET /analytics/cohort/
- Backend: 22 tests (Pearson correlation unit tests, service tests, API endpoint tests)

---

## [2026-03-10] — Pipeline 71: v6.5 Step 14 (Voice Memo Parsing + Video Analysis)

### Added

- Backend: VoiceMemo model — audio file storage, Whisper transcription, NLP parsing pipeline with status lifecycle
- Backend: VideoAnalysis model — video upload, GPT-4o Vision exercise form analysis, rep counting, form scoring
- Backend: Voice memo service — upload validation (MP3/WAV/M4A/WebM, 25MB max), OpenAI Whisper transcription, auto-parse via NLP
- Backend: Video analysis service — upload validation (MP4/MOV/WebM, 50MB max), frame extraction via ffmpeg, GPT-4o Vision analysis, exercise library matching
- Backend: Video analysis prompt for GPT-4o Vision — exercise detection, rep count, form score (0-10), specific observations
- Backend: DecisionLog on video analysis confirmation
- Backend: 7 API endpoints: 3 for voice memos (upload, list, detail), 4 for video analysis (upload, list, detail, confirm)
- Backend: 24 tests with mocked AI covering both services and all API endpoints

---

## [2026-03-10] — Pipeline 70: v6.5 Step 13 (Auto-tagging Pipeline)

### Added

- Backend: ExerciseTagDraft model — AI-generated tag suggestions with confidence scores, reasoning, retry tracking
- Backend: Auto-tagging service — GPT-4o generates v6.5 ExerciseCard tags (pattern_tags, muscle groups, stance, plane, ROM bias, equipment, athletic tags)
- Backend: AI response validation — filters invalid enum values, normalizes muscle_contribution_map to sum=1.0
- Backend: Draft/edit/retry workflow — trainers can edit AI suggestions, retry for new attempt, apply atomically with version increment
- Backend: DecisionLog + UndoSnapshot on tag application for full auditability
- Backend: 7 API endpoints: request auto-tag, get/edit draft, apply, reject, retry, tag history
- Backend: 22 tests with mocked AI covering service layer, validation, and API
- Backend: Added PLAN scope to UndoSnapshot for program imports

### Fixed

- Backend: Removed invalid `decision_log` FK kwarg from UndoSnapshot creation in import service

---

## [2026-03-10] — Pipeline 69: v6.5 Step 12 (Import Pipeline — Draft/Confirm)

### Added

- Backend: ProgramImportDraft model — UUID PK, status lifecycle (pending_review/confirmed/rejected/expired), raw CSV storage, parsed data, validation errors/warnings
- Backend: CSV import service — parse & validate CSV, case-insensitive exercise lookup, row-level validation with detailed error messages
- Backend: Atomic confirm — creates TrainingPlan → PlanWeek → PlanSession → PlanSlot hierarchy + DecisionLog + UndoSnapshot
- Backend: 5 API endpoints: POST upload, GET list, GET detail, POST confirm, DELETE reject
- Backend: 24 tests covering CSV parsing (10), confirm import (4), draft management (5), API endpoints (9)

---

## [2026-03-10] — Pipeline 68: v6.5 Step 11 (Trainer Copilot + Daily Digest)

### Added

- Backend: DailyDigest model — per-trainer daily summary with aggregated metrics, highlights, concerns, action items
- Backend: DigestPreference model — configurable delivery settings (method, hour, timezone, content toggles)
- Backend: Daily digest service — aggregates TraineeActivitySummary, pain events, recovery concerns into structured digest
- Backend: Message drafting service — 5 template types (encouragement, check_in, missed_workout, pain_follow_up, goal_update)
- Backend: 5 new API endpoints: POST generate digest, GET history, GET/PATCH preferences, GET detail (auto-marks read), POST draft message
- Backend: 20 tests covering digest generation, preferences, history, message drafting, API endpoints

---

## [2026-03-10] — Pipeline 67: v6.5 Step 10 (Food Swap Engine + Nutrition DecisionLog)

### Added

- Backend: Food swap recommendation engine — 3 modes: same_macros (calorie-normalized P/C/F similarity), same_category (name matching), explore (diverse alternatives)
- Backend: Food swap execution — replaces MealLogEntry food item with UndoSnapshot for reversal
- Backend: CARB_CYCLING template type — Mifflin-St Jeor BMR × activity multiplier, 3 day types (high_carb: 40P/40C/20F, medium: 40P/30C/30F, low_carb: 45P/15C/40F)
- Backend: Nutrition DecisionLog — plan generation decisions now logged with inputs/outputs
- Backend: 2 new API endpoints: GET /food-items/{id}/swaps/, POST /meal-logs/entries/{id}/swap/
- Backend: 25 tests covering similarity scoring, swap recommendations, swap execution, carb cycling

---

## [2026-03-10] — Pipeline 66: v6.5 Step 9 (Session Feedback + Trainer Routing Rules)

### Added

- Backend: SessionFeedback model — end-of-session feedback with 6 rating scales (1-5), completion_state, friction_reasons JSON, recovery_concern, notes. OneToOneField to ActiveSession
- Backend: PainEvent model — pain/discomfort tracking with 17 body regions, pain_score (1-10), sensation_type, onset_phase, warmup_effect. Can be standalone or linked to a session
- Backend: TrainerRoutingRule model — configurable alert rules (low_rating, pain_report, high_difficulty, recovery_concern, form_breakdown, missed_sessions) with threshold_value JSON and notification_method
- Backend: Feedback service — submit_feedback evaluates routing rules and creates TrainerNotifications when thresholds exceeded. Standalone pain event logging with rule evaluation
- Backend: 9 API endpoints: POST submit feedback, GET feedback for session, GET list feedback, POST log pain event, GET list/retrieve pain events, CRUD routing rules, GET defaults, POST initialize
- Backend: Default routing rule initialization (5 rules) for trainers, idempotent
- Backend: 30 comprehensive tests covering service, serializer, and API layers

### Security

- Role enforcement: trainee-only for feedback submission and pain logging, trainer/admin for routing rule CRUD
- IDOR prevention: session ownership check on feedback submission
- Cross-trainer protection on routing rule update/delete
- Notification creation failure handling (does not roll back feedback)

---

## [2026-03-09] — Pipeline 65: v6.5 Step 8 (Client Session Runner — Backend)

### Added

- Backend: ActiveSession model — tracks in-progress workout sessions with status lifecycle (not_started → in_progress → completed/abandoned). UUID PK, partial unique constraint for one-active-per-trainee
- Backend: ActiveSetLog model — per-set tracking during active sessions with prescribed vs actual values, skip reasons, timestamps
- Backend: Session runner service — full session lifecycle (start, log_set, skip_set, complete, abandon, get_status, get_active). Pre-populates set prescriptions from progression engine. Auto-creates LiftSetLog records on complete/abandon. Triggers progression evaluation on completion
- Backend: Rest timer service — computes rest durations by slot_role (180/120/90/60s) with modality overrides (myo_reps=20s, drop_sets=10s) and between-exercise bonus (+30s)
- Backend: 8 API endpoints: POST start, GET status, POST log-set, POST skip-set, POST complete, POST abandon, GET active, GET list (with pagination)
- Backend: Stale session auto-abandon (>4hr) with race-safe select_for_update
- Backend: 48 comprehensive tests

### Security

- Trainee-only role enforcement on session mutations (PermissionDenied for trainers/admins)
- IDOR protection: PlanSession ownership verified via plan→week→session chain
- select_for_update on all session mutations to prevent race conditions
- Stale cleanup wrapped in transaction.atomic with select_for_update

---

## [2026-03-09] — Pipeline 64: v6.5 Step 7 (Progression Engine — Staircase + Wave + Deload)

### Added

- Backend: ProgressionProfile model — 5 progression types (Staircase Percent, Rep Staircase, Double Progression, Linear, Wave-by-Month) with rules, deload_rules, failure_rules JSON configs. UUID PK, is_system flag
- Backend: ProgressionEvent model — audit trail for every progression decision, linked to DecisionLog and ProgressionProfile
- Backend: TrainingPlan.default_progression_profile FK (plan-level default)
- Backend: PlanSlot.progression_profile FK (slot-level override, falls back to plan default)
- Backend: Progression engine service — 5 deterministic evaluators with gap detection (>14 days → 90% TM deload), consecutive failure detection, scheduled deload weeks, dynamic load unit resolution
- Backend: 4 PlanSlot actions: next-prescription (GET), apply-progression (POST, trainer/admin only), progression-readiness (GET), progression-history (GET)
- Backend: ProgressionProfile CRUD ViewSet with role-based security (system profiles admin-only)
- Backend: PlanSlot serializer now includes progression_profile info (name, type)
- Backend: seed_progression_profiles management command — 5 system profiles with full rule configs
- Backend: 73 comprehensive tests covering all evaluators, edge cases, role-based access

### Security

- Trainees blocked from apply-progression (trainer/admin only action)
- Row-level security on ProgressionProfileViewSet (system + trainer-scoped visibility)
- PlanSlot actions inherit queryset-level IDOR protection
- DecisionLog audit trail with explicit actor_type (user vs system)

### Fixed

- Staircase percent off-by-one: first work week now correctly uses start_pct
- Wave-by-month cycle counter now only counts progression/deload events (not hold/failure)
- load_prescription_pct unconditionally cleared when switching from percent-based to absolute-load profiles
- Dynamic load unit resolution from LiftMax/LiftSetLog (no more hardcoded 'lb')

---

## [2026-03-09] — Pipeline 63: v6.5 Step 6 (Modality Library with Counting Rules and Guardrails)

### Added

- Backend: SetStructureModality model — 8 system modalities (Straight Sets, Down Sets, Controlled Eccentrics, Giant Sets, Myo-reps, Drop Sets, Supersets, Occlusion) with volume multipliers from v6.5 packet
- Backend: ModalityGuardrail model — configurable rule engine with condition_field/operator/value pattern supporting 6 operators (has_any, has_none, gt, lt, eq, in)
- Backend: PlanSlot modality fields — set_structure_modality FK, modality_details JSON, modality_volume_contribution Decimal (backward compatible)
- Backend: Modality service — guardrail validation, ranked recommendations by goal/slot_role, volume computation, apply with UndoSnapshot + DecisionLog
- Backend: A5 generator enhancement — default modality assignment during plan generation based on goal + slot_role table, deload weeks force Straight Sets
- Backend: Session volume summary — per-muscle volume aggregation with modality multipliers
- Backend: API endpoints: modalities CRUD, plan-slots modality-recommendations/set-modality, plan-sessions volume-summary
- Backend: seed_modalities management command — idempotent seeding of 8 modalities + 5 guardrails

### Security

- Row-level security on all new ViewSets (modalities, plan-sessions)
- Modality IDOR prevention: visibility_q scoping on set-modality action
- Trainee guardrail override restriction (403 for trainees)
- Prefetch with filtered guardrails to avoid information leakage

### Performance

- Prefetched system modalities once during pipeline (dict lookup, zero per-slot queries)
- Filtered Prefetch on guardrails (avoids re-hitting DB for active guardrail filtering)
- Session volume summary uses single query with select_related

---

## [2026-03-09] — Pipeline 62: v6.5 Step 5 (Training Generator Pipeline + Swap System)

### Added

- Backend: Relational plan hierarchy — TrainingPlan → PlanWeek → PlanSession → PlanSlot (replaces flat Program.schedule JSON)
- Backend: SplitTemplate model — reusable split definitions with session_definitions JSON, cross-field validation
- Backend: 7-step deterministic generator pipeline (A1-A7) with DecisionLog at each step
- Backend: SlotSpec in-memory specification pattern — no premature DB writes during pipeline construction
- Backend: Per-week exercise variety (used_ids resets per week, not globally)
- Backend: In-memory swap recommendation computation (zero per-slot DB queries in A7)
- Backend: Exercise pool shared between A6 and A7 (single prefetch)
- Backend: 3-tab swap system — Same Muscle, Same Pattern, Explore All with pre-computed candidates
- Backend: Swap execution with DecisionLog + UndoSnapshot for audit trail and undo support
- Backend: Plan lifecycle: draft → active → completed/archived with single-active enforcement
- Backend: API endpoints: training-plans CRUD, generate, activate, archive; plan-slots retrieve/update/swap-options/swap; split-templates CRUD

### Security

- Privacy-filtered swap candidates (privacy_q applied even on cached IDs)
- Privacy check on swap execution (new exercise must be public or trainer-owned)
- Trainee write restriction on SplitTemplate CRUD
- IDOR prevention: parent_trainer_id null guard on trainee SplitTemplate queryset
- Row-level security on all new ViewSets

### Performance

- List queryset: annotated weeks_count (no N+1), no deep prefetch
- Detail queryset: full hierarchy prefetch for nested serializer
- A7: fully in-memory swap computation from shared exercise pool

---

## [2026-03-09] — Pipeline 61: v6.5 Step 4 (Workload Engine)

### Added

- Backend: WorkloadAggregationService — computes exercise, session, and weekly workload totals from LiftSetLog data
- Backend: Workload-by-muscle-group distribution using Exercise.muscle_contribution_map (single-pass with pattern distribution)
- Backend: Workload-by-pattern distribution using Exercise.pattern_tags
- Backend: WorkloadTrendService — acute:chronic workload ratio (7d/28d), spike/dip detection, week-over-week deltas, trend direction
- Backend: WorkloadFactService — deterministic cool fact selection from template library with safe regex-based rendering
- Backend: WorkloadFactTemplate model — scoped (exercise/session), priority-based, condition rules, trainer-manageable
- Backend: Mixed units detection flag on exercise and session workload responses
- Backend: Comparable session/exercise matching for delta comparisons
- Backend: API endpoints: exercise workload, session workload summary, weekly breakdown, trends with ACWR

### Security

- Template injection prevention: regex-based substitution (no Python attribute access via format specs)
- Fact templates scoped by trainer: system defaults + trainer's own (no cross-tenant leakage)
- Bounded template evaluation (max 50) to prevent DoS
- Row-level security on all workload endpoints
- Trainer ownership checks on CRUD for fact templates

---

## [2026-03-09] — Pipeline 60: v6.5 Step 3 (LiftSetLog + LiftMax + Max/Load Engine)

### Added

- Backend: LiftSetLog model — per-set performance tracking with UUID PK, auto-computed canonical load (per-hand entries doubled), auto-computed workload (load × reps), load entry modes (total/per-hand/bodyweight+external), RPE tracking, standardization pass gate
- Backend: LiftMax model — per-exercise per-trainee cached e1RM and Training Max with history arrays (capped at 200 entries), unique constraint on (trainee, exercise)
- Backend: MaxLoadService — e1RM estimation (conservative: lower of Epley/Brzycki), e1RM smoothing (max ±15%/10% per update), TM calculation (80-100% of e1RM), load prescription with equipment rounding, auto-update from qualifying sets with `select_for_update()` concurrency protection
- Backend: LiftSetLog API — Create + List + Retrieve (no update/delete — historical records), filtering by exercise, date, date range, trainee
- Backend: LiftMax API — Read-only with pagination, history endpoint (GET /history/?exercise_id=), load prescription endpoint (POST /prescribe/)
- Backend: `prescribe_for_trainee` service method — encapsulates full prescription flow with unit resolution
- Backend: Proper indexes — composite indexes on (trainee, session_date), (trainee, exercise), (exercise, session_date), unique constraint on (trainee, exercise, session_date, set_number)

### Security

- Row-level security on all endpoints — trainees see own data, trainers see their trainees', admins see all
- LiftSetLog is create+read only — no update/delete to prevent tampering with historical performance data
- `standardization_pass` and `workload_eligible` are read-only in serializer — clients cannot bypass standardization gates
- `standardization_pass` defaults to False (fail-closed) — sets must be explicitly marked as passing
- `trainee_id` in prescribe endpoint validated through serializer (not raw request.data)
- Trainer row-level check on prescribe — trainers can only prescribe for their own trainees

### Edge Cases Handled

- 0 reps → e1RM = 0 (no update)
- RPE=10 with 1 rep → weight IS the 1RM (no formula)
- > 15 reps → capped at 15 for estimation accuracy
- Per-hand entry → canonical load doubled
- Bodyweight+external → canonical is just external portion
- No existing LiftMax → auto-created on first qualifying set
- e1RM smoothing prevents wild swings (±15%/10% caps)
- No LiftMax for exercise → prescribe returns null with reason

---

## [2026-03-09] — Pipeline 59: v6.5 Foundation (ExerciseCard Tags + DecisionLog + UndoSnapshot)

### Added

- Backend: ExerciseCard v6.5 enrichment — 16 new fields on Exercise model: `pattern_tags`, `athletic_skill_tags`, `athletic_attribute_tags`, `muscle_contribution_map`, `primary_muscle_group`, `secondary_muscle_groups`, `stance`, `plane`, `rom_bias`, `equipment_required`, `equipment_optional`, `athletic_constraints`, `standardization_block`, `swap_seed_ids`, `aliases`, `version`
- Backend: Full tag taxonomy from Trainer Packet v6.5 — 16 pattern tags, 19 athletic skill tags, 10 athletic attribute tags, 21 detailed muscle groups, 13 stances, 4 planes, 4 ROM biases
- Backend: DecisionLog model — UUID PK, actor tracking, full decision trail (inputs_snapshot, constraints_applied, options_considered, final_choice, reason_codes), override tracking, undo support
- Backend: UndoSnapshot model — full before/after state snapshots, scope-based (slot/session/week/exercise/nutrition_day), revert tracking
- Backend: DecisionLogService — `log_decision()` and `undo_decision()` with `@transaction.atomic`, returns frozen `DecisionResult` dataclass
- Backend: DecisionLog API — GET list/detail with filtering (decision_type, actor_type, date range), POST undo endpoint
- Backend: Exercise tag-based filtering — pattern_tags (overlap), stance, plane, rom_bias, primary_muscle_group, equipment_required
- Backend: `backfill_exercise_tags` management command — maps legacy muscle_group to v6.5 tags using name heuristics, bulk_update with iterator
- Backend: GIN index on pattern_tags for efficient overlap queries
- Backend: Serializer validation — muscle_contribution_map sum-to-1.0, pattern/skill/attribute tag choices validation

### Security

- Row-level security on DecisionLog — trainers see only their trainees' decisions, trainees see only their own
- IDOR protection on undo endpoint — verifies decision is in user's queryset scope before allowing undo
- Exercise creation restricted to trainers (custom) and admins (public) — trainees blocked
- `is_public` and `created_by` on Exercise are read-only in serializer

---

## [2026-03-09] — Pipeline 58: Progress Photos

### Added

- Web: Full progress photos UI — photo grid with date grouping, category filter (All/Front/Side/Back/Other), pagination, upload dialog with drag-and-drop, photo detail dialog with delete confirmation, side-by-side comparison view with measurement diffs
- Web: Progress photos tab on trainee detail page (trainer read-only view)
- Web: Progress photos section on trainee progress page
- Backend: Server-side photo upload validation (JPEG/PNG/WebP, 10MB limit), measurements allowlist with range checks, notes length limit
- Backend: Admin role support in ProgressPhotoViewSet, orphaned file cleanup on delete, optimized compare endpoint
- Mobile: Fixed category tabs (was showing 4x "All"), added "Other" category
- Mobile: Family provider pattern for trainee-scoped photo state (fixes global state leak)
- Mobile: Fixed ComparisonScreen to respect trainee_id parameter
- Tests: 38 comprehensive backend tests covering CRUD, permissions, IDOR prevention, filtering, pagination, edge cases
- i18n: Progress photos translations for en/es/pt-BR

### Fixed

- Auth bypass: trainers could previously create/update/delete photos via direct API calls
- IDOR: trainers could view photos of trainees not assigned to them
- Measurements encoding: mobile was sending `{waist: 75.0}` string instead of JSON
- Compare endpoint crash on non-numeric photo IDs
- Web comparison view stale state across dialog open/close cycles
- Web upload dialog memory leak (unreleased object URLs)

### Security

- Added server-side file type/size validation (was frontend-only)
- Added measurements JSON injection protection with key allowlist
- Added notes length limit (was unbounded)

---

## [2026-03-08] — Pipeline 57: Trainee Dashboard Visual Redesign

### Added

- Mobile: Premium dark-themed trainee home dashboard replacing 1,418-line monolith with 14 focused widget files
- Mobile: `DashboardHeader` — "Hey, {name}!" greeting with date, avatar, coach badge, notification bell
- Mobile: `WeekCalendarStrip` — horizontal 7-day strip with selected day highlight and workout dots
- Mobile: `TodaysWorkoutsSection` — horizontal scrollable workout cards with gradient backgrounds, difficulty badges, duration circles
- Mobile: `ActivityRingsCard` — Apple Watch-style triple concentric rings (calories/steps/activity) with CustomPainter
- Mobile: `HealthMetricsRow` — side-by-side Heart Rate (with waveform) and Sleep (placeholder) cards
- Mobile: `WeightLogCard` — latest weight display with trend indicator and "Weight In" CTA
- Mobile: `LeaderboardTeaserCard` — trophy icon linking to community leaderboard
- Mobile: `DashboardShimmer` — full shimmer skeleton matching dashboard layout
- Mobile: `DashboardColors` — centralized dashboard color constants

### Changed

- Mobile: `home_screen.dart` reduced from 1,418 to 109 lines (slim orchestrator pattern)
- Mobile: All existing cards preserved (PendingCheckinBanner, ProgressionAlertCard, HabitsSummaryCard, QuickLogCard)
- Mobile: Pull-to-refresh debounce guard prevents duplicate loads

---

## [2026-03-08] — Pipeline 56: Video Workout Layout End-to-End

### Added

- Backend: `video` choice added to `WorkoutLayoutConfig.LayoutType` TextChoices with migration
- Web: Layout config selector shows 4 options (Classic, Card, Minimal, Video) matching backend enum
- Web: `ExerciseVideoPlayer` component — YouTube embed + native `<video>` fallback with sandbox, lazy loading, ARIA labels
- Web: Exercise detail panel integrates inline video player
- Mobile: `VideoWorkoutLayout` — full-screen portrait video background, gradient overlays, top info bar, swipe/chevron navigation, speed toggle, rest timer overlay, compact dark logging card
- i18n: `trainees.layoutDescription` key in en/es/pt-BR

### Fixed

- Web: Layout config values now match backend enum (`classic`/`card`/`minimal` not `default`/`compact`/`detailed`)
- Web: Layout config field name corrected from `layout` to `layout_type`
- Mobile: Video init race condition prevented via generation counter
- Mobile: `_formatMuscleGroup` guarded against empty strings
- Mobile: `SystemChrome` overlay style restored on dispose
- Mobile: Exercise name overflow constrained with Flexible wrapper

---

## [2026-03-05] — Pipeline 55: Web i18n String Extraction

### Added

- Web: Extracted hardcoded English strings to i18n JSON message files across 150 components
- Web: 728 `t()` translation calls replacing inline English text
- Web: Expanded en.json, es.json, pt-BR.json from ~130 to ~580 translation keys each
- Web: All navigation links (trainer, admin, ambassador, trainee sidebars) now use i18n keys
- Web: Page titles, descriptions, button labels, form labels, placeholders, toast messages, empty/error states, and table headers fully internationalized
- Web: Spanish (es) and Portuguese (pt-BR) translations for all new keys

### Changed

- Web: Nav link data files store i18n keys instead of English strings; sidebar components translate at render time

---

## [2026-03-05] — Pipeline 54: Web Impersonation Spec Fix

### Fixed

- PRODUCT_SPEC.md: Updated stale "Partial" status for web impersonation to "Done" -- the full token swap was completed in Pipeline 27 (2026-02-20) but the feature table and historical notes were not updated at the time

---

## [2026-03-05] — Pipeline 53: TV Mode Gym Display

### Added

- Mobile: Full TV Mode gym display replacing placeholder screen
- Mobile: `tv_mode_provider.dart` — Riverpod StateNotifier for TV mode state (exercise tracking, set completion, rest timer, elapsed time)
- Mobile: `tv_mode_screen.dart` — Main screen with loading/empty/error/rest-day/complete/active states
- Mobile: `tv_exercise_card.dart` — Large exercise cards with completion status, muscle group, last weight
- Mobile: `tv_rest_timer.dart` — Circular countdown timer with configurable duration (30s/60s/90s/120s/180s)
- Mobile: `tv_progress_bar.dart` — Workout progress bar (sets completed / total)
- Mobile: `tv_workout_header.dart` — Header with program name, day, elapsed timer, exit button
- Mobile: `tv_empty_states.dart` — Loading, empty, complete, and exit button widgets
- Mobile: TV mode icon button added to home screen header
- Mobile: `/tv-mode` route added to app_router.dart
- Mobile: `wakelock_plus` package for keeping screen on during TV mode
- Mobile: Immersive sticky system UI mode for maximum screen real estate
- Mobile: Landscape-preferred orientation (supports portrait too)

### Changed

- Mobile: `tv_screen.dart` converted from placeholder to barrel re-export
- PRODUCT_SPEC: TV mode marked as Done

---

## [2026-03-05] — Pipeline 52: i18n String Extraction (Phase B)

### Added

- Mobile: 976 new ARB translation keys extracted from hardcoded English strings across 161 dart files
- Mobile: Spanish (es) translations for all 1164 ARB keys
- Mobile: Portuguese Brazil (pt-br) translations for all 1164 ARB keys
- Mobile: l10n imports added to all modified feature/widget files

### Changed

- Mobile: All user-facing strings in screens/widgets now use `context.l10n.keyName` pattern instead of hardcoded English
- Mobile: `const` removed from widgets where runtime l10n values replaced compile-time string constants
- Mobile: Total ARB keys expanded from 188 to 1164 (6x increase)
- PRODUCT_SPEC: String extraction (Phase B - Flutter) marked as Done

### Not Changed

- Web (Next.js) i18n infrastructure exists but component adoption deferred to separate pipeline
- ~56 Flutter strings with Dart interpolation remain hardcoded (need ICU message format conversion)

---

## [2026-03-05] — Pipeline 51: Churn Push Notifications via FCM

### Added

- Backend: `_send_trainer_churn_push()` and `_send_trainee_re_engagement_push()` helpers in retention_notification_service — wire FCM delivery via core notification_service
- Backend: `re_engagement` BooleanField on NotificationPreference model (default=True) with migration
- Mobile: Deep link handling for `churn_alert` (navigates to trainer trainee detail) and `re_engagement` (navigates to home screen) in push_notification_service
- Mobile: "Re-engagement Reminders" toggle in trainee notification preferences screen

### Changed

- Backend: `create_churn_alerts()` now sends FCM pushes to trainers after creating TrainerNotification records
- Backend: `send_re_engagement_pushes()` now sends FCM pushes to critical-risk trainees instead of just logging intent
- Backend: NotificationPreference.VALID_CATEGORIES expanded from 10 to 11 categories

---

## [2026-03-05] — Pipeline 50: Achievement Toast on New Badge

### Added

- Backend: Weight check-in endpoint now returns `new_achievements` in 201 response
- Backend: Nutrition confirm-and-save endpoint now returns `new_achievements` in response
- Mobile: `AchievementCelebrationOverlay` — animated toast with elastic scale entrance, pulsing gold glow, backdrop blur, tap/swipe dismiss, 4-second auto-dismiss
- Mobile: `AchievementToastService` — singleton queue manager for sequential display with 500ms gap between achievements
- Mobile: `showAchievementToastsFromRaw()` — shared helper to parse raw achievement JSON and trigger toasts
- Mobile: Achievement toasts wired into 5 trigger points: post-workout survey, weight check-in, AI command center, manual food entry, barcode scan
- Mobile: Haptic feedback (success pattern) on achievement display
- Mobile: Accessibility semantics with liveRegion for screen reader announcement

### Changed

- Mobile: Consolidated duplicated `achievementIconMap` — achievement_badge.dart now imports from celebration overlay
- Mobile: `rootNavigatorKey` made public for global overlay access by toast service
- Mobile: `OfflineSaveResult` gained `newAchievements` convenience accessor
- Mobile: `LoggingState` gained `newAchievements` field for forwarding achievement data through the logging flow

### Fixed

- Mobile: Overlay dispose safety — completer always completes even if widget is disposed during animation, preventing stuck queue

---

## [2026-03-05] — Pipeline 49: Video Attachments on Community Posts

### Added

- Backend: `PostVideo` model with FK to CommunityPost, FileField, ImageField thumbnail, duration, file_size, sort_order
- Backend: `video_service.py` — 3-layer validation (extension + MIME type + magic bytes), ffprobe duration extraction, ffmpeg thumbnail generation
- Backend: Migration `0007_add_post_video` with indexes on (post, sort_order) and (created_at)
- Backend: `MediaUploadThrottle` rate limiting (20/hour) on community feed POST
- Backend: Django `DATA_UPLOAD_MAX_MEMORY_SIZE` (60MB) and `FILE_UPLOAD_MAX_MEMORY_SIZE` (10MB) settings
- Backend: Video file + thumbnail cleanup on post deletion
- Backend: 15MB fallback size limit when ffprobe unavailable (graceful degradation)
- Backend: `ffmpeg` added to Dockerfile
- Mobile: `PostVideoModel` with `formattedDuration` getter (M:SS format)
- Mobile: `VideoPlayerCard` — lazy initialization, muted autoplay, tap play/pause, loading spinner, error retry
- Mobile: `FullscreenVideoPlayer` — landscape support, seek bar, auto-hide controls, mute toggle
- Mobile: Video picker in compose sheet with extension/size validation, preview cards with VIDEO badge and file size
- Mobile: Upload progress bar (indeterminate while preparing, percentage during upload)
- Mobile: Semantics labels on all video player controls (accessibility)
- Mobile: Enlarged touch targets on remove buttons (images + videos)

### Fixed

- Negative duration guard in `formattedDuration` (returns empty for ≤0)
- Double-tap race condition in video player (added `_isLoading` guard)
- Bookmark queries now prefetch videos (N+1 fix)
- `transaction.atomic()` wraps post + images + videos creation
- Video player error overlay improved with styled retry button

---

## [2026-03-05] — Pipeline 48: FCM Push Notifications for Community Events

### Added

- Backend: 4 notification dispatch methods in EventService (created, updated, cancelled, reminder)
- Backend: `send_event_reminders` management command for cron-based reminders (`*/5 * * * *`)
- Backend: `community_event` notification preference category with migration
- Backend: Event status state machine (`_VALID_TRANSITIONS`) with ValueError on invalid transitions
- Mobile: Full PushNotificationService — Firebase init, local notification display, deep link navigation
- Mobile: Stream subscription lifecycle management (cancel on deactivate, re-subscribe on init)
- Mobile: "Community Events" toggle in notification preferences (trainee Updates section)
- Auth: Push token registration on all 5 login paths (email, register, Google, Apple, impersonation)
- Auth: Push token deactivation on logout, account deletion, and impersonation identity switch

### Fixed

- Duplicate reminder sends (narrowed cron window to 10-15 min matching 5-min interval)
- Fragile local notification payload encoding (switched to JSON)
- Firebase init error handling (graceful degradation with `_initialized` reset)
- Stream subscription leak on login/logout cycles (store and cancel `StreamSubscription` refs)
- Impersonation token leak (deactivate before switching identity)
- Banned users receiving event notifications (excluded via UserBan query)
- N+1 queries in reminder command (batched RSVP fetch)
- False-positive update notifications (compare old vs new field values)
- Deep link paths corrected (event detail, announcements)
- Missing `community_event` field in NotificationPreferenceSerializer

---

## [2026-03-05] — Pipeline 47: Community Events — Trainer Create & Trainee RSVP

### Added

- CommunityEventModel and RsvpStatus enum with full fromJson, copyWith, computed getters
- EventRepository with trainee (list, detail, RSVP) and trainer (CRUD, status transition) endpoints
- TraineeEventNotifier with optimistic RSVP updates and error rollback
- TrainerEventNotifier with create, update, delete, cancel operations
- EventCard widget with date formatting, type/status badges, RSVP indicator, dimming for past/cancelled
- EventTypeBadge and EventStatusBadge widgets (5 event types, 4 statuses)
- RsvpButton — 3-way SegmentedButton with capacity-aware disabling
- Event list screen with date-grouped sections (Today/Tomorrow/This Week/Next Week/Later)
- Event detail screen with API fallback for deep links, Join Meeting button, RSVP error snackbar
- Trainer event list with FAB, edit on tap, confirmation dialogs for cancel/delete
- Trainer event form (create + edit) with date/time pickers, virtual toggle, validation
- Loading skeleton for event list matching card layout
- Events icon in Community tab app bar
- "Manage Events" card on trainer dashboard
- 5 new routes in app_router.dart

### Fixed

- DateTime.tryParse with fallback for corrupt backend data
- PATCH instead of PUT for partial event updates
- Negative count guard in RSVP optimistic update
- End-time auto-correction when start-time is moved past end-time

---

## [2026-03-05] — Pipeline 46: Nutrition Phase 5 — Wire Template Assignment into Trainer Detail Screen

### Added

- `_NutritionTemplateSection` widget in trainer's trainee detail Nutrition tab
- "Assign Nutrition Template" button (no active assignment) and assignment summary card (active assignment)
- `traineeActiveAssignmentProvider` with autoDispose.family for trainer-side lookup
- Body weight validation (required, 0-1000 lbs), body fat % (1-70), meals per day (1-10)
- Loading spinner, error card with retry, empty template list state
- PopScope to prevent back navigation during submission
- Semantics labels for accessibility on loading/error states
- Success snackbar with check icon and green background
- Helper text on all parameter fields
- Reassign confirmation dialog

### Fixed

- setState after async gap now checks mounted first
- Raw error strings replaced with user-friendly messages
- autoDispose added to dayPlanProvider and weekPlansProvider to prevent memory growth

---

## [2026-03-05] — Pipeline 45: Nutrition Phase 4 — Wire Plan Screens into Navigation

### Added

- Meal plan card on trainee nutrition screen showing day type, template name, calorie target, P/C/F macros
- Card tap navigates to DayPlanScreen with selected date
- "View Week" button navigates to WeekPlanScreen
- Card conditionally rendered only for trainees with active template assignments

### Fixed

- Future.wait type safety in nutrition provider for typed repository returns
- Template name overflow in meal plan card (Flexible + ellipsis)
- Removed unused import in template_assignment_screen

---

## [2026-03-05] — Pipeline 44: Nutrition Phase 3 — LBM Formula Engine & SHREDDED/MASSIVE Templates

### Added

- LBM-based macro calculation engine with `calculate_shredded_macros()` and `calculate_massive_macros()`
- SHREDDED template: 22% caloric deficit, 1.3g protein/lb LBM, 3 day types (low/medium/high carb)
- MASSIVE template: 12% caloric surplus, 1.1g protein/lb LBM, 2 day types (training/rest)
- Boer formula fallback for body fat estimation when not measured
- Per-meal macro distribution with front-loaded carbs and exact remainder handling
- Profile enrichment auto-pulling sex/height/age/activity from UserProfile
- `recalculate` endpoint on NutritionTemplateAssignment (regenerates 7 days)
- `DayPlanScreen` with date navigation, daily totals, per-meal cards, all UX states
- `WeekPlanScreen` with 7-day overview, today highlight, day type badges
- `DayTypeBadge` widget (color-coded for each day type)
- `MealPlanCard` widget with macro bars and calorie totals
- Migration 0017 updating SHREDDED/MASSIVE templates with formula-driven rulesets
- 40 unit tests for all formula functions and edge cases

### Fixed

- 2 IDOR vulnerabilities on NutritionDayPlanViewSet list/week endpoints (trainer ownership check)
- Provider error silencing — providers now throw on API errors instead of returning null/empty
- Repository returns typed values instead of raw `Map<String, dynamic>`

### Security

- Added trainer ownership validation on day plan list and week endpoints
- Fixed error propagation chain: repository → provider → UI error state

---

## [2026-03-05] — Pipeline 43: Nutrition Phase 2 — FoodItem, MealLog, Fat Mode

### Added

- `FoodItem` model with Exercise-pattern visibility (`is_public` + `created_by`), full macro fields, barcode support, auto-calculated calories
- `MealLog` + `MealLogEntry` relational models replacing JSON blob nutrition logging
- `FoodItemViewSet` with search, barcode lookup, recent foods, CRUD with ownership checks
- `MealLogViewSet` with date filtering, daily summary aggregation, quick-add with auto-created containers, entry deletion
- `active_assignment` action on `NutritionTemplateAssignmentViewSet`
- `FoodItemRepository` and `MealLogRepository` (Flutter)
- `FoodItemSearchNotifier` with 300ms debounce and barcode lookup
- `MealLogNotifier` with parallel loading, optimistic deletes with rollback
- `MealCard` widget with macro chips, swipe-to-delete, a11y semantics
- `FatModeBadge` widget with tooltip explanation
- 6 new backend serializers, 9 new API endpoints
- Migration `0016_fooditem_meallog`

### Fixed

- 3 IDOR vulnerabilities on summary, active_assignment, and barcode_lookup endpoints
- N+1 query pattern in MealLogSerializer (4x `entries.all()` → cached)
- Missing FoodItem access control in quick_add endpoint
- Silent exception swallow on date parse in MealLogViewSet
- ProtectedError crash on FoodItem delete (now returns 409 Conflict)
- Removed 2 pre-existing debug `print()` statements from `food_search_repository.dart`

---

## [2026-03-04] — Pipeline 42: Notification Preferences, Local Reminders & Dead UI Cleanup

### Added

- Backend `NotificationPreference` model with 9 per-category boolean toggles
- GET/PATCH API endpoint for notification preferences (`/api/users/notification-preferences/`)
- Preference checking before sending FCM push notifications (single + group)
- `NotificationPreferencesScreen` with role-based categories and optimistic toggle updates
- `RemindersScreen` for local workout, meal, and weight check-in reminders
- `HelpSupportScreen` with FAQ accordion, contact card, and dynamic app version
- `ReminderService` singleton using `flutter_local_notifications` with timezone-aware scheduling
- Notification tap handling with payload routing
- Help & Support tile in trainee settings

### Fixed

- 7 dead "Coming Soon" buttons in Settings now navigate to real screens
- Dead Message and Schedule buttons on trainee detail screen now functional
- Removed ~30 debug `print()` statements from `api_client.dart` and `admin_repository.dart`
- Fixed broken `widget_test.dart` (was testing non-existent counter app)
- Trainee "Check-in Days" was routing to `/edit-diet` instead of `/reminders`
- Duplicate notification icon on adjacent settings tiles

### Changed

- All backend notification callers now pass `category` parameter for preference filtering
- `send_push_to_group` supports category-based opt-out with batch query

---

## [2026-02-27] — Pipeline 41: Calendar Integration Completion

### Added

- **CalendarEventsScreen** — Full event list with date grouping, provider filter chips (All/Google/Microsoft), pull-to-refresh sync, empty/no-connection states, shimmer loading placeholders
- **TrainerAvailabilityScreen** — Availability CRUD with day-of-week grouping, add/edit/toggle/delete operations, adaptive time pickers (CupertinoDatePicker on iOS, showTimePicker on Android), optimistic toggle with rollback, swipe-to-delete with confirmation
- **11 extracted widgets** — CalendarEventTile (with provider badge G/M), CalendarCard, AvailabilitySlotEditor, AvailabilitySlotTile, TimeTile, CalendarProviderFilter, CalendarNoConnectionView, CalendarConnectionHeader, CalendarActionsSection
- **Accessibility** — Semantics labels on all interactive elements, tooltips on icon buttons and FAB, screen reader support throughout
- **Auto-pagination** — Mobile repository fetches all pages from paginated events endpoint (bounded at 10 pages / ~200 events)

### Fixed

- **3 race conditions** — Filter revert, delete confirmation, and concurrent sync all raced against `ref.listen` clearing `state.error`; fixed with identity-based checks
- **Initial frame flash** — Added `connectionsLoaded` flag to prevent "No calendar connected" flashing before connections load
- **Field name bugs** — `is_all_day` → `all_day`, `external_event_id` → `external_id` in CalendarEventModel
- **Backend error leakage** — 4 views exposed `str(e)` in error responses; replaced with generic messages + `logger.exception()`
- **Provider badge colors** — Google=red, Microsoft=blue (matching card icon colors)
- **Malformed time handling** — Empty/invalid time strings now show "--:--" or raw value instead of misleading "12:00 AM"

### Security

- Input validation: `max_length`/`min_length` on OAuth `code`/`state` fields, `max_length` on event description/location/attendees
- Provider URL parameter validation via `_validate_provider()` helper
- Admin panel token fields excluded (`_access_token`, `_refresh_token`)
- HTTP request timeouts `(10, 30)` on all external API calls
- `select_related('connection')` on events queryset (N+1 fix)
- `CreateEventSerializer.validate()` ensures `end_time > start_time`

### Technical

- CalendarConnectionScreen refactored from 524 to 222 lines with 6 extracted widgets
- Typed `SyncResult` model replaces raw `Map<String, dynamic>` returns
- `TrainerAvailabilityModel.copyWith()` for optimistic state updates
- Shared `calendarDayNames` constant across model, screens, and editor
- Event creation logic moved from view to `CalendarSyncService.create_external_event()`
- Quality Score: 8/10 SHIP

---

## [2026-02-27] — Pipeline 39: Trainee Retention & Churn Prevention Analytics

### Added

- **Engagement scoring** — 0-100 per-trainee score based on workout consistency (30%), nutrition consistency (25%), goal adherence (25%), and recency (20%) over a 14-day rolling window
- **Churn risk scoring** — 0-100 score with 4 risk tiers: Critical (>=75), High (>=50), Medium (>=25), Low (<25). Combines engagement deficit (40%), inactivity signal (30%), declining trend (20%), and low volume signal (10%)
- **New trainee guard** — Trainees created within the lookback window with zero activity are capped at Medium risk (not flagged as churning)
- **Retention analytics API** — `GET /api/trainer/analytics/retention/?days=14` returns full retention analytics with summary, per-trainee scores, and daily trends
- **At-risk trainees API** — `GET /api/trainer/analytics/at-risk/?days=14` returns critical + high risk trainees sorted by churn risk DESC
- **Automated churn alerts** — `compute_retention` management command (daily cron) creates TrainerNotification entries for at-risk trainees with 3-day deduplication
- **Re-engagement pushes** — Automated push notification records for critical-risk trainees with 7-day deduplication (FCM delivery pending firebase_admin wiring)
- **CHURN_ALERT notification type** — New TrainerNotification.NotificationType enum value
- **Web retention UI** — RetentionSection on analytics page with 4 summary cards (At-Risk Count, Avg Engagement, Retention Rate, Critical Count), risk distribution horizontal bar chart, retention trend line chart, at-risk trainee DataTable with risk badges and engagement bars
- **Mobile retention UI** — RetentionAnalyticsScreen with summary card grid, risk tier badges, at-risk trainee tiles with engagement indicators

### Technical

- Frozen dataclasses pattern (RetentionAnalyticsResult, RetentionSummary, TraineeEngagementItem, RetentionTrendPoint) following revenue_analytics_service.py
- Single annotated queryset with select_related to avoid N+1
- bulk_create for notifications with type-safe int casting for JSONB field lookups
- Per-trainer error handling in management command with .iterator() for memory efficiency
- Quality Score: 9/10 SHIP

---

## [2026-02-27] — Pipeline 40: Multi-Language Support (i18n — Spanish + Portuguese)

### Added

- **Django i18n infrastructure** — `preferred_language` CharField on UserProfile (en/es/pt-br), `LocaleMiddleware`, `LANGUAGES`/`LOCALE_PATHS` settings, PO files for en/es/pt-BR (~20 API error strings)
- **Flutter i18n infrastructure** — `flutter_localizations` + `gen_l10n` with ARB files (~200 strings each for en/es/pt), `LocaleProvider` (Riverpod StateNotifier + SharedPreferences persistence), `context.l10n` extension for concise access
- **Next.js i18n infrastructure** — React context-based i18n with cookie persistence (`NEXT_LOCALE`), JSON message files (~130 strings each for en/es/pt-BR), `LocaleProvider` with `t()` function for dot-path key access
- **Accept-Language header** — Propagated from both Flutter and Next.js API clients to Django backend
- **Language selector (mobile)** — Language settings screen accessible from all role settings (admin, trainer, trainee), backend sync via PATCH to profiles endpoint, SharedPreferences persistence
- **Language selector (web)** — LanguageSelector component added to all 4 settings pages (admin, trainer, trainee, ambassador), cookie + API sync, radio button UI matching AppearanceSection pattern
- **Translation glossary** — `translations/glossary.md` with standardized fitness terms (Trainer/Trainee/Workout/Exercise/Set/Rep/Macros/etc.) across en/es/pt-br with 7 consistency rules

### Technical

- Cookie security: Secure flag for HTTPS, string-split getCookie (prevents ReDoS vs regex), SameSite=Lax
- Synchronous locale initialization on web (reads cookie in useState initializer, no English flash)
- html lang attribute synced on locale changes
- ARB files auto-generate AppLocalizations via `flutter gen-l10n`
- Quality Score: 9/10 SHIP

---

## [2026-02-24] — Pipeline 38: Admin Dashboard Mobile Responsiveness

### Changed

- **Responsive table columns** — 14 columns hidden on mobile (`hidden md:table-cell`) across admin tables: trainers (Trainees, Status, Joined), subscriptions (Tier, Start, Status), tiers (Price, Active, Subs), coupons (Type, Uses, Expires), users (Role, Status, Joined)
- **Mobile-safe dialogs** — 9 admin dialogs updated with `max-h-[90dvh] overflow-y-auto` to prevent off-screen content on small viewports
- **Full-width filter inputs** — 4 filter/search inputs made full-width on mobile for easier touch interaction
- **Stacked button groups** — 3 button groups restructured to stack vertically on mobile with proper spacing
- **Touch target fixes** — Minimum 44px touch targets on all interactive admin elements
- **Layout dvh fix** — Replaced `100vh` with `100dvh` for Mobile Safari address bar compatibility

### Fixed

- **3 missing error states** — Added error boundaries/states to admin pages that were missing them
- **2 stale state bugs** — Fixed stale state in admin dialogs that persisted data between open/close cycles

### Technical

- Completes the three-part web responsive sweep: P36 (Trainee Portal), P37 (Trainer Dashboard), P38 (Admin Dashboard)
- All admin pages now fully usable on mobile devices (320px+)
- Quality Score: 9/10 SHIP
- Security: purely CSS/layout changes, no auth/data/API modifications

---

## [2026-02-24] — Pipeline 37: Trainer Dashboard Mobile Responsiveness

### Changed

- **DataTable responsive columns** — Hide less-important columns on mobile (`hidden md:table-cell`) across trainee list (Program, Joined), program list (Goal, Used, Created), invitation list (Program, Expires), activity tab (Carbs, Fat), revenue tables (Since, Type, Date)
- **DataTable compact pagination** — `Page X of Y (Z total)` → `X/Y` on mobile, icon-only Previous/Next buttons with 44px touch targets
- **Trainee detail page** — Header stacks vertically on mobile, action buttons use 2-column grid with 44px min-height, scrollable tabs at 320px
- **Revenue section header** — Restructured into two-row layout: heading + period selector on row 1, export buttons on row 2
- **Exercise bank filters** — Collapsible filter chips behind "Filters (N)" toggle on mobile with `aria-expanded`/`aria-controls`
- **Exercise row inputs** — Taller `h-9` inputs on mobile for better touch targets, reduced left padding (`pl-0 sm:pl-8`)
- **Program builder save bar** — Sticky at bottom on mobile with safe-area-inset-bottom padding, reverts to static at `md:` breakpoint
- **Chat pages** — `100vh` → `100dvh` on AI Chat and Messages pages to fix Mobile Safari address bar overlap
- **Dashboard home table** — Recent Trainees table now hides Program and Joined columns on mobile with scroll hint
- **Progress charts** — Added `interval="preserveStartEnd"` and smaller font size to prevent XAxis label overlap on mobile

### Added

- **Horizontal scroll hints** — `.table-scroll-hint` CSS class with gradient fade + JS scroll listener that hides when scrolled to edge; applied to DataTable and TraineeActivityTab
- **Dialog overflow protection** — Added `max-h-[90dvh] overflow-y-auto` to 9 trainer dialogs (edit-goals, mark-missed-day, remove-trainee, change-program, exercise-picker, assign-program, create-invitation, announcement-form, create-feature-request)
- **Compact notification/announcement pagination** — Icon-only Previous/Next buttons on mobile matching DataTable pattern
- **Calendar event truncation** — Long event titles truncate properly at mobile widths

### Technical

- TypeScript: zero errors, build passes
- Security: 10/10 PASS — purely CSS/layout changes
- Architecture: 9/10 APPROVE — CSS-first approach, consistent `md:` breakpoint usage
- UX: 9/10 — 6 issues found and fixed during audit
- Hacker: 7/10 — found and fixed 19 additional files beyond ticket scope
- 25+ files changed across web/src/

---

## [2026-02-24] — Pipeline 36: Trainee Web Mobile Responsiveness

### Changed

- **Dynamic viewport height** — Replaced `h-screen` (100vh) with `h-dvh` (100dvh) in trainee and trainer dashboard layouts, fixing Mobile Safari address bar overlap
- **Exercise log card** — Responsive 5-column grid that compresses gracefully at 320px, responsive "Wt" / "Weight" column header, numeric/decimal keyboard inputs (`inputMode`)
- **Active workout** — Sticky bottom bar on mobile with timer, set counter, Finish/Discard buttons always reachable; header actions wrap on narrow screens; abbreviated button text
- **Charts** — `useIsMobile` hook for Recharts: angled XAxis labels (-45°), smaller fonts, `preserveStartEnd` interval, reduced chart heights
- **Program viewer** — Week tabs horizontally scrollable with thin scrollbar indicator, increased tab touch targets on mobile
- **Dialogs** — All dialogs (`workout-detail`, `workout-finish`, `weight-checkin`, `meal-delete`, `discard-confirm`) use `max-h-[90dvh] overflow-y-auto` to prevent off-screen content
- **Workout detail** — Responsive "S1" / "Set 1" prefix, title tooltip on truncated weight values
- **Nutrition page** — Larger date nav button touch targets (36px on mobile), responsive date display width
- **Messages** — Flexbox-based viewport height, sidebar border hidden on mobile single-panel view
- **Announcements** — Header stacks vertically on mobile with proper gap

### Added

- **iOS auto-zoom prevention** — `font-size: 16px !important` on inputs at mobile breakpoint (replaces WCAG-violating `maximumScale: 1`)
- **Safe area insets** — `viewportFit: "cover"` + `env(safe-area-inset-*)` body padding for notched devices (iPhone X+)
- **Number spinner removal** — Global CSS hiding `input[type="number"]` spinners to save horizontal space
- **Scrollbar-thin utility** — Thin scrollbar styling using correct oklch `var(--border)` color
- **Touch target improvements** — Checkbox wrapper padding (p-1.5), meal delete buttons (h-8), nutrition nav buttons (h-9)
- **Responsive page header** — `text-xl` on mobile, `text-2xl` on sm+

### Fixed

- **Scrollbar color mismatch** — Changed `hsl(var(--border))` to `var(--border)` since CSS vars use oklch
- **Deprecated `-moz-appearance`** — Replaced with standard `appearance: textfield`
- **Invalid `role="timer"`** — Changed to `role="status"` (valid ARIA role)
- **Exercise name overflow** — Added `truncate` with `title` attribute on long exercise names

### Technical

- TypeScript: zero errors, build passes
- Security: 10/10 PASS — purely CSS/layout changes, no auth/data/API modifications
- Architecture: 9/10 APPROVE — CSS-first approach, JS only for Recharts imperative config
- UX: 8/10 — 15 usability + 5 accessibility issues found and fixed during audit
- Hacker: 8/10 — sticky bottom bar, numeric keyboards, tooltip fallbacks, keyboard hint hiding
- 21 files changed across web/src/

---

## [2026-02-24] — Pipeline 35: Trainee Web Nutrition Tracking Page

### Added

- **Nutrition page** (`/trainee/nutrition`) — Full nutrition tracking for trainee web portal with AI-powered meal logging, daily macro tracking, date navigation, meal history, and macro presets
- **AI meal logging** — Natural language input → parse → preview → confirm & save flow. Clarification handling when AI needs more details. Character count with progressive feedback (shows at 1800+)
- **Macro tracking** — 4 progress bars (Calories, Protein, Carbs, Fat) with consumed/goal display, over-goal amber indicators showing excess amount (+N)
- **Date navigation** — Previous/next day arrows, disabled forward past today, "Today" quick-return button, midnight crossover auto-advance
- **Meal history** — List of logged meals with delete confirmation dialog. Race-condition-safe delete target capture
- **Macro preset chips** — Read-only trainer-managed presets with active detection, skeleton loading, keyboard-accessible tooltips
- **Shared MacroBar component** (`components/shared/macro-bar.tsx`) — Extracted from DRY violation, used by both dashboard summary card and nutrition page
- **4 new React Query hooks** — `useParseNaturalLanguage`, `useConfirmAndSaveMeal`, `useDeleteMealEntry`, `useTraineeMacroPresets`
- **Date utilities** — `addDays()` and `formatDisplayDate()` extracted to `schedule-utils.ts`

### Changed

- `trainee-nav-links.tsx` — Added "Nutrition" link with Apple icon between Progress and Messages
- `nutrition-summary-card.tsx` — Replaced inline MacroBar with shared component import
- `constants.ts` — Added 3 API URL constants for nutrition endpoints

### Fixed (Backend)

- Added `IsTrainee` permission on `parse_natural_language` and `confirm_and_save` endpoints (previously only `IsAuthenticated`)
- `delete_meal_entry` and `edit_meal_entry` now use their serializers instead of manual validation

### Technical

- TypeScript: zero errors
- Security: 8/10 CONDITIONAL PASS — 3 HIGH fixed, rate limiting deferred
- Architecture: 9/10 APPROVE — follows all existing patterns
- UX: 8.5/10 — 18 accessibility and usability issues found and fixed
- 21 files changed, +1,677 / -671 lines

---

## [2026-02-23] — Pipeline 34: Trainee Web Trainer Branding

### Added

- Trainee web portal now shows trainer's custom branding (app name, logo, primary color) in sidebar
- New `useTraineeBranding()` hook with React Query caching (5-min staleTime)
- Shared `BrandLogo` component with graceful image error fallback
- Frontend hex color sanitization for defense-in-depth
- `SheetDescription` for Radix Dialog accessibility compliance

### Changed

- Trainee desktop sidebar displays trainer's logo, app name, and branded active link colors
- Trainee mobile sidebar applies same branding treatment
- `TraineeBranding` type moved to `types/branding.ts` (collocated with `TrainerBranding`)
- `BrandLogo` extracted to shared component eliminating DRY violation

### Technical

- TypeScript: zero errors
- Security: PASS (9/10) — no XSS, no CSS injection, strict hex validation
- Architecture: APPROVE (9/10) — proper layering, shared components, centralized types
- 5 files changed, 209 lines added

---

## [2026-02-21] — Trainee Web Workout Logging & Progress Tracking (Pipeline 33)

### Added

- **Weight check-in dialog** — Trainees can log weight from the dashboard card. Validates 20-500 kg range, no future dates, optional notes (500 char max). POST via React Query mutation with toast feedback and automatic cache invalidation of weight trend + latest weight queries.
- **Active workout page** (`/trainee/workout`) — Full workout logging with real-time timer, exercise cards with editable sets/reps/weight, add/remove sets, native checkbox completion, `beforeunload` guard for unsaved work. ExerciseTarget snapshot pattern decouples from live program query. Discard button with confirmation dialog.
- **Workout finish dialog** — Review summary before saving: workout name, duration, exercise count, sets completed/total, total volume with dynamic unit. Incomplete sets warning banner. Enter-key submission via `<form>`. Prevents dialog close during save.
- **Workout history page** (`/trainee/history`) — Paginated list (20 per page) with exercise count, total sets, volume, duration. Detail dialog shows per-exercise set breakdown with completed/skipped badges. "Page X of Y" pagination with scroll-to-top.
- **Progress page** (`/trainee/progress`) — Three chart components: Weight Trend (LineChart, last 30 entries), Workout Volume (BarChart), Weekly Adherence (progress bar with color-coded percentage). Theme-aware `CHART_COLORS` from `chart-utils.ts`. Screen reader `<ul>` fallbacks for all charts.
- **"Already logged today" detection** — Dashboard Today's Workout card checks for existing daily log. Shows "View Today's Workout" (outline button, links to history) when logged, "Start Workout" when not.
- **Save workout mutation** (`useSaveWorkout`) — Checks for existing daily log via GET, PATCHes if exists, POSTs if new. Handles DailyLog unique constraint on (trainee, date). Invalidates weekly-progress, workout-history, and today-log queries on success.
- **Shared schedule utilities** (`lib/schedule-utils.ts`) — Extracted `getTodaysDayNumber()`, `findTodaysWorkout()`, `getTodayString()`, `formatDuration()` to eliminate duplication across components.
- **3 new page routes** — `/trainee/workout`, `/trainee/history`, `/trainee/progress` with proper auth guards.
- **8 new trainee dashboard hooks** — `useTraineeTodayLog`, `useSaveWorkout`, `useTraineeWorkoutHistory`, `useTraineeWorkoutDetail`, plus existing hooks extended.

### Changed

- `trainee-nav-links.tsx` — Added History and Progress navigation links (8 total nav items).
- `weight-trend-card.tsx` — Added "Log Weight" button with `WeightCheckInDialog` integration.
- `nutrition-summary-card.tsx` — Replaced duplicate `getToday()` with import from `schedule-utils`.
- `trainee-progress-charts.tsx` — Charts use `CHART_COLORS.weight` and `CHART_COLORS.workout` instead of inline `hsl(var(--primary))`. Weight chart limited to 30 entries.
- `chart-utils.ts` — Added `weight: "hsl(var(--chart-5))"` to `CHART_COLORS`.
- `constants.ts` — Added `TRAINEE_DAILY_LOGS`, `TRAINEE_WORKOUT_HISTORY`, `traineeWorkoutDetail(id)` URL constants.
- `trainee-dashboard.ts` (types) — Added `WorkoutHistoryItem`, `WorkoutHistoryResponse`, `WorkoutDetailData`, `SaveWorkoutPayload`, and related interfaces.

### Security

- Added `encodeURIComponent()` for all date query parameters in hooks (XSS/injection prevention).
- Input validation: reps 0-999, weight 0-9999, weight check-in 20-500 kg, notes 500 char max.
- No `dangerouslySetInnerHTML`, no `localStorage` for sensitive data, generic error messages.

### Accessibility

- 33 accessibility improvements across 9 files: `aria-busy` on skeletons, `aria-live="polite"` on dynamic content, `aria-label` on all interactive elements, `role="timer"` on workout timer, `role="region"` on summary sections, `role="alert"` on incomplete sets warning, `aria-hidden` on decorative icons, focus-visible styles on links.
- Pagination changed from `<div>` to `<nav>` with proper `aria-label`.
- Screen reader fallback lists for all chart data.

### Fixed

- Bodyweight/isometric exercise inputs (weight=0, reps=0) now display "0" instead of blank.
- Timezone-safe date parsing using `parseISO` from date-fns instead of `new Date()`.
- Duplicate React keys in chart screen reader lists resolved with unique `_key` field.
- Recharts Tooltip formatter TypeScript type mismatch fixed.

---

## [2026-02-21] — Trainee Web Portal — Home Dashboard & Program Viewer (Pipeline 32)

### Added

- **Trainee web login** — Standalone TRAINEE login via existing JWT auth. Auth provider now accepts TRAINEE role. Login page routes TRAINEE users directly to `/trainee/dashboard`. Middleware + layout double-guard with role-based routing.
- **Trainee dashboard** — Home page with 4 independent stat cards: Today's Workout (exercises from active program, rest day, no-program states), Nutrition Macros (4 color-coded progress bars with CSS variable-driven colors), Weight Trend (neutral colors, kg-only, "since" context), Weekly Progress (animated bar with percentage). Each card has independent skeleton loading, error with retry, and empty states.
- **Program viewer** — Full read-only program schedule display with tabbed week view (WAI-ARIA compliant keyboard navigation: Arrow keys, Home, End), day cards with exercise details (sets × reps @ weight, rest seconds), rest day badges, "No exercises scheduled" distinct from rest days, program switcher dropdown for multiple programs.
- **Messages** — Reuses existing ConversationList, ChatView, MessageSearch components. Auto-selects first conversation. Cmd/Ctrl+K search shortcut. Suspense boundary for useSearchParams. Derived state pattern (no setState-in-useEffect).
- **Announcements** — Click-to-expand cards with unread visual distinction (dot + bold title + primary/5 background). Per-announcement mark-read on open via POST. Mark-all-read button with loading state. Optimistic updates with rollback on both mutations. Pinned-first sorting.
- **Achievements** — Grid with earned (trophy icon, date) / locked (lock icon, progress bar) states. Summary "X of Y earned" header. ARIA labels on progress bars and cards.
- **Settings** — Reuses ProfileSection (business name field hidden for TRAINEE), AppearanceSection, SecuritySection.
- **Navigation** — 6-link sidebar (Dashboard, My Program, Messages, Announcements, Achievements, Settings). Shared `useTraineeBadgeCounts` hook for unread badges. 256px desktop sidebar, Sheet drawer on mobile. "Hi, {firstName}" header greeting.
- **Shared hooks** — `use-trainee-dashboard.ts` (programs, nutrition, weekly progress, latest weight, weight history), `use-trainee-announcements.ts` (list, unread count, mark-all-read, mark-one-read with optimistic updates), `use-trainee-achievements.ts`, `use-trainee-badge-counts.ts`.
- **Progress component** — New `web/src/components/ui/progress.tsx` with `--progress-color` CSS variable support, ARIA progressbar role.

### Changed

- `web/src/middleware.ts` — Added `isTraineeDashboardPath()`, TRAINEE routing to `/trainee/dashboard`, non-trainee guard for `/trainee/*` paths.
- `web/src/providers/auth-provider.tsx` — TRAINEE role now allowed for standalone login (was previously rejected).
- `web/src/app/(auth)/login/page.tsx` — TRAINEE role routes to `/trainee/dashboard` (was falling through to `/dashboard`).
- `web/src/app/(dashboard)/layout.tsx` — TRAINEE redirect uses `router.replace` instead of `window.location.href`.
- `web/src/components/layout/user-nav.tsx` — Settings link routes to `/trainee/settings` for TRAINEE role.
- `web/src/components/settings/profile-section.tsx` — Business name field hidden for TRAINEE role.
- `web/src/lib/constants.ts` — Added 9 trainee API URL constants.

### Deferred

- **AC-19: Trainer branding** — `TRAINEE_BRANDING` API URL defined but branding colors/logo not applied to trainee dashboard. Tracked for next pipeline.

---

## [2026-02-21] — Smart Program Generator (Pipeline 31)

### Added

- **Exercise difficulty classification** — `difficulty_level` (beginner/intermediate/advanced) and `category` fields on Exercise model with composite index on `(muscle_group, difficulty_level)`. Management command `classify_exercises` supports OpenAI GPT-4o batch classification and heuristic fallback mode.
- **KILO exercise library** — 1,067 exercises seeded via `seed_kilo_exercises` management command with fixture data in `kilo_exercises.json`.
- **Program generation service** (`backend/workouts/services/program_generator.py`) — Deterministic algorithm supporting 5 split types (PPL, Upper/Lower, Full Body, Bro Split, Custom), 3 difficulty levels, 6 training goals. Features exercise selection with difficulty fallback, sets/reps/rest schemes per goal×difficulty matrix, progressive overload (+1 set/3 weeks, +1 rep/2 weeks, capped at +3 sets/+5 reps), deload every 4th week, and goal-based nutrition templates.
- **Generate API endpoint** — `POST /api/trainer/program-templates/generate/` with `GenerateProgramRequestSerializer` (validates split type, difficulty, goal, duration 1-52 weeks, training days 2-7, custom day configs) and `GeneratedProgramResponseSerializer`. Protected by `[IsAuthenticated, IsTrainer]`.
- **Web generator wizard** — 3-step wizard at `/programs/generate`: split type selection (radio cards), configuration (difficulty/goal radio groups with keyboard navigation, duration/days inputs), preview with loading skeleton and retry. Generated data passed to existing program builder via sessionStorage.
- **Mobile generator wizard** — 3-step Flutter wizard with split type cards, goal cards, custom day configurator, accessibility Semantics labels, and navigation to existing ProgramBuilderScreen with generated data.
- **Exercise picker difficulty filter** — Added difficulty level filter chips to exercise pickers on both web and mobile (week editor).
- **"Generate with AI" button** — Added to Programs page on both web and mobile to launch the generator wizard.
- **123 new backend tests** — Unit tests for compound detection, progressive overload, exercise pool, deload weeks. Integration tests for all 5 split types, nutrition templates, schedule format. API endpoint tests for auth, validation, IDOR security. All 18 goal/difficulty combinations smoke-tested.

### Changed

- `WorkoutExercise.reps` changed from `int` to `String` in Flutter to support rep ranges (e.g., "8-10") from the generator. Backward-compatible `fromJson` handles both formats. Updated across 5 mobile files.
- All 4 program providers in `program_provider.dart` now throw `Exception` on API failure instead of silently returning empty lists (consistency with exercise provider fix).
- `ExerciseFilter.hashCode` changed from XOR-based to `Object.hash()` for better collision resistance.
- Extracted `ExercisePickerSheet` and `StepIndicator` into separate widget files from larger screens.

### Security

- Fixed IDOR vulnerability where `_get_exercises_for_muscle_group` exposed all exercises when `trainer_id=None`. Now correctly scopes to `is_public=True` only.
- `trainer_id` sourced from `request.user.id`, not request body, preventing exercise pool manipulation.

---

## [2026-02-21] — Macro Preset Management for Web Trainer Dashboard (Pipeline 30)

### Added

- **Macro presets section** on trainee detail Overview tab — trainers can create, edit, delete, and copy nutrition presets (e.g. Training Day, Rest Day) per trainee. Responsive card grid with name, 4 macro values, frequency badge, default star icon.
- **React Query hooks** (`web/src/hooks/use-macro-presets.ts`) — 5 hooks: `useMacroPresets` (query with 5min staleTime), `useCreateMacroPreset`, `useUpdateMacroPreset`, `useDeleteMacroPreset`, `useCopyMacroPreset` (all with proper cache invalidation).
- **Preset form dialog** (`web/src/components/trainees/preset-form-dialog.tsx`) — Reusable create/edit dialog with name, calories, protein, carbs, fat fields. Frequency selector (1-7x/week). Default checkbox. Client-side validation matching backend rules. `Math.round()` on all numeric values. Calorie mismatch warning when macros don't add up.
- **Copy preset dialog** (`web/src/components/trainees/copy-preset-dialog.tsx`) — Copy preset to another trainee with trainee selector dropdown. Memoized trainee filter, loading skeleton, empty state.
- **Delete confirmation** with `role="alertdialog"`, pointer/escape dismissal prevention during pending mutation.
- **Full accessibility** — `aria-describedby` on all validation errors, `role="alert"` on error messages, `aria-label` on all action buttons, `sr-only` text for default preset star icon, `aria-busy` on loading skeleton.
- **4 URL constants** — `MACRO_PRESETS`, `macroPresetDetail(id)`, `macroPresetCopyTo(id)`, `MACRO_PRESETS_ALL`.
- **`MacroPreset` TypeScript interface** with all 16 fields matching the API response.

### Changed

- Trainee Overview tab layout wrapped in outer `space-y-6` container to accommodate full-width Macro Presets section below the 2-column grid.
- `PresetCard` extracted to separate file for component separation (architecture audit).

---

## [2026-02-21] — CSV Data Export for Trainer Dashboard (Pipeline 29)

### Added

- **3 CSV export endpoints** — `GET /api/trainer/export/payments/?days=N`, `/export/subscribers/`, `/export/trainees/` returning downloadable CSV files with `Content-Disposition: attachment` headers and `Cache-Control: no-store`.
- **Export service** (`backend/trainer/services/export_service.py`) — Frozen `CsvExportResult` dataclass. Uses `csv.writer` with `StringIO`. Amounts always 2 decimal places. Dates ISO 8601 formatted. Empty data returns valid header-only CSV.
- **CSV injection protection** — `_sanitize_csv_value()` prefixes cells starting with `=`, `+`, `-`, `@`, `\t`, `\r` with single-quote per OWASP recommendation.
- **Reusable ExportButton component** (`web/src/components/shared/export-button.tsx`) — Blob download with auth token refresh, AbortController for race conditions, `idle` → `downloading` → `success` state machine, Sonner toast on error/success, `aria-live` region for screen readers.
- **Export buttons in Revenue section** — "Export Payments" and "Export Subscribers" buttons in the Revenue header, disabled during data refetch, payment export respects the active period selector.
- **Export button on Trainees page** — "Export CSV" in the page header next to "Invite Trainee" button. Shows when trainer has trainees (uses `data.count` not page results).
- **39 new backend tests** covering auth (401/403), response format (content-type, filename), data correctness, row-level security (trainer isolation), period filtering, all payment/subscription statuses, edge cases (empty data, null fields, special characters).
- **Shared utility** (`backend/trainer/utils.py`) — Extracted `parse_days_param` function used by both `views.py` and `export_views.py`.

### Changed

- Trainee export query uses `annotate(last_log_date=Max("daily_logs__date"))` and filtered `Prefetch` for active programs instead of unbounded prefetch.
- Revenue section header wraps (`flex-wrap`) on narrow viewports to prevent horizontal overflow.

---

## [2026-02-20] — Trainer Revenue & Subscription Analytics (Pipeline 28)

### Added

- **Revenue analytics API** -- `GET /api/trainer/analytics/revenue/?days=N` returns MRR, total period revenue, active subscriber count, average revenue per subscriber, 12-month revenue breakdown, subscriber list, and recent payments. Service layer with frozen dataclasses. `[IsAuthenticated, IsTrainer]` permissions with row-level security.
- **Revenue section on analytics page** -- New `RevenueSection` component below the existing Progress section with:
  - 4 stat cards: MRR (DollarSign), Period Revenue (TrendingUp), Active Subscribers (Users), Avg/Subscriber (UserCheck)
  - Monthly revenue bar chart (Recharts, current month highlighted, $K/$M axis formatting)
  - Active subscribers table (clickable rows → trainee detail, renewal countdown with green/amber/red color coding)
  - Recent payments table (last 10, color-coded status badges: succeeded/pending/failed/refunded)
  - Period selector (30d / 90d / 1y) with ARIA radiogroup keyboard navigation
- **36 new backend tests** covering auth/authz, response shape, MRR calculation, period filtering, monthly aggregation, subscriber/payment fields, row-level security, and edge cases.
- **Database indexes** on `TraineePayment.paid_at` and composite `(trainer, status, paid_at)` for query performance.

### Changed

- `useAdherenceAnalytics` and `useAdherenceTrends` hooks now use `keepPreviousData` to prevent flash-to-skeleton when switching periods (also applied to new `useRevenueAnalytics`).
- `DataTable` component now accepts `rowAriaLabel` prop for screen reader context on clickable rows.
- `formatCurrency` includes NaN guard for defensive rendering.
- Revenue chart Y-axis handles $1M+ values correctly.

---

## [2026-02-20] — Full Trainer→Trainee Impersonation (Pipeline 27)

### Added

- **Trainer→trainee token swap** -- "View as Trainee" button now performs a real token swap: saves trainer tokens to sessionStorage, sets trainee JWT tokens, sets TRAINEE role cookie, and hard-navigates to a new `/trainee-view` page. Previously the button was a no-op that redirected to `/dashboard`.
- **Trainer impersonation banner** -- Amber banner at the top of the trainee view showing "Viewing as {name}" with Read-Only badge and "End Impersonation" button. End impersonation restores trainer tokens and redirects back to the trainee detail page.
- **Read-only trainee view page** -- New `(trainee-view)` route group with 4 data cards: Profile Summary, Active Program (with today's exercises), Today's Nutrition (macro progress bars), and Recent Weight (last 5 check-ins with trend indicator). All cards have loading skeletons, empty states, and error states with retry.
- **TRAINEE middleware routing** -- Middleware now routes TRAINEE role cookie to `/trainee-view` and redirects TRAINEE users away from trainer/admin/ambassador paths.

### Changed

- Auth provider now allows TRAINEE role when trainer impersonation state exists in sessionStorage.
- Dashboard layout now redirects TRAINEE role to `/trainee-view` (defense-in-depth).
- Added 4 trainee-facing API URL constants: `TRAINEE_PROGRAMS`, `TRAINEE_NUTRITION_SUMMARY`, `TRAINEE_WEIGHT_CHECKINS`.

---

## [2026-02-20] — Advanced Trainer Analytics (Pipeline 26)

### Added

- **Calorie goal hit rate** -- 4th stat card on the trainer analytics page showing the percentage of days trainees hit their calorie goals. Uses the existing `hit_calorie_goal` field from `TraineeActivitySummary` which was previously unused.
- **Adherence trend chart** -- New `AdherenceTrendChart` component showing daily adherence rates (food, workout, protein, calorie) as a Recharts AreaChart over the selected period. Includes custom tooltip with all 4 rates + trainee count, legend, `sr-only` data list, and responsive layout.
- **Adherence trends API** -- `GET /api/trainer/analytics/adherence/trends/?days=N` returns per-day adherence rates for all metrics. Single annotated query with O(days) response. Authenticated + IsTrainer.
- **21 new backend tests** -- 5 for calorie_goal_rate in existing adherence endpoint, 16 for the new trends endpoint (calculation, sorting, auth, isolation, parameter validation, edge cases).

### Changed

- `AdherenceAnalyticsView` now returns `calorie_goal_rate` alongside existing food/workout/protein rates.
- Analytics stat cards grid updated from 3 columns to `sm:grid-cols-2 lg:grid-cols-4` for the 4th card.
- Skeleton state updated to show 4 card skeletons + 2 chart skeletons.
- `CHART_COLORS` extended with `calorie` color (`--chart-3`).
- Extracted `_parse_days_param()` helper to reduce duplication between analytics views.
- X-axis labels: 7d shows weekday names, 14d/30d shows "Feb 15" format for clarity.

---

## [2026-02-20] — Ambassador Dashboard Enhancement (Pipeline 25)

### Added

- **Earnings chart** -- Recharts BarChart on the ambassador dashboard showing monthly commission earnings for the last 12 months. Zero-filled gaps, current month highlighted, tooltips with exact amounts, responsive with `preserveStartEnd` for mobile, accessible `sr-only` data list.
- **Referral status breakdown** -- Stacked progress bar showing active/pending/churned referral distribution with color-coded legend and ARIA label.
- **Referral list pagination** -- Server-side pagination on `/ambassador/referrals` with Previous/Next controls, page indicator, and `keepPreviousData` for smooth transitions.
- **Referral status filter tabs** -- All/Active/Pending/Churned filter tabs on the referral list page. Server-side filtering via `?status=` query param. Page resets to 1 on filter change.
- **19 new backend tests** -- Dashboard monthly earnings (12-month zero-fill, amount key, pending exclusion), status counts, referral pagination, status filtering, ordering, row-level isolation, auth.

### Changed

- `AmbassadorDashboardView` returns 12 months of earnings (was 6) with zero-fill for gaps and `amount` key aligned with frontend type.
- `AmbassadorReferralsView` now has explicit `order_by('-referred_at')` for deterministic pagination.
- Dashboard page layout: earnings chart between stat cards and referral code; status breakdown + referral code in responsive 2-column grid.

### Fixed

- StatusBadge case-sensitive comparison (API returns uppercase, component compared lowercase) — badges now correctly color-coded.
- X-axis label overlap on mobile screens for 12-month chart.

---

## [2026-02-20] — In-App Message Search (Pipeline 24)

### Added

- **Message search API** -- `GET /api/messaging/search/?q=<query>&page=<page>` searches messages across all conversations the authenticated user participates in. Case-insensitive substring match via `icontains`. Excludes soft-deleted messages and archived conversations. Paginated (20/page) with `-created_at` ordering.
- **`search_messages()` service function** -- Business logic in `services/search_service.py` with frozen dataclass returns (`SearchMessageItem`, `SearchMessagesResult`). Row-level security enforced at query level: trainers see trainer's conversations, trainees see theirs, admins must impersonate.
- **`SearchMessageResultSerializer`** -- API response serializer with sender info, conversation context (other participant), image URL, timestamps. Nullable `other_participant_id` for removed trainees (SET_NULL FK).
- **Web: Search button with Cmd/Ctrl+K** -- Keyboard shortcut opens/closes search panel in messages sidebar. Platform-detected modifier key badge on button.
- **Web: Search panel** -- Replaces conversation list when active. Debounced input (300ms), 2-character minimum, skeleton loading, empty/error states with retry, pagination (Previous/Next).
- **Web: Highlighted search results** -- `highlightText()` splits text on query match, wraps in `<mark>` with `bg-primary/20` (XSS-safe via React JSX, no innerHTML). `truncateAroundMatch()` centers ~150 char snippet around first match.
- **Web: Click-to-scroll-and-highlight** -- Clicking a search result navigates to the conversation, scrolls to the matched message, and applies a 3-second yellow flash animation. Light and dark mode CSS keyframes with `prefers-reduced-motion` support.
- **Web: Accessibility** -- `role="search"` landmark, `aria-live="polite"` results count, `aria-describedby` hint, semantic `<nav>` pagination, semantic `<time>` timestamps, `aria-busy` during refetch, dark mode highlight contrast (`dark:bg-primary/30`).
- **Web: `useSearchMessages()` hook** -- React Query hook with `enabled: query.length >= 2`, `placeholderData: keepPreviousData` for smooth pagination, cache key `["messaging", "search", query, page]`.
- **42 backend tests** -- Service layer basics (13), edge cases (8), pagination (3), view layer (18). Covers row-level security, cross-tenant isolation, special characters, null trainee, archived conversations, admin rejection, impersonation, field completeness.

### Fixed

- **Regex `g` flag stateful bug** -- `highlightText()` initially used `gi` regex flag. The `g` flag makes `RegExp.test()` stateful (advances `lastIndex`), causing alternating match/no-match for consecutive matches. Fixed by using `i` flag only with `part.toLowerCase() === lowerQuery` comparison.
- **Admin role silently returned empty** -- Admin users fell through to `else` branch and got empty results with no error. Fixed by raising `ValueError('Only trainers and trainees can search messages.')`.
- **Search results flashed to skeleton** -- Every keystroke caused jarring flash from results to skeleton placeholders. Fixed with `placeholderData: keepPreviousData` on the React Query hook.
- **Scroll position not reset on page change** -- Paginating search results kept scroll position at bottom. Fixed with `resultsRef` scroll-to-top effect.
- **`formatSearchTime` future date handling** -- Could display negative "d ago" values for server clock skew. Fixed with `isNaN` and negative-diff guards.

---

## [2026-02-19] — Message Editing and Deletion (Pipeline 23)

### Added

- **Message editing (15-min window)** -- PATCH `/api/messaging/conversations/<id>/messages/<message_id>/` edits message content. Sender-only, within configurable 15-minute window (`EDIT_WINDOW`). Sets `edited_at` timestamp. Content validated (max 2000 chars, not empty for text-only messages, empty allowed for image messages). Race condition prevention via `transaction.atomic()` + `select_for_update()`.
- **Message soft-deletion** -- DELETE on same endpoint soft-deletes message. Sender-only, no time limit. Clears content to empty string, sets image to None, deletes actual image file from storage. Sets `is_deleted=True`. Race condition prevention via `transaction.atomic()` + `select_for_update()`.
- **`EditMessageResult` and `DeleteMessageResult` frozen dataclasses** -- Service layer returns typed results per project convention.
- **WebSocket broadcast events** -- `chat.message_edited` (message_id, content, edited_at) and `chat.message_deleted` (message_id) broadcast to conversation channel group for real-time sync.
- **Conversation list deleted preview** -- `annotated_last_message_is_deleted` subquery annotation. Serializer returns "This message was deleted" for soft-deleted last messages.
- **Mobile: Long-press context menu** -- Bottom sheet with Edit (pencil icon), Delete (trash, red), Copy (clipboard). Other users' messages show Copy only. Edit grayed out with "Edit window expired" subtitle when >15 minutes.
- **Mobile: Edit bottom sheet** -- Pre-filled TextFormField, character counter (X/2000), Save/Cancel buttons. `hasImage` param allows empty content for image-only messages.
- **Mobile: Delete confirmation** -- AlertDialog: "Delete this message? This can't be undone." with Cancel/Delete buttons.
- **Mobile: Deleted/edited message states** -- "[This message was deleted]" italic gray placeholder with timestamp preserved. "(edited)" indicator next to timestamp.
- **Mobile: Optimistic edit/delete** -- Both operations update state immediately and revert on API error. SnackBar error feedback on failure.
- **Web: Hover action icons** -- Pencil and trash icons appear on hover over own messages. Pencil hidden when edit window expired.
- **Web: Inline edit mode** -- Textarea replaces content with Save/Cancel buttons. Esc cancels, Cmd/Ctrl+Enter saves (platform-detected modifier key). Save disabled when content unchanged or empty (unless image message).
- **Web: Delete confirmation** -- Inline dialog with `role="alertdialog"`, aria-label, Escape key dismissal. "Delete this message? This can't be undone."
- **Web: Deleted/edited message states** -- "[This message was deleted]" muted italic with aria-label. "(edited)" indicator.
- **Web: `useEditMessage()` and `useDeleteMessage()` mutation hooks** -- React Query mutations with `setQueriesData` across all cached pages and conversation invalidation.
- **Web: WebSocket edit/delete callbacks** -- `onMessageEdited` and `onMessageDeleted` on `useMessagingWebSocket` hook update local `allMessages` state directly for other party's real-time edits/deletes.
- **107 backend tests** -- Comprehensive coverage: service layer (21), views (18), serializers (7), model (4), edge cases (13), boundary (2), cross-conversation security (3), trainee edit/delete (4), existing tests (35).

### Fixed

- **CRITICAL: Race condition on edit/delete** -- Both `edit_message()` and `delete_message()` lacked transaction/row lock. Could corrupt data under concurrent writes. Fixed with `transaction.atomic()` + `Message.objects.select_for_update().get(...)`.
- **CRITICAL: Test URL mismatch for delete views** -- Delete tests used `/messages/<id>/delete/` URL (non-existent) instead of RESTful `/messages/<id>/` with DELETE method. Fixed 3 test URLs.
- **HIGH: Orphaned image files on delete** -- Setting `message.image = None` didn't delete actual file from storage. Fixed by saving reference before clearing, calling `old_image_field.delete(save=False)` outside transaction.
- **HIGH: EditMessageSerializer blocked image message caption clearing** -- `CharField` defaulted to `allow_blank=False`, rejecting empty content at serializer level before service could check for image. Fixed with `allow_blank=True`.
- **HIGH: Web WS events didn't update local state for other party** -- `useMessagingWebSocket` updated React Query cache but `ChatView` maintained separate `allMessages` state that was stale. Added `onMessageEdited`/`onMessageDeleted` callbacks.
- **Missing rate limiting on delete** -- `DeleteMessageView` had no throttle. Merged into unified `MessageDetailView` with `throttle_scope = 'messaging'`.
- **Mobile `orElse` crash risk** -- `firstWhere` with `state.messages.first` as fallback throws `StateError` on empty list. Fixed with `indexWhere` + index check.
- **Mobile silent exception swallowing** -- WS service caught all exceptions. Fixed to only catch `FormatException` and `TypeError`.
- **Web delete confirmation mouse leave** -- `onMouseLeave` dismissed confirmation before user could click it. Removed premature dismissal; Escape key dismisses instead.
- **Web wrong keyboard shortcut hint on macOS** -- Always showed "Ctrl+Enter". Now detects macOS and shows command symbol.
- **Mobile no error feedback** -- Edit/delete failures silently reverted. Added `ref.listen` for error state → SnackBar display with `clearError()`.
- **Mobile debugPrint calls** -- 3 `debugPrint()` calls violated convention. Removed with unused import.

### Accessibility

- Mobile deleted message bubble: `Semantics` widget with sender, deleted status, and timestamp
- Web delete confirmation: `role="alertdialog"` and `aria-label="Confirm message deletion"`
- Web deleted message: `aria-label` with sender context and timestamp
- Web delete confirmation: Escape key listener for keyboard-only users

### Quality Metrics

- Code Review: 7/10 → fixed (1 round, 4 critical + 8 major all fixed)
- QA: HIGH confidence, 72 initial → 107 final tests, all pass, 0 failures
- Security Audit: 9/10 PASS (row-level security gap fixed, views consolidated)
- Architecture Audit: 9/10 APPROVE (RESTful single-resource, deduplication, AC-32 hooks)
- UX Audit: 9/10 (6 usability + 4 accessibility issues found and fixed)
- Hacker Audit: 8/10 (4 bugs found and fixed: test URLs, serializer, WS sync, debugPrint)
- Final Verdict: SHIP at 9/10, HIGH confidence

---

## [2026-02-19] — WebSocket Real-Time Web Messaging (Pipeline 22)

### Added

- **`useMessagingWebSocket` hook** -- New custom React hook (`web/src/hooks/use-messaging-ws.ts`, ~468 lines) managing full WebSocket lifecycle per conversation. JWT auth via URL query parameter, exponential backoff reconnection (1s→16s cap, max 5 attempts), 30s heartbeat with 5s pong timeout, tab visibility API reconnection, React Query cache mutations with deduplication.
- **Typing indicators on web** -- Wired existing `typing-indicator.tsx` component via WebSocket `typing_indicator` events. `sendTyping()` with 3s debounce, 4s display timeout. "Name is typing..." with animated dots (staggered 0ms/150ms/300ms delays). Positioned outside scroll area so it's always visible regardless of scroll position.
- **Real-time read receipts on web** -- WebSocket `read_receipt` events update React Query cache in real-time, replacing poll-based receipt updates.
- **Connection state banners** -- `ConnectionBanner` component with two states: "Reconnecting..." (amber background, Loader2 spinner) for transient disconnection, "Updates may be delayed" (muted background, WifiOff icon) for persistent failure. Dark mode support on both variants.
- **Graceful HTTP polling fallback** -- When WebSocket is connected, HTTP polling disabled (interval set to 0). When disconnected/failed, HTTP polling resumes at 5s. Refetches once on reconnect to catch missed messages.
- **Configurable polling intervals** -- `useConversations()` and `useMessagingUnreadCount()` hooks now accept `refetchIntervalMs` parameter for dynamic polling control.
- **`onTyping` callback on ChatInput** -- Fires `onTyping(true)` on input, `onTyping(false)` on send. Enables typing indicator integration.

### Fixed

- **CRITICAL: Race condition in async `connect()`** -- If component unmounted while `connect()` was awaiting `refreshAccessToken()`, cleanup fired but `connect()` resumed and created a leaked WebSocket with no cleanup reference. Fixed with `cancelledRef` pattern — set to `true` in cleanup, checked after each async gap.
- **CRITICAL: Typing indicator inside scroll area** -- Was placed inside `overflow-y-auto` div, invisible when user scrolled up. Moved outside scroll area, between message list and ChatInput.
- **Pre-existing `@/hooks/use-toast` import** -- `chat-input.tsx` imported from non-existent `@/hooks/use-toast`. Project uses `sonner`. Replaced with `import { toast } from "sonner"` and updated all call sites.
- **`markRead` referenced before declaration** -- `useMessagingWebSocket` on line 42 referenced `markRead` declared on line 78. Moved `useMarkConversationRead` call above `useMessagingWebSocket`.
- **Confusing `POLLING_DISABLED` naming** -- `POLLING_DISABLED = false as const` was confusing (variable "DISABLED" = `false`). Renamed to `POLLING_OFF = 0`.

### Accessibility

- `aria-live="polite"` on typing indicator for screen reader announcements
- `role="status"` on connection state banners
- Connection banners use appropriate semantic colors (amber for transient, muted for persistent)

### Quality Metrics

- Code Review: 8/10 APPROVE (2 rounds -- 2 critical + 2 major all fixed)
- QA: HIGH confidence, 31/31 AC pass, 35 backend tests pass, 0 new TS errors
- Security Audit: 9/10 PASS (JWT in URL param is standard for WebSocket, no issues found)
- Architecture Audit: 9/10 APPROVE (clean separation, no tech debt introduced)
- Hacker Audit: 9/10 (no dead UI, visual bugs, or logic bugs found)
- UX Audit: 9/10 (all states handled, accessible, dark mode correct)
- Final Verdict: SHIP at 9/10, HIGH confidence

---

## [2026-02-19] — Image Attachments in Direct Messages (Pipeline 21)

### Added

- **Image field on Message model** -- Optional `ImageField` with UUID-based upload paths (`message_images/{uuid}.{ext}`), nullable with default None. Migration adds image column and makes content field blank/optional.
- **Image validation in views** -- `_validate_message_image()` helper validates JPEG/PNG/WebP content types and 5MB max size. Both `SendMessageView` and `StartConversationView` accept `MultiPartParser` for multipart uploads alongside existing JSON.
- **Conversation list "Sent a photo" preview** -- Chained Subquery annotation (`_last_message_image` + `annotated_last_message_has_image`) correctly checks if the most recent message has an image. Serializer shows "Sent a photo" for image-only last messages.
- **Push notification for image messages** -- `send_message_push_notification()` accepts `has_image` parameter, shows "Sent a photo" body for image-only messages.
- **35 backend tests** -- Comprehensive test suite covering image upload, validation (reject GIF/SVG/PDF/oversized), acceptance (JPEG/PNG/WebP), absolute URLs, row-level security, annotation correctness (last message vs any), service layer, model behavior.
- **Mobile image picker** -- Camera icon button in ChatInput, opens `ImagePicker` with gallery source, max 1920x1920, 85% quality compression. Preview strip with X remove button. 5MB client-side validation with SnackBar error.
- **Mobile optimistic image send** -- Creates temporary `MessageModel` with `localImagePath` for immediate display. Replaces with server response on success, marks `isSendFailed` on error. Deduplicates with WebSocket-delivered messages.
- **Mobile fullscreen image viewer** -- `MessageImageViewer` with `InteractiveViewer` (pinch-to-zoom 1.0x-4.0x), black background, loading/error states. Supports both network and local images.
- **Mobile image in message bubble** -- `MessageBubble` displays images with rounded corners, max 300px height, tap-to-fullscreen. Loading spinner, broken image error state. Accessibility labels: "Photo message" / "Photo message with text: ...".
- **Web image attach button** -- Paperclip icon button with hidden file input (JPEG/PNG/WebP filter). Preview strip with X remove. 5MB validation with toast errors.
- **Web FormData upload** -- `useSendMessage` and `useStartConversation` hooks use `FormData` when image is present, JSON otherwise. Backward compatible.
- **Web image in message bubble** -- `MessageBubble` displays images with click-to-open-modal. Image error state. `loading="lazy"` for performance.
- **Web image modal** -- `ImageModal` dialog component with full-size image, close button, sr-only DialogTitle for accessibility.
- **Object URL cleanup** -- `useEffect` cleanup in web ChatInput to revoke object URLs on unmount, preventing memory leaks.

### Fixed

- **Dead code cleanup** -- Removed unused `last_message_image_subquery` variable and unused `Length` import in `messaging_service.py`.
- **Import ordering** -- Moved all imports to top of `views.py` (were after function definition, violating PEP 8).
- **Type safety** -- Changed `image: Any | None` to `image: UploadedFile | None` on `send_message()` and `send_message_to_trainee()`.
- **Missing import** -- Added `MessageSender` to show clause in `messaging_provider.dart`.
- **Missing logging** -- Added `debugPrint` in provider catch blocks (`loadConversations`, `loadMessages`, `loadMore`).
- **Gitignore** -- Added `backend/media/` to `.gitignore` to prevent test-generated media files from being committed.

---

## [2026-02-19] — In-App Direct Messaging (Pipeline 20)

### Added

- **New `messaging` Django app** -- Full backend for 1:1 trainer-to-trainee direct messaging. `Conversation` model (trainer FK CASCADE, trainee FK SET_NULL, unique constraint, 3 indexes, soft-archive via `is_archived`). `Message` model (conversation FK CASCADE, sender FK CASCADE, content max 2000 chars, is_read/read_at, 3 indexes). 2 migrations including SET_NULL fix for trainee FK.
- **6 REST API endpoints** -- `GET /api/messaging/conversations/` (paginated at 50, annotated preview + unread count), `GET /api/messaging/conversations/<id>/messages/` (paginated at 20), `POST /api/messaging/conversations/<id>/send/` (rate-limited 30/min), `POST /api/messaging/conversations/start/` (trainer-only, creates conversation if needed), `POST /api/messaging/conversations/<id>/read/` (mark all read), `GET /api/messaging/unread-count/` (total unread). All endpoints have IsAuthenticated + row-level security.
- **WebSocket consumer** -- `DirectMessageConsumer` with JWT authentication via query parameter, per-conversation channel groups (`messaging_conversation_{id}`), typing indicators (coerced to strict bool), read receipt forwarding, ping/pong heartbeat. `is_archived=False` check on connect.
- **Service layer** -- `messaging_service.py` with frozen dataclass returns (`SendMessageResult`, `MarkReadResult`, `UnreadCountResult`). Functions: `send_message()`, `mark_conversation_read()`, `get_unread_count()` (single Q-object query), `get_conversations_for_user()` (Subquery + Left + Count annotations), `get_messages_for_conversation()`, `get_or_create_conversation()`, `archive_conversations_for_trainee()`, `send_message_to_trainee()`, `broadcast_new_message()`, `broadcast_read_receipt()`, `send_message_push_notification()`, `is_impersonating()`.
- **Impersonation read-only guard** -- `SendMessageView` and `StartConversationView` check `request.auth` for JWT `impersonating` claim and return 403.
- **Conversation archival** -- `RemoveTraineeView` now calls `archive_conversations_for_trainee()` before clearing `parent_trainer`. Trainee FK uses SET_NULL to preserve message history for audit.
- **Mobile messaging feature (Flutter)** -- Full feature with Riverpod state management: `ConversationListNotifier`, `ChatNotifier`, `UnreadCountNotifier`, `NewConversationNotifier`. Conversations list screen, chat screen, new conversation screen. WebSocket service with exponential backoff reconnection (1s base, 30s cap). Typing indicators (animated 3-dot widget), read receipts (single/double checkmark), optimistic message updates.
- **Mobile navigation integration** -- Messages tab added to both trainer shell (index 2) and trainee shell (index 4) with unread badge. `ConsumerStatefulWidget` with `initState()` refresh (no infinite loop).
- **Mobile accessibility** -- `Semantics` widgets on MessageBubble, ConversationTile, TypingIndicator, ChatInput send button, ConversationListScreen.
- **Web messages page** -- Responsive split-panel layout (320px sidebar + chat, single-panel on mobile with back button). Conversation list with relative timestamps, unread badges, empty/error states. Chat view with date separators, infinite scroll (page 2+ on scroll-to-top), auto-scroll to bottom, 5s HTTP polling. Scroll-to-bottom FAB.
- **Web new conversation flow** -- `NewConversationView` component renders when trainer navigates from trainee detail "Message" button and no existing conversation found. Shows "Send your first message" CTA, calls `startConversation` API, redirects to new conversation on success.
- **Web message input** -- `ChatInput` component with textarea, 2000 char max, character counter at 90%, Enter-to-send, Shift+Enter for newline, disabled during send.
- **Web read receipts** -- `MessageBubble` shows `Check` (sent) or `CheckCheck` (read) icons for own messages.
- **Web sidebar unread badge** -- Both `sidebar.tsx` and `sidebar-mobile.tsx` show red badge next to Messages link via `useMessagingUnreadCount()`. 99+ cap.
- **Web trainee detail integration** -- "Message" button on `/trainees/[id]` navigates to `/messages?trainee=<id>`.
- **Shared utility** -- `getInitials()` extracted to `format-utils.ts` (was duplicated in conversation-list and chat-view).
- **7 Playwright E2E tests** -- `messages.spec.ts` covering: sidebar nav link, page navigation, empty state, conversation list rendering, chat view selection, message input area, send button enable.
- **E2E mock setup** -- Paginated conversation mock in auth helpers, per-test conversation/message route overrides.

### Fixed

- **CRITICAL: scrollToBottom ReferenceError** -- `useCallback` for `scrollToBottom` was defined after the `useEffect` that depended on it. `const` is not hoisted, causing runtime crash when any conversation with messages was rendered. Moved definition above the dependent effect.
- **CRITICAL: Web new-conversation dead end** -- Navigating from trainee detail "Message" when no conversation existed showed "Select a conversation" with no way to create one. Added `NewConversationView` with first-message flow.
- **HIGH: Web layout unusable on mobile** -- Sidebar was always `w-80` even on mobile screens. Changed to `w-full md:w-80` with show/hide based on selection state. Added back button for mobile navigation.
- **HIGH: Archived conversation WebSocket access** -- `_check_conversation_access()` did not filter `is_archived=False`. A removed trainee with valid JWT could connect to archived conversation's WebSocket channel. Added filter.
- **HIGH: Bare exception in WebSocket auth** -- `except Exception` silently swallowed all errors including ImportError/AttributeError. Narrowed to `except (TokenError, User.DoesNotExist, ValueError, KeyError)`. Moved imports outside try block.
- **HIGH: Archived conversation message access** -- `ConversationDetailView` did not check `is_archived`. Removed trainee could still read all messages. Added archived check (trainees get 403, trainers can view for audit).
- **MEDIUM: Archived conversation mark-read** -- `MarkReadView` did not check `is_archived`. Added check returning 403.
- **MEDIUM: Null recipient push notification** -- `recipient_id` could be None after SET_NULL. Added null check with warning log.
- **Business logic in views** -- Moved `broadcast_new_message()`, `broadcast_read_receipt()`, `send_message_push_notification()`, `is_impersonating()` from views.py to services/messaging_service.py.
- **Unread count query optimization** -- Consolidated from 2 queries to 1 using Django Q objects.
- **Duplicated getInitials** -- Extracted to shared `format-utils.ts`.
- **E2E mock format** -- Changed conversations mock from bare array to paginated response `{ count, next, previous, results }`.
- **E2E ambiguous selector** -- Scoped conversation list assertion to listbox role.
- **3 mobile debugPrint calls removed** -- Replaced with descriptive comments explaining non-fatal behavior.
- **Missing web TypeScript field** -- Added `is_new_conversation: boolean` to `StartConversationResponse` type.

### Accessibility

- `Semantics` widgets on all mobile messaging widgets (MessageBubble, ConversationTile, TypingIndicator, ChatInput, ConversationListScreen)
- `role="log"` with `aria-label="Message history"` and `aria-live="polite"` on web message container
- `role="listbox"` with `aria-label="Conversations"` on web conversation list
- `aria-label="Scroll to latest messages"` on scroll-to-bottom button
- `aria-label="Back to conversations"` on mobile-web back button
- `role="status"` on loading spinners, `role="alert"` on error messages
- `sr-only` loading text for screen readers

### Quality Metrics

- Code Review: 8/10 APPROVE (2 rounds -- 5 critical + 9 major + 10 minor all fixed)
- QA: HIGH confidence, 93 tests passed, 0 failed, 4 bugs found and fixed
- Security Audit: 9/10 PASS (3 High + 2 Medium all fixed, no secrets leaked)
- Architecture Audit: 9/10 APPROVE (4 fixes: business logic placement, query optimization, code dedup, null-safety)
- Hacker Audit: 7/10 (2 critical flow bugs fixed, 5 significant fixes total)
- Final Verdict: SHIP at 9/10, HIGH confidence

### Deferred

- Web WebSocket support for messaging (v1 uses HTTP polling at 5s)
- Web typing indicators (component exists at `typing-indicator.tsx`, awaiting WebSocket)
- Quick-message from trainee list row on web (must open trainee detail first)
- Message editing and deletion
- File/image attachments in messages
- Message search

---

## [2026-02-19] — Web Dashboard Full Parity + UI/UX Polish + E2E Tests (Pipeline 19)

### Added

- **Trainer Announcements (Web)** -- Full CRUD with pin sort, character counters, format toggle (plain/markdown), skeleton loading, empty state.
- **Trainer AI Chat (Web)** -- Chat interface with trainee selector dropdown, suggestion chips, clear conversation dialog, AI provider availability check.
- **Trainer Branding (Web)** -- Color pickers with 12 presets per field, hex input validation, logo upload/remove, live preview card, unsaved changes guard with beforeunload.
- **Exercise Bank (Web)** -- Responsive card grid, debounced search (300ms), muscle group filter chips, create exercise dialog, exercise detail dialog.
- **Program Assignment (Web)** -- Assign/change program dialog on trainee detail page with program dropdown.
- **Edit Trainee Goals (Web)** -- 4 macro fields (protein, carbs, fat, calories) with min/max validation and inline error messages.
- **Remove Trainee (Web)** -- Confirmation dialog requiring "REMOVE" text match before deletion.
- **Subscription Management (Web)** -- Stripe Connect 3-state flow (not connected, setup incomplete, fully connected), plan overview card.
- **Calendar Integration (Web)** -- Google auth popup, calendar connection cards, events list display.
- **Layout Config (Web)** -- 3 radio-style layout options (classic/card/minimal) with optimistic update and rollback.
- **Impersonation (Web)** -- Button + confirm dialog (partial -- full token swap deferred to backend integration).
- **Mark Missed Day (Web)** -- Skip/push radio selection, date picker, program selector.
- **Feature Requests (Web)** -- Vote toggle, status filters (all/open/planned/completed), create dialog with title/description, comment hooks.
- **Leaderboard Settings (Web)** -- Toggle switches per metric_type/time_period combination with optimistic update.
- **Admin Ambassador Management (Web)** -- Server-side search, full CRUD dialogs, commission rate editing, bulk approve/pay operations.
- **Admin Upcoming Payments & Past Due (Web)** -- Lists with severity color coding (green/amber/red), reminder email button (stub).
- **Admin Settings (Web)** -- Platform configuration, security notice, profile/appearance/security sections.
- **Ambassador Dashboard (Web)** -- Earnings stat cards, referral code with clipboard copy, recent referrals list.
- **Ambassador Referrals (Web)** -- Status filter (all/pending/active/churned), paginated list with status badges.
- **Ambassador Payouts (Web)** -- Stripe Connect 3-state setup flow, payout history table with status badges.
- **Ambassador Settings (Web)** -- Profile display, referral code edit with alphanumeric validation.
- **Ambassador Auth & Routing (Web)** -- Middleware-based routing for AMBASSADOR role, `(ambassador-dashboard)` route group, layout with sidebar nav and auth guards.
- **Login Page Redesign** -- Two-column layout with animated gradient background, floating fitness icons, framer-motion staggered text animation, feature pills, prefers-reduced-motion support.
- **Page Transitions** -- PageTransition wrapper component with fade-up animation using framer-motion on all dashboard pages.
- **Skeleton Loading** -- Content-shaped skeleton placeholders on all data pages (not generic spinners).
- **Micro-Interactions** -- Button active:scale-95 press feedback, card-hover CSS utility with elevation transition, prefers-reduced-motion media query.
- **Dashboard Trend Indicators** -- Extended StatCard with TrendingUp/TrendingDown icons and green/red coloring.
- **Error States** -- ErrorState component with retry button deployed on all data-fetching pages.
- **Empty States** -- EmptyState component with contextual icons and action CTAs on all list pages.
- **Playwright E2E Test Suite** -- Configuration with 5 browser targets (Chromium, Firefox, WebKit, Mobile Chrome, Mobile Safari). 19 test files covering auth flows, trainer features (7), admin features (3), ambassador features (4), responsive behavior, error states, dark mode, and navigation. Test helpers: `loginAs()`, `logout()`, mock-api fixtures.

### Fixed

- **CRITICAL: LeaderboardSection type mismatch** -- Component referenced `setting.id`, `setting.metric`, `setting.label`, `setting.enabled` and `METRIC_DESCRIPTIONS` which did not exist on the `LeaderboardSetting` type from the hook. The hook returns `{ metric_type, time_period, is_enabled }` with no numeric `id`. Complete rewrite with composite key function (`metric_type:time_period`), display name helper, and correct mutation payload.
- **CRITICAL: StripeConnectSetup type cast** -- Component cast data as `{ is_connected?: boolean }` but the `AmbassadorConnectStatus` type has `has_account` (not `is_connected`). Removed unsafe cast, now uses `data?.has_account` and `data?.payouts_enabled` directly.
- **Ambassador list redundant variable** -- Removed `const filtered = ambassadors;` that was identical to `ambassadors`. All references updated.

### Accessibility

- Focus-visible rings (`focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`) added to exercise list filter chips, feature request status filters, and branding color picker buttons (24 buttons total)
- `aria-label` added to ambassador list View button (`View details for {email}`)
- `role="status"` on EmptyState component, `role="alert"` with `aria-live="assertive"` on ErrorState component
- `prefers-reduced-motion` support on login animations and card-hover transitions

### Quality Metrics

- Code Review: 8/10 APPROVE (1 round -- 5 critical + 8 major all fixed)
- QA: HIGH confidence, 52/60 AC pass, 0 failures (3 partial documented, 5 deferred non-blocking)
- UX Audit: 8/10 (1 critical type mismatch fixed, 4 medium accessibility fixes, 5 total fixes applied)
- Security Audit: 9/10 PASS (no secrets, no XSS vectors, proper JWT lifecycle, no critical/high issues)
- Architecture Audit: 8/10 APPROVE (1 type mismatch fixed, clean layered pattern across 124 files)
- Hacker Audit: 8/10 (0 dead UI beyond 2 known stubs, 0 console.log, 0 TODOs, 1 cosmetic fix)
- Final Verdict: SHIP at 8/10, HIGH confidence

### Deferred

- AC-11: Full impersonation token swap (needs backend integration)
- AC-22: Ambassador monthly earnings chart and referral stats row
- AC-33: Onboarding checklist for new trainers
- AC-26: Community announcements (covered by trainer management)
- AC-27: Community tab (backend not connected)
- Past due reminder email (currently a toast.info stub)
- Server-side pagination on ambassador list UI

---

## [2026-02-16] — Phase 8 Community & Platform Enhancements (Pipeline 18)

### Added

- **Leaderboards** — New `Leaderboard` and `LeaderboardEntry` models. Trainer-configurable ranked leaderboards with workout count and streak metrics. Dense ranking algorithm (1, 2, 2, 4). Opt-in/opt-out per trainee with `show_on_leaderboard` field. Leaderboard screen with skeleton loading, empty state ("No leaderboard data yet"), error state with retry. Leaderboard service with `LeaderboardEntry` dataclass returns.
- **Push Notifications (FCM)** — `DeviceToken` model with platform detection (iOS/Android). Firebase Cloud Messaging integration via `firebase-admin` SDK. `NotificationService` with `send_push_notification()` for single and `send_bulk_push()` for batch delivery. Notification triggers on new announcements and new comments. Device token CRUD API (`POST/DELETE /api/community/device-tokens/`). Platform-specific payload formatting (iOS badge count, Android notification channel).
- **Rich Text / Markdown** — `content_format` field on CommunityPost and Announcement models (`plain`/`markdown` choices). `flutter_markdown` rendering on mobile with theme-aware styling. Server-side format validation in serializers. Backward-compatible with existing plain text content.
- **Image Attachments** — `image` ImageField on CommunityPost. Multipart upload endpoint with content-type validation (JPEG/PNG/WebP only), 5MB server-side limit, 5MB client-side validation with user-friendly error message. UUID-based filenames to prevent path traversal. Full-screen pinch-to-zoom image viewer (`InteractiveViewer` with `minScale: 1.0`, `maxScale: 4.0`). Loading shimmer placeholder (250dp height, 12dp border radius) and error state for image loading.
- **Comment Threads** — `Comment` model with ForeignKey to CommunityPost. Flat comment system with cursor pagination. Author delete + trainer moderation delete. `comment_count` annotation on feed queries for N+1 prevention. Comments bottom sheet with real-time count updates. Push notifications sent to post author on new comments.
- **Real-time WebSocket** — Django Channels `CommunityFeedConsumer` with JWT authentication via query parameter (`?token=<JWT>`). Channel layer group per trainer (`community_feed_{trainer_id}`). 4 broadcast event types: `new_post`, `post_deleted`, `new_comment`, `reaction_update` (all with timestamps). Close codes: 4001 (auth failure), 4003 (no trainer). Ping/pong heartbeat. Mobile `CommunityWsService` with exponential backoff reconnection (3s base delay, 5 max attempts). Typed message handling for all 4 event types.
- **Stripe Connect Ambassador Payouts** — `AmbassadorPayout` model with Stripe transfer tracking. Stripe Connect Express account onboarding (`POST /api/ambassador/stripe/onboard/`). Admin-triggered payouts (`POST /api/admin/ambassador/payouts/trigger/`) with `select_for_update()` + `transaction.atomic()` for race condition protection. Payout history screen with status badges (pending/paid/failed). `PayoutService` with `PayoutResult` dataclass returns. Ambassador payouts screen with empty state (wallet icon + descriptive text).

### Changed

- **`backend/community/consumers.py`** — Added `feed_reaction_update` handler for real-time reaction count broadcasting. Removed unused `json` import.
- **`backend/community/views.py`** — Refactored `_get_post()` to return `tuple[CommunityPost | None, Response | None]` distinguishing 403 (wrong group) from 404 (not found). Added WebSocket broadcast helpers for all 4 event types.
- **`mobile/lib/features/community/data/services/community_ws_service.dart`** — Added `reaction_update` case handler. Implemented exponential backoff reconnection (3s, 6s, 12s, 24s, 48s).
- **`mobile/lib/features/community/presentation/providers/community_feed_provider.dart`** — Added `onReactionUpdate()`, `onNewComment()`, `onNewPost()`, `onPostDeleted()` methods for WebSocket-driven state updates.
- **`mobile/lib/features/community/presentation/widgets/community_post_card.dart`** — Image height increased 200dp to 250dp, border radius 8dp to 12dp. InteractiveViewer minScale fixed from 0.5 to 1.0. Semantics labels on full image viewer.
- **`mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart`** — Added 5MB client-side image size validation with user-friendly snackbar.

### Accessibility

- `Semantics` labels on all leaderboard entries (rank, name, metric, value)
- `Semantics` labels on comment tiles (author, content, timestamp)
- `Semantics` on full-screen image viewer (image description, close button)
- Skeleton loading placeholder for leaderboard screen matching populated layout

### Quality Metrics

- Code Review: 8/10 APPROVE (2 rounds — 6 critical + 10 major issues all fixed)
- QA: HIGH confidence, 50/61 AC pass, 0 failures (11 ACs deferred: settings toggles, markdown toolbar, notification banners — all non-blocking for V1)
- UX Audit: 8/10 (ambassador payouts empty state improved)
- Security Audit: 9/10 PASS (no critical/high vulnerabilities)
- Architecture Audit: 9/10 APPROVE (follows established patterns, no tech debt introduced)
- Hacker Audit: 8/10 (0 dead UI, 0 critical bugs, 2 low visual items, 1 low logic item)
- Final Verdict: SHIP at 8/10

---

## [2026-02-16] — Social & Community (Phase 7)

### Added

- **New `community` Django app** — 6 models (Announcement, AnnouncementReadStatus, Achievement, UserAchievement, CommunityPost, PostReaction), 13 API endpoints, 2 service modules, seed command, admin registration. Single migration with all indexes and constraints.
- **Trainer Announcements (CRUD)** — `GET/POST /api/trainer/announcements/`, `GET/PUT/DELETE /api/trainer/announcements/<id>/`. Title (200 chars), body (2000 chars), is_pinned toggle. Ordered by `is_pinned DESC, created_at DESC`. Row-level security: `trainer=request.user`.
- **Trainee Announcement Feed** — `GET /api/community/announcements/` (paginated, scoped to parent_trainer), `GET /api/community/announcements/unread-count/` (returns count of new announcements since last read), `POST /api/community/announcements/mark-read/` (upserts `AnnouncementReadStatus` with `last_read_at`).
- **Achievement/Badge System** — 15 predefined achievements across 5 criteria types: workout count (1/10/25/50/100), workout streak (3/7/14/30), weight check-in streak (7/30), nutrition streak (3/7/30), program completed (1). `check_and_award_achievements()` service with streak/count calculation, idempotent `get_or_create` awarding, and `IntegrityError` handling for concurrent calls. Hooks on workout completion, weight check-in, and nutrition logging (fire-and-forget, never blocks parent operation).
- **Community Feed** — `GET /api/community/feed/` with batch reaction aggregation (2 queries, no N+1), `POST /api/community/feed/` for text posts (1000 chars, whitespace-stripped), `DELETE /api/community/feed/<id>/` with author + trainer moderation, `POST /api/community/feed/<id>/react/` toggle endpoint for fire/thumbs_up/heart reactions. All scoped by `parent_trainer`.
- **Auto-Post Service** — `create_auto_post()` generates community posts on workout completion ("Just completed {workout_name}!") and achievement earning ("Earned the {achievement_name} badge!"). Fire-and-forget with `_SafeFormatDict` for safe template formatting.
- **Seed Command** — `python manage.py seed_achievements` creates 15 achievements idempotently via `get_or_create`.
- **Community Feed Screen** — Replaces Forums tab in bottom navigation (renamed to "Community"). Pull-to-refresh, infinite scroll pagination, shimmer skeleton loading (3 post cards matching populated layout), empty state ("No posts yet. Be the first to share!"), error state with retry.
- **Compose Post Sheet** — Bottom sheet with TextField (1000 chars, `maxLines: 5`, character counter), "Post" button, loading state (disabled field + spinner), success snackbar "Posted!", error snackbar with content preserved.
- **Reaction Bar** — Fire/thumbs_up/heart buttons with optimistic toggle updates. Active: filled background + primary color + bold count. Inactive: outlined + muted. Reverts on API error with snackbar "Couldn't update reaction."
- **Auto-Post Visual Distinction** — Tinted background (`primary.withValues(alpha: 0.05)`), type badge above content (Workout/Achievement/Milestone with matching icons) per AC-29 and AC-32.
- **Post Deletion** — PopupMenuButton "Delete" on own posts, AlertDialog confirmation ("Delete this post? This cannot be undone."), success/failure snackbars.
- **Pinned Announcement Banner** — Shown at top of community feed when trainer has a pinned announcement. InkWell with ripple feedback, navigates to full announcements screen.
- **Trainee Announcements Screen** — Full list with pinned indicators (pin icon + primary-tinted left border), pull-to-refresh. Mark-read called on screen open. Empty states for "has trainer" vs "no trainer".
- **Notification Bell** — Home screen app bar bell icon with unread count badge (red circle, white number). Fetched on home screen load. Tapping navigates to announcements screen.
- **Achievements Screen** — 3-column GridView.builder with earned (colored icon, primary border, "Earned {date}") and locked (muted 0.4 opacity, divider border) badge states. Detail bottom sheet with description and earned date. Progress summary card ("X of Y earned"). Pull-to-refresh, shimmer skeleton (6 circles), error with retry, empty state.
- **Settings Achievements Tile** — "Badges & Achievements" tile in trainee settings between TRACKING and SUBSCRIPTION sections, showing earned/total count.
- **Trainer Announcements Management Screen** — List with title, body preview, pinned indicator, relative timestamp. Swipe-to-delete with confirmation dialog. Tap to edit. FAB to create. Empty state with campaign icon.
- **Create/Edit Announcement Screen** — Title (200 chars) and body (2000 chars) fields with character counters, is_pinned toggle, loading state, success snackbar, error snackbar with data preserved.
- **Trainer Dashboard Announcements Section** — Total count with "Manage" button navigating to announcements management.
- **55 comprehensive backend tests** — Announcements (14), achievements (15), feed (17), auto-post (5), seed command (4). Covering all CRUD operations, security (IDOR, auth, authz), edge cases (no parent_trainer, concurrent operations, max lengths), and service logic (streak calculation, idempotent awarding).

### Changed

- **`main_navigation_shell.dart`** — Renamed "Forums" tab to "Community" with `people_outlined` / `people` icons.
- **`app_router.dart`** — Replaced ForumsScreen route with CommunityFeedScreen. Added 4 new routes: `/community/announcements`, `/community/achievements`, `/trainer/announcements-screen`, `/trainer/create-announcement`.
- **`api_constants.dart`** — Added 11 community endpoint constants.
- **`home_screen.dart`** — Added announcement bell with unread badge count in app bar.
- **`settings_screen.dart`** — Added ACHIEVEMENTS section with earned/total count tile.
- **`trainer_dashboard_screen.dart`** — Added Announcements management section.
- **`workouts/survey_views.py`** — Hooked `check_and_award_achievements()` and `create_auto_post()` after workout completion. `new_achievements` included in response.
- **`workouts/views.py`** — Hooked `check_and_award_achievements()` after weight check-in and nutrition save (both wrapped in try-except).
- **`config/settings.py`** — Added `'community'` to `INSTALLED_APPS`.
- **`config/urls.py`** — Added `path('api/community/', include('community.urls'))`.
- **`trainer/urls.py`** — Added trainer announcement CRUD URL patterns.

### Fixed

- **CRITICAL: Announcement pagination parsing crash** — Mobile `AnnouncementRepository.getAnnouncements()` and `getTrainerAnnouncements()` were parsing `response.data as List<dynamic>`, but DRF `ListAPIView`/`ListCreateAPIView` return paginated responses `{count, next, previous, results}`. Changed to parse as `Map<String, dynamic>` and extract `data['results']`. Would have caused a runtime `type 'Map' is not a subtype of type 'List'` crash on both trainee and trainer announcement screens.
- **Auto-post type badge placement** — Badge was below content text; AC-29 specifies "subtle label + icon above content." Moved `_buildPostTypeBadge()` above the content Text widget.
- **Auto-post visual distinction missing** — All posts used `theme.cardColor` uniformly; AC-32 specifies tinted background for auto-posts. Added conditional `post.isAutoPost ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.cardColor`.
- **Serializer misuse in AchievementListView** — `AchievementWithStatusSerializer(data=..., many=True)` was called without `.is_valid()`. Replaced with direct `Response(data)` since the serializer was passthrough.
- **Non-optimistic reaction toggle** — Reaction bar awaited API call before updating UI (200-500ms delay). Implemented optimistic update: immediate UI change, revert on API error with snackbar.
- **Missing delete confirmation dialog** — Post deletion fired immediately on "Delete" tap. Added AlertDialog with Cancel/Delete actions per AC-33.
- **Race condition with `.first` call** — `announcements.where((a) => a.isPinned).first` could throw `StateError` between `any()` check and `.first` access. Fixed with safe access pattern.

### Accessibility

- `Semantics(label: '{name}, earned/locked', button: true)` on all achievement badges with InkWell ripple feedback
- `Semantics(label: '{type} reaction, {count}, active/inactive. Tap to react/remove.', button: true)` on all reaction buttons
- `Semantics(label: 'Pinned announcement: {title}. Tap to view all.', button: true)` on announcement banner with Material+InkWell ripple
- `Semantics(label: 'Loading ...')` on all 4 screen skeleton loading states
- `Semantics(header: true)` on achievement progress summary heading
- `tooltip: 'New post'` on community feed compose FAB
- `tooltip: 'New announcement'` on trainer announcements FAB
- Achievement badge name font size increased from 11px to 12px for WCAG minimum
- GestureDetector replaced with InkWell on achievement badges and announcement banner (proper ripple feedback + touch targets)

### Architecture

- New `community` Django app cleanly separated from `trainer` and `workouts` apps (no cyclic dependencies)
- Business logic in services: `achievement_service.py` (streak calculation, idempotent awarding), `auto_post_service.py` (template formatting, fire-and-forget)
- Removed 6 unused serializers from `serializers.py`: `AchievementWithStatusSerializer`, `CommunityPostSerializer`, `PostAuthorSerializer`, `UnreadCountSerializer`, `MarkReadResponseSerializer`, `ReactionResponseSerializer`
- Database indexes on all query patterns: `(trainer, -created_at)` on Announcement and CommunityPost, `(trainer, is_pinned)` on Announcement, `(post, reaction_type)` on PostReaction, `(user, -earned_at)` on UserAchievement
- Proper unique constraints: `(user, trainer)` on AnnouncementReadStatus, `(criteria_type, criteria_value)` on Achievement, `(user, achievement)` on UserAchievement, `(user, post, reaction_type)` on PostReaction
- Mobile follows repository pattern consistently: Screen -> Provider -> Repository -> ApiClient.dio
- All widget files under 150 lines, screens under 200 lines

### Security

- All 13 endpoints verified: authentication + role-based authorization (IsTrainee/IsTrainer) + row-level security
- No IDOR vulnerabilities: 7 attack vectors tested and blocked (cross-group feed, cross-group reactions, cross-trainer announcements, non-author delete, trainee accessing trainer endpoints, trainer accessing trainee endpoints)
- Input validation: max_length on all user inputs, choice validation on reaction_type, whitespace stripping on post content
- Concurrency safe: unique constraints + `get_or_create` + `IntegrityError` catch on reactions, achievements, and read status
- No injection vectors: Django ORM only (no raw SQL), Flutter Text() widgets (no HTML interpretation)
- No secrets in code or git history
- Error messages don't leak internals

### Quality

- Code review: R1 6/10 REQUEST CHANGES -> All 3 critical + 7 major fixed -> R1 fixes applied
- QA: 55/55 PASS, HIGH confidence, all 34 ACs verified (31 DONE, 3 justified PARTIAL)
- UX audit: 8/10 PASS (13 usability/accessibility fixes)
- Security audit: 9/10 PASS (no vulnerabilities found)
- Architecture: 9/10 APPROVE (clean separation, proper indexes, no N+1, unused serializers cleaned)
- Hacker: 7/10 (2 critical runtime crash bugs found and fixed, 2 visual bugs fixed)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Health Data Integration + Performance Audit + Offline UI Polish (Phase 6 Completion)

### Added

- **HealthKit / Health Connect Integration** — Reads steps, active calories, heart rate, and weight from Apple Health (iOS) and Health Connect (Android) via the `health` Flutter package. Platform-level aggregation queries (HKStatisticsQuery / AggregateRequest) prevent double-counting from overlapping sources (e.g., iPhone + Apple Watch).
- **"Today's Health" Card** — New card on trainee home screen displaying 4 health metrics with walking/flame/heart/weight icons. Skeleton loading state, 200ms opacity fade-in, "--" for missing data, NumberFormat for thousands separators. Gear icon opens device health settings.
- **Health Permission Flow** — One-time bottom sheet with platform-specific explanation ("Apple Health" vs "Health Connect"). "Connect Health" / "Not Now" buttons. Permission status persisted in SharedPreferences. Card hidden entirely when permission denied.
- **Weight Auto-Import** — Automatically imports weight from HealthKit/Health Connect to WeightCheckIn model via existing OfflineWeightRepository. Date-based deduplication checks both server and local pending data. Notes: "Auto-imported from Health". Silent failure (background operation).
- **Pending Workout Merge** — Local pending workouts from Drift merged into Home "Recent Workouts" list at top with `SyncStatusBadge`. Tapping shows "Pending sync" snackbar.
- **Pending Nutrition Merge** — Local pending nutrition entries merged into Nutrition screen macro totals for selected date. "(includes X pending)" label below macro cards with cloud_off icon.
- **Pending Weight Merge** — Local pending weight check-ins merged into Weight Trends history list and "Latest Weight" display on Nutrition screen. Pending entries show SyncStatusBadge.
- **DAO Query Methods** — `getPendingWorkoutsForUser()`, `getPendingNutritionForUser()`, `getPendingWeightCheckins()` in Drift DAOs for offline data access.
- **`syncCompletionProvider`** — Riverpod provider exposing sync completion events. Home, Nutrition, and Weight Trends screens listen and refresh pending data reactively.
- **`HealthMetrics` Dataclass** — Immutable typed model with const constructor, equality operators, toString(). Replaces Map<String, dynamic> returns.
- **`HealthDataNotifier`** — Sealed class state hierarchy: Initial, Loading, Loaded, PermissionDenied, Unavailable. Manages permission lifecycle, data fetching, and weight auto-import with mounted guards.

### Changed

- **`health_service.dart`** — Rewritten: added ACTIVE_ENERGY_BURNED and WEIGHT types, removed SLEEP_IN_BED. Uses `getTotalStepsInInterval()` and `getHealthAggregateDataFromTypes()` for platform-level deduplication. Injectable via Riverpod provider (no more static singleton). Fixed HealthDataPoint value extraction bug.
- **`home_screen.dart`** — Added TodaysHealthCard between Nutrition and Weekly Progress sections. Pending workouts merged into recent list. RepaintBoundary on CalorieRing and MacroCircle. Riverpod select() for granular health card visibility rebuilds. syncCompletionProvider listener.
- **`nutrition_screen.dart`** — Pending nutrition macros added to server totals. "(includes X pending)" label. RepaintBoundary on MacroCard. IconButton replacing GestureDetector for touch targets. syncCompletionProvider listener.
- **`nutrition_provider.dart`** — Loads pending nutrition and weight data in parallel. Merges pending macros into totals. Latest weight considers both server and local data.
- **`weight_trends_screen.dart`** — Converted to CustomScrollView + SliverList.builder for virtualized rendering. Pending weight rows with SyncStatusBadge. RepaintBoundary on weight chart. shouldRepaint optimization comparing data arrays.

### Performance

- RepaintBoundary on CalorieRing, MacroCircle, MacroCard, weight chart CustomPaint
- const constructors audited across priority widget files
- Riverpod select() for granular rebuilds (home screen health card visibility)
- SliverList.builder replacing Column + map().toList() in weight trends
- shouldRepaint optimization on weight chart painter (data comparison vs always true)
- Static final NumberFormat instances (avoid re-creation per build)

### Accessibility

- Semantics labels on all health metric tiles, sync status badges, skeleton states
- ExcludeSemantics on decorative icons
- Semantics liveRegion on "(includes X pending)" label
- Minimum 32dp touch targets on all interactive elements
- Tooltips on icon buttons

---

## [2026-02-15] — Offline-First Workout & Nutrition Logging (Phase 6)

### Added

- **Drift (SQLite) Local Database** — 5 tables: `PendingWorkoutLogs`, `PendingNutritionLogs`, `PendingWeightCheckins`, `CachedPrograms`, `SyncQueueItems`. Background isolate via `NativeDatabase.createInBackground()`. WAL mode for concurrent read/write. Startup cleanup (synced items >24h, stale cache >30d). Transactional user data clearing on logout.
- **Connectivity Monitoring** — `ConnectivityService` wrapping `connectivity_plus` with 2-second debounce to prevent sync thrashing during connection flapping. Handles Android multi-result edge case (`[wifi, none]` reports online, not offline).
- **Offline-Aware Repositories** — Decorator pattern: `OfflineWorkoutRepository`, `OfflineNutritionRepository`, `OfflineWeightRepository` wrap existing online repos. When online, delegate to API. When offline, save to Drift + sync queue. UUID-based `clientId` idempotency prevents duplicate submissions. Storage-full `SqliteException` caught with user-friendly messages.
- **Sync Queue Engine** — `SyncService` with FIFO sequential processing, exponential backoff (5s, 15s, 45s), max 3 retries before permanent failure. HTTP 409 conflict detection with operation-specific messages (no auto-retry). 401 auth error handling (pauses sync, preserves data). Corrupted JSON and unknown operation types handled gracefully.
- **Program Caching** — Programs cached in Drift on successful API fetch. Offline fallback with "Showing cached program. Some data may be outdated." banner. Corrupted cache detected, deleted, and reported gracefully. Active workout screen works fully offline with cached data.
- **Offline Banner** — 4 visual states: offline (amber, cloud_off), syncing (blue, LinearProgressIndicator, "Syncing X of Y..."), synced (green, auto-dismiss 3s), failed (red, tap to open failed sync sheet). Semantics liveRegion for screen readers. AnimatedSwitcher transitions.
- **Failed Sync Bottom Sheet** — `DraggableScrollableSheet` listing each failed item with operation type icon, description, error message, Retry/Delete buttons. Retry All in header. Auto-close when empty.
- **Logout Warning** — Both home screen and settings screen check `unsyncedCountProvider`. Dialog shows count of unsynced items with "Cancel" / "Logout Anyway" options. `clearUserData()` runs in a transaction.
- **Typed `OfflineSaveResult`** — Replaces `Map<String, dynamic>` returns from offline save operations with typed `success`, `offline`, `error`, `data` fields.
- **`SyncStatusBadge` widget** — 16x16 badge with 12px icons for pending/syncing/failed states. Ready for per-card placement in follow-up.
- **`network_error_utils.dart`** — Shared `isNetworkError()` function (DRY, was triplicated across 3 offline repos).
- **`SyncOperationType` and `SyncItemStatus` enums** — Centralized enums with `fromString()` parsers replacing magic strings.

### Changed

- **`mobile/lib/main.dart`** — Initializes `AppDatabase` and `ConnectivityService` before `runApp`. Overrides providers in `ProviderScope`.
- **`active_workout_screen.dart`** — `submitPostWorkoutSurvey` and `submitReadinessSurvey` now use `OfflineWorkoutRepository`. Offline save snackbar with cloud_off icon. `late final _workoutClientId` for idempotency.
- **`workout_log_screen.dart`** — Added `OfflineBanner` at top. Shows "Showing cached program" banner when programs from cache.
- **`weight_checkin_screen.dart`** — Uses `OfflineWeightRepository`. Added `_isSaving` flag (prevents double-submit). Success snackbar for both online and offline saves.
- **`ai_command_center_screen.dart`** — Offline notice banner when device is offline (AI parsing requires network). Offline save feedback snackbar.
- **`home_screen.dart`** — Added `OfflineBanner`. Logout checks `unsyncedCountProvider` with warning dialog.
- **`settings_screen.dart`** — All three logout buttons use `_handleLogout` with pending sync check and warning dialog.
- **`logging_provider.dart`** — `LoggingNotifier` uses `OfflineNutritionRepository`. `savedOffline` field in `LoggingState`.
- **`workout_provider.dart`** — `WorkoutNotifier` accepts `OfflineWorkoutRepository`. `programsFromCache` flag for cache banner.
- **`nutrition_screen.dart`** — Added `OfflineBanner` at top of screen body.
- **`pubspec.yaml`** — Added `connectivity_plus: ^6.0.0`, `uuid: ^4.0.0`, `sqlite3: ^2.9.0`.

### Security

- No secrets, API keys, or credentials in any committed file (regex scan verified)
- All SQLite queries use Drift parameterized builder (no raw SQL, no injection vectors)
- userId filtering in every DAO query prevents cross-user data access
- Sync uses existing JWT auth via `ApiClient` with token refresh
- 401 handling preserves user data for retry after re-authentication
- Error messages are user-friendly, no internal details leaked
- Transactional dual-inserts (pending data + sync queue) prevent orphaned data
- Transactional user data cleanup on logout
- Corrupted JSON in cache/queue handled gracefully (no crashes)

### Fixed

- **Infinite retry loop** — `retryItem()` was used for both manual and automatic retries, resetting `retryCount` to 0 each time. Added `requeueForRetry()` for automatic retries that preserves retryCount. Manual retries (`retryItem`) correctly reset to 0 for a fresh set of attempts.
- **Connectivity false-negative on Android** — `_mapResults()` now only reports offline when `ConnectivityResult.none` is the sole result, handling the `[wifi, none]` edge case documented in `connectivity_plus`.
- **Weight check-in double-submit** — Added local `_isSaving` flag with proper setState management. Button disabled during async save.
- **Missing weight check-in success feedback** — Added success snackbar for online saves (previously screen popped with no feedback).
- **Synced badge showing green icon** — Changed to `SizedBox.shrink()` per AC-38 (synced items should show no badge).
- **Non-atomic local save operations** — Wrapped dual inserts (pending table + sync queue) in `transaction()` in all 3 offline repos.
- **Non-atomic user data cleanup** — Wrapped all 5 deletes in `clearUserData()` in `transaction()`.
- **Recursive stack growth** — `_processQueue()` recursion via `_pendingRestart` now uses `Future.microtask()`.
- **Corrupted JSON crashes app** — `_getProgramsFromCache()` catches `FormatException`, deletes corrupt cache, returns graceful error.

### Quality

- Code review: 7.5/10 APPROVE (2 rounds — 4 critical + 9 major all fixed)
- QA: 33/42 AC pass, MEDIUM-HIGH confidence, 1 critical bug found and fixed
- Security audit: 9/10 PASS (1 medium fixed, 0 critical/high)
- Architecture review: 8/10 APPROVE (6 issues fixed)
- Hacker report: 7/10 (5 fixes applied, 13 edge cases verified clean)
- Final verdict: 8/10 SHIP, HIGH confidence

### Deferred

- AC-12: Merge local pending workouts into Home "Recent Workouts" list
- AC-16: Merge local pending nutrition into macro totals
- AC-18: Merge local pending weight check-ins into weight trends
- AC-36/37/38: Place SyncStatusBadge on individual cards in list views
- Background health data sync (HealthKit / Health Connect) -- separate ticket
- App performance audit (60fps, RepaintBoundary) -- separate ticket

---

## [2026-02-15] — Ambassador Enhancements (Phase 5)

### Added

- **Monthly Earnings Chart** — fl_chart BarChart on ambassador dashboard showing last 6 months of commission earnings. Skeleton loading state, empty state for zero data, accessibility semantics on chart elements.
- **Native Share Sheet** — share_plus package integration for native iOS/Android share dialog. Automatic fallback to clipboard on unsupported platforms (emulators, web). Broad exception catch handles MissingPluginException.
- **Commission Approval/Payment Workflow** — Full admin workflow for commission lifecycle (PENDING → APPROVED → PAID). Individual and bulk operations (up to 200 per request). `CommissionService` with atomic transactions, `select_for_update` concurrency control, frozen-dataclass results following `ReferralService` pattern. Admin mobile UI with confirmation dialogs, per-commission loading indicators (`Set<int>`), and "Pay All" bulk button.
- **Custom Referral Codes** — Ambassadors can set custom 4-20 character alphanumeric codes (e.g., "JOHN20"). Triple-layer validation: serializer uniqueness check (fast-path UX), DB unique constraint (ultimate guard), `IntegrityError` catch (TOCTOU race condition). Edit dialog in ambassador settings with auto-uppercase and server error display.
- **Ambassador Password Validation** — Django `validate_password()` applied to admin-created ambassador accounts via `AdminCreateAmbassadorSerializer`.
- **`BulkCommissionActionResult`** — Typed Dart model replacing raw `Map<String, dynamic>` returns from bulk commission repository methods.
- **3 extracted sub-widgets** — `AmbassadorProfileCard` (167 lines), `AmbassadorReferralsList` (117 lines), `AmbassadorCommissionsList` (261 lines) decomposed from 900-line monolithic screen.

### Changed

- `referral_code` max_length widened from 8 to 20 characters (migration 0003, `AlterField` only, fully reversible)
- Commission service logic extracted from views into dedicated `CommissionService` following `ReferralService` pattern
- `AdminAmbassadorDetailView.get()` reuses paginator's cached count instead of issuing redundant SQL COUNT queries
- Individual approve/pay buttons disabled during bulk processing to prevent conflicting actions
- Share exception catch broadened from `PlatformException` to `catch (_)` for `MissingPluginException` compatibility
- All-zero earnings chart now shows empty state instead of invisible zero-height bars
- Currency display uses comma-grouped formatting ($10,500.00 instead of 10500.00)
- Long referral codes wrapped in `FittedBox(fit: BoxFit.scaleDown)` to prevent overflow

### Security

- State transition guards on `AmbassadorCommission.approve()` and `mark_paid()` — `ValueError` for invalid state transitions
- Bulk operations capped at 200 IDs with automatic deduplication via `validate_commission_ids`
- Django password validation on admin-created ambassador accounts
- `select_for_update()` prevents concurrent double-processing of commissions
- No secrets, API keys, or credentials in any committed file

### Quality

- Code review: 8/10 APPROVE (2 rounds — all issues fixed)
- QA: 34/34 AC pass, HIGH confidence, 0 bugs
- Security audit: 9/10 PASS (3 fixes applied)
- Architecture review: 8/10 APPROVE (4 fixes applied)
- Hacker report: 7/10 (8 fixes applied)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Admin Dashboard (Completes Web Dashboard Phase 4)

### Added

- **Admin Dashboard Overview** — `/admin/dashboard` with stat cards (MRR, trainers, trainees), revenue cards (past due, upcoming payments), tier breakdown, and past due alerts with "View All" link.
- **Trainer Management** — `/admin/trainers` with searchable/filterable list, detail dialog with subscription info, activate/suspend toggle, and impersonation flow (stores admin tokens in sessionStorage).
- **Subscription Management** — `/admin/subscriptions` with multi-filter list (status, tier, past due, upcoming). Detail dialog with 4 action forms: change tier, change status, record payment, admin notes. Payment History and Change History tabs.
- **Tier Management** — `/admin/tiers` with CRUD dialogs, toggle active (optimistic update), seed defaults for empty state, delete protection for tiers with active subscriptions.
- **Coupon Management** — `/admin/coupons` with CRUD dialogs, applicable tiers multi-select, revoke/reactivate lifecycle, detail dialog with usage history. Status/type/applies_to filters. Auto-uppercase codes.
- **User Management** — `/admin/users` with role-filtered list, create admin/trainer accounts, edit users, self-deletion/self-deactivation protection.
- **Admin Layout** — Separate `(admin-dashboard)` route group with admin sidebar, admin nav links, impersonation banner.
- **`admin-constants.ts`** — Centralized TIER_COLORS, SUBSCRIPTION_STATUS_VARIANT, COUPON_STATUS_VARIANT, SELECT_CLASSES constants.
- **`format-utils.ts`** — Shared `formatCurrency()` with cached `Intl.NumberFormat`, `formatDiscount()` for coupon display.

### Changed

- **`auth-provider.tsx`** — Extended to accept ADMIN role. Sets role cookie after login for middleware routing.
- **`middleware.ts`** — Added admin route protection: checks role cookie, blocks non-admin from `/admin/*` routes.
- **`token-manager.ts`** — Added `setRoleCookie()`, optional `role` parameter on `setTokens()`, cleanup in `clearTokens()`.
- **`constants.ts`** — Added 20+ admin API URL constants.
- **`impersonation-banner.tsx`** — Restores ADMIN role cookie on end-impersonation, sets TRAINER role on start.

### Security

- Three-layer admin auth: Edge middleware (role cookie) → Layout component (server user check) → Backend API (`IsAdminUser`)
- Role cookie is client-writable (documented limitation) — backend authorization is the true security boundary
- Impersonation tokens scoped to sessionStorage (tab isolation), hard page reload on end clears React Query cache
- No secrets, XSS vectors, or IDOR vulnerabilities found

### Quality

- Code review: 8/10 APPROVE (2 rounds — 3 critical + 8 major all fixed)
- QA: 46/49 AC pass, MEDIUM confidence (3 design deviations: dialogs vs dedicated pages)
- UX audit: 16 usability + 6 accessibility fixes
- Security audit: 8.5/10 PASS (1 High fixed: middleware route protection)
- Architecture: 8/10 APPROVE (5 deduplication fixes, centralized constants)
- Hacker audit: 7/10 (13 fixes across 10 files — overflow protection, error states, same-value guards)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 4 (Trainer Program Builder)

### Added

- **Program List Page** — `/programs` route with DataTable showing program templates (name, difficulty badge, goal, duration, times used, created date). Search with `useDeferredValue`, pagination, empty state with "Create Program" CTA. Three-dot action menu with Edit (owner only), Assign to Trainee, Delete (owner only).
- **Program Builder** — Two-card layout (metadata + schedule). Name (100 chars) and description (500 chars) with live character counters and amber warning at 90%. Duration (1-52 weeks), difficulty, and goal selects with lowercase enum values matching Django TextChoices. Week tabs with horizontal scroll. 7 days per week (Mon-Sun), rest day toggle with exercise loss confirmation. Exercise picker dialog with multi-add, search, muscle group filter, truncation warning ("Showing X of Y"). Exercise rows with sets (1-20), reps (1-100 or string ranges), weight (0-9999), unit (lbs/kg), rest (0-600s). Up/down reorder. Max 50 exercises per day. Copy Week to All feature. Ctrl/Cmd+S keyboard shortcut.
- **Assignment Flow** — Dialog with trainee dropdown (up to 200 via `useAllTrainees`), date picker with local timezone default. Empty trainee state with "Send Invitation" CTA.
- **Delete Flow** — Confirmation dialog with times_used warning. Prevents close during API call. "Cannot be undone" copy.
- **`error-utils.ts`** — Shared `getErrorMessage()` for extracting DRF field-level validation error messages. Used across program-builder, assign-program-dialog, and delete-program-dialog.
- **Backend: JSON field validation** — `validate_schedule_template()` (512KB max, 52 weeks, 7 days/week structure validation) and `validate_nutrition_template()` (64KB max, dict validation) on `ProgramTemplateSerializer`.
- **Backend: SearchFilter** — Added `filter_backends = [SearchFilter]` with `search_fields = ['name', 'description']` to `ProgramTemplateListCreateView`.
- **`reconcileSchedule()`** — Syncs schedule weeks with duration when trainer changes week count. Pads new weeks with default 7-day structure, trims excess weeks with confirmation.

### Changed

- **`nav-links.tsx`** — Added Programs nav item with `Dumbbell` icon between Trainees and Invitations.
- **`constants.ts`** — Added `PROGRAM_TEMPLATES`, `programTemplateDetail(id)`, `programTemplateAssign(id)`, `EXERCISES` API URL constants.
- **`use-trainees.ts`** — `useAllTrainees()` hook moved here from `use-programs.ts` (architecture fix).
- **`program-list.tsx`** — Columns memoized with `useMemo`. Program name is clickable link to edit page for owners.
- **Backend: `ProgramTemplateSerializer`** — `is_public` and `image_url` added to `read_only_fields` (security fix).

### Accessibility

- All form inputs have visible labels, `aria-label`, and proper `htmlFor`/`id` associations
- `role="group"` with descriptive `aria-label` on exercise rows for screen reader grouping
- `aria-invalid` on whitespace-only program names with `role="alert"` error message
- Move/delete buttons include exercise name in `aria-label` (e.g., "Move Bench Press up")
- `DialogDescription` on all dialogs for screen reader context
- Focus-visible rings on all interactive elements including `<select>` elements
- Week tabs have `aria-label="Week N of M"`

### UX

- Dirty state tracking: `hasMountedRef` skips initial mount (no false "unsaved changes" warning), `beforeunload` event only when dirty, cancel button confirms when dirty
- Double-click prevention: `savingRef` guard + `<fieldset disabled={isSaving}>` disables entire form during save
- Data loss prevention: Confirmation when reducing duration (removes populated weeks), confirmation when toggling rest day with exercises
- Character counters with amber warning at 90% capacity on name and description fields
- "Back to Programs" navigation link on create and edit pages
- Truncation warning on exercise picker when results exceed page_size
- Green checkmark on already-added exercises in multi-select picker
- "Done (N added)" button text in exercise picker footer

### Quality

- Code review: 8/10 APPROVE (2 rounds — 4 critical + 8 major issues all fixed in round 1)
- QA: 27/27 AC pass, HIGH confidence (3 minor input clamping bugs fixed)
- UX audit: 9/10 (19 usability + 10 accessibility fixes)
- Security audit: 8/10 CONDITIONAL PASS (2 High fixed: JSON validation, read-only fields)
- Architecture: 9/10 APPROVE (3 fixes: hook placement, missing type field, column memoization)
- Hacker audit: 16 items fixed (multi-add dialog, Cmd+S, copy week, exercise cap, data loss confirmations)
- Final verdict: 8/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 3 (Trainer Analytics Page)

### Added

- **Trainer Analytics Page** — New `/analytics` route with two independent sections: Adherence and Progress. Nav link added between Invitations and Notifications.
- **Adherence Section** — Three `StatCard` components (Food Logged, Workouts Logged, Protein Goal Hit) with color-coded values: green (≥80%), amber (50-79%), red (<50%). Text descriptions ("Above target", "Below target", "Needs attention") for WCAG 1.4.1 color-only compliance.
- **Adherence Bar Chart** — Horizontal recharts `BarChart` with per-trainee adherence rates sorted descending. Theme-aware colors via CSS custom properties (`--chart-2`, `--chart-4`, `--destructive`). Click-through navigation to trainee detail page. Custom YAxis tick with SVG `<title>` for truncated name tooltips.
- **Period Selector** — 7d/14d/30d tab-style radio group with WAI-ARIA radiogroup pattern: roving tabindex, arrow key navigation (Left/Right/Up/Down), `aria-checked`, `aria-label` with expanded text. `disabled` prop during initial load. Focus-visible rings and active press states.
- **Progress Section** — `DataTable` with 4 columns: trainee name (truncated with title tooltip), current weight, weight change (with TrendingUp/TrendingDown icons and goal-aligned coloring), and goal. Click-through to trainee detail.
- **`AdherencePeriod` type** — Union type `7 | 14 | 30` for compile-time safety on period selector and React Query hook.
- **`chart-utils.ts`** — Shared module with `tooltipContentStyle` and `CHART_COLORS` constants, eliminating duplication between progress-charts.tsx and adherence-chart.tsx.
- **`StatCard` `valueClassName` prop** — Extended shared component with optional `valueClassName` for colored analytics values. Backward-compatible.

### Changed

- **`nav-links.tsx`** — Added Analytics nav item with `BarChart3` icon at index 3 (between Invitations and Notifications).
- **`constants.ts`** — Added `ANALYTICS_ADHERENCE` and `ANALYTICS_PROGRESS` API URL constants.
- **`progress-charts.tsx`** — Refactored to import `tooltipContentStyle` and `CHART_COLORS` from shared `@/lib/chart-utils` instead of local definitions.

### Accessibility

- Screen-reader accessible chart: `role="img"` with descriptive `aria-label` + sr-only `<ul>` listing all trainee adherence data
- `aria-busy` attribute on sections during background refetch with sr-only live region announcements
- Skeleton loading states with `role="status"` and `aria-label`
- `aria-label="No data"` on em-dash placeholder spans in progress table
- `getIndicatorDescription()` text labels complement color-only stat card indicators (WCAG 1.4.1)

### Quality

- Code review: 9/10 APPROVE (2 rounds — 2 critical + 7 major issues all fixed in round 1)
- QA: 21/22 AC pass, HIGH confidence (1 deliberate copy improvement)
- UX audit: 9/10 (shared StatCard, WCAG fixes, responsive header, disabled period selector, sr-only live regions)
- Security audit: 9/10 PASS (0 Critical/High/Medium issues)
- Architecture: 9/10 APPROVE (extracted shared chart-utils, extended StatCard, eliminated 3 duplication instances)
- Hacker audit: 7/10 (theme-aware amber, scroll trap fix, isFetching on progress, trainee counts)
- Final verdict: 9/10 SHIP, HIGH confidence

---

## [2026-02-15] — Web Dashboard Phase 2 (Settings, Charts, Notifications, Invitations)

### Added

- **Settings Page** — Three sections: Profile (name, business name, image upload/remove), Appearance (Light/Dark/System theme toggle), Security (password change with inline Djoser error parsing). Loading skeleton, error state with retry.
- **Progress Charts** — Trainee detail Progress tab now renders three recharts visualizations: weight trend (LineChart), workout volume (BarChart), adherence (stacked BarChart). Theme-aware colors via CSS custom properties. Per-chart empty states with contextual icons. Safe date parsing via `parseISO`/`isValid`.
- **Notification Click-Through** — Notifications with `trainee_id` in data now navigate to `/trainees/{id}`. ChevronRight visual affordance for navigable notifications. Popover auto-closes on navigation. Non-navigable notifications show "Marked as read" toast.
- **Invitation Row Actions** — Three-dot dropdown menu per invitation row: Copy Code (clipboard), Resend (POST, resets expiry), Cancel (with confirmation dialog). Status-aware action visibility: PENDING shows all, EXPIRED hides Cancel, ACCEPTED/CANCELLED shows Copy only.
- **Auth `refreshUser()`** — `AuthProvider` now exposes `refreshUser()` method. Profile/image mutations call it so the header nav updates immediately without full page reload.

### Changed

- **`api-client.ts`** — Added `postFormData()` method; `buildHeaders()` skips `Content-Type: application/json` for FormData bodies (lets browser set `multipart/form-data` boundary).
- **`notification-bell.tsx`** — Controlled Popover state for programmatic close. Conditionally renders `NotificationPopover` only when open (prevents unnecessary API calls).

### Accessibility

- Theme selector implements proper ARIA radiogroup keyboard navigation (arrow keys, roving tabIndex, focus management)
- Password fields have `aria-describedby` and `aria-invalid` attributes linking to error messages
- Email field has `aria-describedby="email-hint"` for the read-only explanation
- Notification popover loading state has `role="status"` and `aria-label`
- Image upload spinner has `aria-hidden="true"`

### Quality

- Code review: 8/10 APPROVE (2 rounds — all critical/major issues fixed)
- QA: 27/28 AC pass, HIGH confidence (1 partial is pre-existing backend gap)
- UX audit: 9/10 (10 usability + 6 accessibility fixes implemented)
- Security audit: 9/10 PASS (0 Critical/High/Medium issues)
- Architecture: 9/10 APPROVE (extracted shared tooltip styles, theme-aware chart colors)
- Hacker audit: 7/10 (isDirty tracking, dropdown close-on-action, toast feedback, layout consistency fixes)

---

## [2026-02-15] — Web Trainer Dashboard (Next.js Foundation)

### Added

- **Web Trainer Dashboard** — Complete Next.js 15 + React 19 web application for trainers at `http://localhost:3000`. ~100 frontend files using shadcn/ui component library, TanStack React Query for data fetching, and Zod v4 for form validation.
- **JWT Auth System** — Login with email/password, automatic token refresh with mutex (prevents thundering herd), session cookie for Next.js middleware route protection, TRAINER role gating (non-trainer users rejected immediately), 10-second auth timeout via `Promise.race`.
- **Dashboard Page** — 4 stats cards (Total Trainees, Active Today, On Track, Pending Onboarding) in responsive grid, recent trainees table (last 10), inactive trainees alert list. Skeleton loading, error with retry, empty state with "Send Invitation" CTA.
- **Trainee Management** — Searchable paginated list with 300ms debounce, full-row click navigation, DataTable with integrated pagination ("Page X of Y (N total)"). Detail page with 3 tabs: Overview (profile, nutrition goals, programs), Activity (7/14/30 day filter with goal badges), Progress (placeholder).
- **Notification System** — Bell icon with unread badge (30s polling, "99+" cap), popover showing last 5 with "View all" link, full page with server-side "All"/"Unread" filtering via `?is_read=false`, mark individual as read, mark all as read with success/error toasts, pagination.
- **Invitation Management** — Table with color-coded status badges (Pending=amber, Accepted=green, Expired=muted, Cancelled=red), smart expired-pending detection. Create dialog with Zod validation: email, optional message (500 char limit with counter), expires days (1-30, integer step).
- **Responsive Layout** — Fixed 256px sidebar on desktop (`lg+`), Sheet drawer on mobile, header with hamburger/bell/avatar dropdown. Skip-to-content link for keyboard users.
- **Dark Mode** — Full support via CSS variables and next-themes with system preference default. All components use theme-aware color tokens.
- **Docker Integration** — Multi-stage `node:20-alpine` Dockerfile with non-root `nextjs` user (uid 1001), standalone output. Added `web` service to `docker-compose.yml` on port 3000.
- **Security Headers** — `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(), microphone=(), geolocation=()`. Removed `X-Powered-By` header.
- **Shared Components** — `DataTable<T>` (generic paginated table with row click + keyboard nav), `EmptyState` (icon + title + CTA), `ErrorState` (alert with retry), `LoadingSpinner` (configurable aria-label), `PageHeader` (title + description + actions).
- **Accessibility** — 16 WCAG fixes: `role="status"` on loading/empty states, `role="alert"` on error states, `aria-hidden="true"` on all decorative icons (10+ files), `aria-current="page"` on active nav links, `aria-label` on pagination/notification/user-menu buttons, skip-to-content link, keyboard-accessible table rows (tabIndex, Enter/Space, focus ring), `aria-label="Main navigation"` on sidebars.
- **Input Protection** — `maxLength` on all inputs (email 254, password 128, message 500), `step={1}` on integer fields, `required` attributes, double-submit prevention (`isSubmitting` / `isPending` guards).
- **`SearchFilter`** added to `TraineeListView` backend — enables `?search=` query parameter for trainee search by email, first_name, last_name.

### Changed (Backend Performance)

- **6 N+1 query patterns eliminated:**
  - `TraineeListView.get_queryset()` — Added `.select_related('profile').prefetch_related('daily_logs', 'programs')`
  - `TraineeDetailView.get_queryset()` — Added `.select_related('profile', 'nutrition_goal').prefetch_related('programs', 'activity_summaries')`
  - `TrainerDashboardView.get()` — Replaced Python loop for inactive trainees with `Max` annotation query, added prefetching
  - `TrainerStatsView.get()` — Replaced Python loop for pending_onboarding with single `.filter().count()` query
  - `AdherenceAnalyticsView.get()` — Replaced per-trainee N+1 loop with `.values().annotate(Case/When)` aggregation
  - `ProgressAnalyticsView.get()` — Added `.select_related('profile').prefetch_related('weight_checkins')`
- **4 bare `except:` clauses** replaced with specific `RelatedObjectDoesNotExist` exceptions in serializers
- **Serializer prefetch optimization** — `get_last_activity()` and `get_current_program()` iterate prefetched data in Python instead of issuing new queries
- **Query param bounds** — `days` parameter clamped to 1-365 with try/except fallback
- **TypeScript/API alignment** — `DashboardOverview.today` field added to match backend response

### Security

- No secrets in source code (full grep scan, `.env.local` gitignored)
- Three-layer auth: Next.js middleware + dashboard layout guard + AuthProvider role validation
- No XSS vectors (zero `dangerouslySetInnerHTML`, `eval`, `innerHTML` usage — React auto-escaping)
- No IDOR (backend row-level security via `parent_trainer` queryset filter on all endpoints)
- JWT in localStorage with refresh mutex (accepted SPA tradeoff, no XSS vectors to exploit)
- Cookie `Secure` flag applied consistently on both set and delete operations
- Generic error messages — no stack traces, SQL errors, or internal paths exposed
- Backend rate limiting: 30/min anonymous, 120/min authenticated
- Docker non-root user (nextjs, uid 1001)
- CORS: development allows all origins; production restricts to env-configured whitelist

### Quality

- Code review: 8/10 — APPROVE (Round 2, all 17 Round 1 issues verified fixed, 2 new major fixed post-QA)
- QA: 34/35 ACs pass initially (AC-12 fixed by UX audit), 7/7 edge cases pass — HIGH confidence
- UX audit: 8/10 — 8 usability + 16 accessibility issues fixed across 15+ files
- Security audit: 9/10 — PASS (0 Critical, 0 High, 2 Medium both fixed)
- Architecture review: 8/10 — APPROVE (10 issues including 6 N+1 patterns, all fixed)
- Hacker report: 6/10 — 3 dead UI, 9 visual bugs, 12 logic bugs found; 20 items fixed
- Overall quality: 8/10 — SHIP

---

## [2026-02-14] — Trainee Workout History + Home Screen Recent Workouts

### Added

- **Workout History API** — `GET /api/workouts/daily-logs/workout-history/` paginated endpoint returning computed summary fields (workout_name, exercise_count, total_sets, total_volume_lbs, duration_display) from workout_data JSON. `GET /api/workouts/daily-logs/{id}/workout-detail/` for full workout data with restricted serializer.
- **`WorkoutHistorySummarySerializer`** — Computes workout summaries from DailyLog.workout_data JSON blob. Handles both `exercises` and `sessions` key formats.
- **`WorkoutDetailSerializer`** — Restricted serializer exposing only id, date, workout_data, notes (excludes trainee email, nutrition_data).
- **`DailyLogService.get_workout_history_queryset()`** — Service-layer queryset builder with DB-level JSON filtering (excludes null, empty dict, empty exercises). Uses `Q` objects for `has_key` lookups and `.defer('nutrition_data')` for performance.
- **WorkoutHistoryScreen** — Paginated list with shimmer skeleton loading, pull-to-refresh, infinite scroll (200px trigger), empty state with "Start a Workout" CTA, styled error with retry.
- **WorkoutDetailScreen** — Full workout detail with real-header shimmer (uses available summary data during loading), exercise cards with sets table (set#, reps, weight, unit, completed icon), pre/post-workout survey badges with color-coded scores, error retry.
- **Home Screen Recent Workouts** — "Recent Workouts" section showing last 3 completed workouts as compact cards. 3-card shimmer loading, styled error with retry, empty state text. "See All" button navigates to full history.
- **`WorkoutDetailData` class** — Data-layer class for centralized JSON extraction logic (exercises, readiness survey, post-workout survey) with factory constructor.
- **`WorkoutHistoryCard` + `StatChip`** — Extracted widgets with responsive `Wrap` layout (prevents overflow on narrow screens).
- **`ExerciseCard`, `SurveyBadge`, `HeaderStat`, `SurveyField`** — Extracted detail widgets with theme-aware colors.
- **Route guards** — `/workout-detail` redirects to `/workout-history` if extra data is invalid.
- **Accessibility** — `Semantics` labels on all new interactive widgets (WorkoutHistoryCard, RecentWorkoutCard, ExerciseCard, SurveyBadge, HeaderStat), `liveRegion` on error/empty states, `ExcludeSemantics` to prevent duplicate announcements.
- **48 new backend tests** — Filtering (7), serialization (15), pagination (9), security (5), detail (8), edge cases (6). Tests verify auth, IDOR prevention, data leakage, and malformed JSON handling.

### Changed

- **`DailyLogService`** — Extracted `get_workout_history_queryset()` from view to service layer per project architecture conventions.
- **`WorkoutHistoryPagination`** — Custom pagination class with `page_size=20`, `max_page_size=50`.
- **Home screen** — Added `recentWorkoutsError` field to `HomeState` for distinguishing API failure from empty data. Section header "See All" uses `InkWell` with Material ripple feedback instead of `GestureDetector`.
- **`workout_history_provider.dart`** — `loadMore()` clears stale errors with `clearError: true` before retrying.
- **Test infrastructure** — Converted `workouts/tests.py` into package with `__init__.py`, `test_surveys.py`, `test_workout_history.py`.

### Security

- Both endpoints require `IsTrainee` (authenticated + trainee role)
- Row-level security via queryset filter `trainee=user` (IDOR returns 404, not 403)
- `WorkoutHistorySummarySerializer` excludes trainee, email, nutrition_data
- `WorkoutDetailSerializer` exposes only id, date, workout_data, notes
- `.defer('nutrition_data')` defense-in-depth (not loaded from DB)
- `max_page_size=50` prevents resource exhaustion
- Generic error messages — no internal details leaked
- 30 security-relevant tests verify auth, authz, IDOR, data leakage

### Quality

- Code review: 8/10 — APPROVE (Round 3, all 2 Critical + 5 Major from Round 2 fixed)
- QA: 48/48 tests pass, 1 bug found and fixed (PostgreSQL NULL semantics) — HIGH confidence
- UX audit: 8/10 — 9 usability + 7 accessibility issues fixed
- Security audit: 9.5/10 — PASS (0 Critical/High issues)
- Architecture review: 9/10 — APPROVE (2 issues fixed: service extraction, data class)
- Hacker report: 7/10 — 4 items fixed (overflow, accessibility, volume display, pagination retry)
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — AI Food Parsing + Password Change + Invitation Emails

### Added

- **AI Food Parsing Activation** — Removed "AI parsing coming soon" banner from AI Entry tab. Added meal selector (1-4) with InkWell touch feedback and Semantics labels. Added `_confirmAiEntry()` with empty meals validation, nutrition refresh after save, icon-enhanced success/error snackbars with retry action. Changed button label from "Log Food" to "Parse with AI" for clarity. Added helper text and concrete input examples.
- **Password Change Screen** — New `ChangePasswordScreen` in Settings → Security. Calls Djoser's `POST /api/auth/users/set_password/` via new `AuthRepository.changePassword()` method. Inline error under "Current Password" field for wrong password. Green success snackbar with icon + auto-pop. Network/server error handling with descriptive messages.
- **Password Strength Indicator** — Color-coded progress bar (Weak/Fair/Good/Strong) on new password field with helper text.
- **Invitation Email Service** — New `backend/trainer/services/invitation_service.py` with `send_invitation_email()`. HTML + plain text email templates with trainer name, invite code, registration URL, expiry date. XSS prevention via `django.utils.html.escape()` on all user-supplied values. URL scheme auto-detection (HTTP for localhost, HTTPS for production). URL-encoded invite codes.
- **`ApiConstants.setPassword`** — New endpoint constant for Djoser password change.
- **Expired Invitation Resend** — Resend endpoint now accepts EXPIRED invitations, resets status to PENDING, extends expiry by 7 days.
- **Accessibility Improvements** — Semantics live regions on error/clarification/preview containers. Autofill hints on password fields (`'password'`, `'newPassword'`). TextInputAction flow (next → next → done). Tooltips on show/hide password buttons. 48dp minimum touch targets on meal selector. Theme-aware colors for light/dark mode.

### Changed

- **Meal prefix on AI-parsed food** — `LoggingNotifier.confirmAndSave()` accepts optional `mealPrefix` parameter. AI-parsed foods saved with "Meal N - " prefix matching manual entry flow.
- **Password fields** — Added focus borders, error borders, `enableSuggestions: false`, `autocorrect: false` for secure input. Outlined visibility icons.
- **Login history section** — Added "PREVIEW ONLY" badge to clarify mock data.
- **Invitation resend query** — Added `select_related('trainer')` to prevent N+1 query.

### Security

- All user input HTML-escaped in invitation email templates (XSS prevention)
- URL scheme auto-detected based on domain (prevents broken links on localhost)
- Invite code URL-encoded for defense-in-depth
- TYPE_CHECKING imports with proper `User` type hints (no `type: ignore`)
- All invitation endpoints require `IsAuthenticated + IsTrainer`
- Row-level security: `trainer=request.user` on all queries
- Password change uses Djoser's built-in endpoint with Django validators

### Quality

- Code review: 9/10 — APPROVE (Round 2, 2 critical + 3 major from Round 1 all fixed)
- QA: 17/17 ACs PASS, 12/12 edge cases, 0 bugs — HIGH confidence
- UX audit: 8.5/10 — 23 usability + 8 accessibility issues fixed
- Security audit: 8.5/10 — PASS (1 CRITICAL URL scheme fixed)
- Architecture review: 10/10 — APPROVE (exemplary architecture, zero issues)
- Hacker report: 7/10 — 2 items fixed, 1 CRITICAL verified as false alarm
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — Trainee Home Experience + Password Reset

### Added

- **Password Reset Flow** — Full forgot/reset password screens using Djoser's built-in email endpoints. ForgotPasswordScreen with email input, loading state, success view with spam folder hint. ResetPasswordScreen with uid/token route params, password strength indicator, validation. Email backend configured (console for dev, SMTP for prod via env vars).
- **Weekly Workout Progress** — New `GET /api/workouts/daily-logs/weekly-progress/` endpoint returning `{total_days, completed_days, percentage, has_program}`. Home screen shows animated progress bar (hidden when no program). Data fetched in parallel with other dashboard data.
- **Food Entry Edit/Delete** — New `PUT /api/workouts/daily-logs/<id>/edit-meal-entry/` and `POST /api/workouts/daily-logs/<id>/delete-meal-entry/` endpoints with input key whitelisting, numeric validation, and automatic total recalculation. Mobile EditFoodEntrySheet bottom sheet with pre-filled form, save/delete buttons, confirmation dialog.
- **EditMealEntrySerializer / DeleteMealEntrySerializer** — Proper DRF serializers for food edit/delete input validation (architecture audit improvement).
- **Date filtering on DailyLog list** — `GET /api/workouts/daily-logs/?date=YYYY-MM-DD` now filters by date (critical fix: was silently ignoring date param).

### Changed

- **Login screen** — "Forgot password?" button now navigates to ForgotPasswordScreen (was showing "Coming soon!" snackbar).
- **Home screen notification button** — Shows info dialog ("Notifications coming soon") instead of being a dead button.
- **ProgramViewSet logging** — Removed verbose email logging, changed to debug level (architecture audit improvement).
- **Nutrition edit/delete** — Uses `refreshDailySummary()` instead of `loadInitialData()` after changes (1 API call instead of 5).
- **Weekly progress domain** — Moved `getWeeklyProgress()` from NutritionRepository to WorkoutRepository (correct domain boundary).

### Security

- Input key whitelisting on meal entry edits (prevents arbitrary JSON injection)
- DELETE-with-body changed to POST for proxy compatibility
- No email enumeration in password reset (204 regardless of email existence)
- Race condition guard (`_isEditingEntry`) prevents concurrent food edits
- Row-level security on all new endpoints (trainee can only edit own logs)

---

## [2026-02-14] — Trainer Notifications Dashboard + Ambassador Commission Webhook

### Added

- **Trainer Notification API** — 5 endpoints: `GET /api/trainer/notifications/` (paginated, `?is_read` filter), `GET /api/trainer/notifications/unread-count/`, `POST /api/trainer/notifications/<id>/read/`, `POST /api/trainer/notifications/mark-all-read/`, `DELETE /api/trainer/notifications/<id>/`. All protected by `[IsAuthenticated, IsTrainer]` with row-level security.
- **Ambassador Commission Webhook** — `_handle_invoice_paid()` creates commissions from actual Stripe invoice `amount_paid` (not cached subscription price). `_handle_checkout_completed()` handles first platform subscription payment. `_handle_subscription_deleted()` triggers `ReferralService.handle_trainer_churn()`. `_create_ambassador_commission()` helper looks up referral, validates active ambassador, extracts billing period.
- **Notification Bell Badge** — `NotificationBadge` widget on trainer dashboard with unread count (shows "99+" for >99), theme-colored, screen reader accessible.
- **Notifications Screen** — Full paginated feed with date grouping ("Today", "Yesterday", "Feb 12"), `NotificationCard` with type-based icons (7 types), unread dot, relative timestamps, swipe-to-dismiss with undo snackbar, mark-all-read with confirmation dialog.
- **Optimistic UI** — All mutations (mark-read, mark-all-read, delete) update state immediately and revert on API failure.
- **Pagination** — `AsyncNotifierProvider` with `loadMore()` guard against concurrent requests, loading indicator at bottom of list.
- **Accessibility** — `Semantics` wrappers on notification cards (read status + type + title + time), badge (count-aware label), mark-all-read button.
- **90 new tests** — 59 notification view tests (auth, permissions, row-level security, pagination, filtering, idempotency) + 31 ambassador webhook tests (commission creation, churn handling, lifecycle, edge cases).
- Database migration: `trainer/migrations/0005_*` (index optimization).

### Changed

- **Index optimization** (`trainer/models.py`) — Removed standalone `notification_type` index (never queried alone). Changed `(trainer, created_at)` to `(trainer, -created_at)` descending to match query pattern.
- **Webhook symmetry** (`payment_views.py`) — Extended `_handle_invoice_payment_failed()` and `_handle_subscription_updated()` to handle both `TraineeSubscription` and `Subscription` models, matching dual-model pattern.
- **Skeleton loader** — Replaced static containers with shared animated `LoadingShimmer` widget.
- **Empty/error states** — Both wrapped in `RefreshIndicator` + `LayoutBuilder` + `SingleChildScrollView` for pull-to-refresh.
- **Safe JSON parsing** (`trainer_notification_model.dart`) — Uses `is Map<String, dynamic>` type check instead of unsafe `as` cast for `data` field.

### Security

- No secrets in committed code (grepped all new/changed files)
- All notification endpoints authenticated + authorized (IsTrainer)
- Row-level security: every query filters `trainer=request.user`
- No IDOR: trainer A cannot read/modify trainer B's notifications
- Webhook signature verification in place (pre-existing `stripe.Webhook.construct_event`)
- Commission creation uses `select_for_update` + `UniqueConstraint` for race condition protection

### Quality

- Code review: 8/10 — APPROVE (Round 2, all Round 1 issues fixed)
- QA: 90/90 tests pass, 0 bugs — HIGH confidence
- UX audit: 8/10 — 15 improvements (shimmer, undo, accessibility, conditional buttons)
- Security audit: 9/10 — PASS (no critical/high issues)
- Architecture review: 9/10 — APPROVE (index optimization, webhook symmetry)
- Hacker report: 8/10 — 5 edge-case fixes (safe JSON cast, exception logging, clock skew guard)
- Overall quality: 9/10 — SHIP

---

## [2026-02-14] — Ambassador User Type & Referral Revenue Sharing

### Added

- **AMBASSADOR user role** — New `User.Role.AMBASSADOR` with `is_ambassador()` helper method, `IsAmbassador` and `IsAmbassadorOrAdmin` permission classes.
- **AmbassadorProfile model** — OneToOne to User with `referral_code` (unique 8-char alphanumeric, auto-generated with collision retry), `commission_rate` (DecimalField, default 0.20), `is_active`, cached `total_referrals` and `total_earnings`.
- **AmbassadorReferral model** — Tracks ambassador-to-trainer referrals with 3-state lifecycle: PENDING (registered) -> ACTIVE (first payment) -> CHURNED (cancelled), with reactivation support.
- **AmbassadorCommission model** — Monthly commission records with rate snapshot at creation time, `UniqueConstraint` on (referral, period_start, period_end) to prevent duplicates.
- **Ambassador API endpoints** — `GET /api/ambassador/dashboard/` (aggregated stats, monthly earnings, recent referrals), `GET /api/ambassador/referrals/` (paginated, status-filterable), `GET /api/ambassador/referral-code/` (code + share message).
- **Admin ambassador management API** — `GET /api/admin/ambassadors/` (search, active filter), `POST /api/admin/ambassadors/create/` (with password), `GET/PUT /api/admin/ambassadors/<id>/` (detail with paginated referrals/commissions, update rate/status).
- **ReferralService** — `process_referral_code()` (registration integration), `create_commission()` (with `select_for_update` locking and duplicate period guard), `handle_trainer_churn()` (bulk update).
- **Registration integration** — Optional `referral_code` field on `UserCreateSerializer`, restricted role choices to TRAINEE/TRAINER only (prevents ADMIN/AMBASSADOR self-registration).
- **Ambassador mobile shell** — `StatefulShellRoute` with 3 tabs: Dashboard, Referrals, Settings. Router redirect for ambassador users.
- **Ambassador dashboard screen** — Gradient earnings card, referral code card with copy/share, stats row (total/active/pending/churned), recent referrals list with status badges.
- **Ambassador referrals screen** — Filterable list (All/Active/Pending/Churned), pull-to-refresh, status badges, subscription tier, commission earned per referral.
- **Ambassador settings screen** — Profile info, commission rate (read-only), referral code, total earnings, logout with confirmation dialog.
- **Admin ambassador screens** — Searchable list with active/inactive filter, create form with password + commission rate slider, detail screen with commission history and rate editing dialog.
- **Referral code on registration** — Optional field shown when TRAINER role selected, `maxLength: 8`, `textCapitalization: characters`.
- **Accessibility** — Semantics widgets on all interactive elements, 48dp minimum touch targets (InkWell), screen reader labels for stat tiles, nav items, and referral cards.
- **Rate limiting** — Global `DEFAULT_THROTTLE_CLASSES` (anon: 30/min, user: 120/min), `RegistrationThrottle` (5/hour).
- **CORS hardening** — `CORS_ALLOW_ALL_ORIGINS` now conditional on `DEBUG`; production reads `CORS_ALLOWED_ORIGINS` from environment variable.
- Database migrations: `ambassador/migrations/0001_initial.py`, `ambassador/migrations/0002_alter_ambassadorreferral_unique_together_and_more.py`, `users/migrations/0005_alter_user_role.py`.
- New file: `backend/core/throttles.py` with `RegistrationThrottle` class.

### Changed

- `users/serializers.py` — Role choices restricted to `[(TRAINEE, 'Trainee'), (TRAINER, 'Trainer')]`, single `create_user()` call instead of two DB writes, referral code processing integrated.
- `config/urls.py` — Ambassador admin URLs mounted at `/api/admin/ambassadors/` (split from ambassador app URLs).
- `config/settings.py` — Added `ambassador` to `INSTALLED_APPS`, throttle classes, conditional CORS.
- `core/permissions.py` — Added `IsAmbassador` and `IsAmbassadorOrAdmin` permission classes.

### Security

- Registration role escalation prevention (ADMIN/AMBASSADOR roles blocked from self-registration)
- Race condition protection: `select_for_update()` on commission creation, `IntegrityError` retry on code generation
- DB-level `UniqueConstraint` on (referral, period_start, period_end) prevents duplicate commissions
- Cryptographic referral code generation (`secrets.choice`, 36^8 = 2.8 trillion code space)
- No IDOR: all ambassador queries filter by `request.user`

### Quality

- Code review: 3 rounds. Round 1: BLOCK (5/10) -> 12 fixes. Round 2: REQUEST CHANGES (7.5/10) -> 3 fixes. Round 3: APPROVE.
- QA: 25/25 acceptance criteria PASS (4 URL routing issues fixed in QA round)
- UX audit: 8/10 — 12 usability + 10 accessibility issues fixed
- Security audit: 9/10 — PASS (5 critical/high issues fixed)
- Architecture review: 8/10 — APPROVE (6 issues fixed: atomicity, DRY, pagination, typed models, bulk updates)
- Hacker report: 6/10 chaos — 10 items fixed (unusable password, crash bug, missing commission display, filter persistence)
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-14] — White-Label Branding Infrastructure

### Added

- **TrainerBranding model** — OneToOne to User with `app_name`, `primary_color`, `secondary_color`, `logo` (ImageField). Auto-creates with defaults via `get_or_create_for_trainer()` classmethod.
- **branding_service.py** — Service layer for image validation and logo operations. `validate_logo_image()` performs 5-layer defense-in-depth validation (content-type, file size, Pillow format, dimensions, filename). `upload_trainer_logo()` and `remove_trainer_logo()` handle business logic.
- **Trainer API endpoints** — `GET/PUT /api/trainer/branding/` for config management, `POST/DELETE /api/trainer/branding/logo/` for logo upload/removal. IsTrainer permission, row-level security via OneToOne.
- **Trainee API endpoint** — `GET /api/users/my-branding/` returns parent trainer's branding or defaults. IsTrainee permission.
- **BrandingScreen** — Trainer-facing branding editor with app name field, 12-preset color picker (primary + secondary), logo upload/preview, and live preview card. Extracted into 3 sub-widgets: `BrandingPreviewCard`, `BrandingLogoSection`, `BrandingColorSection`.
- **Theme branding override** — `ThemeNotifier.applyTrainerBranding()` / `clearTrainerBranding()` with SharedPreferences caching (hex-string format). Trainer's primary/secondary colors override default theme throughout the app.
- **Dynamic splash screen** — Shows trainer's logo (with loading spinner) and app name instead of hardcoded "FitnessAI" when branding is configured.
- **Shared branding sync** — `BrandingRepository.syncTraineeBranding()` static method shared between splash and login screens. Fetches, applies, and caches branding.
- **Unsaved changes guard** — `PopScope` wrapper shows confirmation dialog when navigating away with unsaved changes.
- **Reset to defaults** — AppBar overflow menu option to reset all branding to FitnessAI defaults.
- **Accessibility labels** — Semantics wrappers on all interactive branding elements (buttons, color swatches, logo image, preview card).
- **Luminance-based contrast** — Color picker indicators and preview button text adapt based on color brightness for WCAG compliance.
- **84 comprehensive backend tests** — Model, views, serializer, permissions, row-level security, edge cases (unicode, rapid updates, multi-trainer isolation).
- Database migration: `trainer/migrations/0004_add_trainer_branding.py`.
- **Dead settings buttons fixed** — 5 empty `onTap` handlers in settings_screen.dart now show "Coming soon!" SnackBars.

### Changed

- `splash_screen.dart` — Uses `ref.watch(themeProvider)` for reactive branding updates during animation. Added `loadingBuilder` for logo network images.
- `login_screen.dart` — Fetches branding after trainee login via shared `syncTraineeBranding()`.
- `theme_provider.dart` — Extended `AppThemeState` with `trainerBranding`, `effectivePrimary`, `effectivePrimaryLight`. `TrainerBrandingTheme` uses hex-string format for consistent caching.
- `branding_repository.dart` — All methods return typed `BrandingResult` class instead of `Map<String, dynamic>`. Specific exception catches (`DioException`, `FormatException`).

### Security

- UUID-based filenames for logo uploads (prevents path traversal)
- HTML tag stripping in `validate_app_name()` (prevents stored XSS)
- File size bypass fix (`is None or` instead of `is not None and`)
- Generic error messages (no internal details leaked)
- 5-layer image validation (content-type + Pillow format + size + dimensions + filename)

### Quality

- Code review: 8/10 — APPROVE (Round 2, all 17 Round 1 issues fixed)
- QA: 84/84 tests pass, 0 bugs — HIGH confidence
- UX audit: 8/10 — 9 issues fixed
- Security audit: 9/10 — PASS (5 issues fixed)
- Architecture review: 8.5/10 — APPROVE (service layer extracted)
- Hacker report: 7/10 — 12 items fixed
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-14] — Trainer-Selectable Workout Layouts

### Added

- **WorkoutLayoutConfig model** — OneToOne per trainee with layout_type (classic/card/minimal), config_options JSONField, and configured_by FK for audit trail.
- **Trainer API endpoints** — `GET/PUT /api/trainer/trainees/<id>/layout-config/` with auto-create default and row-level security (parent_trainer check).
- **Trainee API endpoint** — `GET /api/workouts/my-layout/` with IsTrainee permission and graceful fallback to 'classic' when no config exists.
- **ClassicWorkoutLayout widget** — All exercises in scrollable ListView with full sets tables, previous weight/reps, add set, and complete buttons.
- **MinimalWorkoutLayout widget** — Compact collapsible tiles with circular progress indicators, expand/collapse, and quick-complete.
- **Workout Display section** in trainer's trainee detail Overview tab — segmented control with Classic/Card/Minimal options, optimistic update with rollback on failure.
- Error state with retry button on layout picker when API fetch fails.
- `validate_config_options()` on serializer — rejects non-dict and oversized (>2048 char) payloads.
- Database migration: `trainer/migrations/0003_add_workout_layout_config.py`.

### Changed

- `active_workout_screen.dart` — Added `_layoutType` state variable and `_buildExerciseContent` switch statement to render Classic/Card/Minimal based on API config.
- Card layout uses existing `_ExerciseCard` PageView (no new widget needed).

### Quality

- Code review: 9/10 backend, 8.5/10 mobile — APPROVE (Round 2)
- QA: 13/13 acceptance criteria PASS, Confidence HIGH
- Security audit: 9/10 — PASS
- Architecture review: 8.6/10 — APPROVE
- UX audit: 7.5/10 — Fixes applied
- Hacker report: 7.5/10 — 4 issues fixed
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-13] — Fix All 5 Trainee-Side Workout Bugs

### Fixed

- **CRITICAL — Workout data now persists to database.** `PostWorkoutSurveyView` writes to `DailyLog.workout_data` via `_save_workout_to_daily_log()` with `transaction.atomic()` and `get_or_create`. Multiple workouts per day merge into a `sessions` list while preserving a flat `exercises` list for backward compatibility.
- **HIGH — Trainer notifications now fire correctly.** Changed `getattr(user, 'trainer', None)` to `user.parent_trainer` in both `ReadinessSurveyView` and `PostWorkoutSurveyView`. Created missing `TrainerNotification` database migration.
- **HIGH — Real program schedules shown instead of sample data.** Removed `_generateSampleWeeks()` and `_getSampleExercises()` fallbacks from workout provider. Proper empty states for: no programs assigned, empty schedule, no workouts this week.
- **MEDIUM — Debug print statements removed.** All 15+ `print('[WorkoutRepository]...')` statements removed from `workout_repository.dart`.
- **MEDIUM — Program switcher implemented.** Bottom sheet with full program list, active program indicator, snackbar confirmation, and `WorkoutNotifier.switchProgram()` for state update.

### Added

- Comprehensive Django test suite: 10 tests covering workout persistence, merge logic, trainer notifications, edge cases, and auth.
- Error state UI with retry button on workout log screen.
- Accessibility tooltips on icon buttons in workout log header.
- `TrainerNotification` database migration (`trainer/migrations/0002_add_trainer_notification.py`).

### Removed

- ~130 lines of hardcoded sample workout data (`_generateSampleWeeks`, `_getSampleExercises`).
- 2 stale TODO comments in `active_workout_screen.dart` that falsely suggested code was unimplemented.

### Changed

- `DailyLog.workout_data` JSON schema extended with `sessions` array to support multiple workouts per day (backward compatible).

### Quality

- Security audit: 9/10 — PASS
- Architecture review: 8/10 — APPROVE
- UX audit: 7/10 — Acceptable
- Overall quality: 8/10 — SHIP

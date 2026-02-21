# Security Audit: Smart Program Generator

## Audit Date
2026-02-21

## Files Audited

### Backend (New)
- `backend/workouts/services/program_generator.py` -- Core generator service (725 lines)
- `backend/trainer/views.py` -- `GenerateProgramView` (lines 626-669)
- `backend/trainer/serializers.py` -- `GenerateProgramRequestSerializer`, `GeneratedProgramResponseSerializer`, `CustomDayConfigSerializer` (lines 362-459)
- `backend/trainer/urls.py` -- Route registration (line 58)
- `backend/workouts/views.py` -- `ExerciseViewSet` difficulty filter addition (lines 85-92)
- `backend/workouts/management/commands/classify_exercises.py` -- Exercise difficulty classifier (340 lines)
- `backend/workouts/management/commands/seed_kilo_exercises.py` -- KILO exercise seeder (127 lines)
- `backend/workouts/ai_prompts.py` -- `get_exercise_classification_prompt()` (lines 82-121)
- `backend/workouts/fixtures/kilo_exercises.json` -- 6391-line exercise database fixture
- `backend/workouts/tests/test_program_generator.py` -- 1595-line test suite

### Web Frontend (New)
- `web/src/components/programs/program-generator-wizard.tsx` -- Main wizard component
- `web/src/components/programs/generator/split-type-step.tsx` -- Step 1 UI
- `web/src/components/programs/generator/config-step.tsx` -- Step 2 UI
- `web/src/components/programs/generator/preview-step.tsx` -- Step 3 UI
- `web/src/components/programs/generator/custom-day-config.tsx` -- Custom day configurator
- `web/src/hooks/use-programs.ts` -- `useGenerateProgram()` mutation hook
- `web/src/types/program.ts` -- TypeScript type definitions

### Mobile (New)
- `mobile/lib/features/programs/presentation/screens/program_generator_screen.dart` -- Flutter wizard screen
- `mobile/lib/features/programs/data/repositories/program_repository.dart` -- `generateProgram()` method
- `mobile/lib/core/constants/api_constants.dart` -- `generateProgram` endpoint constant

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (DRF serializers + React auto-escaping + Flutter text rendering)
- [x] Authentication checked on all new endpoints (`IsAuthenticated` + `IsTrainer`)
- [x] Authorization -- correct role/permission guards (only trainers can generate programs; trainer_id is derived from authenticated user, not request body)
- [x] No IDOR vulnerabilities (trainer_id sourced from `request.user`, not user input; exercise pool scoped by `is_public` OR `created_by=trainer_id`)
- [x] No file uploads in this feature
- [x] Rate limiting -- relies on global DRF throttling (`user: 120/minute`)
- [x] Error messages don't leak internals (generic 500 message; `ValueError` messages are from our own code)
- [x] CORS policy appropriate (handled globally by Django corsheaders middleware)

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

**SQL Injection Analysis:**
All database queries use Django ORM exclusively. No raw SQL anywhere in the changed files.
- `_prefetch_exercise_pool()` uses `Exercise.objects.filter()` with `Q` objects -- safe.
- `ExerciseViewSet.get_queryset()` uses ORM `filter()` with `icontains` for search -- safe.
- `seed_kilo_exercises.py` uses `get_or_create()` -- safe.
- `classify_exercises.py` uses `bulk_update()` and `values_list()` -- safe.

**XSS Analysis:**
- Web: No `dangerouslySetInnerHTML` in any new component. All user-supplied strings (program name, description, exercise names, error messages) rendered via JSX text interpolation, which React auto-escapes.
- Web: `sessionStorage.setItem("generated-program", JSON.stringify(generatedData))` stores API response data -- not user-controlled text directly. When read back by the builder, it's parsed as JSON and rendered through React components. No XSS vector.
- Mobile: Flutter's `Text()` widget auto-escapes. No HTML rendering anywhere.
- Backend: The `exercise_name` field returned in the schedule JSON comes from the `Exercise.name` database column, not from raw user input. Trainer-created exercise names are saved via the existing serializer-validated exercise creation flow.

**Command Injection Analysis:**
- `classify_exercises.py` calls `openai.OpenAI()` API -- no shell commands executed.
- `seed_kilo_exercises.py` reads a JSON file via `Path.resolve()` and `json.load()` -- no shell commands.
- No `subprocess`, `os.system`, or `eval` calls in any changed file.

**Path Traversal Analysis:**
- `seed_kilo_exercises.py` line 28: `Path(__file__).resolve().parent.parent.parent / "fixtures" / "kilo_exercises.json"` -- hardcoded relative path from the command file. No user input in the path construction. Safe.

## Auth & Authz Issues

| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

**Detailed Auth Analysis:**

1. **GenerateProgramView (POST `/api/trainer/program-templates/generate/`)**
   - Permission classes: `[IsAuthenticated, IsTrainer]` -- correctly restricts to authenticated trainers only.
   - `trainer_id` is sourced from `cast(User, request.user).id` at line 643-644, NOT from request body. This prevents IDOR where a trainer could inject another trainer's ID.
   - Test coverage: `test_unauthenticated_returns_401`, `test_trainee_returns_403`, `test_trainer_returns_200` (lines 1201-1213).

2. **Exercise Pool Privacy (IDOR Prevention)**
   - `_prefetch_exercise_pool()` at line 359: `privacy_q = Q(is_public=True)` with `if trainer_id: privacy_q |= Q(created_by_id=trainer_id)`.
   - This correctly scopes the exercise pool to public exercises + only the authenticated trainer's custom exercises.
   - Other trainers' private exercises are excluded. Verified by tests: `test_privacy_other_trainer_private_exercises_excluded` (line 462-480), `test_other_trainer_does_not_see_private_exercises` (line 1397-1416).

3. **ExerciseViewSet difficulty_level Filter**
   - The new difficulty filter (lines 85-92) validates against `Exercise.DifficultyLevel.choices` before applying the filter. Invalid values return an empty queryset, preventing unfiltered data exposure.
   - Existing permission classes (`IsAuthenticated`) and role-based `get_queryset()` remain intact.

4. **Management Commands** (`classify_exercises.py`, `seed_kilo_exercises.py`)
   - These are CLI-only commands invoked via `python manage.py`. They have no HTTP endpoints and are not accessible via the API. Secure by design.

## Data Exposure Analysis

**API Response Shape (GeneratedProgramResponseSerializer):**
The response includes:
- `name`, `description`: Auto-generated strings from our code, not user input.
- `schedule`: Contains `exercise_id`, `exercise_name`, `muscle_group`, `sets`, `reps`, `rest_seconds`, `weight`, `unit`. These are all exercise metadata -- no sensitive user data.
- `nutrition_template`: Static template data based on goal type. No user-specific data.
- `difficulty_level`, `goal_type`, `duration_weeks`: Echo of request parameters.

No sensitive data (emails, passwords, payment info, personal health data) is exposed in the generated program response.

**Error Message Safety:**
- `ValueError` exceptions (line 648-652): These are raised by our own `generate_program()` for invalid input (e.g., missing `custom_day_config`). The message text is controlled by us -- safe.
- Generic `Exception` handler (line 653-658): Returns `"Program generation failed. Please try again."` -- no stack trace or internal details leaked. Exception is logged server-side via `logger.exception()` -- correct practice.
- Serializer validation errors (line 638-639): DRF field-level errors (e.g., `"split_type: \"invalid\" is not a valid choice."`) -- standard DRF behavior, no internal leaks.

## Input Validation Analysis

**Backend Validation (GenerateProgramRequestSerializer):**
| Field | Validation | Notes |
|-------|-----------|-------|
| `split_type` | ChoiceField: `ppl`, `upper_lower`, `full_body`, `bro_split`, `custom` | Closed set -- safe |
| `difficulty` | ChoiceField: `beginner`, `intermediate`, `advanced` | Closed set -- safe |
| `goal` | ChoiceField: 6 valid values | Closed set -- safe |
| `duration_weeks` | IntegerField, min=1, max=52 | Bounded -- safe |
| `training_days_per_week` | IntegerField, min=2, max=7 | Bounded -- safe |
| `custom_day_config[].day_name` | CharField, max_length=50 | Length-bounded -- safe |
| `custom_day_config[].label` | CharField, max_length=100 | Length-bounded -- safe |
| `custom_day_config[].muscle_groups` | ListField, child=CharField(max=20), min_length=1, max_length=10 | Bounded list with per-item validation against fixed set |

**Cross-field Validation:**
- `custom_day_config` required when `split_type == 'custom'` (line 412).
- `custom_day_config` count must equal `training_days_per_week` (line 417).
- `muscle_groups` validated against a fixed set of 10 valid values (line 373-376).

**Frontend Validation (Web):**
- Duration: `Math.max(1, Math.min(52, Number(e.target.value) || 1))` -- clamped to valid range.
- Training days: `Math.max(2, Math.min(7, Number(e.target.value) || 2))` -- clamped to valid range.
- Custom day label: `maxLength={50}` on input field.
- `canAdvance()` function prevents submission without required fields.

**Frontend Validation (Mobile):**
- Duration: slider `min: 1, max: 52` with `IconButton` bounds checking.
- Training days: slider `min: 2, max: 7` with `IconButton` bounds checking.
- `_canProceed` getter prevents progression without required selections.

**Bounded Loops/Queries:**
- `_prefetch_exercise_pool()`: Executes at most 2 queries (primary + fallback for empty groups). All queries are bounded by the finite set of muscle groups (max 10).
- `generate_program()`: Outer loop is `duration_weeks` (max 52) * 7 days = 364 iterations max. Inner loop is exercises per day (max ~10). Total work is O(52 * 7 * 10) = ~3640 iterations. Well-bounded.
- `_pick_exercises_from_pool()`: The while loop (line 333) is bounded by `count` (max ~5) and terminates when `categories` is empty. Cannot loop infinitely.

## OpenAI API Key Handling

**`classify_exercises.py` lines 112-116:**
```python
api_key = getattr(settings, 'OPENAI_API_KEY', None)
if not api_key:
    raise RuntimeError("OPENAI_API_KEY is not configured in settings.")
client = openai.OpenAI(api_key=api_key)
```
- The API key is sourced from Django settings (`os.getenv('OPENAI_API_KEY', '')` at `settings.py:204`), not hardcoded.
- The key is never logged, returned in responses, or included in error messages.
- The `RuntimeError` message says "not configured" without revealing the actual key value. Safe.

## Fixture File Security

**`kilo_exercises.json` (6391 lines):**
- Contains only exercise data: `name`, `muscle_group`, `category`, `video_url`.
- All `video_url` values are public YouTube links (`https://youtu.be/...`).
- No API keys, secrets, credentials, or internal URLs found (verified via grep).
- No personally identifiable information (PII).

## Test File Security

**`test_program_generator.py` (1595 lines):**
- Test passwords are dummy values (`pass123`, `testpass123`) -- standard practice for Django test fixtures.
- Exercise names like "Secret Trainer Exercise" and "My Secret Move" are descriptive labels, not actual secrets.
- No real API keys, tokens, or credentials in test data.

## CORS/CSRF Analysis

- **CORS**: Handled globally in `settings.py`. In production, `CORS_ALLOW_ALL_ORIGINS = False` with explicit allowlist from `CORS_ALLOWED_ORIGINS` env var. In development, `CORS_ALLOW_ALL_ORIGINS = True` (acceptable for local dev).
- **CSRF**: Not applicable -- API uses JWT Bearer token authentication (not session cookies). DRF's `SessionAuthentication` is not in `DEFAULT_AUTHENTICATION_CLASSES`, so CSRF middleware is not engaged for API requests.
- **The new endpoint** does not introduce any CORS or CSRF changes.

## Rate Limiting Consideration

The `GenerateProgramView` endpoint uses the global DRF throttle of `120/minute` for authenticated users. While program generation is computationally lightweight (no AI/OpenAI calls -- it's pure Python logic selecting exercises from the DB), a sustained burst of 120 requests/minute would execute up to 120 * 2 = 240 DB queries per minute per user. This is acceptable -- not a DoS vector.

The `classify_exercises` management command does call OpenAI, but it's a CLI-only command, not an API endpoint. No rate limiting concern.

## Security Issues Found

| # | Severity | Type | File:Line | Issue | Fix |
|---|----------|------|-----------|-------|-----|
| -- | -- | -- | -- | No Critical or High issues found | -- |

### Medium Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 1 | **Medium** | Information Disclosure | `backend/workouts/views.py:329-357` | The `ProgramViewSet.debug` action exposes user details (email, role, parent_trainer_email) and program data to any authenticated user. While not introduced by this feature, it was noticed during the audit. This debug endpoint should not exist in production. | Remove the `debug` action or restrict it to admin-only with `IsAdmin` permission class. |

### Low Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 2 | **Low** | Predictable randomness | `backend/workouts/services/program_generator.py:337` | `random.choice()` and `random.shuffle()` use Python's default PRNG, which is deterministic if seeded. This is not a security concern because exercise selection randomness is a UX feature, not a security mechanism. The deterministic behavior is actually tested and desired (see `DeterministicOutputTests`). | No action needed. |
| 3 | **Low** | Unbounded AI response parsing | `backend/workouts/management/commands/classify_exercises.py:136` | `json.loads(content)` parses the OpenAI API response without explicit size limits. A maliciously crafted or unexpectedly large response could consume memory. However, this is a CLI management command (not an API endpoint), and OpenAI's `max_tokens=4096` limits the response size. | No action needed -- bounded by `max_tokens`. |

### Info Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 4 | **Info** | Debug logging with f-string | `backend/workouts/views.py:304,320` | Uses `logger.debug(f"...")` and `logger.warning(f"...")` with f-string interpolation. The strings are evaluated even when log level is above DEBUG/WARNING. Prefer `logger.debug("...", user.id)` lazy formatting for minor performance gain. | Minor style issue, no security impact. |
| 5 | **Info** | sessionStorage usage | `web/src/components/programs/program-generator-wizard.tsx:111-114` | Generated program data is stored in `sessionStorage` to pass to the builder page. `sessionStorage` is tab-scoped and cleared on tab close. No XSS vector since the data is JSON-serialized API response data, not raw user input, and React auto-escapes on render. | No action needed. |

## Summary

The Smart Program Generator feature has a **clean security posture**:

1. **No secrets leaked** -- all API keys sourced from environment variables via Django settings. Fixture file contains only public exercise data and YouTube URLs.

2. **Strong auth/authz** -- `[IsAuthenticated, IsTrainer]` on the endpoint, `trainer_id` sourced from `request.user` (not user input), exercise pool properly scoped with IDOR-proof privacy filter, comprehensive test coverage for auth scenarios.

3. **Thorough input validation** -- all inputs validated via DRF `ChoiceField`, `IntegerField(min/max)`, and custom cross-field validation. Custom day config muscle groups validated against a closed set. Frontend enforces matching constraints.

4. **No injection vectors** -- all database access via Django ORM, no raw SQL. No shell commands. No `eval()`. No HTML injection (React/Flutter auto-escaping).

5. **Safe error handling** -- generic 500 message for unexpected errors, `ValueError` messages from our own code, exceptions logged server-side only.

6. **Bounded computation** -- all loops have known upper bounds. Maximum iteration count is ~3640 per request. No unbounded queries or recursive calls.

## Security Score: 9/10

The 1-point deduction is for the pre-existing `ProgramViewSet.debug` endpoint (Medium severity, not introduced by this feature) which exposes user details without admin-only restriction.

## Recommendation: PASS

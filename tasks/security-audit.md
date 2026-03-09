# Security Audit: Video Workout Layout

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs — PASS
- [x] No secrets in git history — PASS
- [x] All user input sanitized — PASS (video_url uses Django URLField; layout_type uses TextChoices enum)
- [x] Authentication checked on all new endpoints — PASS (IsAuthenticated + IsTrainer on TraineeLayoutConfigView)
- [x] Authorization — correct role/permission guards — PASS (get_object checks parent_trainer=trainer)
- [x] No IDOR vulnerabilities — PASS (trainer can only modify their own trainees' layout)
- [x] File uploads validated — PASS (video upload validates content_type and size)
- [ ] Rate limiting on sensitive endpoints — N/A (no sensitive operation)
- [x] Error messages don't leak internals — PASS (Http404 with generic message)
- [x] CORS policy appropriate — N/A

## Vulnerabilities Found

| # | Severity | Type | File:Line | Issue | Fix |
|---|----------|------|-----------|-------|-----|
| 1 | Medium | iframe security | web/src/components/exercises/exercise-video-player.tsx:40-48 | YouTube iframe missing `sandbox` attribute. Without sandboxing, the embedded page can execute scripts, navigate the top window, and access browser APIs. While youtube-nocookie.com is trusted, defense-in-depth requires restricting iframe capabilities. | Add `sandbox="allow-scripts allow-same-origin allow-presentation"` to the iframe element. |
| 2 | Low | Missing referrer policy | web/src/components/exercises/exercise-video-player.tsx:40-48 | YouTube iframe missing `referrerPolicy` attribute. The embedding page URL is sent as a referrer to YouTube by default. | Add `referrerPolicy="no-referrer"` to the iframe element. |

## Detailed Analysis

### 1. XSS via video_url — LOW RISK (mitigated by backend)

The `video_url` field on the Exercise model uses `models.URLField` (line 31 of `backend/workouts/models.py`), which enforces Django's `URLValidator`. This validator only accepts `http://` and `https://` schemes, blocking `javascript:`, `data:text/html`, and other dangerous URI schemes at the database level.

On the web frontend, the `ExerciseVideoPlayer` component (exercise-video-player.tsx):
- For YouTube URLs: extracts the video ID via regex and constructs a hardcoded `https://www.youtube-nocookie.com/embed/{ytId}` URL. This is safe -- attacker-controlled input is sanitized to an 11-character alphanumeric ID.
- For non-YouTube URLs: renders `<video src={videoUrl}>`. HTML `<video>` elements do not execute `javascript:` or `data:` URIs as media sources, so even if a URL somehow bypassed backend validation, the browser would not execute it.

On the mobile frontend (video_workout_layout.dart line 181): `VideoPlayerController.networkUrl(Uri.parse(url))` uses Flutter's video_player which only handles actual video streams, not arbitrary web content.

**Verdict: No XSS vulnerability exists.** Backend validation is the primary control, and frontend rendering provides defense-in-depth.

### 2. IDOR — NOT VULNERABLE

`TraineeLayoutConfigView.get_object()` (backend/trainer/views.py:1466-1488) correctly:
- Casts the authenticated user as the trainer
- Queries `User.objects.get(id=trainee_id, role=TRAINEE, parent_trainer=trainer)`
- Raises Http404 if the trainee doesn't belong to this trainer

A trainer cannot modify another trainer's trainee layout. Verified.

### 3. Input Validation — PROPERLY VALIDATED

`layout_type` field on `WorkoutLayoutConfig` (backend/trainer/models.py:278) uses `choices=LayoutType.choices` with four valid values: classic, card, minimal, video. DRF's `ModelSerializer` automatically validates against these choices on write. Arbitrary strings are rejected with a 400 error.

`config_options` JSONField has explicit size validation (max 2048 chars) in the serializer (backend/trainer/serializers.py:315-323).

### 4. iframe Security — MEDIUM (fixed below)

The YouTube iframe at exercise-video-player.tsx:40-48 is missing the `sandbox` attribute. While `youtube-nocookie.com` is a trusted origin, the `sandbox` attribute provides defense-in-depth by restricting what the embedded content can do (e.g., preventing top-navigation, form submission, popups).

## Security Score: 9/10
## Recommendation: CONDITIONAL PASS

The two iframe hardening issues (sandbox + referrer policy) are Medium/Low severity and have been fixed below. No Critical or High vulnerabilities were found. The backend validation (URLField, TextChoices enum, parent_trainer check) is solid.

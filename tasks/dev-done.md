# Dev Done: Voice Memo Parsing + Video Analysis — v6.5 Step 14

## Files Created

- `backend/workouts/services/voice_memo_service.py` — Upload, Whisper transcription, NLP parsing
- `backend/workouts/services/video_analysis_service.py` — Upload, GPT-4o Vision analysis, confirm with DecisionLog
- `backend/workouts/media_views.py` — 7 API views for voice memos + video analysis
- `backend/workouts/migrations/0032_voice_memo_video_analysis.py` — VoiceMemo + VideoAnalysis models
- `backend/workouts/tests/test_voice_video.py` — 24 tests (mocked AI)

## Files Modified

- `backend/workouts/models.py` — Added VoiceMemo model (status lifecycle, transcript, parsed result) + VideoAnalysis model (exercise detection, rep count, form score, observations)
- `backend/workouts/urls.py` — Added 7 routes for voice/video endpoints
- `backend/workouts/ai_prompts.py` — Added `get_video_analysis_prompt()`

## Endpoints

- POST /api/workouts/voice-memos/ — Upload audio, transcribe, parse (multipart)
- GET /api/workouts/voice-memos/list/ — List recent voice memos
- GET /api/workouts/voice-memos/{id}/ — Get detail
- POST /api/workouts/video-analysis/ — Upload video, analyze (multipart)
- GET /api/workouts/video-analysis/list/ — List recent analyses
- GET /api/workouts/video-analysis/{id}/ — Get detail
- POST /api/workouts/video-analysis/{id}/confirm/ — Confirm findings

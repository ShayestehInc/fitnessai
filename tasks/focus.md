# Focus: Trainer Packet v6.5 — Step 14: Voice Memo Parsing + Video Analysis

## Priority

Critical — Step 14 of the v6.5 build order. Enables trainees to log workouts/nutrition via voice memos and analyze exercise form via video.

## What to Build

### 1. VoiceMemo Model

- Audio file metadata (file URL, duration, format)
- Transcription text and confidence
- Status lifecycle: uploading, transcribing, transcribed, parsed, failed
- FK to trainee, optional link to DailyLog
- Parsed result (JSON from natural language parser)

### 2. VideoAnalysis Model

- Video file metadata (file URL, duration, format, thumbnail)
- AI analysis results: exercise detected, rep count, form score, observations
- Status lifecycle: uploading, analyzing, analyzed, confirmed, failed
- FK to trainee, optional exercise FK
- DecisionLog on confirm

### 3. Transcription Service

- Accept audio upload → validate → call OpenAI Whisper API
- Return transcript + confidence score
- Feed transcript into existing natural language parser
- Support MP3, WAV, M4A, WebM formats

### 4. Video Analysis Service

- Accept video upload → validate → call OpenAI Vision API (GPT-4o)
- Analyze exercise form, count reps, identify exercise
- Return structured analysis with confidence scores

### 5. API Endpoints

- POST /voice-memos/ — Upload audio, transcribe, parse
- GET /voice-memos/{id}/ — Get transcription result
- POST /video-analysis/ — Upload video, analyze
- GET /video-analysis/{id}/ — Get analysis result
- POST /video-analysis/{id}/confirm/ — Confirm and save findings

## What NOT to Build

- Real-time streaming transcription
- Mobile UI (backend only)
- Pose estimation (use GPT-4o vision only)

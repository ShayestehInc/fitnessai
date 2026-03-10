# Focus: Trainer Packet v6.5 — Step 13: Auto-tagging Pipeline

## Priority

Critical — Step 13 of the v6.5 build order. AI-powered exercise tagging with draft/edit/retry/version workflow.

## What to Build

### 1. ExerciseTagDraft Model

- Stores AI-generated tag suggestions before trainer approval
- Status: draft, approved, rejected
- FK to exercise and requesting trainer
- JSONField for drafted tags, confidence scores, AI reasoning
- Retry count tracking

### 2. Auto-tagging Service

- `request_auto_tag()` — Call AI to generate tag suggestions → create draft
- `apply_draft()` — Apply approved tags to exercise, increment version, create DecisionLog + UndoSnapshot
- `reject_draft()` — Reject draft
- `retry_draft()` — Request new AI attempt (increments retry count)
- `get_tag_history()` — Version history for an exercise's tags

### 3. API Endpoints

- POST /exercises/{id}/auto-tag/ — Request AI auto-tagging (creates draft)
- GET /exercises/{id}/auto-tag-draft/ — Get current draft for review
- PATCH /exercises/{id}/auto-tag-draft/ — Edit draft before applying
- POST /exercises/{id}/auto-tag-draft/apply/ — Apply draft tags to exercise
- POST /exercises/{id}/auto-tag-draft/reject/ — Reject draft
- POST /exercises/{id}/auto-tag-draft/retry/ — Request new attempt
- GET /exercises/{id}/tag-history/ — Tag version history

### 4. AI Prompt

- GPT-4o function calling to generate structured tags
- Input: exercise name, description, category, equipment, existing tags
- Output: all v6.5 tag fields + confidence scores + reasoning

## What NOT to Build

- Mobile UI for auto-tagging
- Bulk auto-tagging (one exercise at a time)
- Auto-tagging on exercise creation (manual trigger only)

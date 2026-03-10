# Focus: Trainer Packet v6.5 — Step 12: Import Pipeline (Draft/Confirm)

## Priority

Critical — Step 12 of the v6.5 build order. Enables trainers to bulk import training programs from CSV/JSON with a two-phase draft→confirm workflow.

## What to Build

### 1. ProgramImportDraft Model

- Stores uploaded file content, parsed preview, validation errors
- Status: pending_review, confirmed, rejected, expired
- FK to trainer, optional trainee
- JSONField for parsed data and errors

### 2. Import Service

- `parse_csv_to_draft()` — Parse CSV into structured plan preview
- `validate_draft()` — Validate exercises exist, rep ranges valid, etc.
- `confirm_import()` — Atomic creation of TrainingPlan/PlanWeek/PlanSession/PlanSlot + DecisionLog

### 3. API Endpoints

- POST /program-imports/upload/ — Accept CSV, create draft
- GET /program-imports/{draft_id}/ — Get draft for review
- POST /program-imports/{draft_id}/confirm/ — Execute import
- DELETE /program-imports/{draft_id}/ — Reject/discard draft

## What NOT to Build

- Mobile UI for import
- JSON file import (CSV only for now)
- Exercise auto-creation (exercises must pre-exist)

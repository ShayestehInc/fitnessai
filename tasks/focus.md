# Pipeline 12 Focus: Web Dashboard Phase 4 — Trainer Program Builder

## Priority
The next Phase 4 item is the **Trainer Program Builder** for the web dashboard. This allows trainers to create, edit, and manage workout programs directly from the web interface — a critical workflow that currently only exists in mobile.

## Context
- Web dashboard foundation, trainee management, notifications, invitations, settings, progress charts, and analytics are all shipped
- Backend program APIs already exist (`/api/workouts/programs/`, `/api/workouts/exercises/`)
- Mobile program builder already exists as reference implementation
- Key models: Program (with schedule JSONField), ProgramTemplate, ProgramWeek, Exercise

## Scope
- Program list page with create/edit/delete
- Program builder: week editor, day editor, exercise selection
- Exercise bank browsing (system + trainer-custom)
- Program template support (save as template, create from template)
- Program assignment to trainees
- All CRUD operations with proper loading/error/empty states

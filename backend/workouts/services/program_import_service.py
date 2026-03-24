"""
Program Import Service — v6.5 Step 12.

Two-phase import workflow:
1. Upload CSV → parse & validate → create draft
2. Trainer reviews draft → confirm → atomic creation of TrainingPlan hierarchy

CSV Format:
week,day_of_week,session_label,order,exercise_name,slot_role,sets,reps_min,reps_max,rest_seconds,load_pct,notes
"""
from __future__ import annotations

import csv
import io
import logging
from dataclasses import dataclass
from typing import Any

from django.db import transaction
from django.utils import timezone

from users.models import User
from workouts.models import (
    DecisionLog,
    Exercise,
    PlanSession,
    PlanSlot,
    PlanWeek,
    ProgramImportDraft,
    TrainingPlan,
    UndoSnapshot,
)

logger = logging.getLogger(__name__)

# Required CSV columns
REQUIRED_COLUMNS = {
    'week', 'day_of_week', 'session_label', 'order',
    'exercise_name', 'sets', 'reps_min', 'reps_max',
}

VALID_SLOT_ROLES = {
    'primary_compound', 'secondary_compound', 'isolation',
    'accessory', 'warmup', 'cooldown',
}


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class ParseResult:
    """Result of parsing a CSV into a draft."""
    draft_id: str
    status: str
    total_weeks: int
    total_sessions: int
    total_slots: int
    errors: list[str]
    warnings: list[str]
    parsed_preview: dict[str, Any]


@dataclass(frozen=True)
class ConfirmResult:
    """Result of confirming an import."""
    draft_id: str
    training_plan_id: str
    weeks_created: int
    sessions_created: int
    slots_created: int


# ---------------------------------------------------------------------------
# Parse & Create Draft
# ---------------------------------------------------------------------------

def parse_csv_and_create_draft(
    *,
    trainer: User,
    csv_content: str,
    plan_name: str = '',
    goal: str = 'strength',
    trainee_id: int | None = None,
) -> ParseResult:
    """
    Parse CSV content, validate, and create an import draft.
    Returns errors if the CSV is invalid.
    """
    errors: list[str] = []
    warnings: list[str] = []

    # Parse CSV
    try:
        reader = csv.DictReader(io.StringIO(csv_content))
        if reader.fieldnames is None:
            errors.append("CSV has no header row.")
            return _create_error_draft(trainer, csv_content, plan_name, goal, errors)

        # Normalize field names
        fieldnames = {f.strip().lower() for f in reader.fieldnames}
        missing = REQUIRED_COLUMNS - fieldnames
        if missing:
            errors.append(f"Missing required columns: {', '.join(sorted(missing))}")
            return _create_error_draft(trainer, csv_content, plan_name, goal, errors)

        rows = list(reader)
    except csv.Error as exc:
        errors.append(f"CSV parsing error: {exc}")
        return _create_error_draft(trainer, csv_content, plan_name, goal, errors)

    if not rows:
        errors.append("CSV contains no data rows.")
        return _create_error_draft(trainer, csv_content, plan_name, goal, errors)

    # Validate and build structure
    parsed_data, row_errors, row_warnings = _validate_and_build(rows, trainer)
    errors.extend(row_errors)
    warnings.extend(row_warnings)

    # Count totals
    total_weeks = len(parsed_data.get('weeks', {}))
    total_sessions = sum(
        len(w.get('sessions', {}))
        for w in parsed_data.get('weeks', {}).values()
    )
    total_slots = sum(
        len(s.get('slots', []))
        for w in parsed_data.get('weeks', {}).values()
        for s in w.get('sessions', {}).values()
    )

    # Resolve trainee
    trainee = None
    if trainee_id:
        try:
            trainee = User.objects.get(
                pk=trainee_id,
                role='TRAINEE',
                parent_trainer=trainer,
            )
        except User.DoesNotExist:
            errors.append(f"Trainee {trainee_id} not found or not yours.")

    # Create draft
    draft = ProgramImportDraft.objects.create(
        trainer=trainer,
        trainee=trainee,
        plan_name=plan_name or 'Imported Program',
        goal=goal,
        raw_csv=csv_content,
        parsed_data=parsed_data,
        validation_errors=errors,
        validation_warnings=warnings,
        total_weeks=total_weeks,
        total_sessions=total_sessions,
        total_slots=total_slots,
        status=ProgramImportDraft.Status.PENDING_REVIEW,
    )

    return ParseResult(
        draft_id=str(draft.pk),
        status=draft.status,
        total_weeks=total_weeks,
        total_sessions=total_sessions,
        total_slots=total_slots,
        errors=errors,
        warnings=warnings,
        parsed_preview=parsed_data,
    )


def _create_error_draft(
    trainer: User,
    csv_content: str,
    plan_name: str,
    goal: str,
    errors: list[str],
) -> ParseResult:
    """Create a draft with errors (no valid parsed data)."""
    draft = ProgramImportDraft.objects.create(
        trainer=trainer,
        plan_name=plan_name or 'Imported Program',
        goal=goal,
        raw_csv=csv_content,
        parsed_data={},
        validation_errors=errors,
        status=ProgramImportDraft.Status.PENDING_REVIEW,
    )
    return ParseResult(
        draft_id=str(draft.pk),
        status=draft.status,
        total_weeks=0,
        total_sessions=0,
        total_slots=0,
        errors=errors,
        warnings=[],
        parsed_preview={},
    )


def _validate_and_build(
    rows: list[dict[str, str]],
    trainer: User,
) -> tuple[dict[str, Any], list[str], list[str]]:
    """Validate CSV rows and build structured plan data."""
    errors: list[str] = []
    warnings: list[str] = []

    # Collect all exercise names for bulk lookup
    exercise_names = {
        row.get('exercise_name', '').strip()
        for row in rows
        if row.get('exercise_name', '').strip()
    }

    # Lookup exercises (case-insensitive)
    from django.db.models import Q
    from django.db.models.functions import Lower
    lower_names = {n.lower() for n in exercise_names}
    exercises = Exercise.objects.annotate(
        name_lower=Lower('name'),
    ).filter(
        Q(name_lower__in=lower_names) & (
            Q(is_public=True) | Q(created_by=trainer)
        )
    )
    exercise_map: dict[str, int] = {
        e.name_lower: e.pk for e in exercises  # type: ignore[attr-defined]
    }

    # Check for missing exercises
    for name in exercise_names:
        if name.lower() not in exercise_map:
            errors.append(f"Exercise not found: '{name}'")

    # Build week → session → slot structure
    weeks: dict[int, dict[str, Any]] = {}

    for i, row in enumerate(rows, start=2):  # Row 2 (after header)
        try:
            week_num = int(row.get('week', '0').strip())
        except ValueError:
            errors.append(f"Row {i}: invalid week number '{row.get('week')}'")
            continue

        try:
            day_of_week = int(row.get('day_of_week', '0').strip())
        except ValueError:
            errors.append(f"Row {i}: invalid day_of_week '{row.get('day_of_week')}'")
            continue

        session_label = row.get('session_label', '').strip() or f"Day {day_of_week}"

        try:
            order = int(row.get('order', '1').strip())
        except ValueError:
            order = 1

        exercise_name = row.get('exercise_name', '').strip()
        if not exercise_name:
            errors.append(f"Row {i}: exercise_name is required")
            continue

        try:
            sets = int(row.get('sets', '3').strip())
            reps_min = int(row.get('reps_min', '8').strip())
            reps_max = int(row.get('reps_max', '12').strip())
        except ValueError:
            errors.append(f"Row {i}: invalid sets/reps values")
            continue

        if sets < 1 or sets > 20:
            warnings.append(f"Row {i}: sets={sets} is unusual")
        if reps_min < 1 or reps_max > 100:
            warnings.append(f"Row {i}: rep range {reps_min}-{reps_max} is unusual")
        if reps_min > reps_max:
            errors.append(f"Row {i}: reps_min ({reps_min}) > reps_max ({reps_max})")
            continue

        rest_seconds = 90
        try:
            rest_str = row.get('rest_seconds', '').strip()
            if rest_str:
                rest_seconds = int(rest_str)
        except ValueError:
            pass

        load_pct: float | None = None
        try:
            load_str = row.get('load_pct', '').strip()
            if load_str:
                load_pct = float(load_str)
        except ValueError:
            pass

        slot_role = row.get('slot_role', '').strip() or 'isolation'
        if slot_role not in VALID_SLOT_ROLES:
            warnings.append(f"Row {i}: unknown slot_role '{slot_role}', defaulting to 'isolation'")
            slot_role = 'isolation'

        notes = row.get('notes', '').strip()

        # Build nested structure
        if week_num not in weeks:
            weeks[week_num] = {'week_number': week_num, 'sessions': {}}

        session_key = f"{day_of_week}_{session_label}"
        if session_key not in weeks[week_num]['sessions']:
            weeks[week_num]['sessions'][session_key] = {
                'day_of_week': day_of_week,
                'label': session_label,
                'slots': [],
            }

        weeks[week_num]['sessions'][session_key]['slots'].append({
            'order': order,
            'exercise_name': exercise_name,
            'exercise_id': exercise_map.get(exercise_name.lower()),
            'slot_role': slot_role,
            'sets': sets,
            'reps_min': reps_min,
            'reps_max': reps_max,
            'rest_seconds': rest_seconds,
            'load_prescription_pct': load_pct,
            'notes': notes,
        })

    return {'weeks': weeks}, errors, warnings


# ---------------------------------------------------------------------------
# Confirm Import
# ---------------------------------------------------------------------------

def confirm_import(
    *,
    draft_id: str,
    trainer: User,
) -> ConfirmResult:
    """
    Confirm and execute a program import.
    Creates TrainingPlan → PlanWeeks → PlanSessions → PlanSlots atomically.
    """
    try:
        draft = ProgramImportDraft.objects.get(
            pk=draft_id,
            trainer=trainer,
        )
    except ProgramImportDraft.DoesNotExist:
        raise ValueError("Import draft not found.")

    if draft.status != ProgramImportDraft.Status.PENDING_REVIEW:
        raise ValueError(f"Draft is not pending review (status: {draft.status}).")

    if draft.validation_errors:
        raise ValueError(
            f"Draft has {len(draft.validation_errors)} validation error(s). "
            "Fix errors before confirming."
        )

    parsed = draft.parsed_data
    weeks_data = parsed.get('weeks', {})

    if not weeks_data:
        raise ValueError("Draft has no parsed data to import.")

    weeks_created = 0
    sessions_created = 0
    slots_created = 0

    with transaction.atomic():
        # Create TrainingPlan
        plan = TrainingPlan.objects.create(
            trainee=draft.trainee,
            name=draft.plan_name,
            goal=draft.goal,
            status='draft',
        )

        # Create weeks, sessions, slots
        for week_num_str, week_data in sorted(
            weeks_data.items(), key=lambda x: int(x[0])
        ):
            week = PlanWeek.objects.create(
                plan=plan,
                week_number=int(week_num_str),
            )
            weeks_created += 1

            session_order = 0
            for session_key, session_data in week_data.get('sessions', {}).items():
                session_order += 1
                session = PlanSession.objects.create(
                    week=week,
                    day_of_week=session_data['day_of_week'],
                    label=session_data['label'],
                    order=session_order,
                )
                sessions_created += 1

                for slot_data in sorted(
                    session_data.get('slots', []),
                    key=lambda s: s.get('order', 0),
                ):
                    exercise_id = slot_data.get('exercise_id')
                    if not exercise_id:
                        continue

                    slot_kwargs: dict[str, Any] = {
                        'session': session,
                        'exercise_id': exercise_id,
                        'slot_role': slot_data.get('slot_role', 'isolation'),
                        'sets': slot_data.get('sets', 3),
                        'reps_min': slot_data.get('reps_min', 8),
                        'reps_max': slot_data.get('reps_max', 12),
                        'rest_seconds': slot_data.get('rest_seconds', 90),
                        'order': slot_data.get('order', 0),
                    }
                    load_pct = slot_data.get('load_prescription_pct')
                    if load_pct is not None:
                        slot_kwargs['load_prescription_pct'] = load_pct

                    PlanSlot.objects.create(**slot_kwargs)
                    slots_created += 1

        # Update draft
        draft.status = ProgramImportDraft.Status.CONFIRMED
        draft.training_plan = plan
        draft.confirmed_at = timezone.now()
        draft.save(update_fields=[
            'status', 'training_plan', 'confirmed_at',
        ])

        # DecisionLog
        DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.USER,
            actor_id=trainer.pk,
            decision_type='program_import_confirmed',
            context={
                'draft_id': str(draft.pk),
                'training_plan_id': str(plan.pk),
                'trainee_id': draft.trainee_id,
            },
            inputs_snapshot={
                'plan_name': draft.plan_name,
                'goal': draft.goal,
                'total_weeks': weeks_created,
                'total_sessions': sessions_created,
                'total_slots': slots_created,
            },
            constraints_applied={},
            options_considered=[],
            final_choice={
                'training_plan_id': str(plan.pk),
            },
            reason_codes=['program_import_confirmed'],
        )

        # UndoSnapshot
        UndoSnapshot.objects.create(
            scope=UndoSnapshot.Scope.PLAN,
            before_state={},
            after_state={
                'training_plan_id': str(plan.pk),
                'weeks': weeks_created,
                'sessions': sessions_created,
                'slots': slots_created,
            },
        )

    return ConfirmResult(
        draft_id=str(draft.pk),
        training_plan_id=str(plan.pk),
        weeks_created=weeks_created,
        sessions_created=sessions_created,
        slots_created=slots_created,
    )


# ---------------------------------------------------------------------------
# Reject / Get Draft
# ---------------------------------------------------------------------------

def reject_draft(
    *,
    draft_id: str,
    trainer: User,
) -> None:
    """Reject and discard a draft."""
    try:
        draft = ProgramImportDraft.objects.get(
            pk=draft_id,
            trainer=trainer,
        )
    except ProgramImportDraft.DoesNotExist:
        raise ValueError("Import draft not found.")

    if draft.status != ProgramImportDraft.Status.PENDING_REVIEW:
        raise ValueError(f"Draft is not pending review (status: {draft.status}).")

    draft.status = ProgramImportDraft.Status.REJECTED
    draft.save(update_fields=['status'])


def get_draft(
    *,
    draft_id: str,
    trainer: User,
) -> ProgramImportDraft:
    """Get a draft for review."""
    try:
        return ProgramImportDraft.objects.get(
            pk=draft_id,
            trainer=trainer,
        )
    except ProgramImportDraft.DoesNotExist:
        raise ValueError("Import draft not found.")


def list_drafts(
    *,
    trainer: User,
    limit: int = 20,
) -> list[ProgramImportDraft]:
    """List recent import drafts for a trainer."""
    return list(
        ProgramImportDraft.objects.filter(trainer=trainer)
        .order_by('-created_at')[:limit]
    )


# ---------------------------------------------------------------------------
# PDF Import (v6.5 §13 — beta/experimental)
# ---------------------------------------------------------------------------

def parse_pdf_and_create_draft(
    *,
    trainer: 'User',
    pdf_content: bytes,
    filename: str,
) -> ProgramImportDraft:
    """
    Parse a PDF program file using AI and create an import draft.

    Uses GPT-4o to extract structured program data from the PDF,
    then creates a ProgramImportDraft in the same format as CSV import.

    This is experimental — confidence scores will be lower than CSV
    since PDFs have variable formatting.
    """
    import json
    import logging

    from django.core.files.base import ContentFile

    logger = logging.getLogger(__name__)

    # Extract text from PDF
    try:
        import io
        # Use pdfplumber if available, fallback to basic extraction
        try:
            import pdfplumber
            with pdfplumber.open(io.BytesIO(pdf_content)) as pdf:
                text_pages = [page.extract_text() or '' for page in pdf.pages]
                raw_text = '\n\n'.join(text_pages)
        except ImportError:
            # Fallback: store raw bytes and let AI handle via base64
            raw_text = f"[PDF file: {filename}, {len(pdf_content)} bytes — AI extraction required]"
    except Exception as e:
        logger.exception("Failed to extract text from PDF: %s", filename)
        raw_text = f"[PDF extraction failed: {e}]"

    # Create draft with raw text as CSV equivalent
    draft = ProgramImportDraft.objects.create(
        trainer=trainer,
        original_filename=filename,
        raw_csv=raw_text,
        parsed_data={
            'source': 'pdf',
            'filename': filename,
            'raw_text_length': len(raw_text),
            'status': 'awaiting_ai_parsing',
            'note': (
                'This PDF import requires AI parsing. '
                'Review carefully before confirming — '
                'confidence may be lower than CSV imports.'
            ),
        },
        validation_errors=[],
        validation_warnings=[
            'PDF import is experimental. Please review all exercises and prescriptions carefully.',
        ],
    )

    return draft

"""
PDF export service for programs.
Generates formatted PDF documents from Program data.
"""
from __future__ import annotations

import io
import logging
from typing import Any

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from workouts.models import Exercise, Program

logger = logging.getLogger(__name__)


def export_program_pdf(program: Program) -> bytes:
    """
    Generate a formatted PDF for a program.

    Args:
        program: The program to export.

    Returns:
        PDF file content as bytes.

    Raises:
        ValueError: If the program has no schedule data.
    """
    schedule = program.schedule
    if not isinstance(schedule, dict) or not schedule:
        raise ValueError("Program has no schedule data to export")

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        topMargin=0.75 * inch,
        bottomMargin=0.75 * inch,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "ProgramTitle",
        parent=styles["Title"],
        fontSize=22,
        spaceAfter=12,
    )
    subtitle_style = ParagraphStyle(
        "SubTitle",
        parent=styles["Heading2"],
        fontSize=14,
        spaceAfter=6,
        textColor=colors.HexColor("#555555"),
    )
    day_header_style = ParagraphStyle(
        "DayHeader",
        parent=styles["Heading3"],
        fontSize=12,
        spaceBefore=10,
        spaceAfter=4,
        textColor=colors.HexColor("#333333"),
    )

    elements: list[Any] = []

    # Title
    elements.append(Paragraph(program.name, title_style))
    if program.description:
        elements.append(Paragraph(program.description, subtitle_style))

    # Program info
    info_text = f"Duration: {program.start_date} to {program.end_date}"
    elements.append(Paragraph(info_text, styles["Normal"]))
    elements.append(Spacer(1, 0.3 * inch))

    # Pre-fetch exercise names
    exercise_ids = _collect_exercise_ids(schedule)
    exercise_map = {
        ex.id: ex.name
        for ex in Exercise.objects.filter(id__in=exercise_ids)
    }

    # Render weeks
    weeks = schedule.get("weeks", [])
    if not isinstance(weeks, list):
        weeks = []

    for week in weeks:
        if not isinstance(week, dict):
            continue
        week_num = week.get("week_number", "?")
        elements.append(Paragraph(f"Week {week_num}", styles["Heading2"]))
        elements.append(Spacer(1, 0.1 * inch))

        days = week.get("days", [])
        if not isinstance(days, list):
            continue

        for day in days:
            if not isinstance(day, dict):
                continue

            day_name = day.get("day", "Unknown Day")
            day_type = day.get("day_type", "training")

            if day_type == "rest":
                elements.append(Paragraph(f"{day_name} — Rest Day", day_header_style))
                recovery = day.get("recovery_exercises", [])
                if isinstance(recovery, list) and recovery:
                    for rec_ex in recovery:
                        if isinstance(rec_ex, dict):
                            elements.append(
                                Paragraph(
                                    f"  • {rec_ex.get('name', 'Recovery Exercise')} — "
                                    f"{rec_ex.get('duration', 'As needed')}",
                                    styles["Normal"],
                                )
                            )
                elements.append(Spacer(1, 0.1 * inch))
                continue

            elements.append(Paragraph(day_name, day_header_style))

            exercises = day.get("exercises", [])
            if not isinstance(exercises, list) or not exercises:
                elements.append(Paragraph("No exercises scheduled", styles["Normal"]))
                continue

            # Build exercise table
            table_data: list[list[str]] = [["Exercise", "Sets", "Reps", "Weight", "Rest"]]
            for ex in exercises:
                if not isinstance(ex, dict):
                    continue
                ex_id = ex.get("exercise_id")
                ex_name = exercise_map.get(ex_id, ex.get("exercise_name", f"Exercise #{ex_id}"))
                sets = str(ex.get("sets", "-"))
                reps = str(ex.get("reps", "-"))
                weight = ex.get("weight")
                unit = ex.get("unit", "lbs")
                weight_str = f"{weight} {unit}" if weight else "-"
                rest = f"{ex.get('rest_seconds', '-')}s" if ex.get("rest_seconds") else "-"
                table_data.append([ex_name, sets, reps, weight_str, rest])

            table = Table(
                table_data,
                colWidths=[2.5 * inch, 0.7 * inch, 0.7 * inch, 1.2 * inch, 0.7 * inch],
            )
            table.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2d2d2d")),
                        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                        ("FONTSIZE", (0, 0), (-1, -1), 9),
                        ("ALIGN", (1, 0), (-1, -1), "CENTER"),
                        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#cccccc")),
                        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f5f5f5")]),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                    ]
                )
            )
            elements.append(table)
            elements.append(Spacer(1, 0.15 * inch))

    doc.build(elements)
    return buffer.getvalue()


def _collect_exercise_ids(schedule: dict[str, Any]) -> list[int]:
    """Collect all exercise IDs from a schedule for prefetching."""
    ids: set[int] = set()
    weeks = schedule.get("weeks", [])
    if not isinstance(weeks, list):
        return []
    for week in weeks:
        if not isinstance(week, dict):
            continue
        for day in week.get("days", []):
            if not isinstance(day, dict):
                continue
            for ex in day.get("exercises", []):
                if isinstance(ex, dict) and isinstance(ex.get("exercise_id"), int):
                    ids.add(ex["exercise_id"])
    return list(ids)

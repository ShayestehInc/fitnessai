"""
Program Generator Tool - Create workout program drafts for trainer approval.
"""
from __future__ import annotations

import json
from collections.abc import Callable, Coroutine
from typing import Any, cast

from mcp.server import Server
from mcp.types import Tool, TextContent

from api_client import DjangoAPIClient


def register_program_tools(server: Server, api_client: DjangoAPIClient) -> None:
    """Register program generation tools with the MCP server."""

    async def list_tools_impl() -> list[Tool]:
        """List available program tools."""
        return [
            Tool(
                name="generate_program_draft",
                description="""Generate a workout program draft for a trainee.

This creates a DRAFT program that the trainer must review and approve before assigning.
The draft includes a weekly schedule with exercises, sets, reps, and rest periods.

Parameters:
- trainee_id: The ID of the trainee
- program_name: Name for the program
- duration_weeks: How many weeks (1-16)
- goal: BUILD_MUSCLE, FAT_LOSS, STRENGTH, ENDURANCE, RECOMP, or GENERAL_FITNESS
- days_per_week: Training days per week (2-6)
- focus_areas: Optional list of muscle groups to emphasize
- notes: Optional special instructions or considerations
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "program_name": {
                            "type": "string",
                            "description": "Name for the program",
                        },
                        "duration_weeks": {
                            "type": "integer",
                            "minimum": 1,
                            "maximum": 16,
                            "description": "Program duration in weeks",
                        },
                        "goal": {
                            "type": "string",
                            "enum": ["BUILD_MUSCLE", "FAT_LOSS", "STRENGTH", "ENDURANCE", "RECOMP", "GENERAL_FITNESS"],
                            "description": "Primary training goal",
                        },
                        "days_per_week": {
                            "type": "integer",
                            "minimum": 2,
                            "maximum": 6,
                            "description": "Number of training days per week",
                        },
                        "focus_areas": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Muscle groups to emphasize (optional)",
                        },
                        "notes": {
                            "type": "string",
                            "description": "Special instructions or considerations (optional)",
                        },
                    },
                    "required": ["trainee_id", "program_name", "duration_weeks", "goal", "days_per_week"],
                },
            ),
            Tool(
                name="suggest_program_modifications",
                description="""Suggest modifications to an existing program.

Analyzes the trainee's progress and current program, then suggests adjustments.
Returns suggestions that the trainer must review and approve.

Parameters:
- trainee_id: The ID of the trainee
- modification_type: PROGRESSIVE_OVERLOAD, DELOAD, VOLUME_ADJUSTMENT, or EXERCISE_SWAP
- reason: Why this modification is being suggested
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "modification_type": {
                            "type": "string",
                            "enum": ["PROGRESSIVE_OVERLOAD", "DELOAD", "VOLUME_ADJUSTMENT", "EXERCISE_SWAP"],
                            "description": "Type of modification to suggest",
                        },
                        "reason": {
                            "type": "string",
                            "description": "Reason for the modification",
                        },
                    },
                    "required": ["trainee_id", "modification_type"],
                },
            ),
        ]

    list_tools = cast(
        Callable[[], Coroutine[Any, Any, list[Tool]]],
        server.list_tools()(list_tools_impl),
    )

    async def call_tool_impl(name: str, arguments: dict[str, Any]) -> list[TextContent]:
        """Handle tool calls for program generation."""
        if name == "generate_program_draft":
            result = await generate_program_draft(api_client, arguments)
        elif name == "suggest_program_modifications":
            result = await suggest_program_modifications(api_client, arguments)
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]

    call_tool = cast(
        Callable[[str, dict[str, Any]], Coroutine[Any, Any, list[TextContent]]],
        server.call_tool()(call_tool_impl),
    )


async def generate_program_draft(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Generate a workout program draft based on trainee data and goals."""
    trainee_id = args["trainee_id"]
    program_name = args["program_name"]
    duration_weeks = args["duration_weeks"]
    goal = args["goal"]
    days_per_week = args["days_per_week"]
    focus_areas = args.get("focus_areas", [])
    notes = args.get("notes", "")

    # Get trainee profile for context
    try:
        trainee = await api_client.get_trainee(trainee_id)
        profile = trainee.get("profile", {})
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    # Get available exercises
    try:
        exercises = await api_client.get_exercises()
    except Exception as e:
        return {"error": f"Failed to fetch exercises: {e}", "status": "failed"}

    # Group exercises by muscle group
    exercises_by_group: dict[str, list[dict[str, Any]]] = {}
    for ex in exercises:
        group = ex.get("muscle_group", "OTHER")
        if group not in exercises_by_group:
            exercises_by_group[group] = []
        exercises_by_group[group].append(ex)

    # Generate program structure based on goal and days per week
    program_structure = _generate_program_structure(
        goal=goal,
        days_per_week=days_per_week,
        duration_weeks=duration_weeks,
        focus_areas=focus_areas,
        exercises_by_group=exercises_by_group,
        trainee_profile=profile,
    )

    return {
        "status": "draft_created",
        "message": "Program draft created. Please review and approve before assigning to trainee.",
        "requires_approval": True,
        "draft": {
            "trainee_id": trainee_id,
            "trainee_name": trainee.get("display_name", trainee.get("email")),
            "program_name": program_name,
            "duration_weeks": duration_weeks,
            "goal": goal,
            "days_per_week": days_per_week,
            "focus_areas": focus_areas,
            "notes": notes,
            "schedule": program_structure,
        },
        "trainee_context": {
            "current_goal": profile.get("goal"),
            "activity_level": profile.get("activity_level"),
            "age": profile.get("age"),
        },
    }


def _generate_program_structure(
    goal: str,
    days_per_week: int,
    duration_weeks: int,
    focus_areas: list[str],
    exercises_by_group: dict[str, list[dict[str, Any]]],
    trainee_profile: dict[str, Any],
) -> dict[str, Any]:
    """Generate a program structure based on parameters."""
    # Define workout splits based on days per week
    splits = {
        2: ["FULL_BODY", "FULL_BODY"],
        3: ["PUSH", "PULL", "LEGS"],
        4: ["UPPER", "LOWER", "UPPER", "LOWER"],
        5: ["PUSH", "PULL", "LEGS", "UPPER", "LOWER"],
        6: ["PUSH", "PULL", "LEGS", "PUSH", "PULL", "LEGS"],
    }

    # Map split types to muscle groups
    split_to_muscles = {
        "FULL_BODY": ["CHEST", "BACK", "SHOULDERS", "ARMS", "LEGS", "CORE"],
        "PUSH": ["CHEST", "SHOULDERS", "ARMS"],  # Triceps
        "PULL": ["BACK", "ARMS"],  # Biceps
        "LEGS": ["LEGS", "GLUTES", "CORE"],
        "UPPER": ["CHEST", "BACK", "SHOULDERS", "ARMS"],
        "LOWER": ["LEGS", "GLUTES", "CORE"],
    }

    # Get rep ranges based on goal
    rep_ranges = {
        "BUILD_MUSCLE": {"reps": "8-12", "sets": 4, "rest": 90},
        "FAT_LOSS": {"reps": "12-15", "sets": 3, "rest": 60},
        "STRENGTH": {"reps": "3-6", "sets": 5, "rest": 180},
        "ENDURANCE": {"reps": "15-20", "sets": 3, "rest": 45},
        "RECOMP": {"reps": "8-12", "sets": 4, "rest": 75},
        "GENERAL_FITNESS": {"reps": "10-12", "sets": 3, "rest": 60},
    }

    goal_params = rep_ranges.get(goal, rep_ranges["GENERAL_FITNESS"])
    workout_split = splits.get(days_per_week, splits[3])
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    weeks = []
    for week_num in range(1, duration_weeks + 1):
        days = []
        workout_day_idx = 0

        for day_idx, day_name in enumerate(day_names):
            if workout_day_idx < days_per_week:
                split_type = workout_split[workout_day_idx]
                muscle_groups = split_to_muscles.get(split_type, ["FULL_BODY"])

                # Prioritize focus areas
                if focus_areas:
                    muscle_groups = [m for m in focus_areas if m in muscle_groups] + \
                                    [m for m in muscle_groups if m not in focus_areas]

                exercises_for_day = []
                for muscle in muscle_groups[:4]:  # Limit to 4 muscle groups per day
                    available = exercises_by_group.get(muscle, [])
                    if available:
                        # Pick 1-2 exercises per muscle group
                        for ex in available[:2]:
                            exercises_for_day.append({
                                "exercise_id": ex.get("id"),
                                "exercise_name": ex.get("name"),
                                "sets": goal_params["sets"],
                                "reps": goal_params["reps"],
                                "rest_seconds": goal_params["rest"],
                                "notes": "",
                            })

                days.append({
                    "day": day_name,
                    "workout_type": split_type,
                    "exercises": exercises_for_day[:8],  # Max 8 exercises per day
                })
                workout_day_idx += 1
            else:
                days.append({
                    "day": day_name,
                    "workout_type": "REST",
                    "exercises": [],
                })

        weeks.append({
            "week_number": week_num,
            "is_deload": week_num % 4 == 0,  # Every 4th week is deload
            "intensity_modifier": 0.7 if week_num % 4 == 0 else 1.0,
            "days": days,
        })

    return {"weeks": weeks}


async def suggest_program_modifications(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Suggest modifications to an existing program."""
    trainee_id = args["trainee_id"]
    modification_type = args["modification_type"]
    reason = args.get("reason", "")

    # Get current program
    try:
        program = await api_client.get_trainee_active_program(trainee_id)
        if not program:
            return {
                "status": "no_program",
                "message": "Trainee has no active program to modify",
            }
    except Exception as e:
        return {"error": f"Failed to fetch program: {e}", "status": "failed"}

    # Get recent logs to analyze progress
    try:
        logs = await api_client.get_trainee_daily_logs(trainee_id, limit=14)
    except Exception:
        logs = []

    # Generate suggestions based on modification type
    suggestions = _generate_modification_suggestions(
        modification_type=modification_type,
        program=program,
        recent_logs=logs,
        reason=reason,
    )

    return {
        "status": "suggestions_created",
        "message": "Modification suggestions created. Please review and apply if appropriate.",
        "requires_approval": True,
        "trainee_id": trainee_id,
        "current_program": {
            "id": program.get("id"),
            "name": program.get("name"),
        },
        "modification_type": modification_type,
        "reason": reason,
        "suggestions": suggestions,
    }


def _generate_modification_suggestions(
    modification_type: str,
    program: dict[str, Any],
    recent_logs: list[dict[str, Any]],
    reason: str,
) -> list[dict[str, Any]]:
    """Generate specific modification suggestions."""
    suggestions: list[dict[str, Any]] = []

    if modification_type == "PROGRESSIVE_OVERLOAD":
        suggestions.append({
            "type": "increase_weight",
            "description": "Increase weight by 5-10% for compound movements",
            "affected_exercises": ["Bench Press", "Squat", "Deadlift", "Overhead Press"],
            "rationale": "Progressive overload is key for continued strength and muscle gains",
        })
        suggestions.append({
            "type": "increase_volume",
            "description": "Add 1 set to each exercise",
            "rationale": "Increased volume can drive further adaptation",
        })

    elif modification_type == "DELOAD":
        suggestions.append({
            "type": "reduce_intensity",
            "description": "Reduce weight by 40-50% for all exercises",
            "rationale": "Allow for recovery and prevent overtraining",
        })
        suggestions.append({
            "type": "reduce_volume",
            "description": "Reduce sets by 50%",
            "rationale": "Lower volume during deload week",
        })

    elif modification_type == "VOLUME_ADJUSTMENT":
        suggestions.append({
            "type": "adjust_sets",
            "description": "Modify set count based on recovery capacity",
            "options": [
                {"action": "increase", "amount": "+1 set per exercise"},
                {"action": "decrease", "amount": "-1 set per exercise"},
            ],
        })

    elif modification_type == "EXERCISE_SWAP":
        suggestions.append({
            "type": "swap_exercise",
            "description": "Replace exercises that may be causing issues or staleness",
            "considerations": [
                "Maintain similar movement pattern",
                "Consider equipment availability",
                "Account for any injuries or limitations",
            ],
        })

    return suggestions

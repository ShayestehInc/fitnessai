"""
Message Drafter Tool - Draft messages for trainers to send to trainees.
"""
import json
from typing import Any
from mcp.server import Server
from mcp.types import Tool, TextContent
from api_client import DjangoAPIClient


def register_message_tools(server: Server, api_client: DjangoAPIClient):
    """Register message drafting tools with the MCP server."""

    @server.list_tools()
    async def list_message_tools() -> list[Tool]:
        """List available message tools."""
        return [
            Tool(
                name="draft_checkin_message",
                description="""Draft a check-in message for a trainee based on their recent activity.

Analyzes the trainee's recent logs, compliance, and progress to draft
an appropriate check-in message. The trainer should review and personalize
before sending.

Parameters:
- trainee_id: The ID of the trainee
- message_tone: ENCOURAGING, NEUTRAL, or MOTIVATIONAL
- focus_area: NUTRITION, WORKOUTS, PROGRESS, or GENERAL
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "message_tone": {
                            "type": "string",
                            "enum": ["ENCOURAGING", "NEUTRAL", "MOTIVATIONAL"],
                            "description": "Tone of the message",
                        },
                        "focus_area": {
                            "type": "string",
                            "enum": ["NUTRITION", "WORKOUTS", "PROGRESS", "GENERAL"],
                            "description": "What to focus on in the message",
                        },
                    },
                    "required": ["trainee_id", "message_tone", "focus_area"],
                },
            ),
            Tool(
                name="draft_feedback_message",
                description="""Draft feedback on a trainee's specific workout or nutrition log.

Creates constructive feedback based on the log data. The trainer should
review and customize before sending.

Parameters:
- trainee_id: The ID of the trainee
- log_date: The date of the log to give feedback on (YYYY-MM-DD)
- feedback_type: WORKOUT or NUTRITION
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "log_date": {
                            "type": "string",
                            "description": "Date of the log (YYYY-MM-DD)",
                        },
                        "feedback_type": {
                            "type": "string",
                            "enum": ["WORKOUT", "NUTRITION"],
                            "description": "Type of feedback",
                        },
                    },
                    "required": ["trainee_id", "log_date", "feedback_type"],
                },
            ),
            Tool(
                name="draft_program_intro_message",
                description="""Draft an introduction message for a new program assignment.

Creates a message explaining the new program, its goals, and what to expect.
The trainer should review and personalize before sending.

Parameters:
- trainee_id: The ID of the trainee
- program_name: Name of the program being assigned
- program_goal: The main goal of the program
- duration_weeks: How long the program runs
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
                            "description": "Name of the program",
                        },
                        "program_goal": {
                            "type": "string",
                            "description": "Main goal of the program",
                        },
                        "duration_weeks": {
                            "type": "integer",
                            "description": "Program duration in weeks",
                        },
                    },
                    "required": ["trainee_id", "program_name", "program_goal", "duration_weeks"],
                },
            ),
        ]

    @server.call_tool()
    async def call_message_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
        """Handle tool calls for message drafting."""
        if name == "draft_checkin_message":
            result = await draft_checkin_message(api_client, arguments)
        elif name == "draft_feedback_message":
            result = await draft_feedback_message(api_client, arguments)
        elif name == "draft_program_intro_message":
            result = await draft_program_intro_message(api_client, arguments)
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]


async def draft_checkin_message(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Draft a check-in message based on trainee's recent activity."""
    trainee_id = args["trainee_id"]
    message_tone = args["message_tone"]
    focus_area = args["focus_area"]

    # Get trainee info
    try:
        trainee = await api_client.get_trainee(trainee_id)
        trainee_name = trainee.get("first_name") or trainee.get("display_name", "there")
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    # Get recent logs
    try:
        logs = await api_client.get_trainee_daily_logs(trainee_id, limit=7)
    except Exception:
        logs = []

    # Get weight trend
    try:
        weight_checkins = await api_client.get_trainee_weight_checkins(trainee_id, limit=7)
    except Exception:
        weight_checkins = []

    # Analyze activity
    activity_summary = _analyze_activity(logs, weight_checkins, focus_area)

    # Generate message
    message = _generate_checkin_message(
        trainee_name=trainee_name,
        activity_summary=activity_summary,
        message_tone=message_tone,
        focus_area=focus_area,
    )

    return {
        "status": "draft_created",
        "message": "Message drafted. Please review and personalize before sending.",
        "requires_approval": True,
        "trainee_id": trainee_id,
        "trainee_name": trainee_name,
        "message_tone": message_tone,
        "focus_area": focus_area,
        "activity_summary": activity_summary,
        "draft_message": message,
    }


def _analyze_activity(logs: list, weight_checkins: list, focus_area: str) -> dict[str, Any]:
    """Analyze recent activity for message context."""
    days_logged = 0
    workouts_completed = 0
    nutrition_logged = 0

    for log in logs:
        if log.get("workout_data", {}).get("exercises"):
            workouts_completed += 1
        if log.get("nutrition_data", {}).get("totals"):
            nutrition_logged += 1
            days_logged += 1

    weight_change = None
    if len(weight_checkins) >= 2:
        first = weight_checkins[-1].get("weight_kg", 0)
        last = weight_checkins[0].get("weight_kg", 0)
        weight_change = round(last - first, 2)

    return {
        "days_analyzed": 7,
        "days_logged": days_logged,
        "workouts_completed": workouts_completed,
        "nutrition_logged": nutrition_logged,
        "weight_change_kg": weight_change,
        "logging_consistency": "high" if days_logged >= 5 else "medium" if days_logged >= 3 else "low",
    }


def _generate_checkin_message(
    trainee_name: str,
    activity_summary: dict,
    message_tone: str,
    focus_area: str,
) -> str:
    """Generate a check-in message."""
    consistency = activity_summary.get("logging_consistency", "medium")
    workouts = activity_summary.get("workouts_completed", 0)
    weight_change = activity_summary.get("weight_change_kg")

    # Opening based on tone
    openings = {
        "ENCOURAGING": f"Hey {trainee_name}! Just checking in on how things are going.",
        "NEUTRAL": f"Hi {trainee_name}, wanted to touch base with you this week.",
        "MOTIVATIONAL": f"Hey {trainee_name}! Let's talk about your amazing progress!",
    }
    opening = openings.get(message_tone, openings["NEUTRAL"])

    # Body based on focus and activity
    body_parts = []

    if focus_area == "WORKOUTS" or focus_area == "GENERAL":
        if workouts >= 4:
            body_parts.append(f"Great job getting {workouts} workouts in this week!")
        elif workouts >= 2:
            body_parts.append(f"I see you got {workouts} workouts in. Let's aim for a bit more consistency.")
        else:
            body_parts.append("I noticed workouts have been light this week. Everything okay?")

    if focus_area == "NUTRITION" or focus_area == "GENERAL":
        if consistency == "high":
            body_parts.append("Your nutrition logging has been really consistent - that's key!")
        elif consistency == "medium":
            body_parts.append("Try to log your meals more consistently so we can track your progress better.")
        else:
            body_parts.append("I'd love to see more nutrition logs so I can help you better.")

    if focus_area == "PROGRESS" or focus_area == "GENERAL":
        if weight_change is not None:
            if weight_change < -0.5:
                body_parts.append(f"You're down {abs(weight_change):.1f}kg - the hard work is paying off!")
            elif weight_change > 0.5:
                body_parts.append(f"Weight is up {weight_change:.1f}kg. Let's review and make sure we're on track.")
            else:
                body_parts.append("Weight is holding steady. How are you feeling overall?")

    body = " ".join(body_parts) if body_parts else "How has your week been going?"

    # Closing based on tone
    closings = {
        "ENCOURAGING": "Keep up the good work! Let me know if you need anything.",
        "NEUTRAL": "Let me know if you have any questions or need adjustments.",
        "MOTIVATIONAL": "You've got this! Let's crush it this week!",
    }
    closing = closings.get(message_tone, closings["NEUTRAL"])

    return f"{opening}\n\n{body}\n\n{closing}"


async def draft_feedback_message(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Draft feedback on a specific log."""
    trainee_id = args["trainee_id"]
    log_date = args["log_date"]
    feedback_type = args["feedback_type"]

    # Get trainee info
    try:
        trainee = await api_client.get_trainee(trainee_id)
        trainee_name = trainee.get("first_name") or trainee.get("display_name", "there")
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    # Get the specific log
    try:
        logs = await api_client.get_trainee_daily_logs(trainee_id, limit=30)
        target_log = None
        for log in logs:
            if log.get("date") == log_date:
                target_log = log
                break
        if not target_log:
            return {"error": f"No log found for date {log_date}", "status": "failed"}
    except Exception as e:
        return {"error": f"Failed to fetch logs: {e}", "status": "failed"}

    # Generate feedback
    if feedback_type == "WORKOUT":
        feedback = _generate_workout_feedback(trainee_name, target_log)
    else:
        feedback = _generate_nutrition_feedback(trainee_name, target_log)

    return {
        "status": "draft_created",
        "message": "Feedback drafted. Please review and personalize before sending.",
        "requires_approval": True,
        "trainee_id": trainee_id,
        "trainee_name": trainee_name,
        "log_date": log_date,
        "feedback_type": feedback_type,
        "log_data": target_log.get("workout_data" if feedback_type == "WORKOUT" else "nutrition_data"),
        "draft_message": feedback,
    }


def _generate_workout_feedback(trainee_name: str, log: dict) -> str:
    """Generate workout feedback."""
    workout_data = log.get("workout_data", {})
    exercises = workout_data.get("exercises", [])

    if not exercises:
        return f"Hey {trainee_name}, I don't see any workout logged for this day. Did you train? Make sure to log your workouts so I can track your progress!"

    total_sets = sum(len(ex.get("sets", [])) for ex in exercises)
    exercises_done = len(exercises)

    feedback = f"Hey {trainee_name}!\n\n"
    feedback += f"Nice work on your workout - {exercises_done} exercises and {total_sets} total sets logged.\n\n"

    # Add specific exercise feedback
    for ex in exercises[:3]:  # Comment on first 3 exercises
        ex_name = ex.get("exercise_name", "Exercise")
        sets = ex.get("sets", [])
        if sets:
            max_weight = max(s.get("weight", 0) for s in sets)
            if max_weight > 0:
                feedback += f"- {ex_name}: Good effort with {max_weight}lbs!\n"

    feedback += "\nKeep pushing and let me know if you need any adjustments to your program!"

    return feedback


def _generate_nutrition_feedback(trainee_name: str, log: dict) -> str:
    """Generate nutrition feedback."""
    nutrition_data = log.get("nutrition_data", {})
    totals = nutrition_data.get("totals", {})

    if not totals:
        return f"Hey {trainee_name}, I don't see any nutrition logged for this day. Tracking your food is important for reaching your goals - try to log everything you eat!"

    protein = totals.get("protein", 0)
    calories = totals.get("calories", 0)

    feedback = f"Hey {trainee_name}!\n\n"
    feedback += f"Looking at your nutrition for this day:\n"
    feedback += f"- Calories: {calories}\n"
    feedback += f"- Protein: {protein}g\n\n"

    if protein >= 120:
        feedback += "Great protein intake! This will support your training well.\n"
    elif protein >= 80:
        feedback += "Decent protein, but try to get a bit more in. Consider adding a protein shake or extra serving of meat.\n"
    else:
        feedback += "Protein seems low. Make sure you're hitting your target to support muscle recovery.\n"

    feedback += "\nKeep logging consistently - it really helps us dial in your nutrition!"

    return feedback


async def draft_program_intro_message(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Draft an introduction message for a new program."""
    trainee_id = args["trainee_id"]
    program_name = args["program_name"]
    program_goal = args["program_goal"]
    duration_weeks = args["duration_weeks"]

    # Get trainee info
    try:
        trainee = await api_client.get_trainee(trainee_id)
        trainee_name = trainee.get("first_name") or trainee.get("display_name", "there")
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    message = f"""Hey {trainee_name}!

I've put together a new program for you: **{program_name}**

This is a {duration_weeks}-week program designed to help you {program_goal.lower().replace('_', ' ')}.

Here's what to expect:
- The program will progressively challenge you each week
- Make sure to log all your workouts so I can track your progress
- Every 4th week will be a deload week for recovery
- Stick to the prescribed sets and reps as closely as possible

A few tips for success:
1. Prioritize sleep and recovery
2. Stay consistent with your nutrition
3. Don't skip the warm-up!
4. Message me if anything feels too easy or too hard

I'm excited to see your progress over the next {duration_weeks} weeks. Let's crush it!

Let me know if you have any questions before we get started."""

    return {
        "status": "draft_created",
        "message": "Introduction message drafted. Please review and personalize before sending.",
        "requires_approval": True,
        "trainee_id": trainee_id,
        "trainee_name": trainee_name,
        "program_name": program_name,
        "program_goal": program_goal,
        "duration_weeks": duration_weeks,
        "draft_message": message,
    }

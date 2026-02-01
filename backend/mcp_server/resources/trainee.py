"""
Trainee Resources - Provide AI with context about trainees.
"""
from __future__ import annotations

import json
from collections.abc import Callable, Coroutine
from typing import Any, cast

from mcp.server import Server
from mcp.types import Resource

from api_client import DjangoAPIClient


def register_trainee_resources(server: Server, api_client: DjangoAPIClient) -> None:
    """Register all trainee-related resources with the MCP server."""

    async def list_resources_impl() -> list[Resource]:
        """List available trainee resources."""
        resources = []

        # Get all trainees for this trainer
        try:
            trainees = await api_client.get_trainees()
            for trainee in trainees:
                trainee_id = trainee.get("id")
                trainee_name = trainee.get("display_name", trainee.get("email", f"Trainee {trainee_id}"))

                # Add resources for each trainee
                resources.extend([
                    Resource(
                        uri=f"trainee://{trainee_id}/profile",
                        name=f"{trainee_name} - Profile",
                        description=f"Profile, goals, and preferences for {trainee_name}",
                        mimeType="application/json",
                    ),
                    Resource(
                        uri=f"trainee://{trainee_id}/program",
                        name=f"{trainee_name} - Current Program",
                        description=f"Active workout program for {trainee_name}",
                        mimeType="application/json",
                    ),
                    Resource(
                        uri=f"trainee://{trainee_id}/logs",
                        name=f"{trainee_name} - Recent Logs",
                        description=f"Recent workout and nutrition logs for {trainee_name}",
                        mimeType="application/json",
                    ),
                    Resource(
                        uri=f"trainee://{trainee_id}/progress",
                        name=f"{trainee_name} - Progress",
                        description=f"Weight trends and progress metrics for {trainee_name}",
                        mimeType="application/json",
                    ),
                    Resource(
                        uri=f"trainee://{trainee_id}/nutrition",
                        name=f"{trainee_name} - Nutrition",
                        description=f"Nutrition goals and recent intake for {trainee_name}",
                        mimeType="application/json",
                    ),
                    Resource(
                        uri=f"trainee://{trainee_id}/summary",
                        name=f"{trainee_name} - Full Summary",
                        description=f"Complete context summary for {trainee_name}",
                        mimeType="application/json",
                    ),
                ])
        except Exception as e:
            # If we can't fetch trainees, return empty list
            print(f"Error fetching trainees for resource list: {e}")

        return resources

    list_resources = cast(
        Callable[[], Coroutine[Any, Any, list[Resource]]],
        server.list_resources()(list_resources_impl),
    )

    async def read_resource_impl(uri: str) -> str:
        """Read a trainee resource by URI."""
        # Parse URI: trainee://{trainee_id}/{resource_type}
        if not uri.startswith("trainee://"):
            raise ValueError(f"Unknown resource URI: {uri}")

        parts = uri.replace("trainee://", "").split("/")
        if len(parts) != 2:
            raise ValueError(f"Invalid trainee URI format: {uri}")

        trainee_id = int(parts[0])
        resource_type = parts[1]

        # Fetch the appropriate data
        if resource_type == "profile":
            data = await get_trainee_profile_context(api_client, trainee_id)
        elif resource_type == "program":
            data = await get_trainee_program_context(api_client, trainee_id)
        elif resource_type == "logs":
            data = await get_trainee_logs_context(api_client, trainee_id)
        elif resource_type == "progress":
            data = await get_trainee_progress_context(api_client, trainee_id)
        elif resource_type == "nutrition":
            data = await get_trainee_nutrition_context(api_client, trainee_id)
        elif resource_type == "summary":
            data = await get_trainee_full_summary(api_client, trainee_id)
        else:
            raise ValueError(f"Unknown resource type: {resource_type}")

        return json.dumps(data, indent=2, default=str)

    read_resource = cast(
        Callable[[str], Coroutine[Any, Any, str]],
        server.read_resource()(read_resource_impl),
    )


async def get_trainee_profile_context(api_client: DjangoAPIClient, trainee_id: int) -> dict[str, Any]:
    """Get trainee profile with goals and preferences."""
    trainee = await api_client.get_trainee(trainee_id)
    profile = trainee.get("profile", {})

    return {
        "trainee_id": trainee_id,
        "email": trainee.get("email"),
        "display_name": trainee.get("display_name"),
        "first_name": trainee.get("first_name"),
        "last_name": trainee.get("last_name"),
        "profile": {
            "sex": profile.get("sex"),
            "age": profile.get("age"),
            "height_cm": profile.get("height_cm"),
            "weight_kg": profile.get("weight_kg"),
            "activity_level": profile.get("activity_level"),
            "goal": profile.get("goal"),
            "diet_type": profile.get("diet_type"),
            "meals_per_day": profile.get("meals_per_day"),
            "check_in_days": profile.get("check_in_days"),
        },
        "joined_date": trainee.get("date_joined"),
        "is_active": trainee.get("is_active"),
    }


async def get_trainee_program_context(api_client: DjangoAPIClient, trainee_id: int) -> dict[str, Any]:
    """Get trainee's current active program."""
    program = await api_client.get_trainee_active_program(trainee_id)

    if not program:
        return {
            "trainee_id": trainee_id,
            "has_active_program": False,
            "message": "No active program assigned",
        }

    return {
        "trainee_id": trainee_id,
        "has_active_program": True,
        "program": {
            "id": program.get("id"),
            "name": program.get("name"),
            "description": program.get("description"),
            "start_date": program.get("start_date"),
            "end_date": program.get("end_date"),
            "schedule": program.get("schedule"),
            "weeks": program.get("weeks", []),
        },
    }


async def get_trainee_logs_context(api_client: DjangoAPIClient, trainee_id: int, days: int = 14) -> dict[str, Any]:
    """Get trainee's recent daily logs."""
    logs = await api_client.get_trainee_daily_logs(trainee_id, limit=days)

    # Process logs into a more readable format
    processed_logs = []
    for log in logs:
        processed_logs.append({
            "date": log.get("date"),
            "nutrition": log.get("nutrition_data", {}),
            "workout": log.get("workout_data", {}),
            "steps": log.get("steps"),
            "sleep_hours": log.get("sleep_hours"),
            "recovery_score": log.get("recovery_score"),
            "notes": log.get("notes"),
        })

    return {
        "trainee_id": trainee_id,
        "period_days": days,
        "total_logs": len(processed_logs),
        "logs": processed_logs,
    }


async def get_trainee_progress_context(api_client: DjangoAPIClient, trainee_id: int) -> dict[str, Any]:
    """Get trainee's progress metrics and weight trends."""
    # Get weight check-ins
    weight_checkins = await api_client.get_trainee_weight_checkins(trainee_id, limit=30)

    # Get adherence analytics
    try:
        adherence = await api_client.get_adherence_analytics(trainee_id=trainee_id, days=30)
    except Exception:
        adherence = {}

    # Get progress analytics
    try:
        progress = await api_client.get_progress_analytics(trainee_id=trainee_id, days=30)
    except Exception:
        progress = {}

    # Calculate weight trend
    weight_trend = None
    if len(weight_checkins) >= 2:
        first_weight = weight_checkins[-1].get("weight_kg", 0)
        last_weight = weight_checkins[0].get("weight_kg", 0)
        weight_trend = {
            "start_weight_kg": first_weight,
            "current_weight_kg": last_weight,
            "change_kg": round(last_weight - first_weight, 2),
            "period_days": 30,
        }

    return {
        "trainee_id": trainee_id,
        "weight_checkins": [
            {"date": wc.get("date"), "weight_kg": wc.get("weight_kg"), "notes": wc.get("notes")}
            for wc in weight_checkins
        ],
        "weight_trend": weight_trend,
        "adherence": adherence,
        "progress_metrics": progress,
    }


async def get_trainee_nutrition_context(api_client: DjangoAPIClient, trainee_id: int) -> dict[str, Any]:
    """Get trainee's nutrition goals and recent intake."""
    # Get nutrition goals
    try:
        goals_response = await api_client.get_trainee_nutrition_goals(trainee_id)
        # Handle both list and single object responses
        if isinstance(goals_response, list):
            goals = goals_response[0] if goals_response else {}
        else:
            goals = goals_response
    except Exception:
        goals = {}

    # Get nutrition summary
    try:
        summary_7d = await api_client.get_trainee_nutrition_summary(trainee_id, days=7)
    except Exception:
        summary_7d = {}

    return {
        "trainee_id": trainee_id,
        "goals": {
            "protein_goal": goals.get("protein_goal"),
            "carbs_goal": goals.get("carbs_goal"),
            "fat_goal": goals.get("fat_goal"),
            "calories_goal": goals.get("calories_goal"),
            "per_meal_protein": goals.get("per_meal_protein"),
            "per_meal_carbs": goals.get("per_meal_carbs"),
            "per_meal_fat": goals.get("per_meal_fat"),
            "is_trainer_adjusted": goals.get("is_trainer_adjusted"),
        },
        "recent_summary": summary_7d,
    }


async def get_trainee_full_summary(api_client: DjangoAPIClient, trainee_id: int) -> dict[str, Any]:
    """Get complete trainee context summary for AI."""
    # Fetch all data in parallel (conceptually - Python doesn't have true parallel async)
    profile = await get_trainee_profile_context(api_client, trainee_id)
    program = await get_trainee_program_context(api_client, trainee_id)
    logs = await get_trainee_logs_context(api_client, trainee_id, days=7)  # Last 7 days for summary
    progress = await get_trainee_progress_context(api_client, trainee_id)
    nutrition = await get_trainee_nutrition_context(api_client, trainee_id)

    return {
        "trainee_id": trainee_id,
        "generated_at": "now",  # Will be replaced with actual timestamp
        "profile": profile,
        "current_program": program,
        "recent_activity": logs,
        "progress": progress,
        "nutrition": nutrition,
    }

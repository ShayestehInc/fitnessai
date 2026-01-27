"""
Trainer Resources - Provide AI with trainer's exercise library and templates.
"""
import json
from typing import Any
from mcp.server import Server
from mcp.types import Resource
from api_client import DjangoAPIClient


def register_trainer_resources(server: Server, api_client: DjangoAPIClient):
    """Register all trainer-related resources with the MCP server."""

    # Note: list_resources is registered once in trainee.py, we extend it here
    # This function adds trainer resources to the existing handler

    @server.read_resource()
    async def read_trainer_resource(uri: str) -> str:
        """Read a trainer resource by URI."""
        if not uri.startswith("trainer://"):
            # Not a trainer resource, let other handlers deal with it
            raise ValueError(f"Unknown resource URI: {uri}")

        resource_type = uri.replace("trainer://", "")

        if resource_type == "exercises":
            data = await get_exercises_context(api_client)
        elif resource_type == "templates":
            data = await get_templates_context(api_client)
        elif resource_type == "dashboard":
            data = await get_dashboard_context(api_client)
        elif resource_type == "trainees":
            data = await get_trainees_list_context(api_client)
        else:
            raise ValueError(f"Unknown trainer resource: {resource_type}")

        return json.dumps(data, indent=2, default=str)


async def get_exercises_context(api_client: DjangoAPIClient) -> dict[str, Any]:
    """Get trainer's exercise library."""
    exercises = await api_client.get_exercises()

    # Group exercises by muscle group
    by_muscle_group = {}
    for exercise in exercises:
        muscle_group = exercise.get("muscle_group", "OTHER")
        if muscle_group not in by_muscle_group:
            by_muscle_group[muscle_group] = []
        by_muscle_group[muscle_group].append({
            "id": exercise.get("id"),
            "name": exercise.get("name"),
            "description": exercise.get("description"),
            "is_public": exercise.get("is_public"),
        })

    return {
        "total_exercises": len(exercises),
        "by_muscle_group": by_muscle_group,
        "all_exercises": [
            {
                "id": e.get("id"),
                "name": e.get("name"),
                "muscle_group": e.get("muscle_group"),
                "description": e.get("description"),
            }
            for e in exercises
        ],
    }


async def get_templates_context(api_client: DjangoAPIClient) -> dict[str, Any]:
    """Get trainer's program templates."""
    templates = await api_client.get_program_templates()

    return {
        "total_templates": len(templates),
        "templates": [
            {
                "id": t.get("id"),
                "name": t.get("name"),
                "description": t.get("description"),
                "duration_weeks": t.get("duration_weeks"),
                "difficulty_level": t.get("difficulty_level"),
                "goal_type": t.get("goal_type"),
                "times_used": t.get("times_used"),
                "schedule_template": t.get("schedule_template"),
                "nutrition_template": t.get("nutrition_template"),
            }
            for t in templates
        ],
    }


async def get_dashboard_context(api_client: DjangoAPIClient) -> dict[str, Any]:
    """Get trainer dashboard overview."""
    try:
        dashboard = await api_client.get_trainer_dashboard()
    except Exception:
        dashboard = {}

    try:
        stats = await api_client.get_trainer_stats()
    except Exception:
        stats = {}

    return {
        "dashboard": dashboard,
        "stats": stats,
    }


async def get_trainees_list_context(api_client: DjangoAPIClient) -> dict[str, Any]:
    """Get list of all trainees with basic info."""
    trainees = await api_client.get_trainees()

    return {
        "total_trainees": len(trainees),
        "trainees": [
            {
                "id": t.get("id"),
                "email": t.get("email"),
                "display_name": t.get("display_name"),
                "first_name": t.get("first_name"),
                "last_name": t.get("last_name"),
                "is_active": t.get("is_active"),
                "has_active_program": t.get("has_active_program", False),
            }
            for t in trainees
        ],
    }


def get_trainer_resource_list() -> list[Resource]:
    """Get static list of trainer resources."""
    return [
        Resource(
            uri="trainer://exercises",
            name="Exercise Library",
            description="All exercises available in your library",
            mimeType="application/json",
        ),
        Resource(
            uri="trainer://templates",
            name="Program Templates",
            description="Your saved program templates",
            mimeType="application/json",
        ),
        Resource(
            uri="trainer://dashboard",
            name="Dashboard Overview",
            description="Your trainer dashboard statistics",
            mimeType="application/json",
        ),
        Resource(
            uri="trainer://trainees",
            name="All Trainees",
            description="List of all your trainees",
            mimeType="application/json",
        ),
    ]

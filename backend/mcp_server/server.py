#!/usr/bin/env python3
"""
Fitness AI MCP Server

A Model Context Protocol server that provides AI assistants with context
about trainees and tools for generating programs, nutrition advice, and more.

Usage:
    # Set the trainer's JWT token
    export TRAINER_JWT_TOKEN="your_jwt_token_here"

    # Run the server
    python server.py

    # Or with uvx (recommended for Claude Desktop)
    uvx mcp run server.py
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
from collections.abc import Callable, Coroutine
from typing import Any, cast

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, TextContent, Tool

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mcp_config import (
    DJANGO_API_BASE_URL,
    TRAINER_JWT_TOKEN,
    MCP_SERVER_NAME,
    MCP_SERVER_VERSION,
    ENABLE_PROGRAM_GENERATION,
    ENABLE_NUTRITION_ADVICE,
    ENABLE_MESSAGE_DRAFTING,
    ENABLE_PROGRESS_ANALYSIS,
)
from api_client import DjangoAPIClient
from resources.trainer import get_trainer_resource_list


def create_server(jwt_token: str | None = None) -> tuple[Server, DjangoAPIClient]:
    """Create and configure the MCP server."""
    # Use provided token or fall back to environment variable
    token = jwt_token or TRAINER_JWT_TOKEN
    if not token:
        raise ValueError(
            "No JWT token provided. Set TRAINER_JWT_TOKEN environment variable "
            "or pass token to create_server()"
        )

    # Create API client
    api_client = DjangoAPIClient(token)

    # Create MCP server
    server = Server(MCP_SERVER_NAME)

    # Register resource handlers
    _register_resources(server, api_client)

    # Register tool handlers
    _register_tools(server, api_client)

    return server, api_client


def _register_resources(server: Server, api_client: DjangoAPIClient) -> None:
    """Register all resource handlers."""

    async def list_resources_impl() -> list[Resource]:
        """List all available resources."""
        resources = []

        # Add trainer resources (static)
        resources.extend(get_trainer_resource_list())

        # Add trainee resources (dynamic based on trainer's trainees)
        try:
            trainees = await api_client.get_trainees()
            for trainee in trainees:
                trainee_id = trainee.get("id")
                trainee_name = trainee.get("display_name", trainee.get("email", f"Trainee {trainee_id}"))

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
            print(f"Warning: Could not fetch trainees for resource list: {e}", file=sys.stderr)

        return resources

    list_resources = cast(
        Callable[[], Coroutine[Any, Any, list[Resource]]],
        server.list_resources()(list_resources_impl),
    )

    async def read_resource_impl(uri: str) -> str:
        """Read a resource by URI."""
        # Import here to avoid circular imports
        from resources.trainee import (
            get_trainee_profile_context,
            get_trainee_program_context,
            get_trainee_logs_context,
            get_trainee_progress_context,
            get_trainee_nutrition_context,
            get_trainee_full_summary,
        )
        from resources.trainer import (
            get_exercises_context,
            get_templates_context,
            get_dashboard_context,
            get_trainees_list_context,
        )

        # Handle trainee resources
        if uri.startswith("trainee://"):
            parts = uri.replace("trainee://", "").split("/")
            if len(parts) != 2:
                raise ValueError(f"Invalid trainee URI format: {uri}")

            trainee_id = int(parts[0])
            resource_type = parts[1]

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
                raise ValueError(f"Unknown trainee resource type: {resource_type}")

            return json.dumps(data, indent=2, default=str)

        # Handle trainer resources
        elif uri.startswith("trainer://"):
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

        else:
            raise ValueError(f"Unknown resource URI scheme: {uri}")

    read_resource = cast(
        Callable[[str], Coroutine[Any, Any, str]],
        server.read_resource()(read_resource_impl),
    )


def _register_tools(server: Server, api_client: DjangoAPIClient) -> None:
    """Register all tool handlers."""

    async def list_tools_impl() -> list[Tool]:
        """List all available tools."""
        tools = []

        # Program generation tools
        if ENABLE_PROGRAM_GENERATION:
            tools.extend([
                Tool(
                    name="generate_program_draft",
                    description="Generate a workout program draft for a trainee. Creates a DRAFT that requires trainer approval.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer", "description": "The trainee's ID"},
                            "program_name": {"type": "string", "description": "Name for the program"},
                            "duration_weeks": {"type": "integer", "minimum": 1, "maximum": 16},
                            "goal": {"type": "string", "enum": ["BUILD_MUSCLE", "FAT_LOSS", "STRENGTH", "ENDURANCE", "RECOMP", "GENERAL_FITNESS"]},
                            "days_per_week": {"type": "integer", "minimum": 2, "maximum": 6},
                            "focus_areas": {"type": "array", "items": {"type": "string"}},
                            "notes": {"type": "string"},
                        },
                        "required": ["trainee_id", "program_name", "duration_weeks", "goal", "days_per_week"],
                    },
                ),
                Tool(
                    name="suggest_program_modifications",
                    description="Suggest modifications to an existing program based on trainee progress.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "modification_type": {"type": "string", "enum": ["PROGRESSIVE_OVERLOAD", "DELOAD", "VOLUME_ADJUSTMENT", "EXERCISE_SWAP"]},
                            "reason": {"type": "string"},
                        },
                        "required": ["trainee_id", "modification_type"],
                    },
                ),
            ])

        # Nutrition tools
        if ENABLE_NUTRITION_ADVICE:
            tools.extend([
                Tool(
                    name="suggest_macro_adjustment",
                    description="Suggest macro/calorie adjustments for a trainee based on progress.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "adjustment_reason": {"type": "string", "enum": ["PLATEAU", "GOAL_CHANGE", "ACTIVITY_CHANGE", "CUSTOM"]},
                            "notes": {"type": "string"},
                        },
                        "required": ["trainee_id", "adjustment_reason"],
                    },
                ),
                Tool(
                    name="analyze_nutrition_compliance",
                    description="Analyze a trainee's nutrition compliance and patterns.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "days": {"type": "integer", "minimum": 7, "maximum": 90},
                        },
                        "required": ["trainee_id"],
                    },
                ),
                Tool(
                    name="generate_meal_suggestions",
                    description="Generate meal suggestions to help trainee hit their remaining macros.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "remaining_protein": {"type": "number"},
                            "remaining_carbs": {"type": "number"},
                            "remaining_fat": {"type": "number"},
                            "remaining_calories": {"type": "number"},
                            "meal_type": {"type": "string", "enum": ["BREAKFAST", "LUNCH", "DINNER", "SNACK"]},
                        },
                        "required": ["trainee_id", "remaining_protein", "remaining_carbs", "remaining_fat", "remaining_calories", "meal_type"],
                    },
                ),
            ])

        # Message drafting tools
        if ENABLE_MESSAGE_DRAFTING:
            tools.extend([
                Tool(
                    name="draft_checkin_message",
                    description="Draft a check-in message for a trainee based on their recent activity.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "message_tone": {"type": "string", "enum": ["ENCOURAGING", "NEUTRAL", "MOTIVATIONAL"]},
                            "focus_area": {"type": "string", "enum": ["NUTRITION", "WORKOUTS", "PROGRESS", "GENERAL"]},
                        },
                        "required": ["trainee_id", "message_tone", "focus_area"],
                    },
                ),
                Tool(
                    name="draft_feedback_message",
                    description="Draft feedback on a specific workout or nutrition log.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "log_date": {"type": "string", "description": "Date in YYYY-MM-DD format"},
                            "feedback_type": {"type": "string", "enum": ["WORKOUT", "NUTRITION"]},
                        },
                        "required": ["trainee_id", "log_date", "feedback_type"],
                    },
                ),
                Tool(
                    name="draft_program_intro_message",
                    description="Draft an introduction message for a new program assignment.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "program_name": {"type": "string"},
                            "program_goal": {"type": "string"},
                            "duration_weeks": {"type": "integer"},
                        },
                        "required": ["trainee_id", "program_name", "program_goal", "duration_weeks"],
                    },
                ),
            ])

        # Analysis tools
        if ENABLE_PROGRESS_ANALYSIS:
            tools.extend([
                Tool(
                    name="analyze_trainee_progress",
                    description="Comprehensive progress analysis for a trainee including weight, workouts, and nutrition.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "trainee_id": {"type": "integer"},
                            "analysis_period_days": {"type": "integer", "minimum": 7, "maximum": 90},
                        },
                        "required": ["trainee_id"],
                    },
                ),
                Tool(
                    name="compare_trainees",
                    description="Compare metrics across multiple trainees to identify top performers and those needing attention.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "metric": {"type": "string", "enum": ["COMPLIANCE", "PROGRESS", "ACTIVITY"]},
                            "period_days": {"type": "integer", "minimum": 7, "maximum": 30},
                        },
                        "required": ["metric"],
                    },
                ),
                Tool(
                    name="identify_at_risk_trainees",
                    description="Identify trainees who may need attention based on activity levels.",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "days_threshold": {"type": "integer", "minimum": 3, "maximum": 14},
                        },
                        "required": [],
                    },
                ),
                Tool(
                    name="generate_weekly_summary",
                    description="Generate a weekly summary for all trainees with achievements and action items.",
                    inputSchema={
                        "type": "object",
                        "properties": {},
                        "required": [],
                    },
                ),
            ])

        return tools

    list_tools = cast(
        Callable[[], Coroutine[Any, Any, list[Tool]]],
        server.list_tools()(list_tools_impl),
    )

    async def call_tool_impl(name: str, arguments: dict[str, Any]) -> list[TextContent]:
        """Handle tool calls."""
        # Import tool implementations
        from tools.program_generator import generate_program_draft, suggest_program_modifications
        from tools.nutrition_advisor import suggest_macro_adjustment, analyze_nutrition_compliance, generate_meal_suggestions
        from tools.message_drafter import draft_checkin_message, draft_feedback_message, draft_program_intro_message
        from tools.analysis import analyze_trainee_progress, compare_trainees, identify_at_risk_trainees, generate_weekly_summary

        # Route to appropriate handler
        handlers = {
            "generate_program_draft": lambda args: generate_program_draft(api_client, args),
            "suggest_program_modifications": lambda args: suggest_program_modifications(api_client, args),
            "suggest_macro_adjustment": lambda args: suggest_macro_adjustment(api_client, args),
            "analyze_nutrition_compliance": lambda args: analyze_nutrition_compliance(api_client, args),
            "generate_meal_suggestions": lambda args: generate_meal_suggestions(api_client, args),
            "draft_checkin_message": lambda args: draft_checkin_message(api_client, args),
            "draft_feedback_message": lambda args: draft_feedback_message(api_client, args),
            "draft_program_intro_message": lambda args: draft_program_intro_message(api_client, args),
            "analyze_trainee_progress": lambda args: analyze_trainee_progress(api_client, args),
            "compare_trainees": lambda args: compare_trainees(api_client, args),
            "identify_at_risk_trainees": lambda args: identify_at_risk_trainees(api_client, args),
            "generate_weekly_summary": lambda args: generate_weekly_summary(api_client, args),
        }

        handler = handlers.get(name)
        if not handler:
            result = {"error": f"Unknown tool: {name}"}
        else:
            try:
                result = await handler(arguments)
            except Exception as e:
                result = {"error": str(e), "status": "failed"}

        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]

    call_tool = cast(
        Callable[[str, dict[str, Any]], Coroutine[Any, Any, list[TextContent]]],
        server.call_tool()(call_tool_impl),
    )


async def main() -> None:
    """Run the MCP server."""
    print(f"Starting {MCP_SERVER_NAME} v{MCP_SERVER_VERSION}", file=sys.stderr)
    print(f"Django API: {DJANGO_API_BASE_URL}", file=sys.stderr)

    try:
        server, api_client = create_server()
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Verify connection
    try:
        user = await api_client.get_current_user()
        print(f"Authenticated as: {user.get('email')} (Role: {user.get('role')})", file=sys.stderr)

        if user.get("role") != "TRAINER":
            print("Warning: This MCP server is designed for trainers. Some features may not work correctly.", file=sys.stderr)
    except Exception as e:
        print(f"Warning: Could not verify authentication: {e}", file=sys.stderr)

    # Run server
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

    # Cleanup
    await api_client.close()


if __name__ == "__main__":
    asyncio.run(main())

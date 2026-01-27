"""
Nutrition Advisor Tool - Create nutrition recommendations for trainer approval.
"""
import json
from typing import Any
from mcp.server import Server
from mcp.types import Tool, TextContent
from api_client import DjangoAPIClient


def register_nutrition_tools(server: Server, api_client: DjangoAPIClient):
    """Register nutrition advisory tools with the MCP server."""

    @server.list_tools()
    async def list_nutrition_tools() -> list[Tool]:
        """List available nutrition tools."""
        return [
            Tool(
                name="suggest_macro_adjustment",
                description="""Suggest macro/calorie adjustments for a trainee.

Analyzes the trainee's current goals, progress, and recent nutrition data
to suggest macro adjustments. Returns suggestions that require trainer approval.

Parameters:
- trainee_id: The ID of the trainee
- adjustment_reason: PLATEAU, GOAL_CHANGE, ACTIVITY_CHANGE, or CUSTOM
- notes: Optional additional context
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "adjustment_reason": {
                            "type": "string",
                            "enum": ["PLATEAU", "GOAL_CHANGE", "ACTIVITY_CHANGE", "CUSTOM"],
                            "description": "Reason for the adjustment",
                        },
                        "notes": {
                            "type": "string",
                            "description": "Additional context (optional)",
                        },
                    },
                    "required": ["trainee_id", "adjustment_reason"],
                },
            ),
            Tool(
                name="analyze_nutrition_compliance",
                description="""Analyze a trainee's nutrition compliance and patterns.

Reviews recent nutrition logs against goals to identify:
- Compliance rates for calories and macros
- Patterns (weekday vs weekend, meal timing)
- Areas needing attention

Parameters:
- trainee_id: The ID of the trainee
- days: Number of days to analyze (default 14)
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "days": {
                            "type": "integer",
                            "minimum": 7,
                            "maximum": 90,
                            "description": "Number of days to analyze",
                        },
                    },
                    "required": ["trainee_id"],
                },
            ),
            Tool(
                name="generate_meal_suggestions",
                description="""Generate meal suggestions to help trainee hit their macros.

Creates meal ideas based on the trainee's:
- Remaining macros for the day
- Diet preferences
- Meals per day setting

Parameters:
- trainee_id: The ID of the trainee
- remaining_protein: Grams of protein still needed
- remaining_carbs: Grams of carbs still needed
- remaining_fat: Grams of fat still needed
- remaining_calories: Calories still needed
- meal_type: BREAKFAST, LUNCH, DINNER, or SNACK
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "remaining_protein": {
                            "type": "number",
                            "description": "Grams of protein remaining",
                        },
                        "remaining_carbs": {
                            "type": "number",
                            "description": "Grams of carbs remaining",
                        },
                        "remaining_fat": {
                            "type": "number",
                            "description": "Grams of fat remaining",
                        },
                        "remaining_calories": {
                            "type": "number",
                            "description": "Calories remaining",
                        },
                        "meal_type": {
                            "type": "string",
                            "enum": ["BREAKFAST", "LUNCH", "DINNER", "SNACK"],
                            "description": "Type of meal",
                        },
                    },
                    "required": ["trainee_id", "remaining_protein", "remaining_carbs", "remaining_fat", "remaining_calories", "meal_type"],
                },
            ),
        ]

    @server.call_tool()
    async def call_nutrition_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
        """Handle tool calls for nutrition advisory."""
        if name == "suggest_macro_adjustment":
            result = await suggest_macro_adjustment(api_client, arguments)
        elif name == "analyze_nutrition_compliance":
            result = await analyze_nutrition_compliance(api_client, arguments)
        elif name == "generate_meal_suggestions":
            result = await generate_meal_suggestions(api_client, arguments)
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]


async def suggest_macro_adjustment(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Suggest macro adjustments based on trainee data."""
    trainee_id = args["trainee_id"]
    adjustment_reason = args["adjustment_reason"]
    notes = args.get("notes", "")

    # Get trainee profile
    try:
        trainee = await api_client.get_trainee(trainee_id)
        profile = trainee.get("profile", {})
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    # Get current nutrition goals
    try:
        goals_response = await api_client.get_trainee_nutrition_goals(trainee_id)
        if isinstance(goals_response, list):
            current_goals = goals_response[0] if goals_response else {}
        else:
            current_goals = goals_response
    except Exception:
        current_goals = {}

    # Get weight trend
    try:
        weight_checkins = await api_client.get_trainee_weight_checkins(trainee_id, limit=14)
    except Exception:
        weight_checkins = []

    # Calculate weight trend
    weight_trend = None
    if len(weight_checkins) >= 2:
        first = weight_checkins[-1].get("weight_kg", 0)
        last = weight_checkins[0].get("weight_kg", 0)
        weight_trend = {
            "change_kg": round(last - first, 2),
            "weekly_rate": round((last - first) / 2, 2) if len(weight_checkins) >= 14 else None,
        }

    # Generate suggestions based on reason and data
    suggestions = _generate_macro_suggestions(
        profile=profile,
        current_goals=current_goals,
        weight_trend=weight_trend,
        adjustment_reason=adjustment_reason,
    )

    return {
        "status": "suggestions_created",
        "message": "Macro adjustment suggestions created. Please review before applying.",
        "requires_approval": True,
        "trainee_id": trainee_id,
        "trainee_name": trainee.get("display_name", trainee.get("email")),
        "adjustment_reason": adjustment_reason,
        "notes": notes,
        "current_goals": {
            "protein": current_goals.get("protein_goal"),
            "carbs": current_goals.get("carbs_goal"),
            "fat": current_goals.get("fat_goal"),
            "calories": current_goals.get("calories_goal"),
        },
        "weight_trend": weight_trend,
        "suggestions": suggestions,
    }


def _generate_macro_suggestions(
    profile: dict,
    current_goals: dict,
    weight_trend: dict | None,
    adjustment_reason: str,
) -> list[dict[str, Any]]:
    """Generate macro adjustment suggestions."""
    suggestions = []
    goal = profile.get("goal", "GENERAL_FITNESS")
    current_calories = current_goals.get("calories_goal", 2000)
    current_protein = current_goals.get("protein_goal", 150)

    if adjustment_reason == "PLATEAU":
        if goal in ["FAT_LOSS", "RECOMP"]:
            # Suggest calorie reduction
            suggestions.append({
                "type": "reduce_calories",
                "description": "Reduce daily calories by 100-200",
                "suggested_values": {
                    "calories": current_calories - 150,
                    "carbs": current_goals.get("carbs_goal", 200) - 20,
                },
                "rationale": "Breaking through fat loss plateau often requires a modest calorie reduction",
            })
        else:
            # Suggest calorie increase for muscle building
            suggestions.append({
                "type": "increase_calories",
                "description": "Increase daily calories by 100-200",
                "suggested_values": {
                    "calories": current_calories + 150,
                    "carbs": current_goals.get("carbs_goal", 200) + 30,
                },
                "rationale": "More fuel may be needed to support muscle growth",
            })

    elif adjustment_reason == "GOAL_CHANGE":
        suggestions.append({
            "type": "recalculate_macros",
            "description": "Recalculate macros based on new goal",
            "options": [
                {
                    "goal": "FAT_LOSS",
                    "suggested_values": {
                        "calories": int(current_calories * 0.85),
                        "protein": current_protein,  # Keep protein high
                        "carbs": int(current_goals.get("carbs_goal", 200) * 0.7),
                        "fat": current_goals.get("fat_goal", 60),
                    },
                },
                {
                    "goal": "BUILD_MUSCLE",
                    "suggested_values": {
                        "calories": int(current_calories * 1.1),
                        "protein": int(current_protein * 1.1),
                        "carbs": int(current_goals.get("carbs_goal", 200) * 1.2),
                        "fat": current_goals.get("fat_goal", 60),
                    },
                },
            ],
        })

    elif adjustment_reason == "ACTIVITY_CHANGE":
        suggestions.append({
            "type": "adjust_for_activity",
            "description": "Adjust macros based on activity level change",
            "options": [
                {
                    "activity": "increased",
                    "suggested_values": {
                        "calories": current_calories + 200,
                        "carbs": current_goals.get("carbs_goal", 200) + 40,
                    },
                },
                {
                    "activity": "decreased",
                    "suggested_values": {
                        "calories": current_calories - 200,
                        "carbs": current_goals.get("carbs_goal", 200) - 40,
                    },
                },
            ],
        })

    # Always suggest maintaining protein
    suggestions.append({
        "type": "protein_recommendation",
        "description": "Protein intake recommendation",
        "suggested_values": {
            "protein_per_kg": 1.8 if goal in ["BUILD_MUSCLE", "STRENGTH"] else 1.6,
        },
        "rationale": "Adequate protein is essential for muscle preservation and growth",
    })

    return suggestions


async def analyze_nutrition_compliance(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Analyze trainee's nutrition compliance."""
    trainee_id = args["trainee_id"]
    days = args.get("days", 14)

    # Get nutrition goals
    try:
        goals_response = await api_client.get_trainee_nutrition_goals(trainee_id)
        if isinstance(goals_response, list):
            goals = goals_response[0] if goals_response else {}
        else:
            goals = goals_response
    except Exception:
        goals = {}

    # Get daily logs
    try:
        logs = await api_client.get_trainee_daily_logs(trainee_id, limit=days)
    except Exception:
        logs = []

    if not logs:
        return {
            "status": "no_data",
            "message": "No nutrition logs found for analysis",
            "trainee_id": trainee_id,
        }

    # Analyze compliance
    analysis = _analyze_logs(logs, goals)

    return {
        "status": "analysis_complete",
        "trainee_id": trainee_id,
        "period_days": days,
        "logs_found": len(logs),
        "goals": {
            "protein": goals.get("protein_goal"),
            "carbs": goals.get("carbs_goal"),
            "fat": goals.get("fat_goal"),
            "calories": goals.get("calories_goal"),
        },
        "analysis": analysis,
    }


def _analyze_logs(logs: list[dict], goals: dict) -> dict[str, Any]:
    """Analyze nutrition logs against goals."""
    protein_goal = goals.get("protein_goal", 150)
    carbs_goal = goals.get("carbs_goal", 200)
    fat_goal = goals.get("fat_goal", 60)
    calories_goal = goals.get("calories_goal", 2000)

    # Track compliance
    days_logged = 0
    protein_hits = 0
    carbs_within_range = 0
    fat_within_range = 0
    calorie_hits = 0

    total_protein = 0
    total_carbs = 0
    total_fat = 0
    total_calories = 0

    for log in logs:
        nutrition = log.get("nutrition_data", {})
        totals = nutrition.get("totals", {})

        if totals:
            days_logged += 1
            protein = totals.get("protein", 0)
            carbs = totals.get("carbs", 0)
            fat = totals.get("fat", 0)
            calories = totals.get("calories", 0)

            total_protein += protein
            total_carbs += carbs
            total_fat += fat
            total_calories += calories

            # Check compliance (within 10% of goal)
            if protein >= protein_goal * 0.9:
                protein_hits += 1
            if carbs_goal * 0.8 <= carbs <= carbs_goal * 1.2:
                carbs_within_range += 1
            if fat_goal * 0.8 <= fat <= fat_goal * 1.2:
                fat_within_range += 1
            if calories_goal * 0.9 <= calories <= calories_goal * 1.1:
                calorie_hits += 1

    if days_logged == 0:
        return {"error": "No days with nutrition data"}

    return {
        "compliance_rates": {
            "protein_hit_rate": round(protein_hits / days_logged * 100, 1),
            "carbs_in_range_rate": round(carbs_within_range / days_logged * 100, 1),
            "fat_in_range_rate": round(fat_within_range / days_logged * 100, 1),
            "calorie_hit_rate": round(calorie_hits / days_logged * 100, 1),
            "logging_rate": round(days_logged / len(logs) * 100, 1),
        },
        "averages": {
            "protein": round(total_protein / days_logged, 1),
            "carbs": round(total_carbs / days_logged, 1),
            "fat": round(total_fat / days_logged, 1),
            "calories": round(total_calories / days_logged, 1),
        },
        "insights": _generate_nutrition_insights(
            protein_hits / days_logged if days_logged else 0,
            calorie_hits / days_logged if days_logged else 0,
            total_protein / days_logged if days_logged else 0,
            protein_goal,
        ),
    }


def _generate_nutrition_insights(
    protein_rate: float,
    calorie_rate: float,
    avg_protein: float,
    protein_goal: float,
) -> list[str]:
    """Generate insights from nutrition analysis."""
    insights = []

    if protein_rate < 0.7:
        insights.append("Protein intake is frequently below target. Consider easier protein sources.")
    elif protein_rate >= 0.9:
        insights.append("Excellent protein compliance!")

    if calorie_rate < 0.6:
        if avg_protein < protein_goal:
            insights.append("Calories are inconsistent, often under-eating. May affect energy and recovery.")
        else:
            insights.append("Calories are inconsistent. Review portion sizes and meal timing.")

    if not insights:
        insights.append("Overall nutrition compliance is good. Keep up the consistency!")

    return insights


async def generate_meal_suggestions(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Generate meal suggestions based on remaining macros."""
    trainee_id = args["trainee_id"]
    remaining_protein = args["remaining_protein"]
    remaining_carbs = args["remaining_carbs"]
    remaining_fat = args["remaining_fat"]
    remaining_calories = args["remaining_calories"]
    meal_type = args["meal_type"]

    # Get trainee profile for diet preferences
    try:
        trainee = await api_client.get_trainee(trainee_id)
        profile = trainee.get("profile", {})
        diet_type = profile.get("diet_type", "BALANCED")
    except Exception:
        diet_type = "BALANCED"

    # Generate meal suggestions
    suggestions = _generate_meals(
        remaining_protein=remaining_protein,
        remaining_carbs=remaining_carbs,
        remaining_fat=remaining_fat,
        remaining_calories=remaining_calories,
        meal_type=meal_type,
        diet_type=diet_type,
    )

    return {
        "status": "suggestions_created",
        "trainee_id": trainee_id,
        "meal_type": meal_type,
        "targets": {
            "protein": remaining_protein,
            "carbs": remaining_carbs,
            "fat": remaining_fat,
            "calories": remaining_calories,
        },
        "diet_type": diet_type,
        "suggestions": suggestions,
    }


def _generate_meals(
    remaining_protein: float,
    remaining_carbs: float,
    remaining_fat: float,
    remaining_calories: float,
    meal_type: str,
    diet_type: str,
) -> list[dict[str, Any]]:
    """Generate meal suggestions based on macros needed."""
    suggestions = []

    # High protein options
    if remaining_protein > 30:
        if meal_type in ["LUNCH", "DINNER"]:
            suggestions.append({
                "name": "Grilled Chicken Breast with Rice",
                "description": "6oz chicken breast with 1 cup rice and vegetables",
                "approx_macros": {"protein": 45, "carbs": 50, "fat": 8, "calories": 450},
                "prep_time": "25 min",
            })
            suggestions.append({
                "name": "Salmon with Sweet Potato",
                "description": "5oz salmon fillet with medium sweet potato",
                "approx_macros": {"protein": 35, "carbs": 35, "fat": 15, "calories": 420},
                "prep_time": "30 min",
            })
        elif meal_type == "BREAKFAST":
            suggestions.append({
                "name": "Egg White Omelette",
                "description": "6 egg whites with vegetables and 2 slices whole grain toast",
                "approx_macros": {"protein": 30, "carbs": 25, "fat": 5, "calories": 270},
                "prep_time": "15 min",
            })

    # Low carb options
    if diet_type == "LOW_CARB" or remaining_carbs < 30:
        suggestions.append({
            "name": "Greek Salad with Grilled Chicken",
            "description": "Mixed greens, feta, olives, cucumber with 5oz chicken",
            "approx_macros": {"protein": 40, "carbs": 10, "fat": 20, "calories": 380},
            "prep_time": "15 min",
        })

    # Snack options
    if meal_type == "SNACK":
        suggestions.append({
            "name": "Greek Yogurt with Berries",
            "description": "1 cup Greek yogurt with mixed berries and honey",
            "approx_macros": {"protein": 20, "carbs": 25, "fat": 3, "calories": 200},
            "prep_time": "2 min",
        })
        suggestions.append({
            "name": "Protein Shake",
            "description": "1 scoop whey protein with almond milk and banana",
            "approx_macros": {"protein": 30, "carbs": 30, "fat": 5, "calories": 280},
            "prep_time": "3 min",
        })

    # Quick options
    if not suggestions:
        suggestions.append({
            "name": "Quick Protein Bowl",
            "description": "Pre-cooked chicken, microwave rice, and steamed veggies",
            "approx_macros": {"protein": 35, "carbs": 40, "fat": 10, "calories": 390},
            "prep_time": "10 min",
        })

    return suggestions[:3]  # Return top 3 suggestions

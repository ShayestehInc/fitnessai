"""
Analysis Tools - Analyze trainee progress and generate insights.
"""
from __future__ import annotations

import json
from collections.abc import Callable, Coroutine
from typing import Any, cast

from mcp.server import Server
from mcp.types import Tool, TextContent

from api_client import DjangoAPIClient


def register_analysis_tools(server: Server, api_client: DjangoAPIClient) -> None:
    """Register analysis tools with the MCP server."""

    async def list_analysis_tools_impl() -> list[Tool]:
        """List available analysis tools."""
        return [
            Tool(
                name="analyze_trainee_progress",
                description="""Comprehensive progress analysis for a trainee.

Analyzes multiple aspects of the trainee's journey:
- Weight trends and body composition direction
- Workout consistency and volume progression
- Nutrition compliance and patterns
- Overall adherence to program

Returns detailed insights and recommendations.

Parameters:
- trainee_id: The ID of the trainee
- analysis_period_days: Number of days to analyze (default 30)
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "trainee_id": {
                            "type": "integer",
                            "description": "The trainee's ID",
                        },
                        "analysis_period_days": {
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
                name="compare_trainees",
                description="""Compare metrics across multiple trainees.

Useful for identifying:
- Top performers
- Trainees needing attention
- Common patterns or issues

Parameters:
- metric: COMPLIANCE, PROGRESS, or ACTIVITY
- period_days: Number of days to compare (default 14)
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "metric": {
                            "type": "string",
                            "enum": ["COMPLIANCE", "PROGRESS", "ACTIVITY"],
                            "description": "Metric to compare",
                        },
                        "period_days": {
                            "type": "integer",
                            "minimum": 7,
                            "maximum": 30,
                            "description": "Number of days to analyze",
                        },
                    },
                    "required": ["metric"],
                },
            ),
            Tool(
                name="identify_at_risk_trainees",
                description="""Identify trainees who may need attention.

Flags trainees based on:
- Low logging frequency
- Missed workouts
- Declining compliance
- Stalled progress

Returns a prioritized list of trainees needing check-ins.
""",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "days_threshold": {
                            "type": "integer",
                            "minimum": 3,
                            "maximum": 14,
                            "description": "Days of inactivity to flag (default 5)",
                        },
                    },
                    "required": [],
                },
            ),
            Tool(
                name="generate_weekly_summary",
                description="""Generate a weekly summary for all trainees.

Creates an overview of the past week including:
- Active trainees count
- Average compliance rates
- Notable achievements
- Trainees needing attention

Useful for weekly planning and prioritization.
""",
                inputSchema={
                    "type": "object",
                    "properties": {},
                    "required": [],
                },
            ),
        ]

    list_analysis_tools = cast(
        Callable[[], Coroutine[Any, Any, list[Tool]]],
        server.list_tools()(list_analysis_tools_impl),
    )

    async def call_analysis_tool_impl(name: str, arguments: dict[str, Any]) -> list[TextContent]:
        """Handle tool calls for analysis."""
        if name == "analyze_trainee_progress":
            result = await analyze_trainee_progress(api_client, arguments)
        elif name == "compare_trainees":
            result = await compare_trainees(api_client, arguments)
        elif name == "identify_at_risk_trainees":
            result = await identify_at_risk_trainees(api_client, arguments)
        elif name == "generate_weekly_summary":
            result = await generate_weekly_summary(api_client, arguments)
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]

    call_analysis_tool = cast(
        Callable[[str, dict[str, Any]], Coroutine[Any, Any, list[TextContent]]],
        server.call_tool()(call_analysis_tool_impl),
    )


async def analyze_trainee_progress(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Comprehensive progress analysis for a trainee."""
    trainee_id = args["trainee_id"]
    period_days = args.get("analysis_period_days", 30)

    # Gather all data
    try:
        trainee = await api_client.get_trainee(trainee_id)
        profile = trainee.get("profile", {})
    except Exception as e:
        return {"error": f"Failed to fetch trainee: {e}", "status": "failed"}

    try:
        logs = await api_client.get_trainee_daily_logs(trainee_id, limit=period_days)
    except Exception:
        logs = []

    try:
        weight_checkins = await api_client.get_trainee_weight_checkins(trainee_id, limit=period_days)
    except Exception:
        weight_checkins = []

    try:
        goals_response = await api_client.get_trainee_nutrition_goals(trainee_id)
        if isinstance(goals_response, list):
            goals = goals_response[0] if goals_response else {}
        else:
            goals = goals_response
    except Exception:
        goals = {}

    try:
        program = await api_client.get_trainee_active_program(trainee_id)
    except Exception:
        program = None

    # Analyze weight trend
    weight_analysis = _analyze_weight_trend(weight_checkins, profile.get("goal"))

    # Analyze workout consistency
    workout_analysis = _analyze_workout_consistency(logs, program)

    # Analyze nutrition compliance
    nutrition_analysis = _analyze_nutrition_compliance_detailed(logs, goals)

    # Generate insights and recommendations
    insights = _generate_progress_insights(
        weight_analysis, workout_analysis, nutrition_analysis, profile
    )

    return {
        "status": "analysis_complete",
        "trainee_id": trainee_id,
        "trainee_name": trainee.get("display_name", trainee.get("email")),
        "analysis_period_days": period_days,
        "current_goal": profile.get("goal"),
        "weight_analysis": weight_analysis,
        "workout_analysis": workout_analysis,
        "nutrition_analysis": nutrition_analysis,
        "insights": insights["insights"],
        "recommendations": insights["recommendations"],
        "overall_score": insights["overall_score"],
    }


def _analyze_weight_trend(weight_checkins: list[dict[str, Any]], goal: str | None) -> dict[str, Any]:
    """Analyze weight check-in trends."""
    if len(weight_checkins) < 2:
        return {
            "has_data": False,
            "message": "Not enough weight data for trend analysis",
        }

    weights = [wc.get("weight_kg", 0) for wc in weight_checkins]
    first_weight = weights[-1]
    last_weight = weights[0]
    change = last_weight - first_weight

    # Calculate weekly rate
    days = len(weight_checkins)
    weekly_rate = (change / days) * 7 if days > 0 else 0

    # Determine if trend aligns with goal
    trend_direction = "losing" if change < 0 else "gaining" if change > 0 else "maintaining"
    goal_alignment = "unknown"

    if goal == "FAT_LOSS":
        goal_alignment = "aligned" if change < 0 else "misaligned" if change > 0.5 else "neutral"
    elif goal == "BUILD_MUSCLE":
        goal_alignment = "aligned" if 0 < change < 2 else "too_fast" if change > 2 else "misaligned"
    elif goal == "RECOMP":
        goal_alignment = "aligned" if abs(change) < 1 else "neutral"

    return {
        "has_data": True,
        "start_weight_kg": round(first_weight, 1),
        "current_weight_kg": round(last_weight, 1),
        "total_change_kg": round(change, 2),
        "weekly_rate_kg": round(weekly_rate, 2),
        "trend_direction": trend_direction,
        "goal_alignment": goal_alignment,
        "check_in_frequency": len(weight_checkins),
    }


def _analyze_workout_consistency(logs: list[dict[str, Any]], program: dict[str, Any] | None) -> dict[str, Any]:
    """Analyze workout logging and consistency."""
    days_with_workout = 0
    total_exercises = 0
    total_sets = 0
    total_volume = 0  # Sets × Reps × Weight

    for log in logs:
        workout = log.get("workout_data", {})
        exercises = workout.get("exercises", [])
        if exercises:
            days_with_workout += 1
            total_exercises += len(exercises)
            for ex in exercises:
                sets = ex.get("sets", [])
                total_sets += len(sets)
                for s in sets:
                    reps = s.get("reps", 0)
                    weight = s.get("weight", 0)
                    total_volume += reps * weight

    period = len(logs) if logs else 1
    workout_frequency = days_with_workout / period * 7  # Per week

    return {
        "days_analyzed": len(logs),
        "days_with_workouts": days_with_workout,
        "workout_frequency_per_week": round(workout_frequency, 1),
        "total_exercises_logged": total_exercises,
        "total_sets_logged": total_sets,
        "total_volume": round(total_volume, 0),
        "average_exercises_per_session": round(total_exercises / days_with_workout, 1) if days_with_workout else 0,
        "has_active_program": program is not None,
    }


def _analyze_nutrition_compliance_detailed(logs: list[dict[str, Any]], goals: dict[str, Any]) -> dict[str, Any]:
    """Detailed nutrition compliance analysis."""
    if not goals:
        return {
            "has_goals": False,
            "message": "No nutrition goals set for analysis",
        }

    protein_goal = goals.get("protein_goal", 150)
    calories_goal = goals.get("calories_goal", 2000)

    days_logged = 0
    protein_total = 0
    calories_total = 0
    protein_hits = 0
    calorie_hits = 0

    daily_data = []

    for log in logs:
        nutrition = log.get("nutrition_data", {})
        totals = nutrition.get("totals", {})
        if totals:
            days_logged += 1
            protein = totals.get("protein", 0)
            calories = totals.get("calories", 0)

            protein_total += protein
            calories_total += calories

            if protein >= protein_goal * 0.9:
                protein_hits += 1
            if calories_goal * 0.9 <= calories <= calories_goal * 1.1:
                calorie_hits += 1

            daily_data.append({
                "date": log.get("date"),
                "protein": protein,
                "calories": calories,
                "hit_protein": protein >= protein_goal * 0.9,
                "hit_calories": calories_goal * 0.9 <= calories <= calories_goal * 1.1,
            })

    if days_logged == 0:
        return {
            "has_goals": True,
            "days_logged": 0,
            "message": "No nutrition logs found",
        }

    return {
        "has_goals": True,
        "days_analyzed": len(logs),
        "days_logged": days_logged,
        "logging_rate": round(days_logged / len(logs) * 100, 1) if logs else 0,
        "protein_compliance_rate": round(protein_hits / days_logged * 100, 1),
        "calorie_compliance_rate": round(calorie_hits / days_logged * 100, 1),
        "average_protein": round(protein_total / days_logged, 1),
        "average_calories": round(calories_total / days_logged, 0),
        "protein_goal": protein_goal,
        "calories_goal": calories_goal,
    }


def _generate_progress_insights(
    weight_analysis: dict[str, Any],
    workout_analysis: dict[str, Any],
    nutrition_analysis: dict[str, Any],
    profile: dict[str, Any],
) -> dict[str, Any]:
    """Generate insights and recommendations from analysis."""
    insights = []
    recommendations = []
    scores = []

    goal = profile.get("goal", "GENERAL_FITNESS")

    # Weight insights
    if weight_analysis.get("has_data"):
        alignment = weight_analysis.get("goal_alignment", "unknown")
        if alignment == "aligned":
            insights.append("Weight trend is aligned with goals")
            scores.append(90)
        elif alignment == "misaligned":
            insights.append("Weight trend is not aligned with stated goal")
            recommendations.append("Review nutrition targets and adjust based on current results")
            scores.append(50)
        else:
            insights.append("Weight is relatively stable")
            scores.append(70)
    else:
        insights.append("Limited weight data - encourage regular check-ins")
        recommendations.append("Set up regular weight check-in reminders")
        scores.append(40)

    # Workout insights
    workout_freq = workout_analysis.get("workout_frequency_per_week", 0)
    if workout_freq >= 4:
        insights.append(f"Excellent workout consistency ({workout_freq:.1f}x/week)")
        scores.append(95)
    elif workout_freq >= 3:
        insights.append(f"Good workout consistency ({workout_freq:.1f}x/week)")
        scores.append(80)
    elif workout_freq >= 2:
        insights.append(f"Moderate workout frequency ({workout_freq:.1f}x/week)")
        recommendations.append("Try to add one more training day per week")
        scores.append(60)
    else:
        insights.append(f"Low workout frequency ({workout_freq:.1f}x/week)")
        recommendations.append("Focus on building consistent training habits")
        scores.append(30)

    # Nutrition insights
    if nutrition_analysis.get("has_goals") and nutrition_analysis.get("days_logged", 0) > 0:
        protein_rate = nutrition_analysis.get("protein_compliance_rate", 0)
        logging_rate = nutrition_analysis.get("logging_rate", 0)

        if protein_rate >= 80:
            insights.append(f"Strong protein compliance ({protein_rate:.0f}%)")
            scores.append(90)
        elif protein_rate >= 60:
            insights.append(f"Moderate protein compliance ({protein_rate:.0f}%)")
            recommendations.append("Focus on getting protein in every meal")
            scores.append(65)
        else:
            insights.append(f"Low protein compliance ({protein_rate:.0f}%)")
            recommendations.append("Prioritize protein sources - this is limiting progress")
            scores.append(40)

        if logging_rate < 70:
            insights.append(f"Nutrition logging could be more consistent ({logging_rate:.0f}%)")
            recommendations.append("Encourage daily food logging for better tracking")
    else:
        insights.append("Nutrition data limited or no goals set")
        recommendations.append("Set nutrition goals and encourage logging")
        scores.append(30)

    # Calculate overall score
    overall_score = round(sum(scores) / len(scores)) if scores else 50

    return {
        "insights": insights,
        "recommendations": recommendations,
        "overall_score": overall_score,
        "score_breakdown": {
            "weight_progress": scores[0] if len(scores) > 0 else None,
            "workout_consistency": scores[1] if len(scores) > 1 else None,
            "nutrition_compliance": scores[2] if len(scores) > 2 else None,
        },
    }


async def compare_trainees(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Compare metrics across trainees."""
    metric = args["metric"]
    period_days = args.get("period_days", 14)

    # Get all trainees
    try:
        trainees = await api_client.get_trainees()
    except Exception as e:
        return {"error": f"Failed to fetch trainees: {e}", "status": "failed"}

    if not trainees:
        return {"status": "no_trainees", "message": "No trainees found"}

    comparison_data = []

    for trainee in trainees:
        trainee_id = trainee.get("id")
        trainee_name = trainee.get("display_name", trainee.get("email"))

        try:
            logs = await api_client.get_trainee_daily_logs(trainee_id, limit=period_days)
        except Exception:
            logs = []

        # Calculate metric
        if metric == "COMPLIANCE":
            days_logged = sum(1 for log in logs if log.get("nutrition_data", {}).get("totals"))
            score = (days_logged / period_days * 100) if period_days > 0 else 0
        elif metric == "ACTIVITY":
            workouts = sum(1 for log in logs if log.get("workout_data", {}).get("exercises"))
            score = (workouts / period_days * 7)  # Normalize to per week
        elif metric == "PROGRESS":
            try:
                weight_checkins = await api_client.get_trainee_weight_checkins(trainee_id, limit=period_days)
                if len(weight_checkins) >= 2:
                    change = weight_checkins[0].get("weight_kg", 0) - weight_checkins[-1].get("weight_kg", 0)
                    score = abs(change)  # Use absolute change
                else:
                    score = 0
            except Exception:
                score = 0
        else:
            score = 0

        comparison_data.append({
            "trainee_id": trainee_id,
            "trainee_name": trainee_name,
            "score": round(score, 1),
        })

    # Sort by score descending
    comparison_data.sort(key=lambda x: x["score"], reverse=True)

    return {
        "status": "comparison_complete",
        "metric": metric,
        "period_days": period_days,
        "total_trainees": len(trainees),
        "rankings": comparison_data,
        "top_performers": comparison_data[:3],
        "needs_attention": comparison_data[-3:] if len(comparison_data) >= 3 else comparison_data,
    }


async def identify_at_risk_trainees(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Identify trainees who may need attention."""
    days_threshold = args.get("days_threshold", 5)

    # Get all trainees
    try:
        trainees = await api_client.get_trainees()
    except Exception as e:
        return {"error": f"Failed to fetch trainees: {e}", "status": "failed"}

    at_risk = []

    for trainee in trainees:
        trainee_id = trainee.get("id")
        trainee_name = trainee.get("display_name", trainee.get("email"))
        risk_factors = []

        try:
            logs = await api_client.get_trainee_daily_logs(trainee_id, limit=days_threshold)
        except Exception:
            logs = []

        # Check logging frequency
        days_with_any_log = sum(1 for log in logs if
                                log.get("nutrition_data", {}).get("totals") or
                                log.get("workout_data", {}).get("exercises"))

        if days_with_any_log == 0:
            risk_factors.append(f"No logs in the past {days_threshold} days")
        elif days_with_any_log < days_threshold * 0.5:
            risk_factors.append(f"Low logging frequency ({days_with_any_log}/{days_threshold} days)")

        # Check workout frequency
        workouts = sum(1 for log in logs if log.get("workout_data", {}).get("exercises"))
        if workouts == 0 and days_threshold >= 5:
            risk_factors.append("No workouts logged recently")

        # Check nutrition logging
        nutrition_days = sum(1 for log in logs if log.get("nutrition_data", {}).get("totals"))
        if nutrition_days == 0 and days_threshold >= 5:
            risk_factors.append("No nutrition logged recently")

        if risk_factors:
            at_risk.append({
                "trainee_id": trainee_id,
                "trainee_name": trainee_name,
                "risk_factors": risk_factors,
                "risk_level": "high" if len(risk_factors) >= 2 else "medium",
                "days_since_activity": days_threshold - days_with_any_log,
            })

    # Sort by risk level and days inactive
    at_risk.sort(key=lambda x: (-1 if x["risk_level"] == "high" else 0, -x["days_since_activity"]))

    return {
        "status": "analysis_complete",
        "days_threshold": days_threshold,
        "total_trainees": len(trainees),
        "at_risk_count": len(at_risk),
        "at_risk_trainees": at_risk,
        "recommendation": "Consider reaching out to high-risk trainees first" if at_risk else "All trainees are active!",
    }


async def generate_weekly_summary(api_client: DjangoAPIClient, args: dict[str, Any]) -> dict[str, Any]:
    """Generate a weekly summary for all trainees."""
    # Get all trainees
    try:
        trainees = await api_client.get_trainees()
    except Exception as e:
        return {"error": f"Failed to fetch trainees: {e}", "status": "failed"}

    total_trainees = len(trainees)
    active_trainees = 0
    total_workouts = 0
    total_nutrition_days = 0
    notable_achievements = []
    needs_attention = []

    for trainee in trainees:
        trainee_id = trainee.get("id")
        trainee_name = trainee.get("display_name", trainee.get("email"))

        try:
            logs = await api_client.get_trainee_daily_logs(trainee_id, limit=7)
        except Exception:
            logs = []

        workouts = sum(1 for log in logs if log.get("workout_data", {}).get("exercises"))
        nutrition_days = sum(1 for log in logs if log.get("nutrition_data", {}).get("totals"))

        if workouts > 0 or nutrition_days > 0:
            active_trainees += 1
            total_workouts += workouts
            total_nutrition_days += nutrition_days

            # Check for achievements
            if workouts >= 5:
                notable_achievements.append(f"{trainee_name}: {workouts} workouts this week!")
            if nutrition_days >= 6:
                notable_achievements.append(f"{trainee_name}: Logged nutrition {nutrition_days}/7 days")
        else:
            needs_attention.append({
                "name": trainee_name,
                "issue": "No activity logged this week",
            })

    return {
        "status": "summary_complete",
        "period": "Last 7 days",
        "overview": {
            "total_trainees": total_trainees,
            "active_trainees": active_trainees,
            "inactive_trainees": total_trainees - active_trainees,
            "total_workouts_logged": total_workouts,
            "total_nutrition_days_logged": total_nutrition_days,
            "average_workouts_per_active_trainee": round(total_workouts / active_trainees, 1) if active_trainees else 0,
        },
        "notable_achievements": notable_achievements[:5],  # Top 5
        "needs_attention": needs_attention[:5],  # Top 5
        "action_items": [
            f"Check in with {len(needs_attention)} inactive trainee(s)" if needs_attention else "All trainees active!",
            f"Recognize {len(notable_achievements)} trainee(s) for great work" if notable_achievements else "",
        ],
    }

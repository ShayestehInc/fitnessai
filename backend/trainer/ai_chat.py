"""
AI Chat Service for Trainers

Provides LLM integration with full trainee context using LangChain.
Supports multiple providers: OpenAI, Anthropic, Google.
"""
from __future__ import annotations

import json
import os
from typing import TYPE_CHECKING, Any, Optional, Union, cast
from decimal import Decimal
from datetime import timedelta

from django.utils import timezone
from django.contrib.auth import get_user_model

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.language_models.chat_models import BaseChatModel
from pydantic import SecretStr

from .ai_config import AIProvider, AIModelConfig, get_ai_config, get_api_key
from users.models import User

_ENV_VAR_FOR_PROVIDER: dict[AIProvider, str] = {
    AIProvider.OPENAI: "OPENAI_API_KEY",
    AIProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
    AIProvider.GOOGLE: "GOOGLE_API_KEY",
}


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that handles Decimal types."""
    def default(self, obj: Any) -> Any:
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def get_chat_model(config: AIModelConfig) -> BaseChatModel:
    """
    Get a LangChain chat model based on configuration.

    Args:
        config: AI model configuration

    Returns:
        A LangChain chat model instance

    Raises:
        ValueError: If the API key for the configured provider is missing.
    """
    api_key = get_api_key(config.provider)
    if not api_key:
        raise ValueError(
            f"API key for {config.provider.value} is not configured. "
            f"Set the {_ENV_VAR_FOR_PROVIDER[config.provider]} environment variable."
        )

    if config.provider == AIProvider.OPENAI:
        from langchain_openai import ChatOpenAI
        return ChatOpenAI(
            model=config.model_name,
            temperature=config.temperature,
            api_key=SecretStr(api_key),
        )

    elif config.provider == AIProvider.ANTHROPIC:
        from langchain_anthropic import ChatAnthropic
        # Note: Using kwargs dict to work around type stub limitations
        # The actual API accepts model, max_tokens, etc. but type stubs don't reflect this
        anthropic_kwargs: dict[str, Any] = {
            "model": config.model_name,
            "temperature": config.temperature,
            "max_tokens": config.max_tokens,
            "api_key": SecretStr(api_key),
        }
        return ChatAnthropic(**anthropic_kwargs)

    elif config.provider == AIProvider.GOOGLE:
        from langchain_google_genai import ChatGoogleGenerativeAI
        return ChatGoogleGenerativeAI(
            model=config.model_name,
            temperature=config.temperature,
            max_output_tokens=config.max_tokens,
            google_api_key=api_key,
        )

    else:
        raise ValueError(f"Unsupported AI provider: {config.provider}")


class TraineeContextBuilder:
    """Builds context about trainees for AI chat."""

    def __init__(self, trainer: User) -> None:
        self.trainer = trainer

    def get_trainee_list(self) -> list[dict[str, Any]]:
        """Get list of all trainees with basic info."""
        trainees = User.objects.filter(
            parent_trainer=self.trainer,
            role=User.Role.TRAINEE,
            is_active=True
        )

        return [
            {
                "id": t.id,
                "email": t.email,
                "name": f"{t.first_name} {t.last_name}".strip() or t.email,
                "joined": str(t.date_joined.date()) if t.date_joined else None,
            }
            for t in trainees
        ]

    def get_trainee_summary(self, trainee_id: int) -> dict[str, Any]:
        """Get comprehensive summary for a specific trainee."""
        try:
            trainee = User.objects.get(
                id=trainee_id,
                parent_trainer=self.trainer,
                role=User.Role.TRAINEE
            )
        except User.DoesNotExist:
            return {"error": f"Trainee {trainee_id} not found"}

        summary = {
            "trainee_id": trainee.id,
            "email": trainee.email,
            "name": f"{trainee.first_name} {trainee.last_name}".strip() or trainee.email,
            "is_active": trainee.is_active,
        }

        # Get profile
        try:
            profile = trainee.profile
            summary["profile"] = {
                "sex": profile.sex,
                "age": profile.age,
                "height_cm": profile.height_cm,
                "weight_kg": float(profile.weight_kg) if profile.weight_kg else None,
                "activity_level": profile.activity_level,
                "goal": profile.goal,
                "diet_type": profile.diet_type,
                "meals_per_day": profile.meals_per_day,
            }
        except Exception:
            summary["profile"] = None

        # Get nutrition goals
        try:
            goal = trainee.nutrition_goal
            summary["nutrition_goals"] = {
                "protein": goal.protein_goal,
                "carbs": goal.carbs_goal,
                "fat": goal.fat_goal,
                "calories": goal.calories_goal,
            }
        except Exception:
            summary["nutrition_goals"] = None

        # Get recent daily logs (last 7 days)
        try:
            logs = trainee.daily_logs.order_by('-date')[:7]
            summary["recent_logs"] = [
                {
                    "date": str(log.date),
                    "nutrition": log.nutrition_data.get("totals", {}) if log.nutrition_data else {},
                    "workout_exercises": len(log.workout_data.get("exercises", [])) if log.workout_data else 0,
                    "steps": log.steps,
                    "sleep_hours": float(log.sleep_hours) if log.sleep_hours else None,
                }
                for log in logs
            ]
        except Exception:
            summary["recent_logs"] = []

        # Get weight trend
        try:
            checkins = trainee.weight_checkins.order_by('-date')[:14]
            if checkins:
                weights = [(str(c.date), float(c.weight_kg)) for c in checkins]
                summary["weight_checkins"] = weights
                if len(weights) >= 2:
                    summary["weight_change"] = round(weights[0][1] - weights[-1][1], 2)
        except Exception:
            summary["weight_checkins"] = []

        # Get current program
        try:
            program = trainee.programs.filter(is_active=True).first()
            if program:
                summary["current_program"] = {
                    "name": program.name,
                    "start_date": str(program.start_date) if program.start_date else None,
                    "end_date": str(program.end_date) if program.end_date else None,
                }
        except Exception:
            summary["current_program"] = None

        return summary

    def get_trainer_context(self) -> dict[str, Any]:
        """Get trainer's overall context."""
        trainees = User.objects.filter(
            parent_trainer=self.trainer,
            role=User.Role.TRAINEE
        )

        today = timezone.now().date()

        # Count active trainees
        active_count = trainees.filter(is_active=True).count()

        # Get trainees needing attention (no activity in 3+ days)
        from trainer.models import TraineeActivitySummary
        three_days_ago = today - timedelta(days=3)

        inactive_ids = []
        for trainee in trainees.filter(is_active=True):
            latest = trainee.activity_summaries.order_by('-date').first()
            if not latest or latest.date < three_days_ago:
                inactive_ids.append(trainee.id)

        return {
            "total_trainees": trainees.count(),
            "active_trainees": active_count,
            "trainees_needing_attention": len(inactive_ids),
            "today": str(today),
        }


class AIChat:
    """AI Chat service using LangChain with configurable providers."""

    SYSTEM_PROMPT = """You are an AI assistant for fitness trainers using the Fitness AI platform.

You have access to data about the trainer's trainees, including their profiles, goals, workout logs, nutrition logs, and progress.

Your role is to help trainers:
1. Understand their trainees' progress and compliance
2. Identify trainees who need attention
3. Suggest program modifications or nutrition adjustments
4. Draft messages to send to trainees
5. Analyze trends and patterns across trainees

Important guidelines:
- Always be helpful and provide actionable insights
- When suggesting changes (programs, nutrition, etc.), clearly mark them as SUGGESTIONS that require trainer approval
- Use the trainee data provided to give specific, personalized advice
- If asked about a specific trainee, use their data from the context
- Be concise but thorough in your responses
- Format responses for readability (use bullet points, headers when appropriate)

Remember: You are assisting the trainer, not directly communicating with trainees."""

    def __init__(self, trainer: User, config: Optional[AIModelConfig] = None) -> None:
        self.trainer = trainer
        self.context_builder = TraineeContextBuilder(trainer)
        self.config = config or get_ai_config()
        self.llm = get_chat_model(self.config)

    def _build_context_message(self, trainee_id: Optional[int] = None) -> str:
        """Build context message with trainer and trainee data."""
        context_parts = []

        # Add trainer overview
        trainer_ctx = self.context_builder.get_trainer_context()
        context_parts.append(f"## Trainer Overview\n{json.dumps(trainer_ctx, indent=2, cls=DecimalEncoder)}")

        # Add trainee list
        trainees = self.context_builder.get_trainee_list()
        context_parts.append(f"## Your Trainees ({len(trainees)} total)\n{json.dumps(trainees, indent=2, cls=DecimalEncoder)}")

        # If specific trainee requested, add their detailed summary
        if trainee_id:
            trainee_summary = self.context_builder.get_trainee_summary(trainee_id)
            context_parts.append(f"## Detailed Context for Trainee ID {trainee_id}\n{json.dumps(trainee_summary, indent=2, cls=DecimalEncoder)}")

        return "\n\n".join(context_parts)

    def chat(
        self,
        message: str,
        conversation_history: Optional[list[dict[str, str]]] = None,
        trainee_id: Optional[int] = None,
    ) -> dict[str, Any]:
        """
        Send a chat message and get a response.

        Args:
            message: The user's message
            conversation_history: Previous messages in the conversation
            trainee_id: Optional specific trainee to focus on

        Returns:
            dict with 'response', 'trainee_context_used', 'provider', 'model'
        """
        if conversation_history is None:
            conversation_history = []

        # Build context
        context = self._build_context_message(trainee_id)

        # Build messages list
        messages: list[BaseMessage] = [SystemMessage(content=self.SYSTEM_PROMPT)]

        # Add conversation history
        for msg in conversation_history:
            if msg["role"] == "user":
                messages.append(HumanMessage(content=msg["content"]))
            elif msg["role"] == "assistant":
                messages.append(AIMessage(content=msg["content"]))

        # Add current message with context
        user_message = f"""<context>
{context}
</context>

{message}"""

        messages.append(HumanMessage(content=user_message))

        # Call LLM
        try:
            response = self.llm.invoke(messages)

            # Extract token usage if available
            usage = None
            if hasattr(response, 'usage_metadata') and response.usage_metadata:
                usage = {
                    "input_tokens": response.usage_metadata.get("input_tokens", 0),
                    "output_tokens": response.usage_metadata.get("output_tokens", 0),
                }
            elif hasattr(response, 'response_metadata'):
                meta = response.response_metadata
                if 'usage' in meta:
                    usage = {
                        "input_tokens": meta['usage'].get('prompt_tokens', 0),
                        "output_tokens": meta['usage'].get('completion_tokens', 0),
                    }

            return {
                "response": response.content,
                "trainee_context_used": trainee_id,
                "provider": self.config.provider.value,
                "model": self.config.model_name,
                "usage": usage,
            }

        except Exception as e:
            return {
                "error": str(e),
                "response": None,
                "provider": self.config.provider.value,
                "model": self.config.model_name,
            }


def get_ai_chat(trainer: User, config: Optional[AIModelConfig] = None) -> AIChat:
    """Factory function to get AI chat instance for a trainer."""
    return AIChat(trainer, config)


# Convenience function to list available providers
def get_available_providers() -> list[dict[str, Any]]:
    """Get list of available AI providers with their configuration."""
    from .ai_config import MODEL_CONFIGS

    providers = []
    for provider, config in MODEL_CONFIGS.items():
        api_key = get_api_key(provider)
        providers.append({
            "provider": provider.value,
            "model": config.model_name,
            "configured": bool(api_key),
        })

    return providers

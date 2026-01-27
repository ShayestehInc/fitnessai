"""
AI Configuration for Trainer Chat

Supports multiple LLM providers via LangChain.
"""
import os
from enum import Enum
from typing import Optional
from dataclasses import dataclass


class AIProvider(str, Enum):
    """Supported AI providers."""
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    GOOGLE = "google"


@dataclass
class AIModelConfig:
    """Configuration for an AI model."""
    provider: AIProvider
    model_name: str
    temperature: float = 0.7
    max_tokens: int = 2048


# Default model configurations for each provider
MODEL_CONFIGS = {
    AIProvider.OPENAI: AIModelConfig(
        provider=AIProvider.OPENAI,
        model_name="gpt-4o",
        temperature=0.7,
        max_tokens=2048,
    ),
    AIProvider.ANTHROPIC: AIModelConfig(
        provider=AIProvider.ANTHROPIC,
        model_name="claude-sonnet-4-20250514",
        temperature=0.7,
        max_tokens=2048,
    ),
    AIProvider.GOOGLE: AIModelConfig(
        provider=AIProvider.GOOGLE,
        model_name="gemini-1.5-pro",
        temperature=0.7,
        max_tokens=2048,
    ),
}


def get_ai_config() -> AIModelConfig:
    """Get AI configuration from environment variables."""
    provider_str = os.getenv("AI_PROVIDER", "anthropic").lower()

    try:
        provider = AIProvider(provider_str)
    except ValueError:
        # Default to Anthropic if invalid provider
        provider = AIProvider.ANTHROPIC

    # Get base config for provider
    config = MODEL_CONFIGS.get(provider, MODEL_CONFIGS[AIProvider.ANTHROPIC])

    # Allow overrides from environment
    model_name = os.getenv("AI_MODEL_NAME")
    if model_name:
        config = AIModelConfig(
            provider=config.provider,
            model_name=model_name,
            temperature=config.temperature,
            max_tokens=config.max_tokens,
        )

    temperature = os.getenv("AI_TEMPERATURE")
    if temperature:
        try:
            config = AIModelConfig(
                provider=config.provider,
                model_name=config.model_name,
                temperature=float(temperature),
                max_tokens=config.max_tokens,
            )
        except ValueError:
            pass

    max_tokens = os.getenv("AI_MAX_TOKENS")
    if max_tokens:
        try:
            config = AIModelConfig(
                provider=config.provider,
                model_name=config.model_name,
                temperature=config.temperature,
                max_tokens=int(max_tokens),
            )
        except ValueError:
            pass

    return config


def get_api_key(provider: AIProvider) -> Optional[str]:
    """Get API key for the specified provider."""
    key_map = {
        AIProvider.OPENAI: "OPENAI_API_KEY",
        AIProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
        AIProvider.GOOGLE: "GOOGLE_API_KEY",
    }
    env_var = key_map.get(provider)
    return os.getenv(env_var) if env_var else None

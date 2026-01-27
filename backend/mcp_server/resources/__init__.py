"""
MCP Resources - Read-only data providers for AI context.
"""
from .trainee import register_trainee_resources
from .trainer import register_trainer_resources

__all__ = ["register_trainee_resources", "register_trainer_resources"]

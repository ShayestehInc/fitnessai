"""
MCP Tools - Actions that create drafts/suggestions for trainer approval.
"""
from .program_generator import register_program_tools
from .nutrition_advisor import register_nutrition_tools
from .message_drafter import register_message_tools
from .analysis import register_analysis_tools

__all__ = [
    "register_program_tools",
    "register_nutrition_tools",
    "register_message_tools",
    "register_analysis_tools",
]

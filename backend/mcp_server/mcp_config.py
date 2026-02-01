"""
MCP Server Configuration
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Django API Configuration
DJANGO_API_BASE_URL: str = os.getenv("DJANGO_API_BASE_URL", "http://localhost:8000/api")

# Authentication
# The trainer's JWT token will be passed via environment or MCP initialization
TRAINER_JWT_TOKEN: str = os.getenv("TRAINER_JWT_TOKEN", "")

# Server Configuration
MCP_SERVER_NAME: str = "fitness-ai-trainer"
MCP_SERVER_VERSION: str = "1.0.0"

# Feature Flags
ENABLE_PROGRAM_GENERATION: bool = True
ENABLE_NUTRITION_ADVICE: bool = True
ENABLE_MESSAGE_DRAFTING: bool = True
ENABLE_PROGRESS_ANALYSIS: bool = True

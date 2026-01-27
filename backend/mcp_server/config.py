"""
MCP Server Configuration
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Django API Configuration
DJANGO_API_BASE_URL = os.getenv("DJANGO_API_BASE_URL", "http://localhost:8000/api")

# Authentication
# The trainer's JWT token will be passed via environment or MCP initialization
TRAINER_JWT_TOKEN = os.getenv("TRAINER_JWT_TOKEN", "")

# Server Configuration
MCP_SERVER_NAME = "fitness-ai-trainer"
MCP_SERVER_VERSION = "1.0.0"

# Feature Flags
ENABLE_PROGRAM_GENERATION = True
ENABLE_NUTRITION_ADVICE = True
ENABLE_MESSAGE_DRAFTING = True
ENABLE_PROGRESS_ANALYSIS = True

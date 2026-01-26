# Fitness AI Backend

Django REST API backend for the Fitness AI platform.

## Quick Start

```bash
# From project root
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup environment
cp example.env .env
# Edit .env with your configuration

# Setup database
createdb fitnessai
python manage.py migrate
python manage.py createsuperuser

# Run server
python manage.py runserver
```

Server runs at: `http://localhost:8000`

## API Endpoints

### Authentication
- `POST /api/auth/users/` - Register
- `POST /api/auth/jwt/create/` - Login
- `POST /api/auth/jwt/refresh/` - Refresh token
- `GET /api/auth/users/me/` - Get current user

### Natural Language Logging
- `POST /api/workouts/daily-logs/parse-natural-language/` - Parse input
- `POST /api/workouts/daily-logs/confirm-and-save/` - Save log

### Other Endpoints
- `GET /api/workouts/exercises/` - List exercises
- `GET /api/workouts/programs/` - List programs
- `GET /api/workouts/daily-logs/` - List daily logs

## Environment Variables

See `example.env` for all required variables:
- `SECRET_KEY` - Django secret key
- `DB_*` - PostgreSQL connection
- `OPENAI_API_KEY` - Required for AI parsing
- `STRIPE_*` - For future payment integration

## Project Structure

```
backend/
├── config/              # Django settings
├── users/               # User management
├── workouts/            # Workout & nutrition + AI parsing
│   ├── services/       # Business logic
│   │   └── natural_language_parser.py
│   └── ai_prompts.py   # AI prompts
├── subscriptions/       # Subscription tiers
└── core/               # Shared utilities
```

## Development Standards

- All business logic in `services/` directories
- Type hints mandatory
- Prompts stored in `ai_prompts.py`
- Prefetching to prevent N+1 queries

See `.cursorrules` in project root for full standards.

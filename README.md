# Fitness AI for Trainers

A high-performance, native mobile fitness platform connecting Trainers with Trainees, managed by a Super Admin.

## Project Structure

```
fitnessai/
├── backend/              # Django REST API (Docker-ready)
├── mobile/               # Flutter mobile app
└── docker-compose.yml    # Docker orchestration
```

## Quick Start

### Option 1: Docker (Recommended) 🐳

```bash
# Start everything (Backend + Database)
./run_docker.sh
```

This automatically:
- ✅ Sets up PostgreSQL database
- ✅ Runs migrations
- ✅ Starts Django server on `http://localhost:8000`

**Services:**
- Backend API: `http://localhost:8000`
- Admin Panel: `http://localhost:8000/admin`
- Database: `localhost:5432`

### Option 2: Manual Setup

```bash
# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp example.env .env  # Edit with your config
python manage.py migrate
python manage.py runserver

# Mobile (separate terminal)
cd mobile
./setup.sh
flutter run -d ios
```

## Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Run migrations
docker-compose exec backend python manage.py migrate

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Stop services
docker-compose down
```

See `DOCKER_SETUP.md` for full Docker documentation.

## Tech Stack

- **Backend**: Django REST Framework + PostgreSQL (Docker)
- **Mobile**: Flutter with Riverpod
- **AI**: OpenAI GPT-4o for natural language parsing
- **Auth**: Email-only authentication (no username)

## Features

- ✅ **AI Command Center**: Natural language logging
- ✅ **Email Authentication**: No username required
- ✅ **Role-Based Access**: Admin, Trainer, Trainee
- ✅ **Health Integration**: HealthKit/Health Connect ready
- ✅ **Offline-First**: Ready for Drift database

## Environment Setup

Create `.env` file in project root:

```env
SECRET_KEY=your-secret-key
DEBUG=True
DB_NAME=fitnessai
DB_USER=postgres
DB_PASSWORD=postgres
OPENAI_API_KEY=your-openai-key
```

## Documentation

- **Docker Setup**: See `DOCKER_SETUP.md`
- **Email Auth Migration**: See `EMAIL_AUTH_MIGRATION.md`
- **Backend API**: See `backend/README.md`
- **Mobile App**: See `mobile/README.md`
- **Project Structure**: See `PROJECT_STRUCTURE.md`

## License

Proprietary - Shayesteh Inc.

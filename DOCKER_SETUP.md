# Docker Setup for Fitness AI

## Quick Start

### Start Everything (Backend + Database)

```bash
./run_docker.sh
```

This will:
- Build Docker images
- Start PostgreSQL database
- Start Django backend
- Run migrations automatically
- Show logs

### Manual Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up --build -d
```

## Services

- **Backend**: `http://localhost:8000`
- **Database**: `localhost:5432`
- **Admin**: `http://localhost:8000/admin`

## Common Tasks

### Run Migrations

```bash
docker-compose exec backend python manage.py makemigrations
docker-compose exec backend python manage.py migrate
```

### Create Superuser

```bash
docker-compose exec backend python manage.py createsuperuser
```

### Access Django Shell

```bash
docker-compose exec backend python manage.py shell
```

### View Logs

```bash
# All services
docker-compose logs -f

# Just backend
docker-compose logs -f backend

# Just database
docker-compose logs -f db
```

### Stop Services

```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Slate)

```bash
docker-compose down -v
```

## Environment Variables

Create a `.env` file in the project root:

```bash
# Django
SECRET_KEY=your-secret-key-here
DEBUG=True

# Database (used by docker-compose)
DB_NAME=fitnessai
DB_USER=postgres
DB_PASSWORD=postgres

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Stripe
STRIPE_SECRET_KEY=your-stripe-key
STRIPE_PUBLISHABLE_KEY=your-stripe-key
```

## Database Access

The database is accessible at `localhost:5432` from your host machine:

```bash
# Using psql
psql -h localhost -U postgres -d fitnessai

# Password: postgres (or whatever you set in .env)
```

## Volumes

Docker creates persistent volumes for:
- `postgres_data` - Database data
- `backend_static` - Static files
- `backend_media` - Media files

Data persists even after stopping containers.

## Troubleshooting

### Port Already in Use

If port 8000 or 5432 is already in use:

```bash
# Change ports in docker-compose.yml
ports:
  - "8001:8000"  # Use 8001 instead of 8000
```

### Rebuild After Code Changes

```bash
docker-compose up --build -d
```

### Reset Database

```bash
docker-compose down -v
docker-compose up -d
# Then run migrations again
docker-compose exec backend python manage.py migrate
```

### View Container Status

```bash
docker-compose ps
```

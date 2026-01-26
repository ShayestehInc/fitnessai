#!/bin/bash

# Fitness AI - Docker Development Startup Script
# Runs both Django backend and PostgreSQL in Docker containers

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 Starting Fitness AI with Docker...${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    echo -e "${YELLOW}   Visit: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env file with your configuration${NC}"
        echo -e "${YELLOW}   Required: SECRET_KEY, OPENAI_API_KEY${NC}"
        echo -e "${YELLOW}   Generating SECRET_KEY...${NC}"
        # Generate a secret key
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || openssl rand -hex 32)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
        else
            sed -i "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
        fi
        echo -e "${GREEN}✅ SECRET_KEY generated and added to .env${NC}"
    else
        echo -e "${RED}❌ .env.example not found. Please create .env file manually.${NC}"
        exit 1
    fi
fi

# Use docker-compose or docker compose (newer versions)
COMPOSE_CMD="docker-compose"
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Building and starting containers...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Build and start containers
$COMPOSE_CMD up --build -d

echo ""
echo -e "${GREEN}✅ Containers started!${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🌐 Services:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Backend API: http://localhost:8000${NC}"
echo -e "${GREEN}✅ Admin Panel: http://localhost:8000/admin${NC}"
echo -e "${GREEN}✅ API Root: http://localhost:8000/api/${NC}"
echo -e "${GREEN}✅ Database: localhost:5432${NC}"
echo ""
echo -e "${YELLOW}📝 Useful commands:${NC}"
echo -e "   View logs:        ${COMPOSE_CMD} logs -f"
echo -e "   Stop containers:  ${COMPOSE_CMD} down"
echo -e "   Restart:          ${COMPOSE_CMD} restart"
echo -e "   Run migrations:    ${COMPOSE_CMD} exec backend python manage.py migrate"
echo -e "   Create superuser:  ${COMPOSE_CMD} exec backend python manage.py createsuperuser"
echo -e "   Shell access:      ${COMPOSE_CMD} exec backend python manage.py shell"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop containers${NC}"
echo ""

# Follow logs
$COMPOSE_CMD logs -f

#!/bin/bash

# Helper script for common Docker operations

set -e

# Use docker-compose or docker compose
COMPOSE_CMD="docker-compose"
if ! command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
fi

case "$1" in
    migrate)
        echo "🔄 Running migrations..."
        $COMPOSE_CMD exec backend python manage.py makemigrations
        $COMPOSE_CMD exec backend python manage.py migrate
        ;;
    createsuperuser)
        echo "👤 Creating superuser..."
        $COMPOSE_CMD exec backend python manage.py createsuperuser
        ;;
    shell)
        echo "🐚 Opening Django shell..."
        $COMPOSE_CMD exec backend python manage.py shell
        ;;
    logs)
        echo "📋 Viewing logs..."
        $COMPOSE_CMD logs -f "${2:-}"
        ;;
    restart)
        echo "🔄 Restarting services..."
        $COMPOSE_CMD restart "${2:-}"
        ;;
    stop)
        echo "🛑 Stopping services..."
        $COMPOSE_CMD down
        ;;
    clean)
        echo "🧹 Stopping and removing volumes..."
        $COMPOSE_CMD down -v
        ;;
    build)
        echo "🔨 Rebuilding containers..."
        $COMPOSE_CMD up --build -d
        ;;
    *)
        echo "Usage: $0 {migrate|createsuperuser|shell|logs|restart|stop|clean|build}"
        echo ""
        echo "Commands:"
        echo "  migrate          - Run database migrations"
        echo "  createsuperuser  - Create Django superuser"
        echo "  shell            - Open Django shell"
        echo "  logs [service]   - View logs (optionally for specific service)"
        echo "  restart [service]- Restart services (optionally specific service)"
        echo "  stop             - Stop all services"
        echo "  clean            - Stop and remove volumes (clean slate)"
        echo "  build            - Rebuild and start containers"
        exit 1
        ;;
esac

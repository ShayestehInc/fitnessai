#!/bin/sh

set -e

echo "Waiting for database..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 0.1
done
echo "Database is ready!"

echo "Running migrations..."
python manage.py makemigrations --noinput || true
python manage.py migrate --noinput

echo "Starting server..."
exec "$@"

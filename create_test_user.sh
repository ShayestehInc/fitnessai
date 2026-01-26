#!/bin/bash

# Create a test user for Fitness AI
# This script creates a test Trainee user via Django shell

cd backend

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d "env" ]; then
    source env/bin/activate
fi

echo "Creating test user..."
echo ""

python manage.py shell << EOF
from users.models import User

# Create a test Trainee user
username = "trainee1"
email = "trainee1@test.com"
password = "test123456"

if User.objects.filter(username=username).exists():
    print(f"User '{username}' already exists!")
    user = User.objects.get(username=username)
    print(f"Username: {user.username}")
    print(f"Email: {user.email}")
    print(f"Role: {user.role}")
else:
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        role='TRAINEE'
    )
    print(f"✅ Created user: {username}")
    print(f"   Email: {email}")
    print(f"   Password: {password}")
    print(f"   Role: TRAINEE")

print("")
print("You can now login with:")
print(f"  Username: {username}")
print(f"  Password: {password}")
EOF

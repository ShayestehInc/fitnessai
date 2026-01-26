#!/bin/bash

# Fitness AI - Full Stack Development Startup Script
# Runs both Django backend and Flutter mobile app simultaneously

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Trap to cleanup background processes
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down services...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$MOBILE_PID" ]; then
        kill $MOBILE_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${GREEN}🚀 Starting Fitness AI Full Stack Development...${NC}"
echo ""

# ============================================
# BACKEND SETUP
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Setting up Backend (Django)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd backend

# Check if virtual environment exists
if [ ! -d "venv" ] && [ ! -d "env" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating one...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d "env" ]; then
    source env/bin/activate
fi

echo -e "${GREEN}✅ Virtual environment activated${NC}"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Copying from example.env...${NC}"
    if [ -f "example.env" ]; then
        cp example.env .env
        echo -e "${YELLOW}⚠️  Please edit backend/.env file with your configuration${NC}"
        echo -e "${YELLOW}   Required: SECRET_KEY, DB_*, OPENAI_API_KEY${NC}"
    else
        echo -e "${RED}❌ example.env not found. Please create backend/.env file manually.${NC}"
        exit 1
    fi
fi

# Check if requirements are installed
echo -e "${GREEN}📦 Checking dependencies...${NC}"
if ! python -c "import django" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Dependencies not installed. Installing from requirements.txt...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi

# Run migrations
echo -e "${GREEN}🔄 Running database migrations...${NC}"
python manage.py makemigrations --noinput 2>/dev/null || true
python manage.py migrate --noinput

echo -e "${GREEN}✅ Backend setup complete${NC}"
echo ""

# ============================================
# MOBILE SETUP
# ============================================
cd ../mobile

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Setting up Mobile App (Flutter)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    echo -e "${YELLOW}   Skipping mobile app startup...${NC}"
    MOBILE_AVAILABLE=false
else
    MOBILE_AVAILABLE=true
    echo -e "${GREEN}✅ Flutter found${NC}"
    
    # Check if dependencies are installed
    if [ ! -d ".dart_tool" ]; then
        echo -e "${YELLOW}⚠️  Flutter dependencies not installed. Installing...${NC}"
        flutter pub get
        echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
    else
        echo -e "${GREEN}✅ Flutter dependencies already installed${NC}"
    fi
    
    # Check if code generation is needed
    if [ ! -f "lib/features/auth/data/models/user_model.freezed.dart" ] || 
       [ ! -f "lib/features/logging/data/models/parsed_log_model.freezed.dart" ]; then
        echo -e "${YELLOW}⚠️  Generated files missing. Running build_runner...${NC}"
        flutter pub run build_runner build --delete-conflicting-outputs || {
            echo -e "${YELLOW}⚠️  Code generation failed. You may need to run it manually.${NC}"
        }
    fi
fi

cd ..

echo ""

# ============================================
# START SERVICES
# ============================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Starting Services...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Start Backend
echo -e "${BLUE}📦 Starting Django Backend...${NC}"
cd backend
source venv/bin/activate 2>/dev/null || source env/bin/activate
python manage.py runserver > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 2

# Check if backend started successfully
if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✅ Backend running (PID: $BACKEND_PID)${NC}"
    echo -e "${GREEN}   → http://localhost:8000${NC}"
    echo -e "${GREEN}   → Admin: http://localhost:8000/admin${NC}"
    echo -e "${GREEN}   → API: http://localhost:8000/api/${NC}"
else
    echo -e "${RED}❌ Backend failed to start. Check backend.log for details.${NC}"
fi

echo ""

# Start Mobile App
if [ "$MOBILE_AVAILABLE" = true ]; then
    echo -e "${BLUE}📱 Starting Flutter Mobile App...${NC}"
    cd mobile
    
    # Detect available devices
    DEVICE=$(flutter devices --machine | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    
    if [ -z "$DEVICE" ]; then
        echo -e "${YELLOW}⚠️  No Flutter devices found.${NC}"
        echo -e "${YELLOW}   Please start an emulator/simulator or connect a device.${NC}"
        echo -e "${YELLOW}   You can run manually: cd mobile && flutter run${NC}"
    else
        echo -e "${GREEN}✅ Starting on device: $DEVICE${NC}"
        flutter run -d "$DEVICE" > ../mobile.log 2>&1 &
        MOBILE_PID=$!
        echo -e "${GREEN}✅ Mobile app starting (PID: $MOBILE_PID)${NC}"
    fi
    
    cd ..
else
    echo -e "${YELLOW}⚠️  Mobile app not started (Flutter not available)${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ All services started!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 Logs:${NC}"
echo -e "   Backend: tail -f backend.log"
echo -e "   Mobile:  tail -f mobile.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Wait for user interrupt
wait

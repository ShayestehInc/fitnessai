#!/bin/bash

# Flutter Mobile App Setup Script
# Generates code and sets up the project

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Fitness AI Mobile App...${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Installing dependencies...${NC}"
flutter pub get

echo -e "${GREEN}🔨 Generating code (Freezed, JSON serialization)...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "   1. Update API base URL in lib/core/constants/api_constants.dart"
echo "   2. Run: flutter run -d ios (or android)"

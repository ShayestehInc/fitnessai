#!/bin/bash

# Configure Xcode for Flutter development
# This script requires your password for sudo

echo "🔧 Configuring Xcode for Flutter development..."
echo ""

# Switch to full Xcode installation
echo "Switching to Xcode.app..."
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

if [ $? -eq 0 ]; then
    echo "✅ Successfully switched to Xcode.app"
else
    echo "❌ Failed to switch to Xcode.app"
    exit 1
fi

echo ""

# Run first launch
echo "Running Xcode first launch setup..."
sudo xcodebuild -runFirstLaunch

if [ $? -eq 0 ]; then
    echo "✅ Xcode first launch completed"
else
    echo "⚠️  First launch may have had issues, but continuing..."
fi

echo ""
echo "✅ Xcode configuration complete!"
echo ""
echo "You can now:"
echo "  1. Build and run in Xcode (open ios/Runner.xcworkspace)"
echo "  2. Or run from terminal: flutter run -d ios"

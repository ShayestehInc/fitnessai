#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# 1. Bump build number in pubspec.yaml
current_build=$(grep 'version:' pubspec.yaml | sed 's/.*+//')
new_build=$((current_build + 1))
sed -i '' "s/version: \(.*\)+${current_build}/version: \1+${new_build}/" pubspec.yaml
echo "Build number: $current_build -> $new_build"

# 2. Flutter build
echo "Running flutter pub get..."
flutter pub get

echo "Building iOS release..."
flutter build ios --release --no-codesign

# 3. Pod install
echo "Running pod install..."
cd ios
pod install

# 4. Fastlane archive + upload
echo "Archiving and uploading to TestFlight..."
fastlane beta

echo "Done! Build $new_build uploaded to TestFlight."

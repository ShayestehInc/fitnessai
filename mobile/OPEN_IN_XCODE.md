# Opening Flutter Project in Xcode

## Prerequisites

1. **Install Flutter** (if not already installed):
   ```bash
   # Download from: https://flutter.dev/docs/get-started/install/macos
   # Or use Homebrew:
   brew install --cask flutter
   
   # Verify installation:
   flutter doctor
   ```

2. **Install Xcode** (from App Store if not installed)

3. **Install CocoaPods** (for iOS dependencies):
   ```bash
   sudo gem install cocoapods
   ```

## Setup Steps

### Step 1: Generate iOS Project Structure

Since the Flutter project was created manually, we need to generate the iOS project:

```bash
cd mobile

# Generate iOS project (this will create the Xcode workspace)
flutter create --platforms=ios .
```

**Note**: This command will:
- Generate the full iOS project structure
- Create `ios/Runner.xcworkspace`
- Set up CocoaPods
- Generate necessary Xcode project files

### Step 2: Install Dependencies

```bash
cd mobile
flutter pub get

# Install iOS dependencies (CocoaPods)
cd ios
pod install
cd ..
```

### Step 3: Open in Xcode

```bash
cd mobile
open ios/Runner.xcworkspace
```

**Important**: Always open `Runner.xcworkspace` (not `Runner.xcodeproj`) because Flutter uses CocoaPods.

## Alternative: Create Fresh Flutter Project

If you prefer to start fresh:

```bash
# Create new Flutter project
flutter create fitnessai_mobile

# Copy your lib/ folder and pubspec.yaml
# Then open:
cd fitnessai_mobile
open ios/Runner.xcworkspace
```

## Troubleshooting

### "Flutter command not found"
- Add Flutter to your PATH:
  ```bash
  export PATH="$PATH:$HOME/flutter/bin"
  # Add to ~/.zshrc or ~/.bash_profile for permanent
  ```

### "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd mobile/ios
pod install
```

### "No such module 'Flutter'"
- Run `flutter pub get` first
- Then `cd ios && pod install`

## Quick Setup Script

Run this from the project root:

```bash
# Install Flutter (if needed)
# brew install --cask flutter

# Setup iOS project
cd mobile
flutter create --platforms=ios .
flutter pub get
cd ios && pod install && cd ..

# Open in Xcode
open ios/Runner.xcworkspace
```

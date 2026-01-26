# TestFlight Deployment Guide

This guide will walk you through deploying your Fitness AI app to TestFlight.

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Sign up at https://developer.apple.com
   - Enroll in the Apple Developer Program

2. **App Store Connect Access**
   - Access at https://appstoreconnect.apple.com
   - You'll need to create an app record here

3. **Xcode** (latest version recommended)
   - Install from Mac App Store
   - Install additional components when prompted

4. **Flutter Setup**
   - Ensure Flutter is properly installed and configured
   - Run `flutter doctor` to verify iOS setup

## Step 1: Update Bundle Identifier

Your current bundle identifier is `com.example.fitnessai`. You need to change it to a unique identifier (reverse domain notation).

**Option A: Using Xcode (Recommended)**
1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" project in the left sidebar
3. Select the "Runner" target
4. Go to the "Signing & Capabilities" tab
5. Change "Bundle Identifier" from `com.example.fitnessai` to something like:
   - `com.yourcompany.fitnessai`
   - `com.yourname.fitnessai`
   - `io.shayestehinc.fitnessai` (if you own shayestehinc.com)

**Option B: Manual Edit**
The bundle identifier is set in `mobile/ios/Runner.xcodeproj/project.pbxproj` at line 618 and 640.

## Step 2: Create App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: Fitness AI (or your preferred name)
   - **Primary Language**: English (or your choice)
   - **Bundle ID**: Select the one you created in Step 1 (or create new)
   - **SKU**: A unique identifier (e.g., `fitnessai-001`)
   - **User Access**: Full Access (or Limited if you have a team)
4. Click "Create"

## Step 3: Configure Signing in Xcode

1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" project → "Runner" target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your Team (your Apple Developer account)
6. Xcode will automatically create/select the correct Provisioning Profile

**Note**: If you see signing errors, you may need to:
- Create an App ID in the Apple Developer Portal first
- Ensure your Apple Developer account is properly configured

## Step 4: Update Version and Build Number

Your current version in `pubspec.yaml` is `1.0.0+1`. For TestFlight:
- Version (1.0.0): This is the user-facing version
- Build number (+1): This must increment for each TestFlight upload

Update in `mobile/pubspec.yaml`:
```yaml
version: 1.0.0+1  # Increment the build number (+1) for each upload
```

## Step 5: Build for Release

### Option A: Using Xcode (Recommended for first time)

1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" or "Generic iOS Device" from the device dropdown (top left)
3. Go to **Product** → **Archive**
4. Wait for the build to complete
5. The Organizer window will open automatically

### Option B: Using Flutter Command Line

```bash
cd mobile
flutter build ipa --release
```

This creates an `.ipa` file in `mobile/build/ios/ipa/`

## Step 6: Upload to App Store Connect

### Using Xcode Organizer (Easiest)

1. After archiving (Step 5, Option A), the Organizer window should be open
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Click "Next"
6. Choose "Upload"
7. Click "Next"
8. Review the app information
9. Click "Upload"
10. Wait for the upload to complete (this can take 10-30 minutes)

### Using Transporter App (Alternative)

1. Download "Transporter" from the Mac App Store
2. Open the `.ipa` file from `mobile/build/ios/ipa/` in Transporter
3. Click "Deliver"
4. Wait for upload to complete

### Using Command Line (Advanced)

```bash
cd mobile
flutter build ipa --release
xcrun altool --upload-app --type ios --file build/ios/ipa/fitnessai.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

## Step 7: Process Build in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Select your app
3. Go to "TestFlight" tab
4. Wait for processing (usually 10-30 minutes)
5. You'll see a notification when processing is complete

## Step 8: Configure TestFlight

1. In App Store Connect, go to the "TestFlight" tab
2. Select your build
3. Add test information:
   - **What to Test**: Describe what testers should focus on
   - **Marketing URL** (optional): Your website
   - **Privacy Policy URL** (required for external testing): Your privacy policy URL

## Step 9: Add Testers

### Internal Testing (Up to 100 testers, immediate access)

1. Go to "Internal Testing" section
2. Click "+" to create a group (e.g., "Internal Team")
3. Add testers by email (must be added to your App Store Connect team first)
4. Select your build
5. Click "Start Testing"

### External Testing (Up to 10,000 testers, requires App Review)

1. Go to "External Testing" section
2. Click "+" to create a group
3. Add testers by email (they'll receive an invite)
4. Select your build
5. Fill in required information:
   - Export Compliance
   - Advertising Identifier (if applicable)
   - Content Rights
6. Submit for Beta App Review (can take 24-48 hours)

## Step 10: Testers Install TestFlight

1. Testers receive an email invitation
2. They install "TestFlight" from the App Store (if not already installed)
3. They open the invitation email on their iOS device
4. They tap "Start Testing" or "View in TestFlight"
5. The app installs automatically

## Troubleshooting

### Common Issues

1. **Signing Errors**
   - Ensure your Apple Developer account is active
   - Check that the bundle identifier matches in Xcode and App Store Connect
   - Try cleaning: `flutter clean` then rebuild

2. **Upload Fails**
   - Check your internet connection
   - Ensure you're using the latest Xcode
   - Verify your Apple Developer account status

3. **Build Processing Fails**
   - Check email notifications from App Store Connect
   - Review the build details for specific errors
   - Common issues: missing icons, invalid entitlements, missing privacy descriptions

4. **TestFlight Build Not Appearing**
   - Wait up to 30 minutes for processing
   - Check that the build number is higher than previous builds
   - Verify the build was uploaded successfully

### HealthKit Considerations

Your app uses HealthKit. Make sure:
- HealthKit capability is enabled in Xcode (Signing & Capabilities)
- Privacy descriptions are in Info.plist (already present)
- You've completed the HealthKit entitlement in App Store Connect if required

## Quick Reference Commands

```bash
# Clean build
cd mobile
flutter clean

# Get dependencies
flutter pub get

# Build for release
flutter build ipa --release

# Check Flutter setup
flutter doctor

# Update version (in pubspec.yaml)
# version: 1.0.0+2  # Increment build number
```

## Next Steps After TestFlight

Once your app is tested and ready:
1. Prepare App Store listing (screenshots, description, etc.)
2. Submit for App Store Review
3. Set pricing and availability
4. Release to the App Store

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

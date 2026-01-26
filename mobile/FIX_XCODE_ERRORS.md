# Fixing Xcode CocoaPods Errors

## The Error
"Unable to load contents of file list: '/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Debug-...'"

## Solution Steps

### 1. Close Xcode
Close the Xcode workspace completely.

### 2. Clean Everything (Already Done)
```bash
cd mobile/ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter clean
flutter pub get
```

### 3. Reinstall Pods
```bash
cd mobile/ios
pod install
```

### 4. Generate Flutter Files
```bash
cd mobile
flutter build ios --no-codesign --debug
```

### 5. Reopen Xcode
```bash
open ios/Runner.xcworkspace
```

### 6. In Xcode - Clean Build Folder
- Press `Cmd+Shift+K` (Product → Clean Build Folder)
- Or: Product → Clean Build Folder from menu

### 7. In Xcode - Reset Package Caches (if needed)
- File → Packages → Reset Package Caches

### 8. Build Again
- Press `Cmd+B` to build
- Or click the Run button (▶️)

## Alternative: Fix in Xcode Project Settings

If errors persist:

1. **Select the Runner project** in the Project Navigator (left sidebar)
2. **Select the Runner target**
3. **Go to Build Settings tab**
4. **Search for "Framework Search Paths"**
5. **Make sure it includes**: `$(inherited)` and `"${PODS_CONFIGURATION_BUILD_DIR}"`

6. **Search for "Other Linker Flags"**
7. **Make sure it includes**: `$(inherited)` and `-framework "Flutter"`

## If Still Not Working

Try building from terminal first to generate all necessary files:

```bash
cd mobile
export PATH="$PATH:/opt/homebrew/bin"
flutter build ios --no-codesign
```

Then reopen Xcode and try building again.

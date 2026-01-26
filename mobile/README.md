# Fitness AI Mobile App

Flutter mobile application for the Fitness AI platform.

## Features

- ✅ **AI Command Center**: Natural language logging with optimistic UI
- ✅ **Authentication**: Login/Register with JWT tokens
- ✅ **Dashboard**: Trainee overview with stats
- ✅ **Health Integration**: HealthKit/Health Connect sync (configured)
- ✅ **Offline-First**: Ready for Drift database integration
- ✅ **Shadcn UI**: Dark mode theme matching Shadcn aesthetic

## Setup

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart 3.0.0 or higher
- iOS: Xcode 14+ (for iOS development)
- Android: Android Studio with Android SDK (for Android development)

### Installation

1. **Install dependencies**:
```bash
cd mobile
flutter pub get
```

2. **Generate code** (Freezed, JSON serialization):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Update API base URL**:
   - Edit `lib/core/constants/api_constants.dart`
   - Change `baseUrl` to your Django backend URL (default: `http://localhost:8000`)

### Running the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web (for testing)
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/          # Shadcn Zinc Dark Mode theme
│   ├── api/            # Dio client with interceptors
│   ├── router/         # GoRouter configuration
│   ├── services/       # HealthService
│   └── constants/      # API constants
├── features/
│   ├── auth/           # Authentication
│   │   ├── data/       # Models, Repositories
│   │   └── presentation/  # Screens, Providers
│   ├── dashboard/      # Trainee dashboard
│   └── logging/        # AI Command Center (Killer Feature)
│       ├── data/       # Models, Repositories
│       └── presentation/  # Screens, Widgets, Providers
└── shared/
    └── widgets/        # Reusable components
```

## Key Features

### AI Command Center

The "Killer Feature" - A floating action button that opens a chat interface for natural language logging.

**Flow**:
1. User types: "Ate 3 eggs and did 5x5 squats at 225"
2. **Optimistic UI**: App immediately shows "Processing..." bubble
3. Backend parses text → Returns JSON actions
4. **Confirmation**: App displays a "Draft Log" card with parsed data
5. User taps "Confirm" to save to DB

### Architecture

- **State Management**: Riverpod 2.0 with AutoDispose providers
- **Navigation**: GoRouter for type-safe routing
- **API**: Repository pattern (UI → Provider → Repository → API Client)
- **UI**: Shadcn UI components with Material wrapper

## Health Integration

### iOS (HealthKit)
- Permissions configured in `ios/Runner/Info.plist`
- `NSHealthShareUsageDescription`: "We need your activity data to calculate recovery scores."
- `NSHealthUpdateUsageDescription`: "We sync your workouts to your health ring."

### Android (Health Connect)
- Permissions configured in `android/app/src/main/AndroidManifest.xml`
- MainActivity extends `FlutterFragmentActivity` (required for Health Connect)
- Activity recognition permission included

## Offline-First (Future)

Drift database setup is ready. To implement:
1. Create Drift database schema in `core/database/`
2. Implement sync queue in `core/services/sync_service.dart`
3. Update repositories to use local DB first, then sync

## Development

### Code Generation

After modifying Freezed models or JSON serializable classes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting

```bash
flutter analyze
```

### Testing

```bash
flutter test
```

## Backend Integration

The app connects to the Django REST API. Ensure:
1. Django server is running (see `../run_localhost.sh`)
2. CORS is configured for your mobile app's origin
3. API base URL matches in `api_constants.dart`

## Next Steps

- [ ] Implement Drift database for offline-first
- [ ] Add program viewing feature
- [ ] Implement health data sync
- [ ] Add trainer dashboard features
- [ ] Implement push notifications
- [ ] Add biometric authentication

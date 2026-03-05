# Apple Watch Companion App — Architecture Plan

## Overview

Native SwiftUI WatchOS app that syncs with the Flutter iOS app via `WatchConnectivity`.
The watch receives the current workout plan from the phone and allows trainees to
log sets directly from their wrist during active workouts.

---

## Communication Flow

```
Flutter App (Phone)
  └─ watch_connectivity plugin (Dart)
       └─ WCSession (Swift, iOS side)
            ↕ WatchConnectivity framework
       └─ WCSession (Swift, watchOS side)
            └─ SwiftUI WatchOS App
```

### Data sent Phone → Watch
- Current day's workout plan (exercises, sets, reps, weight, rest timers)
- Active program metadata (name, day number)
- User preferences (weight unit, theme accent color)

### Data sent Watch → Phone
- Set completions (exercise ID, set index, actual reps, actual weight, timestamp)
- Workout start/end events
- Rest timer completions

---

## WatchOS App Structure

```
WatchApp/
├── FitnessAIWatch.swift              # @main App entry point
├── Models/
│   ├── WatchWorkoutPlan.swift         # Codable model for received workout
│   ├── WatchSetCompletion.swift       # Codable model for completed sets
│   └── WatchExercise.swift            # Individual exercise with sets
├── Views/
│   ├── WorkoutListView.swift          # List of today's exercises
│   ├── ExerciseDetailView.swift       # Single exercise with set checkboxes
│   ├── SetRowView.swift               # One set row (reps × weight + checkbox)
│   ├── RestTimerView.swift            # Countdown timer between sets
│   ├── WorkoutSummaryView.swift       # Post-workout summary
│   └── NoWorkoutView.swift            # Empty state when no plan synced
├── ViewModels/
│   ├── WorkoutViewModel.swift         # ObservableObject managing workout state
│   └── ConnectivityViewModel.swift    # WCSession delegate, message handling
├── Services/
│   ├── HapticService.swift            # WKInterfaceDevice haptic feedback
│   └── HealthKitService.swift         # Optional: write workout to HealthKit
└── Assets.xcassets/                   # Watch app icon, accent color
```

---

## Flutter Side Integration

### Plugin: `watch_connectivity` (or custom MethodChannel)

```dart
// mobile/lib/features/watch/
├── data/
│   └── repositories/watch_repository.dart
├── presentation/
│   ├── providers/watch_provider.dart
│   └── screens/watch_sync_screen.dart    # Settings screen for watch pairing status
```

### Key Dart Methods

```dart
class WatchRepository {
  /// Send today's workout plan to the watch
  Future<void> syncWorkoutPlan(WorkoutPlan plan);

  /// Listen for set completion messages from the watch
  Stream<WatchSetCompletion> get setCompletions;

  /// Check if watch is paired and reachable
  Future<bool> get isWatchConnected;
}
```

---

## Data Models (Watch Side)

### WatchWorkoutPlan
```swift
struct WatchWorkoutPlan: Codable {
    let programName: String
    let dayNumber: Int
    let dayName: String
    let exercises: [WatchExercise]
    let weightUnit: String  // "lbs" or "kg"
}
```

### WatchExercise
```swift
struct WatchExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
    let videoUrl: String?
    let groupId: String?      // For supersets
    let groupType: String?    // superset/circuit/drop_set
}
```

### WatchSetCompletion
```swift
struct WatchSetCompletion: Codable {
    let exerciseId: Int
    let setIndex: Int
    let actualReps: Int
    let actualWeight: Double
    let timestamp: Date
    let skipped: Bool
}
```

---

## Watch UX Flow

1. **Launch** → Check `WCSession.isReachable`
   - If reachable: request today's workout from phone
   - If not: show cached last-synced workout or empty state

2. **Workout List** → Scrollable list of exercises
   - Exercise name, target sets × reps @ weight
   - Green checkmark for completed exercises
   - Superset groups visually connected

3. **Exercise Detail** → Tap an exercise
   - List of sets with checkboxes
   - Tap to complete set → haptic confirmation → auto-start rest timer
   - Digital Crown to adjust actual reps/weight if different from plan

4. **Rest Timer** → Full-screen countdown
   - Haptic pulse at 10s, 5s, 0s
   - Skip button
   - Auto-advance to next set/exercise

5. **Workout Summary** → After all sets complete
   - Total sets, total volume, duration
   - "Send to Phone" button → syncs all completions

---

## HealthKit Integration (Optional)

```swift
// Write workout session to HealthKit
let workout = HKWorkout(
    activityType: .traditionalStrengthTraining,
    start: workoutStart,
    end: workoutEnd,
    duration: duration,
    totalEnergyBurned: nil,
    totalDistance: nil,
    metadata: ["programName": plan.programName]
)
healthStore.save(workout)
```

---

## Implementation Phases

### Phase 5a: Scaffold (1-2 days)
- Create WatchOS target in Xcode project
- Set up `WCSession` on both iOS and watchOS sides
- Basic "Hello from watch" ↔ "Hello from phone" message passing

### Phase 5b: Data Sync (2-3 days)
- Implement `WatchWorkoutPlan` serialization
- Send workout plan on app launch + manual refresh
- Cache last plan on watch for offline use
- Flutter `watch_connectivity` plugin integration

### Phase 5c: Workout UI (3-4 days)
- WorkoutListView with exercise cards
- ExerciseDetailView with set completion
- RestTimerView with haptics
- WorkoutSummaryView

### Phase 5d: Bidirectional Sync (2-3 days)
- Send set completions back to phone
- Merge with active workout state on phone
- Handle conflicts (same set completed on both devices)
- HealthKit workout session recording

### Phase 5e: Polish (1-2 days)
- Complications for quick launch
- Watch face shortcuts
- Offline resilience
- Battery optimization

---

## Dependencies

- **watchOS minimum**: 9.0 (SwiftUI lifecycle)
- **Flutter plugin**: `watch_connectivity: ^0.1.0` or custom platform channel
- **No backend changes needed** — all sync happens phone ↔ watch locally

## Xcode Configuration

```
Runner.xcodeproj/
├── Runner (iOS app target)
├── FitnessAIWatch (watchOS app target)
│   ├── Bundle ID: com.shayestehinc.fitnessai.watchkitapp
│   ├── Deployment Target: watchOS 9.0
│   └── Capabilities: HealthKit, Background Modes
└── FitnessAIWatchTests (watchOS test target)
```

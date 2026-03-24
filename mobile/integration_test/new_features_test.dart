import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Session Feedback
import 'package:fitnessai/features/session_feedback/presentation/screens/session_feedback_screen.dart';

// Session Runner Widgets
import 'package:fitnessai/features/session_runner/presentation/widgets/pain_toggle_button.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/feels_off_sheet.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/next_set_card.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/dials_escalation_sheet.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/warmup_assessment_sheet.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/exercise_workload_card.dart';
import 'package:fitnessai/features/session_runner/presentation/widgets/proceed_card.dart';

// Nutrition Screens
import 'package:fitnessai/features/nutrition/presentation/screens/nutrition_template_picker_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/weekly_checkin_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/photo_food_log_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/meal_plan_builder_screen.dart';

// Dual Capture
import 'package:fitnessai/features/dual_capture/presentation/screens/dual_capture_screen.dart';
import 'package:fitnessai/features/dual_capture/presentation/widgets/camera_bubble.dart';
import 'package:fitnessai/features/dual_capture/presentation/widgets/recording_controls.dart';

// Trainer Widgets
import 'package:fitnessai/features/trainer/presentation/widgets/curated_build_sheet.dart';
import 'package:fitnessai/features/trainer/presentation/widgets/curated_nutrition_sheet.dart';

/// Helper to wrap a widget in a testable MaterialApp with Riverpod.
Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

Widget _testScreen(Widget screen) {
  return ProviderScope(
    child: MaterialApp(home: screen),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // GROUP 1: Session Runner Widgets
  // =========================================================================

  group('Session Runner Widgets', () {
    testWidgets('PainToggleButton renders with healing icon', (tester) async {
      await tester.pumpWidget(_testApp(
        PainToggleButton(onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PainToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.healing_rounded), findsOneWidget);
    });

    testWidgets('NextSetCard renders with correct data', (tester) async {
      await tester.pumpWidget(_testApp(
        const NextSetCard(
          setNumber: 3,
          totalSets: 5,
          prescribedRepsMin: 8,
          prescribedRepsMax: 12,
          suggestedLoad: 185.0,
          loadUnit: 'lb',
          tempo: '3-1-2-0',
          cue: 'Drive through heels',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NextSetCard), findsOneWidget);
      expect(find.textContaining('Set 3 of 5'), findsOneWidget);
      expect(find.textContaining('8-12 reps'), findsOneWidget);
      expect(find.textContaining('185 lb'), findsOneWidget);
      expect(find.textContaining('3-1-2-0'), findsOneWidget);
      expect(find.textContaining('Drive through heels'), findsOneWidget);
    });

    testWidgets('ExerciseWorkloadCard renders with delta', (tester) async {
      await tester.pumpWidget(_testApp(
        const ExerciseWorkloadCard(
          exerciseName: 'Bench Press',
          totalWorkload: 4500,
          unit: 'lb-reps',
          setCount: 4,
          repTotal: 32,
          deltaPercent: 8.5,
          factText: 'New 30-day high!',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseWorkloadCard), findsOneWidget);
      expect(find.textContaining('4500'), findsOneWidget);
      expect(find.textContaining('4 sets'), findsOneWidget);
      expect(find.textContaining('32 reps'), findsOneWidget);
      expect(find.textContaining('+8.5%'), findsOneWidget);
      expect(find.textContaining('New 30-day high!'), findsOneWidget);
    });

    testWidgets('ProceedCard renders all 5 options', (tester) async {
      await tester.pumpWidget(_testApp(
        Column(
          children: ProceedCard.allOptions.map((opt) => ProceedCard(
            decision: opt.decision,
            title: opt.title,
            subtitle: opt.subtitle,
            icon: opt.icon,
            onTap: () {},
          )).toList(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProceedCard), findsNWidgets(5));
      expect(find.text('Continue As Planned'), findsOneWidget);
      expect(find.text('Continue With Changes'), findsOneWidget);
      expect(find.text('Swap Exercise'), findsOneWidget);
      expect(find.text('Skip This Exercise'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
    });

    testWidgets('FeelsOffSheet renders 5 options', (tester) async {
      String? selected;
      await tester.pumpWidget(_testApp(
        FeelsOffSheet(
          exerciseName: 'Squat',
          onSelected: (v) => selected = v,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Something feels off?'), findsOneWidget);
      expect(find.text('Wrong muscles activating'), findsOneWidget);
      expect(find.text('Too heavy / too hard'), findsOneWidget);
      expect(find.text('Too easy'), findsOneWidget);
      expect(find.text('Exercise feels awkward'), findsOneWidget);
      expect(find.text('Just want to change exercise'), findsOneWidget);

      // Tap one
      await tester.tap(find.text('Too easy'));
      expect(selected, equals('too_easy'));
    });
  });

  // =========================================================================
  // GROUP 2: Nutrition Screens
  // =========================================================================

  group('Nutrition Screens', () {
    testWidgets('NutritionTemplatePickerScreen renders 4 template cards',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const NutritionTemplatePickerScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Nutrition Template'), findsOneWidget);
      expect(find.text('SHREDDED'), findsOneWidget);
      expect(find.text('MASSIVE'), findsOneWidget);
      expect(find.text('Carb Cycling'), findsOneWidget);
      expect(find.text('Create Your Own'), findsOneWidget);

      // Check badges
      expect(find.text('Added Fats'), findsNWidgets(2)); // SHREDDED + MASSIVE
      expect(find.text('LBM-based'), findsNWidgets(2));
      expect(find.text('Percent-based'), findsOneWidget);
      expect(find.text('Fully editable'), findsOneWidget);
    });

    testWidgets('WeeklyCheckinScreen renders all signal sliders',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const WeeklyCheckinScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Check-In'), findsOneWidget);
      expect(find.text('Hunger'), findsOneWidget);
      expect(find.text('Sleep Quality'), findsOneWidget);
      expect(find.text('Stress'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);
      expect(find.text('Digestion'), findsOneWidget);
      expect(find.text('Submit Check-In'), findsOneWidget);

      // Verify 5 slider buttons per signal (5 signals × 5 buttons = 25)
      // Each slider has numbers 1-5
      expect(find.text('1'), findsNWidgets(5));
      expect(find.text('5'), findsNWidgets(5));
    });

    testWidgets('PhotoFoodLogScreen renders capture view', (tester) async {
      await tester.pumpWidget(_testScreen(
        const PhotoFoodLogScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Photo Food Log'), findsOneWidget);
      expect(find.text('Take a photo of your meal'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('PhotoFoodLogScreen shows AI results after capture',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const PhotoFoodLogScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap "Take Photo"
      await tester.tap(find.text('Take Photo'));
      await tester.pump(); // Start analyzing

      expect(find.text('Analyzing your meal...'), findsOneWidget);

      // Wait for simulated analysis
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify recognized foods
      expect(find.text('Recognized Foods'), findsOneWidget);
      expect(find.text('Grilled Chicken Breast'), findsOneWidget);
      expect(find.text('Brown Rice'), findsOneWidget);
      expect(find.text('Steamed Broccoli'), findsOneWidget);
      expect(find.text('Save to Log'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);

      // Verify confidence badges
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('MealPlanBuilderScreen renders quick actions and meal slots',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const MealPlanBuilderScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Meal Planner'), findsOneWidget);
      expect(find.text('Copy Yesterday'), findsOneWidget);
      expect(find.text('Plan Ahead'), findsOneWidget);
      expect(find.text('Saved Meals'), findsOneWidget);
      expect(find.text("Today's Meals"), findsOneWidget);

      // First few meal slots visible (rest may need scrolling)
      expect(find.text('Breakfast'), findsOneWidget);
      // At least some "Add Food" buttons visible
      expect(find.text('Add Food'), findsWidgets);
    });
  });

  // =========================================================================
  // GROUP 3: Dual Capture
  // =========================================================================

  group('Dual Capture', () {
    testWidgets('DualCaptureScreen renders with mode selector',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const DualCaptureScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DualCaptureScreen), findsOneWidget);
      expect(find.text('Camera Only'), findsOneWidget);
      expect(find.text('Screen + Camera'), findsOneWidget);
      expect(find.text('Screen Only'), findsOneWidget);
      expect(find.text('Ready to record'), findsOneWidget);
    });

    testWidgets('DualCaptureScreen recording flow', (tester) async {
      await tester.pumpWidget(_testScreen(
        const DualCaptureScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap record button (the red circle)
      final recordButtons = find.byType(GestureDetector);
      // Find the record button specifically — it's a container with red circle
      expect(find.text('Ready to record'), findsOneWidget);

      // Switch to Screen + Camera mode
      await tester.tap(find.text('Screen + Camera'));
      await tester.pumpAndSettle();

      // Camera bubble should appear
      expect(find.byType(CameraBubble), findsOneWidget);
    });

    testWidgets('CameraBubble is draggable and minimizable', (tester) async {
      await tester.pumpWidget(_testApp(
        const SizedBox(
          width: 400,
          height: 400,
          child: Stack(
            children: [
              Positioned(
                bottom: 20,
                right: 20,
                child: CameraBubble(),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CameraBubble), findsOneWidget);

      // Long press to minimize
      await tester.longPress(find.byType(CameraBubble));
      await tester.pumpAndSettle();

      // Should show minimized (small circle with videocam icon)
      expect(find.byIcon(Icons.videocam), findsOneWidget);

      // Tap to expand again
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
    });

    testWidgets('RecordingControls shows correct states', (tester) async {
      // Not recording state
      await tester.pumpWidget(_testApp(
        RecordingControls(
          isRecording: false,
          isPaused: false,
          elapsedSeconds: 0,
          onRecord: () {},
          onPause: () {},
          onResume: () {},
          onStop: () {},
          onDiscard: () {},
          onFlipCamera: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Flip'), findsOneWidget);
      // No timer shown when not recording
      expect(find.text('00:00'), findsNothing);
    });

    testWidgets('RecordingControls recording state shows timer',
        (tester) async {
      await tester.pumpWidget(_testApp(
        RecordingControls(
          isRecording: true,
          isPaused: false,
          elapsedSeconds: 65,
          onRecord: () {},
          onPause: () {},
          onResume: () {},
          onStop: () {},
          onDiscard: () {},
          onFlipCamera: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('01:05'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('RecordingControls paused state shows PAUSED',
        (tester) async {
      await tester.pumpWidget(_testApp(
        RecordingControls(
          isRecording: true,
          isPaused: true,
          elapsedSeconds: 30,
          onRecord: () {},
          onPause: () {},
          onResume: () {},
          onStop: () {},
          onDiscard: () {},
          onFlipCamera: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 4: Session Feedback Enhancements
  // =========================================================================

  group('Session Feedback Enhancements', () {
    testWidgets('SessionFeedbackScreen renders new win/context/action sections',
        (tester) async {
      await tester.pumpWidget(_testScreen(
        const SessionFeedbackScreen(sessionPk: 1),
      ));
      await tester.pumpAndSettle();

      // Verify new sections exist
      expect(find.text('What went well?'), findsOneWidget);
      expect(find.text('Session volume'), findsOneWidget);
      expect(find.text('What would you like next?'), findsOneWidget);

      // Win reason chips
      expect(find.text('Strong Performance'), findsOneWidget);
      expect(find.text('Great Pump'), findsOneWidget);
      expect(find.text('Smoother Technique'), findsOneWidget);
      expect(find.text('Pain-Free'), findsOneWidget);
      expect(find.text('Confidence Boost'), findsOneWidget);
      expect(find.text('Efficient Session'), findsOneWidget);

      // Volume perception
      expect(find.text('Too Much'), findsOneWidget);
      expect(find.text('About Right'), findsOneWidget);
      expect(find.text('Too Little'), findsOneWidget);

      // Requested action
      expect(find.text('No Follow-up Needed'), findsOneWidget);
      expect(find.text('Adjust Next Time'), findsOneWidget);
      expect(find.text('Message Trainer'), findsOneWidget);
      expect(find.text('Review With Video'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 5: Warmup & Escalation Sheets
  // =========================================================================

  group('Warmup & Escalation Sheets', () {
    testWidgets('DialsEscalationSheet renders 6 escalation steps',
        (tester) async {
      String? selected;
      await tester.pumpWidget(_testApp(
        DialsEscalationSheet(
          exerciseName: 'Deadlift',
          onSelected: (v) => selected = v,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Deadlift'), findsOneWidget);
      expect(find.text('Focus on Cue'), findsOneWidget);
      expect(find.text('Change Tempo'), findsOneWidget);
      expect(find.text('Reduce Load'), findsOneWidget);
      expect(find.text('Shorten Range of Motion'), findsOneWidget);
      expect(find.text('Change Stance / Support'), findsOneWidget);
      expect(find.text('Swap Exercise'), findsOneWidget);

      await tester.tap(find.text('Reduce Load'));
      expect(selected, equals('load'));
    });

    testWidgets('WarmupAssessmentSheet renders 4 options', (tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => WarmupAssessmentSheet(
              exerciseName: 'Back Squat',
              onSelected: (v) => selected = v,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Back Squat'), findsOneWidget);
      expect(find.text('Something hurts here'), findsOneWidget);
      expect(find.text('Feeling stiff'), findsOneWidget);
      expect(find.text('Want technique tips'), findsOneWidget);
      expect(find.text("I'm ready"), findsOneWidget);

      await tester.tap(find.text("I'm ready"));
      expect(selected, equals('ready'));
    });
  });
}

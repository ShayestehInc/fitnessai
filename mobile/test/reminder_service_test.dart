import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitnessai/core/services/reminder_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ReminderSettings data class tests
  // ---------------------------------------------------------------------------

  group('ReminderSettings', () {
    test('default constructor has correct defaults', () {
      const settings = ReminderSettings();
      expect(settings.workoutEnabled, isFalse);
      expect(settings.workoutHour, 8);
      expect(settings.workoutMinute, 0);
      expect(settings.mealEnabled, isFalse);
      expect(settings.mealHour, 12);
      expect(settings.mealMinute, 0);
      expect(settings.weightEnabled, isFalse);
      expect(settings.weightDay, 0); // Monday
      expect(settings.weightHour, 7);
      expect(settings.weightMinute, 0);
    });

    test('copyWith updates specified fields only', () {
      const original = ReminderSettings();
      final updated = original.copyWith(
        workoutEnabled: true,
        workoutHour: 9,
        mealEnabled: true,
      );

      // Updated fields
      expect(updated.workoutEnabled, isTrue);
      expect(updated.workoutHour, 9);
      expect(updated.mealEnabled, isTrue);

      // Unchanged fields
      expect(updated.workoutMinute, 0);
      expect(updated.mealHour, 12);
      expect(updated.mealMinute, 0);
      expect(updated.weightEnabled, isFalse);
      expect(updated.weightDay, 0);
      expect(updated.weightHour, 7);
      expect(updated.weightMinute, 0);
    });

    test('copyWith with no arguments returns equivalent settings', () {
      const original = ReminderSettings(
        workoutEnabled: true,
        workoutHour: 6,
        workoutMinute: 30,
        mealEnabled: true,
        mealHour: 11,
        mealMinute: 45,
        weightEnabled: true,
        weightDay: 4,
        weightHour: 8,
        weightMinute: 15,
      );
      final copy = original.copyWith();

      expect(copy.workoutEnabled, original.workoutEnabled);
      expect(copy.workoutHour, original.workoutHour);
      expect(copy.workoutMinute, original.workoutMinute);
      expect(copy.mealEnabled, original.mealEnabled);
      expect(copy.mealHour, original.mealHour);
      expect(copy.mealMinute, original.mealMinute);
      expect(copy.weightEnabled, original.weightEnabled);
      expect(copy.weightDay, original.weightDay);
      expect(copy.weightHour, original.weightHour);
      expect(copy.weightMinute, original.weightMinute);
    });

    test('copyWith weight day Sunday (6)', () {
      const settings = ReminderSettings();
      final updated = settings.copyWith(weightDay: 6);
      expect(updated.weightDay, 6);
    });

    test('all fields can be set via constructor', () {
      const settings = ReminderSettings(
        workoutEnabled: true,
        workoutHour: 5,
        workoutMinute: 15,
        mealEnabled: true,
        mealHour: 13,
        mealMinute: 30,
        weightEnabled: true,
        weightDay: 3,
        weightHour: 6,
        weightMinute: 45,
      );

      expect(settings.workoutEnabled, isTrue);
      expect(settings.workoutHour, 5);
      expect(settings.workoutMinute, 15);
      expect(settings.mealEnabled, isTrue);
      expect(settings.mealHour, 13);
      expect(settings.mealMinute, 30);
      expect(settings.weightEnabled, isTrue);
      expect(settings.weightDay, 3);
      expect(settings.weightHour, 6);
      expect(settings.weightMinute, 45);
    });
  });

  // ---------------------------------------------------------------------------
  // SharedPreferences persistence tests
  // ---------------------------------------------------------------------------

  group('ReminderService loadSettings', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loadSettings returns defaults when no saved data', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await ReminderService.instance.loadSettings();
      expect(settings.workoutEnabled, isFalse);
      expect(settings.workoutHour, 8);
      expect(settings.workoutMinute, 0);
      expect(settings.mealEnabled, isFalse);
      expect(settings.mealHour, 12);
      expect(settings.mealMinute, 0);
      expect(settings.weightEnabled, isFalse);
      expect(settings.weightDay, 0);
      expect(settings.weightHour, 7);
      expect(settings.weightMinute, 0);
    });

    test('loadSettings returns saved values', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_workout_enabled': true,
        'reminder_workout_hour': 6,
        'reminder_workout_minute': 30,
        'reminder_meal_enabled': true,
        'reminder_meal_hour': 11,
        'reminder_meal_minute': 15,
        'reminder_weight_enabled': true,
        'reminder_weight_day': 4,
        'reminder_weight_hour': 9,
        'reminder_weight_minute': 45,
      });

      final settings = await ReminderService.instance.loadSettings();
      expect(settings.workoutEnabled, isTrue);
      expect(settings.workoutHour, 6);
      expect(settings.workoutMinute, 30);
      expect(settings.mealEnabled, isTrue);
      expect(settings.mealHour, 11);
      expect(settings.mealMinute, 15);
      expect(settings.weightEnabled, isTrue);
      expect(settings.weightDay, 4);
      expect(settings.weightHour, 9);
      expect(settings.weightMinute, 45);
    });

    test('loadSettings handles partial data gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_workout_enabled': true,
        // Missing other fields - should fall back to defaults
      });

      final settings = await ReminderService.instance.loadSettings();
      expect(settings.workoutEnabled, isTrue);
      expect(settings.workoutHour, 8); // default
      expect(settings.mealEnabled, isFalse); // default
    });
  });

  // ---------------------------------------------------------------------------
  // Notification ID constants test
  // ---------------------------------------------------------------------------

  group('ReminderService constants', () {
    test('ReminderService is a singleton', () {
      final a = ReminderService.instance;
      final b = ReminderService.instance;
      expect(identical(a, b), isTrue);
    });
  });
}

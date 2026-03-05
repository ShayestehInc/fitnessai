import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Immutable settings for all reminder types.
class ReminderSettings {
  final bool workoutEnabled;
  final int workoutHour;
  final int workoutMinute;
  final bool mealEnabled;
  final int mealHour;
  final int mealMinute;
  final bool weightEnabled;
  final int weightDay; // 0=Monday..6=Sunday
  final int weightHour;
  final int weightMinute;

  const ReminderSettings({
    this.workoutEnabled = false,
    this.workoutHour = 8,
    this.workoutMinute = 0,
    this.mealEnabled = false,
    this.mealHour = 12,
    this.mealMinute = 0,
    this.weightEnabled = false,
    this.weightDay = 0,
    this.weightHour = 7,
    this.weightMinute = 0,
  });

  ReminderSettings copyWith({
    bool? workoutEnabled,
    int? workoutHour,
    int? workoutMinute,
    bool? mealEnabled,
    int? mealHour,
    int? mealMinute,
    bool? weightEnabled,
    int? weightDay,
    int? weightHour,
    int? weightMinute,
  }) {
    return ReminderSettings(
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      mealEnabled: mealEnabled ?? this.mealEnabled,
      mealHour: mealHour ?? this.mealHour,
      mealMinute: mealMinute ?? this.mealMinute,
      weightEnabled: weightEnabled ?? this.weightEnabled,
      weightDay: weightDay ?? this.weightDay,
      weightHour: weightHour ?? this.weightHour,
      weightMinute: weightMinute ?? this.weightMinute,
    );
  }
}

/// Manages local notification scheduling for workout, meal, and weight
/// check-in reminders.
///
/// Usage:
/// ```dart
/// await ReminderService.instance.initialize();
/// final settings = await ReminderService.instance.loadSettings();
/// await ReminderService.instance.saveAndSchedule(settings.copyWith(workoutEnabled: true));
/// ```
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // -- Notification IDs --
  static const int _workoutNotificationId = 1;
  static const int _mealNotificationId = 2;
  static const int _weightNotificationId = 3;

  // -- SharedPreferences keys --
  static const String _keyWorkoutEnabled = 'reminder_workout_enabled';
  static const String _keyWorkoutHour = 'reminder_workout_hour';
  static const String _keyWorkoutMinute = 'reminder_workout_minute';
  static const String _keyMealEnabled = 'reminder_meal_enabled';
  static const String _keyMealHour = 'reminder_meal_hour';
  static const String _keyMealMinute = 'reminder_meal_minute';
  static const String _keyWeightEnabled = 'reminder_weight_enabled';
  static const String _keyWeightDay = 'reminder_weight_day';
  static const String _keyWeightHour = 'reminder_weight_hour';
  static const String _keyWeightMinute = 'reminder_weight_minute';

  // -- Channel --
  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription =
      'Workout, meal, and weight check-in reminders';

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Callback invoked when a user taps on a notification.
  ///
  /// Subclasses or callers can override [onNotificationTapped] to handle
  /// navigation based on the payload.
  void Function(String? payload)? onNotificationTapped;

  /// Initializes the notification plugin and timezone database.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneName = await _resolveLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final callback = onNotificationTapped;
    if (callback != null) {
      callback(response.payload);
    }
  }

  /// Requests notification permission on iOS.
  ///
  /// Returns `true` if permission was granted.
  /// On Android this is a no-op and always returns `true`.
  Future<bool> requestIOSPermission() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin == null) return false;

    final granted = await iosPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return granted ?? false;
  }

  // ---------------------------------------------------------------------------
  // Settings persistence
  // ---------------------------------------------------------------------------

  /// Loads persisted [ReminderSettings] from [SharedPreferences].
  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return ReminderSettings(
      workoutEnabled: prefs.getBool(_keyWorkoutEnabled) ?? false,
      workoutHour: prefs.getInt(_keyWorkoutHour) ?? 8,
      workoutMinute: prefs.getInt(_keyWorkoutMinute) ?? 0,
      mealEnabled: prefs.getBool(_keyMealEnabled) ?? false,
      mealHour: prefs.getInt(_keyMealHour) ?? 12,
      mealMinute: prefs.getInt(_keyMealMinute) ?? 0,
      weightEnabled: prefs.getBool(_keyWeightEnabled) ?? false,
      weightDay: prefs.getInt(_keyWeightDay) ?? 0,
      weightHour: prefs.getInt(_keyWeightHour) ?? 7,
      weightMinute: prefs.getInt(_keyWeightMinute) ?? 0,
    );
  }

  /// Persists [settings] to [SharedPreferences] and reschedules all
  /// notifications to match.
  Future<void> saveAndSchedule(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setBool(_keyWorkoutEnabled, settings.workoutEnabled),
      prefs.setInt(_keyWorkoutHour, settings.workoutHour),
      prefs.setInt(_keyWorkoutMinute, settings.workoutMinute),
      prefs.setBool(_keyMealEnabled, settings.mealEnabled),
      prefs.setInt(_keyMealHour, settings.mealHour),
      prefs.setInt(_keyMealMinute, settings.mealMinute),
      prefs.setBool(_keyWeightEnabled, settings.weightEnabled),
      prefs.setInt(_keyWeightDay, settings.weightDay),
      prefs.setInt(_keyWeightHour, settings.weightHour),
      prefs.setInt(_keyWeightMinute, settings.weightMinute),
    ]);

    await _scheduleAll(settings);
  }

  /// Cancels all scheduled reminder notifications.
  Future<void> cancelAll() async {
    await _plugin.cancel(_workoutNotificationId);
    await _plugin.cancel(_mealNotificationId);
    await _plugin.cancel(_weightNotificationId);
  }

  // ---------------------------------------------------------------------------
  // Scheduling (private)
  // ---------------------------------------------------------------------------

  Future<void> _scheduleAll(ReminderSettings settings) async {
    // Cancel existing before rescheduling.
    await cancelAll();

    if (settings.workoutEnabled) {
      await _scheduleDaily(
        id: _workoutNotificationId,
        title: 'Workout Reminder',
        body: 'Time to get your workout in! Stay consistent.',
        hour: settings.workoutHour,
        minute: settings.workoutMinute,
        payload: 'workout',
      );
    }

    if (settings.mealEnabled) {
      await _scheduleDaily(
        id: _mealNotificationId,
        title: 'Meal Logging Reminder',
        body: 'Don\'t forget to log your meals today.',
        hour: settings.mealHour,
        minute: settings.mealMinute,
        payload: 'meal',
      );
    }

    if (settings.weightEnabled) {
      await _scheduleWeekly(
        id: _weightNotificationId,
        title: 'Weight Check-in',
        body: 'Time for your weekly weigh-in. Track your progress!',
        day: settings.weightDay,
        hour: settings.weightHour,
        minute: settings.weightMinute,
        payload: 'weight',
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    final notificationDetails = _buildNotificationDetails();
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    final notificationDetails = _buildNotificationDetails();
    final scheduledDate = _nextInstanceOfWeekday(day, hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  NotificationDetails _buildNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Returns the next [tz.TZDateTime] matching the given [hour] and [minute].
  ///
  /// If the time has already passed today, returns tomorrow at that time.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Returns the next [tz.TZDateTime] matching the given weekday, [hour], and
  /// [minute].
  ///
  /// [day] uses 0=Monday..6=Sunday mapping. Internally converted to Dart's
  /// [DateTime.monday] (1) .. [DateTime.sunday] (7).
  tz.TZDateTime _nextInstanceOfWeekday(int day, int hour, int minute) {
    // Convert 0=Mon..6=Sun to Dart's 1=Mon..7=Sun.
    final dartWeekday = day + 1;

    var scheduled = _nextInstanceOfTime(hour, minute);

    while (scheduled.weekday != dartWeekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Resolves the local IANA timezone name using the platform.
  ///
  /// Falls back to UTC when the platform timezone cannot be determined.
  Future<String> _resolveLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      return timezoneName;
    } catch (e) {
      debugPrint('Failed to get local timezone, falling back to UTC: $e');
      return 'UTC';
    }
  }
}

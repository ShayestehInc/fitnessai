import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Repository for Apple Watch communication via WatchConnectivity.
///
/// Uses a MethodChannel to bridge to the native iOS WCSession.
/// On Android this is a no-op (returns sensible defaults).
class WatchRepository {
  static const _channel = MethodChannel('com.shayestehinc.fitnessai/watch');

  WatchRepository() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final _setCompletionController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of set completions received from the watch.
  Stream<Map<String, dynamic>> get setCompletions =>
      _setCompletionController.stream;

  /// Whether a paired watch is reachable right now.
  Future<bool> get isWatchConnected async {
    try {
      final result = await _channel.invokeMethod<bool>('isReachable');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Whether any watch is paired (even if not currently reachable).
  Future<bool> get isWatchPaired async {
    try {
      final result = await _channel.invokeMethod<bool>('isPaired');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Send today's workout plan to the watch.
  ///
  /// [workoutPlan] should contain:
  /// - `programName` (String)
  /// - `dayNumber` (int)
  /// - `dayName` (String)
  /// - `exercises` (List<Map>) each with id, name, sets, reps, weight, restSeconds
  /// - `weightUnit` (String)
  Future<void> syncWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    try {
      await _channel.invokeMethod<void>(
        'syncWorkoutPlan',
        jsonEncode(workoutPlan),
      );
    } on MissingPluginException {
      // Not on iOS or watch_connectivity not set up yet — silently ignore.
    }
  }

  /// Request the watch to send back any pending set completions.
  Future<void> requestPendingCompletions() async {
    try {
      await _channel.invokeMethod<void>('requestPendingCompletions');
    } on MissingPluginException {
      // No-op on non-iOS platforms.
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSetCompletion':
        final data = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        _setCompletionController.add(data);
        return null;
      default:
        return null;
    }
  }

  void dispose() {
    _setCompletionController.close();
  }
}

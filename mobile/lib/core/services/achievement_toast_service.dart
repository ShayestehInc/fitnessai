import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../features/community/data/models/achievement_model.dart';
import '../../shared/widgets/achievement_celebration_overlay.dart';
import '../router/app_router.dart' show rootNavigatorKey;

/// Manages a queue of achievement celebrations and shows them sequentially.
///
/// Usage:
///   AchievementToastService.instance.showAchievements(achievements);
///
/// The service uses [rootNavigatorKey] from the app router to access the
/// root Overlay. No additional setup is required.
class AchievementToastService {
  AchievementToastService._();

  static final AchievementToastService instance = AchievementToastService._();

  final Queue<NewAchievementModel> _queue = Queue<NewAchievementModel>();
  bool _isShowing = false;

  /// Enqueue one or more achievements to be displayed.
  ///
  /// If nothing is currently showing, begins displaying immediately.
  /// If a celebration is already on screen, queued items will display
  /// after the current one dismisses.
  void showAchievements(List<NewAchievementModel> achievements) {
    if (achievements.isEmpty) return;
    _queue.addAll(achievements);
    if (!_isShowing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isShowing = true;

    while (_queue.isNotEmpty) {
      final achievement = _queue.removeFirst();
      final overlay = _getOverlay();
      if (overlay == null) {
        // No overlay available (app not mounted yet). Clear queue.
        _queue.clear();
        break;
      }

      final topPadding = _getTopPadding();

      await showAchievementCelebration(
        overlay: overlay,
        achievement: achievement,
        topPadding: topPadding,
      );

      // Brief pause between sequential achievements.
      if (_queue.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    _isShowing = false;
  }

  OverlayState? _getOverlay() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;
    return Overlay.of(context);
  }

  /// Clear any queued achievements that haven't been shown yet.
  void cancelAll() {
    _queue.clear();
  }

  double _getTopPadding() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return 44.0;
    return MediaQuery.of(context).padding.top;
  }
}

/// Convenience function to parse raw achievement JSON from an API response
/// and show celebration toasts. This is the single entry point used by all
/// screens that trigger achievements (workout, nutrition, weight check-in).
///
/// [rawAchievements] is the `new_achievements` list from the API response,
/// typically `List<dynamic>` containing `Map<String, dynamic>` entries.
void showAchievementToastsFromRaw(List<dynamic>? rawAchievements) {
  if (rawAchievements == null || rawAchievements.isEmpty) return;
  try {
    final achievements = rawAchievements
        .whereType<Map<String, dynamic>>()
        .map((json) => NewAchievementModel.fromJson(json))
        .toList();
    if (achievements.isNotEmpty) {
      AchievementToastService.instance.showAchievements(achievements);
    }
  } catch (e) {
    developer.log(
      'Failed to parse achievement data for toast display',
      error: e,
      name: 'AchievementToastService',
    );
  }
}

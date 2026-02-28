import 'package:flutter/services.dart';

/// Semantic haptic feedback utility for platform-native tactile responses.
///
/// Uses Flutter's built-in [HapticFeedback] — no additional dependencies.
/// All methods are fire-and-forget (return void, never throw).
abstract final class HapticService {
  /// Light tap — nav tab switch, list item selection, minor toggle.
  static void lightTap() => HapticFeedback.lightImpact();

  /// Medium tap — button press, card tap, form submit.
  static void mediumTap() => HapticFeedback.mediumImpact();

  /// Heavy tap — destructive confirmation, long press.
  static void heavyTap() => HapticFeedback.heavyImpact();

  /// Selection tick — switch toggle, picker snap.
  static void selectionTick() => HapticFeedback.selectionClick();

  /// Success — save complete, action confirmed.
  static void success() => HapticFeedback.mediumImpact();

  /// Error — validation failure, destructive action triggered.
  static void error() => HapticFeedback.heavyImpact();
}

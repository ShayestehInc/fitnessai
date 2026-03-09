import 'package:flutter/material.dart';

/// Dashboard-specific color constants for the trainee home screen.
class DashboardColors {
  // Activity ring colors
  static const Color caloriesRing = Color(0xFF8B5CF6); // Violet
  static const Color stepsRing = Color(0xFFF97316); // Orange
  static const Color activityRing = Color(0xFF22C55E); // Green

  // Difficulty badge colors
  static const Color beginnerBadge = Color(0xFF22C55E); // Green
  static const Color intermediateBadge = Color(0xFFF59E0B); // Amber
  static const Color advancedBadge = Color(0xFFEF4444); // Red

  // Health card accents
  static const Color heartRate = Color(0xFFEF4444); // Red
  static const Color sleepAccent = Color(0xFF8B5CF6); // Violet

  // Trend indicators
  static const Color trendDown = Color(0xFF22C55E); // Green (weight loss)
  static const Color trendUp = Color(0xFFEF4444); // Red (weight gain)

  // Leaderboard
  static const Color trophy = Color(0xFFF59E0B); // Amber
}

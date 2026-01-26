import 'package:flutter/material.dart';

/// Shadcn "Zinc" Dark Mode Theme
/// Matches the minimalist, professional aesthetic of Shadcn UI
class AppTheme {
  // Zinc color palette (dark mode)
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Accent colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF27272A);
  static const Color secondaryForeground = Color(0xFFFAFAFA);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF27272A);
  static const Color mutedForeground = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFF27272A);
  static const Color accentForeground = Color(0xFFFAFAFA);
  static const Color border = Color(0xFF3F3F46);
  static const Color input = Color(0xFF3F3F46);
  static const Color ring = Color(0xFF6366F1);
  static const Color background = Color(0xFF09090B);
  static const Color foreground = Color(0xFFFAFAFA);
  static const Color card = Color(0xFF18181B);
  static const Color cardForeground = Color(0xFFFAFAFA);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        error: destructive,
        onError: destructiveForeground,
        surface: background,
        onSurface: foreground,
        background: background,
        onBackground: foreground,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ring, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: foreground, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: foreground, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: foreground, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: foreground, fontSize: 16),
        bodyMedium: TextStyle(color: foreground, fontSize: 14),
        bodySmall: TextStyle(color: foreground, fontSize: 12),
        labelLarge: TextStyle(color: mutedForeground, fontSize: 14),
        labelMedium: TextStyle(color: mutedForeground, fontSize: 12),
        labelSmall: TextStyle(color: mutedForeground, fontSize: 10),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available preset color schemes for the app
enum AppColorScheme {
  indigo('Indigo', Color(0xFF6366F1), Color(0xFF818CF8)),
  purple('Purple', Color(0xFF8B5CF6), Color(0xFFA78BFA)),
  blue('Ocean', Color(0xFF3B82F6), Color(0xFF60A5FA)),
  emerald('Emerald', Color(0xFF10B981), Color(0xFF34D399)),
  rose('Rose', Color(0xFFF43F5E), Color(0xFFFB7185)),
  amber('Amber', Color(0xFFF59E0B), Color(0xFFFBBF24)),
  cyan('Cyan', Color(0xFF06B6D4), Color(0xFF22D3EE)),
  pink('Pink', Color(0xFFEC4899), Color(0xFFF472B6)),
  custom('Custom', Color(0xFF6366F1), Color(0xFF818CF8));

  final String displayName;
  final Color primary;
  final Color primaryLight;

  const AppColorScheme(this.displayName, this.primary, this.primaryLight);
}

/// Theme mode with system option
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Custom color palette for granular control
class CustomColorPalette {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;

  // Background colors (null = use defaults)
  final Color? backgroundDark;
  final Color? surfaceDark;
  final Color? cardDark;
  final Color? backgroundLight;
  final Color? surfaceLight;
  final Color? cardLight;

  const CustomColorPalette({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    this.success = const Color(0xFF10B981),
    this.warning = const Color(0xFFF59E0B),
    this.error = const Color(0xFFEF4444),
    this.backgroundDark,
    this.surfaceDark,
    this.cardDark,
    this.backgroundLight,
    this.surfaceLight,
    this.cardLight,
  });

  /// Generate a complete color palette from a single primary color
  factory CustomColorPalette.fromPrimary(Color primary) {
    final hsl = HSLColor.fromColor(primary);

    // Generate primary light (lighter, more saturated)
    final primaryLight = HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 1.1).clamp(0.0, 1.0),
      (hsl.lightness + 0.15).clamp(0.0, 1.0),
    ).toColor();

    // Generate secondary (complementary hue shift)
    final secondaryHue = (hsl.hue + 30) % 360;
    final secondary = HSLColor.fromAHSL(
      1.0,
      secondaryHue,
      hsl.saturation * 0.8,
      hsl.lightness,
    ).toColor();

    final secondaryLight = HSLColor.fromAHSL(
      1.0,
      secondaryHue,
      (hsl.saturation * 0.9).clamp(0.0, 1.0),
      (hsl.lightness + 0.15).clamp(0.0, 1.0),
    ).toColor();

    // Generate accent (triadic color)
    final accentHue = (hsl.hue + 180) % 360;
    final accent = HSLColor.fromAHSL(
      1.0,
      accentHue,
      hsl.saturation * 0.7,
      (hsl.lightness + 0.1).clamp(0.0, 1.0),
    ).toColor();

    return CustomColorPalette(
      primary: primary,
      primaryLight: primaryLight,
      secondary: secondary,
      secondaryLight: secondaryLight,
      accent: accent,
    );
  }

  CustomColorPalette copyWith({
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? secondaryLight,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? backgroundDark,
    Color? surfaceDark,
    Color? cardDark,
    Color? backgroundLight,
    Color? surfaceLight,
    Color? cardLight,
  }) {
    return CustomColorPalette(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      cardDark: cardDark ?? this.cardDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      cardLight: cardLight ?? this.cardLight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary.value,
      'primaryLight': primaryLight.value,
      'secondary': secondary.value,
      'secondaryLight': secondaryLight.value,
      'accent': accent.value,
      'success': success.value,
      'warning': warning.value,
      'error': error.value,
      'backgroundDark': backgroundDark?.value,
      'surfaceDark': surfaceDark?.value,
      'cardDark': cardDark?.value,
      'backgroundLight': backgroundLight?.value,
      'surfaceLight': surfaceLight?.value,
      'cardLight': cardLight?.value,
    };
  }

  factory CustomColorPalette.fromJson(Map<String, dynamic> json) {
    return CustomColorPalette(
      primary: Color(json['primary'] as int),
      primaryLight: Color(json['primaryLight'] as int),
      secondary: Color(json['secondary'] as int),
      secondaryLight: Color(json['secondaryLight'] as int),
      accent: Color(json['accent'] as int),
      success: json['success'] != null ? Color(json['success'] as int) : const Color(0xFF10B981),
      warning: json['warning'] != null ? Color(json['warning'] as int) : const Color(0xFFF59E0B),
      error: json['error'] != null ? Color(json['error'] as int) : const Color(0xFFEF4444),
      backgroundDark: json['backgroundDark'] != null ? Color(json['backgroundDark'] as int) : null,
      surfaceDark: json['surfaceDark'] != null ? Color(json['surfaceDark'] as int) : null,
      cardDark: json['cardDark'] != null ? Color(json['cardDark'] as int) : null,
      backgroundLight: json['backgroundLight'] != null ? Color(json['backgroundLight'] as int) : null,
      surfaceLight: json['surfaceLight'] != null ? Color(json['surfaceLight'] as int) : null,
      cardLight: json['cardLight'] != null ? Color(json['cardLight'] as int) : null,
    );
  }

  /// Default palette (indigo)
  static const defaultPalette = CustomColorPalette(
    primary: Color(0xFF6366F1),
    primaryLight: Color(0xFF818CF8),
    secondary: Color(0xFF8B5CF6),
    secondaryLight: Color(0xFFA78BFA),
    accent: Color(0xFF06B6D4),
  );
}

/// Complete theme state
class AppThemeState {
  final AppThemeMode mode;
  final AppColorScheme colorScheme;
  final bool useSystemColors;
  final CustomColorPalette? customPalette;
  final bool useAdvancedColors; // When true, uses customPalette for more granular control

  const AppThemeState({
    this.mode = AppThemeMode.dark,
    this.colorScheme = AppColorScheme.indigo,
    this.useSystemColors = false,
    this.customPalette,
    this.useAdvancedColors = false,
  });

  AppThemeState copyWith({
    AppThemeMode? mode,
    AppColorScheme? colorScheme,
    bool? useSystemColors,
    CustomColorPalette? customPalette,
    bool? useAdvancedColors,
  }) {
    return AppThemeState(
      mode: mode ?? this.mode,
      colorScheme: colorScheme ?? this.colorScheme,
      useSystemColors: useSystemColors ?? this.useSystemColors,
      customPalette: customPalette ?? this.customPalette,
      useAdvancedColors: useAdvancedColors ?? this.useAdvancedColors,
    );
  }

  bool get isDark => mode == AppThemeMode.dark;
  bool get isLight => mode == AppThemeMode.light;
  bool get isSystem => mode == AppThemeMode.system;

  /// Get the effective primary color
  Color get effectivePrimary {
    if (colorScheme == AppColorScheme.custom && customPalette != null) {
      return customPalette!.primary;
    }
    return colorScheme.primary;
  }

  /// Get the effective primary light color
  Color get effectivePrimaryLight {
    if (colorScheme == AppColorScheme.custom && customPalette != null) {
      return customPalette!.primaryLight;
    }
    return colorScheme.primaryLight;
  }
}

/// Theme notifier for state management
class ThemeNotifier extends StateNotifier<AppThemeState> {
  static const String _modeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';
  static const String _customPaletteKey = 'custom_palette';
  static const String _useAdvancedKey = 'use_advanced_colors';

  ThemeNotifier() : super(const AppThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_modeKey) ?? 2; // Default to dark
    final colorIndex = prefs.getInt(_colorSchemeKey) ?? 0; // Default to indigo
    final useAdvanced = prefs.getBool(_useAdvancedKey) ?? false;

    CustomColorPalette? customPalette;
    final customPaletteJson = prefs.getString(_customPaletteKey);
    if (customPaletteJson != null) {
      try {
        customPalette = CustomColorPalette.fromJson(jsonDecode(customPaletteJson));
      } catch (_) {
        // Invalid JSON, use default
      }
    }

    state = state.copyWith(
      mode: AppThemeMode.values[modeIndex.clamp(0, AppThemeMode.values.length - 1)],
      colorScheme: AppColorScheme.values[colorIndex.clamp(0, AppColorScheme.values.length - 1)],
      customPalette: customPalette,
      useAdvancedColors: useAdvanced,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
    _updateSystemUI(mode);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, scheme.index);
  }

  /// Set a custom primary color and generate palette from it
  Future<void> setCustomPrimaryColor(Color primary) async {
    final palette = CustomColorPalette.fromPrimary(primary);
    state = state.copyWith(
      colorScheme: AppColorScheme.custom,
      customPalette: palette,
    );
    await _saveCustomPalette(palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, AppColorScheme.custom.index);
  }

  /// Set a complete custom palette
  Future<void> setCustomPalette(CustomColorPalette palette) async {
    state = state.copyWith(
      colorScheme: AppColorScheme.custom,
      customPalette: palette,
    );
    await _saveCustomPalette(palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, AppColorScheme.custom.index);
  }

  /// Update a single color in the custom palette
  Future<void> updateCustomColor({
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? secondaryLight,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? backgroundDark,
    Color? surfaceDark,
    Color? cardDark,
    Color? backgroundLight,
    Color? surfaceLight,
    Color? cardLight,
  }) async {
    final currentPalette = state.customPalette ?? CustomColorPalette.defaultPalette;
    final newPalette = currentPalette.copyWith(
      primary: primary,
      primaryLight: primaryLight,
      secondary: secondary,
      secondaryLight: secondaryLight,
      accent: accent,
      success: success,
      warning: warning,
      error: error,
      backgroundDark: backgroundDark,
      surfaceDark: surfaceDark,
      cardDark: cardDark,
      backgroundLight: backgroundLight,
      surfaceLight: surfaceLight,
      cardLight: cardLight,
    );

    state = state.copyWith(
      colorScheme: AppColorScheme.custom,
      customPalette: newPalette,
    );
    await _saveCustomPalette(newPalette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, AppColorScheme.custom.index);
  }

  /// Toggle advanced color mode
  Future<void> setAdvancedColorsEnabled(bool enabled) async {
    state = state.copyWith(useAdvancedColors: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAdvancedKey, enabled);
  }

  /// Regenerate palette from current primary color
  Future<void> regeneratePaletteFromPrimary() async {
    if (state.customPalette != null) {
      final newPalette = CustomColorPalette.fromPrimary(state.customPalette!.primary);
      state = state.copyWith(customPalette: newPalette);
      await _saveCustomPalette(newPalette);
    }
  }

  /// Reset to default palette
  Future<void> resetToDefaults() async {
    state = state.copyWith(
      colorScheme: AppColorScheme.indigo,
      customPalette: null,
      useAdvancedColors: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, AppColorScheme.indigo.index);
    await prefs.remove(_customPaletteKey);
    await prefs.setBool(_useAdvancedKey, false);
  }

  Future<void> _saveCustomPalette(CustomColorPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customPaletteKey, jsonEncode(palette.toJson()));
  }

  void _updateSystemUI(AppThemeMode mode) {
    final isDark = mode == AppThemeMode.dark ||
        (mode == AppThemeMode.system &&
         WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider that returns the actual ThemeData based on current state
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeProvider);
  return AppThemeBuilder.buildTheme(themeState);
});

/// Provider for current brightness (resolves system theme)
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final themeState = ref.watch(themeProvider);

  if (themeState.mode == AppThemeMode.system) {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  return themeState.mode == AppThemeMode.dark ? Brightness.dark : Brightness.light;
});

/// Theme builder that creates ThemeData from state
class AppThemeBuilder {
  static ThemeData buildTheme(AppThemeState themeState) {
    final isDark = themeState.mode == AppThemeMode.dark ||
        (themeState.mode == AppThemeMode.system &&
         WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    return isDark
        ? _buildDarkTheme(themeState)
        : _buildLightTheme(themeState);
  }

  static ThemeData _buildDarkTheme(AppThemeState themeState) {
    final Color primary;
    final Color primaryLight;
    final Color secondary;
    final Color errorColor;

    // Use custom palette if available and using custom scheme
    if (themeState.colorScheme == AppColorScheme.custom && themeState.customPalette != null) {
      final palette = themeState.customPalette!;
      primary = palette.primary;
      primaryLight = palette.primaryLight;
      secondary = palette.secondary;
      errorColor = palette.error;
    } else {
      primary = themeState.colorScheme.primary;
      primaryLight = themeState.colorScheme.primaryLight;
      secondary = primaryLight;
      errorColor = const Color(0xFFEF4444);
    }

    // Dark mode colors (use custom if provided)
    final background = themeState.customPalette?.backgroundDark ?? const Color(0xFF09090B);
    final surface = themeState.customPalette?.surfaceDark ?? const Color(0xFF18181B);
    final card = themeState.customPalette?.cardDark ?? const Color(0xFF1C1C1F);
    const border = Color(0xFF27272A);
    const foreground = Color(0xFFFAFAFA);
    const mutedForeground = Color(0xFFA1A1AA);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        tertiary: primaryLight.withValues(alpha: 0.3),
        error: errorColor,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: mutedForeground),
        labelStyle: const TextStyle(color: mutedForeground),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: const TextStyle(color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return border;
        }),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: foreground, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: foreground, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(color: foreground, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: foreground, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: mutedForeground, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: mutedForeground, fontSize: 12),
        labelSmall: TextStyle(color: mutedForeground, fontSize: 10),
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData _buildLightTheme(AppThemeState themeState) {
    final Color primary;
    final Color primaryLight;
    final Color secondary;
    final Color errorColor;

    // Use custom palette if available and using custom scheme
    if (themeState.colorScheme == AppColorScheme.custom && themeState.customPalette != null) {
      final palette = themeState.customPalette!;
      primary = palette.primary;
      primaryLight = palette.primaryLight;
      secondary = palette.secondary;
      errorColor = palette.error;
    } else {
      primary = themeState.colorScheme.primary;
      primaryLight = themeState.colorScheme.primaryLight;
      secondary = primaryLight;
      errorColor = const Color(0xFFDC2626);
    }

    // Light mode colors (use custom if provided)
    final background = themeState.customPalette?.backgroundLight ?? const Color(0xFFFAFAFA);
    final surface = themeState.customPalette?.surfaceLight ?? const Color(0xFFFFFFFF);
    final card = themeState.customPalette?.cardLight ?? const Color(0xFFFFFFFF);
    const border = Color(0xFFE4E4E7);
    const foreground = Color(0xFF09090B);
    const mutedForeground = Color(0xFF71717A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        tertiary: primaryLight.withValues(alpha: 0.1),
        error: errorColor,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: mutedForeground),
        labelStyle: const TextStyle(color: mutedForeground),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: TextStyle(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: const TextStyle(color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return border;
        }),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: foreground, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: foreground, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(color: foreground, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: foreground, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: mutedForeground, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: mutedForeground, fontSize: 12),
        labelSmall: TextStyle(color: mutedForeground, fontSize: 10),
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Extension to get theme colors easily
extension ThemeColorExtension on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get cardColor => Theme.of(this).cardColor;
  Color get borderColor => Theme.of(this).dividerColor;
  Color get foregroundColor => Theme.of(this).colorScheme.onSurface;
  Color get mutedColor => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.6);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

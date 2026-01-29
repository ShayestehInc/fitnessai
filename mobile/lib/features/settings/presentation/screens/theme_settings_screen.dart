import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  bool _showAdvancedColors = false;
  bool _showOtherColors = false;

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final canCustomize = user?.isAdmin == true || user?.isTrainer == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Section
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 100),
              child: _buildSectionTitle(context, 'Theme Mode'),
            ),
            const SizedBox(height: 12),
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 150),
              child: _buildThemeModeSelector(context, ref, themeState),
            ),
            const SizedBox(height: 32),

            // Accent Color Section - Presets
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 200),
              child: _buildSectionTitle(context, 'Accent Color'),
            ),
            const SizedBox(height: 12),
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 250),
              child: _buildColorSelector(context, ref, themeState),
            ),

            // Other Colors Section - Only for Admins/Trainers
            if (canCustomize) ...[
              const SizedBox(height: 16),
              SlideInWidget(
                direction: SlideDirection.up,
                delay: const Duration(milliseconds: 300),
                child: _buildOtherColorsToggle(context, themeState),
              ),

              // Expandable Other Colors Content
              if (_showOtherColors) ...[
                const SizedBox(height: 16),
                SlideInWidget(
                  direction: SlideDirection.up,
                  delay: const Duration(milliseconds: 350),
                  child: _buildColorWheelPicker(context, ref, themeState),
                ),

                // Generated Palette Display
                if (themeState.colorScheme == AppColorScheme.custom &&
                    themeState.customPalette != null) ...[
                  const SizedBox(height: 24),
                  SlideInWidget(
                    direction: SlideDirection.up,
                    delay: const Duration(milliseconds: 400),
                    child: _buildGeneratedPalette(context, ref, themeState),
                  ),

                  // Advanced Colors Toggle
                  const SizedBox(height: 24),
                  SlideInWidget(
                    direction: SlideDirection.up,
                    delay: const Duration(milliseconds: 450),
                    child: _buildAdvancedToggle(context),
                  ),

                  // Advanced Color Controls
                  if (_showAdvancedColors) ...[
                    const SizedBox(height: 16),
                    SlideInWidget(
                      direction: SlideDirection.up,
                      delay: const Duration(milliseconds: 500),
                      child: _buildAdvancedColorControls(context, ref, themeState),
                    ),
                  ],
                ],
              ],
            ],

            const SizedBox(height: 32),

            // Preview Section
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 550),
              child: _buildSectionTitle(context, 'Preview'),
            ),
            const SizedBox(height: 12),
            SlideInWidget(
              direction: SlideDirection.up,
              delay: const Duration(milliseconds: 600),
              child: _buildPreviewCard(context, themeState),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _ThemeModeOption(
            icon: Icons.brightness_auto,
            title: 'System',
            subtitle: 'Match device settings',
            isSelected: themeState.mode == AppThemeMode.system,
            onTap: () => ref.read(themeProvider.notifier).setThemeMode(AppThemeMode.system),
            isFirst: true,
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          _ThemeModeOption(
            icon: Icons.light_mode,
            title: 'Light',
            subtitle: 'Always use light mode',
            isSelected: themeState.mode == AppThemeMode.light,
            onTap: () => ref.read(themeProvider.notifier).setThemeMode(AppThemeMode.light),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          _ThemeModeOption(
            icon: Icons.dark_mode,
            title: 'Dark',
            subtitle: 'Always use dark mode',
            isSelected: themeState.mode == AppThemeMode.dark,
            onTap: () => ref.read(themeProvider.notifier).setThemeMode(AppThemeMode.dark),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
  ) {
    final theme = Theme.of(context);
    // Exclude 'custom' from the preset list
    final presets = AppColorScheme.values.where((s) => s != AppColorScheme.custom).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: presets.map((scheme) {
          final isSelected = themeState.colorScheme == scheme;
          return AnimatedPress(
            onTap: () => ref.read(themeProvider.notifier).setColorScheme(scheme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.primaryLight],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scheme.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? scheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtherColorsToggle(BuildContext context, AppThemeState themeState) {
    final theme = Theme.of(context);
    final isCustom = themeState.colorScheme == AppColorScheme.custom;

    return AnimatedPress(
      onTap: () {
        setState(() {
          _showOtherColors = !_showOtherColors;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCustom
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isCustom && themeState.customPalette != null
                    ? LinearGradient(
                        colors: [
                          themeState.customPalette!.primary,
                          themeState.customPalette!.primaryLight,
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFF59E0B),
                          Color(0xFF10B981),
                          Color(0xFF3B82F6),
                          Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
              ),
              child: isCustom
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize theme color',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCustom ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    isCustom ? 'Custom color active' : 'Pick your own color',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.labelMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showOtherColors ? Icons.expand_less : Icons.expand_more,
              color: theme.textTheme.labelMedium?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorWheelPicker(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
  ) {
    final theme = Theme.of(context);
    final isCustom = themeState.colorScheme == AppColorScheme.custom;
    final currentColor = isCustom && themeState.customPalette != null
        ? themeState.customPalette!.primary
        : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Color Wheel
          _ColorWheel(
            selectedColor: currentColor,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).setCustomPrimaryColor(color);
            },
          ),
          const SizedBox(height: 24),
          // Hex Input and Preview
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _HexColorInput(
                  color: currentColor,
                  onColorChanged: (color) {
                    ref.read(themeProvider.notifier).setCustomPrimaryColor(color);
                  },
                ),
              ),
            ],
          ),
          // Reset to default button
          if (isCustom) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(themeProvider.notifier).resetToDefaults();
                  setState(() {
                    _showAdvancedColors = false;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset to default'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratedPalette(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
  ) {
    final theme = Theme.of(context);
    final palette = themeState.customPalette!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generated Palette',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(themeProvider.notifier).regeneratePaletteFromPrimary();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PaletteColorChip(
                label: 'Primary',
                color: palette.primary,
              ),
              _PaletteColorChip(
                label: 'Primary Light',
                color: palette.primaryLight,
              ),
              _PaletteColorChip(
                label: 'Secondary',
                color: palette.secondary,
              ),
              _PaletteColorChip(
                label: 'Accent',
                color: palette.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPress(
      onTap: () {
        setState(() {
          _showAdvancedColors = !_showAdvancedColors;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Color Controls',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Fine-tune individual colors',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.labelMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showAdvancedColors ? Icons.expand_less : Icons.expand_more,
              color: theme.textTheme.labelMedium?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedColorControls(
    BuildContext context,
    WidgetRef ref,
    AppThemeState themeState,
  ) {
    final theme = Theme.of(context);
    final palette = themeState.customPalette!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand Colors',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.labelMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          _AdvancedColorRow(
            label: 'Primary',
            color: palette.primary,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(primary: color);
            },
          ),
          _AdvancedColorRow(
            label: 'Primary Light',
            color: palette.primaryLight,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(primaryLight: color);
            },
          ),
          _AdvancedColorRow(
            label: 'Secondary',
            color: palette.secondary,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(secondary: color);
            },
          ),
          _AdvancedColorRow(
            label: 'Accent',
            color: palette.accent,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(accent: color);
            },
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Status Colors',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.labelMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          _AdvancedColorRow(
            label: 'Success',
            color: palette.success,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(success: color);
            },
          ),
          _AdvancedColorRow(
            label: 'Warning',
            color: palette.warning,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(warning: color);
            },
          ),
          _AdvancedColorRow(
            label: 'Error',
            color: palette.error,
            onColorSelected: (color) {
              ref.read(themeProvider.notifier).updateCustomColor(error: color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, AppThemeState themeState) {
    final theme = Theme.of(context);
    final primary = themeState.effectivePrimary;
    final primaryLight = themeState.effectivePrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Workout',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upper Body - 45 min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.labelMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar preview
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '65%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Buttons preview
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Schedule'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all color customizations back to the default Indigo theme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textTheme.labelMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(themeProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              setState(() {
                _showOtherColors = false;
                _showAdvancedColors = false;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnimatedPress(
      onTap: onTap,
      scaleDown: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? primary.withValues(alpha: 0.15) : theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? primary : theme.textTheme.labelMedium?.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.labelMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Color wheel picker widget
class _ColorWheel extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorWheel({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<_ColorWheel> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    _updateFromColor(widget.selectedColor);
  }

  @override
  void didUpdateWidget(_ColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      _updateFromColor(widget.selectedColor);
    }
  }

  void _updateFromColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20; // Account for padding

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Calculate hue from angle
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    final hue = (angle / (2 * math.pi)) * 360;

    // Calculate saturation from distance (clamped to wheel radius)
    final saturation = (distance / radius).clamp(0.0, 1.0);

    setState(() {
      _hue = hue;
      _saturation = saturation;
    });

    final color = HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();
    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Color Wheel
        LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, 280.0);
            return GestureDetector(
              onPanStart: (details) => _onPanUpdate(details.localPosition, Size(size, size)),
              onPanUpdate: (details) => _onPanUpdate(details.localPosition, Size(size, size)),
              onTapDown: (details) => _onPanUpdate(details.localPosition, Size(size, size)),
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _ColorWheelPainter(
                    lightness: _lightness,
                    selectedHue: _hue,
                    selectedSaturation: _saturation,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Lightness Slider
        Row(
          children: [
            Icon(
              Icons.brightness_low,
              size: 20,
              color: theme.textTheme.labelMedium?.color,
            ),
            Expanded(
              child: Slider(
                value: _lightness,
                min: 0.2,
                max: 0.8,
                onChanged: (value) {
                  setState(() {
                    _lightness = value;
                  });
                  final color = HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();
                  widget.onColorSelected(color);
                },
              ),
            ),
            Icon(
              Icons.brightness_high,
              size: 20,
              color: theme.textTheme.labelMedium?.color,
            ),
          ],
        ),
        Text(
          'Brightness',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.labelMedium?.color,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the color wheel
class _ColorWheelPainter extends CustomPainter {
  final double lightness;
  final double selectedHue;
  final double selectedSaturation;

  _ColorWheelPainter({
    required this.lightness,
    required this.selectedHue,
    required this.selectedSaturation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw the color wheel using sweep gradient
    final wheelPaint = Paint()
      ..shader = SweepGradient(
        colors: List.generate(360, (i) {
          return HSLColor.fromAHSL(1.0, i.toDouble(), 1.0, lightness).toColor();
        }),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, wheelPaint);

    // Draw radial gradient for saturation (white in center)
    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          HSLColor.fromAHSL(1.0, 0, 0, lightness).toColor(),
          HSLColor.fromAHSL(0.0, 0, 0, lightness).toColor(),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, saturationPaint);

    // Draw selection indicator
    final angle = (selectedHue / 360) * 2 * math.pi;
    final distance = selectedSaturation * radius;
    final selectorX = center.dx + distance * math.cos(angle);
    final selectorY = center.dy + distance * math.sin(angle);

    // Outer ring (white)
    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(selectorX, selectorY), 12, outerRingPaint);

    // Inner ring (dark for contrast)
    final innerRingPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(selectorX, selectorY), 10, innerRingPaint);

    // Fill with selected color
    final selectedColor = HSLColor.fromAHSL(1.0, selectedHue, selectedSaturation, lightness).toColor();
    final fillPaint = Paint()..color = selectedColor;
    canvas.drawCircle(Offset(selectorX, selectorY), 9, fillPaint);
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return oldDelegate.lightness != lightness ||
           oldDelegate.selectedHue != selectedHue ||
           oldDelegate.selectedSaturation != selectedSaturation;
  }
}

/// Hex color input field
class _HexColorInput extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const _HexColorInput({
    required this.color,
    required this.onColorChanged,
  });

  @override
  State<_HexColorInput> createState() => _HexColorInputState();
}

class _HexColorInputState extends State<_HexColorInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _colorToHex(widget.color));
  }

  @override
  void didUpdateWidget(_HexColorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      final newHex = _colorToHex(widget.color);
      if (_controller.text.toUpperCase() != newHex.toUpperCase()) {
        _controller.text = newHex;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length != 6) return null;
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Hex Color',
        hintText: '#6366F1',
        prefixIcon: Icon(Icons.tag, size: 20),
      ),
      textCapitalization: TextCapitalization.characters,
      onSubmitted: (value) {
        final color = _hexToColor(value);
        if (color != null) {
          widget.onColorChanged(color);
        }
      },
      onChanged: (value) {
        if (value.length == 7 || (value.length == 6 && !value.startsWith('#'))) {
          final color = _hexToColor(value);
          if (color != null) {
            widget.onColorChanged(color);
          }
        }
      },
    );
  }
}

/// Palette color chip display
class _PaletteColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PaletteColorChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.dividerColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced color row with edit capability
class _AdvancedColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onColorSelected;

  const _AdvancedColorRow({
    required this.label,
    required this.color,
    required this.onColorSelected,
  });

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          AnimatedPress(
            onTap: () => _showColorPickerDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dividerColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _colorToHex(color),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: theme.textTheme.labelMedium?.color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: color,
        onColorSelected: onColorSelected,
      ),
    );
  }
}

/// Color picker dialog with wheel
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Select Color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorWheel(
              selectedColor: _selectedColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _colorToHex(_selectedColor),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.textTheme.labelMedium?.color),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onColorSelected(_selectedColor);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

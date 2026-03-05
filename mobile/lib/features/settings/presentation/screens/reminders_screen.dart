import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';

/// Screen for configuring workout, meal, and weight check-in reminders.
///
/// Trainee-only. Uses [ReminderService] for scheduling and persistence.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  ReminderSettings _settings = const ReminderSettings();
  bool _loading = true;

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ReminderService.instance;
    await service.initialize();
    final loaded = await service.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  Future<void> _updateSettings(ReminderSettings newSettings) async {
    setState(() => _settings = newSettings);
    try {
      await ReminderService.instance.saveAndSchedule(newSettings);
    } catch (e) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Failed to save reminder settings.',
        type: ToastType.error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Time / day pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickTime({
    required int currentHour,
    required int currentMinute,
    required void Function(int hour, int minute) onPicked,
  }) async {
    HapticService.lightTap();

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      await _showCupertinoTimePicker(
        currentHour: currentHour,
        currentMinute: currentMinute,
        onPicked: onPicked,
      );
    } else {
      await _showMaterialTimePicker(
        currentHour: currentHour,
        currentMinute: currentMinute,
        onPicked: onPicked,
      );
    }
  }

  Future<void> _showMaterialTimePicker({
    required int currentHour,
    required int currentMinute,
    required void Function(int hour, int minute) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (picked != null) {
      onPicked(picked.hour, picked.minute);
    }
  }

  Future<void> _showCupertinoTimePicker({
    required int currentHour,
    required int currentMinute,
    required void Function(int hour, int minute) onPicked,
  }) async {
    var selectedHour = currentHour;
    var selectedMinute = currentMinute;

    await showAdaptiveBottomSheet<void>(
      context: context,
      maxHeight: 300,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onPicked(selectedHour, selectedMinute);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  currentHour,
                  currentMinute,
                ),
                onDateTimeChanged: (dt) {
                  selectedHour = dt.hour;
                  selectedMinute = dt.minute;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (Platform.isIOS) {
      final granted = await ReminderService.instance.requestIOSPermission();
      if (!granted && mounted) {
        showAdaptiveToast(
          context,
          message:
              'Notification permission denied. Enable it in Settings to receive reminders.',
          type: ToastType.warning,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String _formatTime(int hour, int minute) {
    final tod = TimeOfDay(hour: hour, minute: minute);
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionHeader(theme, 'WORKOUT'),
                _buildWorkoutSection(theme),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, 'MEAL LOGGING'),
                _buildMealSection(theme),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, 'WEIGHT CHECK-IN'),
                _buildWeightSection(theme),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Workout reminder
  // ---------------------------------------------------------------------------

  Widget _buildWorkoutSection(ThemeData theme) {
    return _buildReminderCard(
      theme: theme,
      icon: Icons.fitness_center,
      title: 'Workout Reminder',
      subtitle: 'Get a daily reminder to complete your workout',
      enabled: _settings.workoutEnabled,
      onToggle: (enabled) async {
        if (enabled) await _requestPermissionIfNeeded();
        HapticService.selectionTick();
        await _updateSettings(_settings.copyWith(workoutEnabled: enabled));
      },
      timeLabel: _formatTime(_settings.workoutHour, _settings.workoutMinute),
      onTimeTap: () => _pickTime(
        currentHour: _settings.workoutHour,
        currentMinute: _settings.workoutMinute,
        onPicked: (h, m) => _updateSettings(
          _settings.copyWith(workoutHour: h, workoutMinute: m),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Meal reminder
  // ---------------------------------------------------------------------------

  Widget _buildMealSection(ThemeData theme) {
    return _buildReminderCard(
      theme: theme,
      icon: Icons.restaurant_menu,
      title: 'Meal Logging Reminder',
      subtitle: 'Get a daily reminder to log your meals',
      enabled: _settings.mealEnabled,
      onToggle: (enabled) async {
        if (enabled) await _requestPermissionIfNeeded();
        HapticService.selectionTick();
        await _updateSettings(_settings.copyWith(mealEnabled: enabled));
      },
      timeLabel: _formatTime(_settings.mealHour, _settings.mealMinute),
      onTimeTap: () => _pickTime(
        currentHour: _settings.mealHour,
        currentMinute: _settings.mealMinute,
        onPicked: (h, m) => _updateSettings(
          _settings.copyWith(mealHour: h, mealMinute: m),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Weight check-in reminder
  // ---------------------------------------------------------------------------

  Widget _buildWeightSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReminderCard(
          theme: theme,
          icon: Icons.monitor_weight_outlined,
          title: 'Weight Check-in Reminder',
          subtitle: 'Get a weekly reminder to log your weight',
          enabled: _settings.weightEnabled,
          onToggle: (enabled) async {
            if (enabled) await _requestPermissionIfNeeded();
            HapticService.selectionTick();
            await _updateSettings(_settings.copyWith(weightEnabled: enabled));
          },
          timeLabel:
              _formatTime(_settings.weightHour, _settings.weightMinute),
          onTimeTap: () => _pickTime(
            currentHour: _settings.weightHour,
            currentMinute: _settings.weightMinute,
            onPicked: (h, m) => _updateSettings(
              _settings.copyWith(weightHour: h, weightMinute: m),
            ),
          ),
          extraContent: _settings.weightEnabled
              ? _buildDayOfWeekPicker(theme)
              : null,
        ),
      ],
    );
  }

  Widget _buildDayOfWeekPicker(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_dayLabels.length, (index) {
          final isSelected = _settings.weightDay == index;
          return ChoiceChip(
            label: Text(_dayLabels[index]),
            selected: isSelected,
            onSelected: (_) {
              HapticService.selectionTick();
              _updateSettings(_settings.copyWith(weightDay: index));
            },
            selectedColor:
                theme.colorScheme.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared card builder
  // ---------------------------------------------------------------------------

  Widget _buildReminderCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required String timeLabel,
    required VoidCallback onTimeTap,
    Widget? extraContent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            value: enabled,
            onChanged: onToggle,
          ),
          if (enabled) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTimeRow(
              theme: theme,
              label: 'Time',
              value: timeLabel,
              onTap: onTimeTap,
            ),
            if (extraContent != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: extraContent,
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required ThemeData theme,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

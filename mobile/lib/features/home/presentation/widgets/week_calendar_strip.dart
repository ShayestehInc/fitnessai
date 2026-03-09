import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Horizontal 7-day calendar strip with selected day and workout dots.
class WeekCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Set<int> workoutDays;
  final ValueChanged<DateTime>? onDayTapped;

  const WeekCalendarStrip({
    super.key,
    required this.selectedDate,
    this.workoutDays = const {},
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart(selectedDate);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: days.map((day) {
          final isSelected = _isSameDay(day, selectedDate);
          final hasWorkout = workoutDays.contains(day.weekday);
          return Expanded(
            child: GestureDetector(
              onTap: () => onDayTapped?.call(day),
              behavior: HitTestBehavior.opaque,
              child: _DayColumn(
                day: day,
                isSelected: isSelected,
                hasWorkout: hasWorkout,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  DateTime _weekStart(DateTime date) {
    final diff = date.weekday % 7; // Sunday = 0
    return DateTime(date.year, date.month, date.day - diff);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool hasWorkout;

  const _DayColumn({
    required this.day,
    required this.isSelected,
    required this.hasWorkout,
  });

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final label = _dayLabels[day.weekday - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.foreground : AppTheme.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          decoration: isSelected
              ? const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                )
              : null,
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.foreground,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasWorkout ? AppTheme.primary : Colors.transparent,
          ),
        ),
      ],
    );
  }
}

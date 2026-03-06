import 'package:flutter/material.dart';
import '../../data/models/calendar_connection_model.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Single availability slot row with time display, active toggle, edit button.
/// Used inside Dismissible in TrainerAvailabilityScreen.
class AvailabilitySlotTile extends StatelessWidget {
  final TrainerAvailabilityModel slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const AvailabilitySlotTile({
    super.key,
    required this.slot,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _formatTimeString(slot.startTime);
    final end = _formatTimeString(slot.endTime);
    final statusLabel = slot.isActive ? 'Active' : 'Inactive';

    return Semantics(
      label: '$start to $end, $statusLabel. Swipe left to delete.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: slot.isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$start – $end',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: slot.isActive
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  decoration: slot.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            Switch.adaptive(
              value: slot.isActive,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: context.l10n.calendarEditTimeSlot,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeString(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return time; // Show raw value for malformed times
    }
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}

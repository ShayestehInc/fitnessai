import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/availability_slot_editor.dart';

class TrainerAvailabilityScreen extends ConsumerStatefulWidget {
  const TrainerAvailabilityScreen({super.key});

  @override
  ConsumerState<TrainerAvailabilityScreen> createState() =>
      _TrainerAvailabilityScreenState();
}

class _TrainerAvailabilityScreenState
    extends ConsumerState<TrainerAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).loadAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        showAdaptiveToast(context, message: next.error!, type: ToastType.error);
        ref.read(calendarProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        showAdaptiveToast(context,
            message: next.successMessage!, type: ToastType.success);
        ref.read(calendarProvider.notifier).clearMessages();
      }
    });

    final slots = state.availability;
    final grouped = _groupByDay(slots);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading && slots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : slots.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(calendarProvider.notifier).loadAvailability(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final day = grouped.keys.elementAt(index);
                      final daySlots = grouped[day]!;
                      return _buildDaySection(theme, day, daySlots);
                    },
                  ),
                ),
    );
  }

  Map<int, List<TrainerAvailabilityModel>> _groupByDay(
      List<TrainerAvailabilityModel> slots) {
    final map = <int, List<TrainerAvailabilityModel>>{};
    for (final slot in slots) {
      map.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }
    // Sort by day of week
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildDaySection(
      ThemeData theme, int day, List<TrainerAvailabilityModel> slots) {
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final dayName = day >= 0 && day < 7 ? dayNames[day] : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            dayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...slots.map((slot) => _buildSlotTile(theme, slot)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSlotTile(ThemeData theme, TrainerAvailabilityModel slot) {
    final start = _formatTimeString(slot.startTime);
    final end = _formatTimeString(slot.endTime);

    return Dismissible(
      key: ValueKey(slot.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) => _confirmDelete(slot.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: slot.isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$start – $end',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: slot.isActive
                      ? null
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                  decoration: slot.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            Switch.adaptive(
              value: slot.isActive,
              onChanged: (v) =>
                  ref.read(calendarProvider.notifier).toggleAvailability(slot.id, v),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditor(context, slot: slot),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(int id) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Delete Slot',
      message: 'Remove this availability slot?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      ref.read(calendarProvider.notifier).deleteAvailability(id);
      return true;
    }
    return false;
  }

  void _showEditor(BuildContext context, {TrainerAvailabilityModel? slot}) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    if (slot != null) {
      final sp = slot.startTime.split(':');
      startTime = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
      final ep = slot.endTime.split(':');
      endTime = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AvailabilitySlotEditor(
        initialDay: slot?.dayOfWeek,
        initialStart: startTime,
        initialEnd: endTime,
        onSave: (day, start, end) {
          if (slot != null) {
            ref.read(calendarProvider.notifier).updateAvailability(
                  slot.id,
                  dayOfWeek: day,
                  startTime: start,
                  endTime: end,
                );
          } else {
            ref.read(calendarProvider.notifier).createAvailability(
                  dayOfWeek: day,
                  startTime: start,
                  endTime: end,
                );
          }
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No availability set', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first time slot',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeString(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/availability_slot_editor.dart';
import '../widgets/availability_slot_tile.dart';

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
    final dayKeys = grouped.keys.toList();

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
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(calendarProvider.notifier).loadAvailability(),
              child: slots.isEmpty
                  ? _buildEmpty(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dayKeys.length,
                      itemBuilder: (context, index) {
                        final day = dayKeys[index];
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
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildDaySection(
      ThemeData theme, int day, List<TrainerAvailabilityModel> slots) {
    final dayName = day >= 0 && day < calendarDayNames.length
        ? calendarDayNames[day]
        : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            dayName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...slots.map((slot) => Dismissible(
              key: ValueKey(slot.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              confirmDismiss: (_) => _confirmDelete(slot.id),
              child: AvailabilitySlotTile(
                slot: slot,
                onToggle: (v) => ref
                    .read(calendarProvider.notifier)
                    .toggleAvailability(slot.id, v),
                onEdit: () => _showEditor(context, slot: slot),
              ),
            )),
        const SizedBox(height: 8),
      ],
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
      await ref.read(calendarProvider.notifier).deleteAvailability(id);
      final state = ref.read(calendarProvider);
      return state.error == null;
    }
    return false;
  }

  void _showEditor(BuildContext context, {TrainerAvailabilityModel? slot}) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    if (slot != null) {
      final sp = slot.startTime.split(':');
      startTime = TimeOfDay(
        hour: int.tryParse(sp.isNotEmpty ? sp[0] : '') ?? 0,
        minute: int.tryParse(sp.length > 1 ? sp[1] : '') ?? 0,
      );
      final ep = slot.endTime.split(':');
      endTime = TimeOfDay(
        hour: int.tryParse(ep.isNotEmpty ? ep[0] : '') ?? 0,
        minute: int.tryParse(ep.length > 1 ? ep[1] : '') ?? 0,
      );
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('No availability set', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first time slot',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

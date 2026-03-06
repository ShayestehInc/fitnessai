import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../data/models/calendar_connection_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/availability_slot_editor.dart';
import '../widgets/availability_slot_tile.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
        title: Text(context.l10n.calendarAvailability),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () => context.pop(),
          tooltip: context.l10n.calendarBackToCalendarSettings,
        ),
        actions: [
          if (Theme.of(context).platform == TargetPlatform.iOS)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showEditor(context),
              tooltip: context.l10n.calendarAddAvailabilitySlot,
            ),
        ],
      ),
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton(
              onPressed: () => _showEditor(context),
              tooltip: context.l10n.calendarAddAvailabilitySlot,
              child: const Icon(Icons.add),
            ),
      body: state.isLoading && slots.isEmpty
          ? _buildLoadingShimmer()
          : AdaptiveRefreshIndicator(
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
      title: context.l10n.calendarDeleteSlot,
      message: context.l10n.calendarRemoveThisAvailabilitySlot,
      confirmText: context.l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref.read(calendarProvider.notifier).deleteAvailability(id);
      // Check if the slot was actually removed from state rather than
      // checking state.error, which may already be cleared by the listener.
      final currentState = ref.read(calendarProvider);
      final wasDeleted = !currentState.availability.any((a) => a.id == id);
      return wasDeleted;
    }
    return false;
  }

  /// Parses an HH:MM or HH:MM:SS time string into a TimeOfDay, clamping
  /// values to valid ranges. Returns a fallback of midnight for malformed input.
  TimeOfDay _parseTimeString(String time) {
    if (time.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    final parts = time.split(':');
    final hour = (int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0).clamp(0, 23);
    final minute = (int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0).clamp(0, 59);
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _showEditor(BuildContext context, {TrainerAvailabilityModel? slot}) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    if (slot != null) {
      startTime = _parseTimeString(slot.startTime);
      endTime = _parseTimeString(slot.endTime);
    }

    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
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
          child: Semantics(
            label: context.l10n.calendarNoAvailabilitySetTapThePlusButtonToAddYourFir,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    semanticLabel: context.l10n.calendarNoAvailability),
                const SizedBox(height: 16),
                Text(context.l10n.calendarNoAvailabilitySet, style: theme.textTheme.titleMedium),
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
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int day = 0; day < 3; day++) ...[
            const LoadingShimmer(width: 100, height: 16, borderRadius: 4),
            const SizedBox(height: 12),
            for (int slot = 0; slot < 2; slot++) ...[
              const LoadingShimmer(height: 48, borderRadius: 10),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

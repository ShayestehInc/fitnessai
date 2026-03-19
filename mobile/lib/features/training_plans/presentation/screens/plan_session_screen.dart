import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/training_plan_models.dart';
import '../providers/training_plan_provider.dart';
import '../widgets/plan_slot_card.dart';

class PlanSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const PlanSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<PlanSessionScreen> createState() => _PlanSessionScreenState();
}

class _PlanSessionScreenState extends ConsumerState<PlanSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildError(theme, error),
        data: (session) => _buildContent(theme, session),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
            const SizedBox(height: 16),
            Text('Failed to Load Session', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(sessionDetailProvider(widget.sessionId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, PlanSessionModel session) {
    final slots = session.slots ?? [];

    return Column(
      children: [
        Expanded(
          child: slots.isEmpty
              ? _buildEmptySlots(theme)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSessionHeader(theme, session),
                    const SizedBox(height: 16),
                    ...slots.asMap().entries.map((entry) {
                      return PlanSlotCard(
                        slot: entry.value,
                        index: entry.key + 1,
                      );
                    }),
                  ],
                ),
        ),
        _buildStartButton(theme),
      ],
    );
  }

  Widget _buildSessionHeader(ThemeData theme, PlanSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              session.dayName.substring(0, 3),
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.label, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${session.slotCount} exercise${session.slotCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlots(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, color: AppTheme.mutedForeground, size: 48),
            const SizedBox(height: 16),
            Text('No Exercises', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This session does not have any exercises assigned yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to session runner / active workout screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session runner coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Start Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

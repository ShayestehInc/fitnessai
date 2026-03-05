import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../checkins/data/models/checkin_models.dart';
import '../../../checkins/presentation/providers/checkin_provider.dart';

/// Banner displayed when the trainee has pending check-in assignments.
/// Tapping navigates to the first pending check-in form.
class PendingCheckinBanner extends ConsumerWidget {
  const PendingCheckinBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingCheckInsProvider);

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (assignments) {
        if (assignments.isEmpty) return const SizedBox.shrink();
        return _PendingCheckinContent(assignments: assignments);
      },
    );
  }
}

class _PendingCheckinContent extends StatelessWidget {
  final List<CheckInAssignmentModel> assignments;

  const _PendingCheckinContent({required this.assignments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = assignments.length;
    final first = assignments.first;

    return Card(
      color: theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/checkin', extra: first),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.onSecondaryContainer,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? 'You have a pending check-in'
                      : 'You have $count pending check-ins',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/muscle_reference_model.dart';

class MovementsTab extends StatelessWidget {
  final MuscleReferenceModel muscle;

  const MovementsTab({super.key, required this.muscle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (muscle.primaryMovements.isEmpty) {
      return Center(
        child: Text(
          'No movement data available.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (muscle.functionDescription.isNotEmpty) ...[
          Text(muscle.functionDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        Text(
          'Primary Movements',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...muscle.primaryMovements.map(
          (movement) => Card(
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(movement),
            ),
          ),
        ),
      ],
    );
  }
}

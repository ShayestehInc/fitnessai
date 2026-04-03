import 'package:flutter/material.dart';
import '../../../data/models/muscle_reference_model.dart';

class AboutTab extends StatelessWidget {
  final MuscleReferenceModel muscle;

  const AboutTab({super.key, required this.muscle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(muscle.description, style: theme.textTheme.bodyMedium),

        if (muscle.origin.isNotEmpty || muscle.insertion.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Anatomy',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (muscle.origin.isNotEmpty)
            _InfoRow(label: 'Origin', value: muscle.origin),
          if (muscle.insertion.isNotEmpty)
            _InfoRow(label: 'Insertion', value: muscle.insertion),
        ],

        if (muscle.trainingTips.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Training Tips',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(muscle.trainingTips, style: theme.textTheme.bodyMedium),
        ],

        if (muscle.subMuscles.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Sub-Muscles',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...muscle.subMuscles.map(
            (sub) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sub.latinName.isNotEmpty)
                      Text(
                        sub.latinName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (sub.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(sub.description, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

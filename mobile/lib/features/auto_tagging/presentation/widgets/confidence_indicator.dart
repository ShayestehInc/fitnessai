import 'package:flutter/material.dart';
import '../../data/models/auto_tag_model.dart';

class ConfidenceIndicator extends StatelessWidget {
  final AutoTagDraftModel draft;

  const ConfidenceIndicator({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = draft.confidence ?? 0.0;
    final color = _confidenceColor(confidence);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Confidence', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  draft.confidenceLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.lightGreen;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

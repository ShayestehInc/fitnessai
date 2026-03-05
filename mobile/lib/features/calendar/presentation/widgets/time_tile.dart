import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';

/// Tappable time display tile used in the availability slot editor.
class TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const TimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}

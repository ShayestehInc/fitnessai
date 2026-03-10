import 'package:flutter/material.dart';

/// Reusable rating input widget with a label and 1-5 star/slider selector.
class RatingInputWidget extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? description;

  const RatingInputWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value/5',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= value;

            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: isSelected
                      ? _starColor(starValue)
                      : theme.dividerColor,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _starColor(int starValue) {
    if (starValue <= 2) return const Color(0xFFEF4444);
    if (starValue <= 3) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }
}

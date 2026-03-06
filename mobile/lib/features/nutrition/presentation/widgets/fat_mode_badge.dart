import 'package:flutter/material.dart';

class FatModeBadge extends StatelessWidget {
  final String fatMode;
  final bool showTooltip;

  const FatModeBadge({
    super.key,
    required this.fatMode,
    this.showTooltip = true,
  });

  String get _label =>
      fatMode == 'added_fat' ? 'Added Fat' : 'Total Fat';

  String get _tooltipText => fatMode == 'added_fat'
      ? 'Tracking added fats only (oils, butter, dressings). '
        'Naturally occurring fats in protein sources are excluded.'
      : 'Tracking all dietary fat including naturally occurring fats '
        'in meats, dairy, nuts, and added cooking fats.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAddedFat = fatMode == 'added_fat';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isAddedFat
                ? Colors.amber
                : theme.colorScheme.primary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isAddedFat
                  ? Colors.amber
                  : theme.colorScheme.primary)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAddedFat ? Icons.water_drop_outlined : Icons.opacity,
            size: 14,
            color: isAddedFat ? Colors.amber.shade700 : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAddedFat ? Colors.amber.shade700 : theme.colorScheme.primary,
            ),
          ),
          if (showTooltip) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.info_outline,
              size: 12,
              color: (isAddedFat
                      ? Colors.amber.shade700
                      : theme.colorScheme.primary)
                  .withValues(alpha: 0.6),
            ),
          ],
        ],
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: _tooltipText,
      preferBelow: true,
      child: badge,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Filter chips for selecting calendar provider (All / Google / Microsoft).
class CalendarProviderFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const CalendarProviderFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(label: context.l10n.commonAll, selected: selected == null, onTap: () => onChanged(null)),
          const SizedBox(width: 8),
          _Chip(label: context.l10n.authGoogle, selected: selected == 'google', onTap: () => onChanged('google')),
          const SizedBox(width: 8),
          _Chip(label: context.l10n.calendarMicrosoft, selected: selected == 'microsoft', onTap: () => onChanged('microsoft')),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.calendarFilterBylabel,
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? theme.colorScheme.primary : theme.dividerColor,
              ),
            ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.primary : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models/space_model.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Horizontal scrollable list of space filter chips.
class SpaceChipBar extends StatelessWidget {
  final List<SpaceModel> spaces;
  final int? selectedSpaceId;
  final ValueChanged<int?> onSelected;

  const SpaceChipBar({
    super.key,
    required this.spaces,
    required this.selectedSpaceId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selectedSpaceId == null,
              label: Text(context.l10n.commonAll),
              onSelected: (_) => onSelected(null),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: selectedSpaceId == null
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Space chips
          ...spaces.map((space) {
            final isSelected = selectedSpaceId == space.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text('${space.emoji} ${space.name}'),
                onSelected: (_) => onSelected(isSelected ? null : space.id),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

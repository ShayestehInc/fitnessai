import 'package:flutter/material.dart';

/// A category tab definition for the filter bar.
class CategoryTab {
  final String label;
  final String value;

  const CategoryTab({required this.label, required this.value});
}

/// Horizontal scrollable filter chips for photo categories.
class CategoryFilterBar extends StatelessWidget {
  final List<CategoryTab> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const List<CategoryTab> defaultCategories = [
    CategoryTab(label: 'All', value: 'all'),
    CategoryTab(label: 'Front', value: 'front'),
    CategoryTab(label: 'Side', value: 'side'),
    CategoryTab(label: 'Back', value: 'back'),
    CategoryTab(label: 'Other', value: 'other'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.label),
              selected: isSelected,
              onSelected: (_) => onSelected(cat.value),
              backgroundColor: theme.cardColor,
              selectedColor:
                  theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

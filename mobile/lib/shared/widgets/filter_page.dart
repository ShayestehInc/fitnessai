import 'package:flutter/material.dart';

/// A full-page filter/sort screen.
///
/// Use this instead of bottom sheets for filter and sort options.
class FilterPage<T> extends StatefulWidget {
  final String title;
  final List<FilterSection> sections;
  final VoidCallback? onApply;
  final VoidCallback? onReset;

  const FilterPage({
    super.key,
    this.title = 'Filter & Sort',
    required this.sections,
    this.onApply,
    this.onReset,
  });

  @override
  State<FilterPage<T>> createState() => _FilterPageState<T>();
}

class _FilterPageState<T> extends State<FilterPage<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onReset != null)
            TextButton(
              onPressed: () {
                widget.onReset?.call();
                setState(() {});
              },
              child: const Text('Reset'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: widget.sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final section = widget.sections[index];
                return _buildSection(theme, section);
              },
            ),
          ),
          // Apply button
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply?.call();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, FilterSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (section.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            section.subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 12),
        section.content,
      ],
    );
  }
}

/// A section in the filter page.
class FilterSection {
  final String title;
  final String? subtitle;
  final Widget content;

  const FilterSection({
    required this.title,
    this.subtitle,
    required this.content,
  });
}

/// Chip-based multi-select filter widget.
class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool allowMultiple;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowMultiple = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            List<String> newSelected;
            if (allowMultiple) {
              newSelected = List.from(selected);
              if (value) {
                newSelected.add(option);
              } else {
                newSelected.remove(option);
              }
            } else {
              newSelected = value ? [option] : [];
            }
            onChanged(newSelected);
          },
        );
      }).toList(),
    );
  }
}

/// Radio-based single-select filter widget.
class FilterRadioGroup<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  const FilterRadioGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: options.map((option) {
        final isSelected = selected == option.value;
        return InkWell(
          onTap: () => onChanged(option.value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      if (option.description != null)
                        Text(
                          option.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// An option for FilterRadioGroup.
class FilterOption<T> {
  final String label;
  final String? description;
  final T value;

  const FilterOption({
    required this.label,
    this.description,
    required this.value,
  });
}

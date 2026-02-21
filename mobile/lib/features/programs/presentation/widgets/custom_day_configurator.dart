import 'package:flutter/material.dart';

/// Represents a single custom day configuration.
class CustomDayConfig {
  final String dayName;
  final String label;
  final List<String> muscleGroups;

  const CustomDayConfig({
    required this.dayName,
    required this.label,
    required this.muscleGroups,
  });

  CustomDayConfig copyWith({
    String? dayName,
    String? label,
    List<String>? muscleGroups,
  }) {
    return CustomDayConfig(
      dayName: dayName ?? this.dayName,
      label: label ?? this.label,
      muscleGroups: muscleGroups ?? this.muscleGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_name': dayName,
        'label': label,
        'muscle_groups': muscleGroups,
      };
}

const _allMuscleGroups = [
  'chest',
  'back',
  'shoulders',
  'arms',
  'legs',
  'glutes',
  'core',
];

const _muscleGroupLabels = {
  'chest': 'Chest',
  'back': 'Back',
  'shoulders': 'Shoulders',
  'arms': 'Arms',
  'legs': 'Legs',
  'glutes': 'Glutes',
  'core': 'Core',
};

/// Widget for configuring custom split days with muscle groups.
class CustomDayConfigurator extends StatelessWidget {
  final List<CustomDayConfig> days;
  final ValueChanged<List<CustomDayConfig>> onChanged;

  const CustomDayConfigurator({
    super.key,
    required this.days,
    required this.onChanged,
  });

  void _updateDay(int index, CustomDayConfig updated) {
    final newDays = List<CustomDayConfig>.from(days);
    newDays[index] = updated;
    onChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure Each Day',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          return _CustomDayTile(
            dayNumber: index + 1,
            config: day,
            onChanged: (updated) => _updateDay(index, updated),
          );
        }),
      ],
    );
  }
}

class _CustomDayTile extends StatefulWidget {
  final int dayNumber;
  final CustomDayConfig config;
  final ValueChanged<CustomDayConfig> onChanged;

  const _CustomDayTile({
    required this.dayNumber,
    required this.config,
    required this.onChanged,
  });

  @override
  State<_CustomDayTile> createState() => _CustomDayTileState();
}

class _CustomDayTileState extends State<_CustomDayTile> {
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.config.label);
  }

  @override
  void didUpdateWidget(covariant _CustomDayTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.label != widget.config.label &&
        _labelController.text != widget.config.label) {
      _labelController.text = widget.config.label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.dayNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    hintText: 'Day name (e.g. Push Day)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: (value) {
                    widget.onChanged(widget.config.copyWith(label: value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _allMuscleGroups.map((group) {
              final isSelected = widget.config.muscleGroups.contains(group);
              return FilterChip(
                label: Text(
                  _muscleGroupLabels[group] ?? group,
                  style: const TextStyle(fontSize: 12),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final newGroups =
                      List<String>.from(widget.config.muscleGroups);
                  if (selected) {
                    newGroups.add(group);
                  } else {
                    newGroups.remove(group);
                  }
                  widget.onChanged(
                      widget.config.copyWith(muscleGroups: newGroups));
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          if (widget.config.muscleGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Select at least one muscle group',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

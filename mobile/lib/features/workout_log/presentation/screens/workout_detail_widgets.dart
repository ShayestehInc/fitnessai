import 'package:flutter/material.dart';

/// Immutable descriptor for a survey field used by the detail screen.
class SurveyField {
  final String key;
  final String label;

  const SurveyField(this.key, this.label);
}

/// Small stat row shown in the detail header (icon + value).
class HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final ThemeData theme;

  const HeaderStat({
    super.key,
    required this.icon,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Coloured badge showing a survey metric and score.
class SurveyBadge extends StatelessWidget {
  final String label;
  final String value;
  final double score;
  final ThemeData theme;

  const SurveyBadge({
    super.key,
    required this.label,
    required this.value,
    required this.score,
    required this.theme,
  });

  Color get _badgeColor {
    if (score >= 4) return theme.colorScheme.primary;
    if (score >= 3) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: _badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing a single exercise with its sets table.
class ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final ThemeData theme;

  const ExerciseCard({super.key, required this.exercise, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = exercise['exercise_name'] as String? ?? 'Unknown Exercise';
    final sets = exercise['sets'];
    final setsList = sets is List
        ? sets.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (setsList.isNotEmpty) ...[
            Divider(height: 1, color: theme.dividerColor),
            _buildSetsHeader(),
            ...setsList.asMap().entries.map(_buildSetRow),
            const SizedBox(height: 8),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                'No sets recorded',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Set',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Reps',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Weight',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSetRow(MapEntry<int, Map<String, dynamic>> entry) {
    final setData = entry.value;
    final setNumber = setData['set_number'] ?? (entry.key + 1);
    final reps = setData['reps'] ?? 0;
    final weight = setData['weight'];
    final unit = setData['unit'] as String? ?? 'lbs';
    final completed = setData['completed'] as bool? ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$reps',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              weight != null ? '$weight $unit' : '\u2014',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            completed ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: completed
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }
}

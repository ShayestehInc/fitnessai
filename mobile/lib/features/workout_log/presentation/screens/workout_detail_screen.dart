import 'package:flutter/material.dart';
import '../../data/models/workout_history_model.dart';

/// Read-only detail view of a completed workout.
///
/// Receives a [WorkoutHistorySummary] as the navigation extra.
/// Shows: header (name, date, duration), exercise list with sets,
/// readiness survey section, and post-workout survey section.
class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutHistorySummary workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = workout.workoutData;
    final exercises = _extractExercises(data);
    final readinessSurvey = _extractReadinessSurvey(data);
    final postSurvey = _extractPostSurvey(data);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workout.workoutName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            if (readinessSurvey != null) ...[
              _buildSurveySection(
                theme: theme,
                title: 'Pre-Workout',
                icon: Icons.battery_charging_full,
                survey: readinessSurvey,
                fields: const [
                  _SurveyField('sleep', 'Sleep Quality'),
                  _SurveyField('mood', 'Mood'),
                  _SurveyField('energy', 'Energy'),
                  _SurveyField('stress', 'Stress'),
                  _SurveyField('soreness', 'Soreness'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (exercises.isEmpty)
              _buildNoExercisesCard(theme)
            else
              ...exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(exercise: exercise, theme: theme),
                ),
              ),
            if (postSurvey != null) ...[
              const SizedBox(height: 8),
              _buildSurveySection(
                theme: theme,
                title: 'Post-Workout',
                icon: Icons.check_circle_outline,
                survey: postSurvey,
                fields: const [
                  _SurveyField('performance', 'Performance'),
                  _SurveyField('intensity', 'Intensity'),
                  _SurveyField('energy_after', 'Energy After'),
                  _SurveyField('satisfaction', 'Satisfaction'),
                ],
                notesKey: 'notes',
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  workout.formattedDate,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _HeaderStat(
                icon: Icons.timer_outlined,
                value: workout.durationDisplay,
                theme: theme,
              ),
              const SizedBox(height: 4),
              _HeaderStat(
                icon: Icons.fitness_center,
                value: '${workout.exerciseCount} exercises',
                theme: theme,
              ),
              const SizedBox(height: 4),
              _HeaderStat(
                icon: Icons.repeat,
                value: '${workout.totalSets} sets',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoExercisesCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 12),
          Text(
            'No exercise data recorded',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveySection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Map<String, dynamic> survey,
    required List<_SurveyField> fields,
    String? notesKey,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: fields.map((field) {
              final value = survey[field.key];
              if (value == null) return const SizedBox.shrink();
              return _SurveyBadge(
                label: field.label,
                value: '$value/5',
                score: value is num ? value.toDouble() : 0,
                theme: theme,
              );
            }).toList(),
          ),
          if (notesKey != null && survey[notesKey] != null) ...[
            const SizedBox(height: 12),
            Text(
              survey[notesKey].toString(),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractExercises(Map<String, dynamic> data) {
    final exercises = data['exercises'];
    if (exercises is List) {
      return exercises.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Map<String, dynamic>? _extractReadinessSurvey(Map<String, dynamic> data) {
    // Check top-level
    final topLevel = data['readiness_survey'];
    if (topLevel is Map<String, dynamic> && topLevel.isNotEmpty) {
      // Might be the raw survey_data wrapper
      if (topLevel.containsKey('survey_data') &&
          topLevel['survey_data'] is Map<String, dynamic>) {
        return topLevel['survey_data'] as Map<String, dynamic>;
      }
      return topLevel;
    }
    // Check first session
    final sessions = data['sessions'];
    if (sessions is List && sessions.isNotEmpty) {
      final firstSession = sessions[0];
      if (firstSession is Map<String, dynamic>) {
        final sessionSurvey = firstSession['readiness_survey'];
        if (sessionSurvey is Map<String, dynamic> &&
            sessionSurvey.isNotEmpty) {
          if (sessionSurvey.containsKey('survey_data') &&
              sessionSurvey['survey_data'] is Map<String, dynamic>) {
            return sessionSurvey['survey_data'] as Map<String, dynamic>;
          }
          return sessionSurvey;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractPostSurvey(Map<String, dynamic> data) {
    // Check top-level
    final topLevel = data['post_survey'];
    if (topLevel is Map<String, dynamic> && topLevel.isNotEmpty) {
      return topLevel;
    }
    // Check first session
    final sessions = data['sessions'];
    if (sessions is List && sessions.isNotEmpty) {
      final firstSession = sessions[0];
      if (firstSession is Map<String, dynamic>) {
        final sessionSurvey = firstSession['post_survey'];
        if (sessionSurvey is Map<String, dynamic> &&
            sessionSurvey.isNotEmpty) {
          return sessionSurvey;
        }
      }
    }
    return null;
  }
}

class _SurveyField {
  final String key;
  final String label;

  const _SurveyField(this.key, this.label);
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final ThemeData theme;

  const _HeaderStat({
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

class _SurveyBadge extends StatelessWidget {
  final String label;
  final String value;
  final double score;
  final ThemeData theme;

  const _SurveyBadge({
    required this.label,
    required this.value,
    required this.score,
    required this.theme,
  });

  Color get _badgeColor {
    if (score >= 4) return const Color(0xFF22C55E);
    if (score >= 3) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final ThemeData theme;

  const _ExerciseCard({required this.exercise, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = exercise['exercise_name'] as String? ?? 'Unknown Exercise';
    final sets = exercise['sets'];
    final setsList =
        sets is List ? sets.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name header
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
            // Sets table header
            Padding(
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
            ),
            // Set rows
            ...setsList.asMap().entries.map((entry) {
              final setData = entry.value;
              final setNumber = setData['set_number'] ?? (entry.key + 1);
              final reps = setData['reps'] ?? 0;
              final weight = setData['weight'];
              final unit = setData['unit'] as String? ?? 'lbs';
              final completed = setData['completed'] as bool? ?? true;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        weight != null ? '$weight $unit' : '—',
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
                          ? const Color(0xFF22C55E)
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              );
            }),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/repositories/workout_repository.dart';
import 'workout_detail_widgets.dart';

/// Read-only detail view of a completed workout.
///
/// Receives a [WorkoutHistorySummary] for header info plus fetches
/// full workout_data from the API by log ID.
class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final WorkoutHistorySummary workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  Map<String, dynamic>? _workoutData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final apiClient = ref.read(apiClientProvider);
    final repo = WorkoutRepository(apiClient);
    final result = await repo.getWorkoutDetail(widget.workout.id);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _workoutData = data['workout_data'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] as String? ?? 'Failed to load workout detail';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;

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
      body: _buildBody(theme, workout),
    );
  }

  Widget _buildBody(ThemeData theme, WorkoutHistorySummary workout) {
    if (_isLoading) {
      return _buildDetailShimmer(theme, workout);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    final data = _workoutData ?? {};
    final detail = WorkoutDetailData.fromWorkoutData(data);
    final exercises = detail.exercises;
    final readinessSurvey = detail.readinessSurvey;
    final postSurvey = detail.postSurvey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, workout),
          const SizedBox(height: 24),
          if (readinessSurvey != null) ...[
            _buildSurveySection(
              theme: theme,
              title: 'Pre-Workout',
              icon: Icons.battery_charging_full,
              survey: readinessSurvey,
              fields: const [
                SurveyField('sleep', 'Sleep Quality'),
                SurveyField('mood', 'Mood'),
                SurveyField('energy', 'Energy'),
                SurveyField('stress', 'Stress'),
                SurveyField('soreness', 'Soreness'),
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
                child: ExerciseCard(exercise: exercise, theme: theme),
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
                SurveyField('performance', 'Performance'),
                SurveyField('intensity', 'Intensity'),
                SurveyField('energy_after', 'Energy After'),
                SurveyField('satisfaction', 'Satisfaction'),
              ],
              notesKey: 'notes',
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Skeleton loading that shows the real header (summary data is already
  /// available) plus placeholder exercise cards matching the expected count.
  Widget _buildDetailShimmer(
    ThemeData theme,
    WorkoutHistorySummary workout,
  ) {
    final cardCount = workout.exerciseCount.clamp(1, 5);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, workout),
          const SizedBox(height: 24),
          ...List.generate(
            cardCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
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
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 150,
                            height: 14,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Semantics(
          liveRegion: true,
          label: 'Error: ${_error!}',
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load workout details',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchDetail();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, WorkoutHistorySummary workout) {
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
              HeaderStat(
                icon: Icons.timer_outlined,
                value: workout.durationDisplay,
                theme: theme,
              ),
              const SizedBox(height: 4),
              HeaderStat(
                icon: Icons.fitness_center,
                value: '${workout.exerciseCount} exercises',
                theme: theme,
              ),
              const SizedBox(height: 4),
              HeaderStat(
                icon: Icons.repeat,
                value: '${workout.totalSets} sets',
                theme: theme,
              ),
              if (workout.totalVolumeLbs > 0) ...[
                const SizedBox(height: 4),
                HeaderStat(
                  icon: Icons.monitor_weight_outlined,
                  value: workout.formattedVolume,
                  theme: theme,
                ),
              ],
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
    required List<SurveyField> fields,
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
              return SurveyBadge(
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

}

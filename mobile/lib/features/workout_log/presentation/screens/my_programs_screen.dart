import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/workout_models.dart';
import '../providers/workout_provider.dart';

class MyProgramsScreen extends ConsumerWidget {
  const MyProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(workoutStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(context.l10n.workoutMyPrograms),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.programs.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.programs.length,
              itemBuilder: (context, index) {
                final program = state.programs[index];
                return _ProgramCard(
                  program: program,
                  isActive: state.activeProgram?.id == program.id,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No programs yet',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trainer will assign you a program soon',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final ProgramModel program;
  final bool isActive;

  const _ProgramCard({
    required this.program,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final weekNum = program.currentWeekNumber;
    final totalWeeks = program.durationWeeks ?? 0;
    final progress = totalWeeks > 0 ? (weekNum / totalWeeks).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/logbook'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.zinc800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: isActive ? AppTheme.primary : AppTheme.zinc400,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            color: AppTheme.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (program.goalDisplay.isNotEmpty) ...[
                              _MetaPill(program.goalDisplay),
                              const SizedBox(width: 6),
                            ],
                            _MetaPill(program.difficultyDisplay),
                            if (totalWeeks > 0) ...[
                              const SizedBox(width: 6),
                              _MetaPill('$totalWeeks weeks'),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (isActive && totalWeeks > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.zinc700,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Week $weekNum of $totalWeeks',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
              if (!isActive) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDateRange(program.startDate, program.endDate),
                  style: const TextStyle(fontSize: 12, color: AppTheme.zinc400),
                ),
              ],
              if (program.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  program.description,
                  style: const TextStyle(fontSize: 13, color: AppTheme.zinc400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
    } catch (_) {
      return '$startDate - $endDate';
    }
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  const _MetaPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.zinc300),
      ),
    );
  }
}

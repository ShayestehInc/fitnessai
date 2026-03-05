import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_check_tile.dart';

/// The trainee-facing daily habit checklist screen.
///
/// Shows today's habits with completion checkboxes, a progress bar at the top,
/// and streak summaries.
class HabitChecklistScreen extends ConsumerStatefulWidget {
  const HabitChecklistScreen({super.key});

  @override
  ConsumerState<HabitChecklistScreen> createState() =>
      _HabitChecklistScreenState();
}

class _HabitChecklistScreenState extends ConsumerState<HabitChecklistScreen> {
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyHabitsAsync = ref.watch(dailyHabitsProvider(_selectedDate));
    final streaksAsync = ref.watch(habitStreaksProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Daily Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => _pickDate(context),
            tooltip: 'Pick date',
          ),
        ],
      ),
      body: dailyHabitsAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error.toString()),
        data: (dailyHabits) {
          if (dailyHabits.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Build a streak lookup: habitId -> currentStreak
          final streakMap = <int, int>{};
          streaksAsync.whenData((streaks) {
            for (final s in streaks) {
              streakMap[s.habitId] = s.currentStreak;
            }
          });

          final completedCount =
              dailyHabits.where((h) => h.completed).length;
          final totalCount = dailyHabits.length;
          final progress =
              totalCount > 0 ? completedCount / totalCount : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyHabitsProvider(_selectedDate));
              ref.invalidate(habitStreaksProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              children: [
                // Date label
                _buildDateLabel(theme),
                const SizedBox(height: 16),

                // Progress card
                _buildProgressCard(
                  theme,
                  completedCount,
                  totalCount,
                  progress,
                ),
                const SizedBox(height: 20),

                // Habit list
                ...dailyHabits.map(
                  (habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HabitCheckTile(
                      habit: habit,
                      currentStreak: streakMap[habit.habitId] ?? 0,
                      onToggle: () => _onToggle(habit),
                    ),
                  ),
                ),

                // Completion celebration
                if (completedCount == totalCount && totalCount > 0)
                  _buildCompletionBanner(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateLabel(ThemeData theme) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = _selectedDate == today;
    final parsed = DateFormat('yyyy-MM-dd').parse(_selectedDate);
    final formatted = DateFormat('EEEE, MMM d').format(parsed);

    return Text(
      isToday ? 'Today - $formatted' : formatted,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodySmall?.color,
      ),
    );
  }

  Widget _buildProgressCard(
    ThemeData theme,
    int completed,
    int total,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All habits completed! Great work today.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No habits scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trainer hasn\'t assigned any habits for this day yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load habits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(dailyHabitsProvider(_selectedDate));
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggle(DailyHabitModel habit) async {
    HapticService.lightTap();

    final success = await ref.read(toggleHabitProvider.notifier).toggle(
          habitId: habit.habitId,
          date: _selectedDate,
        );

    if (!mounted) return;

    if (success) {
      HapticService.success();
    } else {
      showAdaptiveToast(
        context,
        message: 'Failed to update habit',
        type: ToastType.error,
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('yyyy-MM-dd').parse(_selectedDate),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
}

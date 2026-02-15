import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout_log/data/models/workout_history_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeStateProvider.notifier).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(homeStateProvider.notifier).loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(user?.displayName ?? 'User'),
                  const SizedBox(height: 24),

                  // Nutrition section
                  _buildSectionHeader('Nutrition'),
                  const SizedBox(height: 16),
                  _buildNutritionSection(homeState),
                  const SizedBox(height: 32),

                  // Weekly Progress section (only if trainee has a program)
                  if (homeState.weeklyProgress case final progress?
                      when progress.hasProgram) ...[
                    _buildSectionHeader('Weekly Progress'),
                    const SizedBox(height: 16),
                    _buildWeeklyProgressSection(homeState),
                    const SizedBox(height: 32),
                  ],

                  // Current Program section
                  _buildSectionHeader('Current Program', showAction: true, actionLabel: 'View', onAction: () => context.push('/logbook')),
                  const SizedBox(height: 16),
                  _buildCurrentProgramSection(homeState),
                  const SizedBox(height: 32),

                  // Next Workout section
                  if (homeState.nextWorkout != null) ...[
                    _buildSectionHeader('Next Workout'),
                    const SizedBox(height: 16),
                    _buildNextWorkoutSection(homeState),
                    const SizedBox(height: 32),
                  ],

                  // Recent Workouts section
                  _buildSectionHeader(
                    'Recent Workouts',
                    showAction: homeState.recentWorkouts.isNotEmpty,
                    onAction: () => context.push('/workout-history'),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentWorkoutsSection(homeState),
                  const SizedBox(height: 32),

                  // Latest Videos section
                  if (homeState.latestVideos.isNotEmpty) ...[
                    _buildSectionHeader('Latest'),
                    const SizedBox(height: 16),
                    _buildLatestVideosSection(homeState),
                  ],

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-command'),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.mic),
        label: const Text('Log'),
      ),
    );
  }

  Widget _buildHeader(String name) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final trainer = user?.trainer;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trainer != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: trainer.profileImage != null
                        ? NetworkImage(trainer.profileImage!)
                        : null,
                    child: trainer.profileImage == null
                        ? Text(
                            (trainer.firstName?.isNotEmpty == true
                                    ? trainer.firstName![0]
                                    : trainer.email[0])
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coached by ${trainer.firstName ?? trainer.email.split('@').first}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Notifications'),
                    content: const Text(
                      'Notifications are coming soon! You\'ll be able to see updates from your trainer here.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              color: theme.textTheme.bodySmall?.color,
            ),
            PopupMenuButton(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: user?.profileImage != null
                    ? NetworkImage(user!.profileImage!)
                    : null,
                child: user?.profileImage == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              color: theme.cardColor,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: theme.textTheme.bodyLarge?.color),
                      const SizedBox(width: 8),
                      Text('Settings',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      context.push('/settings');
                    });
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Logout',
                          style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool showAction = false,
    String actionLabel = 'See All',
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: theme.dividerColor,
          ),
        ),
        if (showAction) ...[
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: '$actionLabel $title',
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNutritionSection(HomeState state) {
    return Column(
      children: [
        // Large calorie circle
        Center(
          child: _CalorieRing(
            remaining: state.caloriesRemaining,
            total: state.caloriesGoal,
            consumed: state.caloriesConsumed,
          ),
        ),
        const SizedBox(height: 24),
        // Macro circles row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MacroCircle(
              label: 'Protein',
              current: state.proteinConsumed,
              goal: state.proteinGoal,
              progress: state.proteinProgress,
              color: const Color(0xFFDC2626), // Red
            ),
            _MacroCircle(
              label: 'Carbs',
              current: state.carbsConsumed,
              goal: state.carbsGoal,
              progress: state.carbsProgress,
              color: const Color(0xFF22C55E), // Green
            ),
            _MacroCircle(
              label: 'Fat',
              current: state.fatConsumed,
              goal: state.fatGoal,
              progress: state.fatProgress,
              color: const Color(0xFF3B82F6), // Blue
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressSection(HomeState state) {
    final theme = Theme.of(context);
    final progress = state.weeklyProgress;
    if (progress == null) return const SizedBox.shrink();

    final percentage = progress.percentage;
    final completed = progress.completedDays;
    final total = progress.totalDays;

    String message;
    if (completed == 0) {
      message = 'Start your first workout!';
    } else if (percentage >= 100) {
      message = 'Week complete — great job!';
    } else {
      message = '$completed of $total workout days completed';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage / 100),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProgramSection(HomeState state) {
    final theme = Theme.of(context);
    final program = state.activeProgram;

    if (program == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.fitness_center, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text(
              'No active program',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your trainer to get started',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program name and progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                program.name,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${state.programProgress}%',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: state.programProgress / 100,
            minHeight: 8,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        // View Programs button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/logbook'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('View Programs'),
          ),
        ),
      ],
    );
  }

  Widget _buildNextWorkoutSection(HomeState state) {
    final theme = Theme.of(context);
    final nextWorkout = state.nextWorkout!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
      ),
      child: Row(
        children: [
          // Workout image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          theme.cardColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Workout details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week ${nextWorkout.weekNumber}',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextWorkout.dayName.toUpperCase(),
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/logbook'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    child: const Text('Overview'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutsSection(HomeState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.recentWorkouts.isEmpty) {
      // Shimmer placeholders matching 3-card layout
      return Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state.recentWorkoutsError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.recentWorkoutsError!,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ref.read(homeStateProvider.notifier).loadDashboardData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.recentWorkouts.isEmpty) {
      return Text(
        'No workouts yet. Complete your first workout to see it here.',
        style: TextStyle(
          color: theme.textTheme.bodySmall?.color,
          fontSize: 13,
        ),
      );
    }

    return Column(
      children: state.recentWorkouts.map((workout) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RecentWorkoutCard(
            workout: workout,
            onTap: () => context.push('/workout-detail', extra: workout),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLatestVideosSection(HomeState state) {
    return Column(
      children: state.latestVideos.map((video) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _VideoCard(video: video),
      )).toList(),
    );
  }
}

/// Large calorie ring showing remaining calories
class _CalorieRing extends StatelessWidget {
  final int remaining;
  final int total;
  final int consumed;

  const _CalorieRing({
    required this.remaining,
    required this.total,
    required this.consumed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? (consumed / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.dividerColor),
            ),
          ),
          // Progress ring
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                remaining.toString(),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Calories',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
              Text(
                'remaining',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Macro progress circle (Protein, Carbs, Fat)
class _MacroCircle extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final double progress;
  final Color color;

  const _MacroCircle({
    required this.label,
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).clamp(0, 100).round();

    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.dividerColor),
                ),
              ),
              // Progress ring
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Percentage text
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
        Text(
          '${goal}g',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Video card for Latest Videos section
class _VideoCard extends StatelessWidget {
  final VideoItem video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video thumbnail with play button
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              // Play button overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Video info row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.date,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Like button and count
            Row(
              children: [
                Icon(
                  video.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: video.isLiked ? Colors.red : theme.textTheme.bodySmall?.color,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${video.likes}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact workout card for the home screen "Recent Workouts" section.
class _RecentWorkoutCard extends StatelessWidget {
  final WorkoutHistorySummary workout;
  final VoidCallback onTap;

  const _RecentWorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label:
          '${workout.workoutName}, ${workout.formattedDate}, ${workout.exerciseCount} exercises',
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
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
                        workout.formattedDate,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workout.workoutName,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${workout.exerciseCount} exercises',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

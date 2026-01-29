import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/presentation/widgets/macro_progress_circle.dart';
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
                  const SizedBox(height: 32),

                  // Calorie circle
                  _buildCalorieSection(homeState),
                  const SizedBox(height: 32),

                  // Macro progress
                  _buildMacroSection(homeState),
                  const SizedBox(height: 32),

                  // Program card
                  _buildProgramCard(homeState),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(),
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
                // TODO: Notifications
              },
              icon: const Icon(Icons.notifications_outlined),
              color: theme.textTheme.bodySmall?.color,
            ),
            PopupMenuButton(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                    // Delay to allow popup to close
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

  Widget _buildCalorieSection(HomeState state) {
    return Center(
      child: CalorieProgressCircle(
        consumed: state.caloriesConsumed,
        goal: state.caloriesGoal,
        size: 200,
      ),
    );
  }

  Widget _buildMacroSection(HomeState state) {
    final goals = state.nutritionGoals;
    final consumed = state.todayNutrition?.consumed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MiniMacroCircle(
          label: 'Protein',
          current: consumed?.protein ?? 0,
          goal: goals?.proteinGoal ?? 0,
          color: const Color(0xFFEC4899),
        ),
        _MiniMacroCircle(
          label: 'Carbs',
          current: consumed?.carbs ?? 0,
          goal: goals?.carbsGoal ?? 0,
          color: const Color(0xFF22C55E),
        ),
        _MiniMacroCircle(
          label: 'Fat',
          current: consumed?.fat ?? 0,
          goal: goals?.fatGoal ?? 0,
          color: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildProgramCard(HomeState state) {
    final theme = Theme.of(context);
    final program = state.activeProgram;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Current Program',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (program != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            program?.name ?? 'No active program',
            style: TextStyle(
              color: program != null ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (program != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.35, // TODO: Calculate actual progress
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '35% complete',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/logbook'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              child: const Text('View Programs'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.restaurant,
                label: 'Log Food',
                onTap: () => context.push('/add-food'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.fitness_center,
                label: 'Log Workout',
                onTap: () => context.push('/ai-command'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.scale,
                label: 'Check In',
                onTap: () => context.push('/weight-checkin'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMacroCircle extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final Color color;

  const _MiniMacroCircle({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  double get progress {
    if (goal == 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$current / $goal g',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

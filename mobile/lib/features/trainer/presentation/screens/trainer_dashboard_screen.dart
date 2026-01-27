import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/trainee_card.dart';

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(trainerStatsProvider);
    final traineesAsync = ref.watch(traineesProvider);
    final impersonation = ref.watch(impersonationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () => context.push('/trainer/ai-chat'),
            tooltip: 'AI Assistant',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/trainer/invite'),
            tooltip: 'Invite Trainee',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: impersonation.isImpersonating
          ? _buildImpersonationBanner(context, ref, impersonation)
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(trainerStatsProvider);
                ref.invalidate(traineesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    statsAsync.when(
                      data: (stats) => stats != null
                          ? QuickStatsGrid(stats: stats)
                          : const SizedBox(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Recent Trainees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Trainees',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => context.push('/trainer/trainees'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    traineesAsync.when(
                      data: (trainees) {
                        if (trainees.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trainees.length.clamp(0, 5),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return TraineeCard(
                              trainee: trainees[index],
                              onTap: () => context.push(
                                '/trainer/trainees/${trainees[index].id}',
                              ),
                              onLoginAs: () => _startImpersonation(
                                context,
                                ref,
                                trainees[index].id,
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trainer/invite'),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite'),
      ),
    );
  }

  Widget _buildImpersonationBanner(
    BuildContext context,
    WidgetRef ref,
    ImpersonationState state,
  ) {
    return Column(
      children: [
        Container(
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Viewing as Trainee',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.trainee?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (state.session?.isReadOnly ?? true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'READ ONLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _endImpersonation(context, ref),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Viewing ${state.trainee?.firstName ?? state.trainee?.email ?? "Trainee"}\'s Experience',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Navigate to see what your trainee sees',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Trainee Home'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.group_add,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Trainees Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite your first trainee to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/trainer/invite'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Trainee'),
            ),
          ],
        ),
      ),
    );
  }

  void _startImpersonation(BuildContext context, WidgetRef ref, int traineeId) async {
    final result = await ref.read(impersonationProvider.notifier).startImpersonation(traineeId);

    if (!result['success']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to start session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (context.mounted) {
      // Navigate directly to trainee home
      context.go('/home');
    }
  }

  void _endImpersonation(BuildContext context, WidgetRef ref) async {
    await ref.read(impersonationProvider.notifier).endImpersonation();
    ref.invalidate(trainerStatsProvider);
    ref.invalidate(traineesProvider);
  }
}

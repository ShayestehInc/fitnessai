import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_badge.dart';

/// Full-screen achievement / badge grid.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementProvider.notifier).loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(achievementProvider.notifier).loadAchievements();
        },
        child: _buildBody(theme, state),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AchievementState state) {
    if (state.isLoading && state.achievements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(state.error!, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(achievementProvider.notifier).loadAchievements(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'No achievements available',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary
          _buildProgressSummary(theme, state),
          const SizedBox(height: 24),
          // Badge grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: state.achievements.length,
            itemBuilder: (context, index) {
              return AchievementBadge(
                achievement: state.achievements[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(ThemeData theme, AchievementState state) {
    final earned = state.earnedCount;
    final total = state.totalCount;
    final progress = total > 0 ? earned / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$earned of $total earned',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
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
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

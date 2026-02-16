import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/repositories/community_feed_repository.dart';

/// Leaderboard screen showing rankings by metric and time period.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _metricType = 'workout_count';
  String _timePeriod = 'weekly';
  LeaderboardResponse? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final repo = CommunityFeedRepository(apiClient);
      final data = await repo.getLeaderboard(
        metricType: _metricType,
        timePeriod: _timePeriod,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load leaderboard';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(theme),
          const Divider(height: 1),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildMetricSelector(theme)),
          const SizedBox(width: 12),
          Expanded(child: _buildPeriodSelector(theme)),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _metricType,
      decoration: InputDecoration(
        labelText: 'Metric',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'workout_count', child: Text('Workouts')),
        DropdownMenuItem(value: 'current_streak', child: Text('Streak')),
      ],
      onChanged: (val) {
        if (val != null && val != _metricType) {
          setState(() => _metricType = val);
          _loadLeaderboard();
        }
      },
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _timePeriod,
      decoration: InputDecoration(
        labelText: 'Period',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'weekly', child: Text('This Week')),
        DropdownMenuItem(value: 'monthly', child: Text('This Month')),
      ],
      onChanged: (val) {
        if (val != null && val != _timePeriod) {
          setState(() => _timePeriod = val);
          _loadLeaderboard();
        }
      },
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _LeaderboardSkeleton(theme: theme);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = _data;
    if (data == null || !data.enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.leaderboard_outlined,
                  size: 64, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text(
                'Leaderboard not available',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your trainer has not enabled the leaderboard yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (data.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 64, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text(
                'No rankings yet',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete workouts to appear on the leaderboard!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: data.entries.length + (data.myRank != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Show "Your rank" card at the end if user has a rank
          if (index == data.entries.length && data.myRank != null) {
            return _buildMyRankCard(theme, data.myRank!);
          }
          return _LeaderboardTile(
            entry: data.entries[index],
            metricType: _metricType,
          );
        },
      ),
    );
  }

  Widget _buildMyRankCard(ThemeData theme, int myRank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Your rank: #$myRank',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single leaderboard entry tile.
class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final String metricType;

  const _LeaderboardTile({required this.entry, required this.metricType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopThree = entry.rank <= 3;

    return Semantics(
      label: 'Rank ${entry.rank}, ${entry.displayName}, ${_formatValue(entry.value)}',
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isTopThree
            ? _rankColor(entry.rank).withValues(alpha: 0.06)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: isTopThree
            ? Border.all(color: _rankColor(entry.rank).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTopThree
                ? Icon(_rankIcon(entry.rank),
                    color: _rankColor(entry.rank), size: 24)
                : Text(
                    '#${entry.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: entry.profileImage != null
                ? NetworkImage(entry.profileImage!)
                : null,
            child: entry.profileImage == null
                ? Text(
                    entry.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              entry.displayName,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: isTopThree ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Value
          Text(
            _formatValue(entry.value),
            style: TextStyle(
              color: isTopThree
                  ? _rankColor(entry.rank)
                  : theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return Colors.grey;
    }
  }

  IconData _rankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.workspace_premium;
      case 3:
        return Icons.military_tech;
      default:
        return Icons.tag;
    }
  }

  String _formatValue(int value) {
    if (metricType == 'current_streak') {
      return '${value}d';
    }
    return '$value';
  }
}

/// Skeleton loading placeholder for the leaderboard.
class _LeaderboardSkeleton extends StatelessWidget {
  final ThemeData theme;

  const _LeaderboardSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _skeletonBox(36, 16),
              const SizedBox(width: 10),
              _skeletonCircle(36),
              const SizedBox(width: 10),
              Expanded(child: _skeletonBox(double.infinity, 14)),
              _skeletonBox(30, 16),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _skeletonCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}

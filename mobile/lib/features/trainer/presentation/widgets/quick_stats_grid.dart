import 'package:flutter/material.dart';
import '../../data/models/trainer_stats_model.dart';

class QuickStatsGrid extends StatelessWidget {
  final TrainerStatsModel stats;

  const QuickStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          title: 'Total Trainees',
          value: '${stats.totalTrainees}',
          subtitle: stats.maxTrainees > 0
              ? 'of ${stats.maxTrainees} max'
              : 'unlimited',
          icon: Icons.group,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Active Today',
          value: '${stats.traineesLoggedToday}',
          subtitle: 'logged activity',
          icon: Icons.today,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'On Track',
          value: '${stats.traineesOnTrack}',
          subtitle: 'hitting goals',
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Adherence',
          value: '${stats.avgAdherenceRate.toStringAsFixed(0)}%',
          subtitle: 'avg rate',
          icon: Icons.check_circle,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

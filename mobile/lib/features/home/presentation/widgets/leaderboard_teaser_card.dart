import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../constants/dashboard_colors.dart';

/// Compact teaser card linking to the community leaderboard.
class LeaderboardTeaserCard extends StatelessWidget {
  const LeaderboardTeaserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/community/leaderboard'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events, color: DashboardColors.trophy, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Leaderboard — See where you rank',
                style: TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models/retention_model.dart';
import 'engagement_indicator.dart';
import 'risk_tier_badge.dart';

/// ListTile for an at-risk trainee with engagement bar and risk badge.
class AtRiskTraineeTile extends StatelessWidget {
  final TraineeEngagementModel trainee;
  final VoidCallback? onTap;

  const AtRiskTraineeTile({
    super.key,
    required this.trainee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainee.traineeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastActiveText(trainee.daysSinceLastActivity),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Engagement bar
              EngagementIndicator(value: trainee.engagementScore),
              const SizedBox(width: 12),
              // Risk badge
              RiskTierBadge(tier: trainee.riskTier),
            ],
          ),
        ),
      ),
    );
  }

  static String _lastActiveText(int? days) {
    if (days == null) return 'Never active';
    if (days == 0) return 'Active today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }
}

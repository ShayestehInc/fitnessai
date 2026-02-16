import 'package:flutter/material.dart';
import '../../../ambassador/data/models/ambassador_models.dart';

/// Displays the ambassador's profile header: avatar, name, email, status, and code.
class AmbassadorProfileCard extends StatelessWidget {
  final AmbassadorProfile profile;

  const AmbassadorProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: profile.isActive
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            child: Icon(
              Icons.handshake,
              color: profile.isActive ? Colors.teal : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.user.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.user.email,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: profile.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profile.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: profile.isActive ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Code: ${profile.referralCode}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of three stat tiles showing referrals, earnings, and commission rate.
class AmbassadorStatsRow extends StatelessWidget {
  final AmbassadorProfile profile;
  final VoidCallback? onRateTap;

  const AmbassadorStatsRow({
    super.key,
    required this.profile,
    this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatTile(label: 'Referrals', value: profile.totalReferrals.toString(), color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(label: 'Earnings', value: '\$${profile.totalEarnings}', color: Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onRateTap,
            child: _StatTile(
              label: 'Rate',
              value: '${profile.commissionPercent.toStringAsFixed(0)}%',
              color: Colors.purple,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

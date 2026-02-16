import 'package:flutter/material.dart';
import '../../../ambassador/data/models/ambassador_models.dart';

/// Displays a section header and list of ambassador referrals.
///
/// Shows an empty state when [referrals] is empty.
class AmbassadorReferralsList extends StatelessWidget {
  final List<AmbassadorReferral> referrals;

  const AmbassadorReferralsList({super.key, required this.referrals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referrals (${referrals.length})',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No referrals yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ...referrals.map((r) => _ReferralTile(referral: r)),
      ],
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final AmbassadorReferral referral;

  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (referral.status) {
      'ACTIVE' => Colors.green,
      'PENDING' => Colors.orange,
      'CHURNED' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.trainer.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${referral.trainerSubscriptionTier} tier',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${referral.totalCommissionEarned}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              referral.status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

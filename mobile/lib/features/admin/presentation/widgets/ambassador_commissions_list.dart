import 'package:flutter/material.dart';
import '../../../ambassador/data/models/ambassador_models.dart';

/// Displays a section header with bulk action buttons and a list of commissions.
///
/// Shows an empty state when [commissions] is empty.
/// Individual commission actions (approve / mark paid) are exposed via callbacks.
class AmbassadorCommissionsList extends StatelessWidget {
  final List<AmbassadorCommission> commissions;
  final Set<int> processingIds;
  final bool isBulkProcessing;
  final VoidCallback? onBulkApprove;
  final VoidCallback? onBulkPay;
  final ValueChanged<AmbassadorCommission> onApprove;
  final ValueChanged<AmbassadorCommission> onPay;

  const AmbassadorCommissionsList({
    super.key,
    required this.commissions,
    required this.processingIds,
    required this.isBulkProcessing,
    this.onBulkApprove,
    this.onBulkPay,
    required this.onApprove,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPending = commissions.any((c) => c.status == 'PENDING');
    final hasApproved = commissions.any((c) => c.status == 'APPROVED');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Commission History (${commissions.length})',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isBulkProcessing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              if (hasPending)
                TextButton.icon(
                  onPressed: onBulkApprove,
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    'Approve All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (hasApproved)
                TextButton.icon(
                  onPressed: onBulkPay,
                  icon: const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: Colors.green,
                  ),
                  label: const Text(
                    'Pay All',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (commissions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No commissions yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ...commissions.map(
            (c) => _CommissionTile(
              commission: c,
              isProcessing: processingIds.contains(c.id) || isBulkProcessing,
              onApprove: () => onApprove(c),
              onPay: () => onPay(c),
            ),
          ),
      ],
    );
  }
}

class _CommissionTile extends StatelessWidget {
  final AmbassadorCommission commission;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onPay;

  const _CommissionTile({
    required this.commission,
    required this.isProcessing,
    required this.onApprove,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (commission.status) {
      'PAID' => Colors.green,
      'APPROVED' => Colors.blue,
      'PENDING' => Colors.orange,
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
                  commission.trainerEmail,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${commission.periodStart} - ${commission.periodEnd}',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${commission.commissionAmount}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'of \$${commission.baseAmount}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              commission.status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          if (commission.status == 'PENDING' || commission.status == 'APPROVED') ...[
            const SizedBox(width: 8),
            _buildActionButton(isProcessing),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isProcessing) {
    if (isProcessing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (commission.status == 'PENDING') {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: onApprove,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Approve',
            style: TextStyle(color: Colors.blue, fontSize: 11),
          ),
        ),
      );
    }

    if (commission.status == 'APPROVED') {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: onPay,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Mark Paid',
            style: TextStyle(color: Colors.green, fontSize: 11),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

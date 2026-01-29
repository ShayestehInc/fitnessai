import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';

class AdminSubscriptionDetailScreen extends ConsumerStatefulWidget {
  final int subscriptionId;

  const AdminSubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  ConsumerState<AdminSubscriptionDetailScreen> createState() =>
      _AdminSubscriptionDetailScreenState();
}

class _AdminSubscriptionDetailScreenState
    extends ConsumerState<AdminSubscriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
          .loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminSubscriptionDetailProvider(widget.subscriptionId));
    final sub = state.subscription;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Subscription Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (sub != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value, sub),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'change_tier', child: Text('Change Tier')),
                const PopupMenuItem(value: 'change_status', child: Text('Change Status')),
                const PopupMenuItem(value: 'record_payment', child: Text('Record Payment')),
                const PopupMenuItem(value: 'edit_notes', child: Text('Edit Notes')),
              ],
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sub == null
              ? const Center(child: Text('Subscription not found'))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                      .loadSubscription(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trainer info card
                        _buildTrainerCard(context, sub),
                        const SizedBox(height: 16),

                        // Subscription status card
                        _buildSubscriptionCard(context, sub),
                        const SizedBox(height: 16),

                        // Payment info card
                        _buildPaymentCard(context, sub),
                        const SizedBox(height: 16),

                        // Admin notes
                        _buildNotesCard(context, sub),
                        const SizedBox(height: 16),

                        // Quick actions
                        _buildQuickActions(context, sub),
                        const SizedBox(height: 24),

                        // Recent payments
                        if (sub.recentPayments.isNotEmpty) ...[
                          _buildRecentPayments(context, sub),
                          const SizedBox(height: 24),
                        ],

                        // Change history
                        if (sub.recentChanges.isNotEmpty) ...[
                          _buildChangeHistory(context, sub),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTrainerCard(BuildContext context, AdminSubscription sub) {
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
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              (sub.trainerName.isNotEmpty ? sub.trainerName : sub.trainerEmail)[0]
                  .toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.trainerName.isNotEmpty ? sub.trainerName : 'No name',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sub.trainerEmail,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      '${sub.traineeCount} / ${sub.maxTrainees == -1 ? '∞' : sub.maxTrainees} trainees',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
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

  Widget _buildSubscriptionCard(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(sub.tier);
    final statusColor = _getStatusColor(sub.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.tierEnum.displayName,
                        style: TextStyle(
                          color: tierColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.statusEnum.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${sub.monthlyPrice}/mo',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sub.isPastDue ? Colors.red.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sub.isPastDue ? Colors.red.withValues(alpha: 0.3) : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment Info',
                style: TextStyle(
                  color: sub.isPastDue ? Colors.red : theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (sub.isPastDue) ...[
                const SizedBox(width: 8),
                const Icon(Icons.warning, color: Colors.red, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Next Payment', sub.nextPaymentDate ?? 'N/A'),
          if (sub.daysUntilPayment != null)
            _buildInfoRow(
              context,
              'Days Until Payment',
              '${sub.daysUntilPayment} days',
              valueColor: sub.daysUntilPayment! <= 3 ? Colors.orange : null,
            ),
          _buildInfoRow(context, 'Last Payment', sub.lastPaymentDate ?? 'Never'),
          if (sub.lastPaymentAmount != null)
            _buildInfoRow(context, 'Last Amount', '\$${sub.lastPaymentAmount}'),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            'Past Due Amount',
            '\$${sub.pastDueAmount}',
            valueColor: double.parse(sub.pastDueAmount) > 0 ? Colors.red : Colors.green,
          ),
          if (sub.daysPastDue != null && sub.daysPastDue! > 0)
            _buildInfoRow(
              context,
              'Days Past Due',
              '${sub.daysPastDue} days',
              valueColor: Colors.red,
            ),
          if (sub.failedPaymentCount > 0)
            _buildInfoRow(
              context,
              'Failed Attempts',
              sub.failedPaymentCount.toString(),
              valueColor: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Notes',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showEditNotesDialog(sub),
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.adminNotes.isEmpty ? 'No notes added' : sub.adminNotes,
            style: TextStyle(
              color: sub.adminNotes.isEmpty
                  ? theme.textTheme.bodySmall?.color
                  : theme.textTheme.bodyLarge?.color,
              fontStyle: sub.adminNotes.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              'Change Tier',
              Icons.upgrade,
              Colors.purple,
              () => _showChangeTierDialog(sub),
            ),
            _buildActionChip(
              'Change Status',
              Icons.toggle_on,
              Colors.blue,
              () => _showChangeStatusDialog(sub),
            ),
            _buildActionChip(
              'Record Payment',
              Icons.payment,
              Colors.green,
              () => _showRecordPaymentDialog(sub),
            ),
            if (sub.isPastDue)
              _buildActionChip(
                'Clear Past Due',
                Icons.check_circle,
                Colors.orange,
                () => _clearPastDue(sub),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: onTap,
    );
  }

  Widget _buildRecentPayments(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Payments',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...sub.recentPayments.map((payment) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    payment.status == 'succeeded'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: payment.status == 'succeeded' ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${payment.amount}',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          payment.description,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(payment.paymentDate),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildChangeHistory(BuildContext context, AdminSubscription sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change History',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...sub.recentChanges.map((change) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getChangeTypeColor(change.changeType).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          change.changeType.toUpperCase(),
                          style: TextStyle(
                            color: _getChangeTypeColor(change.changeType),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(change.createdAt),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (change.fromTier != null && change.toTier != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${change.fromTier} → ${change.toTier}',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  ],
                  if (change.fromStatus != null && change.toStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${change.fromStatus} → ${change.toStatus}',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  ],
                  if (change.reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${change.reason}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (change.changedByEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By: ${change.changedByEmail}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  void _handleAction(String action, AdminSubscription sub) {
    switch (action) {
      case 'change_tier':
        _showChangeTierDialog(sub);
        break;
      case 'change_status':
        _showChangeStatusDialog(sub);
        break;
      case 'record_payment':
        _showRecordPaymentDialog(sub);
        break;
      case 'edit_notes':
        _showEditNotesDialog(sub);
        break;
    }
  }

  void _showChangeTierDialog(AdminSubscription sub) {
    final theme = Theme.of(context);
    String selectedTier = sub.tier;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Change Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedTier,
              decoration: const InputDecoration(
                labelText: 'New Tier',
                border: OutlineInputBorder(),
              ),
              items: SubscriptionTier.values.map((tier) {
                return DropdownMenuItem(
                  value: tier.value,
                  child: Text('${tier.displayName} (\$${tier.price}/mo)'),
                );
              }).toList(),
              onChanged: (value) => selectedTier = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                  .changeTier(selectedTier, reason: reasonController.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tier updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(AdminSubscription sub) {
    final theme = Theme.of(context);
    String selectedStatus = sub.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'New Status',
                border: OutlineInputBorder(),
              ),
              items: SubscriptionStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status.value,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) => selectedStatus = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                  .changeStatus(selectedStatus, reason: reasonController.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(AdminSubscription sub) {
    final theme = Theme.of(context);
    final amountController = TextEditingController(text: sub.monthlyPrice);
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Manual payment via check',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                  .recordPayment(
                    amountController.text,
                    description: descriptionController.text,
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded successfully')),
                );
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(AdminSubscription sub) {
    final theme = Theme.of(context);
    final notesController = TextEditingController(text: sub.adminNotes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Edit Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Add notes about this subscription...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                  .updateNotes(notesController.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearPastDue(AdminSubscription sub) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Clear Past Due'),
        content: Text(
          'This will record a payment of \$${sub.pastDueAmount} and clear the past due status. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminSubscriptionDetailProvider(widget.subscriptionId).notifier)
                  .recordPayment(sub.pastDueAmount, description: 'Past due cleared');
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Past due cleared successfully')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'FREE':
        return Colors.grey;
      case 'STARTER':
        return Colors.blue;
      case 'PRO':
        return Colors.purple;
      case 'ENTERPRISE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'past_due':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      case 'trialing':
        return Colors.blue;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getChangeTypeColor(String type) {
    switch (type) {
      case 'upgrade':
        return Colors.green;
      case 'downgrade':
        return Colors.orange;
      case 'cancel':
        return Colors.red;
      case 'reactivate':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

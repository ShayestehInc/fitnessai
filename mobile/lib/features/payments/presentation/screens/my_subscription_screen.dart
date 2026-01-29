import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_models.dart';
import '../providers/payment_provider.dart';

class MySubscriptionScreen extends ConsumerStatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  ConsumerState<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends ConsumerState<MySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(traineeSubscriptionProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(traineeSubscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'My Subscriptions',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.textTheme.bodyLarge?.color,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          tabs: const [
            Tab(text: 'Subscriptions'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSubscriptionsTab(state),
                _buildPaymentHistoryTab(state),
              ],
            ),
    );
  }

  Widget _buildSubscriptionsTab(TraineeSubscriptionState state) {
    final activeSubscriptions = state.activeSubscriptions;
    final inactiveSubscriptions = state.subscriptions
        .where((s) => !s.isActiveStatus)
        .toList();

    if (state.subscriptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.credit_card_off,
        title: 'No Subscriptions',
        message: 'You don\'t have any coaching subscriptions yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(traineeSubscriptionProvider.notifier).loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeSubscriptions.isNotEmpty) ...[
            _buildSectionHeader('ACTIVE SUBSCRIPTIONS'),
            const SizedBox(height: 12),
            ...activeSubscriptions.map((sub) => _buildSubscriptionCard(sub)),
          ],
          if (inactiveSubscriptions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('PAST SUBSCRIPTIONS'),
            const SizedBox(height: 12),
            ...inactiveSubscriptions.map((sub) => _buildSubscriptionCard(sub)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(TraineeSubscriptionModel subscription) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: subscription.isActiveStatus
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: subscription.isActiveStatus
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person,
                  color: subscription.isActiveStatus
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.trainerName ?? subscription.trainerEmail ?? 'Trainer',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscription.formattedAmount,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(subscription.status),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),

          // Details
          if (subscription.currentPeriodEnd != null) ...[
            _buildDetailRow(
              'Next billing',
              _formatDate(subscription.currentPeriodEnd!),
            ),
          ],
          if (subscription.daysUntilRenewal != null && subscription.isActiveStatus) ...[
            _buildDetailRow(
              'Renews in',
              '${subscription.daysUntilRenewal} days',
            ),
          ],
          if (subscription.canceledAt != null) ...[
            _buildDetailRow(
              'Canceled',
              _formatDate(subscription.canceledAt!),
            ),
          ],

          // Cancel Button
          if (subscription.isActiveStatus) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(subscription),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel Subscription'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab(TraineeSubscriptionState state) {
    if (state.payments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: 'No Payments',
        message: 'You haven\'t made any payments yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(traineeSubscriptionProvider.notifier).loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.payments.length,
        itemBuilder: (context, index) {
          return _buildPaymentCard(state.payments[index]);
        },
      ),
    );
  }

  Widget _buildPaymentCard(TraineePaymentModel payment) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: payment.isSucceeded
                  ? Colors.green.withValues(alpha: 0.1)
                  : payment.isPending
                      ? Colors.orange.withValues(alpha: 0.1)
                      : theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              payment.isSucceeded
                  ? Icons.check_circle
                  : payment.isPending
                      ? Icons.pending
                      : Icons.error,
              color: payment.isSucceeded
                  ? Colors.green
                  : payment.isPending
                      ? Colors.orange
                      : theme.colorScheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.isSubscription
                      ? 'Monthly Subscription'
                      : 'One-Time Payment',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  payment.trainerName ?? payment.trainerEmail ?? '',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
                if (payment.paidAt != null)
                  Text(
                    _formatDate(payment.paidAt!),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.formattedAmount,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(payment.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final theme = Theme.of(context);
    Color color;
    String label;

    switch (status) {
      case 'active':
      case 'succeeded':
        color = Colors.green;
        label = status == 'active' ? 'Active' : 'Paid';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'past_due':
        color = Colors.orange;
        label = 'Past Due';
        break;
      case 'canceled':
        color = theme.textTheme.bodySmall?.color ?? Colors.grey;
        label = 'Canceled';
        break;
      case 'failed':
        color = theme.colorScheme.error;
        label = 'Failed';
        break;
      default:
        color = theme.textTheme.bodySmall?.color ?? Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

  void _showCancelDialog(TraineeSubscriptionModel subscription) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Cancel Subscription',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to cancel your subscription with ${subscription.trainerName ?? subscription.trainerEmail}? You will lose access at the end of your current billing period.',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Subscription',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(traineeSubscriptionProvider.notifier)
                  .cancelSubscription(subscription.id);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateString;
    }
  }
}

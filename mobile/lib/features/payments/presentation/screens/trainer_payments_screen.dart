import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_models.dart';
import '../providers/payment_provider.dart';

class TrainerPaymentsScreen extends ConsumerStatefulWidget {
  const TrainerPaymentsScreen({super.key});

  @override
  ConsumerState<TrainerPaymentsScreen> createState() => _TrainerPaymentsScreenState();
}

class _TrainerPaymentsScreenState extends ConsumerState<TrainerPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerPaymentsProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerPaymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Payment History',
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
            Tab(text: 'Payments'),
            Tab(text: 'Subscribers'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Summary
                _buildStatsSummary(state),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPaymentsTab(state),
                      _buildSubscribersTab(state),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsSummary(TrainerPaymentsState state) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Revenue',
              '\$${state.totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Active Subscribers',
              state.activeSubscriberCount.toString(),
              Icons.people,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(TrainerPaymentsState state) {
    if (state.payments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: 'No Payments Yet',
        message: 'You haven\'t received any payments yet. Share your pricing with trainees to get started.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(trainerPaymentsProvider.notifier).loadData();
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
                  payment.traineeEmail ?? 'Trainee',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  payment.isSubscription
                      ? 'Monthly Subscription'
                      : 'One-Time Payment',
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

  Widget _buildSubscribersTab(TrainerPaymentsState state) {
    if (state.subscribers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No Subscribers Yet',
        message: 'You don\'t have any active subscribers yet. Set up your pricing and share it with potential trainees.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(trainerPaymentsProvider.notifier).loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.subscribers.length,
        itemBuilder: (context, index) {
          return _buildSubscriberCard(state.subscribers[index]);
        },
      ),
    );
  }

  Widget _buildSubscriberCard(TraineeSubscriptionModel subscription) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.traineeEmail ?? 'Trainee',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscription.formattedAmount,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(subscription.status),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member since',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subscription.createdAt != null
                          ? _formatDate(subscription.createdAt!)
                          : '-',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (subscription.daysUntilRenewal != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Renews in',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${subscription.daysUntilRenewal} days',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 13,
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateString;
    }
  }
}

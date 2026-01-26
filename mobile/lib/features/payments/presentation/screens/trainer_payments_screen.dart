import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Payment History',
          style: TextStyle(color: AppTheme.foreground),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.foreground,
          unselectedLabelColor: AppTheme.mutedForeground,
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
            color: AppTheme.border,
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.foreground,
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
            color: AppTheme.mutedForeground,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: payment.isSucceeded
                  ? Colors.green.withOpacity(0.1)
                  : payment.isPending
                      ? Colors.orange.withOpacity(0.1)
                      : AppTheme.destructive.withOpacity(0.1),
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
                      : AppTheme.destructive,
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
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  payment.isSubscription
                      ? 'Monthly Subscription'
                      : 'One-Time Payment',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                if (payment.paidAt != null)
                  Text(
                    _formatDate(payment.paidAt!),
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
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
                style: const TextStyle(
                  color: AppTheme.foreground,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primary,
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
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscription.formattedAmount,
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
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
          const Divider(color: AppTheme.border),
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
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subscription.createdAt != null
                          ? _formatDate(subscription.createdAt!)
                          : '-',
                      style: const TextStyle(
                        color: AppTheme.foreground,
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
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${subscription.daysUntilRenewal} days',
                        style: const TextStyle(
                          color: AppTheme.foreground,
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
        color = AppTheme.mutedForeground;
        label = 'Canceled';
        break;
      case 'failed':
        color = AppTheme.destructive;
        label = 'Failed';
        break;
      default:
        color = AppTheme.mutedForeground;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.mutedForeground),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedForeground,
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

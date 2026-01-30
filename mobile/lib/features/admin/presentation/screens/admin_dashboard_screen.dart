import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminDashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Create User',
            onPressed: () => context.push('/admin/users/create'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.stats != null) ...[
                      // MRR Card
                      _buildMRRCard(context, state.stats!),
                      const SizedBox(height: 16),

                      // Quick Actions
                      _buildQuickActions(context),
                      const SizedBox(height: 16),

                      // Quick Stats
                      _buildQuickStats(context, state.stats!),
                      const SizedBox(height: 24),

                      // Tier Breakdown
                      _buildTierBreakdown(context, state.stats!),
                      const SizedBox(height: 24),

                      // Alerts Section
                      _buildAlertsSection(context, state),
                      const SizedBox(height: 24),

                      // Payment Schedule
                      _buildPaymentSchedule(context, state.stats!),
                    ] else ...[
                      // No data state
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.dashboard_outlined,
                                size: 64,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No dashboard data available',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
                                child: const Text('Tap to reload'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMRRCard(BuildContext context, AdminDashboardStats stats) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Recurring Revenue',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${stats.monthlyRecurringRevenue}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMRRStat('Active Trainers', stats.activeTrainers.toString()),
              const SizedBox(width: 24),
              _buildMRRStat('Total Trainees', stats.totalTrainees.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMRRStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
          Text(
            'Quick Actions',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.people,
                  label: 'Users',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/users'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.layers,
                  label: 'Tiers',
                  color: Colors.purple,
                  onTap: () => context.push('/admin/tiers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.local_offer,
                  label: 'Coupons',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/coupons'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AdminDashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Trainers',
            stats.totalTrainers.toString(),
            Icons.person,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Past Due',
            stats.pastDueCount.toString(),
            Icons.warning,
            stats.pastDueCount > 0 ? Colors.red : Colors.green,
            onTap: () => context.push('/admin/past-due'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Past Due',
            '\$${stats.totalPastDue}',
            Icons.attach_money,
            double.parse(stats.totalPastDue) > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBreakdown(BuildContext context, AdminDashboardStats stats) {
    final theme = Theme.of(context);
    final tiers = [
      ('FREE', 'Free', Colors.grey, stats.tierBreakdown['FREE'] ?? 0),
      ('STARTER', 'Starter', Colors.blue, stats.tierBreakdown['STARTER'] ?? 0),
      ('PRO', 'Pro', Colors.purple, stats.tierBreakdown['PRO'] ?? 0),
      ('ENTERPRISE', 'Enterprise', Colors.orange, stats.tierBreakdown['ENTERPRISE'] ?? 0),
    ];

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
                'Subscription Tiers',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/subscriptions'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tiers.map((tier) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTierRow(context, tier.$2, tier.$4, tier.$3),
              )),
        ],
      ),
    );
  }

  Widget _buildTierRow(BuildContext context, String name, int count, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context, AdminDashboardState state) {
    final theme = Theme.of(context);
    if (state.pastDueSubscriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Past Due Accounts',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/past-due'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.pastDueSubscriptions.take(3).map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => context.push('/admin/subscriptions/${sub.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub.trainerEmail,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                      Text(
                        '\$${sub.pastDueAmount}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sub.daysPastDue != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${sub.daysPastDue}d',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentSchedule(BuildContext context, AdminDashboardStats stats) {
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
                'Upcoming Payments',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/admin/upcoming'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(context, 'Today', stats.paymentsDueToday, Colors.red),
          const SizedBox(height: 12),
          _buildPaymentRow(context, 'This Week', stats.paymentsDueThisWeek, Colors.orange),
          const SizedBox(height: 12),
          _buildPaymentRow(context, 'This Month', stats.paymentsDueThisMonth, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context, String label, int count, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count payments',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

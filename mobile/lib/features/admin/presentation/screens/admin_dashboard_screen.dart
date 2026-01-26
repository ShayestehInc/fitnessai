import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    final state = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.background,
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
                      _buildMRRCard(state.stats!),
                      const SizedBox(height: 16),

                      // Quick Stats
                      _buildQuickStats(state.stats!),
                      const SizedBox(height: 24),

                      // Tier Breakdown
                      _buildTierBreakdown(state.stats!),
                      const SizedBox(height: 24),

                      // Alerts Section
                      _buildAlertsSection(state),
                      const SizedBox(height: 24),

                      // Payment Schedule
                      _buildPaymentSchedule(state.stats!),
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
                                color: AppTheme.mutedForeground,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No dashboard data available',
                                style: TextStyle(
                                  color: AppTheme.mutedForeground,
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

  Widget _buildMRRCard(AdminDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
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

  Widget _buildQuickStats(AdminDashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Trainers',
            stats.totalTrainers.toString(),
            Icons.person,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
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
            'Total Past Due',
            '\$${stats.totalPastDue}',
            Icons.attach_money,
            double.parse(stats.totalPastDue) > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
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
                color: AppTheme.mutedForeground,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBreakdown(AdminDashboardStats stats) {
    final tiers = [
      ('FREE', 'Free', Colors.grey, stats.tierBreakdown['FREE'] ?? 0),
      ('STARTER', 'Starter', Colors.blue, stats.tierBreakdown['STARTER'] ?? 0),
      ('PRO', 'Pro', Colors.purple, stats.tierBreakdown['PRO'] ?? 0),
      ('ENTERPRISE', 'Enterprise', Colors.orange, stats.tierBreakdown['ENTERPRISE'] ?? 0),
    ];

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subscription Tiers',
                style: TextStyle(
                  color: AppTheme.foreground,
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
                child: _buildTierRow(tier.$2, tier.$4, tier.$3),
              )),
        ],
      ),
    );
  }

  Widget _buildTierRow(String name, int count, Color color) {
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
            style: const TextStyle(color: AppTheme.foreground),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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

  Widget _buildAlertsSection(AdminDashboardState state) {
    if (state.pastDueSubscriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                          style: const TextStyle(color: AppTheme.foreground),
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
                            color: AppTheme.mutedForeground,
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

  Widget _buildPaymentSchedule(AdminDashboardStats stats) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Payments',
                style: TextStyle(
                  color: AppTheme.foreground,
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
          _buildPaymentRow('Today', stats.paymentsDueToday, Colors.red),
          const SizedBox(height: 12),
          _buildPaymentRow('This Week', stats.paymentsDueThisWeek, Colors.orange),
          const SizedBox(height: 12),
          _buildPaymentRow('This Month', stats.paymentsDueThisMonth, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, int count, Color color) {
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
            style: const TextStyle(color: AppTheme.foreground),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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

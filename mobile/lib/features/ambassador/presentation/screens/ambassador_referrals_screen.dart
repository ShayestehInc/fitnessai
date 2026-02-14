import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ambassador_models.dart';
import '../providers/ambassador_provider.dart';

class AmbassadorReferralsScreen extends ConsumerStatefulWidget {
  const AmbassadorReferralsScreen({super.key});

  @override
  ConsumerState<AmbassadorReferralsScreen> createState() =>
      _AmbassadorReferralsScreenState();
}

class _AmbassadorReferralsScreenState
    extends ConsumerState<AmbassadorReferralsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ambassadorReferralsProvider.notifier).loadReferrals();
    });
  }

  void _onFilterChanged(String? status) {
    setState(() => _statusFilter = status);
    ref.read(ambassadorReferralsProvider.notifier).loadReferrals(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ambassadorReferralsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Referrals'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _buildFilterChips(theme),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildErrorState(theme, state.error!)
                    : state.referrals.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(ambassadorReferralsProvider.notifier)
                                .loadReferrals(status: _statusFilter),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.referrals.length,
                              itemBuilder: (context, index) =>
                                  _buildReferralCard(theme, state.referrals[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(theme, 'All', null),
          const SizedBox(width: 8),
          _buildChip(theme, 'Active', 'ACTIVE'),
          const SizedBox(width: 8),
          _buildChip(theme, 'Pending', 'PENDING'),
          const SizedBox(width: 8),
          _buildChip(theme, 'Churned', 'CHURNED'),
        ],
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, String? status) {
    final isSelected = _statusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(status),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(ambassadorReferralsProvider.notifier)
                  .loadReferrals(status: _statusFilter),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text(
            _statusFilter != null
                ? 'No $_statusFilter referrals'
                : 'No referrals yet',
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(ThemeData theme, AmbassadorReferral referral) {
    final statusColor = switch (referral.status) {
      'ACTIVE' => Colors.green,
      'PENDING' => Colors.orange,
      'CHURNED' => Colors.red,
      _ => Colors.grey,
    };

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
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  referral.trainer.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.trainer.displayName,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      referral.trainer.email,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  referral.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetail(theme, 'Tier', referral.trainerSubscriptionTier),
              const SizedBox(width: 16),
              _buildDetail(theme, 'Commission', '\$${referral.totalCommissionEarned}'),
              const SizedBox(width: 16),
              _buildDetail(theme, 'Referred', _formatDate(referral.referredAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  String? _tierFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSubscriptionsProvider.notifier).loadSubscriptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(adminSubscriptionsProvider.notifier).loadSubscriptions(
      status: _statusFilter,
      tier: _tierFilter,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminSubscriptionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Active filters
          if (_statusFilter != null || _tierFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_statusFilter != null)
                    _buildFilterChip(
                      context,
                      'Status: ${_statusFilter!}',
                      () {
                        setState(() => _statusFilter = null);
                        _applyFilters();
                      },
                    ),
                  if (_tierFilter != null) ...[
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      'Tier: ${_tierFilter!}',
                      () {
                        setState(() => _tierFilter = null);
                        _applyFilters();
                      },
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = null;
                        _tierFilter = null;
                      });
                      _applyFilters();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Subscriptions list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                state.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _applyFilters,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.subscriptions.isEmpty
                        ? Center(
                            child: Text(
                              'No subscriptions found',
                              style: TextStyle(color: theme.textTheme.bodySmall?.color),
                            ),
                          )
                        : RefreshIndicator(
                        onRefresh: () async => _applyFilters(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.subscriptions.length,
                          itemBuilder: (context, index) {
                            return _SubscriptionCard(
                              subscription: state.subscriptions[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Subscriptions',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status filter
              Text(
                'Status',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: SubscriptionStatus.values.map((status) {
                  final isSelected = _statusFilter == status.value;
                  return FilterChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        setState(() {
                          _statusFilter = selected ? status.value : null;
                        });
                      });
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Tier filter
              Text(
                'Tier',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: SubscriptionTier.values.map((tier) {
                  final isSelected = _tierFilter == tier.value;
                  return FilterChip(
                    label: Text(tier.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        setState(() {
                          _tierFilter = selected ? tier.value : null;
                        });
                      });
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final AdminSubscriptionListItem subscription;

  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(subscription.tier);
    final statusColor = _getStatusColor(subscription.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/subscriptions/${subscription.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: tierColor.withValues(alpha: 0.2),
                    child: Text(
                      subscription.trainerEmail[0].toUpperCase(),
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.trainerEmail,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subscription.trainerName != null)
                          Text(
                            subscription.trainerName!,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges row
              Row(
                children: [
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subscription.tierEnum.displayName,
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subscription.statusEnum.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Amount
                  Text(
                    '\$${subscription.tierEnum.price}/mo',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Past due warning
              if (double.parse(subscription.pastDueAmount) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Past due: \$${subscription.pastDueAmount}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subscription.daysPastDue != null) ...[
                        const Spacer(),
                        Text(
                          '${subscription.daysPastDue} days',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Next payment date
              if (subscription.nextPaymentDate != null &&
                  double.parse(subscription.pastDueAmount) <= 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Next payment: ${_formatDate(subscription.nextPaymentDate!)}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

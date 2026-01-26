import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminUpcomingPaymentsScreen extends ConsumerStatefulWidget {
  const AdminUpcomingPaymentsScreen({super.key});

  @override
  ConsumerState<AdminUpcomingPaymentsScreen> createState() => _AdminUpcomingPaymentsScreenState();
}

class _AdminUpcomingPaymentsScreenState extends ConsumerState<AdminUpcomingPaymentsScreen> {
  List<AdminSubscriptionListItem> _subscriptions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repository = ref.read(adminRepositoryProvider);
    final result = await repository.getUpcomingPayments(days: _selectedDays);

    if (result['success'] == true) {
      setState(() {
        _subscriptions = result['data'] as List<AdminSubscriptionListItem>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] as String?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Upcoming Payments'),
        backgroundColor: AppTheme.background,
      ),
      body: Column(
        children: [
          // Time range selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show payments due in:',
                  style: TextStyle(color: AppTheme.foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDayChip(7, 'Next 7 days'),
                        const SizedBox(width: 8),
                        _buildDayChip(14, 'Next 14 days'),
                        const SizedBox(width: 8),
                        _buildDayChip(30, 'Next 30 days'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUpcoming,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _subscriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 64,
                                  color: AppTheme.mutedForeground.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No upcoming payments',
                                  style: TextStyle(
                                    color: AppTheme.foreground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No payments due in the next $_selectedDays days.',
                                  style: TextStyle(color: AppTheme.mutedForeground),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUpcoming,
                            child: Column(
                              children: [
                                // Summary card
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.payments,
                                          color: AppTheme.primary,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_subscriptions.length} Payments',
                                              style: TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Expected: \$${_calculateExpectedRevenue()}',
                                              style: TextStyle(
                                                color: AppTheme.mutedForeground,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Grouped by day
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _subscriptions.length,
                                    itemBuilder: (context, index) {
                                      return _UpcomingPaymentCard(
                                        subscription: _subscriptions[index],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDays = days);
        _loadUpcoming();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.foreground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _calculateExpectedRevenue() {
    double total = 0;
    for (final sub in _subscriptions) {
      total += sub.tierEnum.price;
    }
    return total.toStringAsFixed(2);
  }
}

class _UpcomingPaymentCard extends StatelessWidget {
  final AdminSubscriptionListItem subscription;

  const _UpcomingPaymentCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(subscription.tier);
    final daysUntil = _calculateDaysUntil(subscription.nextPaymentDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/subscriptions/${subscription.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _getDateColor(daysUntil).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      daysUntil == 0
                          ? 'Today'
                          : daysUntil == 1
                              ? 'Tomorrow'
                              : '$daysUntil',
                      style: TextStyle(
                        color: _getDateColor(daysUntil),
                        fontSize: daysUntil > 1 ? 20 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (daysUntil > 1)
                      Text(
                        'days',
                        style: TextStyle(
                          color: _getDateColor(daysUntil),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.trainerEmail,
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subscription.tierEnum.displayName,
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (subscription.nextPaymentDate != null)
                          Text(
                            _formatDate(subscription.nextPaymentDate!),
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '\$${subscription.tierEnum.price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateDaysUntil(String? dateStr) {
    if (dateStr == null) return 0;
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final paymentDate = DateTime(date.year, date.month, date.day);
      return paymentDate.difference(today).inDays;
    } catch (e) {
      return 0;
    }
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

  Color _getDateColor(int daysUntil) {
    if (daysUntil <= 0) return Colors.red;
    if (daysUntil <= 3) return Colors.orange;
    if (daysUntil <= 7) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return dateStr;
    }
  }
}

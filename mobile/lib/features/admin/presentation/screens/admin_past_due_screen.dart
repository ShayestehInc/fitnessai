import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminPastDueScreen extends ConsumerStatefulWidget {
  const AdminPastDueScreen({super.key});

  @override
  ConsumerState<AdminPastDueScreen> createState() => _AdminPastDueScreenState();
}

class _AdminPastDueScreenState extends ConsumerState<AdminPastDueScreen> {
  List<AdminSubscriptionListItem> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPastDue();
  }

  Future<void> _loadPastDue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repository = ref.read(adminRepositoryProvider);
    final result = await repository.getPastDueSubscriptions();

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Past Due Accounts'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
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
                        onPressed: _loadPastDue,
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
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No past due accounts!',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All subscriptions are up to date.',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPastDue,
                      child: Column(
                        children: [
                          // Summary card
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_subscriptions.length} Past Due',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Total: \$${_calculateTotalPastDue()}',
                                        style: TextStyle(
                                          color: theme.textTheme.bodySmall?.color,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _subscriptions.length,
                              itemBuilder: (context, index) {
                                return _PastDueCard(
                                  subscription: _subscriptions[index],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  String _calculateTotalPastDue() {
    double total = 0;
    for (final sub in _subscriptions) {
      total += double.tryParse(sub.pastDueAmount) ?? 0;
    }
    return total.toStringAsFixed(2);
  }
}

class _PastDueCard extends StatelessWidget {
  final AdminSubscriptionListItem subscription;

  const _PastDueCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(subscription.tier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/subscriptions/${subscription.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    child: Text(
                      subscription.trainerEmail[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.red,
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.2),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Past Due Amount',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '\$${subscription.pastDueAmount}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Days Overdue',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${subscription.daysPastDue ?? 0}',
                          style: TextStyle(
                            color: _getDaysOverdueColor(subscription.daysPastDue ?? 0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Send reminder email
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reminder sent')),
                        );
                      },
                      icon: const Icon(Icons.email, size: 18),
                      label: const Text('Send Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/admin/subscriptions/${subscription.id}'),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Record Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
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

  Color _getDaysOverdueColor(int days) {
    if (days > 30) return Colors.red;
    if (days > 14) return Colors.orange;
    return Colors.yellow.shade700;
  }
}

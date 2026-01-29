import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tier_coupon_models.dart';
import '../providers/admin_provider.dart';

class AdminCouponDetailScreen extends ConsumerStatefulWidget {
  final int couponId;

  const AdminCouponDetailScreen({super.key, required this.couponId});

  @override
  ConsumerState<AdminCouponDetailScreen> createState() =>
      _AdminCouponDetailScreenState();
}

class _AdminCouponDetailScreenState
    extends ConsumerState<AdminCouponDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(couponDetailProvider(widget.couponId).notifier).loadCoupon();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(couponDetailProvider(widget.couponId));
    final coupon = state.coupon;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(coupon?.code ?? 'Coupon Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (coupon != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: coupon.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                  ),
                );
              },
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
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(couponDetailProvider(widget.couponId)
                                  .notifier)
                              .loadCoupon(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : coupon == null
                  ? const Center(child: Text('Coupon not found'))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(couponDetailProvider(widget.couponId).notifier)
                          .loadCoupon(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, coupon),
                            const SizedBox(height: 24),
                            _buildDetailsSection(context, coupon),
                            const SizedBox(height: 24),
                            _buildUsageSection(context, coupon),
                            const SizedBox(height: 24),
                            _buildUsageHistory(context, state.usages),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeader(BuildContext context, CouponModel coupon) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(coupon.status);
    final typeColor = _getTypeColor(context, coupon.couponType);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                coupon.code,
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              coupon.discountDisplay,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coupon.typeDisplay,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                coupon.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, CouponModel coupon) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Applies To', coupon.appliesToDisplay),
            if (coupon.description.isNotEmpty)
              _buildDetailRow(context, 'Description', coupon.description),
            _buildDetailRow(
              context,
              'Valid From',
              coupon.validFrom != null
                  ? _formatDateTime(coupon.validFrom!)
                  : 'Immediately',
            ),
            _buildDetailRow(
              context,
              'Valid Until',
              coupon.validUntil != null
                  ? _formatDateTime(coupon.validUntil!)
                  : 'No expiry',
            ),
            if (coupon.applicableTiers.isNotEmpty)
              _buildDetailRow(context, 'Applicable Tiers', coupon.applicableTiers.join(', ')),
            if (coupon.createdByAdminEmail != null)
              _buildDetailRow(context, 'Created By (Admin)', coupon.createdByAdminEmail!),
            if (coupon.createdByTrainerEmail != null)
              _buildDetailRow(context, 'Created By (Trainer)', coupon.createdByTrainerEmail!),
            if (coupon.stripeCouponId != null)
              _buildDetailRow(context, 'Stripe ID', coupon.stripeCouponId!),
            _buildDetailRow(
              context,
              'Created At',
              coupon.createdAt != null
                  ? _formatDateTime(coupon.createdAt!)
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, CouponModel coupon) {
    final theme = Theme.of(context);
    final usagePercent = coupon.maxUses > 0
        ? (coupon.currentUses / coupon.maxUses).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage',
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
                        coupon.usageDisplay,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      if (coupon.maxUses > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: usagePercent,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usagePercent >= 0.9 ? Colors.red : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Max per user',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${coupon.maxUsesPerUser}',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageHistory(BuildContext context, List<CouponUsageModel> usages) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage History',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${usages.length} uses',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (usages.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No usage yet',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: usages.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final usage = usages[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        usage.userEmail?[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      usage.userEmail ?? 'Unknown user',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: usage.usedAt != null
                        ? Text(
                            _formatDateTime(usage.usedAt!),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '-\$${usage.discountAmount}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'revoked':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'exhausted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    switch (type) {
      case 'percent':
        return Colors.purple;
      case 'fixed':
        return Colors.blue;
      case 'free_trial':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

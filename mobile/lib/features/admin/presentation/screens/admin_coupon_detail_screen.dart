import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
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
    final state = ref.watch(couponDetailProvider(widget.couponId));
    final coupon = state.coupon;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(coupon?.code ?? 'Coupon Details'),
        backgroundColor: AppTheme.background,
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
                            _buildHeader(coupon),
                            const SizedBox(height: 24),
                            _buildDetailsSection(coupon),
                            const SizedBox(height: 24),
                            _buildUsageSection(coupon),
                            const SizedBox(height: 24),
                            _buildUsageHistory(state.usages),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeader(CouponModel coupon) {
    final statusColor = _getStatusColor(coupon.status);
    final typeColor = _getTypeColor(coupon.couponType);

    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
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
              style: const TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coupon.typeDisplay,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
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

  Widget _buildDetailsSection(CouponModel coupon) {
    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Applies To', coupon.appliesToDisplay),
            if (coupon.description.isNotEmpty)
              _buildDetailRow('Description', coupon.description),
            _buildDetailRow(
              'Valid From',
              coupon.validFrom != null
                  ? _formatDateTime(coupon.validFrom!)
                  : 'Immediately',
            ),
            _buildDetailRow(
              'Valid Until',
              coupon.validUntil != null
                  ? _formatDateTime(coupon.validUntil!)
                  : 'No expiry',
            ),
            if (coupon.applicableTiers.isNotEmpty)
              _buildDetailRow('Applicable Tiers', coupon.applicableTiers.join(', ')),
            if (coupon.createdByAdminEmail != null)
              _buildDetailRow('Created By (Admin)', coupon.createdByAdminEmail!),
            if (coupon.createdByTrainerEmail != null)
              _buildDetailRow('Created By (Trainer)', coupon.createdByTrainerEmail!),
            if (coupon.stripeCouponId != null)
              _buildDetailRow('Stripe ID', coupon.stripeCouponId!),
            _buildDetailRow(
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

  Widget _buildUsageSection(CouponModel coupon) {
    final usagePercent = coupon.maxUses > 0
        ? (coupon.currentUses / coupon.maxUses).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage',
              style: TextStyle(
                color: AppTheme.foreground,
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
                        style: const TextStyle(
                          color: AppTheme.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      if (coupon.maxUses > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: usagePercent,
                          backgroundColor: AppTheme.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usagePercent >= 0.9 ? Colors.red : AppTheme.primary,
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
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${coupon.maxUsesPerUser}',
                      style: const TextStyle(
                        color: AppTheme.foreground,
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

  Widget _buildUsageHistory(List<CouponUsageModel> usages) {
    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Usage History',
                  style: TextStyle(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${usages.length} uses',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
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
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No usage yet',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
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
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Text(
                        usage.userEmail?[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      usage.userEmail ?? 'Unknown user',
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: usage.usedAt != null
                        ? Text(
                            _formatDateTime(usage.usedAt!),
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
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

  Widget _buildDetailRow(String label, String value) {
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
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.foreground,
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'percent':
        return Colors.purple;
      case 'fixed':
        return Colors.blue;
      case 'free_trial':
        return Colors.green;
      default:
        return AppTheme.primary;
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

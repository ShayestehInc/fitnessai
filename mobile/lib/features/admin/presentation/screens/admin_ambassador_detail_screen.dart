import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ambassador/data/models/ambassador_models.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';

class AdminAmbassadorDetailScreen extends ConsumerStatefulWidget {
  final int ambassadorId;

  const AdminAmbassadorDetailScreen({super.key, required this.ambassadorId});

  @override
  ConsumerState<AdminAmbassadorDetailScreen> createState() =>
      _AdminAmbassadorDetailScreenState();
}

class _AdminAmbassadorDetailScreenState
    extends ConsumerState<AdminAmbassadorDetailScreen> {
  AmbassadorDetailData? _detail;
  bool _isLoading = true;
  bool _isToggling = false;
  String? _error;
  final Set<int> _processingCommissionIds = {};
  bool _isBulkProcessing = false;

  AmbassadorProfile? get _profile => _detail?.profile;
  List<AmbassadorReferral> get _referrals => _detail?.referrals ?? [];
  List<AmbassadorCommission> get _commissions => _detail?.commissions ?? [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      final detail = await repo.getAmbassadorDetail(widget.ambassadorId);

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleActive() async {
    if (_profile == null || _isToggling) return;

    final newActive = !_profile!.isActive;
    final actionLabel = newActive ? 'activate' : 'deactivate';
    final displayName = _profile!.user.displayName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newActive ? 'Activate' : 'Deactivate'} Ambassador'),
        content: Text(
          'Are you sure you want to $actionLabel $displayName? '
          '${newActive ? 'They will be able to earn commissions again.' : 'They will no longer earn commissions on new referrals.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newActive ? Colors.green : Colors.orange,
            ),
            child: Text(newActive ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isToggling = true);

    final success = await ref.read(adminAmbassadorsProvider.notifier).updateAmbassador(
          _profile!.id,
          isActive: newActive,
        );

    if (mounted) {
      setState(() => _isToggling = false);
    }

    if (success) {
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Ambassador activated' : 'Ambassador deactivated'),
            backgroundColor: newActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $actionLabel ambassador. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showEditCommissionRateDialog() async {
    if (_profile == null) return;

    double currentRate = double.tryParse(_profile!.commissionRate) ?? 0.20;
    double newRate = currentRate;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Commission Rate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(newRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: newRate,
                    min: 0.05,
                    max: 0.50,
                    divisions: 9,
                    label: '${(newRate * 100).toStringAsFixed(0)}%',
                    onChanged: (value) => setDialogState(() => newRate = value),
                  ),
                  Text(
                    'Ambassador earns ${(newRate * 100).toStringAsFixed(0)}% of each referred trainer\'s subscription.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(newRate),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentRate && mounted) {
      final success = await ref.read(adminAmbassadorsProvider.notifier).updateAmbassador(
            _profile!.id,
            commissionRate: result,
          );
      if (success) {
        await _loadDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Commission rate updated to ${(result * 100).toStringAsFixed(0)}%'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveCommission(AmbassadorCommission commission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Commission'),
        content: Text(
          'Approve \$${commission.commissionAmount} commission for ${commission.trainerEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingCommissionIds.add(commission.id));

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      await repo.approveCommission(widget.ambassadorId, commission.id);
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = _parseErrorMessage(e, 'Failed to approve commission. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingCommissionIds.remove(commission.id));
      }
    }
  }

  Future<void> _payCommission(AmbassadorCommission commission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Commission as Paid'),
        content: Text(
          'Mark \$${commission.commissionAmount} commission for ${commission.trainerEmail} as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingCommissionIds.add(commission.id));

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      await repo.payCommission(widget.ambassadorId, commission.id);
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = _parseErrorMessage(e, 'Failed to mark commission as paid. Please try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingCommissionIds.remove(commission.id));
      }
    }
  }

  Future<void> _bulkApproveAll() async {
    final pendingCommissions = _commissions.where((c) => c.status == 'PENDING').toList();
    if (pendingCommissions.isEmpty) return;

    final totalAmount = pendingCommissions.fold<double>(
      0.0,
      (sum, c) => sum + (double.tryParse(c.commissionAmount) ?? 0.0),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Pending'),
        content: Text(
          'Approve ${pendingCommissions.length} pending commission(s) totaling \$${totalAmount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBulkProcessing = true);

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      final ids = pendingCommissions.map((c) => c.id).toList();
      final result = await repo.bulkApproveCommissions(widget.ambassadorId, ids);
      await _loadDetail();
      if (mounted) {
        final approvedCount = result['approved_count'] as int? ?? 0;
        final message = approvedCount > 0
            ? '$approvedCount commission(s) approved'
            : 'No pending commissions to approve.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: approvedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to bulk approve commissions. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBulkProcessing = false);
      }
    }
  }

  String _parseErrorMessage(Object error, String fallback) {
    // Extract the server error message from DioException response data
    // rather than brittle string matching on toString().
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final serverError = data['error'];
        if (serverError is String && serverError.isNotEmpty) {
          return serverError;
        }
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ambassador Detail'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_profile != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit Commission Rate',
              onPressed: _showEditCommissionRateDialog,
            ),
            _isToggling
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _profile!.isActive ? Icons.pause_circle : Icons.play_circle,
                      color: _profile!.isActive ? Colors.orange : Colors.green,
                    ),
                    tooltip: _profile!.isActive ? 'Deactivate ambassador' : 'Activate ambassador',
                    onPressed: _toggleActive,
                  ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(theme),
                        const SizedBox(height: 16),
                        _buildStatsCard(theme),
                        const SizedBox(height: 24),
                        _buildReferralsList(theme),
                        const SizedBox(height: 24),
                        _buildCommissionsList(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load ambassador details',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    final profile = _profile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: profile.isActive
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            child: Icon(
              Icons.handshake,
              color: profile.isActive ? Colors.teal : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.user.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.user.email,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: profile.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profile.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: profile.isActive ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${profile.referralCode}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
    final profile = _profile!;
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(theme, 'Referrals', profile.totalReferrals.toString(), Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(theme, 'Earnings', '\$${profile.totalEarnings}', Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _showEditCommissionRateDialog,
            child: _buildStatTile(
                theme, 'Rate', '${profile.commissionPercent.toStringAsFixed(0)}%', Colors.purple),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, Color color) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referrals (${_referrals.length})',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No referrals yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ..._referrals.map((r) => _buildReferralTile(theme, r)),
      ],
    );
  }

  Widget _buildReferralTile(ThemeData theme, AmbassadorReferral referral) {
    final statusColor = switch (referral.status) {
      'ACTIVE' => Colors.green,
      'PENDING' => Colors.orange,
      'CHURNED' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.trainer.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${referral.trainerSubscriptionTier} tier',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${referral.totalCommissionEarned}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              referral.status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsList(ThemeData theme) {
    final hasPending = _commissions.any((c) => c.status == 'PENDING');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Commission History (${_commissions.length})',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasPending)
              _isBulkProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: _bulkApproveAll,
                      icon: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Approve All Pending',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 12),
        if (_commissions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No commissions yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ..._commissions.map((c) => _buildCommissionTile(theme, c)),
      ],
    );
  }

  Widget _buildCommissionTile(ThemeData theme, AmbassadorCommission commission) {
    final statusColor = switch (commission.status) {
      'PAID' => Colors.green,
      'APPROVED' => Colors.blue,
      'PENDING' => Colors.orange,
      _ => Colors.grey,
    };

    final isProcessing = _processingCommissionIds.contains(commission.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commission.trainerEmail,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${commission.periodStart} - ${commission.periodEnd}',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${commission.commissionAmount}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'of \$${commission.baseAmount}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              commission.status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          if (commission.status == 'PENDING' || commission.status == 'APPROVED') ...[
            const SizedBox(width: 8),
            _buildCommissionActionButton(theme, commission, isProcessing),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionActionButton(
    ThemeData theme,
    AmbassadorCommission commission,
    bool isProcessing,
  ) {
    if (isProcessing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (commission.status == 'PENDING') {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: () => _approveCommission(commission),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Approve',
            style: TextStyle(color: Colors.blue, fontSize: 11),
          ),
        ),
      );
    }

    if (commission.status == 'APPROVED') {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: () => _payCommission(commission),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Mark Paid',
            style: TextStyle(color: Colors.green, fontSize: 11),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

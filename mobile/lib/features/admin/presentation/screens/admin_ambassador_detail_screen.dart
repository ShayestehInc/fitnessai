import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ambassador/data/models/ambassador_models.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';
import '../widgets/ambassador_commissions_list.dart';
import '../widgets/ambassador_profile_card.dart';
import '../widgets/ambassador_referrals_list.dart';

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
        final approvedCount = result.processedCount;
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

  Future<void> _bulkPayAll() async {
    final approvedCommissions = _commissions.where((c) => c.status == 'APPROVED').toList();
    if (approvedCommissions.isEmpty) return;

    final totalAmount = approvedCommissions.fold<double>(
      0.0,
      (sum, c) => sum + (double.tryParse(c.commissionAmount) ?? 0.0),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay All Approved'),
        content: Text(
          'Mark ${approvedCommissions.length} approved commission(s) totaling \$${totalAmount.toStringAsFixed(2)} as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Pay All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBulkProcessing = true);

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      final ids = approvedCommissions.map((c) => c.id).toList();
      final result = await repo.bulkPayCommissions(widget.ambassadorId, ids);
      await _loadDetail();
      if (mounted) {
        final paidCount = result.processedCount;
        final message = paidCount > 0
            ? '$paidCount commission(s) marked as paid'
            : 'No approved commissions to pay.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: paidCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to bulk pay commissions. Please try again.'),
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
                        AmbassadorProfileCard(profile: _profile!),
                        const SizedBox(height: 16),
                        AmbassadorStatsRow(
                          profile: _profile!,
                          onRateTap: _showEditCommissionRateDialog,
                        ),
                        const SizedBox(height: 24),
                        AmbassadorReferralsList(referrals: _referrals),
                        const SizedBox(height: 24),
                        AmbassadorCommissionsList(
                          commissions: _commissions,
                          processingIds: _processingCommissionIds,
                          isBulkProcessing: _isBulkProcessing,
                          onBulkApprove: _bulkApproveAll,
                          onBulkPay: _bulkPayAll,
                          onApprove: _approveCommission,
                          onPay: _payCommission,
                        ),
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
}

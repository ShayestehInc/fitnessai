import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tier_coupon_models.dart';
import '../providers/admin_provider.dart';

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCouponsProvider.notifier).loadCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCouponsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Coupons'),
        backgroundColor: AppTheme.background,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() => _statusFilter = status);
              ref.read(adminCouponsProvider.notifier).loadCoupons(status: status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Text('Active'),
              ),
              const PopupMenuItem(
                value: 'revoked',
                child: Text('Revoked'),
              ),
              const PopupMenuItem(
                value: 'expired',
                child: Text('Expired'),
              ),
              const PopupMenuItem(
                value: 'exhausted',
                child: Text('Exhausted'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCouponDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFilterChip(
                    'Status: $_statusFilter',
                    () {
                      setState(() => _statusFilter = null);
                      ref.read(adminCouponsProvider.notifier).loadCoupons();
                    },
                  ),
                ],
              ),
            ),
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
                                    .read(adminCouponsProvider.notifier)
                                    .loadCoupons(status: _statusFilter),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.coupons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 64,
                                  color: AppTheme.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No coupons found',
                                  style: TextStyle(
                                    color: AppTheme.mutedForeground,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showCouponDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Coupon'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(adminCouponsProvider.notifier)
                                .loadCoupons(status: _statusFilter),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.coupons.length,
                              itemBuilder: (context, index) {
                                final coupon = state.coupons[index];
                                return _CouponCard(
                                  coupon: coupon,
                                  onTap: () =>
                                      context.push('/admin/coupons/${coupon.id}'),
                                  onRevoke: coupon.isActive
                                      ? () => _revokeCoupon(coupon)
                                      : null,
                                  onReactivate: !coupon.isActive &&
                                          coupon.status != 'expired' &&
                                          coupon.status != 'exhausted'
                                      ? () => _reactivateCoupon(coupon)
                                      : null,
                                  onDelete: () => _confirmDelete(coupon),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primary,
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
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CouponDialog(
        onSave: (data) async {
          final success =
              await ref.read(adminCouponsProvider.notifier).createCoupon(data);

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Coupon created'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _revokeCoupon(CouponListItemModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Revoke Coupon'),
        content: Text(
          'Are you sure you want to revoke "${coupon.code}"? It will no longer be usable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(adminCouponsProvider.notifier).revokeCoupon(coupon.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon revoked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _reactivateCoupon(CouponListItemModel coupon) async {
    final success = await ref
        .read(adminCouponsProvider.notifier)
        .reactivateCoupon(coupon.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon reactivated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(CouponListItemModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to delete "${coupon.code}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(adminCouponsProvider.notifier).deleteCoupon(coupon.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _CouponCard extends StatelessWidget {
  final CouponListItemModel coupon;
  final VoidCallback onTap;
  final VoidCallback? onRevoke;
  final VoidCallback? onReactivate;
  final VoidCallback onDelete;

  const _CouponCard({
    required this.coupon,
    required this.onTap,
    this.onRevoke,
    this.onReactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(coupon.status);
    final typeColor = _getTypeColor(coupon.couponType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      coupon.code,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      coupon.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.discountDisplay,
                          style: const TextStyle(
                            color: AppTheme.foreground,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTypeLabel(coupon.couponType),
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getAppliesToLabel(coupon.appliesTo),
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatUsage(coupon),
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (coupon.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  coupon.description,
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (coupon.validUntil != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${_formatDate(coupon.validUntil!)}',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReactivate != null)
                    TextButton.icon(
                      onPressed: onReactivate,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reactivate'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  if (onRevoke != null)
                    TextButton.icon(
                      onPressed: onRevoke,
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Revoke'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'percent':
        return 'Percentage discount';
      case 'fixed':
        return 'Fixed amount off';
      case 'free_trial':
        return 'Free trial days';
      default:
        return type;
    }
  }

  String _getAppliesToLabel(String appliesTo) {
    switch (appliesTo) {
      case 'trainer':
        return 'Trainer subscriptions';
      case 'trainee':
        return 'Trainee coaching';
      case 'both':
        return 'All subscriptions';
      default:
        return appliesTo;
    }
  }

  String _formatUsage(CouponListItemModel coupon) {
    if (coupon.maxUses == 0) {
      return '${coupon.currentUses} used (unlimited)';
    }
    return '${coupon.currentUses}/${coupon.maxUses} used';
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

class _CouponDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _CouponDialog({required this.onSave});

  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxUsesController = TextEditingController(text: '0');

  String _couponType = 'percent';
  String _appliesTo = 'both';
  DateTime? _validUntil;
  bool _isSaving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'code': _codeController.text.toUpperCase(),
      'description': _descriptionController.text,
      'coupon_type': _couponType,
      'discount_value': _discountValueController.text,
      'applies_to': _appliesTo,
      'max_uses': int.tryParse(_maxUsesController.text) ?? 0,
    };

    if (_validUntil != null) {
      data['valid_until'] = _validUntil!.toIso8601String();
    }

    await widget.onSave(data);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _validUntil = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Coupon',
                  style: TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'e.g., SAVE20',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                  ],
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Code is required';
                    if (v!.length < 3) return 'Code must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Internal description',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _couponType,
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'percent',
                      child: Text('Percentage Off'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed Amount Off'),
                    ),
                    DropdownMenuItem(
                      value: 'free_trial',
                      child: Text('Free Trial Days'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _couponType = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _getDiscountLabel(),
                    prefixText: _couponType == 'fixed' ? '\$' : null,
                    suffixText: _couponType == 'percent'
                        ? '%'
                        : _couponType == 'free_trial'
                            ? 'days'
                            : null,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    final value = double.tryParse(v!);
                    if (value == null || value <= 0) return 'Invalid value';
                    if (_couponType == 'percent' && value > 100) {
                      return 'Cannot exceed 100%';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _appliesTo,
                  decoration: const InputDecoration(labelText: 'Applies To'),
                  items: const [
                    DropdownMenuItem(
                      value: 'both',
                      child: Text('All (Trainers & Trainees)'),
                    ),
                    DropdownMenuItem(
                      value: 'trainer',
                      child: Text('Trainer Subscriptions Only'),
                    ),
                    DropdownMenuItem(
                      value: 'trainee',
                      child: Text('Trainee Coaching Only'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _appliesTo = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxUsesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Uses (0 = unlimited)',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (optional)',
                      suffixIcon: _validUntil != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _validUntil = null),
                            )
                          : const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _validUntil != null
                          ? '${_validUntil!.month}/${_validUntil!.day}/${_validUntil!.year}'
                          : 'No expiry date',
                      style: TextStyle(
                        color: _validUntil != null
                            ? AppTheme.foreground
                            : AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDiscountLabel() {
    switch (_couponType) {
      case 'percent':
        return 'Discount Percentage';
      case 'fixed':
        return 'Discount Amount';
      case 'free_trial':
        return 'Trial Days';
      default:
        return 'Value';
    }
  }
}

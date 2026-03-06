import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_date_picker.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_dropdown.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/tier_coupon_models.dart';
import '../providers/admin_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
    final theme = Theme.of(context);
    final state = ref.watch(adminCouponsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.adminCoupons),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          Theme.of(context).platform == TargetPlatform.iOS
              ? IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => showAdaptiveActionSheet(
                    context: context,
                    title: context.l10n.adminFilterByStatus,
                    actions: [
                      AdaptiveAction(
                        label: context.l10n.commonAll,
                        onPressed: () {
                          setState(() => _statusFilter = null);
                          ref.read(adminCouponsProvider.notifier).loadCoupons(status: null);
                        },
                      ),
                      AdaptiveAction(
                        label: context.l10n.adminActive,
                        onPressed: () {
                          setState(() => _statusFilter = 'active');
                          ref.read(adminCouponsProvider.notifier).loadCoupons(status: 'active');
                        },
                      ),
                      AdaptiveAction(
                        label: context.l10n.adminRevoked,
                        onPressed: () {
                          setState(() => _statusFilter = 'revoked');
                          ref.read(adminCouponsProvider.notifier).loadCoupons(status: 'revoked');
                        },
                      ),
                      AdaptiveAction(
                        label: context.l10n.adminExpired,
                        onPressed: () {
                          setState(() => _statusFilter = 'expired');
                          ref.read(adminCouponsProvider.notifier).loadCoupons(status: 'expired');
                        },
                      ),
                      AdaptiveAction(
                        label: context.l10n.adminExhausted,
                        onPressed: () {
                          setState(() => _statusFilter = 'exhausted');
                          ref.read(adminCouponsProvider.notifier).loadCoupons(status: 'exhausted');
                        },
                      ),
                    ],
                  ),
                )
              : PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (status) {
                    setState(() => _statusFilter = status);
                    ref.read(adminCouponsProvider.notifier).loadCoupons(status: status);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: null,
                      child: Text(context.l10n.commonAll),
                    ),
                    PopupMenuItem(
                      value: 'active',
                      child: Text(context.l10n.adminActive),
                    ),
                    PopupMenuItem(
                      value: 'revoked',
                      child: Text(context.l10n.adminRevoked),
                    ),
                    PopupMenuItem(
                      value: 'expired',
                      child: Text(context.l10n.adminExpired),
                    ),
                    PopupMenuItem(
                      value: 'exhausted',
                      child: Text(context.l10n.adminExhausted),
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
                    context,
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
                ? const Center(child: AdaptiveSpinner())
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
                                child: Text(context.l10n.commonRetry),
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
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No coupons found',
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showCouponDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: Text(context.l10n.adminCreateCoupon),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AdaptiveRefreshIndicator(
                            onRefresh: () => ref
                                .read(adminCouponsProvider.notifier)
                                .loadCoupons(status: _statusFilter),
                            child: ListView.builder(
                              physics: adaptiveAlwaysScrollablePhysics(context),
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

  void _showCouponDialog(BuildContext context) {
    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CouponDialog(
        onSave: (data) async {
          final success =
              await ref.read(adminCouponsProvider.notifier).createCoupon(data);

          if (success && mounted) {
            Navigator.pop(context);
            showAdaptiveToast(
              context,
              message: context.l10n.adminCouponCreated,
              type: ToastType.success,
            );
          }
        },
      ),
    );
  }

  Future<void> _revokeCoupon(CouponListItemModel coupon) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: context.l10n.adminRevokeCoupon,
      message: 'Are you sure you want to revoke "${coupon.code}"? It will no longer be usable.',
      confirmText: context.l10n.adminRevoke,
      isDestructive: true,
    );

    if (confirmed == true) {
      final success =
          await ref.read(adminCouponsProvider.notifier).revokeCoupon(coupon.id);

      if (success && mounted) {
        showAdaptiveToast(
          context,
          message: context.l10n.adminCouponRevoked,
          type: ToastType.success,
        );
      }
    }
  }

  Future<void> _reactivateCoupon(CouponListItemModel coupon) async {
    final success = await ref
        .read(adminCouponsProvider.notifier)
        .reactivateCoupon(coupon.id);

    if (success && mounted) {
      showAdaptiveToast(
        context,
        message: context.l10n.adminCouponReactivated,
        type: ToastType.success,
      );
    }
  }

  Future<void> _confirmDelete(CouponListItemModel coupon) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: context.l10n.adminDeleteCoupon,
      message: 'Are you sure you want to delete "${coupon.code}"? This cannot be undone.',
      confirmText: context.l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed == true) {
      final success =
          await ref.read(adminCouponsProvider.notifier).deleteCoupon(coupon.id);

      if (success && mounted) {
        showAdaptiveToast(
          context,
          message: context.l10n.adminCouponDeleted,
          type: ToastType.success,
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
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(coupon.status);
    final typeColor = _getTypeColor(context, coupon.couponType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: AdaptiveTappable(
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
                      color: typeColor.withValues(alpha: 0.2),
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
                      color: statusColor.withValues(alpha: 0.2),
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
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTypeLabel(coupon.couponType),
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
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
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatUsage(coupon),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
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
                    color: theme.textTheme.bodySmall?.color,
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
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${_formatDate(coupon.validUntil!)}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
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
                      label: Text(context.l10n.adminReactivate),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  if (onRevoke != null)
                    TextButton.icon(
                      onPressed: onRevoke,
                      icon: const Icon(Icons.block, size: 18),
                      label: Text(context.l10n.adminRevoke),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(context.l10n.commonDelete),
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
    final picked = await showAdaptiveDatePicker(
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
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Coupon',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminCouponCode,
                    hintText: context.l10n.adminEGSAVE20,
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
                  decoration: InputDecoration(
                    labelText: context.l10n.adminDescriptionOptional,
                    hintText: context.l10n.adminInternalDescription,
                  ),
                ),
                const SizedBox(height: 16),
                AdaptiveDropdown<String>(
                  value: _couponType,
                  decoration: InputDecoration(labelText: context.l10n.adminDiscountType),
                  items: [
                    AdaptiveDropdownItem(value: 'percent', label: context.l10n.adminPercentageOff),
                    AdaptiveDropdownItem(value: 'fixed', label: context.l10n.adminFixedAmountOff),
                    AdaptiveDropdownItem(value: 'free_trial', label: context.l10n.adminFreeTrialDays),
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
                AdaptiveDropdown<String>(
                  value: _appliesTo,
                  decoration: InputDecoration(labelText: context.l10n.adminAppliesTo),
                  items: [
                    AdaptiveDropdownItem(value: 'both', label: context.l10n.adminAllTrainersTrainees),
                    AdaptiveDropdownItem(value: 'trainer', label: context.l10n.adminTrainerSubscriptionsOnly),
                    AdaptiveDropdownItem(value: 'trainee', label: context.l10n.adminTraineeCoachingOnly),
                  ],
                  onChanged: (v) => setState(() => _appliesTo = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxUsesController,
                  decoration: InputDecoration(
                    labelText: context.l10n.adminMaxUses0Unlimited,
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                AdaptiveTappable(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.adminExpiryDateOptional,
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
                            ? theme.textTheme.bodyLarge?.color
                            : theme.textTheme.bodySmall?.color,
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
                      child: Text(context.l10n.commonCancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: _isSaving
                          ? const AdaptiveSpinner.small()
                          : Text(context.l10n.adminCreate),
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

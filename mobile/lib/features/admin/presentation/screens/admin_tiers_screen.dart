import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tier_coupon_models.dart';
import '../providers/admin_provider.dart';

class AdminTiersScreen extends ConsumerStatefulWidget {
  const AdminTiersScreen({super.key});

  @override
  ConsumerState<AdminTiersScreen> createState() => _AdminTiersScreenState();
}

class _AdminTiersScreenState extends ConsumerState<AdminTiersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminTiersProvider.notifier).loadTiers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTiersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Subscription Tiers'),
        backgroundColor: AppTheme.background,
        actions: [
          if (state.tiers.isEmpty && !state.isLoading)
            TextButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final success = await ref
                          .read(adminTiersProvider.notifier)
                          .seedDefaultTiers();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Default tiers created'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.add_box),
              label: const Text('Seed Defaults'),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTierDialog(context),
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
                          onPressed: () =>
                              ref.read(adminTiersProvider.notifier).loadTiers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.tiers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 64,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subscription tiers',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final success = await ref
                                  .read(adminTiersProvider.notifier)
                                  .seedDefaultTiers();
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Default tiers created'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_box),
                            label: const Text('Create Default Tiers'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminTiersProvider.notifier).loadTiers(),
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.tiers.length,
                        onReorder: (oldIndex, newIndex) {
                          // Handle reorder if needed
                        },
                        itemBuilder: (context, index) {
                          final tier = state.tiers[index];
                          return _TierCard(
                            key: ValueKey(tier.id),
                            tier: tier,
                            onEdit: () => _showTierDialog(context, tier: tier),
                            onToggleActive: () => _toggleTierActive(tier),
                            onDelete: () => _confirmDelete(tier),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showTierDialog(BuildContext context, {SubscriptionTierModel? tier}) {
    showDialog(
      context: context,
      builder: (context) => _TierDialog(
        tier: tier,
        onSave: (data) async {
          final notifier = ref.read(adminTiersProvider.notifier);
          final success = tier == null
              ? await notifier.createTier(data)
              : await notifier.updateTier(tier.id, data);

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(tier == null ? 'Tier created' : 'Tier updated'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleTierActive(SubscriptionTierModel tier) async {
    final success =
        await ref.read(adminTiersProvider.notifier).toggleTierActive(tier.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              tier.isActive ? 'Tier deactivated' : 'Tier activated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(SubscriptionTierModel tier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Tier'),
        content: Text(
          'Are you sure you want to delete "${tier.displayName}"? This cannot be undone.',
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
          await ref.read(adminTiersProvider.notifier).deleteTier(tier.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tier deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _TierCard extends StatelessWidget {
  final SubscriptionTierModel tier;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TierCard({
    super.key,
    required this.tier,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(tier.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tier.isActive ? AppTheme.border : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getTierIcon(tier.name),
                      color: tierColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.displayName,
                            style: const TextStyle(
                              color: AppTheme.foreground,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (!tier.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        tier.name.toLowerCase(),
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tier.formattedPrice,
                  style: TextStyle(
                    color: tierColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (tier.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                tier.description,
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppTheme.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  tier.isUnlimited
                      ? 'Unlimited trainees'
                      : '${tier.traineeLimit} trainees max',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (tier.features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tier.features.map((feature) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.muted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    tier.isActive ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(tier.isActive ? 'Deactivate' : 'Activate'),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tierName) {
    switch (tierName.toUpperCase()) {
      case 'FREE':
        return Colors.grey;
      case 'STARTER':
        return Colors.blue;
      case 'PRO':
        return Colors.purple;
      case 'ENTERPRISE':
        return Colors.orange;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName.toUpperCase()) {
      case 'FREE':
        return Icons.card_giftcard;
      case 'STARTER':
        return Icons.rocket_launch;
      case 'PRO':
        return Icons.star;
      case 'ENTERPRISE':
        return Icons.business;
      default:
        return Icons.layers;
    }
  }
}

class _TierDialog extends StatefulWidget {
  final SubscriptionTierModel? tier;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _TierDialog({
    this.tier,
    required this.onSave,
  });

  @override
  State<_TierDialog> createState() => _TierDialogState();
}

class _TierDialogState extends State<_TierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _traineeLimitController;
  late final TextEditingController _featuresController;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tier?.name ?? '');
    _displayNameController =
        TextEditingController(text: widget.tier?.displayName ?? '');
    _descriptionController =
        TextEditingController(text: widget.tier?.description ?? '');
    _priceController = TextEditingController(
        text: widget.tier?.priceValue.toStringAsFixed(2) ?? '0.00');
    _traineeLimitController = TextEditingController(
        text: widget.tier?.traineeLimit.toString() ?? '0');
    _featuresController =
        TextEditingController(text: widget.tier?.features.join('\n') ?? '');
    _isActive = widget.tier?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _traineeLimitController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final features = _featuresController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await widget.onSave({
      'name': _nameController.text.toUpperCase().replaceAll(' ', '_'),
      'display_name': _displayNameController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'trainee_limit': int.tryParse(_traineeLimitController.text) ?? 0,
      'features': features,
      'is_active': _isActive,
    });

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tier != null;

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
                Text(
                  isEditing ? 'Edit Tier' : 'Create Tier',
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tier Name (Internal)',
                    hintText: 'e.g., PRO, STARTER',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z_]')),
                  ],
                  validator: (v) =>
                      v?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'e.g., Professional',
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Display name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of this tier',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (\$/month)',
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          final price = double.tryParse(v!);
                          if (price == null || price < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _traineeLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Trainee Limit',
                          hintText: '0 = unlimited',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _featuresController,
                  decoration: const InputDecoration(
                    labelText: 'Features (one per line)',
                    hintText: 'Basic analytics\nEmail support\n...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle:
                      const Text('Inactive tiers cannot be purchased'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
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
                          : Text(isEditing ? 'Update' : 'Create'),
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
}

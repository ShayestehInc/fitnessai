import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';

class TrainerPricingScreen extends ConsumerStatefulWidget {
  const TrainerPricingScreen({super.key});

  @override
  ConsumerState<TrainerPricingScreen> createState() => _TrainerPricingScreenState();
}

class _TrainerPricingScreenState extends ConsumerState<TrainerPricingScreen> {
  final _monthlyPriceController = TextEditingController();
  final _oneTimePriceController = TextEditingController();
  bool _monthlyEnabled = false;
  bool _oneTimeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerPricingProvider.notifier).loadPricing();
    });
  }

  @override
  void dispose() {
    _monthlyPriceController.dispose();
    _oneTimePriceController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final pricing = ref.read(trainerPricingProvider).pricing;
    if (pricing != null) {
      _monthlyPriceController.text = pricing.monthlyPrice.toStringAsFixed(2);
      _oneTimePriceController.text = pricing.oneTimePrice.toStringAsFixed(2);
      setState(() {
        _monthlyEnabled = pricing.monthlySubscriptionEnabled;
        _oneTimeEnabled = pricing.oneTimeConsultationEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerPricingProvider);

    ref.listen<TrainerPricingState>(trainerPricingProvider, (previous, next) {
      if (previous?.pricing == null && next.pricing != null) {
        _populateFields();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Set Your Prices',
          style: TextStyle(color: AppTheme.foreground),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Monthly Subscription
                  _buildPricingCard(
                    title: 'Monthly Subscription',
                    description: 'Recurring monthly coaching fee',
                    icon: Icons.calendar_month,
                    enabled: _monthlyEnabled,
                    onEnabledChanged: (value) {
                      setState(() => _monthlyEnabled = value);
                    },
                    priceController: _monthlyPriceController,
                    priceSuffix: '/month',
                  ),
                  const SizedBox(height: 16),

                  // One-Time Consultation
                  _buildPricingCard(
                    title: 'One-Time Consultation',
                    description: 'Single session or consultation fee',
                    icon: Icons.person,
                    enabled: _oneTimeEnabled,
                    onEnabledChanged: (value) {
                      setState(() => _oneTimeEnabled = value);
                    },
                    priceController: _oneTimePriceController,
                    priceSuffix: '',
                  ),
                  const SizedBox(height: 24),

                  // Preview Card
                  _buildPreviewCard(),
                  const SizedBox(height: 24),

                  // Save Button
                  _buildSaveButton(state),

                  // Error
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorCard(state.error!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Configuration',
          style: TextStyle(
            color: AppTheme.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your coaching prices. Trainees will see these when subscribing to your services.',
          style: TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String description,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TextEditingController priceController,
    required String priceSuffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppTheme.primary.withOpacity(0.1)
                      : AppTheme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppTheme.primary : AppTheme.mutedForeground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeColor: AppTheme.primary,
              ),
            ],
          ),

          if (enabled) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: AppTheme.mutedForeground.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (priceSuffix.isNotEmpty)
                  Text(
                    priceSuffix,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final monthlyPrice = double.tryParse(_monthlyPriceController.text) ?? 0;
    final oneTimePrice = double.tryParse(_oneTimePriceController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: AppTheme.mutedForeground, size: 20),
              const SizedBox(width: 8),
              Text(
                'Preview (what trainees see)',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),

          if (_monthlyEnabled && monthlyPrice > 0) ...[
            _buildPreviewRow(
              'Monthly Coaching',
              '\$${monthlyPrice.toStringAsFixed(2)}/mo',
              Icons.calendar_month,
            ),
            const SizedBox(height: 12),
          ],

          if (_oneTimeEnabled && oneTimePrice > 0) ...[
            _buildPreviewRow(
              'One-Time Consultation',
              '\$${oneTimePrice.toStringAsFixed(2)}',
              Icons.person,
            ),
          ],

          if (!_monthlyEnabled && !_oneTimeEnabled)
            Text(
              'Enable at least one pricing option to allow trainees to subscribe.',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String title, String price, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.foreground,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          price,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(TrainerPricingState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isSaving
            ? null
            : () async {
                final monthlyPrice = double.tryParse(_monthlyPriceController.text);
                final oneTimePrice = double.tryParse(_oneTimePriceController.text);

                await ref.read(trainerPricingProvider.notifier).updatePricing(
                  monthlySubscriptionPrice: monthlyPrice,
                  monthlySubscriptionEnabled: _monthlyEnabled,
                  oneTimeConsultationPrice: oneTimePrice,
                  oneTimeConsultationEnabled: _oneTimeEnabled,
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryForeground,
                ),
              )
            : const Text(
                'Save Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.destructive, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppTheme.destructive,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/payment_models.dart';
import '../providers/payment_provider.dart';

class TrainerPricingViewScreen extends ConsumerWidget {
  final int trainerId;
  final String? trainerName;

  const TrainerPricingViewScreen({
    super.key,
    required this.trainerId,
    this.trainerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(trainerPublicPricingProvider(trainerId));
    final checkoutState = ref.watch(checkoutProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          trainerName ?? 'Trainer Pricing',
          style: const TextStyle(color: AppTheme.foreground),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
        data: (pricing) {
          if (pricing == null) {
            return _buildErrorState(context, 'Trainer has not set up pricing');
          }
          return _buildPricingContent(context, ref, pricing, checkoutState);
        },
      ),
    );
  }

  Widget _buildPricingContent(
    BuildContext context,
    WidgetRef ref,
    TrainerPublicPricingModel pricing,
    CheckoutState checkoutState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trainer Header
          _buildTrainerHeader(pricing),
          const SizedBox(height: 24),

          // Warning if no Stripe account
          if (!pricing.canAcceptPayments) ...[
            _buildWarningCard(
              'This trainer hasn\'t completed their payment setup yet. Check back later.',
            ),
            const SizedBox(height: 24),
          ],

          // No offerings
          if (!pricing.hasAnyOffering) ...[
            _buildWarningCard(
              'This trainer hasn\'t set up any coaching packages yet.',
            ),
          ],

          // Monthly Subscription
          if (pricing.monthlySubscriptionEnabled) ...[
            _buildPricingCard(
              context,
              ref,
              title: 'Monthly Coaching',
              description: 'Get ongoing coaching and support with personalized workout and nutrition plans.',
              price: '\$${pricing.monthlyPrice.toStringAsFixed(2)}',
              period: '/month',
              icon: Icons.calendar_month,
              features: const [
                'Personalized workout programs',
                'Nutrition guidance',
                'Progress tracking',
                'Direct messaging',
              ],
              isEnabled: pricing.canAcceptPayments,
              isLoading: checkoutState.isLoading,
              onSubscribe: () async {
                final success = await ref
                    .read(checkoutProvider.notifier)
                    .startSubscriptionCheckout(trainerId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(checkoutState.error ?? 'Failed to start checkout'),
                      backgroundColor: AppTheme.destructive,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // One-Time Consultation
          if (pricing.oneTimeConsultationEnabled) ...[
            _buildPricingCard(
              context,
              ref,
              title: 'One-Time Consultation',
              description: 'Get a single session for a specific question or initial assessment.',
              price: '\$${pricing.oneTimePrice.toStringAsFixed(2)}',
              period: '',
              icon: Icons.person,
              features: const [
                'Personalized assessment',
                'Action plan',
                'Follow-up resources',
              ],
              isEnabled: pricing.canAcceptPayments,
              isLoading: checkoutState.isLoading,
              onSubscribe: () async {
                final success = await ref
                    .read(checkoutProvider.notifier)
                    .startOneTimeCheckout(trainerId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(checkoutState.error ?? 'Failed to start checkout'),
                      backgroundColor: AppTheme.destructive,
                    ),
                  );
                }
              },
            ),
          ],

          // Error display
          if (checkoutState.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(checkoutState.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainerHeader(TrainerPublicPricingModel pricing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pricing.trainerName ?? 'Trainer',
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pricing.trainerEmail ?? '',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (pricing.canAcceptPayments)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required String price,
    required String period,
    required IconData icon,
    required List<String> features,
    required bool isEnabled,
    required bool isLoading,
    required VoidCallback onSubscribe,
  }) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Features
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 16),

          // Subscribe Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled && !isLoading ? onSubscribe : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
                disabledBackgroundColor: AppTheme.muted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryForeground,
                      ),
                    )
                  : Text(
                      period.isEmpty ? 'Purchase' : 'Subscribe',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ),
        ],
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Pricing',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

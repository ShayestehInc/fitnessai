import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';

class StripeConnectScreen extends ConsumerStatefulWidget {
  const StripeConnectScreen({super.key});

  @override
  ConsumerState<StripeConnectScreen> createState() => _StripeConnectScreenState();
}

class _StripeConnectScreenState extends ConsumerState<StripeConnectScreen> {
  @override
  void initState() {
    super.initState();
    // Load Stripe Connect status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stripeConnectProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stripeConnectProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Payment Setup',
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

                  // Status Card
                  _buildStatusCard(state),
                  const SizedBox(height: 24),

                  // Actions
                  _buildActions(state),

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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stripe Connect',
                    style: TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Receive payments from your trainees',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
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
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.mutedForeground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect your Stripe account to receive payments directly when trainees subscribe to your coaching.',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(StripeConnectState state) {
    final isConnected = state.isConnected;
    final isReady = state.isReadyForPayments;

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.withOpacity(0.1)
                      : isConnected
                          ? Colors.orange.withOpacity(0.1)
                          : AppTheme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isReady
                      ? Icons.check_circle
                      : isConnected
                          ? Icons.pending
                          : Icons.link_off,
                  color: isReady
                      ? Colors.green
                      : isConnected
                          ? Colors.orange
                          : AppTheme.mutedForeground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady
                          ? 'Ready for Payments'
                          : isConnected
                              ? 'Setup In Progress'
                              : 'Not Connected',
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isReady
                          ? 'Your account is fully set up'
                          : isConnected
                              ? 'Complete onboarding to accept payments'
                              : 'Connect Stripe to receive payments',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isConnected) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),

            // Status Details
            _buildStatusRow(
              'Charges Enabled',
              state.status?.chargesEnabled ?? false,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Payouts Enabled',
              state.status?.payoutsEnabled ?? false,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Details Submitted',
              state.status?.detailsSubmitted ?? false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Row(
      children: [
        Icon(
          value ? Icons.check_circle : Icons.circle_outlined,
          color: value ? Colors.green : AppTheme.mutedForeground,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: value ? AppTheme.foreground : AppTheme.mutedForeground,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(StripeConnectState state) {
    final isConnected = state.isConnected;
    final isReady = state.isReadyForPayments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isConnected || !isReady) ...[
          ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(stripeConnectProvider.notifier).startOnboarding();
                  },
            icon: const Icon(Icons.link),
            label: Text(isConnected ? 'Continue Setup' : 'Connect with Stripe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (isReady) ...[
          ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(stripeConnectProvider.notifier).openDashboard();
                  },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Stripe Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/trainer/pricing'),
            icon: const Icon(Icons.attach_money),
            label: const Text('Set Your Prices'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.foreground,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            ref.read(stripeConnectProvider.notifier).loadStatus();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh Status'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.mutedForeground,
          ),
        ),
      ],
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

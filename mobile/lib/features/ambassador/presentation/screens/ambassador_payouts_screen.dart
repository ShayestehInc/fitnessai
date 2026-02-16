import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/api_constants.dart';

/// Screen showing ambassador payout history and Stripe Connect status.
class AmbassadorPayoutsScreen extends ConsumerStatefulWidget {
  const AmbassadorPayoutsScreen({super.key});

  @override
  ConsumerState<AmbassadorPayoutsScreen> createState() =>
      _AmbassadorPayoutsScreenState();
}

class _AmbassadorPayoutsScreenState
    extends ConsumerState<AmbassadorPayoutsScreen> {
  Map<String, dynamic>? _connectStatus;
  List<Map<String, dynamic>> _payouts = [];
  bool _isLoading = true;
  String? _error;
  bool _isOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final statusResp =
          await apiClient.dio.get(ApiConstants.ambassadorConnectStatus);
      final payoutsResp =
          await apiClient.dio.get(ApiConstants.ambassadorPayouts);

      if (!mounted) return;
      setState(() {
        _connectStatus = statusResp.data as Map<String, dynamic>;
        final payoutData = payoutsResp.data;
        if (payoutData is List) {
          _payouts = payoutData
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } else if (payoutData is Map<String, dynamic> &&
            payoutData.containsKey('results')) {
          _payouts = (payoutData['results'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load payout data';
      });
    }
  }

  Future<void> _startOnboarding() async {
    setState(() => _isOnboarding = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final resp =
          await apiClient.dio.post(ApiConstants.ambassadorConnectOnboard);
      final url = (resp.data as Map<String, dynamic>)['onboarding_url'] as String?;
      if (url != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Opening Stripe onboarding... Complete setup in browser.'),
            duration: const Duration(seconds: 6),
          ),
        );
        // In a real app, launch the URL in the browser:
        // launchUrl(Uri.parse(url));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start Stripe onboarding')),
      );
    } finally {
      if (mounted) setState(() => _isOnboarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payouts'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildConnectStatusCard(theme),
                      const SizedBox(height: 16),
                      _buildPayoutHistory(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildConnectStatusCard(ThemeData theme) {
    final status = _connectStatus;
    final hasAccount = status?['has_account'] as bool? ?? false;
    final chargesEnabled = status?['charges_enabled'] as bool? ?? false;
    final payoutsEnabled = status?['payouts_enabled'] as bool? ?? false;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!hasAccount) {
      statusColor = Colors.orange;
      statusText = 'Not Connected';
      statusIcon = Icons.link_off;
    } else if (chargesEnabled && payoutsEnabled) {
      statusColor = Colors.green;
      statusText = 'Active';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending Verification';
      statusIcon = Icons.hourglass_bottom;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stripe Connect',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasAccount
                ? 'Your Stripe account is connected. Payouts will be processed automatically.'
                : 'Connect your Stripe account to receive payouts for your referral commissions.',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          if (!hasAccount || !(chargesEnabled && payoutsEnabled)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isOnboarding ? null : _startOnboarding,
                child: _isOnboarding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(hasAccount
                        ? 'Complete Verification'
                        : 'Connect Stripe Account'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayoutHistory(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout History',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_payouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payouts yet',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payouts will appear here once triggered by admin.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ..._payouts.map((payout) => _buildPayoutTile(theme, payout)),
      ],
    );
  }

  Widget _buildPayoutTile(ThemeData theme, Map<String, dynamic> payout) {
    final amount = payout['amount'] as String? ?? '0.00';
    final status = payout['status'] as String? ?? 'pending';
    final createdAt = payout['created_at'] as String?;
    final date = createdAt != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt))
        : '';

    final statusColor = switch (status) {
      'completed' => Colors.green,
      'failed' => Colors.red,
      _ => Colors.orange,
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
          Icon(Icons.payment, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$$amount',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

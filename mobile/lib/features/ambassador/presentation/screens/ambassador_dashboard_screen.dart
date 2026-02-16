import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/ambassador_models.dart';
import '../providers/ambassador_provider.dart';
import '../widgets/monthly_earnings_chart.dart';

class AmbassadorDashboardScreen extends ConsumerStatefulWidget {
  const AmbassadorDashboardScreen({super.key});

  @override
  ConsumerState<AmbassadorDashboardScreen> createState() =>
      _AmbassadorDashboardScreenState();
}

class _AmbassadorDashboardScreenState
    extends ConsumerState<AmbassadorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ambassadorDashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ambassadorDashboardProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ambassador Dashboard'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(theme, state.error!)
              : state.data == null
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(ambassadorDashboardProvider.notifier)
                          .loadDashboard(),
                      child: _buildContent(theme, state),
                    ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(ambassadorDashboardProvider.notifier).loadDashboard(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'Welcome, Ambassador!',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share your referral code to start earning commissions on every trainer you refer.',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(ambassadorDashboardProvider.notifier).loadDashboard(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AmbassadorDashboardState state) {
    final data = state.data!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!data.isActive) _buildSuspendedBanner(theme),
          _buildEarningsCard(theme, data),
          const SizedBox(height: 16),
          _buildReferralCodeCard(theme, data),
          const SizedBox(height: 16),
          MonthlyEarningsChart(monthlyEarnings: data.monthlyEarnings),
          const SizedBox(height: 16),
          _buildStatsRow(theme, data),
          const SizedBox(height: 24),
          _buildRecentReferrals(theme, data),
        ],
      ),
    );
  }

  Widget _buildSuspendedBanner(ThemeData theme) {
    return Semantics(
      label: 'Warning: Your ambassador account is currently suspended. Contact admin for details.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your account is currently suspended. Please contact the admin team for assistance.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(ThemeData theme, AmbassadorDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${data.totalEarnings}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEarningStat('Pending', '\$${data.pendingEarnings}'),
              const SizedBox(width: 24),
              _buildEarningStat('Commission', '${data.commissionPercent.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard(ThemeData theme, AmbassadorDashboardData data) {
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
          Text(
            'Your Referral Code',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data.referralCode,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                  onPressed: () => _copyCode(data.referralCode),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: 'Share referral code ${data.referralCode}',
              child: ElevatedButton.icon(
                onPressed: () => _shareCode(data.referralCode),
                icon: const Icon(Icons.share),
                label: const Text('Share Referral Code'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, AmbassadorDashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            'Total',
            data.totalReferrals.toString(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            theme,
            'Active',
            data.activeReferrals.toString(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            theme,
            'Pending',
            data.pendingReferrals.toString(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            theme,
            'Churned',
            data.churnedReferrals.toString(),
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, Color color) {
    return Semantics(
      label: '$label referrals: $value',
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
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReferrals(ThemeData theme, AmbassadorDashboardData data) {
    if (data.recentReferrals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text(
                'No referrals yet. Share your code!',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Referrals',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...data.recentReferrals.map<Widget>((referral) => _buildReferralTile(theme, referral)),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              referral.trainer.initials,
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
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
                  referral.trainer.email,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareCode(String code) async {
    final message =
        'Join FitnessAI and grow your training business! Use my referral code $code when you sign up.';
    try {
      await Share.share(message);
    } catch (_) {
      // Fallback to clipboard if native share fails (e.g., on some emulators)
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share message copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

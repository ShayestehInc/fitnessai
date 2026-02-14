import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ambassador_provider.dart';

class AmbassadorSettingsScreen extends ConsumerStatefulWidget {
  const AmbassadorSettingsScreen({super.key});

  @override
  ConsumerState<AmbassadorSettingsScreen> createState() =>
      _AmbassadorSettingsScreenState();
}

class _AmbassadorSettingsScreenState
    extends ConsumerState<AmbassadorSettingsScreen> {
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
    final authState = ref.watch(authStateProvider);
    final dashState = ref.watch(ambassadorDashboardProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user?.displayName ?? 'A')[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? '',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ambassador info with loading/error states
          _buildAmbassadorDetailsCard(theme, dashState),
          const SizedBox(height: 24),

          // Logout button with confirmation
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: 'Log out of your account',
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(theme),
                icon: Icon(Icons.logout, color: theme.colorScheme.error),
                label: Text('Log Out', style: TextStyle(color: theme.colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbassadorDetailsCard(ThemeData theme, AmbassadorDashboardState dashState) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ambassador Details',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (dashState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (dashState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load details. Pull to refresh.',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () => ref.read(ambassadorDashboardProvider.notifier).loadDashboard(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildInfoRow(
              theme,
              'Commission Rate',
              dashState.data != null
                  ? '${dashState.data!.commissionPercent.toStringAsFixed(0)}%'
                  : '--',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              theme,
              'Referral Code',
              dashState.data?.referralCode ?? '--',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              theme,
              'Total Lifetime Earnings',
              dashState.data != null ? '\$${dashState.data!.totalEarnings}' : '--',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              theme,
              'Status',
              dashState.data == null
                  ? '--'
                  : dashState.data!.isActive
                      ? 'Active'
                      : 'Inactive',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

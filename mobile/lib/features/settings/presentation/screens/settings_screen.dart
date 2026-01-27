import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final role = user?.role ?? 'TRAINEE';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppTheme.foreground),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role-specific settings
          if (role == 'ADMIN') ..._buildAdminSettings(context, ref, user?.email),
          if (role == 'TRAINER') ..._buildTrainerSettings(context, ref, user?.email),
          if (role == 'TRAINEE') ..._buildTraineeSettings(context, ref, user?.email),
        ],
      ),
    );
  }

  List<Widget> _buildAdminSettings(BuildContext context, WidgetRef ref, String? email) {
    return [
      // Admin Info
      _buildSectionHeader('ADMIN ACCOUNT'),
      _buildSettingsTile(
        icon: Icons.admin_panel_settings,
        title: 'Admin Profile',
        subtitle: email ?? 'admin@fitnessai.com',
        onTap: null,
      ),

      const SizedBox(height: 24),

      // Platform Management
      _buildSectionHeader('PLATFORM'),
      _buildSettingsTile(
        icon: Icons.dashboard,
        title: 'Dashboard',
        subtitle: 'View platform statistics',
        onTap: () => context.go('/admin'),
      ),
      _buildSettingsTile(
        icon: Icons.people,
        title: 'Manage Trainers',
        subtitle: 'View and manage all trainers',
        onTap: () => context.go('/admin/trainers'),
      ),
      _buildSettingsTile(
        icon: Icons.credit_card,
        title: 'Subscriptions',
        subtitle: 'Manage billing and subscriptions',
        onTap: () => context.go('/admin/subscriptions'),
      ),

      const SizedBox(height: 24),

      // Pricing & Promotions
      _buildSectionHeader('PRICING & PROMOTIONS'),
      _buildSettingsTile(
        icon: Icons.layers,
        title: 'Subscription Tiers',
        subtitle: 'Manage tier pricing and features',
        onTap: () => context.push('/admin/tiers'),
      ),
      _buildSettingsTile(
        icon: Icons.local_offer,
        title: 'Coupons',
        subtitle: 'Create and manage platform coupons',
        onTap: () => context.push('/admin/coupons'),
      ),

      const SizedBox(height: 24),

      // System
      _buildSectionHeader('SYSTEM'),
      _buildSettingsTile(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Configure system notifications',
        onTap: () {},
      ),
      _buildSettingsTile(
        icon: Icons.security,
        title: 'Security',
        subtitle: 'Manage platform security settings',
        onTap: () {},
      ),

      const SizedBox(height: 24),

      // Account Actions
      _buildSectionHeader('ACCOUNT'),
      _buildSettingsTile(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out of admin account',
        isDestructive: true,
        onTap: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
    ];
  }

  List<Widget> _buildTrainerSettings(BuildContext context, WidgetRef ref, String? email) {
    return [
      // Profile Section
      _buildSectionHeader('PROFILE'),
      _buildSettingsTile(
        icon: Icons.person_outline,
        title: 'Business Profile',
        subtitle: 'Update your trainer profile',
        onTap: () => context.push('/edit-profile'),
      ),
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: email ?? 'Not set',
        onTap: null,
      ),

      const SizedBox(height: 24),

      // Business Section
      _buildSectionHeader('BUSINESS'),
      _buildSettingsTile(
        icon: Icons.credit_card,
        title: 'Subscription',
        subtitle: 'Manage your subscription plan',
        onTap: () => context.push('/trainer/subscription'),
      ),
      _buildSettingsTile(
        icon: Icons.people_outline,
        title: 'My Trainees',
        subtitle: 'View and manage your trainees',
        onTap: () => context.go('/trainer/trainees'),
      ),
      _buildSettingsTile(
        icon: Icons.bar_chart,
        title: 'Analytics',
        subtitle: 'View trainee progress analytics',
        onTap: () {},
      ),

      const SizedBox(height: 24),

      // Payments Section
      _buildSectionHeader('PAYMENTS'),
      _buildSettingsTile(
        icon: Icons.account_balance,
        title: 'Payment Setup',
        subtitle: 'Connect Stripe to receive payments',
        onTap: () => context.push('/trainer/stripe-connect'),
      ),
      _buildSettingsTile(
        icon: Icons.attach_money,
        title: 'Set Your Prices',
        subtitle: 'Configure coaching subscription pricing',
        onTap: () => context.push('/trainer/pricing'),
      ),
      _buildSettingsTile(
        icon: Icons.local_offer,
        title: 'My Coupons',
        subtitle: 'Create discounts for your trainees',
        onTap: () => context.push('/trainer/coupons'),
      ),
      _buildSettingsTile(
        icon: Icons.receipt_long,
        title: 'Payment History',
        subtitle: 'View received payments and subscribers',
        onTap: () => context.push('/trainer/payments'),
      ),

      const SizedBox(height: 24),

      // Notifications
      _buildSectionHeader('NOTIFICATIONS'),
      _buildSettingsTile(
        icon: Icons.notifications_outlined,
        title: 'Push Notifications',
        subtitle: 'Manage notification preferences',
        onTap: () {},
      ),
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: 'Email Notifications',
        subtitle: 'Configure email alerts',
        onTap: () {},
      ),

      const SizedBox(height: 24),

      // Feature Requests
      _buildSectionHeader('FEEDBACK'),
      _buildSettingsTile(
        icon: Icons.lightbulb_outline,
        title: 'Feature Requests',
        subtitle: 'Suggest new features or vote on ideas',
        onTap: () => context.push('/feature-requests'),
      ),
      _buildSettingsTile(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get help with using the platform',
        onTap: () {},
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader('ACCOUNT'),
      _buildSettingsTile(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        isDestructive: true,
        onTap: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),

      const SizedBox(height: 24),

      // Danger Zone
      _buildSectionHeader('DANGER ZONE'),
      _buildSettingsTile(
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        isDestructive: true,
        onTap: () => _showDeleteAccountDialog(context, ref),
      ),
    ];
  }

  List<Widget> _buildTraineeSettings(BuildContext context, WidgetRef ref, String? email) {
    return [
      // Profile Section
      _buildSectionHeader('PROFILE'),
      _buildSettingsTile(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        onTap: () => context.push('/edit-profile'),
      ),
      _buildSettingsTile(
        icon: Icons.fitness_center,
        title: 'Fitness Goals',
        subtitle: 'Change your activity level and goals',
        onTap: () => context.push('/edit-goals'),
      ),
      _buildSettingsTile(
        icon: Icons.restaurant_menu,
        title: 'Diet Preferences',
        subtitle: 'Update diet type and meal settings',
        onTap: () => context.push('/edit-diet'),
      ),

      const SizedBox(height: 24),

      // Tracking Settings
      _buildSectionHeader('TRACKING'),
      _buildSettingsTile(
        icon: Icons.monitor_weight_outlined,
        title: 'Check-in Days',
        subtitle: 'Set your weigh-in schedule',
        onTap: () => context.push('/edit-diet'),
      ),
      _buildSettingsTile(
        icon: Icons.notifications_outlined,
        title: 'Reminders',
        subtitle: 'Configure workout and meal reminders',
        onTap: () {},
      ),

      const SizedBox(height: 24),

      // Subscription Section
      _buildSectionHeader('SUBSCRIPTION'),
      _buildSettingsTile(
        icon: Icons.credit_card,
        title: 'My Subscriptions',
        subtitle: 'Manage coaching subscriptions',
        onTap: () => context.push('/my-subscription'),
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader('ACCOUNT'),
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: email ?? 'Not set',
        onTap: null,
      ),
      _buildSettingsTile(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        isDestructive: true,
        onTap: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),

      const SizedBox(height: 24),

      // Danger Zone
      _buildSectionHeader('DANGER ZONE'),
      _buildSettingsTile(
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        isDestructive: true,
        onTap: () => _showDeleteAccountDialog(context, ref),
      ),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.destructive : AppTheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.destructive : AppTheme.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 12,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: AppTheme.mutedForeground)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.foreground),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await ref.read(authStateProvider.notifier).deleteAccount();
              if (result['success'] == true && context.mounted) {
                context.go('/login');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['error'] ?? 'Failed to delete account'),
                    backgroundColor: AppTheme.destructive,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}

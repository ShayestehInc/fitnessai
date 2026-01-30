import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final role = user?.role ?? 'TRAINEE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
    int index = 0;
    return [
      // Admin Info
      _buildSectionHeader(context, 'ADMIN ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.admin_panel_settings,
        title: 'Admin Profile',
        subtitle: email ?? 'admin@fitnessai.com',
        onTap: null,
        index: index++,
      ),

      const SizedBox(height: 24),

      // Platform Management
      _buildSectionHeader(context, 'PLATFORM', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.dashboard,
        title: 'Dashboard',
        subtitle: 'View platform statistics',
        onTap: () => context.go('/admin'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.people,
        title: 'Manage Trainers',
        subtitle: 'View and manage all trainers',
        onTap: () => context.go('/admin/trainers'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.credit_card,
        title: 'Subscriptions',
        subtitle: 'Manage billing and subscriptions',
        onTap: () => context.go('/admin/subscriptions'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Pricing & Promotions
      _buildSectionHeader(context, 'PRICING & PROMOTIONS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.layers,
        title: 'Subscription Tiers',
        subtitle: 'Manage tier pricing and features',
        onTap: () => context.push('/admin/tiers'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.local_offer,
        title: 'Coupons',
        subtitle: 'Create and manage platform coupons',
        onTap: () => context.push('/admin/coupons'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Appearance
      _buildSectionHeader(context, 'APPEARANCE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.palette_outlined,
        title: 'Appearance',
        subtitle: 'Theme, colors, and display',
        onTap: () => context.push('/theme-settings'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // System
      _buildSectionHeader(context, 'SYSTEM', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Configure system notifications',
        onTap: () {},
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.security,
        title: 'Security',
        subtitle: 'Manage platform security settings',
        onTap: () {},
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Actions
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
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
        index: index++,
      ),
    ];
  }

  List<Widget> _buildTrainerSettings(BuildContext context, WidgetRef ref, String? email) {
    int index = 0;
    return [
      // Profile Section
      _buildSectionHeader(context, 'PROFILE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.person_outline,
        title: 'Business Profile',
        subtitle: 'Update your trainer profile',
        onTap: () => context.push('/edit-profile'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: email ?? 'Not set',
        onTap: null,
        index: index++,
      ),

      const SizedBox(height: 24),

      // Business Section
      _buildSectionHeader(context, 'BUSINESS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.credit_card,
        title: 'Subscription',
        subtitle: 'Manage your subscription plan',
        onTap: () => context.push('/trainer/subscription'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.bar_chart,
        title: 'Analytics',
        subtitle: 'View trainee progress analytics',
        onTap: () {},
        index: index++,
      ),

      const SizedBox(height: 24),

      // Scheduling Section
      _buildSectionHeader(context, 'SCHEDULING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.calendar_month,
        title: 'Calendar Integration',
        subtitle: 'Connect Google or Microsoft calendar',
        onTap: () => context.push('/trainer/calendar'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Payments Section
      _buildSectionHeader(context, 'PAYMENTS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.account_balance,
        title: 'Payment Setup',
        subtitle: 'Connect Stripe to receive payments',
        onTap: () => context.push('/trainer/stripe-connect'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.attach_money,
        title: 'Set Your Prices',
        subtitle: 'Configure coaching subscription pricing',
        onTap: () => context.push('/trainer/pricing'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.local_offer,
        title: 'My Coupons',
        subtitle: 'Create discounts for your trainees',
        onTap: () => context.push('/trainer/coupons'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.receipt_long,
        title: 'Payment History',
        subtitle: 'View received payments and subscribers',
        onTap: () => context.push('/trainer/payments'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Appearance
      _buildSectionHeader(context, 'APPEARANCE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.palette_outlined,
        title: 'Appearance',
        subtitle: 'Theme, colors, and display',
        onTap: () => context.push('/theme-settings'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Notifications
      _buildSectionHeader(context, 'NOTIFICATIONS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: 'Push Notifications',
        subtitle: 'Manage notification preferences',
        onTap: () {},
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: 'Email Notifications',
        subtitle: 'Configure email alerts',
        onTap: () {},
        index: index++,
      ),

      const SizedBox(height: 24),

      // Feature Requests
      _buildSectionHeader(context, 'FEEDBACK', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.lightbulb_outline,
        title: 'Feature Requests',
        subtitle: 'Suggest new features or vote on ideas',
        onTap: () => context.push('/feature-requests'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get help with using the platform',
        onTap: () {},
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
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
        index: index++,
      ),

      const SizedBox(height: 24),

      // Danger Zone
      _buildSectionHeader(context, 'DANGER ZONE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        isDestructive: true,
        onTap: () => _openDeleteAccountScreen(context),
        index: index++,
      ),
    ];
  }

  List<Widget> _buildTraineeSettings(BuildContext context, WidgetRef ref, String? email) {
    int index = 0;
    return [
      // Profile Section
      _buildSectionHeader(context, 'PROFILE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        onTap: () => context.push('/edit-profile'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.fitness_center,
        title: 'Fitness Goals',
        subtitle: 'Change your activity level and goals',
        onTap: () => context.push('/edit-goals'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.restaurant_menu,
        title: 'Diet Preferences',
        subtitle: 'Update diet type and meal settings',
        onTap: () => context.push('/edit-diet'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Tracking Settings
      _buildSectionHeader(context, 'TRACKING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.monitor_weight_outlined,
        title: 'Check-in Days',
        subtitle: 'Set your weigh-in schedule',
        onTap: () => context.push('/edit-diet'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: 'Reminders',
        subtitle: 'Configure workout and meal reminders',
        onTap: () {},
        index: index++,
      ),

      const SizedBox(height: 24),

      // Subscription Section
      _buildSectionHeader(context, 'SUBSCRIPTION', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.credit_card,
        title: 'My Subscriptions',
        subtitle: 'Manage coaching subscriptions',
        onTap: () => context.push('/my-subscription'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: email ?? 'Not set',
        onTap: null,
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
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
        index: index++,
      ),

      const SizedBox(height: 24),

      // Danger Zone
      _buildSectionHeader(context, 'DANGER ZONE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account and all data',
        isDestructive: true,
        onTap: () => _openDeleteAccountScreen(context),
        index: index++,
      ),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title, int index) {
    final theme = Theme.of(context);
    return StaggeredListItem(
      index: index,
      delay: const Duration(milliseconds: 30),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required int index,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final destructiveColor = theme.colorScheme.error;

    return StaggeredListItem(
      index: index,
      delay: const Duration(milliseconds: 30),
      child: AnimatedPress(
        onTap: onTap,
        scaleDown: onTap != null ? 0.98 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDestructive ? destructiveColor : primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? destructiveColor : primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isDestructive ? destructiveColor : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: onTap != null
                ? Icon(
                    Icons.chevron_right,
                    color: theme.textTheme.bodySmall?.color,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _openDeleteAccountScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }
}

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: AppTheme.foreground),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader('Profile'),
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

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: user?.email ?? 'Not set',
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
        ],
      ),
    );
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

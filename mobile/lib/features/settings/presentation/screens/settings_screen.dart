import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    final result = await ref.read(authStateProvider.notifier).uploadProfileImage(image.path);

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to upload image')),
      );
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingImage = true);

    final result = await ref.read(authStateProvider.notifier).removeProfileImage();

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to remove image')),
      );
    }
  }

  void _showImageOptions() {
    final user = ref.read(authStateProvider).user;
    final hasImage = user?.profileImage != null;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            if (hasImage)
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Profile Picture Section - shown for all roles
          _buildProfilePictureSection(context, user?.profileImage, user?.displayName ?? ''),
          const SizedBox(height: 24),
          // Role-specific settings
          if (role == 'ADMIN') ..._buildAdminSettings(context, user?.email),
          if (role == 'TRAINER') ..._buildTrainerSettings(context, user?.email),
          if (role == 'TRAINEE') ..._buildTraineeSettings(context, user?.email),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(BuildContext context, String? profileImage, String displayName) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return StaggeredListItem(
      index: 0,
      delay: const Duration(milliseconds: 30),
      child: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _showImageOptions,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : profileImage != null
                            ? ClipOval(
                                child: Image.network(
                                  profileImage,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildInitials(displayName, theme),
                                ),
                              )
                            : _buildInitials(displayName, theme),
                  ),
                  if (!_isUploadingImage)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to change photo',
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

  Widget _buildInitials(String name, ThemeData theme) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildAdminSettings(BuildContext context, String? email) {
    int index = 1; // Start at 1 since profile picture is index 0
    return [
      // Admin Info
      _buildSectionHeader(context, 'PROFILE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.badge_outlined,
        title: 'Edit Name',
        subtitle: 'Update your name',
        onTap: () => context.push('/edit-name'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: email ?? 'admin@fitnessai.com',
        onTap: null,
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
        onTap: () => context.push('/admin/notifications'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.security,
        title: 'Security',
        subtitle: 'Password, 2FA, and sessions',
        onTap: () => context.push('/admin/security'),
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
        onTap: () => _handleLogout(),
        index: index++,
      ),
    ];
  }

  List<Widget> _buildTrainerSettings(BuildContext context, String? email) {
    int index = 1; // Start at 1 since profile picture is index 0
    return [
      // Profile Section
      _buildSectionHeader(context, 'PROFILE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.badge_outlined,
        title: 'Edit Name & Business',
        subtitle: 'Update your name and business name',
        onTap: () => context.push('/edit-name'),
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
        onTap: () => _showComingSoon(context),
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

      // Branding
      _buildSectionHeader(context, 'BRANDING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.brush_outlined,
        title: 'Branding',
        subtitle: 'Customize your app colors, logo, and name',
        onTap: () => context.push('/trainer/branding'),
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
        onTap: () => _showComingSoon(context),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: 'Email Notifications',
        subtitle: 'Configure email alerts',
        onTap: () => _showComingSoon(context),
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
        onTap: () => _showComingSoon(context),
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
        onTap: () => _handleLogout(),
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

  List<Widget> _buildTraineeSettings(BuildContext context, String? email) {
    int index = 1; // Start at 1 since profile picture is index 0
    return [
      // Profile Section
      _buildSectionHeader(context, 'PROFILE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.badge_outlined,
        title: 'Edit Name',
        subtitle: 'Update your name',
        onTap: () => context.push('/edit-name'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.person_outline,
        title: 'Body Measurements',
        subtitle: 'Update age, height, and weight',
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
        onTap: () => _showComingSoon(context),
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
        onTap: () => _handleLogout(),
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

  Future<void> _handleLogout() async {
    final unsyncedCount = await ref.read(unsyncedCountProvider.future);

    if (!mounted) return;

    if (unsyncedCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsynced Data'),
          content: Text(
            'You have $unsyncedCount unsynced item${unsyncedCount == 1 ? '' : 's'} '
            'that will be lost if you log out. '
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Logout Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Clear local database for this user before logging out
      final db = ref.read(databaseProvider);
      final userId = ref.read(authStateProvider).user?.id;
      if (userId != null) {
        await db.clearUserData(userId);
      }
    }

    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
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

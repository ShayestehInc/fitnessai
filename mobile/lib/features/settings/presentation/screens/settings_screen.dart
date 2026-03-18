import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_route.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'delete_account_screen.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
      showAdaptiveToast(context, message: result['error'] ?? 'Failed to upload image', type: ToastType.error);
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: context.l10n.settingsRemoveProfilePicture,
      message: context.l10n.settingsAreYouSureYouWantToRemoveYourProfilePicture,
      confirmText: context.l10n.programsRemove,
    );

    if (confirmed != true) return;

    setState(() => _isUploadingImage = true);

    final result = await ref.read(authStateProvider.notifier).removeProfileImage();

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] != true) {
      showAdaptiveToast(context, message: result['error'] ?? 'Failed to remove image', type: ToastType.error);
    }
  }

  void _showImageOptions() {
    final user = ref.read(authStateProvider).user;
    final hasImage = user?.profileImage != null;

    showAdaptiveActionSheet(
      context: context,
      actions: [
        AdaptiveAction(
          label: context.l10n.photosChooseFromGallery,
          icon: Icons.photo_library,
          onPressed: _pickAndUploadImage,
        ),
        if (hasImage)
          AdaptiveAction(
            label: context.l10n.settingsRemovePhoto,
            icon: Icons.delete,
            isDestructive: true,
            onPressed: _removeImage,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final role = user?.role ?? 'TRAINEE';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
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
                        ? const Center(child: AdaptiveSpinner())
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
        title: context.l10n.settingsEditName,
        subtitle: context.l10n.settingsUpdateYourName,
        onTap: () => context.push('/edit-name'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: context.l10n.authEmailLabel,
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
        title: context.l10n.settingsAppearance,
        subtitle: context.l10n.settingsThemeColorsAndDisplay,
        onTap: () => context.push('/theme-settings'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.language,
        title: context.l10n.settingsLanguage,
        subtitle: context.l10n.settingsLanguageSelect,
        onTap: () => context.push('/language-settings'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // System
      _buildSectionHeader(context, 'SYSTEM', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: context.l10n.settingsNotifications,
        subtitle: context.l10n.settingsConfigureSystemNotifications,
        onTap: () => context.push('/admin/notifications'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.security,
        title: context.l10n.settingsSecurity,
        subtitle: context.l10n.settingsPassword2FAAndSessions,
        onTap: () => context.push('/admin/security'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Actions
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.logout,
        title: context.l10n.homeLogout,
        subtitle: context.l10n.settingsSignOutOfAdminAccount,
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
        title: context.l10n.settingsEditNameBusiness,
        subtitle: context.l10n.settingsUpdateYourNameAndBusinessName,
        onTap: () => context.push('/edit-name'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: context.l10n.authEmailLabel,
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
        title: context.l10n.settingsSubscription,
        subtitle: context.l10n.settingsManageYourSubscriptionPlan,
        onTap: () => context.push('/trainer/subscription'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.bar_chart,
        title: context.l10n.settingsAnalytics,
        subtitle: context.l10n.settingsViewTraineeProgressAnalytics,
        onTap: () => context.push('/trainer/retention'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Scheduling Section
      _buildSectionHeader(context, 'SCHEDULING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.calendar_month,
        title: context.l10n.settingsCalendar,
        subtitle: context.l10n.settingsConnectGoogleOrMicrosoftCalendar,
        onTap: () => context.push('/trainer/calendar'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Payments Section
      _buildSectionHeader(context, 'PAYMENTS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.account_balance,
        title: context.l10n.settingsPaymentSetup,
        subtitle: context.l10n.settingsConnectStripeToReceivePayments,
        onTap: () => context.push('/trainer/stripe-connect'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.attach_money,
        title: context.l10n.paymentsSetYourPrices,
        subtitle: context.l10n.settingsConfigureCoachingSubscriptionPricing,
        onTap: () => context.push('/trainer/pricing'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.local_offer,
        title: context.l10n.paymentsMyCoupons,
        subtitle: context.l10n.settingsCreateDiscountsForYourTrainees,
        onTap: () => context.push('/trainer/coupons'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.receipt_long,
        title: context.l10n.settingsPaymentHistory,
        subtitle: context.l10n.settingsViewReceivedPaymentsAndSubscribers,
        onTap: () => context.push('/trainer/payments'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Appearance
      _buildSectionHeader(context, 'APPEARANCE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.palette_outlined,
        title: context.l10n.settingsAppearance,
        subtitle: context.l10n.settingsThemeColorsAndDisplay,
        onTap: () => context.push('/theme-settings'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.language,
        title: context.l10n.settingsLanguage,
        subtitle: context.l10n.settingsLanguageSelect,
        onTap: () => context.push('/language-settings'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Branding
      _buildSectionHeader(context, 'BRANDING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.brush_outlined,
        title: context.l10n.settingsBranding,
        subtitle: context.l10n.settingsCustomizeYourAppColorsLogoAndName,
        onTap: () => context.push('/trainer/branding'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Notifications
      _buildSectionHeader(context, 'NOTIFICATIONS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: context.l10n.settingsPushNotifications,
        subtitle: context.l10n.settingsManageNotificationPreferences,
        onTap: () => context.push('/notification-preferences'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Feature Requests
      _buildSectionHeader(context, 'FEEDBACK', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.lightbulb_outline,
        title: context.l10n.settingsFeatureRequests,
        subtitle: context.l10n.settingsSuggestNewFeaturesOrVoteOnIdeas,
        onTap: () => context.push('/feature-requests'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.help_outline,
        title: context.l10n.settingsHelpSupport,
        subtitle: context.l10n.settingsGetHelpWithUsingThePlatform,
        onTap: () => context.push('/help-support'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.logout,
        title: context.l10n.homeLogout,
        subtitle: context.l10n.settingsSignOutOfYourAccount,
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
        title: context.l10n.settingsDeleteAccount,
        subtitle: context.l10n.settingsPermanentlyDeleteYourAccountAndAllData,
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
        title: context.l10n.settingsEditName,
        subtitle: context.l10n.settingsUpdateYourName,
        onTap: () => context.push('/edit-name'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.person_outline,
        title: context.l10n.settingsBodyMeasurements,
        subtitle: context.l10n.settingsUpdateAgeHeightAndWeight,
        onTap: () => context.push('/edit-profile'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.fitness_center,
        title: context.l10n.settingsFitnessGoals,
        subtitle: context.l10n.settingsChangeYourActivityLevelAndGoals,
        onTap: () => context.push('/edit-goals'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.restaurant_menu,
        title: context.l10n.onboardingDiet,
        subtitle: context.l10n.settingsUpdateDietTypeAndMealSettings,
        onTap: () => context.push('/edit-diet'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Tracking Settings
      _buildSectionHeader(context, 'TRACKING', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.monitor_weight_outlined,
        title: context.l10n.settingsCheckInDays,
        subtitle: context.l10n.settingsSetYourWeighInSchedule,
        onTap: () => context.push('/reminders'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.alarm,
        title: context.l10n.settingsReminders,
        subtitle: context.l10n.settingsConfigureWorkoutAndMealReminders,
        onTap: () => context.push('/reminders'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.notifications_outlined,
        title: context.l10n.settingsPushNotifications,
        subtitle: context.l10n.settingsManageNotificationPreferences,
        onTap: () => context.push('/notification-preferences'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.photo_library,
        title: context.l10n.photosProgressPhotos,
        subtitle: context.l10n.settingsTrackYourVisualTransformationOverTime,
        onTap: () => context.push('/progress-photos'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.watch,
        title: context.l10n.settingsAppleWatch,
        subtitle: context.l10n.settingsSyncWorkoutsAndHealthDataWithYourWatch,
        onTap: () => context.push('/watch'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Help & Support
      _buildSectionHeader(context, 'SUPPORT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.help_outline,
        title: context.l10n.settingsHelpSupport,
        subtitle: context.l10n.settingsGetHelpWithUsingThePlatform,
        onTap: () => context.push('/help-support'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Achievements
      _buildSectionHeader(context, 'ACHIEVEMENTS', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.emoji_events_outlined,
        title: context.l10n.settingsBadgesAchievements,
        subtitle: context.l10n.settingsViewYourEarnedBadges,
        onTap: () => context.push('/community/achievements'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Appearance
      _buildSectionHeader(context, 'APPEARANCE', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.palette_outlined,
        title: context.l10n.settingsAppearance,
        subtitle: context.l10n.settingsThemeColorsAndDisplay,
        onTap: () => context.push('/theme-settings'),
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.language,
        title: context.l10n.settingsLanguage,
        subtitle: context.l10n.settingsLanguageSelect,
        onTap: () => context.push('/language-settings'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Subscription Section
      _buildSectionHeader(context, 'SUBSCRIPTION', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.credit_card,
        title: context.l10n.settingsMySubscriptions,
        subtitle: context.l10n.settingsManageCoachingSubscriptions,
        onTap: () => context.push('/my-subscription'),
        index: index++,
      ),

      const SizedBox(height: 24),

      // Account Section
      _buildSectionHeader(context, 'ACCOUNT', index++),
      _buildSettingsTile(
        context: context,
        icon: Icons.email_outlined,
        title: context.l10n.authEmailLabel,
        subtitle: email ?? 'Not set',
        onTap: null,
        index: index++,
      ),
      _buildSettingsTile(
        context: context,
        icon: Icons.logout,
        title: context.l10n.homeLogout,
        subtitle: context.l10n.settingsSignOutOfYourAccount,
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
        title: context.l10n.settingsDeleteAccount,
        subtitle: context.l10n.settingsPermanentlyDeleteYourAccountAndAllData,
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
    int unsyncedCount = 0;
    try {
      unsyncedCount = await ref
          .read(unsyncedCountProvider.future)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Database not available or timeout — proceed with logout
    }

    if (!mounted) return;

    if (unsyncedCount > 0) {
      final confirmed = await showAdaptiveConfirmDialog(
        context: context,
        title: context.l10n.homeUnsyncedData,
        message: 'You have $unsyncedCount unsynced item${unsyncedCount == 1 ? '' : 's'} '
            'that will be lost if you log out. '
            'Are you sure you want to continue?',
        confirmText: context.l10n.homeLogoutAnyway,
        isDestructive: true,
      );

      if (confirmed != true || !mounted) return;

      // Clear local database for this user before logging out
      try {
        final db = ref.read(databaseProvider);
        final userId = ref.read(authStateProvider).user?.id;
        if (userId != null) {
          await db.clearUserData(userId);
        }
      } catch (_) {
        // Database not available — skip cleanup
      }
    }

    HapticService.heavyTap();
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  void _openDeleteAccountScreen(BuildContext context) {
    Navigator.of(context).push(
      adaptivePageRoute(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }
}

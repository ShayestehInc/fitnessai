import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Admin notification preferences screen
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  // Push notification settings
  bool _pushEnabled = true;
  bool _newTrainerSignup = true;
  bool _subscriptionChanges = true;
  bool _paymentAlerts = true;
  bool _pastDueAlerts = true;

  // Email notification settings
  bool _emailEnabled = true;
  bool _dailySummary = false;
  bool _weeklySummary = true;
  bool _paymentReceipts = true;
  bool _securityAlerts = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('admin_push_enabled') ?? true;
      _newTrainerSignup = prefs.getBool('admin_push_new_trainer') ?? true;
      _subscriptionChanges = prefs.getBool('admin_push_subscription') ?? true;
      _paymentAlerts = prefs.getBool('admin_push_payments') ?? true;
      _pastDueAlerts = prefs.getBool('admin_push_past_due') ?? true;

      _emailEnabled = prefs.getBool('admin_email_enabled') ?? true;
      _dailySummary = prefs.getBool('admin_email_daily') ?? false;
      _weeklySummary = prefs.getBool('admin_email_weekly') ?? true;
      _paymentReceipts = prefs.getBool('admin_email_receipts') ?? true;
      _securityAlerts = prefs.getBool('admin_email_security') ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.settingsNotifications)),
        body: const Center(child: AdaptiveSpinner()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsNotifications),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push Notifications Section
          _buildSectionHeader(theme, 'PUSH NOTIFICATIONS'),
          const SizedBox(height: 8),
          _buildMainToggle(
            theme: theme,
            title: context.l10n.settingsPushNotifications,
            subtitle: context.l10n.settingsReceivePushNotificationsOnThisDevice,
            value: _pushEnabled,
            onChanged: (value) {
              setState(() => _pushEnabled = value);
              _saveSetting('admin_push_enabled', value);
            },
          ),
          if (_pushEnabled) ...[
            const SizedBox(height: 8),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsNewTrainerSignups,
              subtitle: context.l10n.settingsWhenANewTrainerCreatesAnAccount,
              value: _newTrainerSignup,
              onChanged: (value) {
                setState(() => _newTrainerSignup = value);
                _saveSetting('admin_push_new_trainer', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsSubscriptionChanges,
              subtitle: context.l10n.settingsUpgradesDowngradesAndCancellations,
              value: _subscriptionChanges,
              onChanged: (value) {
                setState(() => _subscriptionChanges = value);
                _saveSetting('admin_push_subscription', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsPaymentAlerts,
              subtitle: context.l10n.settingsSuccessfulAndFailedPayments,
              value: _paymentAlerts,
              onChanged: (value) {
                setState(() => _paymentAlerts = value);
                _saveSetting('admin_push_payments', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsPastDueAlerts,
              subtitle: context.l10n.settingsWhenAccountsBecomePastDue,
              value: _pastDueAlerts,
              onChanged: (value) {
                setState(() => _pastDueAlerts = value);
                _saveSetting('admin_push_past_due', value);
              },
            ),
          ],

          const SizedBox(height: 32),

          // Email Notifications Section
          _buildSectionHeader(theme, 'EMAIL NOTIFICATIONS'),
          const SizedBox(height: 8),
          _buildMainToggle(
            theme: theme,
            title: context.l10n.settingsEmailNotifications,
            subtitle: context.l10n.settingsReceiveNotificationsViaEmail,
            value: _emailEnabled,
            onChanged: (value) {
              setState(() => _emailEnabled = value);
              _saveSetting('admin_email_enabled', value);
            },
          ),
          if (_emailEnabled) ...[
            const SizedBox(height: 8),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsDailySummary,
              subtitle: context.l10n.settingsDailyOverviewOfPlatformActivity,
              value: _dailySummary,
              onChanged: (value) {
                setState(() => _dailySummary = value);
                _saveSetting('admin_email_daily', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsWeeklySummary,
              subtitle: context.l10n.settingsWeeklyReportWithKeyMetrics,
              value: _weeklySummary,
              onChanged: (value) {
                setState(() => _weeklySummary = value);
                _saveSetting('admin_email_weekly', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsPaymentReceipts,
              subtitle: context.l10n.settingsConfirmationEmailsForPayments,
              value: _paymentReceipts,
              onChanged: (value) {
                setState(() => _paymentReceipts = value);
                _saveSetting('admin_email_receipts', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: context.l10n.settingsSecurityAlerts,
              subtitle: context.l10n.settingsLoginAttemptsAndSecurityEvents,
              value: _securityAlerts,
              onChanged: (value) {
                setState(() => _securityAlerts = value);
                _saveSetting('admin_email_security', value);
              },
            ),
          ],

          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notification settings are stored locally on this device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildMainToggle({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSubToggle({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile.adaptive(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        dense: true,
      ),
    );
  }
}

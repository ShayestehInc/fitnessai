import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push Notifications Section
          _buildSectionHeader(theme, 'PUSH NOTIFICATIONS'),
          const SizedBox(height: 8),
          _buildMainToggle(
            theme: theme,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications on this device',
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
              title: 'New Trainer Signups',
              subtitle: 'When a new trainer creates an account',
              value: _newTrainerSignup,
              onChanged: (value) {
                setState(() => _newTrainerSignup = value);
                _saveSetting('admin_push_new_trainer', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Subscription Changes',
              subtitle: 'Upgrades, downgrades, and cancellations',
              value: _subscriptionChanges,
              onChanged: (value) {
                setState(() => _subscriptionChanges = value);
                _saveSetting('admin_push_subscription', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Payment Alerts',
              subtitle: 'Successful and failed payments',
              value: _paymentAlerts,
              onChanged: (value) {
                setState(() => _paymentAlerts = value);
                _saveSetting('admin_push_payments', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Past Due Alerts',
              subtitle: 'When accounts become past due',
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
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
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
              title: 'Daily Summary',
              subtitle: 'Daily overview of platform activity',
              value: _dailySummary,
              onChanged: (value) {
                setState(() => _dailySummary = value);
                _saveSetting('admin_email_daily', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Weekly Summary',
              subtitle: 'Weekly report with key metrics',
              value: _weeklySummary,
              onChanged: (value) {
                setState(() => _weeklySummary = value);
                _saveSetting('admin_email_weekly', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Payment Receipts',
              subtitle: 'Confirmation emails for payments',
              value: _paymentReceipts,
              onChanged: (value) {
                setState(() => _paymentReceipts = value);
                _saveSetting('admin_email_receipts', value);
              },
            ),
            _buildSubToggle(
              theme: theme,
              title: 'Security Alerts',
              subtitle: 'Login attempts and security events',
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
      child: SwitchListTile(
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
      child: SwitchListTile(
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

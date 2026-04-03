import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_progress_bar.dart';
import '../../../../shared/widgets/adaptive/adaptive_route.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Admin security settings screen
class AdminSecurityScreen extends ConsumerStatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  ConsumerState<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends ConsumerState<AdminSecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsSecurity),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Password Section
          _buildSectionHeader(theme, 'PASSWORD'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            theme: theme,
            icon: Icons.lock_outline,
            title: context.l10n.settingsChangePassword,
            subtitle: context.l10n.settingsUpdateYourAccountPassword,
            onTap: () => _navigateToChangePassword(context),
          ),

          const SizedBox(height: 24),

          // Two-Factor Authentication — Coming Soon
          _buildSectionHeader(theme, 'TWO-FACTOR AUTHENTICATION'),
          const SizedBox(height: 8),
          _buildComingSoonCard(
            theme: theme,
            icon: Icons.shield_outlined,
            iconColor: Colors.orange,
            title: 'Two-Factor Authentication',
            description: 'Add an extra layer of security to your account. '
                'Support for authenticator apps and SMS verification is coming soon.',
          ),

          const SizedBox(height: 24),

          // Session Management — Coming Soon
          _buildSectionHeader(theme, 'SESSIONS'),
          const SizedBox(height: 8),
          _buildComingSoonCard(
            theme: theme,
            icon: Icons.devices,
            iconColor: theme.colorScheme.primary,
            title: 'Session Management',
            description: 'View and manage active sessions across your devices. '
                'This feature is coming soon.',
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

  Widget _buildSettingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? theme.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.of(context).push(
      adaptivePageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

}

/// Screen to change password
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword() {
    if (_confirmPasswordController.text.isEmpty) return null;
    if (_confirmPasswordController.text != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _canSubmit() {
    return _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.length >= 8 &&
        _newPasswordController.text == _confirmPasswordController.text;
  }

  Future<void> _changePassword() async {
    if (!_canSubmit()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showAdaptiveToast(context, message: context.l10n.settingsPasswordChangedSuccessfully, type: ToastType.success);
      Navigator.of(context).pop();
    } else {
      final errorMsg = result['error'] as String? ?? 'Failed to change password';
      setState(() {
        _errorMessage = errorMsg;
      });

      // Also show toast for better visibility
      showAdaptiveToast(context, message: errorMsg, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsChangePassword),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a new password',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new password must be at least 8 characters long.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Current Password
            _buildPasswordField(
              controller: _currentPasswordController,
              label: context.l10n.settingsCurrentPassword,
              hint: 'Enter your current password',
              obscure: _obscureCurrent,
              onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
              errorText: _errorMessage,
              autofillHint: 'password',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // New Password
            _buildPasswordField(
              controller: _newPasswordController,
              label: context.l10n.settingsNewPassword,
              hint: 'At least 8 characters',
              obscure: _obscureNew,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              errorText: _validateNewPassword(),
              autofillHint: 'newPassword',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // Confirm Password
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: context.l10n.settingsConfirmNewPassword,
              hint: 'Re-enter your new password',
              obscure: _obscureConfirm,
              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              errorText: _validateConfirmPassword(),
              autofillHint: 'newPassword',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // Password strength indicator
            if (_newPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() && !_isLoading ? _changePassword : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const AdaptiveSpinner.small()
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final theme = Theme.of(context);
    final password = _newPasswordController.text;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    String strengthText;
    Color strengthColor;
    double strengthValue;

    if (strength <= 1) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
      strengthValue = 0.25;
    } else if (strength == 2) {
      strengthText = 'Fair';
      strengthColor = Colors.orange;
      strengthValue = 0.5;
    } else if (strength == 3) {
      strengthText = 'Good';
      strengthColor = Colors.yellow[700]!;
      strengthValue = 0.75;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
      strengthValue = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AdaptiveProgressBar(
                  value: strengthValue,
                  backgroundColor: theme.dividerColor,
                  color: strengthColor,
                  minHeight: 6,
                ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use uppercase, numbers, and special characters for a stronger password',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? errorText,
    String? autofillHint,
    TextInputAction? textInputAction,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) => setState(() {}),
          autofillHints: autofillHint != null ? <String>[autofillHint] : null,
          textInputAction: textInputAction ?? TextInputAction.next,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: theme.brightness == Brightness.light
                ? const Color(0xFFF5F5F8)
                : theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
              tooltip: obscure ? 'Show password' : 'Hide password',
            ),
            errorText: errorText,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

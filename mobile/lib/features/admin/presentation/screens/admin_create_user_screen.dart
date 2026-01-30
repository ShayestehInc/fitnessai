import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/step_form_page.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen for admins to create new Admin or Trainer accounts.
class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String _selectedRole = 'TRAINER';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String? _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword() {
    if (_confirmPasswordController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _canProceed() {
    return _validateEmail() == null &&
        _validatePassword() == null &&
        _validateConfirmPassword() == null;
  }

  Future<void> _createUser() async {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before continuing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final apiClient = ref.read(apiClientProvider);
    final adminRepo = AdminRepository(apiClient);

    final result = await adminRepo.createUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedRole == 'ADMIN' ? 'Admin' : 'Trainer'} account created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to create user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StepFormPage(
      title: 'Create User',
      completeButtonText: _isLoading ? 'Creating...' : 'Create Account',
      onComplete: _isLoading ? null : _createUser,
      steps: [
        // Step 1: Role Selection
        FormStep(
          title: 'Select Role',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What type of account do you want to create?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the role for the new user.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildRoleOption(
                theme: theme,
                role: 'TRAINER',
                title: 'Trainer',
                description: 'Can manage trainees, create programs, and view analytics',
                icon: Icons.fitness_center,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildRoleOption(
                theme: theme,
                role: 'ADMIN',
                title: 'Admin',
                description: 'Full platform access including trainer management and billing',
                icon: Icons.admin_panel_settings,
                color: Colors.purple,
              ),
            ],
          ),
        ),
        // Step 2: Basic Info
        FormStep(
          title: 'User Details',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the user\'s information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'They will use this email to sign in.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'John',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Doe',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'john@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
            ],
          ),
        ),
        // Step 3: Password
        FormStep(
          title: 'Set Password',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a secure password',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
              _buildSummaryCard(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required ThemeData theme,
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function()? validator,
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
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          onChanged: (_) => setState(() {}),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
            errorText: validator?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final roleColor = _selectedRole == 'ADMIN' ? Colors.purple : Colors.blue;
    final roleIcon = _selectedRole == 'ADMIN' ? Icons.admin_panel_settings : Icons.fitness_center;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            theme,
            'Role',
            _selectedRole == 'ADMIN' ? 'Admin' : 'Trainer',
            roleIcon,
            roleColor,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'Name',
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim().isEmpty
                ? 'Not provided'
                : '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
            Icons.person,
            theme.textTheme.bodyMedium?.color ?? Colors.grey,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'Email',
            _emailController.text.trim().isEmpty ? 'Not provided' : _emailController.text.trim(),
            Icons.email,
            theme.textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

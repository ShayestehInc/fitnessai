import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_dropdown.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/auth_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  String _selectedRole = 'TRAINEE';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    HapticService.mediumTap();
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      showAdaptiveToast(context, message: context.l10n.authPasswordsDoNotMatch);
      return;
    }

    await ref.read(authStateProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          referralCode: _referralCodeController.text.trim().isEmpty
              ? null
              : _referralCodeController.text.trim(),
        );

    final authState = ref.read(authStateProvider);
    
    if (authState.user != null) {
      if (mounted) {
        context.go('/dashboard');
      }
    } else if (authState.error != null && mounted) {
      showAdaptiveToast(context, message: authState.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.authRegister),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: context.l10n.authEmailLabel,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AdaptiveDropdown<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: context.l10n.authRole,
                ),
                items: [
                  AdaptiveDropdownItem(value: 'TRAINEE', label: context.l10n.authTrainee),
                  AdaptiveDropdownItem(value: 'TRAINER', label: context.l10n.adminTrainer),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              if (_selectedRole == 'TRAINER') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralCodeController,
                  decoration: InputDecoration(
                    labelText: context.l10n.authReferralCodeOptional,
                    helperText: context.l10n.authHaveAReferralCodeEnterItHere,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: context.l10n.authPasswordLabel,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: context.l10n.authConfirmPasswordLabel,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleRegister,
                child: authState.isLoading
                    ? const AdaptiveSpinner.small()
                    : Text(context.l10n.authRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

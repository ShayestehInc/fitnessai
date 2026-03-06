import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

class AdminCreateAmbassadorScreen extends ConsumerStatefulWidget {
  const AdminCreateAmbassadorScreen({super.key});

  @override
  ConsumerState<AdminCreateAmbassadorScreen> createState() =>
      _AdminCreateAmbassadorScreenState();
}

class _AdminCreateAmbassadorScreenState
    extends ConsumerState<AdminCreateAmbassadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  double _commissionRate = 0.20;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(adminAmbassadorsProvider.notifier).createAmbassador(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          password: _passwordController.text,
          commissionRate: _commissionRate,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result != null) {
      showAdaptiveToast(
        context,
        message: 'Ambassador created! Referral code: ${result.referralCode}',
        type: ToastType.success,
        duration: const Duration(seconds: 4),
      );
      context.pop();
    } else {
      final error = ref.read(adminAmbassadorsProvider).error;
      showAdaptiveToast(
        context,
        message: error ?? 'Failed to create ambassador. Please try again.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.adminCreateAmbassador),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: AbsorbPointer(
            absorbing: _isSubmitting,
            child: AnimatedOpacity(
              opacity: _isSubmitting ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: context.l10n.authEmailLabel,
                      hintText: context.l10n.adminAmbassadorexampleCom,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.authFirstNameLabel,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'First name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.authLastNameLabel,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Last name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: context.l10n.adminTemporaryPassword,
                      helperText: context.l10n.adminShareThisWithTheAmbassadorSoTheyCanLogIn,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Commission rate: ${(_commissionRate * 100).toStringAsFixed(0)} percent',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commission Rate: ${(_commissionRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider.adaptive(
                          value: _commissionRate,
                          min: 0.05,
                          max: 0.50,
                          divisions: 9,
                          label: '${(_commissionRate * 100).toStringAsFixed(0)}%',
                          onChanged: (value) => setState(() => _commissionRate = value),
                        ),
                        Text(
                          'Ambassador earns ${(_commissionRate * 100).toStringAsFixed(0)}% of each referred trainer\'s subscription revenue.',
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const AdaptiveSpinner.small()
                          : Text(context.l10n.adminCreateAmbassador),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

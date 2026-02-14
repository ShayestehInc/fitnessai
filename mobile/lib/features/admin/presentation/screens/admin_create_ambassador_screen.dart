import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';

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
  double _commissionRate = 0.20;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(adminAmbassadorsProvider.notifier).createAmbassador(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          commissionRate: _commissionRate,
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ambassador created! Code: ${result.referralCode}'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(adminAmbassadorsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create ambassador'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Ambassador'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'First name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Last name is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Commission Rate: ${(_commissionRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _commissionRate,
                min: 0.05,
                max: 0.50,
                divisions: 9,
                label: '${(_commissionRate * 100).toStringAsFixed(0)}%',
                onChanged: (value) => setState(() => _commissionRate = value),
              ),
              Text(
                'Ambassador earns ${(_commissionRate * 100).toStringAsFixed(0)}% of each referred trainer\'s subscription',
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Ambassador'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

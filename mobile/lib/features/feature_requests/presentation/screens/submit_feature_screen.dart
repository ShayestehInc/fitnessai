import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/feature_request_model.dart';
import '../providers/feature_request_provider.dart';

class SubmitFeatureScreen extends ConsumerStatefulWidget {
  const SubmitFeatureScreen({super.key});

  @override
  ConsumerState<SubmitFeatureScreen> createState() => _SubmitFeatureScreenState();
}

class _SubmitFeatureScreenState extends ConsumerState<SubmitFeatureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeatureCategory _selectedCategory = FeatureCategory.other;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Feature'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Have an idea to make the app better?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your feature request below and let others vote on it!',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Feature Title',
                hintText: 'Brief description of your idea',
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 10) {
                  return 'Title must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<FeatureCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: FeatureCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.display),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Explain your idea in detail. What problem does it solve? How would it work?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              maxLength: 2000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 30) {
                  return 'Description must be at least 30 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tips section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for a great request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Be specific about what you want\n'
                    '• Explain the problem it solves\n'
                    '• Describe how it would work\n'
                    '• Check if similar requests exist first',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Feature Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(featureRequestRepositoryProvider).createFeatureRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory.value,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to submit feature request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

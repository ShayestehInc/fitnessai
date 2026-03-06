import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/space_provider.dart';

/// Screen for creating (or editing) a space — trainer only.
class SpaceCreateScreen extends ConsumerStatefulWidget {
  const SpaceCreateScreen({super.key});

  @override
  ConsumerState<SpaceCreateScreen> createState() => _SpaceCreateScreenState();
}

class _SpaceCreateScreenState extends ConsumerState<SpaceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _emoji = '💬';
  String _visibility = 'public';
  bool _isDefault = false;
  bool _isSubmitting = false;

  static const List<String> _emojiOptions = [
    '💬', '🏋️', '🥗', '🏃', '💪', '🎯', '📚', '🔥', '⭐', '🌟',
    '🎉', '💡', '🧘', '🏊', '🚴', '🏆', '❤️', '🤝', '📣', '🎵',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Space'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emoji picker
            _buildEmojiSection(theme),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Space Name',
                hintText: 'e.g. Workout Tips',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this space about?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visibility
            _buildVisibilitySection(theme),
            const SizedBox(height: 16),

            // Default toggle
            SwitchListTile(
              title: const Text('Auto-join new members'),
              subtitle: const Text(
                'New trainees will automatically join this space',
              ),
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? AdaptiveSpinner.small()
                    : const Text('Create Space'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojiOptions.map((emoji) {
            final isSelected = _emoji == emoji;
            return GestureDetector(
              onTap: () => setState(() => _emoji = emoji),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VisibilityOption(
                label: 'Public',
                icon: Icons.public,
                description: 'Visible to all members',
                isSelected: _visibility == 'public',
                onTap: () => setState(() => _visibility = 'public'),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VisibilityOption(
                label: 'Private',
                icon: Icons.lock_outline,
                description: 'Invite only',
                isSelected: _visibility == 'private',
                onTap: () => setState(() => _visibility = 'private'),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(spacesProvider.notifier).createSpace(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          emoji: _emoji,
          visibility: _visibility,
          isDefault: _isDefault,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      showAdaptiveToast(context,
          message: 'Space created!', type: ToastType.success);
    } else {
      showAdaptiveToast(context,
          message: 'Failed to create space', type: ToastType.error);
    }
  }
}

/// Selectable visibility option card.
class _VisibilityOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _VisibilityOption({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

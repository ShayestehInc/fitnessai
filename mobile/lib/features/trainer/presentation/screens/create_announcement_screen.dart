import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../community/data/models/announcement_model.dart';
import '../../../community/presentation/providers/announcement_provider.dart';

/// Screen for creating or editing a trainer announcement.
class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  final AnnouncementModel? existing;

  const CreateAnnouncementScreen({super.key, this.existing});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _isPinned = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
    _isPinned = widget.existing?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Announcement' : 'New Announcement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Announcement title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLength: 2000,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Body',
                hintText: 'Write your announcement...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pin Announcement'),
              subtitle: const Text('Pinned announcements appear at the top'),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Update' : 'Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final notifier = ref.read(trainerAnnouncementProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateAnnouncement(
        id: widget.existing!.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        isPinned: _isPinned,
      );
    } else {
      success = await notifier.createAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        isPinned: _isPinned,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Failed to update announcement'
                : 'Failed to create announcement',
          ),
        ),
      );
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/progress_photo_provider.dart';
import '../widgets/measurement_form.dart';

/// Screen for adding a new progress photo with category, date, optional
/// body measurements, and notes.
class AddPhotoScreen extends ConsumerStatefulWidget {
  const AddPhotoScreen({super.key});

  @override
  ConsumerState<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends ConsumerState<AddPhotoScreen> {
  final _notesController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armsController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighsController = TextEditingController();

  final _imagePicker = ImagePicker();

  String _selectedCategory = 'front';
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isUploading = false;

  static const List<_CategoryOption> _categoryOptions = [
    _CategoryOption(label: 'Front', value: 'front', icon: Icons.person),
    _CategoryOption(
        label: 'Side', value: 'side', icon: Icons.person_outline),
    _CategoryOption(label: 'Back', value: 'back', icon: Icons.person_3),
    _CategoryOption(
        label: 'Side', value: 'side', icon: Icons.person_outline),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armsController.dispose();
    _hipsController.dispose();
    _thighsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Progress Photo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker area
            _buildImagePicker(theme),
            const SizedBox(height: 24),

            // Category selector
            Text(
              'Category',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(theme),
            const SizedBox(height: 24),

            // Date picker
            Text(
              'Date',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildDatePicker(theme),
            const SizedBox(height: 24),

            // Measurements
            MeasurementForm(
              waistController: _waistController,
              chestController: _chestController,
              armsController: _armsController,
              hipsController: _hipsController,
              thighsController: _thighsController,
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Notes (optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any observations about your progress...',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isUploading || _selectedImage == null ? null : _submit,
                child: _isUploading
                    ? const AdaptiveSpinner.small()
                    : const Text('Save Photo'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
            width: _selectedImage == null ? 2 : 0,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _selectedImage = null);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to add a photo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera or Gallery',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Row(
      children: _categoryOptions.map((option) {
        final isSelected = option.value == _selectedCategory;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option.value != 'other' ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = option.value);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      option.icon,
                      size: 24,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: theme.textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: 'Failed to pick image: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    // Collect measurements from the form.
    final measurements = <String, double>{};
    void tryAdd(String key, TextEditingController ctrl) {
      final value = double.tryParse(ctrl.text.trim());
      if (value != null && value > 0) {
        measurements[key] = value;
      }
    }

    tryAdd('waist', _waistController);
    tryAdd('chest', _chestController);
    tryAdd('arms', _armsController);
    tryAdd('hips', _hipsController);
    tryAdd('thighs', _thighsController);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await ref.read(uploadPhotoProvider.notifier).upload(
          filePath: _selectedImage!.path,
          category: _selectedCategory,
          date: dateStr,
          measurements: measurements,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      showAdaptiveToast(
        context,
        message: 'Progress photo saved!',
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isUploading = false);
      showAdaptiveToast(
        context,
        message: 'Failed to upload photo. Please try again.',
        type: ToastType.error,
      );
    }
  }
}

class _CategoryOption {
  final String label;
  final String value;
  final IconData icon;

  const _CategoryOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

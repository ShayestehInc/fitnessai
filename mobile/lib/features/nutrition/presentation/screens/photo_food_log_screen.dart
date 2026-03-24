import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_toast.dart';

/// Photo-based food logging screen (Nutrition Spec §12).
/// Captures a photo → sends to AI for food recognition → shows editable results.
class PhotoFoodLogScreen extends ConsumerStatefulWidget {
  const PhotoFoodLogScreen({super.key});

  @override
  ConsumerState<PhotoFoodLogScreen> createState() => _PhotoFoodLogScreenState();
}

class _PhotoFoodLogScreenState extends ConsumerState<PhotoFoodLogScreen> {
  bool _hasPhoto = false;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _recognizedFoods = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Photo Food Log'),
      ),
      body: _hasPhoto
          ? _buildAnalysisView(theme)
          : _buildCaptureView(theme),
    );
  }

  Widget _buildCaptureView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_rounded, size: 64, color: theme.dividerColor),
          const SizedBox(height: 24),
          Text('Take a photo of your meal',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('AI will identify the foods and estimate portions',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView(ThemeData theme) {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Analyzing your meal...', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Identifying foods and estimating portions',
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    if (_recognizedFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food_rounded, size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text('No foods recognized', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _hasPhoto = false),
              child: const Text('Try Another Photo'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recognized Foods', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tap to edit portions. Long press to remove.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        ..._recognizedFoods.asMap().entries.map((entry) =>
            _FoodResultCard(
              food: entry.value,
              onRemove: () {
                setState(() => _recognizedFoods.removeAt(entry.key));
              },
            )),
        const SizedBox(height: 16),
        _buildTotalCard(theme),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _hasPhoto = false),
                child: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveToLog,
                icon: const Icon(Icons.check),
                label: const Text('Save to Log'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    int totalCal = 0, totalP = 0, totalC = 0, totalF = 0;
    for (final f in _recognizedFoods) {
      totalCal += (f['calories'] as int?) ?? 0;
      totalP += (f['protein_g'] as int?) ?? 0;
      totalC += (f['carbs_g'] as int?) ?? 0;
      totalF += (f['fat_g'] as int?) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroChip(label: '${totalCal}cal', theme: theme),
          _MacroChip(label: '${totalP}g P', theme: theme),
          _MacroChip(label: '${totalC}g C', theme: theme),
          _MacroChip(label: '${totalF}g F', theme: theme),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    // TODO: Use image_picker to capture photo, then send to backend
    // POST /api/workouts/food-recognition/ with image
    // Backend calls get_photo_food_recognition_prompt() + GPT-4o Vision
    setState(() {
      _hasPhoto = true;
      _isAnalyzing = true;
    });

    // Simulate AI response for now
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _recognizedFoods = [
        {
          'name': 'Grilled Chicken Breast',
          'quantity_g': 150,
          'confidence': 0.9,
          'protein_g': 46,
          'carbs_g': 0,
          'fat_g': 5,
          'calories': 231,
        },
        {
          'name': 'Brown Rice',
          'quantity_g': 200,
          'confidence': 0.85,
          'protein_g': 5,
          'carbs_g': 46,
          'fat_g': 2,
          'calories': 218,
        },
        {
          'name': 'Steamed Broccoli',
          'quantity_g': 100,
          'confidence': 0.95,
          'protein_g': 3,
          'carbs_g': 7,
          'fat_g': 0,
          'calories': 35,
        },
      ];
    });
  }

  Future<void> _pickFromGallery() async {
    await _capturePhoto(); // Same flow for now
  }

  void _saveToLog() {
    // TODO: POST recognized foods as MealLogEntries
    showAdaptiveToast(context,
        message: '${_recognizedFoods.length} foods logged!',
        type: ToastType.success);
    Navigator.of(context).pop();
  }
}

class _FoodResultCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onRemove;

  const _FoodResultCard({required this.food, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = (food['confidence'] as double?) ?? 0.0;
    final confColor = confidence >= 0.8
        ? const Color(0xFF22C55E)
        : confidence >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(food['name'] as String? ?? 'Unknown'),
        subtitle: Text(
          '${food['quantity_g']}g — '
          '${food['protein_g']}P / ${food['carbs_g']}C / ${food['fat_g']}F — '
          '${food['calories']}cal',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: confColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: confColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _MacroChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

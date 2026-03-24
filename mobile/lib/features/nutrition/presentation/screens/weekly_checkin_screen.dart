import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';

/// Weekly nutrition check-in screen (Nutrition Spec §13).
/// Captures weight, adherence signals, and subjective ratings.
class WeeklyCheckinScreen extends ConsumerStatefulWidget {
  const WeeklyCheckinScreen({super.key});

  @override
  ConsumerState<WeeklyCheckinScreen> createState() =>
      _WeeklyCheckinScreenState();
}

class _WeeklyCheckinScreenState extends ConsumerState<WeeklyCheckinScreen> {
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();

  int _hunger = 3;
  int _sleep = 3;
  int _stress = 3;
  int _fatigue = 3;
  int _digestion = 3;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Weekly Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your week?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Quick check-in to help adjust your nutrition plan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Weight
            Text('Average weight this week (kg)',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 82.5',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Waist (optional)
            Text('Waist measurement (cm, optional)',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _waistController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 85',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Signal sliders
            Text('How did you feel this week?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _SignalSlider(
              label: 'Hunger',
              value: _hunger,
              lowLabel: 'Not hungry',
              highLabel: 'Very hungry',
              onChanged: (v) => setState(() => _hunger = v),
            ),
            _SignalSlider(
              label: 'Sleep Quality',
              value: _sleep,
              lowLabel: 'Poor',
              highLabel: 'Excellent',
              onChanged: (v) => setState(() => _sleep = v),
            ),
            _SignalSlider(
              label: 'Stress',
              value: _stress,
              lowLabel: 'Low',
              highLabel: 'Very high',
              onChanged: (v) => setState(() => _stress = v),
            ),
            _SignalSlider(
              label: 'Fatigue',
              value: _fatigue,
              lowLabel: 'Fresh',
              highLabel: 'Exhausted',
              onChanged: (v) => setState(() => _fatigue = v),
            ),
            _SignalSlider(
              label: 'Digestion',
              value: _digestion,
              lowLabel: 'Uncomfortable',
              highLabel: 'Great',
              onChanged: (v) => setState(() => _digestion = v),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const AdaptiveSpinner.small()
                    : const Text('Submit Check-In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      showAdaptiveToast(context,
          message: 'Please enter a valid weight.', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Call backend API to submit WeeklyNutritionCheckIn
    // For now, show success
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    showAdaptiveToast(context,
        message: 'Check-in submitted!', type: ToastType.success);
    Navigator.of(context).pop();
  }
}

class _SignalSlider extends StatelessWidget {
  final String label;
  final int value;
  final String lowLabel;
  final String highLabel;
  final ValueChanged<int> onChanged;

  const _SignalSlider({
    required this.label,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('$value/5', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final isSelected = (i + 1) == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i + 1),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.15)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: theme.textTheme.labelSmall),
              Text(highLabel, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

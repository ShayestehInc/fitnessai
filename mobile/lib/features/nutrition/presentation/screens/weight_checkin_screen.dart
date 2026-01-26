import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/nutrition_provider.dart';

class WeightCheckInScreen extends ConsumerStatefulWidget {
  const WeightCheckInScreen({super.key});

  @override
  ConsumerState<WeightCheckInScreen> createState() =>
      _WeightCheckInScreenState();
}

class _WeightCheckInScreenState extends ConsumerState<WeightCheckInScreen> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _useMetric = true;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Weight Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regular weigh-ins help track your progress. '
                      'Try to weigh yourself at the same time each day.',
                      style: TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Weight input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _UnitToggle(
                  leftLabel: 'lbs',
                  rightLabel: 'kg',
                  isRight: _useMetric,
                  onToggle: () {
                    setState(() {
                      _useMetric = !_useMetric;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: _useMetric ? '75.0' : '165.0',
                hintStyle: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                suffixText: _useMetric ? 'kg' : 'lbs',
                filled: true,
                fillColor: AppTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Notes (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'How are you feeling today?',
                filled: true,
                fillColor: AppTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Previous check-in
            if (state.latestCheckIn != null) ...[
              Text(
                'Previous Check-In',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.latestCheckIn!.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: AppTheme.foreground,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.latestCheckIn!.date,
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.history, color: AppTheme.mutedForeground),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 48),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading || _weightController.text.isEmpty
                    ? null
                    : _saveCheckIn,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Check-In'),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(color: AppTheme.destructive),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveCheckIn() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    // Convert to kg if using lbs
    final weightKg = _useMetric ? weight : weight * 0.453592;

    final success = await ref
        .read(nutritionStateProvider.notifier)
        .createWeightCheckIn(
          weightKg: weightKg,
          notes: _notesController.text,
        );

    if (success && mounted) {
      context.pop();
    }
  }
}

class _UnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRight;
  final VoidCallback onToggle;

  const _UnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRight,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.zinc800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(leftLabel, !isRight),
            _buildOption(rightLabel, isRight),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

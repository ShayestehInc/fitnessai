import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/sync_provider.dart';
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
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regular weigh-ins help track your progress. '
                      'Try to weigh yourself at the same time each day.',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
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
                  theme: theme,
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
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                suffixText: _useMetric ? 'kg' : 'lbs',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
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
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.latestCheckIn!.weightKg.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.latestCheckIn!.date,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.history, color: theme.textTheme.bodySmall?.color),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 48),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving || _weightController.text.isEmpty
                    ? null
                    : _saveCheckIn,
                child: _isSaving
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
                style: TextStyle(color: theme.colorScheme.error),
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

    setState(() => _isSaving = true);

    // Convert to kg if using lbs
    final weightKg = _useMetric ? weight : weight * 0.453592;

    final offlineWeightRepo = ref.read(offlineWeightRepositoryProvider);
    if (offlineWeightRepo == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save weight data.')),
        );
      }
      return;
    }

    final dateParam = ref.read(nutritionStateProvider).dateParam;

    final result = await offlineWeightRepo.createWeightCheckIn(
      date: dateParam,
      weightKg: weightKg,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (result.success) {
      if (result.offline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weight saved locally. It will sync when you\'re back online.',
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight check-in saved successfully!')),
        );
      }
      // Trigger sync if online
      ref.read(syncServiceProvider)?.triggerSync();
      context.pop();
    } else {
      if (mounted) setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to save')),
      );
    }
  }
}

class _UnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRight;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _UnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRight,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

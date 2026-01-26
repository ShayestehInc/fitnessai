import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class Step1AboutYouScreen extends ConsumerStatefulWidget {
  const Step1AboutYouScreen({super.key});

  @override
  ConsumerState<Step1AboutYouScreen> createState() => _Step1AboutYouScreenState();
}

class _Step1AboutYouScreenState extends ConsumerState<Step1AboutYouScreen> {
  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _heightCmController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);
    final notifier = ref.read(onboardingStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About You',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us a bit about yourself so we can calculate your personalized nutrition goals.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
          ),
          const SizedBox(height: 32),

          // First Name input
          Text(
            'First Name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter your first name',
            ),
            onChanged: (value) {
              notifier.setFirstName(value.trim());
            },
          ),
          const SizedBox(height: 24),

          // Sex selector
          Text(
            'Sex',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectionCard(
                  title: 'Male',
                  icon: Icons.male,
                  isSelected: state.sex == 'male',
                  onTap: () => notifier.setSex('male'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SelectionCard(
                  title: 'Female',
                  icon: Icons.female,
                  isSelected: state.sex == 'female',
                  onTap: () => notifier.setSex('female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Age input
          Text(
            'Age',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Enter your age',
              suffixText: 'years',
            ),
            onChanged: (value) {
              final age = int.tryParse(value);
              if (age != null) {
                notifier.setAge(age);
              }
            },
          ),
          const SizedBox(height: 24),

          // Height input with unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Height',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _UnitToggle(
                leftLabel: 'ft/in',
                rightLabel: 'cm',
                isRight: state.useMetric,
                onToggle: () => notifier.toggleUnitSystem(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.useMetric)
            TextField(
              controller: _heightCmController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                hintText: 'Enter height',
                suffixText: 'cm',
              ),
              onChanged: (value) {
                final height = double.tryParse(value);
                if (height != null) {
                  notifier.setHeight(height);
                }
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightFeetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Feet',
                      suffixText: 'ft',
                    ),
                    onChanged: (_) => _updateHeightFromImperial(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightInchesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Inches',
                      suffixText: 'in',
                    ),
                    onChanged: (_) => _updateHeightFromImperial(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Weight input with unit toggle
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
                isRight: state.useMetric,
                onToggle: () => notifier.toggleUnitSystem(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter weight',
              suffixText: state.useMetric ? 'kg' : 'lbs',
            ),
            onChanged: (value) {
              final weight = double.tryParse(value);
              if (weight != null) {
                final weightKg = state.useMetric ? weight : weight * 0.453592;
                notifier.setWeight(weightKg);
              }
            },
          ),
          const SizedBox(height: 48),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.canProceedStep1 && !state.isLoading
                  ? () => notifier.saveStep1()
                  : null,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: AppTheme.destructive),
            ),
          ],
        ],
      ),
    );
  }

  void _updateHeightFromImperial() {
    final feet = int.tryParse(_heightFeetController.text) ?? 0;
    final inches = int.tryParse(_heightInchesController.text) ?? 0;
    final totalInches = (feet * 12) + inches;
    final cm = totalInches * 2.54;
    if (cm > 0) {
      ref.read(onboardingStateProvider.notifier).setHeight(cm);
    }
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppTheme.primary : AppTheme.mutedForeground,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.foreground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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

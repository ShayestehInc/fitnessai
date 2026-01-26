import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import '../providers/onboarding_provider.dart';

class Step4DietSetupScreen extends ConsumerWidget {
  const Step4DietSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingStateProvider);
    final notifier = ref.read(onboardingStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => notifier.goBack(),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: AppTheme.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(color: AppTheme.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Diet Setup',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your nutrition preferences.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
          ),
          const SizedBox(height: 32),

          // Check-in days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in Days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GestureDetector(
                onTap: () {
                  if (notifier.allDaysSelected) {
                    notifier.clearAllDays();
                  } else {
                    notifier.selectAllDays();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: notifier.allDaysSelected
                        ? AppTheme.primary
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notifier.allDaysSelected
                          ? AppTheme.primary
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    'Everyday',
                    style: TextStyle(
                      color: notifier.allDaysSelected
                          ? Colors.white
                          : AppTheme.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select days to weigh in and track progress',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _WeekDaySelector(
            selectedDays: state.checkInDays,
            onDayToggle: (day) => notifier.toggleCheckInDay(day),
          ),
          const SizedBox(height: 32),

          // Diet type
          Text(
            'Diet Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred macro distribution',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ProfileEnums.dietTypes.map((type) {
              final isSelected = state.dietType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setDietType(type),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != ProfileEnums.dietTypes.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ProfileEnums.dietTypeLabels[type] ?? type,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDietDescription(type),
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Meals per day
          Text(
            'Meals Per Day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'How many meals do you typically eat?',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _MealsSlider(
            value: state.mealsPerDay,
            onChanged: (value) => notifier.setMealsPerDay(value),
          ),
          const SizedBox(height: 48),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.canProceedStep4 && !state.isLoading
                  ? () => notifier.saveStep4AndComplete()
                  : null,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete Setup'),
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

  String _getDietDescription(String type) {
    switch (type) {
      case 'low_carb':
        return '35P/25C/40F';
      case 'balanced':
        return '30P/40C/30F';
      case 'high_carb':
        return '25P/50C/25F';
      default:
        return '';
    }
  }
}

class _WeekDaySelector extends StatelessWidget {
  final List<String> selectedDays;
  final Function(String) onDayToggle;

  const _WeekDaySelector({
    required this.selectedDays,
    required this.onDayToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ProfileEnums.weekDays.map((day) {
        final isSelected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () => onDayToggle(day),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Center(
              child: Text(
                ProfileEnums.weekDayLabels[day]!.substring(0, 1),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MealsSlider extends StatelessWidget {
  final int value;
  final Function(int) onChanged;

  const _MealsSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '2',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value meals',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '6',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.zinc700,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }
}

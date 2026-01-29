import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../onboarding/data/models/user_profile_model.dart';
import '../providers/settings_provider.dart';

class EditDietScreen extends ConsumerStatefulWidget {
  const EditDietScreen({super.key});

  @override
  ConsumerState<EditDietScreen> createState() => _EditDietScreenState();
}

class _EditDietScreenState extends ConsumerState<EditDietScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStateProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Diet Preferences',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        elevation: 0,
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: notifier.allDaysSelected
                                ? theme.colorScheme.primary
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notifier.allDaysSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            'Everyday',
                            style: TextStyle(
                              color: notifier.allDaysSelected
                                  ? Colors.white
                                  : theme.textTheme.bodySmall?.color,
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
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ProfileEnums.weekDays.map((day) {
                      final isSelected =
                          state.profile?.checkInDays.contains(day) ?? false;
                      return GestureDetector(
                        onTap: () => notifier.toggleCheckInDay(day),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              ProfileEnums.weekDayLabels[day]!.substring(0, 1),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ProfileEnums.dietTypes.map((type) {
                      final isSelected = state.profile?.dietType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.updateDietType(type),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: type != ProfileEnums.dietTypes.last ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  ProfileEnums.dietTypeLabels[type] ?? type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDietDescription(type),
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
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
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '2',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.profile?.mealsPerDay ?? 4} meals',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '6',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: theme.colorScheme.primary,
                          inactiveTrackColor: theme.dividerColor,
                          thumbColor: theme.colorScheme.primary,
                          overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: (state.profile?.mealsPerDay ?? 4).toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          onChanged: (val) =>
                              notifier.updateMealsPerDay(val.round()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final success = await notifier.saveProfile();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Diet preferences updated!'),
                                  ),
                                );
                                context.pop();
                              }
                            },
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
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

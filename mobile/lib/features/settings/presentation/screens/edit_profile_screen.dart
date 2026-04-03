import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../onboarding/data/models/user_profile_model.dart';
import '../providers/settings_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _initialized = false;
  double _age = 30;
  double _heightCm = 170;
  double _weightKg = 70;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStateProvider.notifier).loadProfile();
    });
  }

  void _initValues(SettingsState state) {
    if (state.profile != null && !_initialized) {
      _initialized = true;
      _age = (state.profile!.age ?? 30).toDouble();
      _heightCm = state.profile!.heightCm ?? 170;
      _weightKg = state.profile!.weightKg ?? 70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);
    final theme = Theme.of(context);

    _initValues(state);

    // Derived display values for imperial
    final totalInches = _heightCm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    final weightLbs = (_weightKg * 2.205).round();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        elevation: 0,
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: AdaptiveSpinner())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sex selection
                  Text(context.l10n.onboardingSexLabel, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: ProfileEnums.sexOptions.map((sex) {
                      final isSelected = state.profile?.sex == sex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.updateSex(sex),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: sex == 'male' ? 8 : 0,
                              left: sex == 'female' ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
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
                                  sex == 'male' ? Icons.male : Icons.female,
                                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sex == 'male' ? 'Male' : 'Female',
                                  style: TextStyle(
                                    color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Age
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.l10n.onboardingAgeLabel, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${_age.round()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSlider(
                    value: _age,
                    min: 13,
                    max: 100,
                    divisions: 87,
                    theme: theme,
                    onChanged: (value) {
                      setState(() => _age = value);
                      notifier.updateAge(value.round());
                    },
                  ),
                  const SizedBox(height: 24),

                  // Unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.l10n.settingsHeightWeight, style: Theme.of(context).textTheme.titleMedium),
                      GestureDetector(
                        onTap: () => notifier.toggleUnitSystem(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            state.useMetric ? 'Metric' : 'Imperial',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Height
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Height', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        state.useMetric
                            ? '${_heightCm.round()} cm'
                            : '$feet\'$inches"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSlider(
                    value: _heightCm,
                    min: 120,
                    max: 220,
                    divisions: 100,
                    theme: theme,
                    onChanged: (value) {
                      setState(() => _heightCm = value);
                      notifier.updateHeight(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weight', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        state.useMetric
                            ? '${_weightKg.round()} kg'
                            : '$weightLbs lbs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSlider(
                    value: _weightKg,
                    min: 30,
                    max: 200,
                    divisions: 340,
                    theme: theme,
                    onChanged: (value) {
                      setState(() => _weightKg = value);
                      notifier.updateWeight(value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              HapticService.mediumTap();
                              final success = await notifier.saveProfile();
                              if (success && context.mounted) {
                                showAdaptiveToast(context, message: context.l10n.settingsProfileUpdated);
                                context.pop();
                              }
                            },
                      child: state.isLoading
                          ? const AdaptiveSpinner.small()
                          : Text(context.l10n.adminSaveChanges),
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

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ThemeData theme,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.cardColor,
        thumbColor: theme.colorScheme.primary,
        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

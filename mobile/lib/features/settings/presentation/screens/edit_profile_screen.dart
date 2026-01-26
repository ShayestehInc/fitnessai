import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/data/models/user_profile_model.dart';
import '../providers/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _ageController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStateProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _heightCmController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initControllers(SettingsState state) {
    if (state.profile != null && _ageController.text.isEmpty) {
      _ageController.text = state.profile!.age?.toString() ?? '';
      if (state.useMetric) {
        _heightCmController.text = state.profile!.heightCm?.toString() ?? '';
        _weightController.text = state.profile!.weightKg?.toString() ?? '';
      } else {
        final totalInches = (state.profile!.heightCm ?? 0) / 2.54;
        _heightFeetController.text = (totalInches / 12).floor().toString();
        _heightInchesController.text = (totalInches % 12).round().toString();
        _weightController.text = ((state.profile!.weightKg ?? 0) * 2.205).round().toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);

    _initControllers(state);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.foreground),
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
                  // Sex selection
                  Text('Sex', style: Theme.of(context).textTheme.titleMedium),
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
                                Icon(
                                  sex == 'male' ? Icons.male : Icons.female,
                                  color: isSelected ? AppTheme.primary : AppTheme.mutedForeground,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sex == 'male' ? 'Male' : 'Female',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primary : AppTheme.foreground,
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
                  Text('Age', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter your age',
                      filled: true,
                      fillColor: AppTheme.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onChanged: (value) {
                      final age = int.tryParse(value);
                      if (age != null) notifier.updateAge(age);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Height & Weight', style: Theme.of(context).textTheme.titleMedium),
                      GestureDetector(
                        onTap: () => notifier.toggleUnitSystem(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            state.useMetric ? 'Metric' : 'Imperial',
                            style: TextStyle(
                              color: AppTheme.primary,
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
                  if (state.useMetric)
                    TextField(
                      controller: _heightCmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Height (cm)',
                        filled: true,
                        fillColor: AppTheme.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      onChanged: (value) {
                        final cm = double.tryParse(value);
                        if (cm != null) notifier.updateHeight(cm);
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightFeetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Feet',
                              filled: true,
                              fillColor: AppTheme.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.border),
                              ),
                            ),
                            onChanged: (_) => _updateHeightFromImperial(notifier),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightInchesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Inches',
                              filled: true,
                              fillColor: AppTheme.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.border),
                              ),
                            ),
                            onChanged: (_) => _updateHeightFromImperial(notifier),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Weight
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: state.useMetric ? 'Weight (kg)' : 'Weight (lbs)',
                      filled: true,
                      fillColor: AppTheme.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value);
                      if (weight != null) {
                        final kg = state.useMetric ? weight : weight / 2.205;
                        notifier.updateWeight(kg);
                      }
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
                              final success = await notifier.saveProfile();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile updated!')),
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
                      style: TextStyle(color: AppTheme.destructive),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _updateHeightFromImperial(SettingsNotifier notifier) {
    final feet = int.tryParse(_heightFeetController.text) ?? 0;
    final inches = int.tryParse(_heightInchesController.text) ?? 0;
    final totalInches = (feet * 12) + inches;
    final cm = totalInches * 2.54;
    notifier.updateHeight(cm);
  }
}

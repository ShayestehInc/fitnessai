import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/progression_profile_model.dart';
import '../providers/progression_profile_provider.dart';

class ProgressionProfileScreen extends ConsumerStatefulWidget {
  final int? profileId;

  const ProgressionProfileScreen({super.key, this.profileId});

  @override
  ConsumerState<ProgressionProfileScreen> createState() =>
      _ProgressionProfileScreenState();
}

class _ProgressionProfileScreenState
    extends ConsumerState<ProgressionProfileScreen> {
  String? _selectedStrategy;
  final _stepSizeController = TextEditingController();
  final _deloadFrequencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.profileId != null) {
        ref
            .read(progressionProfileProvider.notifier)
            .loadProfile(widget.profileId!);
      } else {
        ref.read(progressionProfileProvider.notifier).loadProfiles();
      }
    });
  }

  @override
  void dispose() {
    _stepSizeController.dispose();
    _deloadFrequencyController.dispose();
    super.dispose();
  }

  void _populateFields(ProgressionProfileModel profile) {
    _selectedStrategy ??= profile.strategy;
    if (_stepSizeController.text.isEmpty) {
      _stepSizeController.text = profile.config.stepSize.toString();
    }
    if (_deloadFrequencyController.text.isEmpty) {
      _deloadFrequencyController.text =
          profile.config.deloadFrequency.toString();
    }
  }

  Future<void> _saveProfile(ProgressionProfileModel profile) async {
    final stepSize = double.tryParse(_stepSizeController.text);
    if (stepSize == null || stepSize <= 0) {
      showAdaptiveToast(
        context,
        message: 'Step size must be a positive number',
        type: ToastType.error,
      );
      return;
    }
    final deloadFreq = int.tryParse(_deloadFrequencyController.text);
    if (deloadFreq == null || deloadFreq < 1) {
      showAdaptiveToast(
        context,
        message: 'Deload frequency must be at least 1',
        type: ToastType.error,
      );
      return;
    }

    final config = {
      'step_size': stepSize,
      'deload_frequency': deloadFreq,
      'wave_pattern': profile.config.wavePattern,
    };

    final success = await ref
        .read(progressionProfileProvider.notifier)
        .updateProfile(
          profile.id,
          strategy: _selectedStrategy,
          config: config,
        );

    if (!mounted) return;
    if (success) {
      showAdaptiveToast(
        context,
        message: 'Progression profile updated',
        type: ToastType.success,
      );
    } else {
      final error = ref.read(progressionProfileProvider).error;
      showAdaptiveToast(
        context,
        message: error ?? 'Failed to save',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(progressionProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progression Profile')),
      body: _buildBody(theme, profileState),
    );
  }

  Widget _buildBody(ThemeData theme, ProgressionProfileState state) {
    if (state.isLoading) {
      return const Center(child: AdaptiveSpinner());
    }
    if (state.error != null && state.selectedProfile == null) {
      return _buildError(theme, state.error!);
    }
    final profile = state.selectedProfile;
    if (profile == null) {
      return _buildEmpty(theme);
    }
    _populateFields(profile);
    return _buildForm(theme, profile, state.isSaving);
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
            const SizedBox(height: 16),
            Text('Failed to Load Profile', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(progressionProfileProvider.notifier)
                  .loadProfiles(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Progression Profile',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A progression profile will be created when your trainer '
              'assigns a training plan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    ThemeData theme,
    ProgressionProfileModel profile,
    bool isSaving,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStrategySelector(theme),
        const SizedBox(height: 20),
        _buildConfigSection(theme),
        const SizedBox(height: 24),
        _buildSaveButton(theme, profile, isSaving),
      ],
    );
  }

  Widget _buildStrategySelector(ThemeData theme) {
    const strategies = ['staircase', 'wave', 'deload'];
    const labels = {
      'staircase': 'Staircase',
      'wave': 'Wave',
      'deload': 'Auto-Deload',
    };
    const icons = {
      'staircase': Icons.stairs,
      'wave': Icons.waves,
      'deload': Icons.trending_down,
    };
    const descriptions = {
      'staircase': 'Linear progression with gradual increases each session.',
      'wave': 'Undulating loads cycling through light, medium, heavy.',
      'deload': 'Auto-reduce volume when fatigue markers are detected.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strategy', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...strategies.map((strategy) {
          final isSelected = _selectedStrategy == strategy;
          return GestureDetector(
            onTap: () => setState(() => _selectedStrategy = strategy),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSelected ? AppTheme.primary : AppTheme.zinc600)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icons[strategy] ?? Icons.help,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.mutedForeground,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels[strategy] ?? strategy,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? AppTheme.foreground
                                : AppTheme.zinc300,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          descriptions[strategy] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfigSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuration', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          label: 'Step Size (lbs)',
          controller: _stepSizeController,
          hint: '2.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          theme,
          label: 'Deload Every N Weeks',
          controller: _deloadFrequencyController,
          hint: '4',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.zinc600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(
    ThemeData theme,
    ProgressionProfileModel profile,
    bool isSaving,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : () => _saveProfile(profile),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryForeground,
                ),
              )
            : const Text('Save Changes'),
      ),
    );
  }
}

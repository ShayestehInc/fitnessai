import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Shared expanded brief form used by both Quick Build and Advanced Builder.
/// Collects all inputs per the UI/UX spec: goals, schedule, experience,
/// equipment, recovery, pain tolerances, and preferences.
class ExpandedBriefForm extends StatelessWidget {
  // Core
  final String goal;
  final ValueChanged<String> onGoalChanged;
  final int daysPerWeek;
  final ValueChanged<int> onDaysPerWeekChanged;
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onSelectedDaysChanged;
  final int sessionLength;
  final ValueChanged<int> onSessionLengthChanged;
  final String difficulty;
  final ValueChanged<String> onDifficultyChanged;
  final Set<String> equipment;
  final ValueChanged<Set<String>> onEquipmentChanged;
  final String style;
  final ValueChanged<String> onStyleChanged;

  // Expanded
  final String secondaryGoal;
  final ValueChanged<String> onSecondaryGoalChanged;
  final List<String> bodyPartEmphasis;
  final ValueChanged<List<String>> onBodyPartEmphasisChanged;
  final int? trainingAgeYears;
  final ValueChanged<int?> onTrainingAgeChanged;
  final String skillLevel;
  final ValueChanged<String> onSkillLevelChanged;
  final Map<String, String> recoveryProfile;
  final ValueChanged<Map<String, String>> onRecoveryProfileChanged;
  final Map<String, String> painTolerances;
  final ValueChanged<Map<String, String>> onPainTolerancesChanged;
  final List<String> hatedLifts;
  final ValueChanged<List<String>> onHatedLiftsChanged;
  final String complexityTolerance;
  final ValueChanged<String> onComplexityToleranceChanged;

  const ExpandedBriefForm({
    super.key,
    required this.goal,
    required this.onGoalChanged,
    required this.daysPerWeek,
    required this.onDaysPerWeekChanged,
    required this.selectedDays,
    required this.onSelectedDaysChanged,
    required this.sessionLength,
    required this.onSessionLengthChanged,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.equipment,
    required this.onEquipmentChanged,
    required this.style,
    required this.onStyleChanged,
    this.secondaryGoal = '',
    required this.onSecondaryGoalChanged,
    this.bodyPartEmphasis = const [],
    required this.onBodyPartEmphasisChanged,
    this.trainingAgeYears,
    required this.onTrainingAgeChanged,
    this.skillLevel = '',
    required this.onSkillLevelChanged,
    this.recoveryProfile = const {},
    required this.onRecoveryProfileChanged,
    this.painTolerances = const {},
    required this.onPainTolerancesChanged,
    this.hatedLifts = const [],
    required this.onHatedLiftsChanged,
    this.complexityTolerance = '',
    required this.onComplexityToleranceChanged,
  });

  static const _goals = [
    ('build_muscle', 'Build Muscle', Icons.fitness_center_rounded),
    ('strength', 'Strength', Icons.bolt_rounded),
    ('fat_loss', 'Fat Loss', Icons.local_fire_department_rounded),
    ('endurance', 'Endurance', Icons.directions_run_rounded),
    ('recomp', 'Recomp', Icons.swap_vert_rounded),
    ('general_fitness', 'General', Icons.favorite_rounded),
  ];

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _equipmentOptions = [
    'barbell', 'dumbbell', 'cable', 'machine',
    'bodyweight', 'kettlebell', 'bands', 'smith_machine',
  ];

  static const _bodyParts = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'quadriceps', 'hamstrings', 'glutes', 'calves', 'core',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(context, 'Primary Goal'),
        const SizedBox(height: 8),
        _buildGoalSelector(),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Secondary Goal (optional)'),
        const SizedBox(height: 8),
        _buildSecondaryGoalSelector(),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Training Days'),
        const SizedBox(height: 8),
        _buildDaySelector(),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Session Length'),
        const SizedBox(height: 8),
        _buildSlider(
          value: sessionLength,
          min: 30,
          max: 120,
          divisions: 6,
          label: '$sessionLength min',
          onChanged: onSessionLengthChanged,
        ),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Equipment'),
        const SizedBox(height: 8),
        _buildMultiChipSelector(
          options: _equipmentOptions,
          selected: equipment,
          onChanged: onEquipmentChanged,
        ),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Difficulty'),
        const SizedBox(height: 8),
        _buildSingleChipRow(
          options: const [
            ('beginner', 'Beginner'),
            ('intermediate', 'Intermediate'),
            ('advanced', 'Advanced'),
          ],
          selected: difficulty,
          onChanged: onDifficultyChanged,
        ),
        const SizedBox(height: 20),

        _sectionLabel(context, 'Body Part Emphasis (optional)'),
        const SizedBox(height: 8),
        _buildMultiChipSelector(
          options: _bodyParts,
          selected: bodyPartEmphasis.toSet(),
          onChanged: (s) => onBodyPartEmphasisChanged(s.toList()),
        ),
        const SizedBox(height: 20),

        // Collapsible advanced section
        _ExpandableSection(
          title: 'Experience & Recovery',
          children: [
            _sectionLabel(context, 'Training Age'),
            const SizedBox(height: 8),
            _buildSlider(
              value: trainingAgeYears ?? 2,
              min: 0,
              max: 20,
              divisions: 20,
              label: '${trainingAgeYears ?? 2} years',
              onChanged: (v) => onTrainingAgeChanged(v),
            ),
            const SizedBox(height: 16),
            _sectionLabel(context, 'Skill Level'),
            const SizedBox(height: 8),
            _buildSingleChipRow(
              options: const [
                ('novice', 'Novice'),
                ('intermediate', 'Intermediate'),
                ('advanced', 'Advanced'),
              ],
              selected: skillLevel,
              onChanged: onSkillLevelChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel(context, 'Recovery'),
            const SizedBox(height: 8),
            _buildRecoveryRow('Sleep', 'sleep'),
            const SizedBox(height: 8),
            _buildRecoveryRow('Stress', 'stress'),
            const SizedBox(height: 8),
            _buildRecoveryRow('Soreness Tolerance', 'soreness_tolerance'),
          ],
        ),
        const SizedBox(height: 12),

        _ExpandableSection(
          title: 'Pain & Restrictions',
          children: [
            _buildPainRow('Overhead', 'overhead'),
            const SizedBox(height: 8),
            _buildPainRow('Axial Loading', 'axial_loading'),
            const SizedBox(height: 8),
            _buildPainRow('Unilateral', 'unilateral'),
            const SizedBox(height: 8),
            _buildPainRow('Impact', 'impact'),
          ],
        ),
        const SizedBox(height: 12),

        _ExpandableSection(
          title: 'Preferences',
          children: [
            _sectionLabel(context, 'Style'),
            const SizedBox(height: 8),
            _buildSingleChipRow(
              options: const [
                ('', 'No preference'),
                ('bodybuilding', 'Bodybuilding'),
                ('powerbuilding', 'Powerbuilding'),
                ('athletic', 'Athletic'),
                ('functional', 'Functional'),
                ('minimalist', 'Minimalist'),
              ],
              selected: style,
              onChanged: onStyleChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel(context, 'Complexity'),
            const SizedBox(height: 8),
            _buildSingleChipRow(
              options: const [
                ('low', 'Keep it simple'),
                ('moderate', 'Moderate'),
                ('high', 'Bring it on'),
              ],
              selected: complexityTolerance,
              onChanged: onComplexityToleranceChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.foreground,
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _goals.map((g) {
        final isSelected = goal == g.$1;
        return _ChipButton(
          label: g.$2,
          icon: g.$3,
          isSelected: isSelected,
          onTap: () => onGoalChanged(g.$1),
        );
      }).toList(),
    );
  }

  Widget _buildSecondaryGoalSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChipButton(
          label: 'None',
          isSelected: secondaryGoal.isEmpty,
          onTap: () => onSecondaryGoalChanged(''),
        ),
        ..._goals
            .where((g) => g.$1 != goal)
            .map((g) => _ChipButton(
                  label: g.$2,
                  isSelected: secondaryGoal == g.$1,
                  onTap: () => onSecondaryGoalChanged(g.$1),
                )),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isSelected = selectedDays.contains(i);
        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected && newDays.length > 1) {
              newDays.remove(i);
            } else {
              newDays.add(i);
            }
            onSelectedDaysChanged(newDays);
            onDaysPerWeekChanged(newDays.length);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.zinc800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _dayNames[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.mutedForeground,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlider({
    required int value,
    required int min,
    required int max,
    required int divisions,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.foreground, fontSize: 14)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiChipSelector({
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return _ChipButton(
          label: opt.replaceAll('_', ' '),
          isSelected: isSelected,
          onTap: () {
            final newSet = Set<String>.from(selected);
            if (isSelected) {
              newSet.remove(opt);
            } else {
              newSet.add(opt);
            }
            onChanged(newSet);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSingleChipRow({
    required List<(String, String)> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        return _ChipButton(
          label: o.$2,
          isSelected: selected == o.$1,
          onTap: () => onChanged(o.$1),
        );
      }).toList(),
    );
  }

  Widget _buildRecoveryRow(String label, String key) {
    final value = recoveryProfile[key] ?? '';
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.zinc400)),
        ),
        ...['poor', 'fair', 'good'].map((opt) {
          final isSelected = value == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ChipButton(
              label: opt,
              isSelected: isSelected,
              onTap: () {
                final newMap = Map<String, String>.from(recoveryProfile);
                newMap[key] = opt;
                onRecoveryProfileChanged(newMap);
              },
              small: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPainRow(String label, String key) {
    final value = painTolerances[key] ?? 'ok';
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.zinc400)),
        ),
        ...['ok', 'limited', 'avoid'].map((opt) {
          final isSelected = value == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ChipButton(
              label: opt,
              isSelected: isSelected,
              onTap: () {
                final newMap = Map<String, String>.from(painTolerances);
                newMap[key] = opt;
                onPainTolerancesChanged(newMap);
              },
              small: true,
              dangerWhenSelected: opt == 'avoid',
            ),
          );
        }),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool small;
  final bool dangerWhenSelected;

  const _ChipButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.small = false,
    this.dangerWhenSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = dangerWhenSelected && isSelected
        ? AppTheme.destructive
        : AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 12,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : AppTheme.zinc800,
          borderRadius: BorderRadius.circular(small ? 6 : 8),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? activeColor : AppTheme.mutedForeground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.foreground : AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _ExpandableSection({required this.title, required this.children});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: AppTheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}

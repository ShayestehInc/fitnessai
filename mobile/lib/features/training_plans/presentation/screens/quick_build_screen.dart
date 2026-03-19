import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/builder_models.dart';
import '../providers/training_plan_provider.dart';
import '../widgets/why_panel.dart';

/// Quick Build: simple form -> generate -> review result with explanations.
class QuickBuildScreen extends ConsumerStatefulWidget {
  const QuickBuildScreen({super.key});

  @override
  ConsumerState<QuickBuildScreen> createState() => _QuickBuildScreenState();
}

class _QuickBuildScreenState extends ConsumerState<QuickBuildScreen> {
  // Form state
  String _goal = 'build_muscle';
  int _daysPerWeek = 4;
  String _difficulty = 'intermediate';
  int _sessionLength = 60;
  final Set<String> _equipment = {'barbell', 'dumbbell', 'cable'};
  final List<String> _injuries = [];
  String _style = '';
  final List<String> _priorities = [];
  final List<String> _dislikes = [];
  final Set<int> _selectedDays = {0, 1, 3, 4}; // Mon, Tue, Thu, Fri

  bool _showResult = false;

  static const _goals = [
    ('build_muscle', 'Build Muscle', Icons.fitness_center_rounded),
    ('strength', 'Strength', Icons.bolt_rounded),
    ('fat_loss', 'Fat Loss', Icons.local_fire_department_rounded),
    ('endurance', 'Endurance', Icons.directions_run_rounded),
    ('recomp', 'Recomp', Icons.swap_vert_rounded),
    ('general_fitness', 'General', Icons.favorite_rounded),
  ];

  static const _equipmentOptions = [
    'barbell',
    'dumbbell',
    'cable',
    'machine',
    'bodyweight',
    'kettlebell',
    'bands',
    'smith_machine',
  ];

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _styleOptions = [
    ('', 'No preference'),
    ('bodybuilding', 'Bodybuilding'),
    ('powerbuilding', 'Powerbuilding'),
    ('athletic', 'Athletic'),
    ('functional', 'Functional'),
    ('minimalist', 'Minimalist'),
  ];

  void _updateDaysPerWeek(int days) {
    setState(() {
      _daysPerWeek = days;
      // Auto-select default day indices
      _selectedDays.clear();
      const defaults = {
        1: [0],
        2: [0, 3],
        3: [0, 2, 4],
        4: [0, 1, 3, 4],
        5: [0, 1, 2, 3, 4],
        6: [0, 1, 2, 3, 4, 5],
        7: [0, 1, 2, 3, 4, 5, 6],
      };
      _selectedDays.addAll(defaults[days] ?? []);
    });
  }

  Future<void> _generate() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final brief = BuilderBrief(
      traineeId: userId,
      goal: _goal,
      daysPerWeek: _daysPerWeek,
      difficulty: _difficulty,
      sessionLengthMinutes: _sessionLength,
      equipment: _equipment.toList(),
      injuries: _injuries,
      style: _style,
      priorities: _priorities,
      dislikes: _dislikes,
      trainingDayIndices: _selectedDays.toList()..sort(),
    );

    await ref.read(quickBuildProvider.notifier).build(brief);
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final buildState = ref.watch(quickBuildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Build'),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () {
            if (_showResult) {
              setState(() => _showResult = false);
              ref.read(quickBuildProvider.notifier).reset();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _showResult
          ? _buildResult(buildState)
          : _buildForm(buildState.isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Goal'),
          const SizedBox(height: 8),
          _buildGoalSelector(),
          const SizedBox(height: 24),
          _sectionLabel('Training Days'),
          const SizedBox(height: 8),
          _buildDaysPerWeekSlider(),
          const SizedBox(height: 12),
          _buildDaySelector(),
          const SizedBox(height: 24),
          _sectionLabel('Session Length'),
          const SizedBox(height: 8),
          _buildSessionLengthSlider(),
          const SizedBox(height: 24),
          _sectionLabel('Equipment'),
          const SizedBox(height: 8),
          _buildEquipmentChips(),
          const SizedBox(height: 24),
          _sectionLabel('Difficulty'),
          const SizedBox(height: 8),
          _buildDifficultySelector(),
          const SizedBox(height: 24),
          _sectionLabel('Style (optional)'),
          const SizedBox(height: 8),
          _buildStyleSelector(),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : _generate,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Program'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResult(QuickBuildState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() => _showResult = false);
                  ref.read(quickBuildProvider.notifier).reset();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.planName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.zinc300,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatChip(label: '${result.weeksCount} weeks'),
              const SizedBox(width: 8),
              _StatChip(label: '${result.sessionsCount} sessions'),
              const SizedBox(width: 8),
              _StatChip(label: '${result.slotsCount} exercises'),
            ],
          ),
          const SizedBox(height: 24),

          // Step explanations
          Text(
            'Why This Fits',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...result.stepExplanations.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WhyPanel(
                  stepName: e.stepName,
                  why: e.why,
                ),
              )),
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                // Navigate to plan detail
                context.push('/plan-detail/${result.planId}');
              },
              child: const Text('View Plan Details'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                setState(() => _showResult = false);
                ref.read(quickBuildProvider.notifier).reset();
              },
              child: const Text('Build Another'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.foreground,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildGoalSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _goals.map((g) {
        final isSelected = _goal == g.$1;
        return GestureDetector(
          onTap: () => setState(() => _goal = g.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.zinc800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(g.$3,
                    size: 16,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  g.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? AppTheme.foreground
                        : AppTheme.mutedForeground,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysPerWeekSlider() {
    return Row(
      children: [
        Text(
          '$_daysPerWeek days/week',
          style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
        ),
        Expanded(
          child: Slider(
            value: _daysPerWeek.toDouble(),
            min: 2,
            max: 7,
            divisions: 5,
            onChanged: (v) => _updateDaysPerWeek(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isSelected = _selectedDays.contains(i);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_selectedDays.length > 1) _selectedDays.remove(i);
              } else {
                _selectedDays.add(i);
              }
              _daysPerWeek = _selectedDays.length;
            });
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
                color:
                    isSelected ? AppTheme.primary : AppTheme.mutedForeground,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSessionLengthSlider() {
    return Row(
      children: [
        Text(
          '$_sessionLength min',
          style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
        ),
        Expanded(
          child: Slider(
            value: _sessionLength.toDouble(),
            min: 30,
            max: 120,
            divisions: 6,
            onChanged: (v) => setState(() => _sessionLength = v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _equipmentOptions.map((eq) {
        final isSelected = _equipment.contains(eq);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _equipment.remove(eq);
            } else {
              _equipment.add(eq);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.zinc800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Text(
              eq.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 13,
                color:
                    isSelected ? AppTheme.foreground : AppTheme.mutedForeground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    const options = [
      ('beginner', 'Beginner'),
      ('intermediate', 'Intermediate'),
      ('advanced', 'Advanced'),
    ];
    return Row(
      children: options.map((o) {
        final isSelected = _difficulty == o.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: o.$1 == 'advanced' ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  o.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.foreground
                        : AppTheme.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _styleOptions.map((s) {
        final isSelected = _style == s.$1;
        return GestureDetector(
          onTap: () => setState(() => _style = s.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.zinc800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Text(
              s.$2,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? AppTheme.foreground
                    : AppTheme.mutedForeground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.zinc300,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

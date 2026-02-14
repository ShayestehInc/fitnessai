import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/edit_food_entry_sheet.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionStateProvider.notifier).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(nutritionStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: state.isLoading && state.dailySummary == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(nutritionStateProvider.notifier).loadInitialData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Goal and Weight Header
                        _buildGoalHeader(state, theme),
                        const SizedBox(height: 16),

                        // Check In button
                        _buildCheckInButton(theme),
                        const SizedBox(height: 24),

                        // Date navigator
                        _buildDateNavigator(state, theme),
                        const SizedBox(height: 20),

                        // Macro presets (if trainer has set any)
                        if (state.hasPresets) ...[
                          _buildMacroPresetsSection(state, theme),
                          const SizedBox(height: 16),
                        ],

                        // Macro cards
                        _buildMacroCards(state, theme),
                        const SizedBox(height: 24),

                        // Meals section
                        _buildMealsSection(state, theme),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGoalHeader(NutritionState state, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your Goal section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Your goal',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      // Refresh goal
                      ref.read(nutritionStateProvider.notifier).loadInitialData();
                    },
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.goalLabel,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Latest Weight section
        GestureDetector(
          onTap: () => context.push('/weight-trends'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    state.latestCheckIn != null
                        ? 'Latest Weight, ${state.latestWeightDate}'
                        : 'Latest Weight',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.bar_chart,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.latestWeightFormatted,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.push('/weight-checkin'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textTheme.bodyLarge?.color,
          side: BorderSide(color: theme.colorScheme.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Check In'),
      ),
    );
  }

  Widget _buildDateNavigator(NutritionState state, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () =>
              ref.read(nutritionStateProvider.notifier).goToPreviousDay(),
          icon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        GestureDetector(
          onTap: () =>
              ref.read(nutritionStateProvider.notifier).goToToday(),
          child: Text(
            state.formattedDate,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        IconButton(
          onPressed: () =>
              ref.read(nutritionStateProvider.notifier).goToNextDay(),
          icon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroPresetsSection(NutritionState state, ThemeData theme) {
    final presets = state.macroPresets;
    final activePreset = state.activePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Macro Presets',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'From Trainer',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = activePreset?.id == preset.id;

              return GestureDetector(
                onTap: () => _showPresetDetail(context, preset, isActive),
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(right: index < presets.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodyLarge?.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (preset.isDefault)
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${preset.calories} cal',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      if (preset.frequencyDisplay.isNotEmpty)
                        Text(
                          preset.frequencyDisplay,
                          style: TextStyle(
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPresetDetail(BuildContext context, MacroPresetModel preset, bool isActive) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Preset name and badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (preset.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (preset.frequencyDisplay.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preset.frequencyDisplay,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Macro breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildPresetMacroRow(theme, 'Calories', '${preset.calories}', 'cal', Colors.orange),
                    const Divider(height: 24),
                    _buildPresetMacroRow(theme, 'Protein', '${preset.protein}', 'g', const Color(0xFFEC4899)),
                    const Divider(height: 24),
                    _buildPresetMacroRow(theme, 'Carbs', '${preset.carbs}', 'g', const Color(0xFF22C55E)),
                    const Divider(height: 24),
                    _buildPresetMacroRow(theme, 'Fat', '${preset.fat}', 'g', const Color(0xFF3B82F6)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isActive
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final success = await ref
                              .read(nutritionStateProvider.notifier)
                              .applyPreset(preset);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Applied "${preset.name}" preset'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isActive ? 'Currently Active' : 'Apply This Preset',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetMacroRow(ThemeData theme, String label, String value, String unit, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCards(NutritionState state, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            label: 'Protein, g',
            current: state.proteinConsumed,
            goal: state.proteinGoal,
            remaining: state.proteinRemaining,
            progress: state.proteinProgress,
            color: const Color(0xFFEC4899), // Pink
            backgroundColor: const Color(0xFF2D1F2F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Carbs, g',
            current: state.carbsConsumed,
            goal: state.carbsGoal,
            remaining: state.carbsRemaining,
            progress: state.carbsProgress,
            color: const Color(0xFF22C55E), // Green
            backgroundColor: const Color(0xFF1F2D25),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            label: 'Fat, g',
            current: state.fatConsumed,
            goal: state.fatGoal,
            remaining: state.fatRemaining,
            progress: state.fatProgress,
            color: const Color(0xFF3B82F6), // Blue
            backgroundColor: const Color(0xFF1F252D),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsSection(NutritionState state, ThemeData theme) {
    final meals = state.dailySummary?.meals ?? [];
    final perMealTargets = state.dailySummary?.perMealTargets ??
        PerMealTargets(
          protein: state.goals?.perMealProtein ?? 0,
          carbs: state.goals?.perMealCarbs ?? 0,
          fat: state.goals?.perMealFat ?? 0,
        );
    final mealsPerDay = state.userProfile?.mealsPerDay ?? 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(mealsPerDay, (index) {
        final mealNumber = index + 1;
        final mealEntries = <MapEntry<int, MealEntry>>[];
        for (int i = 0; i < meals.length; i++) {
          if (meals[i].name.toLowerCase().contains('meal $mealNumber')) {
            mealEntries.add(MapEntry(i, meals[i]));
          }
        }
        final totalProtein = mealEntries.fold(0, (sum, e) => sum + e.value.protein);
        final totalCarbs = mealEntries.fold(0, (sum, e) => sum + e.value.carbs);
        final totalFat = mealEntries.fold(0, (sum, e) => sum + e.value.fat);

        return _MealSection(
          mealNumber: mealNumber,
          entries: mealEntries.map((e) => e.value).toList(),
          entryIndices: mealEntries.map((e) => e.key).toList(),
          totalProtein: totalProtein,
          totalCarbs: totalCarbs,
          totalFat: totalFat,
          targetProtein: perMealTargets.protein,
          targetCarbs: perMealTargets.carbs,
          targetFat: perMealTargets.fat,
          onAddFood: () => context.push('/add-food?meal=$mealNumber'),
          onEditEntry: (entryIndex, entry) => _handleEditEntry(entryIndex, entry),
          onDeleteEntry: (entryIndex) => _handleDeleteEntry(entryIndex),
          theme: theme,
        );
      }),
    );
  }

  Future<void> _handleEditEntry(int entryIndex, MealEntry entry) async {
    final edited = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EditFoodEntrySheet(
        entry: entry,
        onDelete: () => _handleDeleteEntry(entryIndex),
      ),
    );

    if (edited == null || !mounted) return;

    // Get the daily log ID from the nutrition summary API
    // We need to get the daily log for today's date
    final state = ref.read(nutritionStateProvider);
    final dateStr = _formatDate(state.selectedDate);
    final logResult = await ref.read(nutritionStateProvider.notifier).getDailyLogId(dateStr);
    if (logResult == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No log found for this date')),
        );
      }
      return;
    }

    final nutritionRepo = NutritionRepository(ref.read(apiClientProvider));
    final result = await nutritionRepo.editMealEntry(
      logId: logResult,
      mealIndex: 0,
      entryIndex: entryIndex,
      data: {
        'name': edited.name,
        'protein': edited.protein,
        'carbs': edited.carbs,
        'fat': edited.fat,
        'calories': edited.calories,
      },
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food entry updated')),
      );
      ref.read(nutritionStateProvider.notifier).loadInitialData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to update'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleDeleteEntry(int entryIndex) async {
    final state = ref.read(nutritionStateProvider);
    final dateStr = _formatDate(state.selectedDate);
    final logResult = await ref.read(nutritionStateProvider.notifier).getDailyLogId(dateStr);
    if (logResult == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No log found for this date')),
        );
      }
      return;
    }

    final nutritionRepo = NutritionRepository(ref.read(apiClientProvider));
    final result = await nutritionRepo.deleteMealEntry(
      logId: logResult,
      mealIndex: 0,
      entryIndex: entryIndex,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food entry deleted')),
      );
      ref.read(nutritionStateProvider.notifier).loadInitialData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to delete'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Macro card with circular progress and stats
class _MacroCard extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final int remaining;
  final double progress;
  final Color color;
  final Color backgroundColor;

  const _MacroCard({
    required this.label,
    required this.current,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? backgroundColor : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Circular progress
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.dividerColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$current',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 8),

          // Goal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal:',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              Text(
                '$goal',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Remain row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remain',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              Text(
                '$remaining',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Meal section with entries and add food button
class _MealSection extends StatelessWidget {
  final int mealNumber;
  final List<MealEntry> entries;
  final List<int> entryIndices;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final VoidCallback onAddFood;
  final void Function(int entryIndex, MealEntry entry) onEditEntry;
  final void Function(int entryIndex) onDeleteEntry;
  final ThemeData theme;

  const _MealSection({
    required this.mealNumber,
    required this.entries,
    required this.entryIndices,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.onAddFood,
    required this.onEditEntry,
    required this.onDeleteEntry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Meal header with macros
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                'Meal $mealNumber',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildMacroTarget(totalProtein, targetProtein),
              const SizedBox(width: 16),
              _buildMacroTarget(totalCarbs, targetCarbs),
              const SizedBox(width: 16),
              _buildMacroTarget(totalFat, targetFat),
            ],
          ),
        ),

        // Food entries
        if (entries.isNotEmpty)
          for (int i = 0; i < entries.length; i++)
            _FoodEntryRow(
              entry: entries[i],
              theme: theme,
              onEdit: () => onEditEntry(entryIndices[i], entries[i]),
            ),

        // Add Food button row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onAddFood,
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add Food',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: theme.textTheme.bodySmall?.color,
                ),
                color: theme.cardColor,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.copy, color: theme.textTheme.bodyLarge?.color, size: 18),
                        const SizedBox(width: 8),
                        Text('Copy Meal', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Clear Meal', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Divider
        Container(
          height: 1,
          color: theme.dividerColor,
        ),
      ],
    );
  }

  Widget _buildMacroTarget(int current, int target) {
    return Text(
      '$current/$target',
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color,
        fontSize: 14,
      ),
    );
  }
}

class _FoodEntryRow extends StatelessWidget {
  final MealEntry entry;
  final ThemeData theme;
  final VoidCallback onEdit;

  const _FoodEntryRow({
    required this.entry,
    required this.theme,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Extract just the food name (remove "Meal X - " prefix if present)
    String displayName = entry.name;
    final mealPrefixMatch = RegExp(r'^Meal \d+ - ').firstMatch(entry.name);
    if (mealPrefixMatch != null) {
      displayName = entry.name.substring(mealPrefixMatch.end);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.protein}g',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.carbs}g',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.fat}g',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Icon(
              Icons.edit_outlined,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

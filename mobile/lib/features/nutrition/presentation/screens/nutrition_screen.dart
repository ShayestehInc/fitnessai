import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/nutrition_models.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/macro_progress_circle.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionStateProvider.notifier).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
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
                        // Header
                        _buildHeader(state),
                        const SizedBox(height: 24),

                        // Date navigator
                        _buildDateNavigator(state),
                        const SizedBox(height: 24),

                        // Macro circles
                        _buildMacroCircles(state),
                        const SizedBox(height: 32),

                        // Meals section
                        _buildMealsSection(state),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(NutritionState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.goals != null
                        ? '${state.goals!.caloriesGoal} cal goal'
                        : 'Set your goals',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.latestCheckIn != null)
              Text(
                'Latest: ${state.latestCheckIn!.weightKg.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/weight-checkin'),
          icon: const Icon(Icons.scale, size: 16),
          label: const Text('Check In'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.foreground,
            side: BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator(NutritionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                ref.read(nutritionStateProvider.notifier).goToPreviousDay(),
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.mutedForeground,
          ),
          GestureDetector(
            onTap: () =>
                ref.read(nutritionStateProvider.notifier).goToToday(),
            child: Text(
              state.formattedDate,
              style: const TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(nutritionStateProvider.notifier).goToNextDay(),
            icon: const Icon(Icons.chevron_right),
            color: AppTheme.mutedForeground,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCircles(NutritionState state) {
    final consumed = state.dailySummary?.consumed;
    final goals = state.goals;
    final remaining = state.dailySummary?.remaining;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MacroProgressCircle(
          label: 'Protein',
          current: consumed?.protein ?? 0,
          goal: goals?.proteinGoal ?? 0,
          remaining: remaining?.protein ?? goals?.proteinGoal ?? 0,
          color: const Color(0xFFEC4899), // Pink
          size: 90,
        ),
        MacroProgressCircle(
          label: 'Carbs',
          current: consumed?.carbs ?? 0,
          goal: goals?.carbsGoal ?? 0,
          remaining: remaining?.carbs ?? goals?.carbsGoal ?? 0,
          color: const Color(0xFF22C55E), // Green
          size: 90,
        ),
        MacroProgressCircle(
          label: 'Fat',
          current: consumed?.fat ?? 0,
          goal: goals?.fatGoal ?? 0,
          remaining: remaining?.fat ?? goals?.fatGoal ?? 0,
          color: const Color(0xFF3B82F6), // Blue
          size: 90,
        ),
      ],
    );
  }

  Widget _buildMealsSection(NutritionState state) {
    final meals = state.dailySummary?.meals ?? [];
    final perMealTargets = state.dailySummary?.perMealTargets ??
        state.goals?.let((g) => PerMealTargets(
              protein: g.perMealProtein,
              carbs: g.perMealCarbs,
              fat: g.perMealFat,
            ));
    final mealsPerDay = state.goals?.let((g) => 4) ?? 4; // Default to 4

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Meals',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/add-food'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Food'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Generate meal cards
        ...List.generate(mealsPerDay, (index) {
          final mealNumber = index + 1;
          final mealEntries =
              meals.where((m) => m.name.contains('Meal $mealNumber')).toList();
          final totalProtein =
              mealEntries.fold(0, (sum, m) => sum + m.protein);
          final totalCarbs = mealEntries.fold(0, (sum, m) => sum + m.carbs);
          final totalFat = mealEntries.fold(0, (sum, m) => sum + m.fat);
          final totalCalories =
              mealEntries.fold(0, (sum, m) => sum + m.calories);

          return _MealCard(
            mealNumber: mealNumber,
            entries: mealEntries,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalCalories: totalCalories,
            targetProtein: perMealTargets?.protein ?? 0,
            targetCarbs: perMealTargets?.carbs ?? 0,
            targetFat: perMealTargets?.fat ?? 0,
            onAddFood: () => context.push('/add-food?meal=$mealNumber'),
          );
        }),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final int mealNumber;
  final List<MealEntry> entries;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final int totalCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final VoidCallback onAddFood;

  const _MealCard({
    required this.mealNumber,
    required this.entries,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meal $mealNumber',
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    _MacroChip(
                        label: 'P', value: totalProtein, target: targetProtein),
                    const SizedBox(width: 4),
                    _MacroChip(
                        label: 'C', value: totalCarbs, target: targetCarbs),
                    const SizedBox(width: 4),
                    _MacroChip(label: 'F', value: totalFat, target: targetFat),
                  ],
                ),
              ],
            ),
          ),

          // Entries
          if (entries.isNotEmpty)
            ...entries.map((entry) => _FoodEntryRow(entry: entry)),

          // Add food button
          InkWell(
            onTap: onAddFood,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add Food',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final int value;
  final int target;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = value >= target && target > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? AppTheme.primary.withOpacity(0.2)
            : AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: isComplete ? AppTheme.primary : AppTheme.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FoodEntryRow extends StatelessWidget {
  final MealEntry entry;

  const _FoodEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.calories} cal',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to handle null safety
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) block) {
    if (this != null) {
      return block(this as T);
    }
    return null;
  }
}

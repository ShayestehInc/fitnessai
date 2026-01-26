import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../logging/presentation/providers/logging_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/food_search_provider.dart';
import '../../data/models/food_search_model.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  final int? mealNumber;

  const AddFoodScreen({super.key, this.mealNumber});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _aiInputController = TextEditingController();
  final _searchController = TextEditingController();

  // Manual entry controllers
  final _foodNameController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingSizeController = TextEditingController();
  int _selectedMealNumber = 1;
  bool _isManualSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Default to the meal number passed in, or meal 1
    _selectedMealNumber = widget.mealNumber ?? 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiInputController.dispose();
    _searchController.dispose();
    _foodNameController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  int get _calculatedCalories {
    final protein = int.tryParse(_proteinController.text) ?? 0;
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fat = int.tryParse(_fatController.text) ?? 0;
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  @override
  Widget build(BuildContext context) {
    final loggingState = ref.watch(loggingStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.mealNumber != null
              ? 'Add to Meal ${widget.mealNumber}'
              : 'Add Food',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'AI Entry'),
            Tab(text: 'Search'),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.mutedForeground,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualEntry(),
          _buildAIQuickEntry(loggingState),
          _buildFoodSearch(),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Food Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Manually enter macros for your food',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Meal selector (only show if not passed in)
          if (widget.mealNumber == null) ...[
            Text(
              'Meal',
              style: TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: List.generate(4, (index) {
                  final mealNum = index + 1;
                  final isSelected = _selectedMealNumber == mealNum;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealNumber = mealNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Meal $mealNum',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.mutedForeground,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Food name
          Text(
            'Food Name',
            style: TextStyle(
              color: AppTheme.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foodNameController,
            decoration: InputDecoration(
              hintText: 'e.g., Chicken Breast',
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Serving size (optional)
          Text(
            'Serving Size (optional)',
            style: TextStyle(
              color: AppTheme.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _servingSizeController,
            decoration: InputDecoration(
              hintText: 'e.g., 150g, 1 cup',
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Macros section
          Text(
            'Macros',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Macro inputs in a row
          Row(
            children: [
              Expanded(
                child: _buildMacroInput(
                  label: 'Protein',
                  controller: _proteinController,
                  color: const Color(0xFFEC4899), // Pink
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput(
                  label: 'Carbs',
                  controller: _carbsController,
                  color: const Color(0xFF22C55E), // Green
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput(
                  label: 'Fat',
                  controller: _fatController,
                  color: const Color(0xFF3B82F6), // Blue
                  suffix: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calories display (calculated)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto-calculated from macros',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_calculatedCalories} cal',
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSaveManualEntry() && !_isManualSaving
                  ? _saveManualEntry
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
              ),
              child: _isManualSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Add Food',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick add presets
          Text(
            'Quick Add',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAddChip('Chicken Breast (150g)', 46, 0, 5),
              _buildQuickAddChip('Rice (1 cup)', 5, 45, 0),
              _buildQuickAddChip('Eggs (2 large)', 12, 1, 10),
              _buildQuickAddChip('Greek Yogurt (170g)', 17, 6, 1),
              _buildQuickAddChip('Banana', 1, 27, 0),
              _buildQuickAddChip('Oatmeal (1 cup)', 6, 27, 3),
              _buildQuickAddChip('Almonds (28g)', 6, 6, 14),
              _buildQuickAddChip('Avocado (half)', 1, 6, 11),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput({
    required String label,
    required TextEditingController controller,
    required Color color,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '0',
            suffixText: suffix,
            filled: true,
            fillColor: AppTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildQuickAddChip(String name, int protein, int carbs, int fat) {
    return ActionChip(
      label: Text(name),
      backgroundColor: AppTheme.card,
      side: BorderSide(color: AppTheme.border),
      onPressed: () {
        _foodNameController.text = name.split('(').first.trim();
        _proteinController.text = protein.toString();
        _carbsController.text = carbs.toString();
        _fatController.text = fat.toString();
        if (name.contains('(')) {
          _servingSizeController.text =
              name.substring(name.indexOf('(') + 1, name.indexOf(')'));
        }
        setState(() {});
      },
    );
  }

  bool _canSaveManualEntry() {
    return _foodNameController.text.isNotEmpty &&
        (_proteinController.text.isNotEmpty ||
            _carbsController.text.isNotEmpty ||
            _fatController.text.isNotEmpty);
  }

  Future<void> _saveManualEntry() async {
    setState(() => _isManualSaving = true);

    try {
      final protein = int.tryParse(_proteinController.text) ?? 0;
      final carbs = int.tryParse(_carbsController.text) ?? 0;
      final fat = int.tryParse(_fatController.text) ?? 0;
      final calories = _calculatedCalories;

      final foodName = _servingSizeController.text.isNotEmpty
          ? '${_foodNameController.text} (${_servingSizeController.text})'
          : _foodNameController.text;

      final mealNumber = widget.mealNumber ?? _selectedMealNumber;

      // Use the logging provider to save the manual entry
      final success = await ref.read(loggingStateProvider.notifier).saveManualFoodEntry(
        name: 'Meal $mealNumber - $foodName',
        protein: protein,
        carbs: carbs,
        fat: fat,
        calories: calories,
      );

      if (success && mounted) {
        // Refresh nutrition data
        ref.read(nutritionStateProvider.notifier).refreshDailySummary();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$foodName" to Meal $mealNumber'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save food entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSaving = false);
      }
    }
  }

  Widget _buildAIQuickEntry(LoggingState loggingState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI parsing coming soon. Use Manual entry for now.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Describe what you ate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use natural language to log your food. For example:\n"3 eggs, 200g chicken breast, and a cup of rice"',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aiInputController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter what you ate...',
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (loggingState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.destructive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loggingState.error!,
                      style: TextStyle(color: AppTheme.destructive),
                    ),
                  ),
                ],
              ),
            ),

          if (loggingState.parsedData != null) ...[
            const SizedBox(height: 16),
            _buildParsedPreview(loggingState),
          ],

          const Spacer(),

          // Action buttons
          if (loggingState.parsedData != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(loggingStateProvider.notifier).clearState();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loggingState.isSaving
                        ? null
                        : () async {
                            final success = await ref
                                .read(loggingStateProvider.notifier)
                                .confirmAndSave();
                            if (success && mounted) {
                              context.pop();
                            }
                          },
                    child: loggingState.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loggingState.isProcessing ||
                        _aiInputController.text.isEmpty
                    ? null
                    : () {
                        ref
                            .read(loggingStateProvider.notifier)
                            .parseInput(_aiInputController.text);
                      },
                child: loggingState.isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log Food'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParsedPreview(LoggingState state) {
    final nutrition = state.parsedData?.nutrition;
    if (nutrition == null) return const SizedBox.shrink();

    final meals = nutrition.meals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Parsed Successfully',
                style: TextStyle(
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meals.map((meal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: const TextStyle(color: AppTheme.foreground),
                    ),
                  ),
                  Text(
                    '${meal.calories.toInt()}cal | P:${meal.protein.toInt()} C:${meal.carbs.toInt()} F:${meal.fat.toInt()}',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFoodSearch() {
    final searchState = ref.watch(foodSearchProvider);
    final selectedFood = searchState.selectedFood;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchState.isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(foodSearchProvider.notifier).clearSearch();
                              },
                            )
                          : null,
                  filled: true,
                  fillColor: AppTheme.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                ),
                onChanged: (value) {
                  ref.read(foodSearchProvider.notifier).searchWithDebounce(value);
                },
                onSubmitted: (value) {
                  ref.read(foodSearchProvider.notifier).search(value);
                },
              ),

              // Error message
              if (searchState.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchState.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Results or empty state
        Expanded(
          child: selectedFood != null
              ? _buildSelectedFoodPreview(selectedFood)
              : searchState.results.isEmpty
                  ? _buildSearchEmptyState(searchState)
                  : _buildSearchResults(searchState.results),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState(FoodSearchState state) {
    if (state.query.isNotEmpty && !state.isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods found for "${state.query}"',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: AppTheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for foods to add',
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search our database of thousands of foods',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<FoodSearchResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final food = results[index];
        return _FoodSearchResultCard(
          food: food,
          onTap: () {
            ref.read(foodSearchProvider.notifier).selectFood(food);
          },
        );
      },
    );
  }

  Widget _buildSelectedFoodPreview(FoodSearchResult food) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () {
              ref.read(foodSearchProvider.notifier).clearSelection();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to results'),
          ),
          const SizedBox(height: 16),

          // Food details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (food.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    food.brand,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Serving: ${food.displayServingSize}',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Nutrition info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientColumn(
                      'Calories',
                      '${food.calories.toInt()}',
                      'cal',
                      Colors.orange,
                    ),
                    _buildNutrientColumn(
                      'Protein',
                      '${food.protein.toInt()}',
                      'g',
                      const Color(0xFFEC4899),
                    ),
                    _buildNutrientColumn(
                      'Carbs',
                      '${food.carbs.toInt()}',
                      'g',
                      const Color(0xFF22C55E),
                    ),
                    _buildNutrientColumn(
                      'Fat',
                      '${food.fat.toInt()}',
                      'g',
                      const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal selector
          Text(
            'Add to Meal',
            style: TextStyle(
              color: AppTheme.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: List.generate(4, (index) {
                final mealNum = index + 1;
                final isSelected = _selectedMealNumber == mealNum;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMealNumber = mealNum),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Meal $mealNum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.mutedForeground,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _addSearchedFood(food),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
              ),
              child: const Text(
                'Add Food',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _addSearchedFood(FoodSearchResult food) async {
    final mealNumber = widget.mealNumber ?? _selectedMealNumber;

    final success = await ref.read(loggingStateProvider.notifier).saveManualFoodEntry(
      name: 'Meal $mealNumber - ${food.displayName}',
      protein: food.protein.toInt(),
      carbs: food.carbs.toInt(),
      fat: food.fat.toInt(),
      calories: food.calories.toInt(),
    );

    if (success && mounted) {
      ref.read(nutritionStateProvider.notifier).refreshDailySummary();
      ref.read(foodSearchProvider.notifier).clearSearch();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${food.name}" to Meal $mealNumber'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add food'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _FoodSearchResultCard extends StatelessWidget {
  final FoodSearchResult food;
  final VoidCallback onTap;

  const _FoodSearchResultCard({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Food icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Food info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (food.brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        food.brand,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${food.calories.toInt()} cal | P:${food.protein.toInt()}g C:${food.carbs.toInt()}g F:${food.fat.toInt()}g',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

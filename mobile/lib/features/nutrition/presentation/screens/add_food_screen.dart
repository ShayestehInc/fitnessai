import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/achievement_toast_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_search_bar.dart';
import '../../../../shared/widgets/adaptive/adaptive_segmented_control.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../logging/presentation/providers/logging_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/food_search_provider.dart';
import '../../data/models/food_search_model.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.mealNumber != null
              ? 'Add to Meal ${widget.mealNumber}'
              : 'Add Food',
        ),
        bottom: theme.platform == TargetPlatform.iOS
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Manual'),
                  Tab(text: 'AI Entry'),
                  Tab(text: 'Search'),
                  Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scan'),
                ],
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.textTheme.bodySmall?.color,
              ),
      ),
      body: Column(
        children: [
          if (theme.platform == TargetPlatform.iOS)
            AdaptiveSegmentedControl(
              controller: _tabController,
              labels: const ['Manual', 'AI Entry', 'Search', 'Scan'],
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildManualEntry(theme),
                _buildAIQuickEntry(loggingState, theme),
                _buildFoodSearch(theme),
                _buildScanTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Barcode',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Point your camera at a food barcode to instantly look up nutrition info.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/barcode-scan'),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(context.l10n.nutritionOpenScanner),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry(ThemeData theme) {
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
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Meal selector (only show if not passed in)
          if (widget.mealNumber == null) ...[
            Text(
              'Meal',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
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
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Meal $mealNum',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color,
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
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foodNameController,
            decoration: InputDecoration(
              hintText: context.l10n.nutritionEGChickenBreast,
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Serving size (optional)
          Text(
            'Serving Size (optional)',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _servingSizeController,
            decoration: InputDecoration(
              hintText: context.l10n.nutritionEG150g1Cup,
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
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
                  label: context.l10n.nutritionProtein,
                  controller: _proteinController,
                  color: const Color(0xFFEC4899), // Pink
                  suffix: 'g',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput(
                  label: context.l10n.nutritionCarbs,
                  controller: _carbsController,
                  color: const Color(0xFF22C55E), // Green
                  suffix: 'g',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroInput(
                  label: context.l10n.nutritionFat,
                  controller: _fatController,
                  color: const Color(0xFF3B82F6), // Blue
                  suffix: 'g',
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calories display (calculated)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
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
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto-calculated from macros',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_calculatedCalories cal',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
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
                backgroundColor: theme.colorScheme.primary,
              ),
              child: _isManualSaving
                  ? const AdaptiveSpinner.small()
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
              _buildQuickAddChip('Chicken Breast (150g)', 46, 0, 5, theme),
              _buildQuickAddChip('Rice (1 cup)', 5, 45, 0, theme),
              _buildQuickAddChip('Eggs (2 large)', 12, 1, 10, theme),
              _buildQuickAddChip('Greek Yogurt (170g)', 17, 6, 1, theme),
              _buildQuickAddChip('Banana', 1, 27, 0, theme),
              _buildQuickAddChip('Oatmeal (1 cup)', 6, 27, 3, theme),
              _buildQuickAddChip('Almonds (28g)', 6, 6, 14, theme),
              _buildQuickAddChip('Avocado (half)', 1, 6, 11, theme),
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
    required ThemeData theme,
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
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
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

  Widget _buildQuickAddChip(String name, int protein, int carbs, int fat, ThemeData theme) {
    return ActionChip(
      label: Text(name),
      backgroundColor: theme.cardColor,
      side: BorderSide(color: theme.dividerColor),
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
        HapticService.success();
        // Refresh nutrition data
        ref.read(nutritionStateProvider.notifier).refreshDailySummary();

        showAdaptiveToast(
          context,
          message: context.l10n.nutritionAddedfoodNameToMealmealNumber,
          type: ToastType.success,
        );
        _showAchievementToastsFromLogging();
        context.pop();
      } else if (mounted) {
        showAdaptiveToast(
          context,
          message: context.l10n.nutritionFailedToSaveFoodEntry,
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSaving = false);
      }
    }
  }

  Widget _buildAIQuickEntry(LoggingState loggingState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe what you ate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use natural language to log your food. For example:\n"3 eggs, 200g chicken breast, and a cup of rice"',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Meal selector
          if (widget.mealNumber == null) ...[
            Text(
              'Meal',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: context.l10n.nutritionSelectMealNumber,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: List.generate(4, (index) {
                    final mealNum = index + 1;
                    final isSelected = _selectedMealNumber == mealNum;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: context.l10n.nutritionMealmealNum,
                        child: AdaptiveTappable(
                          onTap: () => setState(() => _selectedMealNumber = mealNum),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Meal $mealNum',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodySmall?.color,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _aiInputController,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.nutritionEG2ChickenBreasts1CupRice1Apple,
              helperText: context.l10n.nutritionIncludeQuantitiesAndMeasurementsForAccuracy,
              helperMaxLines: 2,
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          if (loggingState.error != null)
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loggingState.error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (loggingState.clarificationQuestion != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              label: context.l10n.nutritionClarificationNeeded,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loggingState.clarificationQuestion!,
                        style: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? Colors.amber[200]
                              : Colors.amber[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (loggingState.parsedData != null) ...[
            const SizedBox(height: 16),
            _buildParsedPreview(loggingState, theme),
          ],

          const SizedBox(height: 24),

          // Action buttons
          if (loggingState.parsedData != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loggingState.isSaving
                        ? null
                        : () {
                            ref.read(loggingStateProvider.notifier).clearState();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loggingState.isSaving
                        ? null
                        : () => _confirmAiEntry(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: loggingState.isSaving
                        ? const AdaptiveSpinner.small()
                        : const Text(
                            'Confirm & Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loggingState.isProcessing ||
                        _aiInputController.text.trim().isEmpty
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        ref
                            .read(loggingStateProvider.notifier)
                            .parseInput(_aiInputController.text);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                child: loggingState.isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AdaptiveSpinner.small(),
                          const SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Parse with AI',
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

  Future<void> _confirmAiEntry() async {
    final parsedData = ref.read(loggingStateProvider).parsedData;
    if (parsedData == null) return;

    // Check if AI actually parsed any food items
    if (parsedData.nutrition.meals.isEmpty) {
      if (!mounted) return;
      showAdaptiveToast(
        context,
        message: context.l10n.nutritionNoFoodItemsDetectedPleaseDescribeWhatYouAteWi,
        type: ToastType.warning,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final mealNumber = widget.mealNumber ?? _selectedMealNumber;
    final success = await ref
        .read(loggingStateProvider.notifier)
        .confirmAndSave(mealPrefix: 'Meal $mealNumber - ');

    if (success && mounted) {
      ref.read(nutritionStateProvider.notifier).refreshDailySummary();
      showAdaptiveToast(
        context,
        message: context.l10n.nutritionFoodLoggedSuccessfully,
        type: ToastType.success,
        duration: const Duration(seconds: 2),
      );
      _showAchievementToastsFromLogging();
      context.pop();
    } else if (mounted) {
      showAdaptiveToastWithAction(
        context,
        message: context.l10n.nutritionFailedToSaveFoodEntryPleaseCheckYourConnectio,
        type: ToastType.error,
        actionLabel: 'Retry',
        onAction: () => _confirmAiEntry(),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildParsedPreview(LoggingState state, ThemeData theme) {
    final nutrition = state.parsedData?.nutrition;
    if (nutrition == null) return const SizedBox.shrink();

    final meals = nutrition.meals;

    // Show error state if no meals were parsed
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No Food Items Detected',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please describe what you ate with specific quantities. For example:\n"2 eggs, 100g chicken breast, 1 cup of rice"',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final totalCalories = meals.fold<double>(0, (sum, meal) => sum + meal.calories);
    final totalProtein = meals.fold<double>(0, (sum, meal) => sum + meal.protein);
    final totalCarbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);

    return Semantics(
      liveRegion: true,
      label: 'Parsed ${meals.length} food items successfully',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Parsed Successfully',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...meals.map((meal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories.toInt()} cal • Protein ${meal.protein.toInt()}g • Carbs ${meal.carbs.toInt()}g • Fat ${meal.fat.toInt()}g',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (meals.length > 1) ...[
              Divider(color: theme.dividerColor, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${totalCalories.toInt()} cal • P ${totalProtein.toInt()}g • C ${totalCarbs.toInt()}g • F ${totalFat.toInt()}g',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodSearch(ThemeData theme) {
    final searchState = ref.watch(foodSearchProvider);
    final selectedFood = searchState.selectedFood;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search input
              AdaptiveSearchBar(
                controller: _searchController,
                placeholder: 'Search foods...',
                onChanged: (value) {
                  ref.read(foodSearchProvider.notifier).searchWithDebounce(value);
                },
                onSubmitted: (value) {
                  ref.read(foodSearchProvider.notifier).search(value);
                },
                onClear: () {
                  ref.read(foodSearchProvider.notifier).clearSearch();
                },
              ),

              // Error message
              if (searchState.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
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
              ? _buildSelectedFoodPreview(selectedFood, theme)
              : searchState.results.isEmpty
                  ? _buildSearchEmptyState(searchState, theme)
                  : _buildSearchResults(searchState.results, theme),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState(FoodSearchState state, ThemeData theme) {
    if (state.query.isNotEmpty && !state.isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods found for "${state.query}"',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
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
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for foods to add',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search our database of thousands of foods',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<FoodSearchResult> results, ThemeData theme) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final food = results[index];
        return _FoodSearchResultCard(
          food: food,
          theme: theme,
          onTap: () {
            ref.read(foodSearchProvider.notifier).selectFood(food);
          },
        );
      },
    );
  }

  Widget _buildSelectedFoodPreview(FoodSearchResult food, ThemeData theme) {
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
            icon: Icon(AdaptiveIcons.back),
            label: Text(context.l10n.nutritionBackToResults),
          ),
          const SizedBox(height: 16),

          // Food details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (food.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    food.brand,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Serving: ${food.displayServingSize}',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
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
                      theme,
                    ),
                    _buildNutrientColumn(
                      'Protein',
                      '${food.protein.toInt()}',
                      'g',
                      const Color(0xFFEC4899),
                      theme,
                    ),
                    _buildNutrientColumn(
                      'Carbs',
                      '${food.carbs.toInt()}',
                      'g',
                      const Color(0xFF22C55E),
                      theme,
                    ),
                    _buildNutrientColumn(
                      'Fat',
                      '${food.fat.toInt()}',
                      'g',
                      const Color(0xFF3B82F6),
                      theme,
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
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
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
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Meal $mealNum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
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
                backgroundColor: theme.colorScheme.primary,
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

  Widget _buildNutrientColumn(String label, String value, String unit, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
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

      showAdaptiveToast(
        context,
        message: 'Added "${food.name}" to Meal $mealNumber',
        type: ToastType.success,
      );
      _showAchievementToastsFromLogging();
      context.pop();
    } else if (mounted) {
      showAdaptiveToast(
        context,
        message: context.l10n.nutritionFailedToAddFood,
        type: ToastType.error,
      );
    }
  }

  void _showAchievementToastsFromLogging() {
    final loggingState = ref.read(loggingStateProvider);
    showAchievementToastsFromRaw(loggingState.newAchievements);
  }
}

class _FoodSearchResultCard extends StatelessWidget {
  final FoodSearchResult food;
  final ThemeData theme;
  final VoidCallback onTap;

  const _FoodSearchResultCard({
    required this.food,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(12),
        child: Row(
            children: [
              // Food icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: theme.colorScheme.primary,
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
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
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
                          color: theme.textTheme.bodySmall?.color,
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
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
      ),
    );
  }
}

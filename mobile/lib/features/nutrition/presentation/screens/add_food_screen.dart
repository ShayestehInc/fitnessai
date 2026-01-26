import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../logging/presentation/providers/logging_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiInputController.dispose();
    _searchController.dispose();
    super.dispose();
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
            Tab(text: 'AI Quick Entry'),
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
          _buildAIQuickEntry(loggingState),
          _buildFoodSearch(),
        ],
      ),
    );
  }

  Widget _buildAIQuickEntry(LoggingState loggingState) {
    return Padding(
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
            onSubmitted: (value) {
              // TODO: Implement food search
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: AppTheme.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for foods to add',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Food database search coming soon.\nUse AI Quick Entry for now.',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
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

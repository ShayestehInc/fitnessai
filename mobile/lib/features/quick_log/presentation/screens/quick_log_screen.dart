import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/quick_log_provider.dart';
import '../widgets/template_card.dart';

class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  static const List<String?> _categoryTabs = [
    null, // All
    'cardio',
    'sports',
    'outdoor',
    'flexibility',
    'other',
  ];

  static const List<String> _tabLabels = [
    'All',
    'Cardio',
    'Sports',
    'Outdoor',
    'Flexibility',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref.read(selectedCategoryProvider.notifier).state =
        _categoryTabs[_tabController.index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Quick Log'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          indicatorColor: theme.colorScheme.primary,
          dividerColor: Colors.transparent,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Template list (scrollable)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categoryTabs.map((category) {
                return _TemplateList(category: category);
              }).toList(),
            ),
          ),

          // Bottom form — visible only when a template is selected
          _QuickLogForm(
            caloriesController: _caloriesController,
            notesController: _notesController,
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final template = ref.read(selectedTemplateProvider);
    if (template == null) {
      showAdaptiveToast(
        context,
        message: 'Please select a workout template',
        type: ToastType.error,
      );
      return;
    }

    final duration = ref.read(quickLogDurationProvider);
    if (duration <= 0) {
      showAdaptiveToast(
        context,
        message: 'Duration must be greater than zero',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Sync notes text into provider before submit
    ref.read(quickLogNotesProvider.notifier).state = _notesController.text;

    // If user typed a manual calorie value, parse it
    final caloriesText = _caloriesController.text.trim();
    if (caloriesText.isNotEmpty) {
      final parsed = double.tryParse(caloriesText);
      if (parsed != null && parsed > 0) {
        ref.read(quickLogCaloriesOverrideProvider.notifier).state = parsed;
      }
    }

    final repository = ref.read(quickLogRepositoryProvider);
    final calories = ref.read(effectiveCaloriesProvider);
    final notes = ref.read(quickLogNotesProvider);

    final result = await repository.submitQuickLog(
      templateId: template.id,
      durationMinutes: duration,
      caloriesBurned: calories,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      showAdaptiveToast(
        context,
        message: 'Quick log saved!',
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      showAdaptiveToast(
        context,
        message: result['error']?.toString() ?? 'Failed to save quick log',
        type: ToastType.error,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Template list for a single tab
// ---------------------------------------------------------------------------

class _TemplateList extends ConsumerWidget {
  final String? category;

  const _TemplateList({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider(category));
    final selectedTemplate = ref.watch(selectedTemplateProvider);
    final theme = Theme.of(context);

    return templatesAsync.when(
      loading: () => const Center(child: AdaptiveSpinner()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load templates',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(workoutTemplatesProvider(category)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No templates available',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Templates for this category will appear here.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final template = templates[index];
            final isSelected = selectedTemplate?.id == template.id;
            return TemplateCard(
              template: template,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedTemplateProvider.notifier).state =
                    isSelected ? null : template;
                // Reset duration to template default when selecting a new template
                if (!isSelected) {
                  ref.read(quickLogDurationProvider.notifier).state =
                      template.estimatedDurationMinutes;
                  ref.read(quickLogCaloriesOverrideProvider.notifier).state =
                      null;
                }
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom form (duration, calories, notes, submit)
// ---------------------------------------------------------------------------

class _QuickLogForm extends ConsumerWidget {
  final TextEditingController caloriesController;
  final TextEditingController notesController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _QuickLogForm({
    required this.caloriesController,
    required this.notesController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemplate = ref.watch(selectedTemplateProvider);
    final theme = Theme.of(context);

    if (selectedTemplate == null) {
      return const SizedBox.shrink();
    }

    final duration = ref.watch(quickLogDurationProvider);
    final effectiveCals = ref.watch(effectiveCaloriesProvider);

    // Keep the calories text field in sync with auto-calculated value when no
    // manual override is set.
    final overrideValue = ref.watch(quickLogCaloriesOverrideProvider);
    if (overrideValue == null) {
      final newText = effectiveCals.toStringAsFixed(0);
      if (caloriesController.text != newText) {
        caloriesController.text = newText;
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration', style: theme.textTheme.titleSmall),
              Text(
                '$duration min',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: duration.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            label: '$duration min',
            activeColor: theme.colorScheme.primary,
            onChanged: (value) {
              ref.read(quickLogDurationProvider.notifier).state =
                  value.round();
              // Clear manual override so auto-calc kicks in
              ref.read(quickLogCaloriesOverrideProvider.notifier).state = null;
            },
          ),

          const SizedBox(height: 8),

          // Calories + notes row
          Row(
            children: [
              // Calories field
              Expanded(
                child: TextField(
                  controller: caloriesController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    suffixText: 'kcal',
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    ref
                        .read(quickLogCaloriesOverrideProvider.notifier)
                        .state = parsed;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Notes field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const AdaptiveSpinner.small()
                  : const Icon(Icons.check),
              label: Text(isSubmitting ? 'Saving...' : 'Log Activity'),
            ),
          ),
        ],
      ),
    );
  }
}

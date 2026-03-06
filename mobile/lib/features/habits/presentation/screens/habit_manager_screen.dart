import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/habit_model.dart';
import '../providers/habit_provider.dart';

/// Trainer-facing screen to create, edit, and delete habits for a trainee.
class HabitManagerScreen extends ConsumerStatefulWidget {
  final int traineeId;

  const HabitManagerScreen({super.key, required this.traineeId});

  @override
  ConsumerState<HabitManagerScreen> createState() =>
      _HabitManagerScreenState();
}

class _HabitManagerScreenState extends ConsumerState<HabitManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Manage Habits'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitForm(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error.toString()),
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState(theme);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(habitsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: habits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildHabitCard(theme, habits[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitCard(ThemeData theme, HabitModel habit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            _resolveIcon(habit.icon),
            size: 24,
            color: habit.isActive
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _frequencyLabel(habit.frequency, habit.customDays),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Active toggle
          Switch(
            value: habit.isActive,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) => _toggleActive(habit, value),
          ),
          // Edit
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: theme.textTheme.bodySmall?.color,
            ),
            onPressed: () => _showHabitForm(context, existing: habit),
          ),
          // Delete
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            onPressed: () => _confirmDelete(habit),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a habit for this trainee.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load habits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(habitsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(HabitModel habit, bool value) async {
    final repo = ref.read(habitRepositoryProvider);
    final result = await repo.updateHabit(
      habitId: habit.id,
      data: {'is_active': value},
    );
    if (result['success'] == true) {
      ref.invalidate(habitsProvider);
    } else if (mounted) {
      showAdaptiveToast(
        context,
        message: result['error'] as String? ?? 'Failed to update',
        type: ToastType.error,
      );
    }
  }

  Future<void> _confirmDelete(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(habitRepositoryProvider);
    final result = await repo.deleteHabit(habit.id);
    if (result['success'] == true) {
      HapticService.success();
      ref.invalidate(habitsProvider);
    } else if (mounted) {
      showAdaptiveToast(
        context,
        message: result['error'] as String? ?? 'Failed to delete',
        type: ToastType.error,
      );
    }
  }

  void _showHabitForm(BuildContext context, {HabitModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HabitFormSheet(
        traineeId: widget.traineeId,
        existing: existing,
        onSaved: () {
          ref.invalidate(habitsProvider);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  String _frequencyLabel(String frequency, List<String> customDays) {
    switch (frequency) {
      case 'daily':
        return 'Every day';
      case 'weekdays':
        return 'Weekdays only';
      case 'custom':
        if (customDays.isEmpty) return 'Custom';
        return customDays.map((d) => d.substring(0, 3)).join(', ');
      default:
        return frequency;
    }
  }
}

IconData _resolveIcon(String iconName) {
  const iconMap = <String, IconData>{
    'check_circle': Icons.check_circle_outline,
    'fitness_center': Icons.fitness_center,
    'local_drink': Icons.local_drink,
    'bedtime': Icons.bedtime,
    'self_improvement': Icons.self_improvement,
    'directions_run': Icons.directions_run,
    'restaurant': Icons.restaurant,
    'medication': Icons.medication,
    'book': Icons.book,
    'emoji_food_beverage': Icons.emoji_food_beverage,
  };
  return iconMap[iconName] ?? Icons.check_circle_outline;
}

// ---------------------------------------------------------------------------
// Habit creation / editing form as a bottom sheet
// ---------------------------------------------------------------------------

class _HabitFormSheet extends ConsumerStatefulWidget {
  final int traineeId;
  final HabitModel? existing;
  final VoidCallback onSaved;

  const _HabitFormSheet({
    required this.traineeId,
    this.existing,
    required this.onSaved,
  });

  @override
  ConsumerState<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<_HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _selectedIcon = 'check_circle';
  String _selectedFrequency = 'daily';
  final Set<String> _selectedDays = {};
  bool _isSaving = false;

  static const _availableIcons = [
    'check_circle',
    'fitness_center',
    'local_drink',
    'bedtime',
    'self_improvement',
    'directions_run',
    'restaurant',
    'medication',
    'book',
    'emoji_food_beverage',
  ];

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    if (existing != null) {
      _selectedIcon = existing.icon;
      _selectedFrequency = existing.frequency;
      _selectedDays.addAll(existing.customDays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isEditing ? 'Edit Habit' : 'New Habit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Drink 8 glasses of water',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of the habit',
                ),
              ),
              const SizedBox(height: 20),

              // Icon picker
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.15)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _resolveIcon(iconName),
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Frequency
              Text(
                'Frequency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                ],
                selected: {_selectedFrequency},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedFrequency = selection.first;
                  });
                },
              ),

              // Custom day selector
              if (_selectedFrequency == 'custom') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day.substring(0, 3)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                      selectedColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: theme.colorScheme.primary,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const AdaptiveSpinner.small()
                      : Text(isEditing ? 'Save Changes' : 'Create Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFrequency == 'custom' && _selectedDays.isEmpty) {
      showAdaptiveToast(
        context,
        message: 'Please select at least one day for custom frequency',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    final repo = ref.read(habitRepositoryProvider);
    final Map<String, dynamic> result;

    if (widget.existing != null) {
      result = await repo.updateHabit(
        habitId: widget.existing!.id,
        data: {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'icon': _selectedIcon,
          'frequency': _selectedFrequency,
          'custom_days': _selectedDays.toList(),
        },
      );
    } else {
      result = await repo.createHabit(
        traineeId: widget.traineeId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
        frequency: _selectedFrequency,
        customDays: _selectedDays.toList(),
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      HapticService.success();
      showAdaptiveToast(
        context,
        message: widget.existing != null
            ? 'Habit updated successfully'
            : 'Habit created successfully',
        type: ToastType.success,
      );
      widget.onSaved();
    } else {
      setState(() => _isSaving = false);
      showAdaptiveToast(
        context,
        message: result['error'] as String? ?? 'Failed to save habit',
        type: ToastType.error,
      );
    }
  }
}

import 'package:flutter/material.dart';
import '../../data/models/nutrition_models.dart';

/// Bottom sheet for editing or deleting a food entry.
/// Returns the edited [MealEntry] on save, or `null` on cancel.
/// Returns a special sentinel value via the [onDelete] callback.
class EditFoodEntrySheet extends StatefulWidget {
  final MealEntry entry;
  final VoidCallback onDelete;

  const EditFoodEntrySheet({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  State<EditFoodEntrySheet> createState() => _EditFoodEntrySheetState();
}

class _EditFoodEntrySheetState extends State<EditFoodEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _caloriesController;

  @override
  void initState() {
    super.initState();
    // Strip "Meal X - " prefix for display
    String displayName = widget.entry.name;
    final prefixMatch = RegExp(r'^Meal \d+ - ').firstMatch(displayName);
    if (prefixMatch != null) {
      displayName = displayName.substring(prefixMatch.end);
    }

    _nameController = TextEditingController(text: displayName);
    _proteinController = TextEditingController(
      text: widget.entry.protein.toString(),
    );
    _carbsController = TextEditingController(
      text: widget.entry.carbs.toString(),
    );
    _fatController = TextEditingController(
      text: widget.entry.fat.toString(),
    );
    _caloriesController = TextEditingController(
      text: widget.entry.calories.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final edited = MealEntry(
      name: _nameController.text.trim(),
      protein: int.tryParse(_proteinController.text) ?? 0,
      carbs: int.tryParse(_carbsController.text) ?? 0,
      fat: int.tryParse(_fatController.text) ?? 0,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      timestamp: widget.entry.timestamp,
    );

    Navigator.of(context).pop(edited);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this food entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // Close the sheet
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
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
              const SizedBox(height: 16),
              Text(
                'Edit Food Entry',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Food name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _proteinController,
                      label: 'Protein (g)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      controller: _carbsController,
                      label: 'Carbs (g)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _fatController,
                      label: 'Fat (g)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      controller: _caloriesController,
                      label: 'Calories',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Delete button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _handleDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete Entry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final fillColor = theme.brightness == Brightness.light
        ? const Color(0xFFF5F5F8)
        : theme.cardColor;

    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    final theme = Theme.of(context);
    final fillColor = theme.brightness == Brightness.light
        ? const Color(0xFFF5F5F8)
        : theme.cardColor;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final parsed = int.tryParse(value);
          if (parsed == null || parsed < 0) {
            return 'Must be 0 or more';
          }
        }
        return null;
      },
    );
  }
}

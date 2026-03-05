import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/checkin_provider.dart';

/// Trainer-facing screen for building a check-in form template.
class CheckInBuilderScreen extends ConsumerStatefulWidget {
  const CheckInBuilderScreen({super.key});

  @override
  ConsumerState<CheckInBuilderScreen> createState() =>
      _CheckInBuilderScreenState();
}

class _CheckInBuilderScreenState extends ConsumerState<CheckInBuilderScreen> {
  final _nameController = TextEditingController();
  String _frequency = 'weekly';
  final List<_EditableField> _fields = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add(_EditableField(
        id: 'field_${DateTime.now().millisecondsSinceEpoch}',
      ));
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].dispose();
      _fields.removeAt(index);
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
    });
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_fields.isEmpty) return false;
    for (final field in _fields) {
      if (field.labelController.text.trim().isEmpty) return false;
      if (field.type == 'multi_choice' && field.options.isEmpty) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      showAdaptiveToast(
        context,
        message: 'Please fill in the template name and all field labels',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    final fieldDefs = _fields.map((f) => {
          'id': f.id,
          'type': f.type,
          'label': f.labelController.text.trim(),
          'required': f.isRequired,
          if (f.type == 'multi_choice') 'options': f.options,
        }).toList();

    final data = {
      'name': _nameController.text.trim(),
      'frequency': _frequency,
      'fields': fieldDefs,
    };

    final repository = ref.read(checkinRepositoryProvider);
    final result = await repository.createTemplate(data);

    if (!mounted) return;

    if (result['success'] == true) {
      ref.invalidate(templatesProvider);
      showAdaptiveToast(
        context,
        message: 'Template created!',
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isSaving = false);
      showAdaptiveToast(
        context,
        message: result['error'] ?? 'Failed to save template',
        type: ToastType.error,
      );
    }
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
        title: const Text('Build Check-In Form'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: AdaptiveSpinner.small(),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template name
            Text('Template Name', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Weekly Progress Check-In',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Frequency selector
            Text('Frequency', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _FrequencySelector(
              value: _frequency,
              theme: theme,
              onChanged: (val) => setState(() => _frequency = val),
            ),
            const SizedBox(height: 24),

            // Fields section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fields', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Field'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_fields.isEmpty)
              _buildEmptyFieldsHint(theme)
            else
              _buildFieldsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFieldsHint(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 36,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 12),
          Text(
            'No fields yet',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Field" to start building your form',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList(ThemeData theme) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fields.length,
      onReorder: _reorderFields,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          elevation: 4,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final field = _fields[index];
        return _FieldEditorCard(
          key: ValueKey(field.id),
          field: field,
          index: index,
          theme: theme,
          onRemove: () => _removeField(index),
          onUpdate: () => setState(() {}),
        );
      },
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final String value;
  final ThemeData theme;
  final ValueChanged<String> onChanged;

  const _FrequencySelector({
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  static const _options = [
    ('weekly', 'Weekly'),
    ('biweekly', 'Biweekly'),
    ('monthly', 'Monthly'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((option) {
        final isSelected = value == option.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: option != _options.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: Text(
                option.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FieldEditorCard extends StatelessWidget {
  final _EditableField field;
  final int index;
  final ThemeData theme;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const _FieldEditorCard({
    super.key,
    required this.field,
    required this.index,
    required this.theme,
    required this.onRemove,
    required this.onUpdate,
  });

  static const _fieldTypes = [
    ('text', 'Text', Icons.text_fields),
    ('number', 'Number', Icons.looks_one),
    ('scale', 'Scale (1-10)', Icons.linear_scale),
    ('multi_choice', 'Multiple Choice', Icons.list),
    ('photo', 'Photo', Icons.camera_alt),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle and delete
          Row(
            children: [
              Icon(
                Icons.drag_handle,
                color: theme.textTheme.bodySmall?.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Field ${index + 1}',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Label input
          TextField(
            controller: field.labelController,
            decoration: InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. How are you feeling?',
              isDense: true,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            onChanged: (_) => onUpdate(),
          ),
          const SizedBox(height: 12),

          // Type selector
          DropdownButtonFormField<String>(
            initialValue: field.type,
            decoration: InputDecoration(
              labelText: 'Type',
              isDense: true,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            items: _fieldTypes.map((ft) {
              return DropdownMenuItem(
                value: ft.$1,
                child: Row(
                  children: [
                    Icon(ft.$3, size: 18),
                    const SizedBox(width: 8),
                    Text(ft.$2),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                field.type = val;
                onUpdate();
              }
            },
          ),
          const SizedBox(height: 12),

          // Required toggle
          Row(
            children: [
              const Text('Required'),
              const Spacer(),
              Switch.adaptive(
                value: field.isRequired,
                onChanged: (val) {
                  field.isRequired = val;
                  onUpdate();
                },
              ),
            ],
          ),

          // Options editor for multi_choice
          if (field.type == 'multi_choice') ...[
            const SizedBox(height: 8),
            _OptionsEditor(
              options: field.options,
              theme: theme,
              onAdd: (option) {
                field.options.add(option);
                onUpdate();
              },
              onRemove: (index) {
                field.options.removeAt(index);
                onUpdate();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionsEditor extends StatefulWidget {
  final List<String> options;
  final ThemeData theme;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _OptionsEditor({
    required this.options,
    required this.theme,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_OptionsEditor> createState() => _OptionsEditorState();
}

class _OptionsEditorState extends State<_OptionsEditor> {
  final _optionController = TextEditingController();

  @override
  void dispose() {
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _optionController.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _optionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: TextStyle(
            color: widget.theme.textTheme.bodySmall?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < widget.options.length; i++)
              Chip(
                label: Text(
                  widget.options[i],
                  style: const TextStyle(fontSize: 13),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => widget.onRemove(i),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _optionController,
                decoration: InputDecoration(
                  hintText: 'Add option...',
                  isDense: true,
                  filled: true,
                  fillColor: widget.theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.theme.dividerColor),
                  ),
                ),
                onSubmitted: (_) => _addOption(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addOption,
              icon: const Icon(Icons.add_circle),
              color: widget.theme.colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

/// Mutable holder for a field being edited in the builder.
class _EditableField {
  final String id;
  final TextEditingController labelController;
  String type;
  bool isRequired;
  final List<String> options;

  _EditableField({
    required this.id,
    String label = '',
    this.type = 'text',
    this.isRequired = false,
    List<String>? options,
  })  : labelController = TextEditingController(text: label),
        options = options ?? [];

  void dispose() {
    labelController.dispose();
  }
}

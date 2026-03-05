import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/checkin_models.dart';

/// Renders a single dynamic form field based on its [CheckInFieldDefinition] type.
///
/// Supported types: text, number, scale, multi_choice, photo.
class DynamicFieldWidget extends StatelessWidget {
  final CheckInFieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const DynamicFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (field.required)
                Text(
                  '*',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFieldInput(context, theme),
        ],
      ),
    );
  }

  Widget _buildFieldInput(BuildContext context, ThemeData theme) {
    switch (field.type) {
      case 'text':
        return _TextFieldInput(
          value: value as String? ?? '',
          onChanged: onChanged,
          theme: theme,
        );
      case 'number':
        return _NumberFieldInput(
          value: value,
          onChanged: onChanged,
          theme: theme,
        );
      case 'scale':
        return _ScaleFieldInput(
          value: (value as int?) ?? 5,
          onChanged: onChanged,
          theme: theme,
        );
      case 'multi_choice':
        return _MultiChoiceFieldInput(
          options: field.options,
          value: value as String?,
          onChanged: onChanged,
          theme: theme,
        );
      case 'photo':
        return _PhotoFieldInput(
          value: value as String?,
          onChanged: onChanged,
          theme: theme,
        );
      default:
        return _TextFieldInput(
          value: value as String? ?? '',
          onChanged: onChanged,
          theme: theme,
        );
    }
  }
}

class _TextFieldInput extends StatefulWidget {
  final String value;
  final ValueChanged<dynamic> onChanged;
  final ThemeData theme;

  const _TextFieldInput({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<_TextFieldInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 3,
      minLines: 1,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Enter your response...',
        filled: true,
        fillColor: widget.theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
      ),
    );
  }
}

class _NumberFieldInput extends StatefulWidget {
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final ThemeData theme;

  const _NumberFieldInput({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_NumberFieldInput> createState() => _NumberFieldInputState();
}

class _NumberFieldInputState extends State<_NumberFieldInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.value.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (text) {
        final parsed = double.tryParse(text);
        widget.onChanged(parsed);
      },
      decoration: InputDecoration(
        hintText: 'Enter a number...',
        filled: true,
        fillColor: widget.theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
      ),
    );
  }
}

class _ScaleFieldInput extends StatelessWidget {
  final int value;
  final ValueChanged<dynamic> onChanged;
  final ThemeData theme;

  const _ScaleFieldInput({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '10',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),
      ],
    );
  }
}

class _MultiChoiceFieldInput extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final ThemeData theme;

  const _MultiChoiceFieldInput({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = value == option;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoFieldInput extends StatelessWidget {
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final ThemeData theme;

  const _PhotoFieldInput({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      onChanged(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (value != null && value!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(value!),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => onChanged(null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 32,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add photo',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

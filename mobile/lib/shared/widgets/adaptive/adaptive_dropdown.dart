import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/l10n/l10n_extension.dart';

/// A platform-adaptive dropdown selector.
///
/// iOS: Tappable field that opens a [CupertinoPicker] in a modal popup.
/// Android: Standard [DropdownButtonFormField].
class AdaptiveDropdown<T> extends StatelessWidget {
  final T? value;
  final List<AdaptiveDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final InputDecoration? decoration;

  const AdaptiveDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.validator,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return _IOSDropdown<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        labelText: labelText,
        hintText: hintText,
        validator: validator,
        decoration: decoration,
      );
    }

    return DropdownButtonFormField<T>(
      value: value,
      decoration: decoration ??
          InputDecoration(
            labelText: labelText,
            hintText: hintText,
          ),
      validator: validator,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item.value,
                child: Text(item.label),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// An item in an [AdaptiveDropdown].
class AdaptiveDropdownItem<T> {
  final T value;
  final String label;

  const AdaptiveDropdownItem({
    required this.value,
    required this.label,
  });
}

class _IOSDropdown<T> extends StatelessWidget {
  final T? value;
  final List<AdaptiveDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final InputDecoration? decoration;

  const _IOSDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.validator,
    this.decoration,
  });

  String? get _selectedLabel {
    if (value == null) return null;
    for (final item in items) {
      if (item.value == value) return item.label;
    }
    return null;
  }

  int get _selectedIndex {
    if (value == null) return 0;
    for (int i = 0; i < items.length; i++) {
      if (items[i].value == value) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: InputDecorator(
                decoration: (decoration ??
                        InputDecoration(
                          labelText: labelText,
                          hintText: hintText,
                        ))
                    .copyWith(
                  errorText: state.errorText,
                  suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
                ),
                child: Text(
                  _selectedLabel ?? hintText ?? '',
                  style: _selectedLabel != null
                      ? Theme.of(context).textTheme.bodyLarge
                      : Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    HapticService.lightTap();
    int tempIndex = _selectedIndex;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(context.l10n.commonCancel),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: Text(context.l10n.commonDone),
                  onPressed: () {
                    HapticService.selectionTick();
                    onChanged(items[tempIndex].value);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController:
                    FixedExtentScrollController(initialItem: _selectedIndex),
                onSelectedItemChanged: (index) {
                  HapticService.selectionTick();
                  tempIndex = index;
                },
                children: items
                    .map((item) => Center(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

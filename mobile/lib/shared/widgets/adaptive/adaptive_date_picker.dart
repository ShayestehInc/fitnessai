import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-adaptive date picker.
///
/// iOS: [CupertinoDatePicker] inside [showCupertinoModalPopup].
/// Android: [showDatePicker] (Material).
///
/// Returns the selected [DateTime] or `null` if dismissed.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  if (isIOS) {
    return _showCupertinoDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

Future<DateTime?> _showCupertinoDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  DateTime selected = initialDate;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Container(
      height: 300,
      color: CupertinoTheme.of(ctx).barBackgroundColor,
      child: Column(
        children: [
          // Toolbar with Cancel / Done
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Picker
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (date) => selected = date,
            ),
          ),
        ],
      ),
    ),
  );
}

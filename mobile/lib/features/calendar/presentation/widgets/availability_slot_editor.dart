import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/calendar_connection_model.dart';
import 'time_tile.dart';

/// Bottom sheet for creating or editing an availability slot.
class AvailabilitySlotEditor extends StatefulWidget {
  final int? initialDay;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  final void Function(int dayOfWeek, String startTime, String endTime) onSave;

  const AvailabilitySlotEditor({
    super.key,
    this.initialDay,
    this.initialStart,
    this.initialEnd,
    required this.onSave,
  });

  @override
  State<AvailabilitySlotEditor> createState() => _AvailabilitySlotEditorState();
}

class _AvailabilitySlotEditorState extends State<AvailabilitySlotEditor> {
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;

  // Use shared calendarDayNames from calendar_connection_model.dart

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay ?? 0;
    _start = widget.initialStart ?? const TimeOfDay(hour: 9, minute: 0);
    _end = widget.initialEnd ?? const TimeOfDay(hour: 17, minute: 0);
  }

  Future<void> _pickTime(bool isStart) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final initial = isStart ? _start : _end;

    if (isIOS) {
      TimeOfDay picked = initial;
      await showCupertinoModalPopup<void>(
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
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() {
                        if (isStart) {
                          _start = picked;
                        } else {
                          _end = picked;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
                  onDateTimeChanged: (dt) {
                    picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
      );
      if (picked != null) {
        setState(() {
          if (isStart) {
            _start = picked;
          } else {
            _end = picked;
          }
        });
      }
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatTimeDisplay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${t.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialDay != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle for discoverability
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Availability' : 'Add Availability',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Day picker
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(
              labelText: 'Day of Week',
              border: OutlineInputBorder(),
            ),
            items: List.generate(7, (i) => DropdownMenuItem(
              value: i,
              child: Text(calendarDayNames[i]),
            )),
            onChanged: (v) {
              if (v != null) setState(() => _day = v);
            },
          ),
          const SizedBox(height: 16),
          // Time pickers
          Row(
            children: [
              Expanded(
                child: TimeTile(
                  label: 'Start',
                  value: _formatTimeDisplay(_start),
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeTile(
                  label: 'End',
                  value: _formatTimeDisplay(_end),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final startMinutes = _start.hour * 60 + _start.minute;
              final endMinutes = _end.hour * 60 + _end.minute;
              if (endMinutes <= startMinutes) {
                showAdaptiveToast(context,
                    message: 'End time must be after start time',
                    type: ToastType.error);
                return;
              }
              widget.onSave(_day, _formatTime(_start), _formatTime(_end));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';

class RsvpButton extends StatelessWidget {
  final String? currentRsvp;
  final bool isAtCapacity;
  final bool disabled;
  final ValueChanged<RsvpStatus> onChanged;

  const RsvpButton({
    super.key,
    required this.currentRsvp,
    required this.isAtCapacity,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = RsvpStatus.fromApi(currentRsvp);

    return Semantics(
      label: 'RSVP status: ${current?.label ?? "Not responded"}',
      child: SegmentedButton<RsvpStatus>(
        segments: [
          ButtonSegment(
            value: RsvpStatus.going,
            label: const Text('Going'),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            enabled: !disabled && (!isAtCapacity || current == RsvpStatus.going),
          ),
          ButtonSegment(
            value: RsvpStatus.maybe,
            label: const Text('Interested'),
            icon: const Icon(Icons.star_outline, size: 16),
            enabled: !disabled,
          ),
          ButtonSegment(
            value: RsvpStatus.notGoing,
            label: const Text('Can\'t Go'),
            icon: const Icon(Icons.close, size: 16),
            enabled: !disabled,
          ),
        ],
        selected: current != null ? {current} : {},
        onSelectionChanged: disabled
            ? null
            : (selected) {
                if (selected.isNotEmpty) {
                  onChanged(selected.first);
                }
              },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        showSelectedIcon: false,
        emptySelectionAllowed: true,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive tab switcher that works with an existing [TabController].
///
/// iOS: [CupertinoSlidingSegmentedControl] synced with [controller].
/// Android: Standard [TabBar] suitable for [AppBar.bottom].
///
/// On iOS this widget is intended to be placed in the body (not [AppBar.bottom]).
/// Wrap in `Padding` for spacing.
class AdaptiveSegmentedControl extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const AdaptiveSegmentedControl({
    super.key,
    required this.controller,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return _CupertinoSegment(controller: controller, labels: labels);
    }

    return TabBar(
      controller: controller,
      tabs: labels.map((l) => Tab(text: l)).toList(),
    );
  }
}

/// Cupertino segmented control that stays in sync with a [TabController].
class _CupertinoSegment extends StatefulWidget {
  final TabController controller;
  final List<String> labels;

  const _CupertinoSegment({required this.controller, required this.labels});

  @override
  State<_CupertinoSegment> createState() => _CupertinoSegmentState();
}

class _CupertinoSegmentState extends State<_CupertinoSegment> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.controller.index;
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _CupertinoSegment old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
      _index = widget.controller.index;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted && widget.controller.index != _index) {
      setState(() => _index = widget.controller.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _index,
          backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
          thumbColor: theme.cardColor,
          children: {
            for (int i = 0; i < widget.labels.length; i++)
              i: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  widget.labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _index == i
                        ? theme.textTheme.bodyLarge?.color
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
          },
          onValueChanged: (value) {
            if (value != null) {
              widget.controller.animateTo(value);
            }
          },
        ),
      ),
    );
  }
}

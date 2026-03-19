import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Collapsible "Why this choice?" panel used in both Quick Build and Advanced Builder.
class WhyPanel extends StatefulWidget {
  final String stepName;
  final String why;
  final bool initiallyExpanded;

  const WhyPanel({
    super.key,
    required this.stepName,
    required this.why,
    this.initiallyExpanded = false,
  });

  @override
  State<WhyPanel> createState() => _WhyPanelState();
}

class _WhyPanelState extends State<WhyPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  String get _displayName {
    switch (widget.stepName) {
      case 'length':
        return 'Program Length';
      case 'split':
        return 'Split Selection';
      case 'skeleton':
        return 'Weekly Layout';
      case 'roles':
        return 'Slot Roles';
      case 'structures':
        return 'Set Structures';
      case 'exercises':
        return 'Exercise Selection';
      case 'swaps':
        return 'Swap Options';
      case 'progression':
        return 'Progression';
      default:
        return widget.stepName
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.zinc800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppTheme.mutedForeground,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.why,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.zinc400,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A panel showing alternatives the user can pick from.
class AlternativesPanel extends StatelessWidget {
  final List<Map<String, dynamic>> alternatives;
  final void Function(Map<String, dynamic> selected)? onSelect;

  const AlternativesPanel({
    super.key,
    required this.alternatives,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alternatives',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        ...alternatives.map((alt) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: onSelect != null ? () => onSelect!(alt) : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alt['name']?.toString() ??
                                  alt['label']?.toString() ??
                                  alt['profile']?.toString() ??
                                  'Option',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.foreground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (alt['description'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                alt['description'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.zinc400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onSelect != null)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppTheme.mutedForeground,
                        ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

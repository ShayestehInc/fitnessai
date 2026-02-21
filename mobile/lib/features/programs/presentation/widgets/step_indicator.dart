import 'package:flutter/material.dart';

/// A horizontal step indicator showing numbered circles connected by lines.
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBefore = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepBefore < currentStep
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            );
          }

          final step = index ~/ 2;
          final isActive = step == currentStep;
          final isCompleted = step < currentStep;

          final statusLabel = isCompleted
              ? '${labels[step]}, completed'
              : isActive
                  ? '${labels[step]}, current step'
                  : '${labels[step]}, upcoming';

          return Semantics(
            label: 'Step ${step + 1} of $totalSteps: $statusLabel',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[step],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive || isCompleted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

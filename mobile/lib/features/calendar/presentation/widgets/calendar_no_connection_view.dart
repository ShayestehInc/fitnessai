import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';

/// Shown when the user navigates to events but has no calendar connected.
class CalendarNoConnectionView extends StatelessWidget {
  final VoidCallback onGoBack;

  const CalendarNoConnectionView({super.key, required this.onGoBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Events'),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: onGoBack,
          tooltip: 'Go back',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  semanticLabel: 'Calendar not connected'),
              const SizedBox(height: 16),
              Text(
                'No calendar connected',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect your Google or Microsoft calendar to see your events here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onGoBack,
                icon: const Icon(Icons.link),
                label: const Text('Connect a Calendar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

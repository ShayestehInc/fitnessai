import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.arrow_back),
          onPressed: onGoBack,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Connect a calendar first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGoBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to Calendar Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Shows a Material bottom sheet explaining why the app needs health data access.
///
/// Returns `true` if the user tapped "Connect Health",
/// `false` if they tapped "Not Now" or dismissed the sheet.
Future<bool> showHealthPermissionSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isDismissible: true,
    builder: (ctx) => const _HealthPermissionSheetContent(),
  );
  return result ?? false;
}

class _HealthPermissionSheetContent extends StatelessWidget {
  const _HealthPermissionSheetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final platformName = isIOS ? 'Apple Health' : 'Health Connect';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Health icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Connect Your Health Data',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'FitnessAI can read your steps, calories burned, heart rate, and '
              'weight from $platformName to give you a complete picture of your '
              'daily activity.',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Connect button (primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Connect Health',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Not Now button (text)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

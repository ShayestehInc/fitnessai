import 'package:flutter/material.dart';

/// A full-page confirmation screen for destructive or important actions.
///
/// Use this instead of AlertDialog for confirmations like:
/// - Delete account
/// - Cancel subscription
/// - Remove items
/// - End program
class ConfirmationPage extends StatelessWidget {
  final String title;
  final String message;
  final String? warningText;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;
  final bool isLoading;
  final Widget? additionalContent;

  const ConfirmationPage({
    super.key,
    required this.title,
    required this.message,
    this.warningText,
    this.confirmButtonText = 'Confirm',
    this.cancelButtonText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = true,
    this.icon,
    this.isLoading = false,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destructiveColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (isDestructive ? destructiveColor : theme.colorScheme.primary)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon ?? (isDestructive ? Icons.warning_rounded : Icons.help_outline_rounded),
                          size: 40,
                          color: isDestructive ? destructiveColor : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Message
                      Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Warning text
                      if (warningText != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  warningText!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Additional content
                      if (additionalContent != null) ...[
                        const SizedBox(height: 24),
                        additionalContent!,
                      ],
                    ],
                  ),
                ),
              ),
              // Buttons
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              onCancel?.call();
                              Navigator.of(context).pop(false);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(cancelButtonText),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? destructiveColor : null,
                        foregroundColor: isDestructive ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDestructive ? Colors.white : null,
                              ),
                            )
                          : Text(confirmButtonText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a confirmation page and returns true if confirmed, false otherwise.
Future<bool> showConfirmationPage(
  BuildContext context, {
  required String title,
  required String message,
  String? warningText,
  String confirmButtonText = 'Confirm',
  String cancelButtonText = 'Cancel',
  bool isDestructive = true,
  IconData? icon,
  Widget? additionalContent,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => ConfirmationPage(
        title: title,
        message: message,
        warningText: warningText,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        isDestructive: isDestructive,
        icon: icon,
        additionalContent: additionalContent,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    ),
  );
  return result ?? false;
}

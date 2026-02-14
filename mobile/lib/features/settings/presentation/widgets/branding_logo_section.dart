import 'package:flutter/material.dart';
import '../../../../shared/widgets/animated_widgets.dart';

/// Logo upload/preview section for the branding screen.
class BrandingLogoSection extends StatelessWidget {
  final String? logoUrl;
  final bool isUploading;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  const BrandingLogoSection({
    super.key,
    this.logoUrl,
    required this.isUploading,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return StaggeredListItem(
      index: 2,
      delay: const Duration(milliseconds: 30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            if (isUploading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (hasLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  logoUrl!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: onPickLogo,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Replace'),
                  ),
                  TextButton.icon(
                    onPressed: onRemoveLogo,
                    icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                    label: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ] else ...[
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your logo',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
              Text(
                'JPEG, PNG, or WebP. Max 2MB. 128-1024px.',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onPickLogo,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Choose Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

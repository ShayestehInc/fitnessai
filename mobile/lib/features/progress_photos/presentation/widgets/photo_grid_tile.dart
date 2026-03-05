import 'package:flutter/material.dart';

import '../../data/models/progress_photo_model.dart';

/// A grid tile displaying a progress photo thumbnail with a date overlay
/// and category badge.
class PhotoGridTile extends StatelessWidget {
  final ProgressPhotoModel photo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PhotoGridTile({
    super.key,
    required this.photo,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo image
            if (photo.photoUrl != null && photo.photoUrl!.isNotEmpty)
              Image.network(
                photo.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(theme),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildLoadingPlaceholder(theme, progress);
                },
              )
            else
              _buildPlaceholder(theme),

            // Gradient overlay at bottom for text legibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xCC000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Date overlay
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                photo.date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Category badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor(photo.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  photo.categoryLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Measurements indicator
            if (photo.hasMeasurements)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.straighten,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 40,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(
    ThemeData theme,
    ImageChunkEvent progress,
  ) {
    final expected = progress.expectedTotalBytes;
    final loaded = progress.cumulativeBytesLoaded;
    final value = expected != null ? loaded / expected : null;

    return Container(
      color: theme.cardColor,
      child: Center(
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'front':
        return const Color(0xFF4CAF50);
      case 'side':
        return const Color(0xFF2196F3);
      case 'back':
        return const Color(0xFFFF9800);
      case 'other':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF757575);
    }
  }
}

import 'package:flutter/material.dart';

import '../../data/models/progress_photo_model.dart';

/// Dialog showing a full-size progress photo with metadata and measurements.
class PhotoDetailDialog extends StatelessWidget {
  final ProgressPhotoModel photo;

  const PhotoDetailDialog({
    super.key,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: photo.photoUrl != null
                  ? Image.network(
                      photo.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        color: theme.cardColor,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: theme.cardColor,
                      child: const Center(
                        child: Icon(Icons.photo_outlined, size: 48),
                      ),
                    ),
            ),
          ),
          _InfoSection(photo: photo),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ProgressPhotoModel photo;

  const _InfoSection({required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                photo.date,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  photo.categoryLabel,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (photo.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(photo.notes, style: theme.textTheme.bodyMedium),
          ],
          if (photo.hasMeasurements) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Measurements', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: photo.measurements.entries.map((entry) {
                final label = entry.key.isNotEmpty
                    ? '${entry.key[0].toUpperCase()}${entry.key.substring(1)}'
                    : entry.key;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.value} cm',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(label, style: theme.textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

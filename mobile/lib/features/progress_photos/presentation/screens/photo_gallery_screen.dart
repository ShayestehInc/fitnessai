import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/progress_photo_model.dart';
import '../providers/progress_photo_provider.dart';
import '../widgets/photo_grid_tile.dart';

/// Gallery screen showing progress photos in a grid, grouped by date.
///
/// Provides category filter tabs (All, Front, Side, Back) and a FAB to add
/// new photos.
class PhotoGalleryScreen extends ConsumerWidget {
  const PhotoGalleryScreen({super.key});

  static const List<_CategoryTab> _categories = [
    _CategoryTab(label: 'All', value: 'all'),
    _CategoryTab(label: 'All', value: 'all'),
    _CategoryTab(label: 'All', value: 'all'),
    _CategoryTab(label: 'All', value: 'all'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final photosAsync = ref.watch(photosProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Progress Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare Photos',
            onPressed: () => context.push('/progress-photos/compare'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter tabs
          _CategoryFilterBar(
            categories: _categories,
            selected: selectedCategory,
            onSelected: (value) {
              ref.read(selectedCategoryProvider.notifier).state = value;
            },
          ),

          // Photo grid
          Expanded(
            child: photosAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _buildErrorState(context, theme, error, ref),
              data: (photos) {
                if (photos.isEmpty) {
                  return _buildEmptyState(context, theme);
                }
                return _buildPhotoGrid(context, theme, photos, ref);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/progress-photos/add'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Photo'),
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    ThemeData theme,
    List<ProgressPhotoModel> photos,
    WidgetRef ref,
  ) {
    // Group photos by date.
    final grouped = <String, List<ProgressPhotoModel>>{};
    for (final photo in photos) {
      grouped.putIfAbsent(photo.date, () => []).add(photo);
    }

    // Sort dates descending (newest first).
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(photosProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final datePhotos = grouped[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  date,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: datePhotos.length,
                itemBuilder: (context, photoIndex) {
                  final photo = datePhotos[photoIndex];
                  return PhotoGridTile(
                    photo: photo,
                    onTap: () => _showPhotoDetail(context, photo, ref),
                    onLongPress: () =>
                        _confirmDelete(context, photo, ref),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No progress photos yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Take your first photo to start tracking your transformation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    Object error,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load photos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(photosProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(
    BuildContext context,
    ProgressPhotoModel photo,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PhotoDetailDialog(photo: photo, ref: ref),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProgressPhotoModel photo,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text(
          'Are you sure you want to delete this progress photo? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(deletePhotoProvider.notifier).delete(photo.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PhotoDetailDialog extends StatelessWidget {
  final ProgressPhotoModel photo;
  final WidgetRef ref;

  const _PhotoDetailDialog({
    required this.photo,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.cardColor,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
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

          // Info section
          Padding(
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
                  Text(
                    photo.notes,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                if (photo.hasMeasurements) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Measurements',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: photo.measurements.entries.map((entry) {
                      return _MeasurementChip(
                        label: entry.key,
                        value: '${entry.value} cm',
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
          ),
        ],
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Capitalize first letter.
    final displayLabel =
        label.isNotEmpty ? '${label[0].toUpperCase()}${label.substring(1)}' : label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          displayLabel,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CategoryTab {
  final String label;
  final String value;

  const _CategoryTab({required this.label, required this.value});
}

class _CategoryFilterBar extends StatelessWidget {
  final List<_CategoryTab> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.label),
              selected: isSelected,
              onSelected: (_) => onSelected(cat.value),
              backgroundColor: theme.cardColor,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

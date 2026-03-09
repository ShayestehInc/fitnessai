import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/progress_photo_model.dart';
import '../providers/progress_photo_provider.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/photo_detail_dialog.dart';
import '../widgets/photo_grid_tile.dart';

/// Gallery screen showing progress photos in a grid, grouped by date.
///
/// When [traineeId] is provided, shows that trainee's photos in read-only
/// mode (trainer view) — no FAB, no delete.
class PhotoGalleryScreen extends ConsumerWidget {
  final int? traineeId;
  final String? traineeName;

  const PhotoGalleryScreen({
    super.key,
    this.traineeId,
    this.traineeName,
  });

  bool get _isTrainerView => traineeId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final photosAsync = ref.watch(photosProvider(traineeId));

    final title = _isTrainerView && traineeName != null
        ? "$traineeName's Photos"
        : 'Progress Photos';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare Photos',
            onPressed: () {
              final uri = traineeId != null
                  ? '/progress-photos/compare?trainee_id=$traineeId'
                  : '/progress-photos/compare';
              context.push(uri);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryFilterBar(
            categories: CategoryFilterBar.defaultCategories,
            selected: selectedCategory,
            onSelected: (value) {
              ref.read(selectedCategoryProvider.notifier).state = value;
            },
          ),
          Expanded(
            child: photosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                onRetry: () => ref.invalidate(photosProvider(traineeId)),
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return _EmptyView(isTrainerView: _isTrainerView);
                }
                return _PhotoGridBody(
                  photos: photos,
                  isTrainerView: _isTrainerView,
                  traineeId: traineeId,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isTrainerView
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/progress-photos/add'),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photo'),
            ),
    );
  }
}

class _PhotoGridBody extends ConsumerWidget {
  final List<ProgressPhotoModel> photos;
  final bool isTrainerView;
  final int? traineeId;

  const _PhotoGridBody({
    required this.photos,
    required this.isTrainerView,
    required this.traineeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final grouped = <String, List<ProgressPhotoModel>>{};
    for (final photo in photos) {
      grouped.putIfAbsent(photo.date, () => []).add(photo);
    }
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(photosProvider(traineeId)),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final datePhotos = grouped[date]!;
          return _DateGroup(
            date: date,
            photos: datePhotos,
            isTrainerView: isTrainerView,
            traineeId: traineeId,
          );
        },
      ),
    );
  }
}

class _DateGroup extends ConsumerWidget {
  final String date;
  final List<ProgressPhotoModel> photos;
  final bool isTrainerView;
  final int? traineeId;

  const _DateGroup({
    required this.date,
    required this.photos,
    required this.isTrainerView,
    required this.traineeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          itemCount: photos.length,
          itemBuilder: (context, photoIndex) {
            final photo = photos[photoIndex];
            return PhotoGridTile(
              photo: photo,
              onTap: () => showDialog(
                context: context,
                builder: (_) => PhotoDetailDialog(photo: photo),
              ),
              onLongPress: isTrainerView
                  ? null
                  : () => _confirmDelete(context, photo, ref),
            );
          },
        ),
      ],
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
              ref
                  .read(deletePhotoProvider(traineeId).notifier)
                  .delete(photo.id);
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

class _EmptyView extends StatelessWidget {
  final bool isTrainerView;

  const _EmptyView({required this.isTrainerView});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              isTrainerView
                  ? 'This trainee hasn\'t uploaded any progress photos.'
                  : 'Start tracking your transformation by taking your first photo.',
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
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/progress_photo_model.dart';
import '../providers/progress_photo_provider.dart';
import '../widgets/comparison_slider.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Screen that lets the user select two progress photos and compare them
/// side-by-side with a slider overlay and measurement diffs.
///
/// Accepts an optional [traineeId] for trainer view (read-only comparison
/// of a specific trainee's photos).
class ComparisonScreen extends ConsumerStatefulWidget {
  final int? traineeId;

  const ComparisonScreen({super.key, this.traineeId});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  ProgressPhotoModel? _photo1;
  ProgressPhotoModel? _photo2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photosAsync = ref.watch(photosProvider(widget.traineeId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.photosComparePhotos),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(context.l10n.photosFailedToLoadPhotos,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(), style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(photosProvider(widget.traineeId)),
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (photos) {
          if (photos.length < 2) {
            return _buildNeedMorePhotos(theme);
          }
          return _buildComparisonBody(context, theme, photos);
        },
      ),
    );
  }

  Widget _buildNeedMorePhotos(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'Need at least 2 photos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more progress photos to start comparing your transformation.',
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

  Widget _buildComparisonBody(
    BuildContext context,
    ThemeData theme,
    List<ProgressPhotoModel> photos,
  ) {
    return Column(
      children: [
        // Photo selection row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _PhotoSlot(
                  label: context.l10n.photosBefore,
                  photo: _photo1,
                  onTap: () => _selectPhoto(context, photos, isFirstSlot: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PhotoSlot(
                  label: context.l10n.photosAfter,
                  photo: _photo2,
                  onTap: () =>
                      _selectPhoto(context, photos, isFirstSlot: false),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Comparison slider
        if (_photo1 != null && _photo2 != null) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ComparisonSlider(
                  beforeUrl: _photo1!.photoUrl,
                  afterUrl: _photo2!.photoUrl,
                  beforeLabel: _photo1!.date,
                  afterLabel: _photo2!.date,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Measurement diff
          if (_photo1!.hasMeasurements || _photo2!.hasMeasurements)
            _buildMeasurementDiff(theme),

          const SizedBox(height: 16),
        ] else
          Expanded(
            child: Center(
              child: Text(
                'Select two photos above to compare',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeasurementDiff(ThemeData theme) {
    final keys = <String>{
      ..._photo1?.measurements.keys ?? <String>[],
      ..._photo2?.measurements.keys ?? <String>[],
    };

    if (keys.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Changes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...keys.map((key) {
              final val1 = _photo1?.getMeasurement(key);
              final val2 = _photo2?.getMeasurement(key);
              final diff = (val1 != null && val2 != null) ? val2 - val1 : null;

              final label = key.isNotEmpty
                  ? '${key[0].toUpperCase()}${key.substring(1)}'
                  : key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Row(
                      children: [
                        if (val1 != null)
                          Text(
                            '${val1.toStringAsFixed(1)} cm',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (val1 != null && val2 != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 14),
                          ),
                        if (val2 != null)
                          Text(
                            '${val2.toStringAsFixed(1)} cm',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (diff != null) ...[
                          const SizedBox(width: 8),
                          _DiffBadge(diff: diff),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _selectPhoto(
    BuildContext context,
    List<ProgressPhotoModel> photos, {
    required bool isFirstSlot,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _PhotoPickerSheet(
            photos: photos,
            scrollController: scrollController,
            onSelect: (photo) {
              setState(() {
                if (isFirstSlot) {
                  _photo1 = photo;
                } else {
                  _photo2 = photo;
                }
              });
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final ProgressPhotoModel? photo;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.label,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: photo != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (photo!.photoUrl != null)
                    Image.network(
                      photo!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(theme, label),
                    )
                  else
                    _buildPlaceholder(theme, label),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        photo!.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _buildPlaceholder(theme, label),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 4),
          Text(
            'Select $text',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPickerSheet extends StatelessWidget {
  final List<ProgressPhotoModel> photos;
  final ScrollController scrollController;
  final ValueChanged<ProgressPhotoModel> onSelect;

  const _PhotoPickerSheet({
    required this.photos,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a Photo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => onSelect(photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photo.photoUrl != null)
                        Image.network(
                          photo.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: theme.cardColor,
                            child: const Center(
                              child: Icon(Icons.photo_outlined, size: 24),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: theme.cardColor,
                          child: const Center(
                            child: Icon(Icons.photo_outlined, size: 24),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.black54,
                          child: Text(
                            photo.date,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final double diff;

  const _DiffBadge({required this.diff});

  @override
  Widget build(BuildContext context) {
    final isPositive = diff > 0;
    final isZero = diff.abs() < 0.05;
    final color = isZero
        ? Colors.grey
        : isPositive
            ? Colors.orange
            : Colors.green;
    final prefix = isZero
        ? ''
        : isPositive
            ? '+'
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$prefix${diff.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

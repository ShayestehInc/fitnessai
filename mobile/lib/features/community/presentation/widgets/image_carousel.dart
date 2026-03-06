import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_route.dart';
import '../../data/models/community_post_model.dart';

/// Multi-image PageView carousel with dots indicator.
class ImageCarousel extends StatefulWidget {
  final List<PostImageModel> images;

  const ImageCarousel({super.key, required this.images});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    if (widget.images.length == 1) {
      return _SingleImage(imageUrl: widget.images.first.url);
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _CarouselImage(imageUrl: widget.images[index].url);
            },
          ),
        ),
        const SizedBox(height: 8),
        _DotsIndicator(
          count: widget.images.length,
          current: _currentPage,
        ),
      ],
    );
  }
}

class _SingleImage extends StatelessWidget {
  final String imageUrl;

  const _SingleImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: AdaptiveSpinner()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 32),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CarouselImage extends StatelessWidget {
  final String imageUrl;

  const _CarouselImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                color: Theme.of(context).dividerColor,
                child: const Center(child: AdaptiveSpinner()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 250,
                color: Theme.of(context).dividerColor,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 32),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        );
      }),
    );
  }
}

void _showFullImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    adaptivePageRoute(
      builder: (_) => _FullImageScreen(imageUrl: imageUrl),
    ),
  );
}

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const _FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: AdaptiveSpinner());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.white54),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

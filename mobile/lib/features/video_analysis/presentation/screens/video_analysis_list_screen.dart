import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../providers/video_analysis_provider.dart';
import '../widgets/video_analysis_card.dart';

/// Screen displaying a list of video analyses with pull-to-refresh and upload FAB.
class VideoAnalysisListScreen extends ConsumerStatefulWidget {
  const VideoAnalysisListScreen({super.key});

  @override
  ConsumerState<VideoAnalysisListScreen> createState() =>
      _VideoAnalysisListScreenState();
}

class _VideoAnalysisListScreenState
    extends ConsumerState<VideoAnalysisListScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(videoAnalysisListProvider);
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile == null) return;
    if (!mounted) return;

    final result = await ref
        .read(uploadVideoAnalysisProvider.notifier)
        .upload(filePath: pickedFile.path);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded for analysis')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to upload video'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysesAsync = ref.watch(videoAnalysisListProvider);
    final uploadState = ref.watch(uploadVideoAnalysisProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Video Analysis'),
      ),
      body: Stack(
        children: [
          analysesAsync.when(
            loading: () =>
                const Center(child: AdaptiveSpinner()),
            error: (error, _) => _ErrorView(
              error: error.toString(),
              onRetry: _onRefresh,
            ),
            data: (analyses) {
              if (analyses.isEmpty) {
                return const _EmptyView();
              }
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: analyses.length,
                  itemBuilder: (context, index) {
                    final analysis = analyses[index];
                    return VideoAnalysisCard(
                      analysis: analysis,
                      onTap: () => context.push(
                        '/video-analysis/${analysis.id}',
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (uploadState.isLoading)
            const _UploadOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uploadState.isLoading ? null : _pickAndUploadVideo,
        icon: const Icon(Icons.videocam),
        label: const Text('Upload Video'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
              Icons.video_library_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No video analyses yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a workout video to get AI-powered form analysis and suggestions.',
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
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

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
              'Failed to load analyses',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
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

class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Uploading video...',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a moment depending on file size.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/sharing_provider.dart';
import '../widgets/share_card_widget.dart';

/// Screen that previews a workout share card and offers share / save actions.
class SharePreviewScreen extends ConsumerStatefulWidget {
  final int logId;

  const SharePreviewScreen({super.key, required this.logId});

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isCapturing = false;

  Future<Uint8List?> _captureImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _shareCard() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final bytes = await _captureImage();
      if (bytes == null) {
        if (mounted) {
          showAdaptiveToast(
            context,
            message: 'Failed to capture workout card',
            type: ToastType.error,
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/workout_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my workout!',
      );
    } catch (e) {
      if (mounted) {
        showAdaptiveToast(
          context,
          message: 'Failed to share: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final bytes = await _captureImage();
      if (bytes == null) {
        if (mounted) {
          showAdaptiveToast(
            context,
            message: 'Failed to capture workout card',
            type: ToastType.error,
          );
        }
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'workout_${widget.logId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        final isSuccess =
            result is Map && result['isSuccess'] == true;
        showAdaptiveToast(
          context,
          message: isSuccess
              ? 'Saved to gallery!'
              : 'Failed to save to gallery',
          type: isSuccess ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAdaptiveToast(
          context,
          message: 'Failed to save: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareCardAsync = ref.watch(shareCardProvider(widget.logId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Share Workout'),
      ),
      body: shareCardAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error),
        data: (shareCard) => Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ShareCardWidget(
                    shareCard: shareCard,
                    repaintKey: _repaintKey,
                  ),
                ),
              ),
            ),
            _buildActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
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
              'Could not load share card',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(shareCardProvider(widget.logId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isCapturing ? null : _saveToGallery,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AdaptiveSpinner.small(),
                    )
                  : const Icon(Icons.save_alt, size: 18),
              label: const Text('Save to Gallery'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _shareCard,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AdaptiveSpinner.small(),
                    )
                  : const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }
}

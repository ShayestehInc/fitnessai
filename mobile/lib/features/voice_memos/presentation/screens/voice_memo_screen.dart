import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/voice_memo_model.dart';
import '../providers/voice_memo_provider.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/voice_memo_card.dart';
import 'voice_memo_detail_screen.dart';

/// Main voice memo screen with recorder and recent memos list.
class VoiceMemoScreen extends ConsumerStatefulWidget {
  const VoiceMemoScreen({super.key});

  @override
  ConsumerState<VoiceMemoScreen> createState() => _VoiceMemoScreenState();
}

class _VoiceMemoScreenState extends ConsumerState<VoiceMemoScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memosAsync = ref.watch(voiceMemoListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Voice Memos'),
      ),
      body: Column(
        children: [
          _buildRecorderSection(theme),
          const Divider(height: 1),
          Expanded(
            child: memosAsync.when(
              loading: () => const Center(child: AdaptiveSpinner()),
              error: (error, _) => _buildErrorState(theme, error),
              data: (memos) {
                if (memos.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildMemosList(theme, memos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          if (_isUploading)
            const Column(
              children: [
                AdaptiveSpinner(),
                SizedBox(height: 12),
                Text('Uploading...'),
              ],
            )
          else
            AudioRecorderWidget(
              onRecordingComplete: _handleRecordingComplete,
            ),
        ],
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
              'Failed to load memos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(voiceMemoListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No voice memos yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Record a voice memo to log your workout or nutrition using natural language.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemosList(ThemeData theme, List<VoiceMemoModel> memos) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return VoiceMemoCard(
          memo: memo,
          onTap: () => _openDetail(memo),
        );
      },
    );
  }

  Future<void> _handleRecordingComplete(File audioFile) async {
    setState(() => _isUploading = true);

    final result = await ref
        .read(uploadVoiceMemoProvider.notifier)
        .upload(filePath: audioFile.path);

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result != null) {
      showAdaptiveToast(
        context,
        message: 'Voice memo uploaded!',
        type: ToastType.success,
      );
    } else {
      showAdaptiveToast(
        context,
        message: 'Failed to upload voice memo.',
        type: ToastType.error,
      );
    }
  }

  void _openDetail(VoiceMemoModel memo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VoiceMemoDetailScreen(memoId: memo.id),
      ),
    );
  }
}

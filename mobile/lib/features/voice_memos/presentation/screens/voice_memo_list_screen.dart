import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/voice_memo_model.dart';
import '../providers/voice_memo_provider.dart';
import '../widgets/voice_memo_card.dart';

/// Screen displaying a list of recorded voice memos with pull-to-refresh
/// and an upload FAB.
class VoiceMemoListScreen extends ConsumerStatefulWidget {
  const VoiceMemoListScreen({super.key});

  @override
  ConsumerState<VoiceMemoListScreen> createState() =>
      _VoiceMemoListScreenState();
}

class _VoiceMemoListScreenState extends ConsumerState<VoiceMemoListScreen> {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleUpload,
        child: const Icon(Icons.upload_file),
      ),
      body: memosAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error),
        data: (memos) {
          if (memos.isEmpty) {
            return _buildEmptyState(theme);
          }
          return _buildList(theme, memos);
        },
      ),
    );
  }

  Widget _buildList(ThemeData theme, List<VoiceMemoModel> memos) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(voiceMemoListProvider);
      },
      child: ListView.separated(
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
              'Upload a voice memo to log your workout or '
              'nutrition using natural language.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
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

  void _openDetail(VoiceMemoModel memo) {
    context.push('/voice-memos/${memo.id}');
  }

  Future<void> _handleUpload() async {
    // Placeholder: in production, open a file picker or recorder.
    // For now the FAB signals the upload intent.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload not yet wired to file picker.')),
    );
  }
}

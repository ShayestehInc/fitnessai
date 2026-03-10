import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/voice_memo_model.dart';
import '../providers/voice_memo_provider.dart';
import '../widgets/memo_status_badge.dart';

/// Detail screen for a single voice memo.
///
/// Shows transcript, parsed result, processing indicator, and a delete button.
class VoiceMemoDetailScreen extends ConsumerStatefulWidget {
  final int memoId;

  const VoiceMemoDetailScreen({super.key, required this.memoId});

  @override
  ConsumerState<VoiceMemoDetailScreen> createState() =>
      _VoiceMemoDetailScreenState();
}

class _VoiceMemoDetailScreenState
    extends ConsumerState<VoiceMemoDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memoAsync = ref.watch(voiceMemoDetailProvider(widget.memoId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Voice Memo'),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: AdaptiveSpinner(),
                  )
                : Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: memoAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error),
        data: (memo) => _buildContent(theme, memo),
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
            Text('Failed to load memo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(voiceMemoDetailProvider(widget.memoId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, VoiceMemoModel memo) {
    final formattedDate = _formatDate(memo.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MemoStatusBadge(status: memo.status),
              Text(formattedDate, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),

          // Processing indicator
          if (memo.isProcessing) ...[
            _buildProcessingBanner(theme),
            const SizedBox(height: 24),
          ],

          // Transcript section
          _buildSection(
            theme: theme,
            title: 'Transcript',
            icon: Icons.text_snippet_outlined,
            child: memo.transcript != null && memo.transcript!.isNotEmpty
                ? Text(memo.transcript!, style: theme.textTheme.bodyLarge)
                : Text(
                    memo.isProcessing
                        ? 'Transcription in progress...'
                        : 'No transcript available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),

          if (memo.transcriptionConfidence != null) ...[
            const SizedBox(height: 8),
            _buildConfidenceBar(theme, memo.transcriptionConfidence!),
          ],

          const SizedBox(height: 24),

          // Parsed result section
          _buildSection(
            theme: theme,
            title: 'Parsed Result',
            icon: Icons.auto_awesome,
            child: memo.parsedResult != null && memo.parsedResult!.isNotEmpty
                ? _buildParsedResult(theme, memo.parsedResult!)
                : Text(
                    memo.status == 'parsed'
                        ? 'No parsed data.'
                        : 'Parsing not yet complete.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),

          if (memo.isFailed) ...[
            const SizedBox(height: 24),
            _buildFailedBanner(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: const AdaptiveSpinner.small(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This memo is still being processed. '
              'Check back shortly for results.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Processing failed. Please try recording again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(ThemeData theme, double confidence) {
    final percentage = (confidence * 100).round();
    final color = confidence >= 0.8
        ? const Color(0xFF22C55E)
        : confidence >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Row(
      children: [
        Text('Confidence: $percentage%', style: theme.textTheme.bodySmall),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParsedResult(
    ThemeData theme,
    Map<String, dynamic> parsedResult,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parsedResult.entries.map((entry) {
        final value = entry.value;
        final displayValue =
            value is Map || value is List ? value.toString() : '$value';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  _formatKey(entry.key),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(displayValue, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voice Memo'),
        content: const Text(
          'Are you sure you want to delete this voice memo? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final repo = ref.read(voiceMemoRepositoryProvider);
    final result = await repo.deleteMemo(widget.memoId);

    if (!mounted) return;

    if (result['success'] == true) {
      ref.invalidate(voiceMemoListProvider);
      Navigator.of(context).pop();
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] as String? ?? 'Failed to delete memo',
          ),
        ),
      );
    }
  }

  static String _formatDate(String raw) {
    try {
      final dateTime = DateTime.parse(raw);
      return DateFormat('MMMM d, yyyy h:mm a').format(dateTime);
    } catch (_) {
      return raw;
    }
  }

  static String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

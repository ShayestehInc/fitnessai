import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/logging_provider.dart';
import '../widgets/draft_log_card.dart';

/// AI Command Center - The "Killer Feature"
/// Floating chat interface for natural language logging
class AICommandCenterScreen extends ConsumerStatefulWidget {
  const AICommandCenterScreen({super.key});

  @override
  ConsumerState<AICommandCenterScreen> createState() =>
      _AICommandCenterScreenState();
}

class _AICommandCenterScreenState
    extends ConsumerState<AICommandCenterScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final input = _textController.text.trim();
    if (input.isEmpty) return;

    // Clear input immediately (optimistic UI)
    _textController.clear();

    // Parse input
    await ref.read(loggingStateProvider.notifier).parseInput(input);

    // Scroll to bottom to show draft card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleConfirm() async {
    final success = await ref.read(loggingStateProvider.notifier).confirmAndSave();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log saved successfully!')),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(loggingStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to save log')),
      );
    }
  }

  void _handleCancel() {
    ref.read(loggingStateProvider.notifier).clearState();
  }

  @override
  Widget build(BuildContext context) {
    final loggingState = ref.watch(loggingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Command Center'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tell me what you did today',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: "Ate 3 eggs and did 5x5 squats at 225"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (loggingState.isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (loggingState.error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(loggingState.error!),
                      ),
                    ),
                  if (loggingState.clarificationQuestion != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clarification needed:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(loggingState.clarificationQuestion!),
                          ],
                        ),
                      ),
                    ),
                  if (loggingState.parsedData != null)
                    DraftLogCard(
                      parsedData: loggingState.parsedData!,
                      onConfirm: _handleConfirm,
                      onCancel: _handleCancel,
                      isSaving: loggingState.isSaving,
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                      color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your log here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

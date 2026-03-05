import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/checkin_models.dart';
import '../providers/checkin_provider.dart';

/// Trainer-facing screen that lists submitted check-in responses.
///
/// Allows the trainer to view responses per-trainee and add notes.
class CheckInResponsesScreen extends ConsumerWidget {
  final int? traineeId;

  const CheckInResponsesScreen({super.key, this.traineeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsesAsync = ref.watch(responsesProvider(traineeId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Check-In Responses'),
      ),
      body: responsesAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error, ref),
        data: (responses) => responses.isEmpty
            ? _buildEmptyState(theme)
            : _buildResponseList(context, theme, responses, ref),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error, WidgetRef ref) {
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
              'Failed to load responses',
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
              onPressed: () => ref.invalidate(responsesProvider(traineeId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
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
              Icons.inbox_outlined,
              size: 48,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No responses yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check-in responses will appear here once trainees submit them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseList(
    BuildContext context,
    ThemeData theme,
    List<CheckInResponseModel> responses,
    WidgetRef ref,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final response = responses[index];
        return _ResponseCard(
          response: response,
          theme: theme,
          onTap: () => _showResponseDetail(context, theme, response, ref),
        );
      },
    );
  }

  void _showResponseDetail(
    BuildContext context,
    ThemeData theme,
    CheckInResponseModel response,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ResponseDetailSheet(
        response: response,
        theme: theme,
        onNoteSaved: (notes) async {
          final repository = ref.read(checkinRepositoryProvider);
          final result = await repository.updateTrainerNotes(
            responseId: response.id,
            notes: notes,
          );
          if (result['success'] == true) {
            ref.invalidate(responsesProvider(traineeId));
          }
          return result['success'] == true;
        },
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final CheckInResponseModel response;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ResponseCard({
    required this.response,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_turned_in,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.templateName ?? 'Check-In',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    response.traineeEmail ?? 'Trainee',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(response.submittedAt),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                if (response.trainerNotes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.notes,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _ResponseDetailSheet extends StatefulWidget {
  final CheckInResponseModel response;
  final ThemeData theme;
  final Future<bool> Function(String notes) onNoteSaved;

  const _ResponseDetailSheet({
    required this.response,
    required this.theme,
    required this.onNoteSaved,
  });

  @override
  State<_ResponseDetailSheet> createState() => _ResponseDetailSheetState();
}

class _ResponseDetailSheetState extends State<_ResponseDetailSheet> {
  late final TextEditingController _notesController;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.response.trainerNotes,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    final success = await widget.onNoteSaved(_notesController.text);
    if (!mounted) return;

    setState(() => _isSavingNote = false);
    showAdaptiveToast(
      context,
      message: success ? 'Note saved' : 'Failed to save note',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.response.templateName ?? 'Check-In Response',
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.response.traineeEmail ?? 'Trainee'} - ${_formatDate(widget.response.submittedAt)}',
                style: TextStyle(
                  color: widget.theme.textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Responses
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...widget.response.responses
                        .map((r) => _buildResponseItem(r)),
                    const SizedBox(height: 20),

                    // Trainer notes
                    Text(
                      'Trainer Notes',
                      style: widget.theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add notes about this check-in...',
                        filled: true,
                        fillColor: widget.theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: widget.theme.dividerColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingNote ? null : _saveNote,
                        child: _isSavingNote
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: AdaptiveSpinner.small(),
                              )
                            : const Text('Save Note'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponseItem(CheckInFieldResponse fieldResponse) {
    final displayValue = fieldResponse.value is String
        ? fieldResponse.value as String
        : fieldResponse.value?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldResponse.fieldId,
            style: TextStyle(
              color: widget.theme.textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

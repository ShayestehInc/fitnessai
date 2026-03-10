import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/feedback_provider.dart';
import '../widgets/rating_input_widget.dart';
import 'pain_log_screen.dart';

/// Post-workout session feedback form.
class SessionFeedbackScreen extends ConsumerStatefulWidget {
  final int sessionPk;

  const SessionFeedbackScreen({super.key, required this.sessionPk});

  @override
  ConsumerState<SessionFeedbackScreen> createState() =>
      _SessionFeedbackScreenState();
}

class _SessionFeedbackScreenState
    extends ConsumerState<SessionFeedbackScreen> {
  final _notesController = TextEditingController();

  String _completionState = 'completed';
  final Map<String, int> _ratings = {
    'overall': 3,
    'muscle_feel': 3,
    'energy': 3,
    'confidence': 3,
    'enjoyment': 3,
    'difficulty': 3,
  };
  final Set<String> _frictionReasons = {};
  bool _recoveryConcern = false;
  final List<Map<String, dynamic>> _painEvents = [];
  bool _isSubmitting = false;

  static const List<String> _completionStates = [
    'completed',
    'partial',
    'skipped',
  ];

  static const Map<String, String> _ratingLabels = {
    'overall': 'Overall',
    'muscle_feel': 'Muscle Feel',
    'energy': 'Energy Level',
    'confidence': 'Confidence',
    'enjoyment': 'Enjoyment',
    'difficulty': 'Difficulty',
  };

  static const Map<String, String> _ratingDescriptions = {
    'overall': 'How was the session overall?',
    'muscle_feel': 'How did your muscles feel during the workout?',
    'energy': 'How was your energy level throughout?',
    'confidence': 'How confident did you feel with the exercises?',
    'enjoyment': 'How much did you enjoy this session?',
    'difficulty': 'How challenging was the session?',
  };

  static const List<String> _availableFrictionReasons = [
    'Too difficult',
    'Too easy',
    'Equipment unavailable',
    'Time constraint',
    'Felt pain/discomfort',
    'Low motivation',
    'Crowded gym',
    'Exercise unfamiliar',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Session Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompletionSelector(theme),
            const SizedBox(height: 24),
            _buildRatingsSection(theme),
            const SizedBox(height: 24),
            _buildFrictionReasons(theme),
            const SizedBox(height: 24),
            _buildRecoveryConcern(theme),
            const SizedBox(height: 24),
            _buildPainEventsSection(theme),
            const SizedBox(height: 24),
            _buildNotesField(theme),
            const SizedBox(height: 32),
            _buildSubmitButton(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Completion', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: _completionStates.map((state) {
            final isSelected = _completionState == state;
            final label = state[0].toUpperCase() + state.substring(1);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: state != _completionStates.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _completionState = state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.15)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ratings', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ..._ratingLabels.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: RatingInputWidget(
              label: entry.value,
              description: _ratingDescriptions[entry.key],
              value: _ratings[entry.key] ?? 3,
              onChanged: (v) => setState(() => _ratings[entry.key] = v),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFrictionReasons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Any friction points?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableFrictionReasons.map((reason) {
            final isSelected = _frictionReasons.contains(reason);
            return FilterChip(
              label: Text(reason),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _frictionReasons.add(reason);
                  } else {
                    _frictionReasons.remove(reason);
                  }
                });
              },
              selectedColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecoveryConcern(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery Concern',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Are you concerned about recovery before your next session?',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _recoveryConcern,
            onChanged: (v) => setState(() => _recoveryConcern = v),
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPainEventsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pain Events', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: _addPainEvent,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_painEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No pain events recorded. Tap "Add" if you experienced any discomfort.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          ..._painEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: _painColor(event['pain_score'] as int? ?? 1),
                ),
                title: Text(
                  _formatBodyRegion(event['body_region'] as String? ?? ''),
                ),
                subtitle: Text(
                  'Score: ${event['pain_score']}/10',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _painEvents.removeAt(index));
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes (optional)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Anything else about this session...',
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const AdaptiveSpinner.small()
            : const Text('Submit Feedback'),
      ),
    );
  }

  Future<void> _addPainEvent() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const PainLogScreen(returnResult: true),
      ),
    );

    if (result != null) {
      setState(() => _painEvents.add(result));
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final result = await ref.read(submitFeedbackProvider.notifier).submit(
          sessionPk: widget.sessionPk,
          completionState: _completionState,
          ratings: Map<String, int>.from(_ratings),
          frictionReasons: _frictionReasons.toList(),
          recoveryConcern: _recoveryConcern,
          notes: _notesController.text.trim(),
          painEvents: _painEvents,
        );

    if (!mounted) return;

    if (result != null) {
      showAdaptiveToast(
        context,
        message: 'Feedback submitted successfully!',
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      showAdaptiveToast(
        context,
        message: 'Failed to submit feedback. Please try again.',
        type: ToastType.error,
      );
    }
  }

  Color _painColor(int score) {
    if (score <= 3) return const Color(0xFF22C55E);
    if (score <= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatBodyRegion(String region) {
    return region
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../../session_feedback/data/models/triage_models.dart';
import '../../../session_feedback/presentation/providers/triage_provider.dart';
import '../widgets/proceed_card.dart';

/// Shows the pain triage bottom sheet and returns the proceed decision.
Future<String?> showPainTriagePopup({
  required BuildContext context,
  required String painEventId,
  required String activeSessionId,
  String? activeSetLogId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PainTriageSheet(
      painEventId: painEventId,
      activeSessionId: activeSessionId,
      activeSetLogId: activeSetLogId,
    ),
  );
}

class _PainTriageSheet extends ConsumerStatefulWidget {
  final String painEventId;
  final String activeSessionId;
  final String? activeSetLogId;

  const _PainTriageSheet({
    required this.painEventId,
    required this.activeSessionId,
    this.activeSetLogId,
  });

  @override
  ConsumerState<_PainTriageSheet> createState() => _PainTriageSheetState();
}

class _PainTriageSheetState extends ConsumerState<_PainTriageSheet> {
  // Round 2 state
  String _loadSens = 'same';
  String _romSens = 'same';
  String _tempoSens = 'same';
  bool _supportHelps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(triageNotifierProvider.notifier).startTriage(
            painEventId: widget.painEventId,
            activeSessionId: widget.activeSessionId,
            activeSetLogId: widget.activeSetLogId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triageNotifierProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHandle(theme),
              const SizedBox(height: 16),
              _buildStepIndicator(theme, state.currentStep),
              const SizedBox(height: 16),
              Expanded(
                child: state.isLoading
                    ? const Center(child: AdaptiveSpinner())
                    : _buildCurrentStep(theme, state, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, int step) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary : theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(
    ThemeData theme,
    TriageState state,
    ScrollController controller,
  ) {
    switch (state.currentStep) {
      case 0:
        return const Center(child: AdaptiveSpinner());
      case 1:
        return _buildRound2(theme, controller);
      case 2:
        return _buildRemedyLadder(theme, state, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRound2(ThemeData theme, ScrollController controller) {
    return ListView(
      controller: controller,
      children: [
        Text(
          'Movement Sensitivity',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Help us find the right fix. Answer these quick questions:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _buildSensitivityQuestion(
          theme,
          'Does it feel better with lighter load?',
          _loadSens,
          (v) => setState(() => _loadSens = v),
        ),
        const SizedBox(height: 16),
        _buildSensitivityQuestion(
          theme,
          'Does it feel better with shorter range of motion?',
          _romSens,
          (v) => setState(() => _romSens = v),
        ),
        const SizedBox(height: 16),
        _buildSensitivityQuestion(
          theme,
          'Does it feel better with slower tempo?',
          _tempoSens,
          (v) => setState(() => _tempoSens = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          title: const Text('Does support gear help?'),
          subtitle: const Text('Belt, wraps, sleeves, etc.'),
          value: _supportHelps,
          onChanged: (v) => setState(() => _supportHelps = v),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitRound2,
            child: const Text('Get Suggestions'),
          ),
        ),
      ],
    );
  }

  Widget _buildSensitivityQuestion(
    ThemeData theme,
    String question,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    const options = ['better', 'same', 'worse'];
    const labels = ['Better', 'Same', 'Worse'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (i) {
            final isSelected = currentValue == options[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onChanged(options[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.15)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRemedyLadder(
    ThemeData theme,
    TriageState state,
    ScrollController controller,
  ) {
    final suggestions = state.ladderResult?.suggestions ?? [];

    return ListView(
      controller: controller,
      children: [
        Text('Suggested Remedies', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Try these in order. Each step is designed to help without stopping your workout.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...suggestions.map((s) => _buildRemedyCard(theme, s)),
        const SizedBox(height: 16),
        Text(
          'Ready to decide?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...ProceedCard.allOptions.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProceedCard(
              decision: option.decision,
              title: option.title,
              subtitle: option.subtitle,
              icon: option.icon,
              onTap: () => _finalize(option.decision),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRemedyCard(ThemeData theme, RemedySuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                '${suggestion.order}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.interventionLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRound2() async {
    final success = await ref.read(triageNotifierProvider.notifier).submitRound2(
          loadSensitivity: _loadSens,
          romSensitivity: _romSens,
          tempoSensitivity: _tempoSens,
          supportHelps: _supportHelps,
        );

    if (!mounted) return;
    if (!success) {
      showAdaptiveToast(
        context,
        message: 'Failed to get suggestions. Please try again.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _finalize(String decision) async {
    final success = await ref.read(triageNotifierProvider.notifier).finalizeTriage(
          proceedDecision: decision,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(decision);
    } else {
      showAdaptiveToast(
        context,
        message: 'Failed to save decision. Please try again.',
        type: ToastType.error,
      );
    }
  }
}

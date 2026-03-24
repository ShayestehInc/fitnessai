import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/session_models.dart';
import '../providers/session_provider.dart';
import '../widgets/dials_escalation_sheet.dart';
import '../widgets/exercise_header_widget.dart';
import '../widgets/exercise_workload_card.dart';
import '../widgets/next_set_card.dart';
import '../widgets/pain_toggle_button.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/set_logging_card.dart';
import '../widgets/warmup_assessment_sheet.dart';
import 'pain_triage_popup.dart';

/// Main workout execution screen. Loads the active session on init,
/// displays the current exercise/set, and provides controls for
/// logging, skipping, completing, and abandoning the session.
class SessionRunnerScreen extends ConsumerStatefulWidget {
  /// Optional session ID to load directly. If null, loads active session.
  final String? sessionId;

  /// Optional plan session ID to start a new session.
  final String? planSessionId;

  const SessionRunnerScreen({
    super.key,
    this.sessionId,
    this.planSessionId,
  });

  @override
  ConsumerState<SessionRunnerScreen> createState() =>
      _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends ConsumerState<SessionRunnerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  Future<void> _initSession() async {
    final notifier = ref.read(sessionNotifierProvider.notifier);
    if (widget.planSessionId != null) {
      await notifier.startSession(widget.planSessionId!);
    } else if (widget.sessionId != null) {
      await notifier.loadSessionDetail(widget.sessionId!);
    } else {
      await notifier.loadActiveSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionNotifierProvider);
    final theme = Theme.of(context);

    // Show error snackbar when error changes
    ref.listen<SessionState>(sessionNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ref.read(sessionNotifierProvider.notifier).clearError();
              },
            ),
          ),
        );
      }

      // Navigate to summary when session is completed
      if (next.summary != null && previous?.summary == null) {
        context.pushReplacement(
          '/session-summary',
          extra: next.summary,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showAbandonConfirmation();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, state, theme),
        body: _buildBody(context, state, theme),
        floatingActionButton: state.activeSession != null && state.activeSession!.isActive
            ? PainToggleButton(
                onTap: () => _handlePainReport(state),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SessionState state,
    ThemeData theme,
  ) {
    final session = state.activeSession;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        session?.planSessionLabel ?? 'Workout',
        style: theme.textTheme.titleMedium,
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _showAbandonConfirmation,
      ),
      actions: [
        if (session != null && session.isActive)
          TextButton(
            onPressed: state.isLoading ? null : _showCompleteConfirmation,
            child: const Text('Finish'),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionState state,
    ThemeData theme,
  ) {
    if (state.isLoading && state.activeSession == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = state.activeSession;

    if (session == null) {
      return _NoSessionView(onRetry: _initSession);
    }

    return Stack(
      children: [
        _SessionContent(
          session: session,
          currentSlotIndex: state.currentSlotIndex,
          isLoggingSet: state.isLoggingSet,
        ),
        if (state.isResting)
          RestTimerWidget(
            secondsRemaining: state.restSecondsRemaining,
            totalSeconds: state.restSecondsTotal,
            onSkip: () {
              ref.read(sessionNotifierProvider.notifier).skipRestTimer();
            },
          ),
      ],
    );
  }

  Future<void> _handlePainReport(SessionState state) async {
    final session = state.activeSession;
    if (session == null) return;

    // For now, go directly to triage popup with a placeholder pain event ID.
    // In production, create a PainEvent first via API, then pass its ID.
    final decision = await showPainTriagePopup(
      context: context,
      painEventId: '', // Will be created inside the popup
      activeSessionId: session.activeSessionId,
    );

    if (!mounted || decision == null) return;

    // Handle proceed decision
    if (decision == 'stop_session') {
      _showCompleteConfirmation();
    } else if (decision == 'skip_slot') {
      // Skip remaining sets in current slot
      final currentSlot = session.slots.isNotEmpty &&
              state.currentSlotIndex < session.slots.length
          ? session.slots[state.currentSlotIndex]
          : null;
      if (currentSlot != null) {
        for (final set in currentSlot.sets) {
          if (set.isPending) {
            ref.read(sessionNotifierProvider.notifier).skipSet(
                  slotId: currentSlot.slotId,
                  setNumber: set.setNumber,
                  reason: 'pain_triage_skip',
                );
          }
        }
      }
    }
  }

  Future<void> _handleFeelsOff(SessionSlotModel? currentSlot) async {
    if (currentSlot == null) return;
    final result = await DialsEscalationSheet.show(
      context,
      exerciseName: currentSlot.exerciseName,
    );
    // Result is the escalation type chosen (cue, tempo, load, rom, stance, swap)
    // For now, just log the selection. Swap would trigger the swap flow.
  }

  void _showAbandonConfirmation() {
    final session = ref.read(sessionNotifierProvider).activeSession;
    if (session == null) {
      context.pop();
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Workout?'),
        content: const Text(
          'Your progress for this session will be saved, but the '
          'session will be marked as abandoned. You can always '
          'start a new session later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final success = await ref
            .read(sessionNotifierProvider.notifier)
            .abandonSession();
        if (success && mounted) {
          context.pop();
        }
      }
    });
  }

  void _showCompleteConfirmation() {
    final session = ref.read(sessionNotifierProvider).activeSession;
    if (session == null) return;

    final pendingSets = session.pendingSets;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Workout?'),
        content: Text(
          pendingSets > 0
              ? 'You still have $pendingSets pending sets. '
                'They will be left incomplete. Continue?'
              : 'Great job! Ready to finish this workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await ref.read(sessionNotifierProvider.notifier).completeSession();
      }
    });
  }
}

class _NoSessionView extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoSessionView({required this.onRetry});

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
              Icons.fitness_center,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No active session',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a workout from your training plan to begin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scrollable session content showing progress, exercise slots, and sets.
class _SessionContent extends ConsumerWidget {
  final ActiveSessionModel session;
  final int currentSlotIndex;
  final bool isLoggingSet;

  const _SessionContent({
    required this.session,
    required this.currentSlotIndex,
    required this.isLoggingSet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final slots = session.slots;
    final currentSlot =
        currentSlotIndex < slots.length ? slots[currentSlotIndex] : null;
    final currentSet = currentSlot?.nextPendingSet;

    final loadUnit = currentSet?.prescribedLoadUnit ??
        currentSlot?.sets.firstOrNull?.prescribedLoadUnit ??
        'lb';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SessionProgressBar(session: session),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SlotNavigator(
            slots: slots,
            currentIndex: currentSlotIndex,
            onSlotTapped: (index) {
              ref
                  .read(sessionNotifierProvider.notifier)
                  .setCurrentSlotIndex(index);
            },
          ),
        ),
        Expanded(
          child: currentSlot == null
              ? Center(
                  child: Text(
                    'All exercises done!',
                    style: theme.textTheme.titleMedium,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ExerciseHeaderWidget(
                      slot: currentSlot,
                      currentSet: currentSet,
                    ),
                    // "Feels off?" button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          DialsEscalationSheet.show(
                            context,
                            exerciseName: currentSlot.exerciseName,
                          );
                        },
                        icon: Icon(
                          Icons.sentiment_dissatisfied_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        label: Text(
                          'Feels off?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    // Next set preview (if there's a pending set)
                    if (currentSet != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NextSetCard(
                          setNumber: currentSet.setNumber,
                          totalSets: currentSlot.totalSets,
                          prescribedRepsMin: currentSet.prescribedRepsMin ?? 0,
                          prescribedRepsMax: currentSet.prescribedRepsMax ?? currentSet.prescribedRepsMin ?? 0,
                          suggestedLoad: double.tryParse(currentSet.prescribedLoad ?? ''),
                          loadUnit: loadUnit,
                        ),
                      ),
                    ...currentSlot.sets.map((set) {
                      final isCurrentSet = currentSet != null &&
                          set.setLogId == currentSet.setLogId;

                      if (!isCurrentSet && set.isPending) {
                        return _FutureSetCard(set: set);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SetLoggingCard(
                          set: set,
                          loadUnit: loadUnit,
                          isLogging: isLoggingSet && isCurrentSet,
                          onLogSet: ({
                            required int completedReps,
                            required double loadValue,
                            required String loadUnit,
                            double? rpe,
                            String? notes,
                          }) {
                            ref
                                .read(sessionNotifierProvider.notifier)
                                .logSet(
                                  slotId: currentSlot.slotId,
                                  setNumber: set.setNumber,
                                  completedReps: completedReps,
                                  loadValue: loadValue,
                                  loadUnit: loadUnit,
                                  rpe: rpe,
                                  notes: notes,
                                );
                          },
                          onSkipSet: ({String? reason}) {
                            ref
                                .read(sessionNotifierProvider.notifier)
                                .skipSet(
                                  slotId: currentSlot.slotId,
                                  setNumber: set.setNumber,
                                  reason: reason,
                                );
                          },
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Horizontal scrollable slot navigator tabs.
class _SlotNavigator extends StatelessWidget {
  final List<SessionSlotModel> slots;
  final int currentIndex;
  final ValueChanged<int> onSlotTapped;

  const _SlotNavigator({
    required this.slots,
    required this.currentIndex,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = slots[index];
          final isSelected = index == currentIndex;
          final isDone = slot.isFullyDone;

          Color bgColor;
          Color textColor;
          if (isSelected) {
            bgColor = colorScheme.primary;
            textColor = colorScheme.onPrimary;
          } else if (isDone) {
            bgColor = Colors.green.withValues(alpha: 0.15);
            textColor = Colors.green;
          } else {
            bgColor = colorScheme.surfaceContainerHighest;
            textColor = colorScheme.onSurface;
          }

          return GestureDetector(
            onTap: () => onSlotTapped(index),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                slot.exerciseName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A dimmed card for future pending sets that aren't the current one.
class _FutureSetCard extends StatelessWidget {
  final SessionSetModel set;

  const _FutureSetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Set ${set.setNumber}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${set.prescribedRepsDisplay} reps @ ${set.prescribedLoadDisplay}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/checkin_models.dart';
import '../providers/checkin_provider.dart';
import '../widgets/dynamic_field_widget.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// Trainee-facing dynamic form screen for completing a check-in assignment.
class CheckInFormScreen extends ConsumerStatefulWidget {
  final CheckInAssignmentModel assignment;

  const CheckInFormScreen({super.key, required this.assignment});

  @override
  ConsumerState<CheckInFormScreen> createState() => _CheckInFormScreenState();
}

class _CheckInFormScreenState extends ConsumerState<CheckInFormScreen> {
  final Map<String, dynamic> _responses = {};
  bool _isSubmitting = false;

  List<CheckInFieldDefinition> get _fields =>
      widget.assignment.templateFields ?? [];

  @override
  void initState() {
    super.initState();
    // Initialize default values for scale fields
    for (final field in _fields) {
      if (field.type == 'scale') {
        _responses[field.id] = 5;
      }
    }
  }

  bool _validate() {
    for (final field in _fields) {
      if (field.required) {
        final value = _responses[field.id];
        if (value == null) return false;
        if (value is String && value.trim().isEmpty) return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      showAdaptiveToast(
        context,
        message: context.l10n.checkinsPleaseFillInAllRequiredFields,
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final responseList = _responses.entries
        .map((entry) => {'field_id': entry.key, 'value': entry.value})
        .toList();

    final repository = ref.read(checkinRepositoryProvider);
    final result = await repository.submitResponse(
      assignmentId: widget.assignment.id,
      responses: responseList,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Invalidate pending check-ins so the list refreshes
      ref.invalidate(pendingCheckInsProvider);
      showAdaptiveToast(
        context,
        message: context.l10n.checkinsCheckInSubmittedSuccessfully,
        type: ToastType.success,
      );
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      showAdaptiveToast(
        context,
        message: result['error'] ?? 'Failed to submit',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateName =
        widget.assignment.templateName ?? 'Check-In';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(),
        ),
        title: Text(templateName),
      ),
      body: _fields.isEmpty
          ? _buildEmptyState(theme)
          : _buildForm(theme),
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
              Icons.assignment_outlined,
              size: 48,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No fields in this check-in',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This check-in form has no fields configured. '
              'Please contact your trainer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Due date indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${widget.assignment.nextDueDate}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic fields
                ..._fields.map((field) => DynamicFieldWidget(
                      field: field,
                      value: _responses[field.id],
                      onChanged: (newValue) {
                        setState(() => _responses[field.id] = newValue);
                      },
                    )),
              ],
            ),
          ),
        ),

        // Submit button
        Container(
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const AdaptiveSpinner.small()
                  : Text(context.l10n.checkinsSubmitCheckIn),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    // If user has entered any data, confirm before exiting
    final hasData = _responses.values.any((v) {
      if (v == null) return false;
      if (v is String && v.isEmpty) return false;
      if (v is int && v == 5) return false; // default scale value
      return true;
    });

    if (!hasData) {
      context.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.checkinsDiscardCheckIn),
        content: const Text(
          'You have unsaved responses. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.checkinsDiscard),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.pop();
    }
  }
}

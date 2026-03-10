import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/program_import_model.dart';
import '../providers/program_import_provider.dart';

/// Review screen for a parsed program import. Shows the parsed structure,
/// any warnings/errors, and a confirm button.
class ImportReviewScreen extends ConsumerStatefulWidget {
  final String importId;

  const ImportReviewScreen({super.key, required this.importId});

  @override
  ConsumerState<ImportReviewScreen> createState() =>
      _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync =
        ref.watch(programImportDetailProvider(widget.importId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Review Import'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildErrorState(theme, error),
        data: (importModel) => _buildContent(theme, importModel),
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
              'Failed to load import',
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
              onPressed: () => ref.invalidate(
                programImportDetailProvider(widget.importId),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ProgramImportModel importModel) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, importModel),
                const SizedBox(height: 24),
                if (importModel.isProcessing)
                  _buildProcessingState(theme),
                if (importModel.isFailed)
                  _buildFailedState(theme, importModel),
                if (importModel.hasErrors)
                  _buildErrorsList(theme, importModel.errors!),
                if (importModel.hasWarnings) ...[
                  _buildWarningsList(theme, importModel.warnings!),
                  const SizedBox(height: 16),
                ],
                if (importModel.parsedProgram != null &&
                    importModel.parsedProgram!.isNotEmpty)
                  _buildParsedProgram(theme, importModel.parsedProgram!),
              ],
            ),
          ),
        ),
        if (importModel.isReady && !importModel.isConfirmed)
          _buildConfirmBar(theme, importModel),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ProgramImportModel importModel) {
    String formattedDate;
    try {
      final dateTime = DateTime.parse(importModel.createdAt);
      formattedDate = DateFormat('MMMM d, yyyy h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = importModel.createdAt;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                importModel.fileName ?? 'Imported Program',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(formattedDate, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        _buildStatusChip(theme, importModel),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, ProgramImportModel importModel) {
    Color chipColor;
    switch (importModel.status) {
      case 'parsed':
        chipColor = const Color(0xFFF59E0B);
      case 'confirmed':
        chipColor = const Color(0xFF22C55E);
      case 'failed':
        chipColor = const Color(0xFFEF4444);
      default:
        chipColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        importModel.statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _buildProcessingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const AdaptiveSpinner(),
            const SizedBox(height: 16),
            Text(
              'Processing your file...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment. Pull down to refresh.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState(ThemeData theme, ProgramImportModel importModel) {
    return Container(
      width: double.infinity,
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
              'Import failed. Please check your file format and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsList(ThemeData theme, List<String> errors) {
    return _buildAlertSection(
      theme: theme,
      title: 'Errors',
      icon: Icons.error_outline,
      color: const Color(0xFFEF4444),
      items: errors,
    );
  }

  Widget _buildWarningsList(ThemeData theme, List<String> warnings) {
    return _buildAlertSection(
      theme: theme,
      title: 'Warnings',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF59E0B),
      items: warnings,
    );
  }

  Widget _buildAlertSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                '$title (${items.length})',
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  \u2022  ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildParsedProgram(
    ThemeData theme,
    Map<String, dynamic> parsedProgram,
  ) {
    return _buildSection(
      theme: theme,
      title: 'Parsed Program',
      icon: Icons.fitness_center_rounded,
      child: _buildProgramTree(theme, parsedProgram),
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

  Widget _buildProgramTree(
    ThemeData theme,
    Map<String, dynamic> data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final value = entry.value;

        if (value is List) {
          return _buildListEntry(theme, entry.key, value);
        }

        if (value is Map) {
          return _buildMapEntry(
            theme,
            entry.key,
            Map<String, dynamic>.from(value),
          );
        }

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
                child: Text('$value', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListEntry(ThemeData theme, String key, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...items.map((item) {
            if (item is Map) {
              return Container(
                margin: const EdgeInsets.only(left: 12, bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildProgramTree(
                  theme,
                  Map<String, dynamic>.from(item),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text('\u2022  $item', style: theme.textTheme.bodyMedium),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapEntry(
    ThemeData theme,
    String key,
    Map<String, dynamic> map,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildProgramTree(theme, map),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar(ThemeData theme, ProgramImportModel importModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isConfirming ? null : _confirmImport,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isConfirming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Import'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() => _isConfirming = true);

    final success = await ref
        .read(confirmProgramImportProvider(widget.importId).notifier)
        .confirm();

    if (!mounted) return;

    setState(() => _isConfirming = false);

    if (success) {
      showAdaptiveToast(
        context,
        message: 'Program imported successfully!',
        type: ToastType.success,
      );
      Navigator.of(context).pop();
    } else {
      showAdaptiveToast(
        context,
        message: 'Failed to confirm import.',
        type: ToastType.error,
      );
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

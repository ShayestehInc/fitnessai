import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/program_import_model.dart';
import '../providers/program_import_provider.dart';
import '../widgets/import_status_card.dart';
import 'import_review_screen.dart';

/// Main screen for program imports: upload zone + list of past imports.
class ProgramImportScreen extends ConsumerStatefulWidget {
  const ProgramImportScreen({super.key});

  @override
  ConsumerState<ProgramImportScreen> createState() =>
      _ProgramImportScreenState();
}

class _ProgramImportScreenState extends ConsumerState<ProgramImportScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importsAsync = ref.watch(programImportListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Import Program'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(programImportListProvider);
        },
        child: Column(
          children: [
            _buildUploadSection(theme),
            const Divider(height: 1),
            Expanded(
              child: importsAsync.when(
                loading: () => const Center(child: AdaptiveSpinner()),
                error: (error, _) => _buildErrorState(theme, error),
                data: (imports) {
                  if (imports.isEmpty) {
                    return _buildEmptyState(theme);
                  }
                  return _buildImportsList(theme, imports);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(ThemeData theme) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadFile,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: _isUploading
            ? const Column(
                children: [
                  AdaptiveSpinner(),
                  SizedBox(height: 12),
                  Text('Uploading...'),
                ],
              )
            : Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Program File',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select a file (.xlsx, .csv, .pdf)',
                    style: theme.textTheme.bodySmall,
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
              'Failed to load imports',
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
              onPressed: () => ref.invalidate(programImportListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        const SizedBox(height: 64),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.file_copy_outlined,
                  size: 64,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 16),
                Text(
                  'No imports yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a program file to get started. '
                  'We will parse it and let you review before confirming.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportsList(
    ThemeData theme,
    List<ProgramImportModel> imports,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: imports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final importModel = imports[index];
        return ImportStatusCard(
          importModel: importModel,
          onTap: () => _openDetail(importModel),
        );
      },
    );
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'pdf', 'xls'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() => _isUploading = true);

    final importModel = await ref
        .read(uploadProgramImportProvider.notifier)
        .upload(filePath: filePath);

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (importModel != null) {
      showAdaptiveToast(
        context,
        message: 'File uploaded! Processing...',
        type: ToastType.success,
      );
    } else {
      showAdaptiveToast(
        context,
        message: 'Failed to upload file.',
        type: ToastType.error,
      );
    }
  }

  void _openDetail(ProgramImportModel importModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(
          importId: importModel.id.toString(),
        ),
      ),
    );
  }
}

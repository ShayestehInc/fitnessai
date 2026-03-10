import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/program_import_model.dart';
import '../../data/repositories/program_import_repository.dart';

/// Repository provider for program imports.
final programImportRepositoryProvider =
    Provider<ProgramImportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgramImportRepository(apiClient);
});

/// Fetches the list of program imports.
final programImportListProvider =
    FutureProvider.autoDispose<List<ProgramImportModel>>((ref) async {
  final repo = ref.watch(programImportRepositoryProvider);
  final result = await repo.listImports();

  if (result['success'] == true) {
    return result['imports'] as List<ProgramImportModel>;
  }

  throw Exception(
    result['error'] as String? ?? 'Failed to load program imports',
  );
});

/// Fetches detail of a specific program import by its draft ID.
final programImportDetailProvider = FutureProvider.autoDispose
    .family<ProgramImportModel, String>((ref, importId) async {
  final repo = ref.watch(programImportRepositoryProvider);
  final result = await repo.getDetail(importId);

  if (result['success'] == true) {
    return result['import'] as ProgramImportModel;
  }

  throw Exception(
    result['error'] as String? ?? 'Failed to load import detail',
  );
});

/// Provider for uploading a program file.
final uploadProgramImportProvider = StateNotifierProvider.autoDispose<
    UploadProgramImportNotifier, AsyncValue<ProgramImportModel?>>((ref) {
  final repo = ref.watch(programImportRepositoryProvider);
  return UploadProgramImportNotifier(repo, ref);
});

class UploadProgramImportNotifier
    extends StateNotifier<AsyncValue<ProgramImportModel?>> {
  final ProgramImportRepository _repo;
  final Ref _ref;

  UploadProgramImportNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<ProgramImportModel?> upload({required String filePath}) async {
    state = const AsyncValue.loading();

    final result = await _repo.uploadFile(filePath: filePath);

    if (result['success'] == true) {
      final importModel = result['import'] as ProgramImportModel;
      state = AsyncValue.data(importModel);
      _ref.invalidate(programImportListProvider);
      return importModel;
    }

    final error = result['error'] as String? ?? 'Upload failed';
    state = AsyncValue.error(error, StackTrace.current);
    return null;
  }
}

/// Provider for confirming a program import.
final confirmProgramImportProvider = StateNotifierProvider.autoDispose
    .family<ConfirmProgramImportNotifier, AsyncValue<void>, String>(
  (ref, importId) {
    final repo = ref.watch(programImportRepositoryProvider);
    return ConfirmProgramImportNotifier(repo, ref, importId);
  },
);

class ConfirmProgramImportNotifier extends StateNotifier<AsyncValue<void>> {
  final ProgramImportRepository _repo;
  final Ref _ref;
  final String _importId;

  ConfirmProgramImportNotifier(this._repo, this._ref, this._importId)
      : super(const AsyncValue.data(null));

  Future<bool> confirm() async {
    state = const AsyncValue.loading();

    final result = await _repo.confirmImport(_importId);

    if (result['success'] == true) {
      state = const AsyncValue.data(null);
      _ref.invalidate(programImportListProvider);
      _ref.invalidate(programImportDetailProvider(_importId));
      return true;
    }

    final error = result['error'] as String? ?? 'Confirm failed';
    state = AsyncValue.error(error, StackTrace.current);
    return false;
  }
}

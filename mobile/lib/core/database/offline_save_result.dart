/// Typed result from an offline-aware save operation.
/// Replaces raw `Map<String, dynamic>` returns.
class OfflineSaveResult {
  /// Whether the save operation succeeded.
  final bool success;

  /// Whether the data was saved offline (true) or online (false).
  final bool offline;

  /// Error message if [success] is false.
  final String? error;

  /// Additional data from the online save (e.g., server response).
  final Map<String, dynamic>? data;

  const OfflineSaveResult({
    required this.success,
    this.offline = false,
    this.error,
    this.data,
  });

  const OfflineSaveResult.onlineSuccess({this.data})
      : success = true,
        offline = false,
        error = null;

  const OfflineSaveResult.offlineSuccess()
      : success = true,
        offline = true,
        error = null,
        data = null;

  const OfflineSaveResult.failure(this.error)
      : success = false,
        offline = false,
        data = null;
}

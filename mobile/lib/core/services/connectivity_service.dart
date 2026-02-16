import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Simplified connectivity status for the app.
enum ConnectivityStatus { online, offline }

/// Service that monitors network connectivity with debouncing
/// to handle connection flapping (rapid on/off transitions).
class ConnectivityService {
  final Connectivity _connectivity;
  final Duration _debounceDuration;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService({
    Connectivity? connectivity,
    Duration debounceDuration = const Duration(seconds: 2),
  })  : _connectivity = connectivity ?? Connectivity(),
        _debounceDuration = debounceDuration;

  /// The current connectivity status (synchronous getter).
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Stream of connectivity status changes (debounced).
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Start monitoring connectivity. Call this once during app init.
  Future<void> initialize() async {
    // Check initial status
    final initialResults = await _connectivity.checkConnectivity();
    _currentStatus = _mapResults(initialResults);
    _statusController.add(_currentStatus);

    // Listen for changes with debouncing
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final newStatus = _mapResults(results);

    // Only debounce if transitioning to offline, or from offline to online.
    // This prevents rapid toggling from causing sync starts/stops.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
      }
    });
  }

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    // On some Android devices, connectivity_plus can return
    // [ConnectivityResult.none] alongside real connections like wifi.
    // Only report offline if 'none' is the sole result.
    final hasRealConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );
    if (!hasRealConnection) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  /// Dispose resources. Call when the app is being shut down.
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    await _statusController.close();
  }
}

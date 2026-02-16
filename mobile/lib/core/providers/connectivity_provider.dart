import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Provides the ConnectivityService singleton.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Streams the current connectivity status for widgets to consume.
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Synchronous check: is the device currently online?
/// Falls back to true if the stream hasn't emitted yet.
final isOnlineProvider = Provider<bool>((ref) {
  final asyncStatus = ref.watch(connectivityStatusProvider);
  return asyncStatus.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online until proven otherwise
    error: (_, __) => true,
  );
});

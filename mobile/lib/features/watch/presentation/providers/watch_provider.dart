import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/watch_repository.dart';

/// Singleton provider for the watch repository.
final watchRepositoryProvider = Provider<WatchRepository>((ref) {
  final repo = WatchRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Whether an Apple Watch is paired to this device.
final isWatchPairedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(watchRepositoryProvider);
  return repo.isWatchPaired;
});

/// Whether the paired Apple Watch is currently reachable.
final isWatchReachableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(watchRepositoryProvider);
  return repo.isWatchConnected;
});

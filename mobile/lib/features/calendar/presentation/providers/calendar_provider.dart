import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/calendar_connection_model.dart';
import '../../data/repositories/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarRepository(apiClient);
});

// Calendar connections state
class CalendarState {
  final List<CalendarConnectionModel> connections;
  final List<CalendarEventModel> events;
  final List<TrainerAvailabilityModel> availability;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  CalendarState({
    this.connections = const [],
    this.events = const [],
    this.availability = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  CalendarState copyWith({
    List<CalendarConnectionModel>? connections,
    List<CalendarEventModel>? events,
    List<TrainerAvailabilityModel>? availability,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return CalendarState(
      connections: connections ?? this.connections,
      events: events ?? this.events,
      availability: availability ?? this.availability,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  CalendarConnectionModel? get googleConnection =>
      connections.where((c) => c.isGoogle && c.isConnected).firstOrNull;

  CalendarConnectionModel? get microsoftConnection =>
      connections.where((c) => c.isMicrosoft && c.isConnected).firstOrNull;

  bool get hasGoogleConnected => googleConnection != null;
  bool get hasMicrosoftConnected => microsoftConnection != null;
  bool get hasAnyConnection => hasGoogleConnected || hasMicrosoftConnected;
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final CalendarRepository _repository;

  CalendarNotifier(this._repository) : super(CalendarState());

  Future<void> loadConnections() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final connections = await _repository.getConnections();
      state = state.copyWith(connections: connections, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load calendar connections: ${e.toString()}',
      );
    }
  }

  Future<String?> getGoogleAuthUrl() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url = await _repository.getGoogleAuthUrl();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get Google auth URL: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> completeGoogleCallback(String code, String stateParam) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final connection = await _repository.completeGoogleCallback(
        code: code,
        state: stateParam,
      );
      final updatedConnections = [...state.connections];
      final existingIndex = updatedConnections.indexWhere((c) => c.isGoogle);
      if (existingIndex >= 0) {
        updatedConnections[existingIndex] = connection;
      } else {
        updatedConnections.add(connection);
      }
      state = state.copyWith(
        connections: updatedConnections,
        isLoading: false,
        successMessage: 'Google Calendar connected successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to connect Google Calendar: ${e.toString()}',
      );
      return false;
    }
  }

  Future<String?> getMicrosoftAuthUrl() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url = await _repository.getMicrosoftAuthUrl();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get Microsoft auth URL: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> completeMicrosoftCallback(String code, String stateParam) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final connection = await _repository.completeMicrosoftCallback(
        code: code,
        state: stateParam,
      );
      final updatedConnections = [...state.connections];
      final existingIndex = updatedConnections.indexWhere((c) => c.isMicrosoft);
      if (existingIndex >= 0) {
        updatedConnections[existingIndex] = connection;
      } else {
        updatedConnections.add(connection);
      }
      state = state.copyWith(
        connections: updatedConnections,
        isLoading: false,
        successMessage: 'Microsoft Calendar connected successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to connect Microsoft Calendar: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> disconnectCalendar(String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.disconnectCalendar(provider);
      final updatedConnections = state.connections
          .where((c) => c.provider != provider)
          .toList();
      state = state.copyWith(
        connections: updatedConnections,
        isLoading: false,
        successMessage: 'Calendar disconnected successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disconnect calendar: ${e.toString()}',
      );
    }
  }

  Future<void> syncCalendar(String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.syncCalendar(provider);
      final syncedCount = result['synced_count'] ?? 0;
      await loadConnections();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Synced $syncedCount events',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sync failed: ${e.toString()}',
      );
    }
  }

  Future<void> loadEvents({String? provider}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.getEvents(provider: provider);
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load events: ${e.toString()}',
      );
    }
  }

  Future<void> loadAvailability() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final availability = await _repository.getAvailability();
      state = state.copyWith(availability: availability, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load availability: ${e.toString()}',
      );
    }
  }

  Future<void> createAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final slot = await _repository.createAvailability(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );
      state = state.copyWith(
        availability: [...state.availability, slot],
        isLoading: false,
        successMessage: 'Availability slot created',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create availability: ${e.toString()}',
      );
    }
  }

  Future<void> deleteAvailability(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAvailability(id);
      final updatedAvailability = state.availability
          .where((a) => a.id != id)
          .toList();
      state = state.copyWith(
        availability: updatedAvailability,
        isLoading: false,
        successMessage: 'Availability slot deleted',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete availability: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  return CalendarNotifier(repository);
});

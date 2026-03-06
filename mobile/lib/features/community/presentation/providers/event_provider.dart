import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventRepository(apiClient);
});

// ── Trainee Event State ──

class EventListState {
  final List<CommunityEventModel> events;
  final bool isLoading;
  final String? error;

  const EventListState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventListState copyWith({
    List<CommunityEventModel>? events,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EventListState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<CommunityEventModel> get upcoming => events
      .where((e) => !e.isPast && !e.isCancelled)
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  List<CommunityEventModel> get past => events
      .where((e) => (e.isPast || e.isCompleted) && !e.isCancelled)
      .toList()
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  List<CommunityEventModel> get cancelled => events
      .where((e) => e.isCancelled)
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}

final traineeEventProvider =
    StateNotifierProvider.autoDispose<TraineeEventNotifier, EventListState>(
        (ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return TraineeEventNotifier(repo);
});

class TraineeEventNotifier extends StateNotifier<EventListState> {
  final EventRepository _repo;

  TraineeEventNotifier(this._repo) : super(const EventListState());

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repo.getEvents();
      state = state.copyWith(events: events, isLoading: false);
    } on DioException catch (e) {
      final message = e.response?.statusCode == 401
          ? 'Session expired. Please log in again.'
          : 'Failed to load events';
      state = state.copyWith(isLoading: false, error: message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load events',
      );
    }
  }

  Future<void> rsvp(int eventId, RsvpStatus status) async {
    final previousEvents = state.events;

    // Optimistic update
    state = state.copyWith(
      events: state.events.map((e) {
        if (e.id != eventId) return e;
        final oldStatus = RsvpStatus.fromApi(e.myRsvp);
        final newCounts = Map<String, int>.from(e.attendeeCounts);
        if (oldStatus != null) {
          final currentCount = newCounts[oldStatus.apiValue] ?? 0;
          newCounts[oldStatus.apiValue] =
              currentCount > 0 ? currentCount - 1 : 0;
        }
        newCounts[status.apiValue] = (newCounts[status.apiValue] ?? 0) + 1;
        return e.copyWith(myRsvp: status.apiValue, attendeeCounts: newCounts);
      }).toList(),
    );

    try {
      final updated = await _repo.rsvp(eventId, status);
      state = state.copyWith(
        events: state.events.map((e) {
          if (e.id != eventId) return e;
          return updated;
        }).toList(),
      );
    } on DioException catch (e) {
      final message = e.response?.statusCode == 409
          ? 'Event is at capacity'
          : 'Could not update RSVP. Try again.';
      state = state.copyWith(events: previousEvents, error: message);
    } catch (_) {
      state = state.copyWith(
        events: previousEvents,
        error: 'Could not update RSVP. Try again.',
      );
    }
  }
}

// ── Single Event Detail (API fallback for deep links) ──

final eventDetailProvider =
    FutureProvider.autoDispose.family<CommunityEventModel, int>(
  (ref, eventId) async {
    final repo = ref.watch(eventRepositoryProvider);
    return repo.getEventDetail(eventId);
  },
);

// ── Trainer Event State ──

final trainerEventProvider =
    StateNotifierProvider.autoDispose<TrainerEventNotifier, EventListState>(
        (ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return TrainerEventNotifier(repo);
});

class TrainerEventNotifier extends StateNotifier<EventListState> {
  final EventRepository _repo;

  TrainerEventNotifier(this._repo) : super(const EventListState());

  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repo.getTrainerEvents();
      state = state.copyWith(events: events, isLoading: false);
    } on DioException catch (e) {
      final message = e.response?.statusCode == 401
          ? 'Session expired. Please log in again.'
          : 'Failed to load events';
      state = state.copyWith(isLoading: false, error: message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load events',
      );
    }
  }

  Future<CommunityEventModel> createEvent({
    required String title,
    required String eventType,
    required DateTime startsAt,
    required DateTime endsAt,
    String description = '',
    String meetingUrl = '',
    int? maxAttendees,
  }) async {
    final event = await _repo.createEvent(
      title: title,
      eventType: eventType,
      startsAt: startsAt,
      endsAt: endsAt,
      description: description,
      meetingUrl: meetingUrl,
      maxAttendees: maxAttendees,
    );
    state = state.copyWith(events: [event, ...state.events]);
    return event;
  }

  Future<void> updateEvent(
    int eventId, {
    String? title,
    String? description,
    String? eventType,
    DateTime? startsAt,
    DateTime? endsAt,
    String? meetingUrl,
    int? maxAttendees,
    bool clearMaxAttendees = false,
  }) async {
    final updated = await _repo.updateEvent(
      eventId,
      title: title,
      description: description,
      eventType: eventType,
      startsAt: startsAt,
      endsAt: endsAt,
      meetingUrl: meetingUrl,
      maxAttendees: maxAttendees,
      clearMaxAttendees: clearMaxAttendees,
    );
    state = state.copyWith(
      events: state.events.map((e) => e.id == eventId ? updated : e).toList(),
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await _repo.deleteEvent(eventId);
    state = state.copyWith(
      events: state.events.where((e) => e.id != eventId).toList(),
    );
  }

  Future<void> cancelEvent(int eventId) async {
    final updated = await _repo.updateEventStatus(eventId, 'cancelled');
    state = state.copyWith(
      events: state.events.map((e) => e.id == eventId ? updated : e).toList(),
    );
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/food_search_model.dart';
import '../../data/repositories/food_search_repository.dart';

// Repository provider
final foodSearchRepositoryProvider = Provider<FoodSearchRepository>((ref) {
  return FoodSearchRepository();
});

// State class
class FoodSearchState {
  final String query;
  final List<FoodSearchResult> results;
  final bool isSearching;
  final String? error;
  final FoodSearchResult? selectedFood;

  const FoodSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
    this.selectedFood,
  });

  FoodSearchState copyWith({
    String? query,
    List<FoodSearchResult>? results,
    bool? isSearching,
    String? error,
    FoodSearchResult? selectedFood,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return FoodSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
      selectedFood: clearSelected ? null : (selectedFood ?? this.selectedFood),
    );
  }
}

// Notifier
class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  final FoodSearchRepository _repository;
  Timer? _debounceTimer;

  FoodSearchNotifier(this._repository) : super(const FoodSearchState());

  /// Search with debouncing for autocomplete
  void searchWithDebounce(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately
    state = state.copyWith(query: query, clearError: true);

    if (query.isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    // Show loading state
    state = state.copyWith(isSearching: true);

    // Debounce the actual search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Immediate search (for submit action)
  Future<void> search(String query) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = state.copyWith(results: [], query: '');
      return;
    }

    state = state.copyWith(query: query, isSearching: true, clearError: true);
    await _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    final response = await _repository.searchFood(query);

    if (response.hasError) {
      state = state.copyWith(
        isSearching: false,
        error: response.error,
        results: [],
      );
    } else {
      state = state.copyWith(
        isSearching: false,
        results: response.results,
      );
    }
  }

  /// Select a food item
  void selectFood(FoodSearchResult food) {
    state = state.copyWith(selectedFood: food);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  /// Clear all state
  void clearSearch() {
    _debounceTimer?.cancel();
    state = const FoodSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Provider
final foodSearchProvider =
    StateNotifierProvider<FoodSearchNotifier, FoodSearchState>((ref) {
  final repository = ref.watch(foodSearchRepositoryProvider);
  return FoodSearchNotifier(repository);
});

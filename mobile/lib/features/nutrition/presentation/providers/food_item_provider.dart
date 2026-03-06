import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/food_item_repository.dart';

// Repository provider
final foodItemRepositoryProvider = Provider<FoodItemRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FoodItemRepository(apiClient);
});

// State
class FoodItemSearchState {
  final String query;
  final List<FoodItemModel> results;
  final List<FoodItemModel> recentItems;
  final bool isSearching;
  final bool isLoadingRecent;
  final String? error;
  final FoodItemModel? selectedItem;

  const FoodItemSearchState({
    this.query = '',
    this.results = const [],
    this.recentItems = const [],
    this.isSearching = false,
    this.isLoadingRecent = false,
    this.error,
    this.selectedItem,
  });

  FoodItemSearchState copyWith({
    String? query,
    List<FoodItemModel>? results,
    List<FoodItemModel>? recentItems,
    bool? isSearching,
    bool? isLoadingRecent,
    String? error,
    FoodItemModel? selectedItem,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return FoodItemSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentItems: recentItems ?? this.recentItems,
      isSearching: isSearching ?? this.isSearching,
      isLoadingRecent: isLoadingRecent ?? this.isLoadingRecent,
      error: clearError ? null : (error ?? this.error),
      selectedItem: clearSelected ? null : (selectedItem ?? this.selectedItem),
    );
  }
}

// Notifier
class FoodItemSearchNotifier extends StateNotifier<FoodItemSearchState> {
  final FoodItemRepository _repository;
  Timer? _debounceTimer;

  FoodItemSearchNotifier(this._repository) : super(const FoodItemSearchState());

  /// Load recently used food items.
  Future<void> loadRecent() async {
    state = state.copyWith(isLoadingRecent: true);
    final result = await _repository.getRecent();

    if (result['success'] == true) {
      state = state.copyWith(
        recentItems: result['items'] as List<FoodItemModel>,
        isLoadingRecent: false,
      );
    } else {
      state = state.copyWith(isLoadingRecent: false);
    }
  }

  /// Search with debouncing (300ms).
  void searchWithDebounce(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, clearError: true);

    if (query.length < 2) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final result = await _repository.search(query);

    if (result['success'] == true) {
      state = state.copyWith(
        results: result['items'] as List<FoodItemModel>,
        isSearching: false,
      );
    } else {
      state = state.copyWith(
        isSearching: false,
        error: result['error'] as String?,
        results: [],
      );
    }
  }

  /// Look up a barcode.
  Future<FoodItemModel?> lookupBarcode(String barcode) async {
    final result = await _repository.getByBarcode(barcode);
    if (result['success'] == true) {
      return result['item'] as FoodItemModel;
    }
    return null;
  }

  /// Select a food item.
  void selectItem(FoodItemModel item) {
    state = state.copyWith(selectedItem: item);
  }

  /// Clear selection.
  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  /// Clear all state.
  void clearSearch() {
    _debounceTimer?.cancel();
    state = const FoodItemSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Provider
final foodItemSearchProvider =
    StateNotifierProvider<FoodItemSearchNotifier, FoodItemSearchState>((ref) {
  final repository = ref.watch(foodItemRepositoryProvider);
  return FoodItemSearchNotifier(repository);
});

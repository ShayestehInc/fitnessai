import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/food_lookup_model.dart';
import '../../data/repositories/barcode_repository.dart';

/// Provides a singleton [BarcodeRepository] backed by the shared [ApiClient].
final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BarcodeRepository(apiClient);
});

/// Looks up a food product by barcode.
///
/// Usage:
/// ```dart
/// final asyncFood = ref.watch(barcodeLookupProvider('0123456789'));
/// ```
final barcodeLookupProvider =
    FutureProvider.family<FoodLookupModel, String>((ref, barcode) async {
  final repository = ref.watch(barcodeRepositoryProvider);
  return repository.lookupBarcode(barcode);
});

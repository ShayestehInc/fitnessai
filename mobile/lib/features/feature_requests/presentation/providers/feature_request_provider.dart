import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/feature_request_model.dart';
import '../../data/repositories/feature_request_repository.dart';

// Repository provider
final featureRequestRepositoryProvider = Provider<FeatureRequestRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FeatureRequestRepository(apiClient);
});

// Feature requests list provider
final featureRequestsProvider = FutureProvider.autoDispose.family<List<FeatureRequestModel>, Map<String, dynamic>?>((ref, params) async {
  final repository = ref.watch(featureRequestRepositoryProvider);
  final result = await repository.getFeatureRequests(
    status: params?['status'],
    category: params?['category'],
    search: params?['search'],
    sort: params?['sort'] ?? 'votes',
  );
  if (result['success']) {
    return result['data'] as List<FeatureRequestModel>;
  }
  return [];
});

// Single feature request provider
final featureRequestDetailProvider = FutureProvider.autoDispose.family<FeatureRequestModel?, int>((ref, featureId) async {
  final repository = ref.watch(featureRequestRepositoryProvider);
  final result = await repository.getFeatureRequest(featureId);
  if (result['success']) {
    return result['data'] as FeatureRequestModel;
  }
  return null;
});

// Comments provider
final featureCommentsProvider = FutureProvider.autoDispose.family<List<FeatureCommentModel>, int>((ref, featureId) async {
  final repository = ref.watch(featureRequestRepositoryProvider);
  final result = await repository.getComments(featureId);
  if (result['success']) {
    return result['data'] as List<FeatureCommentModel>;
  }
  return [];
});

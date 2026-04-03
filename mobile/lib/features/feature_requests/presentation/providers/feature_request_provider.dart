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

class FeatureRequestFilterParams {
  final String? category;
  final String? status;
  final String? search;
  final String sort;

  const FeatureRequestFilterParams({
    this.category,
    this.status,
    this.search,
    this.sort = 'votes',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureRequestFilterParams &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          status == other.status &&
          search == other.search &&
          sort == other.sort;

  @override
  int get hashCode => Object.hash(category, status, search, sort);
}

// Feature requests list provider
final featureRequestsProvider = FutureProvider.autoDispose.family<List<FeatureRequestModel>, FeatureRequestFilterParams>((ref, params) async {
  final repository = ref.watch(featureRequestRepositoryProvider);
  final result = await repository.getFeatureRequests(
    status: params.status,
    category: params.category,
    search: params.search,
    sort: params.sort,
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

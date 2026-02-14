import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ambassador_models.dart';

class AmbassadorRepository {
  final ApiClient _apiClient;

  AmbassadorRepository(this._apiClient);

  Future<AmbassadorDashboardData> getDashboard() async {
    final response = await _apiClient.dio.get(ApiConstants.ambassadorDashboard);
    return AmbassadorDashboardData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AmbassadorReferral>> getReferrals({String? status, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;

    final response = await _apiClient.dio.get(
      ApiConstants.ambassadorReferrals,
      queryParameters: params,
    );

    final results = response.data['results'] as List<dynamic>? ?? response.data as List<dynamic>;
    return results
        .map((e) => AmbassadorReferral.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReferralCodeData> getReferralCode() async {
    final response = await _apiClient.dio.get(ApiConstants.ambassadorReferralCode);
    return ReferralCodeData.fromJson(response.data as Map<String, dynamic>);
  }

  // Admin endpoints

  Future<List<AmbassadorProfile>> getAmbassadors({String? search, bool? isActive}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (isActive != null) params['is_active'] = isActive.toString();

    final response = await _apiClient.dio.get(
      ApiConstants.adminAmbassadors,
      queryParameters: params,
    );

    final results = response.data['results'] as List<dynamic>? ?? response.data as List<dynamic>;
    return results
        .map((e) => AmbassadorProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AmbassadorProfile> createAmbassador({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required double commissionRate,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.adminCreateAmbassador,
      data: {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'commission_rate': commissionRate.toStringAsFixed(2),
      },
    );
    return AmbassadorProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AmbassadorDetailData> getAmbassadorDetail(int id) async {
    final response = await _apiClient.dio.get(ApiConstants.adminAmbassadorDetail(id));
    return AmbassadorDetailData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AmbassadorProfile> updateAmbassador(int id, {double? commissionRate, bool? isActive}) async {
    final data = <String, dynamic>{};
    if (commissionRate != null) data['commission_rate'] = commissionRate.toStringAsFixed(2);
    if (isActive != null) data['is_active'] = isActive;

    final response = await _apiClient.dio.put(
      ApiConstants.adminAmbassadorDetail(id),
      data: data,
    );
    return AmbassadorProfile.fromJson(response.data as Map<String, dynamic>);
  }
}

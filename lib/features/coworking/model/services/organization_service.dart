import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/features/coworking/model/organization.dart';

class OrganizationService {
  final ApiClient _apiClient;

  OrganizationService(this._apiClient);

  Future<OrganizationsResponse> getOrganizations({
    required String buildingId,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/aina/organizations',
        queryParameters: {
          'building_id': buildingId,
          'page': page.toString(),
        },
      );
      return OrganizationsResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

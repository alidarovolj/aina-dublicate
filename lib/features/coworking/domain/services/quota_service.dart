import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/quota.dart';

class QuotaService {
  final ApiClient _apiClient;

  QuotaService(this._apiClient);

  Future<List<Quota>> getQuotas(
      {int page = 1, int perPage = 10, String stateGroup = 'ACTIVE'}) async {
    final response = await _apiClient.dio.get(
      '/api/promenade/orders',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'state_group': stateGroup,
      },
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Quota.fromJson(json)).toList();
    }

    return [];
  }
}

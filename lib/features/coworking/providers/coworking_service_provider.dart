import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';

class CoworkingServiceService {
  final _apiClient = ApiClient();

  Future<CoworkingService> getServiceDetails(int categoryId) async {
    final response = await _apiClient.dio
        .get('/api/promenade/services/categories/$categoryId');

    if (response.data['success']) {
      return CoworkingService.fromJson(response.data['data']);
    }

    throw Exception('Failed to load service details');
  }

  Future<List<CoworkingTariff>> getTariffs(int categoryId) async {
    final response = await _apiClient.dio.get(
      '/api/promenade/services',
      queryParameters: {'category_id': categoryId},
    );

    if (response.data['success']) {
      return (response.data['data'] as List)
          .map((json) => CoworkingTariff.fromJson(json))
          .toList();
    }

    throw Exception('Failed to load tariffs');
  }
}

final coworkingServiceServiceProvider =
    Provider<CoworkingServiceService>((ref) => CoworkingServiceService());

final coworkingServiceProvider =
    FutureProvider.family<CoworkingService, int>((ref, categoryId) async {
  final service = ref.watch(coworkingServiceServiceProvider);
  return service.getServiceDetails(categoryId);
});

final coworkingTariffsProvider =
    FutureProvider.family<List<CoworkingTariff>, int>((ref, categoryId) async {
  final service = ref.watch(coworkingServiceServiceProvider);
  return service.getTariffs(categoryId);
});

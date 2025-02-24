import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/coworking_service.dart';

class CoworkingServiceService {
  final _apiClient = ApiClient();

  Future<CoworkingService> getServiceDetails(int serviceId) async {
    print('Getting service details for ID: $serviceId');

    // First try to get category details
    try {
      final response = await _apiClient.dio
          .get('/api/promenade/services/categories/$serviceId');

      if (response.data['success']) {
        print('Successfully got category details');
        return CoworkingService.fromJson(response.data['data']);
      }
    } catch (e) {
      print('Failed to get category details: $e');
    }

    // If category not found or failed, try getting service details
    try {
      final response =
          await _apiClient.dio.get('/api/promenade/services/$serviceId');

      if (response.data['success']) {
        print('Successfully got service details');
        return CoworkingService.fromJson(response.data['data']);
      }
    } catch (e) {
      print('Failed to get service details: $e');
    }

    throw Exception('Failed to load service details');
  }

  Future<List<CoworkingTariff>> getTariffs(int categoryId) async {
    print('Getting tariffs for category $categoryId');
    final response = await _apiClient.dio.get(
      '/api/promenade/services',
      queryParameters: {'category_id': categoryId},
    );

    if (response.data['success']) {
      final tariffs = (response.data['data'] as List)
          .map((json) => CoworkingTariff.fromJson(json))
          .toList();
      print('Successfully got ${tariffs.length} tariffs');
      return tariffs;
    }

    throw Exception('Failed to load tariffs');
  }

  Future<CoworkingTariff> getTariffDetails(int tariffId) async {
    print('Getting specific tariff details for ID: $tariffId');
    final response =
        await _apiClient.dio.get('/api/promenade/services/$tariffId');

    if (response.data['success']) {
      print('Successfully got tariff details');
      return CoworkingTariff.fromJson(response.data['data']);
    }

    throw Exception('Failed to load tariff details');
  }
}

final coworkingServiceServiceProvider =
    Provider<CoworkingServiceService>((ref) => CoworkingServiceService());

final coworkingServiceProvider =
    FutureProvider.family<CoworkingService, int>((ref, categoryId) async {
  final service = ref.read(coworkingServiceServiceProvider);
  return service.getServiceDetails(categoryId);
});

final coworkingTariffsProvider =
    FutureProvider.family<List<CoworkingTariff>, int>((ref, categoryId) async {
  final service = ref.read(coworkingServiceServiceProvider);
  return service.getTariffs(categoryId);
});

final coworkingTariffDetailsProvider =
    FutureProvider.family<CoworkingTariff, int>((ref, tariffId) async {
  final service = ref.read(coworkingServiceServiceProvider);
  return service.getTariffDetails(tariffId);
});

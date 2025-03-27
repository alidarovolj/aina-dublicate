import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/pages/coworking/domain/models/coworking_service.dart';
import 'package:flutter/foundation.dart';

class CoworkingServiceService {
  final _apiClient = ApiClient();

  Future<CoworkingService> getServiceDetails(int serviceId) async {
    // First try to get category details
    try {
      final response = await _apiClient.dio
          .get('/api/promenade/services/categories/$serviceId');

      if (response.data['success']) {
        return CoworkingService.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Failed to get category details: $e');
    }

    // If category not found or failed, try getting service details
    try {
      final response =
          await _apiClient.dio.get('/api/promenade/services/$serviceId');

      if (response.data['success']) {
        return CoworkingService.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Failed to get service details: $e');
    }

    throw Exception('Failed to load service details');
  }

  Future<List<CoworkingTariff>> getTariffs(int categoryId) async {
    final response = await _apiClient.dio.get(
      '/api/promenade/services',
      queryParameters: {'category_id': categoryId},
    );

    if (response.data['success']) {
      final tariffs = (response.data['data'] as List)
          .map((json) => CoworkingTariff.fromJson(json))
          .toList();
      return tariffs;
    }

    throw Exception('Failed to load tariffs');
  }

  Future<CoworkingTariff> getTariffDetails(int tariffId) async {
    final response =
        await _apiClient.dio.get('/api/promenade/services/$tariffId');

    if (response.data['success']) {
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

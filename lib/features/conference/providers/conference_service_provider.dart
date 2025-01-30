import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/conference/domain/models/conference_service.dart';

class ConferenceServiceService {
  final _apiClient = ApiClient();

  Future<ConferenceService> getServiceDetails(int categoryId) async {
    final response = await _apiClient.dio
        .get('/api/promenade/services/categories/$categoryId');

    if (response.data['success']) {
      return ConferenceService.fromJson(response.data['data']);
    }

    throw Exception('Failed to load service details');
  }

  Future<List<ConferenceTariff>> getTariffs(int categoryId) async {
    final response = await _apiClient.dio.get(
      '/api/promenade/services',
      queryParameters: {'category_id': categoryId},
    );

    if (response.data['success']) {
      return (response.data['data'] as List)
          .map((json) => ConferenceTariff.fromJson(json))
          .toList();
    }

    throw Exception('Failed to load tariffs');
  }
}

final conferenceServiceServiceProvider =
    Provider<ConferenceServiceService>((ref) => ConferenceServiceService());

final conferenceServiceProvider =
    FutureProvider.family<ConferenceService, int>((ref, categoryId) async {
  final service = ref.watch(conferenceServiceServiceProvider);
  return service.getServiceDetails(categoryId);
});

final conferenceTariffsProvider =
    FutureProvider.family<List<ConferenceTariff>, int>((ref, categoryId) async {
  final service = ref.watch(conferenceServiceServiceProvider);
  return service.getTariffs(categoryId);
});

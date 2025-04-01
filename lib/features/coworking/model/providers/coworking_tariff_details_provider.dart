import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/features/coworking/model/models/coworking_tariff_details.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/app/providers/api_client_provider.dart';

final coworkingTariffDetailsProvider = StateNotifierProvider.autoDispose<
    CoworkingTariffDetailsNotifier, AsyncValue<CoworkingTariffDetails?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoworkingTariffDetailsNotifier(apiClient);
});

class CoworkingTariffDetailsNotifier
    extends StateNotifier<AsyncValue<CoworkingTariffDetails?>> {
  final ApiClient _apiClient;

  CoworkingTariffDetailsNotifier(this._apiClient)
      : super(const AsyncValue.data(null));

  Future<void> fetchTariffDetails(int tariffId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.get(
        '/api/promenade/services/$tariffId',
      );

      if (response.data['success'] == true) {
        final tariffDetails = CoworkingTariffDetails.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        state = AsyncValue.data(tariffDetails);
      } else {
        state = AsyncValue.error(
          'Failed to load tariff details',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

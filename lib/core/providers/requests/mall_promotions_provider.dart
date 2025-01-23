import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/providers/requests/promotions/mall_list.dart';

class MallPromotionsProvider
    extends StateNotifier<AsyncValue<List<Promotion>>> {
  MallPromotionsProvider(this._service, this.mallId)
      : super(const AsyncValue.loading()) {
    fetchMallPromotions();
  }

  final RequestMallPromotionsService _service;
  final String mallId;

  Future<void> fetchMallPromotions() async {
    try {
      state = const AsyncValue.loading();
      final response = await _service.mallPromotions(mallId);

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch mall promotions');
      }

      print('Mall promotions API Response data: ${response.data['data']}');

      final List<Promotion> promotions = (response.data['data'] as List)
          .map((json) {
            try {
              return Promotion.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing mall promotion: $e');
              print('Problematic JSON: $json');
              return null;
            }
          })
          .whereType<Promotion>() // Filter out null values
          .toList();

      state = AsyncValue.data(promotions);
      print('Mall promotions fetched successfully: ${promotions.length} items');
    } catch (error, stackTrace) {
      print('Error fetching mall promotions: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final mallPromotionsProvider = StateNotifierProvider.family<
    MallPromotionsProvider, AsyncValue<List<Promotion>>, String>(
  (ref, mallId) =>
      MallPromotionsProvider(ref.read(requestMallPromotionsProvider), mallId),
);

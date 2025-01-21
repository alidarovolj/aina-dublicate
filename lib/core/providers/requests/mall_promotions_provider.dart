import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/providers/requests/promotions/mall_list.dart';

class MallPromotionsProvider
    extends StateNotifier<AsyncValue<List<Promotion>>> {
  MallPromotionsProvider(this._listService, this.mallId)
      : super(const AsyncValue.loading()) {
    fetchMallPromotions();
  }

  final RequestMallPromotionsService _listService;
  final String mallId;

  Future<void> fetchMallPromotions() async {
    try {
      print('Fetching mall promotions...');
      final response = await _listService.mallPromotions(mallId);

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch mall promotions');
      }

      // Debug print
      print('API Response data: ${response.data['data']}');

      final List<Promotion> promotions = (response.data['data'] as List)
          .map((json) => Promotion.fromJson(json))
          .toList();
      state = AsyncValue.data(promotions);
      print('Mall promotions fetched successfully.');
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

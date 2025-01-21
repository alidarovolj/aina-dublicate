import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/providers/requests/promotions/list.dart';

class PromotionsProvider extends StateNotifier<AsyncValue<List<Promotion>>> {
  PromotionsProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchPromotions();
  }

  final RequestPromotionsService _listService;

  Future<void> fetchPromotions() async {
    try {
      print('Fetching promotions...');
      final response = await _listService.promotions();

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch promotions');
      }

      final List<Promotion> promotions = (response.data['data'] as List)
          .map((json) => Promotion.fromJson(json))
          .toList();
      state = AsyncValue.data(promotions);
      print('Promotions fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching promotions: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final promotionsProvider =
    StateNotifierProvider<PromotionsProvider, AsyncValue<List<Promotion>>>(
  (ref) => PromotionsProvider(ref.read(requestPromotionsProvider)),
);

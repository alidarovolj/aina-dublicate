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

      print('API Response data: ${response.data['data']}');

      final List<Promotion> promotions = (response.data['data'] as List)
          .map((json) {
            try {
              return Promotion.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing promotion: $e');
              print('Problematic JSON: $json');
              return null;
            }
          })
          .whereType<Promotion>() // Filter out null values
          .toList();

      state = AsyncValue.data(promotions);
      print('Promotions fetched successfully: ${promotions.length} items');
    } catch (error, stackTrace) {
      print('Error fetching promotions: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool _isValidPromotionData(dynamic json) {
    try {
      // Add validation for required fields
      return json['id'] != null &&
          json['name'] != null &&
          json['order'] != null; // Add other required fields
    } catch (e) {
      print('Invalid promotion data: $json');
      return false;
    }
  }
}

final promotionsProvider =
    StateNotifierProvider<PromotionsProvider, AsyncValue<List<Promotion>>>(
  (ref) => PromotionsProvider(ref.read(requestPromotionsProvider)),
);

final qrPromotionsProvider = Provider<AsyncValue<List<Promotion>>>((ref) {
  final promotionsAsync = ref.watch(promotionsProvider);

  return promotionsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (promotions) {
      final qrPromotions = promotions.where((p) => p.isQr == true).toList();
      return AsyncValue.data(qrPromotions);
    },
  );
});

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
      // // print('Fetching promotions...');
      final response = await _listService.promotions();

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch promotions');
      }

      // // print('API Response data: ${response.data['data']}');

      final rawList = response.data['data'] as List;
      // // print('Raw promotions count: ${rawList.length}');

      final List<Promotion> promotions = rawList
          .map((json) {
            try {
              // // print(
              //     'Processing promotion: ${json['name']} (ID: ${json['id']})');
              return Promotion.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              // // print('Error parsing promotion: $e');
              // // print('Problematic JSON: $json');
              return null;
            }
          })
          .whereType<Promotion>() // Filter out null values
          .toList();

      // // print('Successfully parsed promotions count: ${promotions.length}');
      // // print(
      //     'Final promotions list: ${promotions.map((p) => '${p.name} (ID: ${p.id})').join(', ')}');

      state = AsyncValue.data(promotions);
    } catch (error, stackTrace) {
      // // print('Error fetching promotions: $error');
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
      // // print('Invalid promotion data: $json');
      return false;
    }
  }
}

final promotionsProvider =
    StateNotifierProvider<PromotionsProvider, AsyncValue<List<Promotion>>>(
  (ref) => PromotionsProvider(ref.read(requestPromotionsProvider)),
);

final sortedPromotionsProvider = Provider<AsyncValue<List<Promotion>>>((ref) {
  final promotionsAsync = ref.watch(promotionsProvider);

  return promotionsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (promotions) {
      final sortedPromotions = List<Promotion>.from(promotions)
        ..sort((a, b) {
          // Handle cases where isQr might be null
          final aIsQr = a.isQr ?? false;
          final bIsQr = b.isQr ?? false;
          if (aIsQr == bIsQr) return 0;
          return aIsQr ? -1 : 1; // QR promotions come first
        });
      return AsyncValue.data(sortedPromotions);
    },
  );
});

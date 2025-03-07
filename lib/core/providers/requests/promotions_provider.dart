import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/providers/requests/promotions/list.dart';
import 'package:flutter/material.dart';

class PromotionsProvider extends StateNotifier<AsyncValue<List<Promotion>>> {
  PromotionsProvider(this._listService) : super(const AsyncValue.loading());

  final RequestPromotionsService _listService;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchPromotions(BuildContext context,
      {bool forceRefresh = false}) async {
    if (!_mounted) return;

    try {
      if (!_mounted) return;
      state = const AsyncValue.loading();

      final response =
          await _listService.promotions(context, forceRefresh: forceRefresh);

      if (!_mounted) return;

      if (!response.data['success']) {
        throw Exception(
            'Failed to fetch promotions: ${response.data['message']}');
      }

      final rawList = response.data['data'] as List;
      final List<Promotion> promotions = rawList
          .map((json) => Promotion.fromJson(json as Map<String, dynamic>))
          .where((promotion) => _isValidPromotionData(promotion))
          .toList();

      if (!_mounted) return;
      state = AsyncValue.data(promotions);
    } catch (error, stackTrace) {
      if (!_mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool _isValidPromotionData(Promotion promotion) {
    return promotion.order != null;
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
          final aIsQr = a.isQr ?? false;
          final bIsQr = b.isQr ?? false;
          if (aIsQr == bIsQr) return 0;
          return aIsQr ? -1 : 1;
        });
      return AsyncValue.data(sortedPromotions);
    },
  );
});

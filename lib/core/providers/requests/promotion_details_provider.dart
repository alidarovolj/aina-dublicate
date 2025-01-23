import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/providers/requests/promotions/details.dart';

final promotionDetailsProvider =
    FutureProvider.family<Promotion, String>((ref, id) async {
  final detailsService = ref.read(requestPromotionDetailsProvider);
  final response = await detailsService.promotionDetails(id);

  if (response == null || !response.data['success']) {
    throw Exception('Failed to fetch promotion details');
  }

  return Promotion.fromJson(response.data['data']);
});

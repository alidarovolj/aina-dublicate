import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/types/promotion.dart';

final mallPromotionsProvider = FutureProvider.family<List<Promotion>, String>(
  (ref, mallId) async {
    try {
      final response = await ApiClient().dio.get(
          '/api/aina/buildings/$mallId/posts',
          queryParameters: {'is_qr': false});

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];

        final List<dynamic> promotions = data['promotions'] ?? [];

        final List<Promotion> parsedPromotions = [];
        for (var json in promotions) {
          try {
            final promotion = Promotion.fromJson(json);
            parsedPromotions.add(promotion);
          } catch (e) {
            debugPrint('❌ Ошибка при парсинге промо: $e');
          }
        }
        return parsedPromotions;
      }
      return [];
    } catch (e) {
      return [];
    }
  },
);

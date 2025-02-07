import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/types/promotion.dart';

final mallPromotionsProvider = FutureProvider.family<List<Promotion>, String>(
  (ref, mallId) async {
    try {
      // print('=================== MALL PROMOTIONS PROVIDER ===================');
      // print('Fetching promotions for mall ID: $mallId');
      final response = await ApiClient().dio.get(
          '/api/aina/buildings/$mallId/posts',
          queryParameters: {'is_qr': false});

      // print('API Response raw: ${response.data}');
      // print('API Response success: ${response.data['success']}');
      // print('API Response data exists: ${response.data['data'] != null}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        // print('API Response data: $data');

        final List<dynamic> promotions = data['promotions'] ?? [];
        // print('Raw promotions list: $promotions');

        // print('Found ${promotions.length} promotions in response');
        for (var json in promotions) {
          // print('Raw promotion data:');
          // print('- ID: ${json['id']}');
          // print('- Title: ${json['title']}');
          // print('- Preview Image: ${json['preview_image']}');
          // print('- Start Date: ${json['start_at']}');
          // print('- End Date: ${json['end_at']}');
          // print('- Is QR: ${json['is_qr']}');
        }

        final List<Promotion> parsedPromotions = [];
        for (var json in promotions) {
          try {
            // print(
            // 'Processing promotion: ${json['title']} (Is QR: ${json['is_qr']})');
            final promotion = Promotion.fromJson(json);
            parsedPromotions.add(promotion);
            // print('Successfully added promotion: ${promotion.title}');
            // print('- Preview Image URL: ${promotion.previewImage?.url}');
            // print('- Date Range: ${promotion.formattedDateRange}');
            // print('- Is QR: ${promotion.isQr}');
          } catch (e) {
            // print('Error parsing promotion: $e');
            // print('Stack trace: $stack');
            // print('Problematic JSON: $json');
          }
        }

        // print('Successfully parsed ${parsedPromotions.length} promotions');
        // print('Final promotions list:');
        // for (var promo in parsedPromotions) {
        //   // print('- ${promo.title} (Is QR: ${promo.isQr})');
        // }
        // print(
        //     '=================== END MALL PROMOTIONS PROVIDER ===================');
        return parsedPromotions;
      }

      // print('No promotions found in response');
      // print(
      //     '=================== END MALL PROMOTIONS PROVIDER ===================');
      return [];
    } catch (e) {
      // print('Error fetching promotions: $e');
      // print('Stack trace: $stack');
      // print(
      //     '=================== END MALL PROMOTIONS PROVIDER WITH ERROR ===================');
      return [];
    }
  },
);

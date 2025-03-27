import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/promotion.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';

final eventDetailsProvider =
    FutureProvider.family<Promotion, String>((ref, id) async {
  try {
    final response = await ApiClient().dio.get(
          '/api/aina/events/$id',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Accept-Language': 'ru',
              'Language': 'ru',
            },
          ),
        );

    if (!response.data['success']) {
      throw Exception(
          'Failed to fetch event details: ${response.data['message']}');
    }

    return Promotion.fromJson({
      ...response.data['data'],
      'start_at': response.data['data']['created_at'],
      'end_at': response.data['data']['created_at'],
      'is_qr': false,
    });
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      throw Exception('Event not found');
    }
    rethrow;
  } catch (e) {
    rethrow;
  }
});

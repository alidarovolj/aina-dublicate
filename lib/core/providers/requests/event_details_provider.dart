import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/promotion.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    print('❌ DioError fetching event details: $e');
    if (e.response?.statusCode == 404) {
      throw Exception('Event not found');
    }
    rethrow;
  } catch (e) {
    print('❌ Error fetching event details: $e');
    rethrow;
  }
});

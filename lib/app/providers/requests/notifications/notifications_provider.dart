import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:aina_flutter/shared/api/api_client.dart';

/// Провайдер для получения списка уведомлений пользователя
final notificationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiClient().dio.get(
          '/api/aina/notifications',
          options: Options(
            headers: {'force-refresh': 'true'},
          ),
        );

    if (response.data['success'] == true) {
      return response.data;
    }

    throw Exception(
        'Failed to fetch notifications: ${response.data['message']}');
  } catch (e) {
    throw Exception('Error fetching notifications: $e');
  }
});

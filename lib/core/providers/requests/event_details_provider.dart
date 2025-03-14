import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/types/event.dart';

final eventDetailsProvider = FutureProvider.family<Event, String>(
  (ref, id) async {
    try {
      final response = await ApiClient().dio.get('/api/aina/events/$id');

      if (response.data['success'] == true && response.data['data'] != null) {
        return Event.fromJson(response.data['data']);
      }

      throw Exception('Failed to fetch event details');
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  },
);

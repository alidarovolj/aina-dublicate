import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/event.dart';
import 'package:aina_flutter/core/services/api_service.dart';

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get('/api/aina/events');

  if (response.statusCode == 200 && response.data['success'] == true) {
    final List<dynamic> data = response.data['data']['data'];
    return data.map((json) => Event.fromJson(json)).toList();
  }

  throw Exception(response.data['message'] ?? 'Failed to load events');
});

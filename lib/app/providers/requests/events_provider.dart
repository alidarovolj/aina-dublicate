import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/types/promotion.dart';

class EventsNotifier extends StateNotifier<AsyncValue<List<Promotion>>> {
  EventsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchEvents(BuildContext context,
      {bool forceRefresh = false}) async {
    try {
      state = const AsyncValue.loading();
      final response = await ApiClient().dio.get('/api/aina/events');

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> eventsData = response.data['data'];
        final events =
            eventsData.map((data) => Promotion.fromJson(data)).toList();
        state = AsyncValue.data(events);
      } else {
        state = AsyncValue.error(
          'Failed to load events',
          StackTrace.current,
        );
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<Promotion>>>(
  (ref) => EventsNotifier(),
);

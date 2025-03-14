import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/event.dart';
import 'package:aina_flutter/core/providers/requests/events/mall_list.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/types/promotion.dart';

class MallEventsProvider extends StateNotifier<AsyncValue<List<Event>>> {
  MallEventsProvider(this._listService, this.mallId)
      : super(const AsyncValue.loading()) {
    fetchMallEvents();
  }

  final RequestMallEventsService _listService;
  final String mallId;

  Future<void> fetchMallEvents() async {
    try {
      final response = await _listService.mallEvents(mallId);

      if (response == null || !response.data['success']) {
        throw Exception('Failed to fetch mall events');
      }

      final List<Event> events = (response.data['data']['data'] as List)
          .map((json) => Event.fromJson(json))
          .toList();
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final mallEventsProvider = StateNotifierProvider.family<MallEventsProvider,
    AsyncValue<List<Event>>, String>(
  (ref, mallId) =>
      MallEventsProvider(ref.read(requestMallEventsProvider), mallId),
);

final mallEventsPromotionProvider =
    FutureProvider.family<List<Promotion>, String>(
  (ref, mallId) async {
    try {
      final response = await ApiClient().dio.get(
          '/api/aina/buildings/$mallId/posts',
          queryParameters: {'is_qr': false});

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        final List<dynamic> events = data['events'] ?? [];

        final List<Promotion> parsedEvents = [];
        for (var json in events) {
          try {
            final event = Promotion.fromJson({
              ...json,
              'start_at': json['created_at'],
              'end_at': json['created_at'],
              'is_qr': false,
            });
            parsedEvents.add(event);
          } catch (e) {
            // Handle error silently
          }
        }

        return parsedEvents;
      }

      return [];
    } catch (e) {
      return [];
    }
  },
);

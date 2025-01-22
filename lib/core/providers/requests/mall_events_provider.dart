import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/event.dart';
import 'package:aina_flutter/core/providers/requests/events/mall_list.dart';

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

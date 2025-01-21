import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/stories_type.dart';
import 'package:aina_flutter/core/providers/requests/stories/list.dart';

class StoriesProvider extends StateNotifier<AsyncValue<List<Story>>> {
  StoriesProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchStories();
  }

  final RequestCodeService _listService;

  Future<void> fetchStories() async {
    try {
      print('Fetching stories...');
      final response = await _listService.stories();

      if (response == null) {
        throw Exception('Failed to fetch stories');
      }

      print('Response: ${response.data}');
      final List<Story> stories = (response.data['data'] as List)
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(stories);
      print('Stories fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching stories: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final storiesProvider =
    StateNotifierProvider<StoriesProvider, AsyncValue<List<Story>>>(
  (ref) => StoriesProvider(ref.read(requestCodeProvider)),
);

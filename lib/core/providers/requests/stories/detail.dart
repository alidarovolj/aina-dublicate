import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/types/stories_type.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class StoryDetailService {
  final ApiClient _apiClient;

  StoryDetailService(this._apiClient);

  Future<Story?> getStoryDetail(int storyId) async {
    try {
      final response = await _apiClient.dio.get('/api/aina/stories/$storyId');
      if (response.data != null) {
        return Story.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}

final storyDetailServiceProvider = Provider<StoryDetailService>((ref) {
  return StoryDetailService(ref.watch(apiClientProvider));
});

final storyDetailProvider =
    FutureProvider.family<Story?, int>((ref, storyId) async {
  final service = ref.watch(storyDetailServiceProvider);
  return service.getStoryDetail(storyId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/types/stories_type.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:dio/dio.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class StoryDetailService {
  final ApiClient _apiClient;

  StoryDetailService(this._apiClient);

  Future<String?> _getAuthHeader() async {
    final token = await StorageService.getToken();
    return token != null ? 'Bearer $token' : null;
  }

  Future<Story?> getStoryDetail(int storyId) async {
    try {
      final response = await _apiClient.dio.get('/api/aina/stories/$storyId');
      if (response.data != null) {
        return Story.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      // Не логируем 404 ошибки как критические - это нормально для статических историй
      if (e.toString().contains('404')) {
        print(
            'ℹ️ История $storyId не найдена на сервере (статическая история)');
        return null;
      }
      rethrow;
    }
  }

  Future<bool> markStoryAsViewed(int storyId) async {
    try {
      // Сохраняем статус просмотра в локальное хранилище
      await StorageService.setStoryViewed(storyId);

      print('📖 Локально отмечена история $storyId как просмотренная');
      return true;
    } catch (e) {
      print('❌ Ошибка при отметке истории как просмотренной: $e');
      return false;
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

final markStoryViewedProvider =
    FutureProvider.family<bool, int>((ref, storyId) async {
  final service = ref.watch(storyDetailServiceProvider);
  return service.markStoryAsViewed(storyId);
});

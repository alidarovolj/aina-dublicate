import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/types/stories_type.dart';
import 'package:aina_flutter/app/providers/requests/stories/list.dart';
import 'package:aina_flutter/app/providers/requests/stories/detail.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class StoriesProvider extends StateNotifier<AsyncValue<List<Story>>> {
  StoriesProvider(this._listService) : super(const AsyncValue.loading()) {
    fetchStories();
  }

  final RequestCodeService _listService;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void markAsViewed(int storyId) async {
    await StorageService.setStoryViewed(storyId);
    final currentState = state;
    if (currentState is AsyncData<List<Story>>) {
      final stories = currentState.value;
      final updatedStories = stories.map((story) {
        if (story.id == storyId) {
          return Story(
            id: story.id,
            name: story.name,
            previewImage: story.previewImage,
            stories: story.stories,
            button: story.button,
            read: true,
          );
        }
        return story;
      }).toList();

      if (_mounted) {
        state = AsyncValue.data(updatedStories);
      }
    }
  }

  Future<void> fetchStories() async {
    if (!_mounted) return;

    state = const AsyncValue.loading();

    try {
      final response = await _listService.stories();

      if (!_mounted) return;

      // Проверяем ответ на null
      if (response == null) {
        throw Exception('500 Internal Server Error');
      }

      // Проверяем статус код
      if (response.statusCode != 200) {
        throw Exception('${response.statusCode} Server Error');
      }

      // Проверяем наличие данных
      if (response.data['data'] == null) {
        throw Exception('No data in response');
      }

      final List<Story> stories = (response.data['data'] as List)
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();

      // Загружаем статусы просмотра из локального хранилища
      await _loadViewedStatuses(stories);

      if (!_mounted) return;
      state = AsyncValue.data(stories);
    } catch (error, stackTrace) {
      // Форматируем сообщение об ошибке
      final String errorMessage = _formatErrorMessage(error);
      if (!_mounted) return;
      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  Future<void> _loadViewedStatuses(List<Story> stories) async {
    try {
      final viewedStories = await StorageService.getViewedStories();

      for (final story in stories) {
        if (story.id != null && viewedStories.contains(story.id!)) {
          story.read = true;
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке статусов просмотра: $e');
    }
  }

  // Форматирует сообщение об ошибке в зависимости от типа ошибки
  String _formatErrorMessage(Object error) {
    final errorString = error.toString();

    if (errorString.contains('500')) {
      return '500 Internal Server Error';
    } else if (errorString.contains('404')) {
      return '404 Not Found';
    } else if (errorString.contains('401') || errorString.contains('403')) {
      return 'Authentication Error';
    } else if (errorString.contains('timeout') ||
        errorString.contains('SocketException') ||
        errorString.contains('Network')) {
      return 'Network Error';
    }

    return errorString;
  }
}

final storiesProvider =
    StateNotifierProvider<StoriesProvider, AsyncValue<List<Story>>>(
  (ref) => StoriesProvider(ref.read(requestCodeProvider)),
);

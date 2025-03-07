import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/types/stories_type.dart';
import 'package:aina_flutter/core/providers/requests/stories/list.dart';

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

  Future<void> fetchStories() async {
    if (!_mounted) return;

    state = const AsyncValue.loading();

    try {
      print('📱 Загрузка историй...');
      final response = await _listService.stories();

      if (!_mounted) return;

      // Проверяем ответ на null
      if (response == null) {
        print('❌ Ответ от сервера пустой');
        throw Exception('500 Internal Server Error');
      }

      // Проверяем статус код
      if (response.statusCode != 200) {
        print('❌ Ошибка сервера: ${response.statusCode}');
        throw Exception('${response.statusCode} Server Error');
      }

      // Проверяем наличие данных
      if (response.data['data'] == null) {
        print('❌ В ответе отсутствуют данные');
        throw Exception('No data in response');
      }

      print(
          '✅ Истории успешно загружены: ${(response.data['data'] as List).length} шт.');
      final List<Story> stories = (response.data['data'] as List)
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!_mounted) return;
      state = AsyncValue.data(stories);
    } catch (error, stackTrace) {
      print('❌ Ошибка при загрузке историй: $error');

      // Форматируем сообщение об ошибке
      final String errorMessage = _formatErrorMessage(error);
      if (!_mounted) return;
      state = AsyncValue.error(errorMessage, stackTrace);
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

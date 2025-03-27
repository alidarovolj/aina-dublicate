import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

enum UpdateType {
  none,
  minor,
  hard,
}

class UpdateNotifierState {
  final UpdateType type;
  final String currentVersion;
  final String newVersion;

  UpdateNotifierState({
    required this.type,
    required this.currentVersion,
    required this.newVersion,
  });

  UpdateNotifierState copyWith({
    UpdateType? type,
    String? currentVersion,
    String? newVersion,
  }) {
    return UpdateNotifierState(
      type: type ?? this.type,
      currentVersion: currentVersion ?? this.currentVersion,
      newVersion: newVersion ?? this.newVersion,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateNotifierState> {
  UpdateNotifier()
      : super(UpdateNotifierState(
          type: UpdateType.none,
          currentVersion: '',
          newVersion: '',
        ));

  @override
  void dispose() {
    // Clean up any resources here
    super.dispose();
  }

  Future<String?> _getIosStoreVersion() async {
    try {
      final response = await Dio().get(
        'https://itunes.apple.com/lookup?bundleId=kz.aina.ios&country=KZ',
      );

      // Безопасная проверка структуры ответа
      if (response.data is Map) {
        // Проверка на наличие resultCount и results
        if (response.data.containsKey('resultCount') &&
            response.data['resultCount'] is int &&
            response.data['resultCount'] > 0 &&
            response.data.containsKey('results') &&
            response.data['results'] is List &&
            response.data['results'].isNotEmpty) {
          final firstResult = response.data['results'][0];

          // Проверка на наличие версии в первом результате
          if (firstResult is Map) {
            // Проверяем наличие ключа version
            if (firstResult.containsKey('version')) {
              final storeVersion = firstResult['version'].toString();
              return storeVersion;
            }
            // Альтернативные ключи, которые могут содержать версию
            else if (firstResult.containsKey('currentVersion')) {
              final storeVersion = firstResult['currentVersion'].toString();
              return storeVersion;
            } else if (firstResult.containsKey('latestVersion')) {
              final storeVersion = firstResult['latestVersion'].toString();
              return storeVersion;
            } else {
              debugPrint(
                  '⚠️ В результате нет ключа version или альтернативных ключей');
            }
          } else {
            debugPrint(
                '⚠️ Первый результат не является Map: ${firstResult.runtimeType}');
          }
        } else {
          debugPrint(
              '⚠️ Структура ответа не содержит resultCount > 0 или results');
        }
      } else {
        debugPrint('⚠️ Ответ не является Map: ${response.data.runtimeType}');
      }

      debugPrint(
          '⚠️ Неожиданная структура ответа от App Store: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при получении версии из App Store: $e');
      return null;
    }
  }

  Future<bool> _checkAndroidUpdate() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }

      try {
        final updateInfo = await InAppUpdate.checkForUpdate();

        if (updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        // Для тестирования на эмуляторе или при ошибках плагина
        // используем запасной вариант с проверкой через API
        try {
          final response = await ApiClient().dio.get(
                '/api/aina/version',
                options: Options(
                  headers: {'platform': 'android'},
                ),
              );

          if (response.data['success'] == true &&
              response.data['data'] != null) {
            final serverVersion = response.data['data']['version'] as String;
            final packageInfo = await PackageInfo.fromPlatform();
            final currentVersion = packageInfo.version;

            if (serverVersion != currentVersion) {
              return true;
            }
          }
          return false;
        } catch (apiError) {
          // В тестовом окружении, если API недоступен,
          // возвращаем false чтобы не блокировать пользователя
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Получаем данные из Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      String latestVersionKey, minVersionKey;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        latestVersionKey = 'current_ios_version';
        minVersionKey = 'min_ios_version';
      } else {
        latestVersionKey = 'current_android_version';
        minVersionKey = 'min_android_version';
      }

      final latestVersion = remoteConfig.getString(latestVersionKey);
      final minVersion = remoteConfig.getString(minVersionKey);

      if (latestVersion.isEmpty || minVersion.isEmpty) {
        try {
          state = state.copyWith(type: UpdateType.none);
        } catch (e) {
          debugPrint('❌ Ошибка при обновлении состояния: $e');
        }
        return;
      }

      // Сравниваем версии
      final needsHardUpdate = _isVersionLower(currentVersion, minVersion);
      final needsMinorUpdate = _isVersionLower(currentVersion, latestVersion) &&
          !_isVersionLower(currentVersion, minVersion);

      if (!needsHardUpdate && !needsMinorUpdate) {
        try {
          state = state.copyWith(type: UpdateType.none);
        } catch (e) {
          debugPrint('❌ Ошибка при обновлении состояния: $e');
        }
        return;
      }

      // Определяем тип обновления
      final updateType = needsHardUpdate ? UpdateType.hard : UpdateType.minor;

      try {
        state = state.copyWith(
          type: updateType,
          currentVersion: currentVersion,
          newVersion: latestVersion,
        );
      } catch (e) {
        debugPrint('❌ Ошибка при обновлении состояния: $e');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке обновлений: $e');
      try {
        state = state.copyWith(type: UpdateType.none);
      } catch (stateError) {
        debugPrint('❌ Ошибка при сбросе состояния: $stateError');
      }
    }
  }

  // Вспомогательный метод для сравнения версий
  bool _isVersionLower(String currentVersion, String targetVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final targetParts = targetVersion.split('.').map(int.parse).toList();

      // Добавляем нули, если в какой-то версии меньше частей
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (targetParts.length < 3) {
        targetParts.add(0);
      }

      // Сравниваем каждую часть версии
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < targetParts[i]) {
          return true;
        }
        if (currentParts[i] > targetParts[i]) {
          return false;
        }
      }

      return false; // Версии равны
    } catch (e) {
      debugPrint('❌ Ошибка при сравнении версий: $e');
      // В случае ошибки считаем, что обновление не требуется
      return false;
    }
  }

  void resetUpdateState() {
    try {
      state = state.copyWith(type: UpdateType.none);
    } catch (e) {
      debugPrint('❌ Ошибка при сбросе состояния: $e');
    }
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateNotifierState>((ref) {
  debugPrint('🔄 Создание нового экземпляра UpdateNotifier');
  final notifier = UpdateNotifier();

  // Добавляем обработчик для автоматического удаления
  ref.onDispose(() {
    debugPrint('🧹 Провайдер updateNotifierProvider удален');
  });

  return notifier;
});

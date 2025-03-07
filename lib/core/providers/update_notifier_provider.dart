import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:aina_flutter/core/api/api_client.dart';
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
    print('🧹 UpdateNotifier disposed');
    super.dispose();
  }

  Future<String?> _getIosStoreVersion() async {
    try {
      print('📱 Проверка версии в App Store...');
      final response = await Dio().get(
        'https://itunes.apple.com/lookup?bundleId=kz.aina.ios&country=KZ',
      );

      // Подробное логирование структуры ответа
      print('📊 Структура ответа от App Store:');
      if (response.data is Map) {
        print('   Тип данных: Map');
        if (response.data.containsKey('resultCount')) {
          print('   resultCount: ${response.data['resultCount']}');
        } else {
          print('   Ключ resultCount отсутствует');
        }

        if (response.data.containsKey('results')) {
          print(
              '   results присутствует, тип: ${response.data['results'].runtimeType}');
          if (response.data['results'] is List &&
              response.data['results'].isNotEmpty) {
            print(
                '   Количество результатов: ${response.data['results'].length}');
            print(
                '   Первый результат тип: ${response.data['results'][0].runtimeType}');
            if (response.data['results'][0] is Map) {
              if (response.data['results'][0].containsKey('version')) {
                print('   Версия: ${response.data['results'][0]['version']}');
              } else {
                print('   Ключ version отсутствует в первом результате');
                // Выводим все ключи первого результата для отладки
                print(
                    '   Доступные ключи: ${response.data['results'][0].keys.toList()}');
              }
            }
          } else {
            print('   results пуст или не является списком');
          }
        } else {
          print('   Ключ results отсутствует');
        }
      } else {
        print('   Тип данных не Map: ${response.data.runtimeType}');
      }

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
              print('📦 Версия в App Store: $storeVersion');
              return storeVersion;
            }
            // Альтернативные ключи, которые могут содержать версию
            else if (firstResult.containsKey('currentVersion')) {
              final storeVersion = firstResult['currentVersion'].toString();
              print('📦 Версия в App Store (currentVersion): $storeVersion');
              return storeVersion;
            } else if (firstResult.containsKey('latestVersion')) {
              final storeVersion = firstResult['latestVersion'].toString();
              print('📦 Версия в App Store (latestVersion): $storeVersion');
              return storeVersion;
            } else {
              print(
                  '⚠️ В результате нет ключа version или альтернативных ключей');
            }
          } else {
            print(
                '⚠️ Первый результат не является Map: ${firstResult.runtimeType}');
          }
        } else {
          print('⚠️ Структура ответа не содержит resultCount > 0 или results');
        }
      } else {
        print('⚠️ Ответ не является Map: ${response.data.runtimeType}');
      }

      print('⚠️ Неожиданная структура ответа от App Store: ${response.data}');
      return null;
    } catch (e) {
      print('❌ Ошибка при получении версии из App Store: $e');
      return null;
    }
  }

  Future<bool> _checkAndroidUpdate() async {
    try {
      print('📱 Проверка обновлений в Play Store...');

      if (defaultTargetPlatform != TargetPlatform.android) {
        print('❌ Платформа не Android');
        return false;
      }

      try {
        final updateInfo = await InAppUpdate.checkForUpdate();

        if (updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          print('✅ Доступно обновление в Play Store');
          return true;
        } else {
          print('❌ Обновлений в Play Store нет');
          return false;
        }
      } catch (e) {
        print('⚠️ Ошибка при проверке через in_app_update: $e');
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

            print(
                '📱 Версия из API - текущая: $currentVersion, серверная: $serverVersion');

            if (serverVersion != currentVersion) {
              print('✅ Доступно обновление через API');
              return true;
            }
          }
          print('❌ Обновлений через API нет');
          return false;
        } catch (apiError) {
          // В тестовом окружении, если API недоступен,
          // возвращаем false чтобы не блокировать пользователя
          print('❌ Ошибка при проверке через API: $apiError');
          return false;
        }
      }
    } catch (e) {
      print('❌ Ошибка при проверке обновлений в Play Store: $e');
      return false;
    }
  }

  Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('🔄 Текущая версия приложения: $currentVersion');

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

      print('📦 Последняя версия из Remote Config: $latestVersion');
      print('📦 Минимальная версия из Remote Config: $minVersion');

      if (latestVersion.isEmpty || minVersion.isEmpty) {
        print('⚠️ Не удалось получить информацию о версиях из Remote Config');
        try {
          state = state.copyWith(type: UpdateType.none);
        } catch (e) {
          print('❌ Ошибка при обновлении состояния: $e');
        }
        return;
      }

      // Сравниваем версии
      final needsHardUpdate = _isVersionLower(currentVersion, minVersion);
      final needsMinorUpdate = _isVersionLower(currentVersion, latestVersion) &&
          !_isVersionLower(currentVersion, minVersion);

      print('🔍 Результаты проверки:');
      print('   Требуется обязательное обновление: $needsHardUpdate');
      print('   Требуется рекомендуемое обновление: $needsMinorUpdate');

      if (!needsHardUpdate && !needsMinorUpdate) {
        print('💤 Обновление не требуется, сбрасываем состояние');
        try {
          state = state.copyWith(type: UpdateType.none);
        } catch (e) {
          print('❌ Ошибка при обновлении состояния: $e');
        }
        return;
      }

      // Определяем тип обновления
      final updateType = needsHardUpdate ? UpdateType.hard : UpdateType.minor;

      print('🔔 Устанавливаем состояние обновления:');
      print(
          '   Тип: ${updateType == UpdateType.hard ? "hard (обязательное)" : "minor (рекомендуемое)"}');
      print('   Текущая версия: $currentVersion');
      print('   Новая версия: $latestVersion');
      print('   Минимальная версия: $minVersion');

      try {
        state = state.copyWith(
          type: updateType,
          currentVersion: currentVersion,
          newVersion: latestVersion,
        );
      } catch (e) {
        print('❌ Ошибка при обновлении состояния: $e');
      }
    } catch (e) {
      print('❌ Ошибка при проверке обновлений: $e');
      try {
        state = state.copyWith(type: UpdateType.none);
      } catch (stateError) {
        print('❌ Ошибка при сбросе состояния: $stateError');
      }
    }
  }

  // Вспомогательный метод для сравнения версий
  bool _isVersionLower(String currentVersion, String targetVersion) {
    print(
        '🔍 Сравниваем версии: текущая $currentVersion, целевая $targetVersion');

    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final targetParts = targetVersion.split('.').map(int.parse).toList();

      // Добавляем нули, если в какой-то версии меньше частей
      while (currentParts.length < 3) currentParts.add(0);
      while (targetParts.length < 3) targetParts.add(0);

      print('🔢 Разбор версий: текущая $currentParts, целевая $targetParts');

      // Сравниваем каждую часть версии
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < targetParts[i]) {
          print(
              '📉 Текущая версия НИЖЕ целевой в позиции $i: ${currentParts[i]} < ${targetParts[i]}');
          return true;
        }
        if (currentParts[i] > targetParts[i]) {
          print(
              '📈 Текущая версия ВЫШЕ целевой в позиции $i: ${currentParts[i]} > ${targetParts[i]}');
          return false;
        }
      }

      print('📊 Версии РАВНЫ');
      return false; // Версии равны
    } catch (e) {
      print('❌ Ошибка при сравнении версий: $e');
      // В случае ошибки считаем, что обновление не требуется
      return false;
    }
  }

  void resetUpdateState() {
    try {
      state = state.copyWith(type: UpdateType.none);
    } catch (e) {
      print('❌ Ошибка при сбросе состояния: $e');
    }
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateNotifierState>((ref) {
  print('🔄 Создание нового экземпляра UpdateNotifier');
  final notifier = UpdateNotifier();

  // Добавляем обработчик для автоматического удаления
  ref.onDispose(() {
    print('🧹 Провайдер updateNotifierProvider удален');
  });

  return notifier;
});

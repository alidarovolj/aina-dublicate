import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

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

  Future<String?> _getIosStoreVersion() async {
    try {
      print('📱 Проверка версии в App Store...');
      final response = await Dio().get(
        'https://itunes.apple.com/lookup?bundleId=kz.aina.ios&country=KZ',
      );

      if (response.data['resultCount'] > 0) {
        final storeVersion = response.data['results'][0]['version'] as String;
        print('📦 Версия в App Store: $storeVersion');
        return storeVersion;
      }
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

      String? storeVersion;
      bool needsUpdate = false;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        storeVersion = await _getIosStoreVersion();
        if (storeVersion != null) {
          needsUpdate = storeVersion != currentVersion;
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        needsUpdate = await _checkAndroidUpdate();
        if (needsUpdate) {
          // Для Android мы не можем получить точную версию,
          // поэтому просто увеличиваем текущую версию
          final parts = currentVersion.split('.');
          if (parts.isNotEmpty) {
            final major = int.parse(parts[0]);
            storeVersion = '${major + 1}.0.0';
          }
        }
      }

      if (storeVersion == null || !needsUpdate) {
        print('💤 Обновление не требуется, сбрасываем состояние');
        state = state.copyWith(type: UpdateType.none);
        return;
      }

      print('📦 Версия в сторе: $storeVersion');

      // Разбиваем версии на части
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final serverParts = storeVersion.split('.').map(int.parse).toList();
      print('🔍 Разбор версий:');
      print('   Текущая: $currentParts');
      print('   Серверная: $serverParts');

      // Добавляем нули, если в какой-то версии меньше частей
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (serverParts.length < 3) {
        serverParts.add(0);
      }

      // Определяем тип обновления
      bool isHardUpdate = serverParts[0] > currentParts[0];

      print('🔔 Устанавливаем состояние обновления:');
      print('   Тип: ${isHardUpdate ? "hard" : "minor"}');
      print('   Текущая версия: $currentVersion');
      print('   Новая версия: $storeVersion');

      state = state.copyWith(
        type: isHardUpdate ? UpdateType.hard : UpdateType.minor,
        currentVersion: currentVersion,
        newVersion: storeVersion,
      );
    } catch (e) {
      print('❌ Ошибка при проверке обновлений: $e');
      state = state.copyWith(type: UpdateType.none);
    }
  }

  void resetUpdateState() {
    state = state.copyWith(type: UpdateType.none);
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateNotifierState>((ref) {
  return UpdateNotifier();
});

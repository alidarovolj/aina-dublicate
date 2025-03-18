import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/api/firebase_setup.dart';
// import 'core/utils/notification_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:flutter/services.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/widgets/restart_widget.dart';
import 'package:aina_flutter/core/api/firebase_setup.dart';
import 'package:aina_flutter/core/utils/notification_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'core/services/amplitude_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'dart:io' show Platform;
import 'dart:convert';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first as it's required by other services
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize core services in parallel
    final initResults = await Future.wait([
      EasyLocalization.ensureInitialized(),
      dotenv.load(),
      initializeDateFormatting('ru', null),
      SharedPreferences.getInstance(),
    ], eagerError: true);

    final prefs = initResults[3] as SharedPreferences;

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize Chucker
    ChuckerFlutter.showOnRelease = false;
    ChuckerFlutter.isDebugMode = false;

    // Load saved locale
    final savedLocale =
        prefs.getString('selected_locale') ?? prefs.getString('locale');
    final initialLocale =
        savedLocale != null ? Locale(savedLocale) : const Locale('ru');

    // Initialize services that depend on Firebase
    await Future.wait([
      initializeRemoteConfig(),
      AmplitudeService().init(),
      requestNotificationPermissions(),
    ], eagerError: true);

    // Set up notification listeners
    setupNotificationListeners();

    // Check auth and fetch profile
    String? token = await StorageService.getToken();
    print('🔍 Token: $token');

    // Try to get saved user data
    String? savedUserDataStr = prefs.getString('user_data');
    int userId = 0;
    int deviceId = 0;

    if (savedUserDataStr != null) {
      try {
        final savedUserData =
            jsonDecode(savedUserDataStr) as Map<String, dynamic>;
        userId = savedUserData['id'] ?? 0;
        deviceId = savedUserData['device_id'] ?? 0;
        print(
            '📱 Found saved user data - userId: $userId, deviceId: $deviceId');
      } catch (e) {
        print('⚠️ Error parsing saved user data: $e');
      }
    }

    if (token != null) {
      try {
        print('🔍 Token found, fetching profile...');
        final response = await ApiClient().dio.get('/api/promenade/profile');
        print('📡 API Response: ${response.data}');

        if (response.data['success'] == true && response.data['data'] != null) {
          final userData = response.data['data'] as Map<String, dynamic>;
          print('👤 User data received: $userData');

          userId = userData['id'] ?? userId;
          deviceId = userData['device_id'] ?? deviceId;
          print('📊 Updated IDs - userId: $userId, deviceId: $deviceId');

          await prefs.setString('user_data', jsonEncode(userData));
          print('💾 Fresh user data saved to preferences');
        }
      } catch (e) {
        print('❌ Error loading profile: $e');
      }
    } else {
      print('⚠️ No token found');
    }

    // Send event if we have valid user data
    if (userId != 0 && deviceId != 0) {
      String platform = 'web';
      if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      }

      print('📤 Sending Amplitude event with data:');
      print('   - user_id: $userId');
      print('   - device_id: $deviceId');
      print('   - platform: $platform');
      print('   - source: main');

      await AmplitudeService().logEvent(
        'main_click',
        eventProperties: {
          'user_id': userId,
          'device_id': deviceId,
          'source': 'main',
          'Platform': platform,
        },
      );
    } else {
      print('⚠️ Skipping Amplitude event - no valid user data');
    }

    // Initialize Sentry and run the app
    await SentryFlutter.init(
      (options) {
        options.dsn = 'http://01f6f7ad077e199227439ee9bc1032d1@192.168.0.93/17';
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        EasyLocalization(
          supportedLocales: const [Locale('ru'), Locale('kk'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ru'),
          startLocale: initialLocale,
          child: const RestartWidget(
            child: ProviderScope(
              child: MyApp(initialRoute: '/'),
            ),
          ),
        ),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ Critical error during app initialization: $e');
    print('Stack trace: $stackTrace');

    // Показываем пользователю сообщение об ошибке
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Произошла ошибка при запуске приложения',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final context = WidgetsBinding
                          .instance.focusManager.primaryFocus?.context;
                      if (context != null) {
                        RestartWidget.restartApp(context);
                      }
                    },
                    child: const Text('Перезапустить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Отдельная функция для инициализации Remote Config
Future<void> initializeRemoteConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Устанавливаем настройки для более быстрой инициализации в debug режиме
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Устанавливаем значения по умолчанию
    await remoteConfig.setDefaults({
      'current_ios_version': '1.0.0',
      'current_android_version': '1.0.0',
      'min_ios_version': '1.0.0',
      'min_android_version': '1.0.0',
      'force_update_message':
          'Пожалуйста, обновите приложение для продолжения работы.'
    });

    // Получение значений при запуске
    await remoteConfig.fetchAndActivate();

    print('✅ Remote Config успешно инициализирован');
    print(
        '📱 current_ios_version: ${remoteConfig.getString('current_ios_version')}');
    print(
        '📱 current_android_version: ${remoteConfig.getString('current_android_version')}');
    print('📱 min_ios_version: ${remoteConfig.getString('min_ios_version')}');
    print(
        '📱 min_android_version: ${remoteConfig.getString('min_android_version')}');
  } catch (e) {
    print('❌ Ошибка при инициализации Remote Config: $e');
    // В случае ошибки используем значения по умолчанию
  }
}

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  static Future<bool> hasSeenOnboarding() async {
    return _storage
        .read(key: _hasSeenOnboardingKey)
        .then((value) => value != null);
  }

  static Future<void> setHasSeenOnboarding() async {
    await _storage.write(key: _hasSeenOnboardingKey, value: 'true');
  }
}

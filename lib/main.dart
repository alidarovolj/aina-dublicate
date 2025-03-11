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

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

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
  ChuckerFlutter.isDebugMode = false; // Disable debug mode

  // Load environment variables and other initializations
  await dotenv.load();
  await initializeDateFormatting('ru', null);

  // Initialize Amplitude
  await AmplitudeService().init();

  // Load saved locale
  final prefs = await SharedPreferences.getInstance();
  final savedLocale =
      prefs.getString('selected_locale') ?? prefs.getString('locale');
  final initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('ru');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permissions
  await requestNotificationPermissions();

  // Set up notification listeners
  setupNotificationListeners();

  // Запускаем приложение
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ru'),
        Locale('kk'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      startLocale: initialLocale,
      child: const RestartWidget(
        child: ProviderScope(
          child: MyApp(initialRoute: '/'),
        ),
      ),
    ),
  );

  // Инициализация Remote Config перенесена в _MyAppState._initializeRemoteConfigAndCheckUpdates()
}

// Отдельная функция для инициализации Remote Config
Future<void> initializeRemoteConfig() async {
  try {
    // Добавляем небольшую задержку, чтобы убедиться, что Firebase полностью инициализирован
    await Future.delayed(const Duration(seconds: 1));

    final remoteConfig = FirebaseRemoteConfig.instance;

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

    // Выводим полученные значения для проверки
    print(
        '📱 current_ios_version: ${remoteConfig.getString('current_ios_version')}');
    print(
        '📱 current_android_version: ${remoteConfig.getString('current_android_version')}');
    print('📱 min_ios_version: ${remoteConfig.getString('min_ios_version')}');
    print(
        '📱 min_android_version: ${remoteConfig.getString('min_android_version')}');

    // Вместо создания нового ProviderContainer, используем существующий
    // Это предотвратит создание нового экземпляра UpdateNotifier
    // и использование его после dispose
  } catch (e) {
    print('❌ Ошибка при инициализации Remote Config: $e');
    // Продолжаем работу приложения даже при ошибке Remote Config
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

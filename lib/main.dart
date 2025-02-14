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

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Chucker
  ChuckerFlutter.showOnRelease = false;
  ChuckerFlutter.isDebugMode = false; // Disable debug mode

  // Load environment variables and other initializations
  await dotenv.load();
  await initializeDateFormatting('ru', null);

  // Load saved locale
  final prefs = await SharedPreferences.getInstance();
  final savedLocale =
      prefs.getString('selected_locale') ?? prefs.getString('locale');
  final initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('ru');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Check if user has seen onboarding
  // final hasSeenOnboarding = await StorageService.hasSeenOnboarding();

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

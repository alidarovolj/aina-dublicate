import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/api/firebase_setup.dart';
// import 'core/utils/notification_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:flutter/services.dart';
import 'package:chucker_flutter/chucker_flutter.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Chucker
  ChuckerFlutter.showOnRelease = true;

  // Load environment variables and other initializations
  await dotenv.load();
  await initializeDateFormatting('ru', null);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light, // Adjust for your theme
      statusBarIconBrightness: Brightness.dark, // Icon color
      statusBarColor: Colors.white, // Makes it transparent
      systemNavigationBarColor: Colors.white, // Nav bar background
      systemNavigationBarIconBrightness: Brightness.dark, // Nav bar icons
    ),
  );

  // Check if user has seen onboarding
  // final hasSeenOnboarding = await StorageService.hasSeenOnboarding();

  runApp(
    const ProviderScope(
      child: MyApp(initialRoute: '/'),
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

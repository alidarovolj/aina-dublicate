import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/api/firebase_setup.dart';
// import 'core/utils/notification_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:aina_flutter/core/providers/auth/auth_state.dart';

Future<void> main() async {
  await dotenv.load();
  // WidgetsFlutterBinding.ensureInitialized();

  // // Initialize Firebase
  // await initializeFirebase();

  // // Request notification permissions
  // await requestNotificationPermissions();

  // // Set up notification listeners
  // setupNotificationListeners();

  await initializeDateFormatting('ru', null);

  // Check if user has seen onboarding
  // final hasSeenOnboarding = await StorageService.hasSeenOnboarding();

  runApp(
    const ProviderScope(
      // child: Consumer(
      //   builder: (context, ref, child) {
      //     // Initialize auth state
      //     ref.read(authProvider.notifier).initializeAuth();

      //     // If user hasn't seen onboarding, redirect to it
      //     if (!hasSeenOnboarding) {
      //       Future.microtask(() => StorageService.setHasSeenOnboarding());
      //       return const MyApp(initialRoute: '/onboarding');
      //     }

      //     return const MyApp(initialRoute: '/');
      //   },
      // ),
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

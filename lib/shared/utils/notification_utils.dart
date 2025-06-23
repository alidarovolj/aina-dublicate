import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math' as math;

// Key for storing whether FCM token has been registered with a user
const String _fcmUserRegisteredKey = 'fcm_user_registered';

// Check if FCM token has been registered with a user
Future<bool> isFCMTokenRegisteredWithUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_fcmUserRegisteredKey) ?? false;
}

// Mark FCM token as registered with a user
Future<void> markFCMTokenAsRegistered() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_fcmUserRegisteredKey, true);
}

// Clear FCM registration status (for logout)
Future<void> clearFCMRegistrationStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_fcmUserRegisteredKey);
}

Future<void> setupNotificationListeners() async {
  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      await Firebase.initializeApp();
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      // Configure presentation options first
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request permissions with all options
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );

      // Try to get APNS token but don't block on failure
      try {
        String? apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('Successfully obtained APNS token');
        } else {
          debugPrint(
              'APNS token not available (possibly running in simulator)');
        }
      } catch (e) {
        debugPrint(
            'Error getting APNS token (possibly running in simulator): $e');
      }
    }

    // Get initial token but don't send it without user_id
    try {
      // Check if we already registered with a user
      bool isRegistered = await isFCMTokenRegisteredWithUser();
      if (!isRegistered) {
        // Don't send FCM token without user_id during initial setup
        // Token will be sent with user_id after authentication
        debugPrint(
            '⏭️ Skipping initial FCM token registration - will be sent after authentication');
      } else {
        debugPrint(
            'Skipping initial FCM registration as already registered with user');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      // Only send token refresh if user is already registered
      bool isRegistered = await isFCMTokenRegisteredWithUser();
      if (isRegistered) {
        // Send with existing user context - server will handle the refresh
        await sendFCMToken(newToken);
        debugPrint('🔄 FCM token refreshed and sent');
      } else {
        debugPrint(
            '⏭️ FCM token refreshed but skipping send - user not registered');
      }
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
    });

    // Handle notifications that open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
    });
  } catch (e) {
    debugPrint('Error setting up notification listeners: $e');
  }
}

Future<void> getDeviceToken() async {
  // Check if we already registered with a user
  bool isRegistered = await isFCMTokenRegisteredWithUser();
  if (isRegistered) {
    debugPrint('Skipping FCM registration as already registered with user');
    return;
  }

  // Force token refresh
  await refreshFCMToken();

  try {
    if (Platform.isIOS) {
      // Set up notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request full permissions first
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Try to get FCM token directly
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await sendFCMToken(fcmToken);
            return;
          } else {
            debugPrint('FCM token is null (possibly running in simulator)');
          }
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }
      } else {
        debugPrint(
            'iOS notifications not authorized: ${settings.authorizationStatus}');
      }
    } else {
      // Android token retrieval
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await sendFCMToken(fcmToken);
      } else {
        debugPrint('Failed to obtain FCM token on Android');
      }
    }
  } catch (e) {
    debugPrint('Error in getDeviceToken: $e');
  }
}

Future<void> sendFCMToken(String token, {String? userId}) async {
  int maxAttempts = 3;
  int delaySeconds = 1;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // Get previous token to send as old_token
      String? oldToken = await getPreviousToken();

      final deviceInfo = await getDeviceInfo();
      final Map<String, dynamic> data = {
        'key': deviceInfo.identifier,
        'token': token,
        'os': deviceInfo.operatingSystem,
      };

      // Add user_id to the request if provided
      if (userId != null) {
        data['user_id'] = userId;

        // Only include old_token if we have a previous token that's different from current
        if (oldToken != null && oldToken != token) {
          data['old_token'] = oldToken;
        }
        // If old_token is the same as current token or doesn't exist, don't send it
      } else if (oldToken != null && oldToken != token) {
        // In non-auth scenarios, only include old_token if we have a different previous token
        data['old_token'] = oldToken;
      }

      final response = await ApiClient().dio.post(
            '/api/aina/firebase/token',
            data: data,
            options: Options(
              headers: {'force-refresh': 'true'},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Save current token as previous token for future requests
        await savePreviousToken(token);
        return;
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
      } else {
        debugPrint('Failed to send FCM token after $maxAttempts attempts');
      }
    }
  }
}

// Key for storing previous FCM token
const String _previousTokenKey = 'previous_fcm_token';

// Get previous FCM token from SharedPreferences
Future<String?> getPreviousToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_previousTokenKey);
}

// Save current token as previous token
Future<void> savePreviousToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_previousTokenKey, token);
}

Future<DeviceInfo> getDeviceInfo() async {
  final deviceInfoPlugin = DeviceInfoPlugin();
  String deviceId = '';
  String os = Platform.operatingSystem;

  try {
    if (Platform.isIOS) {
      // Get iOS device info
      final iosInfo = await deviceInfoPlugin.iosInfo;
      // Используем identifierForVendor и убираем дефисы для получения короткого ID
      String? vendorId = iosInfo.identifierForVendor;
      if (vendorId != null) {
        // Убираем дефисы и берем первые 12-16 символов
        deviceId = vendorId.replaceAll('-', '').substring(0, 12).toLowerCase();
      } else {
        // Fallback: генерируем уникальный ID на основе данных устройства
        final String fallbackData =
            '${iosInfo.name}_${iosInfo.model}_${iosInfo.systemVersion}_${iosInfo.utsname.machine}';
        deviceId = _generateDeviceId(fallbackData);
      }
      os = 'ios';
      debugPrint('Using iOS identifier: $deviceId');
    } else if (Platform.isAndroid) {
      // Get Android device info
      final androidInfo = await deviceInfoPlugin.androidInfo;
      // Используем androidId или генерируем на основе доступных данных
      if (androidInfo.id.isNotEmpty && androidInfo.id != 'unknown') {
        deviceId = androidInfo.id
            .substring(0, math.min(12, androidInfo.id.length))
            .toLowerCase();
      } else {
        // Fallback: генерируем на основе других данных
        final String fallbackData =
            '${androidInfo.brand}_${androidInfo.model}_${androidInfo.device}_${androidInfo.fingerprint}';
        deviceId = _generateDeviceId(fallbackData);
      }
      os = 'android';
      debugPrint('Using Android identifier: $deviceId');
    } else {
      // Для других платформ генерируем уникальный ID
      final String fallbackData =
          '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
      deviceId = _generateDeviceId(fallbackData);
    }
  } catch (e) {
    debugPrint('Error getting device info: $e');
    // В случае ошибки генерируем уникальный ID
    final String fallbackData =
        '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
    deviceId = _generateDeviceId(fallbackData);
  }

  return DeviceInfo(
    identifier: deviceId,
    operatingSystem: os,
  );
}

// Вспомогательная функция для генерации короткого уникального ID
String _generateDeviceId(String input) {
  // Простой хеш для генерации короткого ID
  int hash = input.hashCode;
  if (hash < 0) hash = -hash;

  // Конвертируем в hex и берем первые 12 символов
  String hexString = hash.toRadixString(16).padLeft(8, '0');

  // Добавляем текущее время для большей уникальности
  final timeHash =
      (DateTime.now().millisecondsSinceEpoch % 0xFFFFFF).toRadixString(16);

  return (hexString + timeHash).substring(0, 12).toLowerCase();
}

// Add a new function to get and send FCM token with user ID
Future<void> getAndSendDeviceTokenWithUserId(String userId) async {
  try {
    // Use existing token instead of forcing refresh
    // await refreshFCMToken(); // Removed - no need to refresh token on every auth
    if (Platform.isIOS) {
      // Set up notification presentation options
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request full permissions first
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Try to get FCM token directly
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await sendFCMToken(fcmToken, userId: userId);
            // Mark FCM token as registered with user
            await markFCMTokenAsRegistered();
            return;
          } else {
            debugPrint('FCM token is null (possibly running in simulator)');
          }
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }
      } else {
        debugPrint(
            'iOS notifications not authorized: ${settings.authorizationStatus}');
      }
    } else {
      // Android token retrieval
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await sendFCMToken(fcmToken, userId: userId);
        // Mark FCM token as registered with user
        await markFCMTokenAsRegistered();
      } else {
        debugPrint('Failed to obtain FCM token on Android');
      }
    }
  } catch (e) {
    debugPrint('Error in getAndSendDeviceTokenWithUserId: $e');
  }
}

// Function to force FCM token refresh
Future<void> refreshFCMToken() async {
  try {
    debugPrint('Forcing FCM token refresh...');
    // Delete the existing token
    await FirebaseMessaging.instance.deleteToken();
    debugPrint('Existing FCM token deleted');

    // Wait a moment for the token to be fully deleted
    await Future.delayed(const Duration(milliseconds: 500));

    // Request a new token
    final newToken = await FirebaseMessaging.instance.getToken();
    debugPrint(
        'New FCM token generated: ${newToken != null ? 'success' : 'failed'}');

    return;
  } catch (e) {
    debugPrint('Error refreshing FCM token: $e');
  }
}

class DeviceInfo {
  final String identifier;
  final String operatingSystem;

  DeviceInfo({
    required this.identifier,
    required this.operatingSystem,
  });
}

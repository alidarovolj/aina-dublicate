import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

    // Get initial token (will work on Android and iOS devices, might fail on simulator)
    try {
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        await sendFCMToken(fcmToken);
      } else {
        debugPrint('FCM token is null (possibly running in simulator)');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      sendFCMToken(newToken);
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

Future<void> sendFCMToken(String token) async {
  int maxAttempts = 3;
  int delaySeconds = 1;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final deviceInfo = await getDeviceInfo();
      final response = await ApiClient().dio.post(
            '/api/aina/firebase/token',
            data: {
              'key': deviceInfo.identifier,
              'token': token,
              'os': deviceInfo.operatingSystem,
            },
            options: Options(
              headers: {'force-refresh': 'true'},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

      if (response.statusCode == 200 && response.data['success'] == true) {
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

Future<DeviceInfo> getDeviceInfo() async {
  // This is a placeholder. You should implement actual device info gathering
  // using package:device_info_plus
  return DeviceInfo(
    identifier: Platform.isIOS ? 'ios_device' : 'android_device',
    operatingSystem: Platform.operatingSystem,
  );
}

class DeviceInfo {
  final String identifier;
  final String operatingSystem;

  DeviceInfo({
    required this.identifier,
    required this.operatingSystem,
  });
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> setupNotificationListeners() async {
  try {
    print('Setting up notification listeners...');

    // Ensure Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      await Firebase.initializeApp();
      print('Firebase initialized');
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      print('iOS platform detected, starting iOS-specific setup...');

      // Configure presentation options first
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Foreground notification options set for iOS');

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

      print('iOS Authorization status: ${settings.authorizationStatus}');

      // Try to get APNS token but don't block on failure
      try {
        String? apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          print('Successfully obtained APNS token');
        } else {
          print('APNS token not available (possibly running in simulator)');
        }
      } catch (e) {
        print('Error getting APNS token (possibly running in simulator): $e');
      }
    }

    // Get initial token (will work on Android and iOS devices, might fail on simulator)
    try {
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        print(
            'Successfully obtained FCM token: ${fcmToken.substring(0, 8)}...');
        await sendFCMToken(fcmToken);
      } else {
        print('FCM token is null (possibly running in simulator)');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: ${newToken.substring(0, 8)}...");
      sendFCMToken(newToken);
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    });

    // Handle notifications that open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    });

    print('Notification listeners setup complete');
  } catch (e, stackTrace) {
    print('Error setting up notification listeners: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> getDeviceToken() async {
  try {
    print('Starting device token retrieval process...');

    if (Platform.isIOS) {
      print('iOS platform detected, starting iOS-specific setup...');

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

      print('iOS Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Try to get FCM token directly
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            print(
                'Successfully obtained FCM token: ${fcmToken.substring(0, 8)}...');
            await sendFCMToken(fcmToken);
            return;
          } else {
            print('FCM token is null (possibly running in simulator)');
          }
        } catch (e) {
          print('Error getting FCM token: $e');
        }
      } else {
        print(
            'iOS notifications not authorized: ${settings.authorizationStatus}');
      }
    } else {
      // Android token retrieval
      print('Android platform detected, getting FCM token...');
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        print(
            'Successfully obtained FCM token: ${fcmToken.substring(0, 8)}...');
        await sendFCMToken(fcmToken);
      } else {
        print('Failed to obtain FCM token on Android');
      }
    }
  } catch (e, stackTrace) {
    print('Error in getDeviceToken: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> sendFCMToken(String token) async {
  int maxAttempts = 3;
  int delaySeconds = 1;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      print(
          'Attempting to send FCM token to server (attempt $attempt of $maxAttempts)...');

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
        print('FCM Token sent to server successfully');
        return;
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM token to server on attempt $attempt: $e');
      if (attempt < maxAttempts) {
        print('Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
      } else {
        print('Failed to send FCM token after $maxAttempts attempts');
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

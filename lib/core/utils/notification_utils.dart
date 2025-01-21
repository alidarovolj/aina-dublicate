import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;

void setupNotificationListeners() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission first
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Get the device token after permissions are granted
  await getDeviceToken();

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    print("Token refreshed: $newToken");
  });

  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
  });

  // Handle notifications that open the app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Opened from notification: ${message.notification?.title}');
  });
}

Future<void> getDeviceToken() async {
  try {
    // Get the FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // For iOS, explicitly request APNS token first
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print('APNS Token: $apnsToken');
    }

    print('FCM Token: $fcmToken');
  } catch (e) {
    print('Error getting device token: $e');
  }
}

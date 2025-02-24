import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aina_flutter/firebase_options.dart';
import 'dart:io' show Platform;

Future<void> initializeFirebase() async {
  try {
    print('Starting Firebase initialization...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase core initialized successfully');

    // Configure Firebase Messaging
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      print('iOS platform detected, configuring APNs...');

      // Set foreground notification presentation options first
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Foreground notification options set');

      // Request provisional authorization for iOS
      print('Requesting provisional authorization...');
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true, // This enables provisional authorization
      );
      print('Provisional authorization requested');

      // Check if APNs token is available
      final apnsToken = await messaging.getAPNSToken();
      print(
          'Initial APNS token check: ${apnsToken != null ? "Available" : "Not available"}');
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('Background message handler configured');
  } catch (e, stackTrace) {
    print('Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  try {
    // Need to initialize Firebase again in background handler
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase reinitialized in background handler');
  } catch (e) {
    print('Error initializing Firebase in background handler: $e');
  }
}

Future<void> requestNotificationPermissions() async {
  try {
    print('Requesting notification permissions...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );

    print('Permission request complete');
    print('Authorization status: ${settings.authorizationStatus}');
    print('Alert setting: ${settings.alert}');
    print('Badge setting: ${settings.badge}');
    print('Sound setting: ${settings.sound}');
    print('Critical alert setting: ${settings.criticalAlert}');
    print('Announcement setting: ${settings.announcement}');

    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
      print('APNS token after permission request: ${apnsToken ?? "null"}');
    }
  } catch (e, stackTrace) {
    print('Error requesting notification permissions: $e');
    print('Stack trace: $stackTrace');
  }
}

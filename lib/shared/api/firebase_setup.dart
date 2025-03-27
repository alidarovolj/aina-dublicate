import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aina_flutter/shared/services/firebase_options.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io' show Platform;

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firebase Messaging
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      // Set foreground notification presentation options first
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request provisional authorization for iOS
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true, // This enables provisional authorization
      );
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Need to initialize Firebase again in background handler
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase in background handler: $e');
  }
}

Future<void> requestNotificationPermissions() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );

    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
    }
  } catch (e) {
    debugPrint('Error requesting notification permissions: $e');
  }
}

import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class AmplitudeService {
  static final AmplitudeService _instance = AmplitudeService._internal();
  factory AmplitudeService() => _instance;
  AmplitudeService._internal();

  final Amplitude _amplitude = Amplitude.getInstance();

  Future<void> init() async {
    await _amplitude.init(dotenv.env['AMPLITUDE_API_KEY'] ?? '');
    await _amplitude.enableCoppaControl();
    await _amplitude.setServerUrl('https://api2.amplitude.com');
    await _amplitude.trackingSessionEvents(true);
  }

  Future<void> setUserId(String? userId) async {
    await _amplitude.setUserId(userId);
  }

  Future<void> logEvent(String eventName,
      {Map<String, dynamic>? eventProperties}) async {
    await _amplitude.logEvent(eventName, eventProperties: eventProperties);
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await _amplitude.setUserProperties(properties);
  }

  Future<void> trackMainClick({
    required int userId,
    required int deviceId,
    required String source,
  }) async {
    await logEvent('main_click', eventProperties: {
      'user_id': userId,
      'device_id': deviceId,
      'source': source,
      'Platform': Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web',
    });
  }
}

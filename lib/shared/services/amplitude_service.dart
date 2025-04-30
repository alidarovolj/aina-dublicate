import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AmplitudeService {
  static final AmplitudeService _instance = AmplitudeService._internal();
  factory AmplitudeService() => _instance;
  AmplitudeService._internal();

  late Amplitude _amplitude;
  bool _isInitialized = false;

  // Constants for Amplitude configuration
  static const int _minIdLength = 1; // Minimum length for identifiers
  static const String _apiEndpoint = 'https://api2.amplitude.com/2/httpapi';

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    final apiKey = dotenv.env['AMPLITUDE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return;
    }

    try {
      // Initialize with Configuration object
      _amplitude = Amplitude(Configuration(
        apiKey: apiKey,
        serverUrl: 'https://api2.amplitude.com',
        minIdLength: _minIdLength,
      ));

      // Wait for initialization to complete
      await _amplitude.isBuilt;

      _isInitialized = true;
    } catch (e) {
      debugPrint('ERROR initializing Amplitude: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) {
      return;
    }

    // Ensure userId has minimum length
    if (userId != null && userId.length < _minIdLength) {
      userId = _ensureMinLength(userId);
    }

    await _amplitude.setUserId(userId);
  }

  Future<void> logEvent(String eventName,
      {Map<String, dynamic>? eventProperties}) async {
    if (!_isInitialized) {
      return;
    }

    // Validate and correct event properties
    final validatedProperties = _validateEventProperties(eventProperties);

    // If userId is in properties, set it and remove from event properties
    if (validatedProperties != null &&
        validatedProperties.containsKey('user_id')) {
      final userId = validatedProperties['user_id'].toString();
      await setUserId(userId);

      // Create a copy of properties without user_id
      final cleanProperties = Map<String, dynamic>.from(validatedProperties);
      cleanProperties.remove('user_id');

      try {
        await _amplitude
            .track(BaseEvent(eventName, eventProperties: cleanProperties));

        // For important events, add direct validation
        if (eventName == 'main_click' ||
            eventName == 'content_type' ||
            eventName == 'subcategory_click') {
          await _validateEventSent(eventName, cleanProperties);
        }
      } catch (e) {
        debugPrint('ERROR logging event: $e');
      }
    } else {
      try {
        await _amplitude
            .track(BaseEvent(eventName, eventProperties: validatedProperties));

        // For important events, add direct validation
        if (eventName == 'main_click' ||
            eventName == 'content_type' ||
            eventName == 'subcategory_click') {
          await _validateEventSent(eventName, validatedProperties);
        }
      } catch (e) {
        debugPrint('ERROR logging event: $e');
      }
    }
  }

  // Method for validating event sent via HTTP API
  Future<void> _validateEventSent(
      String eventName, Map<String, dynamic>? eventProperties) async {
    try {
      final apiKey = dotenv.env['AMPLITUDE_API_KEY'] ?? '';

      // Get current userId
      String? currentUserId = await _amplitude.getUserId();

      // Generate deviceId if not in properties
      String deviceId;
      if (eventProperties?.containsKey('device_id') == true) {
        deviceId = _ensureMinLength(eventProperties!['device_id'].toString());
      } else {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Use current userId or generate a new one
      String userId =
          currentUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Ensure minimum length
      userId = _ensureMinLength(userId);

      // Create a clean copy of event properties
      final Map<String, dynamic> cleanProperties = {};
      eventProperties?.forEach((key, value) {
        if (key != 'user_id' && key != 'device_id') {
          cleanProperties[key] = value;
        }
      });

      final payload = {
        'api_key': apiKey,
        'events': [
          {
            'user_id': userId,
            'device_id': deviceId,
            'event_type': eventName,
            'time': DateTime.now().millisecondsSinceEpoch,
            'platform': eventProperties?['Platform'] ??
                (Platform.isIOS
                    ? 'ios'
                    : Platform.isAndroid
                        ? 'android'
                        : 'web'),
            'event_properties': cleanProperties
          }
        ]
      };

      final response = await http.post(Uri.parse(_apiEndpoint),
          headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
      } else {
        debugPrint(
            'Failed to validate event: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error validating event: $e');
    }
  }

  // Method for validating event properties
  Map<String, dynamic>? _validateEventProperties(
      Map<String, dynamic>? properties) {
    if (properties == null) return null;

    final validatedProperties = Map<String, dynamic>.from(properties);

    // Check and validate user_id
    if (validatedProperties.containsKey('user_id')) {
      final userId = validatedProperties['user_id'].toString();
      if (userId.length < _minIdLength) {
        validatedProperties['user_id'] = _ensureMinLength(userId);
      }
    }

    // Check and validate device_id
    if (validatedProperties.containsKey('device_id')) {
      final deviceId = validatedProperties['device_id'].toString();
      if (deviceId.length < _minIdLength) {
        validatedProperties['device_id'] = _ensureMinLength(deviceId);
      }
    }

    return validatedProperties;
  }

  // Method to ensure minimum length for identifiers
  String _ensureMinLength(String id) {
    if (id.length >= _minIdLength) return id;
    // Add prefix to reach minimum length
    return 'id_$id';
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized) {
      return;
    }

    final identify = Identify();

    properties.forEach((key, value) {
      identify.set(key, value);
    });

    await _amplitude.identify(identify);
  }

  Future<void> trackMainClick({
    required int userId,
    required int deviceId,
    required String source,
  }) async {
    // Ensure minimum length for identifiers
    final validUserId = _ensureMinLength(userId.toString());
    final validDeviceId = _ensureMinLength(deviceId.toString());

    // Use new method for sending event with proper user_id
    await logEventWithUserId(
      'main_click',
      userId: validUserId,
      eventProperties: {
        'device_id': validDeviceId,
        'source': source,
        'Platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'web',
      },
    );
  }

  // Method for sending event with proper user_id
  Future<void> logEventWithUserId(
    String eventName, {
    required String userId,
    Map<String, dynamic>? eventProperties,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Ensure userId has minimum length
    final validUserId = _ensureMinLength(userId);

    // Set userId in Amplitude
    await setUserId(validUserId);

    // Create a clean copy of properties without user_id
    Map<String, dynamic>? cleanProperties;
    if (eventProperties != null) {
      cleanProperties = Map<String, dynamic>.from(eventProperties);
      cleanProperties.remove('user_id'); // Remove user_id from properties
    }

    // Send the event
    await _amplitude
        .track(BaseEvent(eventName, eventProperties: cleanProperties));
  }

  // Method for testing event sending
  Future<void> validateEventSending() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Send a test event
      await logEvent(
        'test_validation_event',
        eventProperties: {
          'timestamp': DateTime.now().toString(),
          'platform': Platform.isIOS
              ? 'ios'
              : Platform.isAndroid
                  ? 'android'
                  : 'web',
        },
      );
    } catch (e) {
      debugPrint('Error sending test validation event: $e');
    }
  }

  // Method to get current user_id
  Future<String?> getCurrentUserId() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      return await _amplitude.getUserId();
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }
}

import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AmplitudeService {
  static final AmplitudeService _instance = AmplitudeService._internal();
  factory AmplitudeService() => _instance;
  AmplitudeService._internal();

  final Amplitude _amplitude = Amplitude.getInstance();
  bool _isInitialized = false;

  // Константы для настройки Amplitude
  static const int _minIdLength = 1; // Минимальная длина идентификаторов
  static const String _apiEndpoint = 'https://api2.amplitude.com/2/httpapi';

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('Amplitude already initialized');
      return;
    }

    final apiKey = dotenv.env['AMPLITUDE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('WARNING: Amplitude API key is empty!');
      return;
    }

    debugPrint('Initializing Amplitude with API key: $apiKey');

    try {
      // Настройка Amplitude перед инициализацией
      await _amplitude.setServerUrl('https://api2.amplitude.com');
      await _amplitude.enableCoppaControl();
      await _amplitude.trackingSessionEvents(true);

      // Инициализация с API ключом
      await _amplitude.init(apiKey);

      _isInitialized = true;
      debugPrint('Amplitude initialized successfully');
    } catch (e) {
      debugPrint('ERROR initializing Amplitude: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) {
      debugPrint('WARNING: Amplitude not initialized when setting user ID');
      return;
    }

    // Проверяем длину userId
    if (userId != null && userId.length < _minIdLength) {
      debugPrint(
          'WARNING: userId length is less than minimum required ($_minIdLength)');
      // Если ID слишком короткий, добавляем префикс для достижения минимальной длины
      userId = _ensureMinLength(userId);
    }

    await _amplitude.setUserId(userId);
    debugPrint('Set user ID: $userId');
  }

  Future<void> logEvent(String eventName,
      {Map<String, dynamic>? eventProperties}) async {
    if (!_isInitialized) {
      debugPrint(
          'WARNING: Amplitude not initialized when logging event: $eventName');
      return;
    }

    // Проверяем и корректируем идентификаторы в свойствах события
    final validatedProperties = _validateEventProperties(eventProperties);

    // Если в свойствах есть user_id, устанавливаем его через setUserId и удаляем из свойств
    if (validatedProperties != null &&
        validatedProperties.containsKey('user_id')) {
      final userId = validatedProperties['user_id'].toString();
      await setUserId(userId);

      // Создаем копию свойств без user_id
      final cleanProperties = Map<String, dynamic>.from(validatedProperties);
      cleanProperties.remove('user_id');

      debugPrint(
          'Logging Amplitude event: $eventName with properties (user_id set separately): $cleanProperties');

      try {
        await _amplitude.logEvent(eventName, eventProperties: cleanProperties);
        debugPrint('Event logged successfully');

        // Для важных событий можно добавить прямую отправку через HTTP API для валидации
        if (eventName == 'main_click' ||
            eventName == 'content_type' ||
            eventName == 'subcategory_click') {
          await _validateEventSent(eventName, cleanProperties);
        }
      } catch (e) {
        debugPrint('ERROR logging event: $e');
      }
    } else {
      // Если user_id нет в свойствах, просто отправляем событие
      debugPrint(
          'Logging Amplitude event: $eventName with properties: $validatedProperties');

      try {
        await _amplitude.logEvent(eventName,
            eventProperties: validatedProperties);
        debugPrint('Event logged successfully');

        // Для важных событий можно добавить прямую отправку через HTTP API для валидации
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

  // Метод для валидации отправки события через HTTP API
  Future<void> _validateEventSent(
      String eventName, Map<String, dynamic>? eventProperties) async {
    try {
      final apiKey = dotenv.env['AMPLITUDE_API_KEY'] ?? '';

      // Получаем текущий userId из Amplitude SDK
      String? currentUserId = await _amplitude.getUserId();

      // Генерируем deviceId, если его нет в свойствах
      String deviceId;
      if (eventProperties?.containsKey('device_id') == true) {
        deviceId = _ensureMinLength(eventProperties!['device_id'].toString());
      } else {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Используем текущий userId из SDK или генерируем новый
      String userId =
          currentUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Убедимся, что userId имеет минимальную длину
      userId = _ensureMinLength(userId);

      // Создаем копию свойств события без user_id и device_id, так как они будут в корне события
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

      debugPrint(
          'Sending validation event via HTTP API: ${jsonEncode(payload)}');

      final response = await http.post(Uri.parse(_apiEndpoint),
          headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
          body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Event validated via HTTP API: ${response.body}');
      } else {
        debugPrint(
            'Failed to validate event: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error validating event: $e');
    }
  }

  // Метод для проверки и корректировки свойств события
  Map<String, dynamic>? _validateEventProperties(
      Map<String, dynamic>? properties) {
    if (properties == null) return null;

    final validatedProperties = Map<String, dynamic>.from(properties);

    // Проверяем user_id
    if (validatedProperties.containsKey('user_id')) {
      final userId = validatedProperties['user_id'].toString();
      if (userId.length < _minIdLength) {
        validatedProperties['user_id'] = _ensureMinLength(userId);
      }
    }

    // Проверяем device_id
    if (validatedProperties.containsKey('device_id')) {
      final deviceId = validatedProperties['device_id'].toString();
      if (deviceId.length < _minIdLength) {
        validatedProperties['device_id'] = _ensureMinLength(deviceId);
      }
    }

    return validatedProperties;
  }

  // Метод для обеспечения минимальной длины идентификаторов
  String _ensureMinLength(String id) {
    if (id.length >= _minIdLength) return id;
    // Добавляем префикс для достижения минимальной длины
    return 'id_$id';
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized) {
      debugPrint(
          'WARNING: Amplitude not initialized when setting user properties');
      return;
    }
    await _amplitude.setUserProperties(properties);
    debugPrint('Set user properties: $properties');
  }

  Future<void> trackMainClick({
    required int userId,
    required int deviceId,
    required String source,
  }) async {
    debugPrint('Tracking main_click event:');
    debugPrint('- User ID: $userId');
    debugPrint('- Device ID: $deviceId');
    debugPrint('- Source: $source');

    // Обеспечиваем минимальную длину идентификаторов
    final validUserId = _ensureMinLength(userId.toString());
    final validDeviceId = _ensureMinLength(deviceId.toString());

    // Используем новый метод для отправки события с правильной установкой user_id
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

  // Метод для отправки события с правильной установкой user_id
  Future<void> logEventWithUserId(
    String eventName, {
    required String userId,
    Map<String, dynamic>? eventProperties,
  }) async {
    if (!_isInitialized) {
      debugPrint(
          'WARNING: Amplitude not initialized when logging event with user_id');
      await init();
    }

    // Убедимся, что userId имеет минимальную длину
    final validUserId = _ensureMinLength(userId);

    // Устанавливаем user_id в Amplitude SDK
    await setUserId(validUserId);

    // Создаем копию свойств без user_id, если они есть
    Map<String, dynamic>? cleanProperties;
    if (eventProperties != null) {
      cleanProperties = Map<String, dynamic>.from(eventProperties);
      cleanProperties.remove(
          'user_id'); // Удаляем user_id из свойств, так как он уже установлен через setUserId
    }

    debugPrint(
        'Logging event with user_id: $eventName, user_id: $validUserId, properties: $cleanProperties');

    // Отправляем событие
    await _amplitude.logEvent(eventName, eventProperties: cleanProperties);
  }

  // Метод для проверки отправки событий
  Future<void> validateEventSending() async {
    if (!_isInitialized) {
      debugPrint(
          'WARNING: Amplitude not initialized when validating event sending');
      await init();
    }

    try {
      // Отправляем тестовое событие
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
      debugPrint('Test validation event sent successfully');
    } catch (e) {
      debugPrint('Error sending test validation event: $e');
    }
  }

  // Метод для получения текущего user_id
  Future<String?> getCurrentUserId() async {
    if (!_isInitialized) {
      debugPrint(
          'WARNING: Amplitude not initialized when getting current user ID');
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

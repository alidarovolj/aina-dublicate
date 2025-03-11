import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'dart:async';
import 'package:aina_flutter/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';
import 'package:aina_flutter/core/services/storage_service.dart';

// Cache entry class to store response with metadata
class _CacheEntry {
  final Response response;
  final DateTime expiresAt;

  _CacheEntry(this.response, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _token;
  String _currentLocale = 'ru';

  // Enhanced cache implementation
  final Map<String, _CacheEntry> _requestCache = <String, _CacheEntry>{};
  static const int _maxCacheSize = 100; // Maximum number of cached responses
  static const Duration _defaultCacheExpiry = Duration(minutes: 5);

  // Stream controller for notifying about data updates
  final _updateController = StreamController<String>.broadcast();
  Stream<String> get onUpdate => _updateController.stream;

  void dispose() {
    _updateController.close();
  }

  // Update locale from context
  void updateLocaleFromContext(BuildContext context) {
    final newLocale = context.locale.languageCode;
    if (newLocale != _currentLocale) {
      _currentLocale = newLocale;
      _updateHeaders();
    }
  }

  void clearCache() {
    _requestCache.clear();
  }

  void _cleanExpiredCache() {
    _requestCache.removeWhere((_, entry) => entry.isExpired);
  }

  void _enforceMaxCacheSize() {
    if (_requestCache.length > _maxCacheSize) {
      // Remove oldest entries first
      final sortedEntries = _requestCache.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

      final entriesToRemove =
          sortedEntries.take(sortedEntries.length - _maxCacheSize);
      for (var entry in entriesToRemove) {
        _requestCache.remove(entry.key);
      }
    }
  }

  set token(String? value) {
    _token = value;
    _updateHeaders();
  }

  void _updateHeaders() {
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'language': _currentLocale,
      'Accept-Language': _currentLocale,
    };

    if (_token != null) {
      dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  ApiClient._internal() {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://default-url.com/';

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    _updateHeaders();
    _addInterceptors();
  }

  void _addInterceptors() {
    // Add error interceptor for 401 responses
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print(
              '🔒 Получена ошибка 401 Unauthorized: ${error.requestOptions.path}');

          // Clear token and cache
          _token = null;
          clearCache();
          _updateHeaders();

          // Очищаем все данные авторизации через StorageService
          await StorageService.clearAuthData();

          // Get the navigator key to access navigation
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            // Logout user using the auth provider
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(authProvider.notifier).logout();
              print('✅ Успешно выполнен logout через authProvider');
            } catch (e) {
              print('❌ Ошибка при вызове logout через authProvider: $e');
            }

            // Если это не запрос к профилю, то показываем сообщение и перенаправляем
            // Запросы к профилю обрабатываются на страницах профиля
            if (!error.requestOptions.path.contains('/api/promenade/profile')) {
              // Show error message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('errors.unauthorized'.tr()),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
          }
        }
        return handler.next(error);
      },
    ));

    // Add caching interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Clean expired cache entries
        _cleanExpiredCache();

        // Check for force refresh header
        final forceRefresh = options.headers['force-refresh'] == 'true';
        if (forceRefresh) {
          // Remove force-refresh header before sending request
          options.headers.remove('force-refresh');
          // Clear cache for this specific endpoint
          final cacheKey = '${options.uri}_$_currentLocale';
          _requestCache.remove(cacheKey);
          return handler.next(options);
        }

        // Clear cache for specific endpoints when POST requests are made
        if (options.method == 'POST') {
          if (options.path.contains('/api/promenade/profile/biometric')) {
            // Clear all cached entries related to biometric profile
            _clearBiometricCache();
          }
        }

        // Only cache GET requests
        if (options.method == 'GET') {
          final cacheKey = '${options.uri}_$_currentLocale';
          final cachedEntry = _requestCache[cacheKey];

          if (cachedEntry != null && !cachedEntry.isExpired) {
            return handler.resolve(cachedEntry.response);
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Only cache GET responses
        if (response.requestOptions.method == 'GET') {
          _cacheResponse(response);
        }
        return handler.next(response);
      },
    ));

    dio.interceptors.add(ChuckerDioInterceptor());
    dio.interceptors.add(LogInterceptor(
      request: false,
      requestBody: false,
      requestHeader: false,
      responseBody: false,
      responseHeader: false,
      error: true,
    ));
  }

  void _clearBiometricCache() {
    final pattern = RegExp(r'/api/promenade/profile/biometric.*');
    _requestCache.removeWhere((key, _) => pattern.hasMatch(key));
    // Clear localized versions
    for (var locale in ['ru', 'kk', 'en']) {
      _requestCache.removeWhere((key, _) => pattern.hasMatch('${key}_$locale'));
    }
  }

  void _cacheResponse(Response response) {
    final cacheKey = '${response.requestOptions.uri}_$_currentLocale';

    // Check if response should be cached based on headers
    final cacheControl = response.headers.value('cache-control');
    if (cacheControl == null || !cacheControl.contains('no-store')) {
      // Parse cache duration from headers or use default
      Duration cacheDuration = _defaultCacheExpiry;
      if (cacheControl != null) {
        final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
        if (maxAgeMatch != null) {
          cacheDuration = Duration(seconds: int.parse(maxAgeMatch.group(1)!));
        }
      }

      _requestCache[cacheKey] = _CacheEntry(
        response,
        DateTime.now().add(cacheDuration),
      );

      // Enforce cache size limits
      _enforceMaxCacheSize();

      // Notify about new data
      _updateController.add(response.requestOptions.uri.toString());
    }
  }

  String _generateCurlCommand(RequestOptions options) {
    final headers = options.headers.entries
        .map((e) => "-H '${e.key}: ${e.value}'")
        .join(' ');
    final data = options.data != null ? "--data '${options.data}'" : '';
    return "curl -X ${options.method} '${options.uri}' $headers $data";
  }
}

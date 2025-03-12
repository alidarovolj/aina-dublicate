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
import 'package:aina_flutter/core/widgets/base_snack_bar.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
        // Capture all API errors in Sentry with request details
        await Sentry.captureException(
          error.error,
          stackTrace: error.stackTrace,
          hint: Hint.withMap({
            'path': error.requestOptions.path,
            'method': error.requestOptions.method,
            'statusCode': error.response?.statusCode,
            'responseData': error.response?.data,
          }),
        );

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
              // Capture authentication-related errors
              await Sentry.captureException(
                e,
                hint: Hint.withMap({
                  'action': 'logout',
                  'context': 'auth_provider',
                }),
              );
              print('❌ Ошибка при вызове logout через authProvider: $e');
            }

            // Если это не запрос к профилю, то показываем сообщение и перенаправляем
            if (!error.requestOptions.path.contains('/api/promenade/profile')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                BaseSnackBar.show(
                  context,
                  message: 'errors.unauthorized'.tr(),
                  type: SnackBarType.error,
                );
              });
            }
          }
        }
        return handler.next(error);
      },
      onRequest: (options, handler) async {
        try {
          // Clean expired cache entries
          _cleanExpiredCache();

          // Check for force refresh header
          final forceRefresh = options.headers['force-refresh'] == 'true';
          if (forceRefresh) {
            options.headers.remove('force-refresh');
            final cacheKey = '${options.uri}_$_currentLocale';
            _requestCache.remove(cacheKey);
            return handler.next(options);
          }

          // Clear cache for specific endpoints when POST requests are made
          if (options.method == 'POST') {
            if (options.path.contains('/api/promenade/profile/biometric')) {
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

          // Add request to Sentry breadcrumbs
          Sentry.addBreadcrumb(
            Breadcrumb(
              category: 'http',
              type: 'http',
              level: SentryLevel.info,
              data: {
                'url': options.uri.toString(),
                'method': options.method,
                'headers': options.headers,
              },
            ),
          );

          return handler.next(options);
        } catch (e, stackTrace) {
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'stage': 'request_interceptor',
              'url': options.uri.toString(),
              'method': options.method,
            }),
          );
          return handler.next(options);
        }
      },
      onResponse: (response, handler) async {
        try {
          // Only cache GET responses
          if (response.requestOptions.method == 'GET') {
            _cacheResponse(response);
          }

          // Add successful response to Sentry breadcrumbs
          Sentry.addBreadcrumb(
            Breadcrumb(
              category: 'http',
              type: 'http',
              level: SentryLevel.info,
              data: {
                'url': response.requestOptions.uri.toString(),
                'status_code': response.statusCode,
                'method': response.requestOptions.method,
              },
            ),
          );

          return handler.next(response);
        } catch (e, stackTrace) {
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'stage': 'response_interceptor',
              'url': response.requestOptions.uri.toString(),
              'status_code': response.statusCode,
            }),
          );
          return handler.next(response);
        }
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

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'dart:async';
import 'package:aina_flutter/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:aina_flutter/widgets/base_snack_bar.dart';
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
  bool _isSentryEnabled = false;

  // Enhanced cache implementation
  final Map<String, _CacheEntry> _requestCache = <String, _CacheEntry>{};
  static const int _maxCacheSize = 100;
  static const Duration _defaultCacheExpiry = Duration(minutes: 5);

  final _updateController = StreamController<String>.broadcast();
  Stream<String> get onUpdate => _updateController.stream;

  Future<void> _captureException(dynamic exception, dynamic stackTrace,
      {Map<String, dynamic>? extras}) async {
    if (!_isSentryEnabled) return;

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: extras != null ? Hint.withMap(extras) : null,
      );
    } catch (e) {
      debugPrint('Error sending exception to Sentry: $e');
    }
  }

  Future<void> _addBreadcrumb({
    required String category,
    required String message,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_isSentryEnabled) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          category: category,
          message: message,
          data: data,
          level: level,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error adding breadcrumb to Sentry: $e');
    }
  }

  void dispose() {
    _updateController.close();
  }

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

    // Check if Sentry is enabled
    _isSentryEnabled = Sentry.isEnabled;
  }

  void _addInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        await _captureException(
          error.error,
          error.stackTrace,
          extras: {
            'path': error.requestOptions.path,
            'method': error.requestOptions.method,
            'statusCode': error.response?.statusCode,
            'responseData': error.response?.data,
          },
        );

        if (error.response?.statusCode == 401) {
          _token = null;
          clearCache();
          _updateHeaders();

          await StorageService.clearAuthData();

          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(authProvider.notifier).logout();
              debugPrint('✅ Успешно выполнен logout через authProvider');
            } catch (e, stackTrace) {
              await _captureException(
                e,
                stackTrace,
                extras: {
                  'action': 'logout',
                  'context': 'auth_provider',
                },
              );
            }

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
          _cleanExpiredCache();

          final forceRefresh = options.headers['force-refresh'] == 'true';
          if (forceRefresh) {
            options.headers.remove('force-refresh');
            final cacheKey = '${options.uri}_$_currentLocale';
            _requestCache.remove(cacheKey);
            return handler.next(options);
          }

          if (options.method == 'POST') {
            if (options.path.contains('/api/promenade/profile/biometric')) {
              _clearBiometricCache();
            }
          }

          if (options.method == 'GET') {
            final cacheKey = '${options.uri}_$_currentLocale';
            final cachedEntry = _requestCache[cacheKey];

            if (cachedEntry != null && !cachedEntry.isExpired) {
              return handler.resolve(cachedEntry.response);
            }
          }

          await _addBreadcrumb(
            category: 'http',
            message: 'API Request',
            data: {
              'url': options.uri.toString(),
              'method': options.method,
              'headers': options.headers,
            },
          );

          return handler.next(options);
        } catch (e, stackTrace) {
          await _captureException(
            e,
            stackTrace,
            extras: {
              'stage': 'request_interceptor',
              'url': options.uri.toString(),
              'method': options.method,
            },
          );
          return handler.next(options);
        }
      },
      onResponse: (response, handler) async {
        try {
          if (response.requestOptions.method == 'GET') {
            _cacheResponse(response);
          }

          await _addBreadcrumb(
            category: 'http',
            message: 'API Response',
            data: {
              'url': response.requestOptions.uri.toString(),
              'status_code': response.statusCode,
              'method': response.requestOptions.method,
            },
          );

          return handler.next(response);
        } catch (e, stackTrace) {
          await _captureException(
            e,
            stackTrace,
            extras: {
              'stage': 'response_interceptor',
              'url': response.requestOptions.uri.toString(),
              'status_code': response.statusCode,
            },
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
    for (var locale in ['ru', 'kk', 'en']) {
      _requestCache.removeWhere((key, _) => pattern.hasMatch('${key}_$locale'));
    }
  }

  void _cacheResponse(Response response) {
    final cacheKey = '${response.requestOptions.uri}_$_currentLocale';

    final cacheControl = response.headers.value('cache-control');
    if (cacheControl == null || !cacheControl.contains('no-store')) {
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

      _enforceMaxCacheSize();
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

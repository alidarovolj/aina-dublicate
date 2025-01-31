import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'dart:async';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _token;
  String _currentLocale = 'ru';
  final _requestCache = <String, Response>{};

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

  void _clearCache() {
    _requestCache.clear();
  }

  set token(String? value) {
    _token = value;
    _updateHeaders();
  }

  void _updateHeaders() {
    print('Updating headers with locale: $_currentLocale'); // Debug print
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _updateHeaders();
    _addInterceptors();
  }

  void _addInterceptors() {
    // Add caching interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Only cache GET requests
        if (options.method == 'GET') {
          final cacheKey = '${options.uri}_$_currentLocale';
          final cachedResponse = _requestCache[cacheKey];
          if (cachedResponse != null) {
            print('Returning cached response for $cacheKey');
            return handler.resolve(cachedResponse);
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Cache the response if it's a GET request
        if (response.requestOptions.method == 'GET') {
          final cacheKey = '${response.requestOptions.uri}_$_currentLocale';
          _requestCache[cacheKey] = response;
          // Notify about new data
          _updateController.add(response.requestOptions.uri.toString());
        }
        return handler.next(response);
      },
    ));

    dio.interceptors.add(ChuckerDioInterceptor());

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  String _generateCurlCommand(RequestOptions options) {
    final headers = options.headers.entries
        .map((e) => "-H '${e.key}: ${e.value}'")
        .join(' ');
    final data = options.data != null ? "--data '${options.data}'" : '';
    return "curl -X ${options.method} '${options.uri}' $headers $data";
  }
}

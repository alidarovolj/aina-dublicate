import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/pages/coworking/domain/models/biometric_data.dart';

class RetryOnErrorInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryOnErrorInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final int currentRetry = options.extra['retryCount'] ?? 0;

    if (currentRetry < maxRetries) {
      await Future.delayed(retryDelay * (currentRetry + 1));

      // Update retry count
      options.extra['retryCount'] = currentRetry + 1;

      try {
        final response = await ApiClient().dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }
}

final biometricRefreshProvider = StateProvider<int>((ref) => 0);

final biometricDataProvider =
    FutureProvider.autoDispose<BiometricData>((ref) async {
  // Watch the refresh trigger
  ref.watch(biometricRefreshProvider);

  final dio = ApiClient().dio;
  dio.interceptors.add(RetryOnErrorInterceptor(
    maxRetries: 3,
    retryDelay: const Duration(milliseconds: 500),
  ));

  try {
    final response = await dio.get(
      '/api/promenade/profile/biometric',
      options: Options(
        headers: {'force-refresh': 'true'},
      ),
    );
    return BiometricData.fromJson(response.data['data']);
  } catch (e) {
    throw Exception('Failed to load biometric data after retries');
  }
});

class BiometricService {
  late final Dio _dio;
  CancelToken? _cancelToken;

  BiometricService() {
    _dio = ApiClient().dio;
    _dio.interceptors.add(RetryOnErrorInterceptor(
      maxRetries: 3,
      retryDelay: const Duration(milliseconds: 500),
    ));
  }

  void cancelRequests() {
    _cancelToken?.cancel('Request cancelled');
    _cancelToken = null;
  }

  Future<BiometricData> getBiometricInfo({bool forceRefresh = true}) async {
    // Cancel any existing requests
    cancelRequests();
    // Create new token for this request
    _cancelToken = CancelToken();

    try {
      final response = await _dio.get(
        '/api/promenade/profile/biometric',
        cancelToken: _cancelToken,
        options: Options(
          headers: forceRefresh ? {'force-refresh': 'true'} : null,
        ),
      );
      if (response.data['success']) {
        return BiometricData.fromJson(response.data['data']);
      }
      throw Exception('Failed to load biometric data');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Request cancelled');
      }
      rethrow;
    }
  }

  Future<void> uploadBiometricPhoto(File photo) async {
    // Cancel any existing requests
    cancelRequests();
    // Create new token for this request
    _cancelToken = CancelToken();

    final formData = FormData.fromMap({
      'biometric': await MultipartFile.fromFile(photo.path),
    });

    try {
      await _dio.post('/api/promenade/profile/biometric',
          data: formData, cancelToken: _cancelToken);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Upload cancelled');
      }
      rethrow;
    }
  }

  Future<void> updateBiometricInfo({
    required String firstname,
    required String lastname,
  }) async {
    // Cancel any existing requests
    cancelRequests();
    // Create new token for this request
    _cancelToken = CancelToken();

    final formData = FormData.fromMap({
      'firstname': firstname,
      'lastname': lastname,
    });

    try {
      await _dio.post('/api/promenade/profile/biometric',
          data: formData, cancelToken: _cancelToken);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Update cancelled');
      }
      rethrow;
    }
  }

  Future<void> validateBiometric() async {
    // Cancel any existing requests
    cancelRequests();
    // Create new token for this request
    _cancelToken = CancelToken();

    try {
      await _dio.post('/api/promenade/profile/biometric-validate',
          cancelToken: _cancelToken);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Validation cancelled');
      }
      rethrow;
    }
  }
}

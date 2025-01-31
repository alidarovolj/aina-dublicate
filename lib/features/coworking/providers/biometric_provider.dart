import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/features/coworking/domain/models/biometric_data.dart';

final biometricRefreshProvider = StateProvider<int>((ref) => 0);

final biometricDataProvider =
    FutureProvider.autoDispose<BiometricData>((ref) async {
  // Watch the refresh trigger
  ref.watch(biometricRefreshProvider);

  try {
    final response =
        await ApiClient().dio.get('/api/promenade/profile/biometric');
    return BiometricData.fromJson(response.data['data']);
  } catch (e) {
    throw Exception('Failed to load biometric data');
  }
});

class BiometricService {
  final Dio _dio = ApiClient().dio;

  Future<BiometricData> getBiometricInfo() async {
    final response = await _dio.get('/api/promenade/profile/biometric');
    if (response.data['success']) {
      return BiometricData.fromJson(response.data['data']);
    }
    throw Exception('Failed to load biometric data');
  }

  Future<void> updateBiometricInfo({
    required String firstname,
    required String lastname,
  }) async {
    final formData = FormData.fromMap({
      'firstname': firstname,
      'lastname': lastname,
    });

    await _dio.post(
      '/promenade/profile/biometric',
      data: formData,
    );
  }

  Future<void> validateBiometric() async {
    await _dio.post('/api/promenade/profile/biometric/validate');
  }

  Future<void> uploadBiometricPhoto(File photo) async {
    final formData = FormData.fromMap({
      'biometric': await MultipartFile.fromFile(photo.path),
    });

    await _dio.post(
      '/api/promenade/profile/biometric',
      data: formData,
    );
  }
}

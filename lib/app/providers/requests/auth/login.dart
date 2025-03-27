import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart';
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:aina_flutter/app/providers/auth/auth_state.dart';

final requestCodeProvider = Provider<RequestCodeService>(
    (ref) => RequestCodeService(ApiClient().dio, ref));

class RequestCodeService {
  final Dio _dio;
  final Ref ref;

  RequestCodeService(this._dio, this.ref);

  Future<String?> _getAuthHeader() async {
    final token = await StorageService.getToken();
    return token != null ? 'Bearer $token' : null;
  }

  Future<Response?> sendCodeRequest(String phoneNumber) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.post(
        '/login/send-message',
        queryParameters: {'phone': phoneNumber},
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> signUp(
      String phone, String firstName, String lastName, String birthDate) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.post(
        '/sign-up',
        data: {
          'phone': phone,
          'first_name': firstName,
          'last_name': lastName,
          'birth_date': birthDate,
        },
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> sendOTP(String phoneNumber, String code) async {
    try {
      final response = await _dio.post(
        '/auth/signin/',
        data: {
          'phone': phoneNumber,
          'otp': code,
        },
      );

      if (response.data is Map && response.data['access_token'] != null) {
        final token = response.data['access_token'];
        ref.read(authProvider.notifier).setToken(token);
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> userProfile() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/aina/profile',
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );
      return response;
    } catch (e) {
      return null;
    }
  }
}

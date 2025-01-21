import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:aina_flutter/core/services/storage_service.dart';

final requestCodeProvider =
    Provider<RequestCodeService>((ref) => RequestCodeService(ApiClient().dio));

class RequestCodeService {
  final Dio _dio;

  RequestCodeService(Dio dio) : _dio = dio;

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
      print('Ошибка при запросе кода: $e');
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
      print('Ошибка при запросе кода: $e');
      return null;
    }
  }

  Future<Response?> sendOTP(String phoneNumber, String code) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.post(
        '/login',
        data: {
          'phone': phoneNumber,
          'code': code,
        },
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );
      return response;
    } catch (e) {
      print('Ошибка при запросе кода: $e');
      return null;
    }
  }

  Future<Response?> userProfile() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/auth/me',
        options: authHeader != null
            ? Options(headers: {'Authorization': authHeader})
            : null,
      );
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}

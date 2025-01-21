import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart'; // Импорт ApiClient

// Провайдер для отправки запроса
final requestCodeProvider =
    Provider<RequestCodeService>((ref) => RequestCodeService(ApiClient().dio));

class RequestCodeService {
  final Dio _dio;

  RequestCodeService(Dio dio) : _dio = dio;

  Future<Response?> userProfile(String phoneNumber) async {
    try {
      final response = await _dio.get('/auth/me');
      return response;
    } catch (e) {
      print('Ошибка при запросе кода: $e');
      return null;
    }
  }

  Future<Response?> sendCodeRequest(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/login/send-message',
        queryParameters: {'phone': phoneNumber}, // Параметры запроса
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
      final response = await _dio.post(
        '/sign-up',
        data: {
          'phone': phone,
          'first_name': firstName,
          'last_name': lastName,
          'birth_date': birthDate,
        },
      );
      return response;
    } catch (e) {
      print('Ошибка при запросе кода: $e');
      return null;
    }
  }

  Future<Response?> sendOTP(String phoneNumber, String code) async {
    try {
      print('Отправка OTP запроса: телефон=$phoneNumber, код=$code');

      final response = await _dio.post(
        '/login',
        data: {
          'phone': phoneNumber,
          'code': code,
        },
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      print('Ответ от сервера (полный): ${response.toString()}');
      print('Данные ответа: ${response.data}');
      print('Тип данных ответа: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('Токен в ответе: ${response.data['access_token']}');
      }
      print('Статус код: ${response.statusCode}');

      return response;
    } on DioException catch (e) {
      print('DioError при отправке OTP: ${e.message}');
      print('Тип ошибки: ${e.type}');
      print('Ответ: ${e.response}');
      return e.response;
    } catch (e) {
      print('Общая ошибка при отправке OTP: $e');
      return null;
    }
  }
}

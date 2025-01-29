import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart'; // Импорт ApiClient
import 'package:aina_flutter/core/services/storage_service.dart';

// Провайдер для отправки запроса
final requestCodeProvider =
    Provider<RequestCodeService>((ref) => RequestCodeService(ApiClient().dio));

class RequestCodeService {
  final Dio _dio;

  RequestCodeService(this._dio);

  Future<Response?> userProfile() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await _dio.get(
        '/api/aina/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch profile: ${response.statusCode}',
        );
      }

      return response;
    } on DioException catch (e) {
      print('DioError fetching profile: ${e.message}');
      print('Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Response?> sendCodeRequest(String phoneNumber) async {
    try {
      final response = await _dio.get(
        '/auth/get-otp',
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
        '/auth/signin/',
        data: {
          'phone': phoneNumber,
          'otp': code,
        },
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          followRedirects: true,
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

class UserProfile {
  final String numericPhone;
  final String maskedPhone;
  final String? email;
  final String firstName;
  final String lastName;
  final String? patronymic;
  final String? gender;
  final String? licensePlate;
  final String? avatarUrl;

  UserProfile({
    required this.numericPhone,
    required this.maskedPhone,
    required this.firstName,
    required this.lastName,
    this.email,
    this.patronymic,
    this.gender,
    this.licensePlate,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return UserProfile(
      numericPhone: data['phone']['numeric'],
      maskedPhone: data['phone']['masked'],
      email: data['email'],
      firstName: data['firstname'],
      lastName: data['lastname'],
      patronymic: data['patronymic'],
      gender: data['gender'],
      licensePlate: data['license_plate'],
      avatarUrl: data['avatar']?['url'],
    );
  }
}

final userProvider = FutureProvider<UserProfile>((ref) async {
  // TODO: Implement actual user fetch logic
  return UserProfile(
    numericPhone: '+7 700 111 11 11',
    maskedPhone: '+7 700 111 11 11',
    firstName: 'Анна',
    lastName: 'Маринина',
  );
});

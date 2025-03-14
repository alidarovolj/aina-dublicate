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
            'force-refresh': 'true',
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
    } on DioException {
      // print('DioError fetching profile: ${e.message}');
      // print('Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      // print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Response?> updateAinaProfile({
    required String firstName,
    required String lastName,
    String? patronymic,
    String? email,
    String? licensePlate,
    String? gender,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await _dio.post(
        '/api/aina/profile',
        data: {
          'firstname': firstName,
          'lastname': lastName,
          'patronymic': patronymic,
          'email': email,
          'license_plate': licensePlate,
          'gender': gender,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'force-refresh': 'true',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to update profile: ${response.statusCode}',
        );
      }

      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response?> sendCodeRequest(
    String phone, {
    String? appHash,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/get-otp',
        queryParameters: {
          'phone': phone,
          if (appHash != null) 'app_hash': appHash,
        },
        options: options,
      );

      return response;
    } catch (e) {
      print('Error sending code request: $e');
      rethrow;
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
      // print('Ошибка при запросе кода: $e');
      return null;
    }
  }

  Future<Response?> sendOTP(String phoneNumber, String code) async {
    try {
      // print('Отправка OTP запроса: телефон=$phoneNumber, код=$code');

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

      // print('Ответ от сервера (полный): ${response.toString()}');
      // print('Данные ответа: ${response.data}');
      // print('Тип данных ответа: ${response.data.runtimeType}');
      if (response.data is Map) {
        // print('Токен в ответе: ${response.data['access_token']}');
      }
      // print('Статус код: ${response.statusCode}');

      return response;
    } on DioException catch (e) {
      // print('DioError при отправке OTP: ${e.message}');
      // print('Тип ошибки: ${e.type}');
      // print('Ответ: ${e.response}');
      return e.response;
    } catch (e) {
      // print('Общая ошибка при отправке OTP: $e');
      return null;
    }
  }

  Future<Response?> userTickets() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await _dio.get(
        '/api/aina/my-tickets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'force-refresh': 'true',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch tickets: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}

class UserProfile {
  final String numericPhone;
  final String maskedPhone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;
  final String? gender;
  final String? licensePlate;
  final String? avatarUrl;

  UserProfile({
    required this.numericPhone,
    required this.maskedPhone,
    this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.gender,
    this.licensePlate,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return UserProfile(
      numericPhone: data['phone']['numeric'].toString(),
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
  try {
    print('🔄 Fetching user profile from userProvider');
    final requestService = ref.read(requestCodeProvider);
    final response = await requestService.userProfile();

    print('📊 User profile response: ${response?.data}');

    if (response == null) {
      print('❌ User profile response is null');
      throw Exception('Failed to fetch user profile: Response is null');
    }

    if (response.statusCode != 200) {
      print(
          '❌ User profile request failed with status: ${response.statusCode}');
      throw Exception(
          'Failed to fetch user profile: Status ${response.statusCode}');
    }

    if (response.data == null) {
      print('❌ User profile data is null');
      throw Exception('Failed to fetch user profile: Data is null');
    }

    final userData = response.data;
    if (userData['data'] == null) {
      print('❌ User profile data["data"] is null');
      throw Exception('Failed to fetch user profile: Invalid data format');
    }

    print('✅ Creating UserProfile from data');
    return UserProfile.fromJson(userData);
  } catch (e, stack) {
    print('❌ Error in userProvider: $e');
    print('📚 Stack trace: $stack');
    rethrow;
  }
});

class Ticket {
  final int id;
  final String? promotionName;
  final String? promotionImage;
  final String? promotionType;
  final DateTime createdAt;
  final int ticketNo;
  final String? receiptNo;
  final String? organization;
  final double? amount;
  final DateTime? purchaseDate;

  Ticket({
    required this.id,
    this.promotionName,
    this.promotionImage,
    this.promotionType,
    required this.createdAt,
    required this.ticketNo,
    this.receiptNo,
    this.organization,
    this.amount,
    this.purchaseDate,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      promotionName: json['promotion']?['name'],
      promotionImage: json['promotion']?['preview_image']?['url'],
      promotionType: json['promotion']?['type'],
      createdAt: DateTime.parse(json['created_at']),
      ticketNo: json['ticket_no'],
      receiptNo: json['receipt_no'],
      organization: json['organization']?['name'],
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : null,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
    );
  }
}

final userTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final requestService = ref.read(requestCodeProvider);
  try {
    final response = await requestService.userTickets();

    if (response == null || response.statusCode != 200) {
      return [];
    }

    final data = response.data['data'] as List;
    return data.map((ticket) => Ticket.fromJson(ticket)).toList();
  } catch (e) {
    return [];
  }
});

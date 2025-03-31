import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/shared/api/api_client.dart'; // Импорт ApiClient
import 'package:aina_flutter/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';

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
      rethrow;
    } catch (e) {
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

      if (response.data is Map) {}

      return response;
    } on DioException catch (e) {
      return e.response;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> userTickets() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      debugPrint('🔑 Making request with token: ${token.substring(0, 20)}...');

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

      debugPrint('📡 Response status code: ${response.statusCode}');
      debugPrint('📦 Raw response data: ${response.data}');

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch tickets: ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error in userTickets: $e');
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
    final requestService = ref.read(requestCodeProvider);
    final response = await requestService.userProfile();

    if (response == null) {
      throw Exception('Failed to fetch user profile: Response is null');
    }

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch user profile: Status ${response.statusCode}');
    }

    if (response.data == null) {
      throw Exception('Failed to fetch user profile: Data is null');
    }

    final userData = response.data;
    if (userData['data'] == null) {
      throw Exception('Failed to fetch user profile: Invalid data format');
    }

    return UserProfile.fromJson(userData);
  } catch (e) {
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
    try {
      debugPrint('🎫 Parsing ticket: $json');

      // Проверка id
      final id = json['id'] as int?;
      if (id == null) {
        debugPrint('❌ Ticket ID is null');
        throw Exception('Ticket ID is required');
      }

      // Проверка created_at
      final createdAt = json['created_at'] as String?;
      if (createdAt == null) {
        debugPrint('❌ Created at is null');
        throw Exception('Created at is required');
      }

      // Проверка ticket_no
      final ticketNo = json['ticket_no'] as int?;
      if (ticketNo == null) {
        debugPrint('❌ Ticket number is null');
        throw Exception('Ticket number is required');
      }

      // Проверка promotion (теперь опционально)
      final promotion = json['promotion'] as Map<String, dynamic>?;
      String? promotionName;
      String? promotionImage;
      String? promotionType;

      if (promotion != null) {
        promotionName = promotion['name'] as String?;
        final previewImage =
            promotion['preview_image'] as Map<String, dynamic>?;
        promotionImage = previewImage?['url'] as String?;
        promotionType = promotion['type'] as String?;
      }

      // Проверка receipt_no
      final receiptNo = json['receipt_no'] as String?;

      // Проверка organization
      final organization = json['organization'] as Map<String, dynamic>?;
      final organizationName = organization?['name'] as String?;

      // Проверка amount
      double? amount;
      if (json['amount'] != null) {
        amount = double.tryParse(json['amount'].toString());
        if (amount == null) {
          debugPrint('❌ Invalid amount format: ${json['amount']}');
        }
      }

      // Проверка purchase_date
      DateTime? purchaseDate;
      if (json['purchase_date'] != null) {
        try {
          purchaseDate = DateTime.parse(json['purchase_date']);
        } catch (e) {
          debugPrint(
              '❌ Invalid purchase date format: ${json['purchase_date']}');
        }
      }

      debugPrint('✅ Successfully parsed ticket data:');
      debugPrint('   ID: $id');
      if (promotionName != null) debugPrint('   Promotion: $promotionName');
      if (promotionType != null) debugPrint('   Type: $promotionType');
      debugPrint('   Ticket No: $ticketNo');
      debugPrint('   Created At: $createdAt');
      if (receiptNo != null) debugPrint('   Receipt No: $receiptNo');
      if (organizationName != null) {
        debugPrint('   Organization: $organizationName');
      }
      if (amount != null) debugPrint('   Amount: $amount');
      if (purchaseDate != null) debugPrint('   Purchase Date: $purchaseDate');

      return Ticket(
        id: id,
        promotionName: promotionName,
        promotionImage: promotionImage,
        promotionType: promotionType,
        createdAt: DateTime.parse(createdAt),
        ticketNo: ticketNo,
        receiptNo: receiptNo,
        organization: organizationName,
        amount: amount,
        purchaseDate: purchaseDate,
      );
    } catch (e) {
      debugPrint('❌ Error parsing ticket: $e');
      rethrow;
    }
  }
}

final userTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final requestService = ref.read(requestCodeProvider);
  try {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('401');
    }

    final response = await requestService.userTickets();

    if (response == null || response.statusCode != 200) {
      debugPrint('❌ Failed to fetch tickets: ${response?.statusCode}');
      return [];
    }

    final data = response.data;
    debugPrint('📦 Response data type: ${data.runtimeType}');
    debugPrint('📦 Response data keys: ${data.keys.toList()}');
    debugPrint('📦 Success value: ${data['success']}');
    debugPrint('📦 Data value type: ${data['data']?.runtimeType}');

    if (data == null || data['success'] != true || data['data'] == null) {
      debugPrint('❌ Invalid tickets data format');
      return [];
    }

    final ticketsData = data['data'] as List;
    debugPrint('🎫 Found ${ticketsData.length} tickets');

    final tickets = <Ticket>[];
    for (var ticketData in ticketsData) {
      try {
        final ticket = Ticket.fromJson(ticketData);
        tickets.add(ticket);
      } catch (e) {
        debugPrint('❌ Failed to parse ticket: $e');
        continue;
      }
    }

    debugPrint('✅ Successfully parsed ${tickets.length} tickets');
    if (tickets.isNotEmpty) {
      debugPrint(
          '✅ First ticket parsed: ${tickets.first.id} - ${tickets.first.promotionName}');
    }

    return tickets;
  } catch (e) {
    debugPrint('❌ Error in userTicketsProvider: $e');
    if (e.toString().contains('401')) {
      throw Exception('401');
    }
    return [];
  }
});

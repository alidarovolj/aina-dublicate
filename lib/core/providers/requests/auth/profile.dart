import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final profileProvider = Provider((ref) => ProfileProvider(ref));

class ProfileProvider {
  final Ref ref;
  final _apiClient = ApiClient();

  ProfileProvider(this.ref);

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String patronymic,
    required String email,
    required String licensePlate,
    required String gender,
  }) async {
    try {
      final formData = FormData.fromMap({
        'firstname': firstName,
        'lastname': lastName,
        'patronymic': patronymic,
        'email': email,
        'license_plate': licensePlate,
        'gender': gender,
      });

      final response = await _apiClient.dio.post(
        '/api/aina/profile',
        data: formData,
        options: Options(
          headers: {
            'accept-language': 'ru',
            'language': 'ru',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

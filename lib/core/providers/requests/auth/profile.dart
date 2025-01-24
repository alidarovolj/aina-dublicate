import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/providers/auth/auth_state.dart';

final profileProvider = Provider((ref) => ProfileProvider(ref));

class ProfileProvider {
  final Ref ref;

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
      final userData = ref.read(authProvider).userData!;
      final dio = Dio();

      final formData = FormData.fromMap({
        'firstname': firstName,
        'lastname': lastName,
        'patronymic': patronymic,
        'email': email,
        'license_plate': licensePlate,
        'gender': gender,
      });

      final response = await dio.post(
        'https://devsuperapi.aina-fashion.kz/api/aina/profile',
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'accept-language': 'ru',
            'authorization': 'Bearer ${userData['token']}',
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

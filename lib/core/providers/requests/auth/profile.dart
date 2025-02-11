import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';

final profileProvider = Provider((ref) => ProfileProvider(ref));

final promenadeProfileProvider = Provider<PromenadeProfileService>((ref) {
  return PromenadeProfileService(ApiClient().dio);
});

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

class PromenadeProfileService {
  final Dio _dio;

  PromenadeProfileService(this._dio);

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = true}) async {
    try {
      final response = await _dio.get(
        '/api/promenade/profile',
        options: Options(
          headers: {'force-refresh': 'true'},
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Failed to fetch profile data');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? patronymic,
    String? email,
    String? gender,
    String? iin,
  }) async {
    try {
      final formData = {
        'firstname': firstName,
        'lastname': lastName,
        'patronymic': patronymic,
        'email': email,
        'gender': gender,
        'iin': iin,
      };

      final response = await _dio.post(
        '/api/promenade/profile',
        data: formData,
        options: Options(
          headers: {'force-refresh': 'true'}, // Always force refresh on update
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }
}

// Create a provider for the profile data with cache key
final profileCacheKeyProvider = StateProvider<int>((ref) => 0);

// Modified profile data provider with cache key support
final promenadeProfileDataProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, cacheKey) async {
  final service = ref.read(promenadeProfileProvider);
  return service.getProfile();
});

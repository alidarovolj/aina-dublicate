import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina_flutter/core/api/api_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

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

  Future<Map<String, dynamic>> uploadAvatar(File photo) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(photo.path),
      });

      final response = await _dio.post(
        '/api/promenade/profile',
        data: formData,
        options: Options(
          headers: {'force-refresh': 'true'},
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        // Get fresh profile data to ensure we have the latest avatar URL
        final updatedProfile = await getProfile(forceRefresh: true);

        // Verify that we have the avatar in the response
        if (updatedProfile['avatar'] == null) {
          throw Exception(
              'Avatar upload succeeded but avatar is missing in profile');
        }

        return updatedProfile;
      }
      throw Exception('Failed to upload avatar: Invalid response format');
    } catch (e) {
      print('Error uploading avatar: $e');
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
    File? avatar,
  }) async {
    try {
      final Map<String, dynamic> formData = {
        'firstname': firstName,
        'lastname': lastName,
        if (patronymic != null) 'patronymic': patronymic,
        if (email != null) 'email': email,
        if (gender != null) 'gender': gender,
        if (iin != null) 'iin': iin,
      };

      if (avatar != null) {
        formData['avatar'] = await MultipartFile.fromFile(avatar.path);
      }

      final response = await _dio.post(
        '/api/promenade/profile',
        data: FormData.fromMap(formData),
        options: Options(
          headers: {'force-refresh': 'true'},
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

  Future<Map<String, dynamic>> removeAvatar() async {
    try {
      final response = await _dio.post(
        '/api/promenade/profile/remove-avatar',
        options: Options(
          headers: {
            'force-refresh': 'true',
            'cache-control': 'no-cache, no-store, must-revalidate',
            'pragma': 'no-cache',
            'expires': '0',
          },
        ),
      );

      if (response.data == null || response.data['success'] != true) {
        throw Exception('Failed to remove avatar');
      }

      // Get fresh profile data with force refresh to ensure avatar is removed
      final updatedProfile = await getProfile(forceRefresh: true);

      // Verify that the avatar is actually null in the response
      if (updatedProfile['avatar'] != null) {
        throw Exception('Avatar was not properly removed');
      }

      return updatedProfile;
    } catch (e) {
      print('Error in removeAvatar: $e');
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
